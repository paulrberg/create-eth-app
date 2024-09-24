/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Libraries
import "./synthetix/DecimalMath.sol";
import "./synthetix/SignedDecimalMath.sol";
import "./libraries/BlackScholes.sol";
import "./libraries/ConvertDecimals.sol";
import "./libraries/Math.sol";
import "./libraries/GWAV.sol";

// Inherited
import "./synthetix/Owned.sol";
import "./libraries/SimpleInitializable.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/security/ReentrancyGuard.sol";

// Interfaces
import "./BaseExchangeAdapter.sol";
import "./OptionMarket.sol";
import "./OptionMarketPricer.sol";

/**
 * @title OptionGreekCache
 * @author Lyra
 * @dev Aggregates the netDelta and netStdVega of the OptionMarket by iterating over current strikes, using gwav vols.
 * Needs to be called by an external actor as it's not feasible to do all the computation during the trade flow and
 * because delta/vega change over time and with movements in asset price and volatility.
 * All stored values in this contract are the aggregate of the trader's perspective. So values need to be inverted
 * to get the LP's perspective
 * Also handles logic for figuring out minimal collateral requirements for shorts.
 */
contract OptionGreekCache is Owned, SimpleInitializable, ReentrancyGuard {
  using DecimalMath for uint;
  using SignedDecimalMath for int;
  using GWAV for GWAV.Params;
  using BlackScholes for BlackScholes.BlackScholesInputs;

  ////////////////
  // Parameters //
  ////////////////

  struct GreekCacheParameters {
    // Cap the number of strikes per board to avoid hitting gasLimit constraints
    uint maxStrikesPerBoard;
    // How much spot price can move since last update before deposits/withdrawals are blocked
    uint acceptableSpotPricePercentMove;
    // How much time has passed since last update before deposits/withdrawals are blocked
    uint staleUpdateDuration;
    // Length of the GWAV for the baseline volatility used to fire the vol circuit breaker
    uint varianceIvGWAVPeriod;
    // Length of the GWAV for the skew ratios used to fire the vol circuit breaker
    uint varianceSkewGWAVPeriod;
    // Length of the GWAV for the baseline used to determine the NAV of the pool
    uint optionValueIvGWAVPeriod;
    // Length of the GWAV for the skews used to determine the NAV of the pool
    uint optionValueSkewGWAVPeriod;
    // Minimum skew that will be fed into the GWAV calculation
    // Prevents near 0 values being used to heavily manipulate the GWAV
    uint gwavSkewFloor;
    // Maximum skew that will be fed into the GWAV calculation
    uint gwavSkewCap;
  }

  struct ForceCloseParameters {
    // Length of the GWAV for the baseline vol used in ForceClose() and liquidations
    uint ivGWAVPeriod;
    // Length of the GWAV for the skew ratio used in ForceClose() and liquidations
    uint skewGWAVPeriod;
    // When a user buys back an option using ForceClose() we increase the GWAV vol to penalise the trader
    uint shortVolShock;
    // Increase the penalty when within the trading cutoff
    uint shortPostCutoffVolShock;
    // When a user sells back an option to the AMM using ForceClose(), we decrease the GWAV to penalise the seller
    uint longVolShock;
    // Increase the penalty when within the trading cutoff
    uint longPostCutoffVolShock;
    // Same justification as shortPostCutoffVolShock
    uint liquidateVolShock;
    // Increase the penalty when within the trading cutoff
    uint liquidatePostCutoffVolShock;
    // Minimum price the AMM will sell back an option at for force closes (as a % of current spot)
    uint shortSpotMin;
    // Minimum price the AMM will sell back an option at for liquidations (as a % of current spot)
    uint liquidateSpotMin;
  }

  struct MinCollateralParameters {
    // Minimum collateral that must be posted for a short to be opened (denominated in quote)
    uint minStaticQuoteCollateral;
    // Minimum collateral that must be posted for a short to be opened (denominated in base)
    uint minStaticBaseCollateral;
    /* Shock Vol:
     * Vol used to compute the minimum collateral requirements for short positions.
     * This value is derived from the following chart, created by using the 4 values listed below.
     *
     *     vol
     *      |
     * volA |____
     *      |    \
     * volB |     \___
     *      |___________ time to expiry
     *         A   B
     */
    uint shockVolA;
    uint shockVolPointA;
    uint shockVolB;
    uint shockVolPointB;
    // Static percentage shock to the current spot price for calls
    uint callSpotPriceShock;
    // Static percentage shock to the current spot price for puts
    uint putSpotPriceShock;
  }

  ///////////////////
  // Cache storage //
  ///////////////////
  struct GlobalCache {
    uint minUpdatedAt;
    uint minUpdatedAtPrice;
    uint maxUpdatedAtPrice;
    uint maxSkewVariance;
    uint maxIvVariance;
    NetGreeks netGreeks;
  }

  struct OptionBoardCache {
    uint id;
    uint[] strikes;
    uint expiry;
    uint iv;
    NetGreeks netGreeks;
    uint updatedAt;
    uint updatedAtPrice;
    uint maxSkewVariance;
    uint ivVariance;
  }

  struct StrikeCache {
    uint id;
    uint boardId;
    uint strikePrice;
    uint skew;
    StrikeGreeks greeks;
    int callExposure; // long - short
    int putExposure; // long - short
    uint skewVariance; // (GWAVSkew - skew)
  }

  // These are based on GWAVed iv
  struct StrikeGreeks {
    int callDelta;
    int putDelta;
    uint stdVega;
    uint callPrice;
    uint putPrice;
  }

  // These are based on GWAVed iv
  struct NetGreeks {
    int netDelta;
    int netStdVega;
    int netOptionValue;
  }

  ///////////////
  // In-memory //
  ///////////////
  struct TradePricing {
    uint optionPrice;
    int preTradeAmmNetStdVega;
    int postTradeAmmNetStdVega;
    int callDelta;
    uint volTraded;
    uint ivVariance;
    uint vega;
  }

  struct BoardGreeksView {
    NetGreeks boardGreeks;
    uint ivGWAV;
    StrikeGreeks[] strikeGreeks;
    uint[] skewGWAVs;
  }

  ///////////////
  // Variables //
  ///////////////
  BaseExchangeAdapter internal exchangeAdapter;
  OptionMarket internal optionMarket;
  address internal optionMarketPricer;

  GreekCacheParameters internal greekCacheParams;
  ForceCloseParameters internal forceCloseParams;
  MinCollateralParameters internal minCollatParams;

  // Cached values and GWAVs
  /// @dev Should be a clone of OptionMarket.liveBoards
  uint[] internal liveBoards;
  GlobalCache internal globalCache;

  mapping(uint => OptionBoardCache) internal boardCaches;
  mapping(uint => GWAV.Params) internal boardIVGWAV;

  mapping(uint => StrikeCache) internal strikeCaches;
  mapping(uint => GWAV.Params) internal strikeSkewGWAV;

  ///////////
  // Setup //
  ///////////

  constructor() Owned() {}

  /**
   * @dev Initialize the contract.
   *
   * @param _exchangeAdapter BaseExchangeAdapter address
   * @param _optionMarket OptionMarket address
   * @param _optionMarketPricer OptionMarketPricer address
   */
  function init(
    BaseExchangeAdapter _exchangeAdapter,
    OptionMarket _optionMarket,
    address _optionMarketPricer
  ) external onlyOwner initializer {
    exchangeAdapter = _exchangeAdapter;
    optionMarket = _optionMarket;
    optionMarketPricer = _optionMarketPricer;
  }

  ///////////
  // Admin //
  ///////////

  function setGreekCacheParameters(GreekCacheParameters memory _greekCacheParams) external onlyOwner {
    if (
      !(_greekCacheParams.acceptableSpotPricePercentMove <= 10e18 && //
        _greekCacheParams.staleUpdateDuration <= 30 days && //
        _greekCacheParams.varianceIvGWAVPeriod > 0 && //
        _greekCacheParams.varianceIvGWAVPeriod <= 60 days && //
        _greekCacheParams.varianceSkewGWAVPeriod > 0 &&
        _greekCacheParams.varianceSkewGWAVPeriod <= 60 days &&
        _greekCacheParams.optionValueIvGWAVPeriod > 0 &&
        _greekCacheParams.optionValueIvGWAVPeriod <= 60 days &&
        _greekCacheParams.optionValueSkewGWAVPeriod > 0 &&
        _greekCacheParams.optionValueSkewGWAVPeriod <= 60 days &&
        _greekCacheParams.gwavSkewFloor <= 1e18 &&
        _greekCacheParams.gwavSkewFloor > 0 &&
        _greekCacheParams.gwavSkewCap >= 1e18)
    ) {
      revert InvalidGreekCacheParameters(address(this), _greekCacheParams);
    }

    greekCacheParams = _greekCacheParams;
    emit GreekCacheParametersSet(greekCacheParams);
  }

  function setForceCloseParameters(ForceCloseParameters memory _forceCloseParams) external onlyOwner {
    if (
      !(_forceCloseParams.ivGWAVPeriod > 0 &&
        _forceCloseParams.ivGWAVPeriod <= 60 days &&
        _forceCloseParams.skewGWAVPeriod > 0 &&
        _forceCloseParams.skewGWAVPeriod <= 60 days &&
        _forceCloseParams.shortVolShock >= 1e18 &&
        _forceCloseParams.shortPostCutoffVolShock >= 1e18 &&
        _forceCloseParams.longVolShock > 0 &&
        _forceCloseParams.longVolShock <= 1e18 &&
        _forceCloseParams.longPostCutoffVolShock > 0 &&
        _forceCloseParams.longPostCutoffVolShock <= 1e18 &&
        _forceCloseParams.liquidateVolShock >= 1e18 &&
        _forceCloseParams.liquidatePostCutoffVolShock >= 1e18 &&
        _forceCloseParams.shortSpotMin <= 1e18 &&
        _forceCloseParams.liquidateSpotMin <= 1e18)
    ) {
      revert InvalidForceCloseParameters(address(this), _forceCloseParams);
    }

    forceCloseParams = _forceCloseParams;
    emit ForceCloseParametersSet(forceCloseParams);
  }

  function setMinCollateralParameters(MinCollateralParameters memory _minCollatParams) external onlyOwner {
    if (
      !(_minCollatParams.minStaticQuoteCollateral > 0 &&
        _minCollatParams.minStaticBaseCollateral > 0 &&
        _minCollatParams.shockVolA > 0 &&
        _minCollatParams.shockVolA >= _minCollatParams.shockVolB &&
        _minCollatParams.shockVolPointA <= _minCollatParams.shockVolPointB &&
        _minCollatParams.callSpotPriceShock >= 1e18 &&
        _minCollatParams.putSpotPriceShock > 0 &&
        _minCollatParams.putSpotPriceShock <= 1e18)
    ) {
      revert InvalidMinCollatParams(address(this), _minCollatParams);
    }

    minCollatParams = _minCollatParams;
    emit MinCollateralParametersSet(minCollatParams);
  }

  //////////////////////////////////////////////////////
  // Sync Boards with OptionMarket (onlyOptionMarket) //
  //////////////////////////////////////////////////////

  /**
   * @notice Adds a new OptionBoardCache
   * @dev Called by the OptionMarket whenever a new OptionBoard is added
   *
   * @param board The new OptionBoard
   * @param strikes The new Strikes for the given board
   */
  function addBoard(
    OptionMarket.OptionBoard memory board,
    OptionMarket.Strike[] memory strikes
  ) external onlyOptionMarket {
    uint strikesLength = strikes.length;
    if (strikesLength > greekCacheParams.maxStrikesPerBoard) {
      revert BoardStrikeLimitExceeded(address(this), board.id, strikesLength, greekCacheParams.maxStrikesPerBoard);
    }

    OptionBoardCache storage boardCache = boardCaches[board.id];
    boardCache.id = board.id;
    boardCache.expiry = board.expiry;
    boardCache.iv = board.iv;
    boardCache.updatedAt = block.timestamp;
    emit BoardCacheUpdated(boardCache);
    boardIVGWAV[board.id]._initialize(board.iv, block.timestamp);
    emit BoardIvUpdated(boardCache.id, board.iv, globalCache.maxIvVariance);

    liveBoards.push(board.id);

    for (uint i = 0; i < strikesLength; ++i) {
      _addNewStrikeToStrikeCache(boardCache, strikes[i].id, strikes[i].strikePrice, strikes[i].skew);
    }

    updateBoardCachedGreeks(board.id);
  }

  /// @dev After board settlement, remove an OptionBoardCache. Called by OptionMarket
  function removeBoard(uint boardId) external onlyOptionMarket {
    // Remove board from cache, removing net positions from global count
    OptionBoardCache memory boardCache = boardCaches[boardId];
    globalCache.netGreeks.netDelta -= boardCache.netGreeks.netDelta;
    globalCache.netGreeks.netStdVega -= boardCache.netGreeks.netStdVega;
    globalCache.netGreeks.netOptionValue -= boardCache.netGreeks.netOptionValue;

    // Clean up, cache isn't necessary for settle logic
    uint boardStrikesLength = boardCache.strikes.length;
    for (uint i = 0; i < boardStrikesLength; ++i) {
      emit StrikeCacheRemoved(boardCache.strikes[i]);
      delete strikeCaches[boardCache.strikes[i]];
    }
    uint liveBoardsLength = liveBoards.length;
    for (uint i = 0; i < liveBoardsLength; ++i) {
      if (liveBoards[i] == boardId) {
        liveBoards[i] = liveBoards[liveBoardsLength - 1];
        liveBoards.pop();
        break;
      }
    }
    emit BoardCacheRemoved(boardId);
    emit GlobalCacheUpdated(globalCache);
    delete boardCaches[boardId];
  }

  /// @dev Add a new strike to a given boardCache. Only callable by OptionMarket.
  function addStrikeToBoard(uint boardId, uint strikeId, uint strikePrice, uint skew) external onlyOptionMarket {
    OptionBoardCache storage boardCache = boardCaches[boardId];
    if (boardCache.strikes.length == greekCacheParams.maxStrikesPerBoard) {
      revert BoardStrikeLimitExceeded(
        address(this),
        boardId,
        boardCache.strikes.length + 1,
        greekCacheParams.maxStrikesPerBoard
      );
    }

    _addNewStrikeToStrikeCache(boardCache, strikeId, strikePrice, skew);
    updateBoardCachedGreeks(boardId);
  }

  /// @dev Updates an OptionBoard's baseIv. Only callable by OptionMarket.
  function setBoardIv(uint boardId, uint newBaseIv) external onlyOptionMarket {
    OptionBoardCache storage boardCache = boardCaches[boardId];
    _updateBoardIv(boardCache, newBaseIv);
    emit BoardIvUpdated(boardId, newBaseIv, globalCache.maxIvVariance);
  }

  /**
   * @dev Updates a Strike's skew. Only callable by OptionMarket.
   *
   * @param strikeId The id of the Strike
   * @param newSkew The new skew of the given Strike
   */
  function setStrikeSkew(uint strikeId, uint newSkew) external onlyOptionMarket {
    StrikeCache storage strikeCache = strikeCaches[strikeId];
    OptionBoardCache storage boardCache = boardCaches[strikeCache.boardId];
    _updateStrikeSkew(boardCache, strikeCache, newSkew);
  }

  /// @dev Adds a new strike to a given board, initialising the skew GWAV
  function _addNewStrikeToStrikeCache(
    OptionBoardCache storage boardCache,
    uint strikeId,
    uint strikePrice,
    uint skew
  ) internal {
    // This is only called when a new board or a new strike is added, so exposure values will be 0
    StrikeCache storage strikeCache = strikeCaches[strikeId];
    strikeCache.id = strikeId;
    strikeCache.strikePrice = strikePrice;
    strikeCache.skew = skew;
    strikeCache.boardId = boardCache.id;

    emit StrikeCacheUpdated(strikeCache);

    strikeSkewGWAV[strikeId]._initialize(
      Math.max(Math.min(skew, greekCacheParams.gwavSkewCap), greekCacheParams.gwavSkewFloor),
      block.timestamp
    );

    emit StrikeSkewUpdated(strikeCache.id, skew, globalCache.maxSkewVariance);

    boardCache.strikes.push(strikeId);
  }

  //////////////////////////////////////////////
  // Updating exposure/getting option pricing //
  //////////////////////////////////////////////

  /**
   * @notice During a trade, updates the exposure of the given strike, board and global state. Computes the cost of the
   * trade and returns it to the OptionMarketPricer.
   * @return pricing The final price of the option to be paid for by the user. This could use marketVol or shockVol,
   * depending on the trade executed.
   */
  function updateStrikeExposureAndGetPrice(
    OptionMarket.Strike memory strike,
    OptionMarket.TradeParameters memory trade,
    uint iv,
    uint skew,
    bool isPostCutoff
  ) external onlyOptionMarketPricer returns (TradePricing memory pricing) {
    StrikeCache storage strikeCache = strikeCaches[strike.id];
    OptionBoardCache storage boardCache = boardCaches[strikeCache.boardId];

    _updateBoardIv(boardCache, iv);
    _updateStrikeSkew(boardCache, strikeCache, skew);

    pricing = _updateStrikeExposureAndGetPrice(
      strikeCache,
      boardCache,
      trade,
      SafeCast.toInt256(strike.longCall) - SafeCast.toInt256(strike.shortCallBase + strike.shortCallQuote),
      SafeCast.toInt256(strike.longPut) - SafeCast.toInt256(strike.shortPut)
    );

    pricing.ivVariance = boardCache.ivVariance;

    // If this is a force close or liquidation, override the option price, delta and volTraded based on pricing for
    // force closes.
    if (trade.isForceClose) {
      (pricing.optionPrice, pricing.volTraded) = getPriceForForceClose(
        trade,
        strike,
        boardCache.expiry,
        iv.multiplyDecimal(skew),
        isPostCutoff
      );
    }

    return pricing;
  }

  /// @dev Updates the exposure of the strike and computes the market black scholes price
  function _updateStrikeExposureAndGetPrice(
    StrikeCache storage strikeCache,
    OptionBoardCache storage boardCache,
    OptionMarket.TradeParameters memory trade,
    int newCallExposure,
    int newPutExposure
  ) internal returns (TradePricing memory pricing) {
    BlackScholes.PricesDeltaStdVega memory pricesDeltaStdVega = BlackScholes
      .BlackScholesInputs({
        timeToExpirySec: _timeToMaturitySeconds(boardCache.expiry),
        volatilityDecimal: boardCache.iv.multiplyDecimal(strikeCache.skew),
        spotDecimal: trade.spotPrice,
        strikePriceDecimal: strikeCache.strikePrice,
        rateDecimal: exchangeAdapter.rateAndCarry(address(optionMarket))
      })
      .pricesDeltaStdVega();

    int strikeOptionValue = (newCallExposure - strikeCache.callExposure).multiplyDecimal(
      SafeCast.toInt256(strikeCache.greeks.callPrice)
    ) + (newPutExposure - strikeCache.putExposure).multiplyDecimal(SafeCast.toInt256(strikeCache.greeks.putPrice));

    int netDeltaDiff = (newCallExposure - strikeCache.callExposure).multiplyDecimal(strikeCache.greeks.callDelta) +
      (newPutExposure - strikeCache.putExposure).multiplyDecimal(strikeCache.greeks.putDelta);

    int netStdVegaDiff = (newCallExposure + newPutExposure - strikeCache.callExposure - strikeCache.putExposure)
      .multiplyDecimal(SafeCast.toInt256(strikeCache.greeks.stdVega));

    strikeCache.callExposure = newCallExposure;
    strikeCache.putExposure = newPutExposure;
    boardCache.netGreeks.netOptionValue += strikeOptionValue;
    boardCache.netGreeks.netDelta += netDeltaDiff;
    boardCache.netGreeks.netStdVega += netStdVegaDiff;

    // The AMM's net std vega is opposite to the global sum of user's std vega
    pricing.preTradeAmmNetStdVega = -globalCache.netGreeks.netStdVega;

    globalCache.netGreeks.netOptionValue += strikeOptionValue;
    globalCache.netGreeks.netDelta += netDeltaDiff;
    globalCache.netGreeks.netStdVega += netStdVegaDiff;

    pricing.optionPrice = (trade.optionType != OptionMarket.OptionType.LONG_PUT &&
      trade.optionType != OptionMarket.OptionType.SHORT_PUT_QUOTE)
      ? pricesDeltaStdVega.callPrice
      : pricesDeltaStdVega.putPrice;
    // AMM's net positions are the inverse of the user's net position
    pricing.postTradeAmmNetStdVega = -globalCache.netGreeks.netStdVega;
    pricing.callDelta = pricesDeltaStdVega.callDelta;
    pricing.volTraded = boardCache.iv.multiplyDecimal(strikeCache.skew);
    pricing.vega = pricesDeltaStdVega.vega;

    emit StrikeCacheUpdated(strikeCache);
    emit BoardCacheUpdated(boardCache);
    emit GlobalCacheUpdated(globalCache);

    return pricing;
  }

  /////////////////////////////////////
  // Liquidation/Force Close pricing //
  /////////////////////////////////////

  /**
   * @notice Calculate price paid by the user to forceClose an options position
   * 
   * @param trade TradeParameter as defined in OptionMarket
   * @param strike strikes details (including total exposure)
   * @param expiry expiry of option
   * @param newVol volatility post slippage as determined in `OptionTokOptionMarketPriceren.ivImpactForTrade()`
   * @param isPostCutoff flag for whether order is closer to expiry than postCutoff param.

   * @return optionPrice premium to charge for close order (excluding fees added in OptionMarketPricer)
   * @return forceCloseVol volatility used to calculate optionPrice
   */
  function getPriceForForceClose(
    OptionMarket.TradeParameters memory trade,
    OptionMarket.Strike memory strike,
    uint expiry,
    uint newVol,
    bool isPostCutoff
  ) public view returns (uint optionPrice, uint forceCloseVol) {
    forceCloseVol = _getGWAVVolWithOverride(
      strike.boardId,
      strike.id,
      forceCloseParams.ivGWAVPeriod,
      forceCloseParams.skewGWAVPeriod
    );

    if (trade.tradeDirection == OptionMarket.TradeDirection.CLOSE) {
      // If the tradeDirection is a close, we know the user force closed.
      if (trade.isBuy) {
        // closing a short - maximise vol
        forceCloseVol = Math.max(forceCloseVol, newVol);
        forceCloseVol = isPostCutoff
          ? forceCloseVol.multiplyDecimal(forceCloseParams.shortPostCutoffVolShock)
          : forceCloseVol.multiplyDecimal(forceCloseParams.shortVolShock);
      } else {
        // closing a long - minimise vol
        forceCloseVol = Math.min(forceCloseVol, newVol);
        forceCloseVol = isPostCutoff
          ? forceCloseVol.multiplyDecimal(forceCloseParams.longPostCutoffVolShock)
          : forceCloseVol.multiplyDecimal(forceCloseParams.longVolShock);
      }
    } else {
      // Otherwise it can only be a liquidation
      forceCloseVol = isPostCutoff
        ? forceCloseVol.multiplyDecimal(forceCloseParams.liquidatePostCutoffVolShock)
        : forceCloseVol.multiplyDecimal(forceCloseParams.liquidateVolShock);
    }

    (uint callPrice, uint putPrice) = BlackScholes
      .BlackScholesInputs({
        timeToExpirySec: _timeToMaturitySeconds(expiry),
        volatilityDecimal: forceCloseVol,
        spotDecimal: trade.spotPrice,
        strikePriceDecimal: strike.strikePrice,
        rateDecimal: exchangeAdapter.rateAndCarry(address(optionMarket))
      })
      .optionPrices();

    uint price = (trade.optionType == OptionMarket.OptionType.LONG_PUT ||
      trade.optionType == OptionMarket.OptionType.SHORT_PUT_QUOTE)
      ? putPrice
      : callPrice;

    if (trade.isBuy) {
      // In the case a short is being closed, ensure the AMM doesn't overpay by charging parity + some excess
      uint parity = _getParity(strike.strikePrice, trade.spotPrice, trade.optionType);
      uint minPrice = parity +
        trade.spotPrice.multiplyDecimal(
          trade.tradeDirection == OptionMarket.TradeDirection.CLOSE
            ? forceCloseParams.shortSpotMin
            : forceCloseParams.liquidateSpotMin
        );
      price = Math.max(price, minPrice);
    }

    return (price, forceCloseVol);
  }

  function _getGWAVVolWithOverride(
    uint boardId,
    uint strikeId,
    uint overrideIvPeriod,
    uint overrideSkewPeriod
  ) internal view returns (uint gwavVol) {
    uint gwavIV = boardIVGWAV[boardId].getGWAVForPeriod(overrideIvPeriod, 0);
    uint strikeGWAVSkew = strikeSkewGWAV[strikeId].getGWAVForPeriod(overrideSkewPeriod, 0);
    return gwavIV.multiplyDecimal(strikeGWAVSkew);
  }

  /**
   * @notice Gets minimum collateral requirement for the specified option
   *
   * @param optionType The option type
   * @param strikePrice The strike price of the option
   * @param expiry The expiry of the option
   * @param spotPrice The price of the underlying asset
   * @param amount The size of the option
   */
  function getMinCollateral(
    OptionMarket.OptionType optionType,
    uint strikePrice,
    uint expiry,
    uint spotPrice,
    uint amount
  ) external view returns (uint minCollateral) {
    if (amount == 0) {
      return 0;
    }

    // If put, reduce spot by percentage. If call, increase.
    uint shockPrice = (optionType == OptionMarket.OptionType.SHORT_PUT_QUOTE)
      ? spotPrice.multiplyDecimal(minCollatParams.putSpotPriceShock)
      : spotPrice.multiplyDecimal(minCollatParams.callSpotPriceShock);

    uint timeToMaturity = _timeToMaturitySeconds(expiry);

    (uint callPrice, uint putPrice) = BlackScholes
      .BlackScholesInputs({
        timeToExpirySec: timeToMaturity,
        volatilityDecimal: getShockVol(timeToMaturity),
        spotDecimal: shockPrice,
        strikePriceDecimal: strikePrice,
        rateDecimal: exchangeAdapter.rateAndCarry(address(optionMarket))
      })
      .optionPrices();

    uint fullCollat;
    uint volCollat;
    uint staticCollat = minCollatParams.minStaticQuoteCollateral;
    if (optionType == OptionMarket.OptionType.SHORT_CALL_BASE) {
      // Can be more lenient to SHORT_CALL_BASE traders
      volCollat = callPrice.multiplyDecimal(amount).divideDecimal(shockPrice);
      fullCollat = amount;
      staticCollat = minCollatParams.minStaticBaseCollateral;
    } else if (optionType == OptionMarket.OptionType.SHORT_CALL_QUOTE) {
      volCollat = callPrice.multiplyDecimal(amount);
      fullCollat = type(uint).max;
    } else {
      // optionType == OptionMarket.OptionType.SHORT_PUT_QUOTE
      volCollat = putPrice.multiplyDecimal(amount);
      fullCollat = amount.multiplyDecimal(strikePrice);
    }

    return Math.min(Math.max(volCollat, staticCollat), fullCollat);
  }

  /// @notice Gets shock vol (Vol used to compute the minimum collateral requirements for short positions)
  function getShockVol(uint timeToMaturity) public view returns (uint) {
    if (timeToMaturity <= minCollatParams.shockVolPointA) {
      return minCollatParams.shockVolA;
    }
    if (timeToMaturity >= minCollatParams.shockVolPointB) {
      return minCollatParams.shockVolB;
    }

    // Flip a and b so we don't need to convert to int
    return
      minCollatParams.shockVolA -
      (((minCollatParams.shockVolA - minCollatParams.shockVolB) * (timeToMaturity - minCollatParams.shockVolPointA)) /
        (minCollatParams.shockVolPointB - minCollatParams.shockVolPointA));
  }

  //////////////////////////////////////////
  // Update GWAV vol greeks and net greeks //
  //////////////////////////////////////////

  /**
   * @notice Updates the cached greeks for an OptionBoardCache used to calculate:
   * - trading fees
   * - aggregate AMM option value
   * - net delta exposure for proper hedging
   *
   * @param boardId The id of the OptionBoardCache.
   */
  function updateBoardCachedGreeks(uint boardId) public nonReentrant {
    _updateBoardCachedGreeks(
      exchangeAdapter.getSpotPriceForMarket(address(optionMarket), BaseExchangeAdapter.PriceType.REFERENCE),
      boardId
    );
  }

  function _updateBoardCachedGreeks(uint spotPrice, uint boardId) internal {
    OptionBoardCache storage boardCache = boardCaches[boardId];
    if (boardCache.id == 0) {
      revert InvalidBoardId(address(this), boardCache.id);
    }

    if (block.timestamp > boardCache.expiry) {
      revert CannotUpdateExpiredBoard(address(this), boardCache.id, boardCache.expiry, block.timestamp);
    }

    // Zero out the board net greeks and recompute all strikes, adding to the totals
    globalCache.netGreeks.netOptionValue -= boardCache.netGreeks.netOptionValue;
    globalCache.netGreeks.netDelta -= boardCache.netGreeks.netDelta;
    globalCache.netGreeks.netStdVega -= boardCache.netGreeks.netStdVega;

    boardCache.netGreeks.netOptionValue = 0;
    boardCache.netGreeks.netDelta = 0;
    boardCache.netGreeks.netStdVega = 0;

    _updateBoardIvVariance(boardCache);
    uint navGWAVbaseIv = boardIVGWAV[boardId].getGWAVForPeriod(greekCacheParams.optionValueIvGWAVPeriod, 0);

    uint strikesLen = boardCache.strikes.length;
    for (uint i = 0; i < strikesLen; ++i) {
      StrikeCache storage strikeCache = strikeCaches[boardCache.strikes[i]];
      _updateStrikeSkewVariance(strikeCache);

      // update variance for strike skew
      uint strikeNavGWAVSkew = strikeSkewGWAV[strikeCache.id].getGWAVForPeriod(
        greekCacheParams.optionValueSkewGWAVPeriod,
        0
      );
      uint navGWAVvol = navGWAVbaseIv.multiplyDecimal(strikeNavGWAVSkew);

      _updateStrikeCachedGreeks(strikeCache, boardCache, spotPrice, navGWAVvol);
    }

    _updateMaxSkewVariance(boardCache);
    _updateMaxIvVariance();

    boardCache.updatedAt = block.timestamp;
    boardCache.updatedAtPrice = spotPrice;

    _updateGlobalLastUpdatedAt();

    emit BoardIvUpdated(boardCache.id, boardCache.iv, globalCache.maxIvVariance);
    emit BoardCacheUpdated(boardCache);
    emit GlobalCacheUpdated(globalCache);
  }

  /**
   * @dev Updates an StrikeCache using TWAP.
   * Assumes board has been zeroed out before updating all strikes at once
   *
   * @param strikeCache The StrikeCache.
   * @param boardCache The OptionBoardCache.
   */
  function _updateStrikeCachedGreeks(
    StrikeCache storage strikeCache,
    OptionBoardCache storage boardCache,
    uint spotPrice,
    uint navGWAVvol
  ) internal {
    BlackScholes.PricesDeltaStdVega memory pricesDeltaStdVega = BlackScholes
      .BlackScholesInputs({
        timeToExpirySec: _timeToMaturitySeconds(boardCache.expiry),
        volatilityDecimal: navGWAVvol,
        spotDecimal: spotPrice,
        strikePriceDecimal: strikeCache.strikePrice,
        rateDecimal: exchangeAdapter.rateAndCarry(address(optionMarket))
      })
      .pricesDeltaStdVega();

    strikeCache.greeks.callPrice = pricesDeltaStdVega.callPrice;
    strikeCache.greeks.putPrice = pricesDeltaStdVega.putPrice;
    strikeCache.greeks.callDelta = pricesDeltaStdVega.callDelta;
    strikeCache.greeks.putDelta = pricesDeltaStdVega.putDelta;
    strikeCache.greeks.stdVega = pricesDeltaStdVega.stdVega;

    // only update board/global if exposure present
    if (strikeCache.callExposure != 0 || strikeCache.putExposure != 0) {
      int strikeOptionValue = (strikeCache.callExposure).multiplyDecimal(
        SafeCast.toInt256(strikeCache.greeks.callPrice)
      ) + (strikeCache.putExposure).multiplyDecimal(SafeCast.toInt256(strikeCache.greeks.putPrice));

      int strikeNetDelta = strikeCache.callExposure.multiplyDecimal(strikeCache.greeks.callDelta) +
        strikeCache.putExposure.multiplyDecimal(strikeCache.greeks.putDelta);

      int strikeNetStdVega = (strikeCache.callExposure + strikeCache.putExposure).multiplyDecimal(
        SafeCast.toInt256(strikeCache.greeks.stdVega)
      );

      boardCache.netGreeks.netOptionValue += strikeOptionValue;
      boardCache.netGreeks.netDelta += strikeNetDelta;
      boardCache.netGreeks.netStdVega += strikeNetStdVega;

      globalCache.netGreeks.netOptionValue += strikeOptionValue;
      globalCache.netGreeks.netDelta += strikeNetDelta;
      globalCache.netGreeks.netStdVega += strikeNetStdVega;
    }

    emit StrikeCacheUpdated(strikeCache);
    emit StrikeSkewUpdated(strikeCache.id, strikeCache.skew, globalCache.maxSkewVariance);
  }

  /// @dev Updates global `lastUpdatedAt`.
  function _updateGlobalLastUpdatedAt() internal {
    OptionBoardCache storage boardCache = boardCaches[liveBoards[0]];
    uint minUpdatedAt = boardCache.updatedAt;
    uint minUpdatedAtPrice = boardCache.updatedAtPrice;
    uint maxUpdatedAtPrice = boardCache.updatedAtPrice;
    uint maxSkewVariance = boardCache.maxSkewVariance;
    uint maxIvVariance = boardCache.ivVariance;

    uint liveBoardsLen = liveBoards.length;
    for (uint i = 1; i < liveBoardsLen; ++i) {
      boardCache = boardCaches[liveBoards[i]];
      if (boardCache.updatedAt < minUpdatedAt) {
        minUpdatedAt = boardCache.updatedAt;
      }
      if (boardCache.updatedAtPrice < minUpdatedAtPrice) {
        minUpdatedAtPrice = boardCache.updatedAtPrice;
      }
      if (boardCache.updatedAtPrice > maxUpdatedAtPrice) {
        maxUpdatedAtPrice = boardCache.updatedAtPrice;
      }
      if (boardCache.maxSkewVariance > maxSkewVariance) {
        maxSkewVariance = boardCache.maxSkewVariance;
      }
      if (boardCache.ivVariance > maxIvVariance) {
        maxIvVariance = boardCache.ivVariance;
      }
    }

    globalCache.minUpdatedAt = minUpdatedAt;
    globalCache.minUpdatedAtPrice = minUpdatedAtPrice;
    globalCache.maxUpdatedAtPrice = maxUpdatedAtPrice;
    globalCache.maxSkewVariance = maxSkewVariance;
    globalCache.maxIvVariance = maxIvVariance;
  }

  /////////////////////////
  // Updating GWAV values //
  /////////////////////////

  /// @dev updates baseIv for a given board, updating the baseIv gwav
  function _updateBoardIv(OptionBoardCache storage boardCache, uint newIv) internal {
    boardCache.iv = newIv;
    boardIVGWAV[boardCache.id]._write(newIv, block.timestamp);
    _updateBoardIvVariance(boardCache);
    _updateMaxIvVariance();

    emit BoardIvUpdated(boardCache.id, newIv, globalCache.maxIvVariance);
  }

  /// @dev updates skew for a given strike, updating the skew gwav
  function _updateStrikeSkew(
    OptionBoardCache storage boardCache,
    StrikeCache storage strikeCache,
    uint newSkew
  ) internal {
    strikeCache.skew = newSkew;

    strikeSkewGWAV[strikeCache.id]._write(
      Math.max(Math.min(newSkew, greekCacheParams.gwavSkewCap), greekCacheParams.gwavSkewFloor),
      block.timestamp
    );
    // Update variance
    _updateStrikeSkewVariance(strikeCache);
    _updateMaxSkewVariance(boardCache);

    emit StrikeSkewUpdated(strikeCache.id, newSkew, globalCache.maxSkewVariance);
  }

  /// @dev updates maxIvVariance across all boards
  function _updateMaxIvVariance() internal {
    uint maxIvVariance = boardCaches[liveBoards[0]].ivVariance;
    uint liveBoardsLen = liveBoards.length;
    for (uint i = 1; i < liveBoardsLen; ++i) {
      if (boardCaches[liveBoards[i]].ivVariance > maxIvVariance) {
        maxIvVariance = boardCaches[liveBoards[i]].ivVariance;
      }
    }
    globalCache.maxIvVariance = maxIvVariance;
  }

  /// @dev updates skewVariance for strike, used to trigger CBs and charge varianceFees
  function _updateStrikeSkewVariance(StrikeCache storage strikeCache) internal {
    uint strikeVarianceGWAVSkew = strikeSkewGWAV[strikeCache.id].getGWAVForPeriod(
      greekCacheParams.varianceSkewGWAVPeriod,
      0
    );

    if (strikeVarianceGWAVSkew >= strikeCache.skew) {
      strikeCache.skewVariance = strikeVarianceGWAVSkew - strikeCache.skew;
    } else {
      strikeCache.skewVariance = strikeCache.skew - strikeVarianceGWAVSkew;
    }
  }

  /// @dev updates ivVariance for board, used to trigger CBs and charge varianceFees
  function _updateBoardIvVariance(OptionBoardCache storage boardCache) internal {
    uint boardVarianceGWAVIv = boardIVGWAV[boardCache.id].getGWAVForPeriod(greekCacheParams.varianceIvGWAVPeriod, 0);

    if (boardVarianceGWAVIv >= boardCache.iv) {
      boardCache.ivVariance = boardVarianceGWAVIv - boardCache.iv;
    } else {
      boardCache.ivVariance = boardCache.iv - boardVarianceGWAVIv;
    }
  }

  /// @dev updates maxSkewVariance for the board and across all strikes
  function _updateMaxSkewVariance(OptionBoardCache storage boardCache) internal {
    uint maxBoardSkewVariance = strikeCaches[boardCache.strikes[0]].skewVariance;
    uint strikesLen = boardCache.strikes.length;
    for (uint i = 1; i < strikesLen; ++i) {
      if (strikeCaches[boardCache.strikes[i]].skewVariance > maxBoardSkewVariance) {
        maxBoardSkewVariance = strikeCaches[boardCache.strikes[i]].skewVariance;
      }
    }
    boardCache.maxSkewVariance = maxBoardSkewVariance;

    uint maxSkewVariance = boardCaches[liveBoards[0]].maxSkewVariance;
    uint liveBoardsLen = liveBoards.length;

    for (uint i = 1; i < liveBoardsLen; ++i) {
      if (boardCaches[liveBoards[i]].maxSkewVariance > maxSkewVariance) {
        maxSkewVariance = boardCaches[liveBoards[i]].maxSkewVariance;
      }
    }
    globalCache.maxSkewVariance = maxSkewVariance;
  }

  //////////////////////////
  // Stale cache checking //
  //////////////////////////

  /**
   * @notice returns `true` if even one board not updated within `staleUpdateDuration` or
   *         if spot price moves up/down beyond `acceptablePriceMovement`
   */

  function isGlobalCacheStale(uint spotPrice) external view returns (bool) {
    if (liveBoards.length == 0) {
      return false;
    } else {
      return (_isUpdatedAtTimeStale(globalCache.minUpdatedAt) ||
        !_isPriceMoveAcceptable(globalCache.minUpdatedAtPrice, spotPrice) ||
        !_isPriceMoveAcceptable(globalCache.maxUpdatedAtPrice, spotPrice));
    }
  }

  /**
   * @notice returns `true` if board not updated within `staleUpdateDuration` or
   *         if spot price moves up/down beyond `acceptablePriceMovement`
   */
  function isBoardCacheStale(uint boardId) external view returns (bool) {
    uint spotPrice = exchangeAdapter.getSpotPriceForMarket(
      address(optionMarket),
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    OptionBoardCache memory boardCache = boardCaches[boardId];
    if (boardCache.id == 0) {
      revert InvalidBoardId(address(this), boardCache.id);
    }
    return (_isUpdatedAtTimeStale(boardCache.updatedAt) ||
      !_isPriceMoveAcceptable(boardCache.updatedAtPrice, spotPrice));
  }

  /**
   * @notice Check if the price move of base asset renders the cache stale.
   *
   * @param pastPrice The previous price.
   * @param currentPrice The current price.
   */
  function _isPriceMoveAcceptable(uint pastPrice, uint currentPrice) internal view returns (bool) {
    uint acceptablePriceMovement = pastPrice.multiplyDecimal(greekCacheParams.acceptableSpotPricePercentMove);
    if (currentPrice > pastPrice) {
      return (currentPrice - pastPrice) < acceptablePriceMovement;
    } else {
      return (pastPrice - currentPrice) < acceptablePriceMovement;
    }
  }

  /**
   * @notice Checks if board updated within `staleUpdateDuration`.
   *
   * @param updatedAt The time of the last update.
   */
  function _isUpdatedAtTimeStale(uint updatedAt) internal view returns (bool) {
    // This can be more complex than just checking the item wasn't updated in the last two hours
    return _getSecondsTo(updatedAt, block.timestamp) > greekCacheParams.staleUpdateDuration;
  }

  /////////////////////////////
  // External View functions //
  /////////////////////////////

  /// @notice Get the current cached global netDelta exposure.
  function getGlobalNetDelta() external view returns (int) {
    return globalCache.netGreeks.netDelta;
  }

  /// @notice Get the current global net option value
  function getGlobalOptionValue() external view returns (int) {
    return globalCache.netGreeks.netOptionValue;
  }

  /// @notice Returns the BoardGreeksView struct given a specific boardId
  function getBoardGreeksView(uint boardId) external view returns (BoardGreeksView memory) {
    uint strikesLen = boardCaches[boardId].strikes.length;

    StrikeGreeks[] memory strikeGreeks = new StrikeGreeks[](strikesLen);
    uint[] memory skewGWAVs = new uint[](strikesLen);
    for (uint i = 0; i < strikesLen; ++i) {
      strikeGreeks[i] = strikeCaches[boardCaches[boardId].strikes[i]].greeks;
      skewGWAVs[i] = strikeSkewGWAV[boardCaches[boardId].strikes[i]].getGWAVForPeriod(
        forceCloseParams.skewGWAVPeriod,
        0
      );
    }
    return
      BoardGreeksView({
        boardGreeks: boardCaches[boardId].netGreeks,
        ivGWAV: boardIVGWAV[boardId].getGWAVForPeriod(forceCloseParams.ivGWAVPeriod, 0),
        strikeGreeks: strikeGreeks,
        skewGWAVs: skewGWAVs
      });
  }

  /// @notice Get StrikeCache given a specific strikeId
  function getStrikeCache(uint strikeId) external view returns (StrikeCache memory) {
    return (strikeCaches[strikeId]);
  }

  /// @notice Get OptionBoardCache given a specific boardId
  function getOptionBoardCache(uint boardId) external view returns (OptionBoardCache memory) {
    return (boardCaches[boardId]);
  }

  /// @notice Get the global cache
  function getGlobalCache() external view returns (GlobalCache memory) {
    return globalCache;
  }

  /// @notice Returns ivGWAV for a given boardId and GWAV time interval
  function getIvGWAV(uint boardId, uint secondsAgo) external view returns (uint ivGWAV) {
    return boardIVGWAV[boardId].getGWAVForPeriod(secondsAgo, 0);
  }

  /// @notice Returns skewGWAV for a given strikeId and GWAV time interval
  function getSkewGWAV(uint strikeId, uint secondsAgo) external view returns (uint skewGWAV) {
    return strikeSkewGWAV[strikeId].getGWAVForPeriod(secondsAgo, 0);
  }

  /// @notice Get the GreekCacheParameters
  function getGreekCacheParams() external view returns (GreekCacheParameters memory) {
    return greekCacheParams;
  }

  /// @notice Get the ForceCloseParamters
  function getForceCloseParams() external view returns (ForceCloseParameters memory) {
    return forceCloseParams;
  }

  /// @notice Get the MinCollateralParamters
  function getMinCollatParams() external view returns (MinCollateralParameters memory) {
    return minCollatParams;
  }

  ////////////////////////////
  // Utility/Math functions //
  ////////////////////////////

  /// @dev Calculate option payout on expiry given a strikePrice, spot on expiry and optionType.
  function _getParity(
    uint strikePrice,
    uint spot,
    OptionMarket.OptionType optionType
  ) internal pure returns (uint parity) {
    int diff = (optionType == OptionMarket.OptionType.LONG_PUT || optionType == OptionMarket.OptionType.SHORT_PUT_QUOTE)
      ? SafeCast.toInt256(strikePrice) - SafeCast.toInt256(spot)
      : SafeCast.toInt256(spot) - SafeCast.toInt256(strikePrice);

    parity = diff > 0 ? uint(diff) : 0;
  }

  /// @dev Returns time to maturity for a given expiry.
  function _timeToMaturitySeconds(uint expiry) internal view returns (uint) {
    return _getSecondsTo(block.timestamp, expiry);
  }

  /// @dev Returns the difference in seconds between two dates.
  function _getSecondsTo(uint fromTime, uint toTime) internal pure returns (uint) {
    if (toTime > fromTime) {
      return toTime - fromTime;
    }
    return 0;
  }

  ///////////////
  // Modifiers //
  ///////////////
  modifier onlyOptionMarket() {
    if (msg.sender != address(optionMarket)) {
      revert OnlyOptionMarket(address(this), msg.sender, address(optionMarket));
    }
    _;
  }

  modifier onlyOptionMarketPricer() {
    if (msg.sender != address(optionMarketPricer)) {
      revert OnlyOptionMarketPricer(address(this), msg.sender, address(optionMarketPricer));
    }
    _;
  }

  ////////////
  // Events //
  ////////////
  event GreekCacheParametersSet(GreekCacheParameters params);
  event ForceCloseParametersSet(ForceCloseParameters params);
  event MinCollateralParametersSet(MinCollateralParameters params);

  event StrikeCacheUpdated(StrikeCache strikeCache);
  event BoardCacheUpdated(OptionBoardCache boardCache);
  event GlobalCacheUpdated(GlobalCache globalCache);

  event BoardCacheRemoved(uint boardId);
  event StrikeCacheRemoved(uint strikeId);
  event BoardIvUpdated(uint boardId, uint newIv, uint globalMaxIvVariance);
  event StrikeSkewUpdated(uint strikeId, uint newSkew, uint globalMaxSkewVariance);

  ////////////
  // Errors //
  ////////////
  // Admin
  error InvalidGreekCacheParameters(address thrower, GreekCacheParameters greekCacheParams);
  error InvalidForceCloseParameters(address thrower, ForceCloseParameters forceCloseParams);
  error InvalidMinCollatParams(address thrower, MinCollateralParameters minCollatParams);

  // Board related
  error BoardStrikeLimitExceeded(address thrower, uint boardId, uint newStrikesLength, uint maxStrikesPerBoard);
  error InvalidBoardId(address thrower, uint boardId);
  error CannotUpdateExpiredBoard(address thrower, uint boardId, uint expiry, uint currentTimestamp);

  // Access
  error OnlyOptionMarket(address thrower, address caller, address optionMarket);
  error OnlyOptionMarketPricer(address thrower, address caller, address optionMarketPricer);
}
