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
  
  //SPDX-License-Identifier:ISC
pragma solidity 0.8.16;

// Libraries
import "../libraries/GWAV.sol";
import "../libraries/BlackScholes.sol";
import "../synthetix/DecimalMath.sol";

// Inherited
import "Lyra-Finance/openzeppelin-contracts-4.4.1/access/Ownable.sol";

// Interfaces
import "Lyra-Finance/openzeppelin-contracts-4.4.1/token/ERC20/IERC20.sol";
import "../interfaces/IOptionToken.sol";
import "../interfaces/IOptionMarket.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IShortCollateral.sol";
import "../interfaces/IOptionGreekCache.sol";
import "../interfaces/ISynthetixAdapter.sol";
import "../interfaces/IDelegateApprovals.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IGWAVOracle.sol";
import "../interfaces/ILyraRegistry.sol";
import "./BasicFeeCounter.sol";

/**
 * @title LyraAdapter
 * @author Lyra
 * @dev Provides helpful functions for any Lyra trading/market data/vault related actions in one contract
 *      To earn trading rewards, integrators must request to be whitelisted by Lyra
 */

contract LyraAdapter is Ownable {
  using DecimalMath for uint;

  ///////////////////////
  // Abstract Contract //
  ///////////////////////

  struct Strike {
    // strike listing identifier
    uint id;
    // expiry of strike
    uint expiry;
    // strike price
    uint strikePrice;
    // volatility component specific to the strike listing (boardIv * skew = vol of strike)
    uint skew;
    // volatility component specific to the board (boardIv * skew = vol of strike)
    uint boardIv;
  }

  struct Board {
    // board identifier
    uint id;
    // expiry of all strikes belong to
    uint expiry;
    // volatility component specific to the board (boardIv * skew = vol of strike)
    uint boardIv;
    // all strikes belonging to board
    uint[] strikeIds;
  }

  struct OptionPosition {
    // OptionToken ERC721 identifier for position
    uint positionId;
    // strike identifier
    uint strikeId;
    // LONG_CALL | LONG_PUT | SHORT_CALL_BASE | SHORT_CALL_QUOTE | SHORT_PUT_QUOTE
    OptionType optionType;
    // number of options contract owned by position
    uint amount;
    // collateral held in position (only applies to shorts)
    uint collateral;
    // EMPTY | ACTIVE | CLOSED | LIQUIDATED | SETTLED | MERGED
    PositionState state;
  }

  enum OptionType {
    LONG_CALL,
    LONG_PUT,
    SHORT_CALL_BASE,
    SHORT_CALL_QUOTE,
    SHORT_PUT_QUOTE
  }

  enum PositionState {
    EMPTY,
    ACTIVE,
    CLOSED,
    LIQUIDATED,
    SETTLED,
    MERGED
  }

  struct TradeInputParameters {
    // id of strike
    uint strikeId;
    // OptionToken ERC721 id for position (set to 0 for new positions)
    uint positionId;
    // number of sub-orders to break order into (reduces slippage)
    uint iterations;
    // type of option to trade
    OptionType optionType;
    // number of contracts to trade
    uint amount;
    // final amount of collateral to leave in OptionToken position
    uint setCollateralTo;
    // revert trade if totalCost is below this value
    uint minTotalCost;
    // revert trade if totalCost is above this value
    uint maxTotalCost;
    // address of recipient for Lyra trading rewards (must request Lyra to be whitelisted for rewards)
    address rewardRecipient;
  }

  struct TradeResult {
    // OptionToken ERC721 id for position
    uint positionId;
    // total option cost paid/received during trade including premium and totalFee
    uint totalCost;
    // trading fees as determined in OptionMarketPricer.sol
    uint totalFee;
  }

  struct Liquidity {
    // Amount of liquidity available for option collateral and premiums
    uint freeLiquidity;
    // Amount of liquidity available for withdrawals - different to freeLiquidity
    uint burnableLiquidity;
    // Amount of liquidity reserved for long options sold to traders
    uint reservedCollatLiquidity;
    // Portion of liquidity reserved for delta hedging (quote outstanding)
    uint pendingDeltaLiquidity;
    // Current value of delta hedge
    uint usedDeltaLiquidity;
    // Net asset value, including everything and netOptionValue
    uint NAV;
  }

  struct MarketParams {
    // The amount of options traded to move baseIv for the board up or down 1 point (depending on trade direction)
    uint standardSize;
    // Determines relative move of skew for a given strike compared to shift in baseIv
    uint skewAdjustmentParam;
    // Interest/risk free rate used in BlackScholes
    int rateAndCarry;
    // Delta cutoff past which options can be traded (optionD > minD && optionD < 1 - minD) - can use forceClose to bypass
    int deltaCutOff;
    // Time when trading closes - can use forceClose to bypass
    uint tradingCutoff;
    // Delta cutoff at which forceClose can be called (optionD < minD || optionD > 1 - minD) - using call delta
    int minForceCloseDelta;
  }

  struct ExchangeRateParams {
    // current snx oracle base price
    uint spotPrice;
    // snx spot exchange rate from quote to base
    uint quoteBaseFeeRate;
    // snx spot exchange rate from base to quote
    uint baseQuoteFeeRate;
  }

  ///////////////
  // Variables //
  ///////////////

  ILyraRegistry public lyraRegistry;
  ISynthetixAdapter internal synthetixAdapter;
  IOptionMarket public optionMarket;
  IOptionToken public optionToken;
  ILiquidityPool public liquidityPool;
  IShortCollateral public shortCollateral;
  IGWAVOracle public gwavOracle;
  IOptionMarketPricer public optionPricer;
  IOptionGreekCache public greekCache;
  IERC20 public quoteAsset;
  IERC20 public baseAsset;

  ICurve public curveSwap;
  BasicFeeCounter public feeCounter;
  bytes32 private constant SNX_ADAPTER = "SYNTHETIX_ADAPTER";

  ///////////
  // Admin //
  ///////////

  constructor() Ownable() {}

  /**
   * @dev Assigns all lyra contracts

   * @param _lyraRegistry LyraRegistry address which holds latest market and global addressess
   * @param _optionMarket OptionMarket address
   * @param _curveSwap Curve pool address for swapping sUSD and other stables via `exchange_with_best_rate`
   * @param _feeCounter Fee counter addressu used to determine Lyra trading rewards
   */

  function setLyraAddresses(
    address _lyraRegistry,
    address _optionMarket,
    address _curveSwap,
    address _feeCounter
  ) public onlyOwner {
    // remove allowance from old assets
    if (address(quoteAsset) != address(0)) {
      quoteAsset.approve(address(optionMarket), 0);
    }
    if (address(baseAsset) != address(0)) {
      baseAsset.approve(address(optionMarket), 0);
    }

    optionMarket = IOptionMarket(_optionMarket);

    // Get market & global addresses via LyraRegistry
    lyraRegistry = ILyraRegistry(_lyraRegistry);
    synthetixAdapter = ISynthetixAdapter(lyraRegistry.getGlobalAddress(SNX_ADAPTER));
    _assignLyraRegistryMarketAddresses();

    // assign curve and Lyra reward counter
    curveSwap = ICurve(_curveSwap);
    feeCounter = BasicFeeCounter(_feeCounter);

    // Do approvals
    IDelegateApprovals(synthetixAdapter.delegateApprovals()).approveExchangeOnBehalf(address(synthetixAdapter));
    quoteAsset.approve(address(optionMarket), type(uint).max);
    baseAsset.approve(address(optionMarket), type(uint).max);
  }

  /// @notice In case of an update to the synthetix contract that revokes the approval
  function updateDelegateApproval() external onlyOwner {
    IDelegateApprovals(synthetixAdapter.delegateApprovals()).approveExchangeOnBehalf(address(synthetixAdapter));
  }

  ////////////////////
  // Market Actions //
  ////////////////////

  /**
   * @notice Attempts to open positions within cost bounds.
   * @dev If a positionId is specified params.amount will be added to the position
   * @dev params.amount can be zero when adjusting an existing position
   *
   * @param params The parameters for the requested trade
   */
  function _openPosition(TradeInputParameters memory params) internal returns (TradeResult memory tradeResult) {
    IOptionMarket.Result memory result = optionMarket.openPosition(_convertParams(params));
    if (params.rewardRecipient != address(0)) {
      feeCounter.trackFee(
        address(optionMarket),
        params.rewardRecipient,
        _convertParams(params).amount,
        result.totalCost,
        result.totalFee
      );
    }
    return TradeResult({positionId: result.positionId, totalCost: result.totalCost, totalFee: result.totalFee});
  }

  /**
   * @notice Attempt close under normal condition or forceClose
   *          if position is outside of delta or too close to expiry.
   *
   * @param params The parameters for the requested trade
   */
  function _closeOrForceClosePosition(
    TradeInputParameters memory params
  ) internal returns (TradeResult memory tradeResult) {
    if (!_isOutsideDeltaCutoff(params.strikeId) && !_isWithinTradingCutoff(params.strikeId)) {
      return _closePosition(params);
    } else {
      // will pay less competitive price to close position but bypasses Lyra delta/trading cutoffs
      return _forceClosePosition(params);
    }
  }

  /**
   * @notice Attempts to close an existing position within cost bounds.
   * @dev If a positionId is specified params.amount will be subtracted from the position
   * @dev params.amount can be zero when adjusting an existing position
   *
   * @param params The parameters for the requested trade
   */
  function _closePosition(TradeInputParameters memory params) internal returns (TradeResult memory tradeResult) {
    IOptionMarket.Result memory result = optionMarket.closePosition(_convertParams(params));
    if (params.rewardRecipient != address(0)) {
      feeCounter.trackFee(
        address(optionMarket),
        params.rewardRecipient,
        _convertParams(params).amount,
        result.totalCost,
        result.totalFee
      );
    }
    return TradeResult({positionId: result.positionId, totalCost: result.totalCost, totalFee: result.totalFee});
  }

  /**
   * @notice Attempts to close an existing position outside of the delta or trading cutoffs (as specified in MarketParams).
   * @dev This market action will charge higher fees than the standard `closePosition()`
   *
   * @param params The parameters for the requested trade
   */
  function _forceClosePosition(TradeInputParameters memory params) internal returns (TradeResult memory tradeResult) {
    IOptionMarket.Result memory result = optionMarket.forceClosePosition(_convertParams(params));
    if (params.rewardRecipient != address(0)) {
      feeCounter.trackFee(
        address(optionMarket),
        params.rewardRecipient,
        _convertParams(params).amount,
        result.totalCost,
        result.totalFee
      );
    }
    return TradeResult({positionId: result.positionId, totalCost: result.totalCost, totalFee: result.totalFee});
  }

  //////////////
  // Exchange //
  //////////////

  /// @notice Exchange an exact amount of quote for a minimum amount of base (revert otherwise)
  function _exchangeFromExactQuote(uint amountQuote, uint minBaseReceived) internal returns (uint baseReceived) {
    baseReceived = synthetixAdapter.exchangeFromExactQuote(address(optionMarket), amountQuote);
    if (baseReceived < minBaseReceived) {
      revert ExchangerBaseReceivedTooLow(address(this), minBaseReceived, baseReceived);
    }
  }

  /// @notice Exchange to an exact amount of quote for a maximum amount of base (revert otherwise)
  function _exchangeToExactQuote(uint amountQuote, uint maxBaseUsed) internal returns (uint quoteReceived) {
    ISynthetixAdapter.ExchangeParams memory exchangeParams = synthetixAdapter.getExchangeParams(address(optionMarket));
    (, quoteReceived) = synthetixAdapter.exchangeToExactQuoteWithLimit(
      exchangeParams,
      address(optionMarket),
      amountQuote,
      maxBaseUsed
    );
  }

  /// @notice Exchange an exact amount of base for a minimum amount of quote (revert otherwise)
  function _exchangeFromExactBase(uint amountBase, uint minQuoteReceived) internal returns (uint quoteReceived) {
    quoteReceived = synthetixAdapter.exchangeFromExactBase(address(optionMarket), amountBase);
    if (quoteReceived < minQuoteReceived) {
      revert ExchangerQuoteReceivedTooLow(address(this), minQuoteReceived, quoteReceived);
    }
  }

  /// @notice Exchange to an exact amount of base for a maximum amount of quote (revert otherwise)
  function _exchangeToExactBase(uint amountBase, uint maxQuoteUsed) internal returns (uint baseReceived) {
    ISynthetixAdapter.ExchangeParams memory exchangeParams = synthetixAdapter.getExchangeParams(address(optionMarket));
    (, baseReceived) = synthetixAdapter.exchangeToExactBaseWithLimit(
      exchangeParams,
      address(optionMarket),
      amountBase,
      maxQuoteUsed
    );
  }

  /// @notice Returns the ExchangeParams for current market.
  function _getExchangeParams() internal view returns (ExchangeRateParams memory) {
    ISynthetixAdapter.ExchangeParams memory params = synthetixAdapter.getExchangeParams(address(optionMarket));
    return
      ExchangeRateParams({
        spotPrice: params.spotPrice,
        quoteBaseFeeRate: params.quoteBaseFeeRate,
        baseQuoteFeeRate: params.baseQuoteFeeRate
      });
  }

  /**
   * @notice WARNING: ENSURE CURVE HAS SUFFICIENT sUSD LIQUIDITY
   *         Exchange between stables within the curveSwap sUSD pool.
   *
   * @param from start ERC20
   * @param to destination ERC20
   * @param amount amount of "from" currency to exchange
   * @param expected minimum expected amount of "to" currency
   * @param receiver address of recipient of "to" currency
   *
   * @return amountOut received amount
   */
  function _swapStables(
    address from,
    address to,
    uint amount,
    uint expected,
    address receiver
  ) internal returns (uint amountOut) {
    amountOut = curveSwap.exchange_with_best_rate(from, to, amount, expected, receiver);
  }

  //////////////////////////
  // Option Token Actions //
  //////////////////////////

  /// @notice Get position info for given positionIds
  function _getPositions(uint[] memory positionIds) internal view returns (OptionPosition[] memory) {
    IOptionToken.OptionPosition[] memory positions = optionToken.getOptionPositions(positionIds);

    uint positionsLen = positions.length;
    OptionPosition[] memory convertedPositions = new OptionPosition[](positionsLen);
    for (uint i = 0; i < positionsLen; ++i) {
      convertedPositions[i] = OptionPosition({
        positionId: positions[i].positionId,
        strikeId: positions[i].strikeId,
        optionType: OptionType(uint(positions[i].optionType)),
        amount: positions[i].amount,
        collateral: positions[i].collateral,
        state: PositionState(uint(positions[i].state))
      });
    }

    return convertedPositions;
  }

  /**
   * @notice Allows a user to split a curent position into two. The amount of the original position will
   *         be subtracted from and a new position will be minted with the desired amount and collateral.
   * @dev Only ACTIVE positions can be owned by users, so status does not need to be checked
   * @dev Both resulting positions must not be liquidatable
   *
   * @param positionId the positionId of the original position to be split
   * @param newAmount the amount in the new position
   * @param newCollateral the amount of collateral for the new position
   * @param recipient recipient of new position
   */
  function _splitPosition(
    uint positionId,
    uint newAmount,
    uint newCollateral,
    address recipient
  ) internal returns (uint newPositionId) {
    newPositionId = optionToken.split(positionId, newAmount, newCollateral, recipient);
  }

  /**
   * @notice User can merge many positions with matching strike and optionType into a single position
   * @dev Only ACTIVE positions can be owned by users, so status does not need to be checked.
   * @dev Merged position must not be liquidatable.
   *
   * @param positionIds the positionIds to be merged together
   */
  function _mergePositions(uint[] memory positionIds) internal {
    optionToken.merge(positionIds);
  }

  ////////////////////
  // Market Getters //
  ////////////////////

  /// @notice Returns the list of live board ids.
  function _getLiveBoards() internal view returns (uint[] memory liveBoards) {
    liveBoards = optionMarket.getLiveBoards();
  }

  /// @notice Returns Board struct for a given boardId
  function _getBoard(uint boardId) internal view returns (Board memory) {
    IOptionMarket.OptionBoard memory board = optionMarket.getOptionBoard(boardId);
    return Board({id: board.id, expiry: board.expiry, boardIv: board.iv, strikeIds: board.strikeIds});
  }

  /// @notice Returns all Strike structs for a list of strikeIds
  function _getStrikes(uint[] memory strikeIds) internal view returns (Strike[] memory allStrikes) {
    uint strikesLen = strikeIds.length;

    allStrikes = new Strike[](strikesLen);
    for (uint i = 0; i < strikesLen; ++i) {
      (IOptionMarket.Strike memory strike, IOptionMarket.OptionBoard memory board) = optionMarket.getStrikeAndBoard(
        strikeIds[i]
      );

      allStrikes[i] = Strike({
        id: strike.id,
        expiry: board.expiry,
        strikePrice: strike.strikePrice,
        skew: strike.skew,
        boardIv: board.iv
      });
    }
    return allStrikes;
  }

  /// @notice Returns current spot volatilities for given strikeIds (boardIv * skew)
  function _getVols(uint[] memory strikeIds) internal view returns (uint[] memory vols) {
    uint strikesLen = strikeIds.length;

    vols = new uint[](strikesLen);
    for (uint i = 0; i < strikesLen; ++i) {
      (IOptionMarket.Strike memory strike, IOptionMarket.OptionBoard memory board) = optionMarket.getStrikeAndBoard(
        strikeIds[i]
      );

      vols[i] = board.iv.multiplyDecimal(strike.skew);
    }
    return vols;
  }

  /// @notice Returns current spot deltas for given strikeIds (using BlackScholes and spot volatilities)
  function _getDeltas(uint[] memory strikeIds) internal view returns (int[] memory callDeltas) {
    uint strikesLen = strikeIds.length;

    callDeltas = new int[](strikesLen);
    for (uint i = 0; i < strikesLen; ++i) {
      BlackScholes.BlackScholesInputs memory bsInput = _getBsInput(strikeIds[i]);
      (callDeltas[i], ) = BlackScholes.delta(bsInput);
    }
  }

  /// @notice Returns current spot vegas for given strikeIds (using BlackScholes and spot volatilities)
  function _getVegas(uint[] memory strikeIds) internal view returns (uint[] memory vegas) {
    uint strikesLen = strikeIds.length;

    vegas = new uint[](strikesLen);
    for (uint i = 0; i < strikesLen; ++i) {
      BlackScholes.BlackScholesInputs memory bsInput = _getBsInput(strikeIds[i]);
      vegas[i] = BlackScholes.vega(bsInput);
    }
  }

  /// @notice Calculate the pure black-scholes premium for given params
  function _getPurePremium(
    uint secondsToExpiry,
    uint vol,
    uint spotPrice,
    uint strikePrice
  ) internal view returns (uint call, uint put) {
    BlackScholes.BlackScholesInputs memory bsInput = BlackScholes.BlackScholesInputs({
      timeToExpirySec: secondsToExpiry,
      volatilityDecimal: vol,
      spotDecimal: spotPrice,
      strikePriceDecimal: strikePrice,
      rateDecimal: synthetixAdapter.rateAndCarry(address(optionMarket))
    });
    (call, put) = BlackScholes.optionPrices(bsInput);
  }

  /// @notice Calculate the spot black-scholes premium for a given strike
  /// @dev Does not include slippage or trading fees
  function _getPurePremiumForStrike(uint strikeId) internal view returns (uint call, uint put) {
    BlackScholes.BlackScholesInputs memory bsInput = _getBsInput(strikeId);
    (call, put) = BlackScholes.optionPrices(bsInput);
  }

  /// @notice Returns the breakdown of current liquidity usage (see Liquidity struct)
  function _getLiquidity() internal view returns (Liquidity memory) {
    ILiquidityPool.Liquidity memory liquidity = liquidityPool.getLiquidity();
    return
      Liquidity({
        freeLiquidity: liquidity.freeLiquidity,
        burnableLiquidity: liquidity.burnableLiquidity,
        reservedCollatLiquidity: liquidity.reservedCollatLiquidity,
        pendingDeltaLiquidity: liquidity.pendingDeltaLiquidity,
        usedDeltaLiquidity: liquidity.usedDeltaLiquidity,
        NAV: liquidity.NAV
      });
  }

  /// @notice Returns the amount of liquidity available for trading
  function _getFreeLiquidity() internal view returns (uint freeLiquidity) {
    freeLiquidity = liquidityPool.getLiquidity().freeLiquidity;
  }

  /// @notice Returns the most critical Lyra market trading parameters that determine pricing/slippage/trading restrictions
  function _getMarketParams() internal view returns (MarketParams memory) {
    IOptionMarketPricer.PricingParameters memory pricingParams = optionPricer.getPricingParams();
    IOptionMarketPricer.TradeLimitParameters memory tradeLimitParams = optionPricer.getTradeLimitParams();
    return
      MarketParams({
        standardSize: pricingParams.standardSize,
        skewAdjustmentParam: pricingParams.skewAdjustmentFactor,
        rateAndCarry: synthetixAdapter.rateAndCarry(address(optionMarket)),
        deltaCutOff: tradeLimitParams.minDelta,
        tradingCutoff: tradeLimitParams.tradingCutoff,
        minForceCloseDelta: tradeLimitParams.minForceCloseDelta
      });
  }

  /// @notice use latest optionMarket delta cutoff to determine whether trade delta is out of bounds
  function _isOutsideDeltaCutoff(uint strikeId) internal view returns (bool) {
    MarketParams memory marketParams = _getMarketParams();
    uint[] memory dynamicArray = new uint[](1);
    dynamicArray[0] = strikeId;

    int callDelta = _getDeltas(dynamicArray)[0];
    return callDelta > (int(DecimalMath.UNIT) - marketParams.deltaCutOff) || callDelta < marketParams.deltaCutOff;
  }

  /// @notice use latest optionMarket trading cutoff to determine whether trade is too close to expiry
  function _isWithinTradingCutoff(uint strikeId) internal view returns (bool) {
    MarketParams memory marketParams = _getMarketParams();
    uint[] memory dynamicArray = new uint[](1);
    dynamicArray[0] = strikeId;

    Strike memory strike = _getStrikes(dynamicArray)[0];
    return strike.expiry - block.timestamp <= marketParams.tradingCutoff;
  }

  ////////////////////////
  // Minimum Collateral //
  ////////////////////////

  /// @notice Estimate minimum collateral required for given parameters
  /// @dev Position is liquidatable when position.collateral < minCollateral
  function _getMinCollateral(
    OptionType optionType,
    uint strikePrice,
    uint expiry,
    uint spotPrice,
    uint amount
  ) internal view returns (uint) {
    return
      greekCache.getMinCollateral(IOptionMarket.OptionType(uint(optionType)), strikePrice, expiry, spotPrice, amount);
  }

  /// @notice Estimate minimum collateral required for an existing position
  function _getMinCollateralForPosition(uint positionId) internal view returns (uint) {
    IOptionToken.PositionWithOwner memory position = optionToken.getPositionWithOwner(positionId);
    if (_isLong(OptionType(uint(position.optionType)))) return 0;

    uint strikePrice;
    uint expiry;
    (strikePrice, expiry) = optionMarket.getStrikeAndExpiry(position.strikeId);

    return
      _getMinCollateral(
        OptionType(uint(position.optionType)),
        strikePrice,
        expiry,
        synthetixAdapter.getSpotPriceForMarket(address(optionMarket)),
        position.amount
      );
  }

  /// @notice Estimate minimum collateral required for a given strike with manual amount
  function _getMinCollateralForStrike(OptionType optionType, uint strikeId, uint amount) internal view returns (uint) {
    if (_isLong(optionType)) return 0;

    uint strikePrice;
    uint expiry;
    (strikePrice, expiry) = optionMarket.getStrikeAndExpiry(strikeId);

    return
      _getMinCollateral(
        optionType,
        strikePrice,
        expiry,
        synthetixAdapter.getSpotPriceForMarket(address(optionMarket)),
        amount
      );
  }

  /////////////////
  // GWAV Oracle //
  /////////////////

  /// @notice the `baseIv` GWAV for a given `boardId` with GWAV interval `secondsAgo`
  function _ivGWAV(uint boardId, uint secondsAgo) internal view returns (uint) {
    return gwavOracle.ivGWAV(boardId, secondsAgo);
  }

  /// @notice the volatility `skew` GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function _skewGWAV(uint strikeId, uint secondsAgo) internal view returns (uint) {
    return gwavOracle.skewGWAV(strikeId, secondsAgo);
  }

  /// @notice the resultant volatility =`skew` * 'baseIv' for a given `strikeId` with GWAV interval `secondsAgo`
  function _volGWAV(uint strikeId, uint secondsAgo) internal view returns (uint) {
    return gwavOracle.volGWAV(strikeId, secondsAgo);
  }

  /// @notice the delta GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function _deltaGWAV(uint strikeId, uint secondsAgo) internal view returns (int callDelta) {
    return gwavOracle.deltaGWAV(strikeId, secondsAgo);
  }

  /// @notice the non-normalized vega GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function _vegaGWAV(uint strikeId, uint secondsAgo) internal view returns (uint) {
    return gwavOracle.vegaGWAV(strikeId, secondsAgo);
  }

  /// @notice the option price GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function _optionPriceGWAV(uint strikeId, uint secondsAgo) internal view returns (uint callPrice, uint putPrice) {
    return gwavOracle.optionPriceGWAV(strikeId, secondsAgo);
  }

  //////////
  // Misc //
  //////////

  /// @dev format all strike related params before input into BlackScholes
  function _getBsInput(uint strikeId) internal view returns (BlackScholes.BlackScholesInputs memory bsInput) {
    (IOptionMarket.Strike memory strike, IOptionMarket.OptionBoard memory board) = optionMarket.getStrikeAndBoard(
      strikeId
    );
    bsInput = BlackScholes.BlackScholesInputs({
      timeToExpirySec: board.expiry - block.timestamp,
      volatilityDecimal: board.iv.multiplyDecimal(strike.skew),
      spotDecimal: synthetixAdapter.getSpotPriceForMarket(address(optionMarket)),
      strikePriceDecimal: strike.strikePrice,
      rateDecimal: synthetixAdapter.rateAndCarry(address(optionMarket))
    });
  }

  /// @dev Check if position is long
  function _isLong(OptionType optionType) internal pure returns (bool) {
    return (optionType < OptionType.SHORT_CALL_BASE);
  }

  /// @dev Convert LyraAdapter.TradeInputParameters into OptionMarket.TradeInputParameters
  function _convertParams(
    TradeInputParameters memory _params
  ) internal pure returns (IOptionMarket.TradeInputParameters memory) {
    return
      IOptionMarket.TradeInputParameters({
        strikeId: _params.strikeId,
        positionId: _params.positionId,
        iterations: _params.iterations,
        optionType: IOptionMarket.OptionType(uint(_params.optionType)),
        amount: _params.amount,
        setCollateralTo: _params.setCollateralTo,
        minTotalCost: _params.minTotalCost,
        maxTotalCost: _params.maxTotalCost
      });
  }

  /// @dev get lyra market addresses from LyraRegistry
  function _assignLyraRegistryMarketAddresses() internal {
    ILyraRegistry.OptionMarketAddresses memory addresses = lyraRegistry.getMarketAddresses(address(optionMarket));

    liquidityPool = ILiquidityPool(addresses.liquidityPool);
    greekCache = IOptionGreekCache(addresses.greekCache);
    optionPricer = IOptionMarketPricer(addresses.optionMarketPricer);
    optionToken = IOptionToken(addresses.optionToken);
    shortCollateral = IShortCollateral(addresses.shortCollateral);
    gwavOracle = IGWAVOracle(addresses.gwavOracle);
    quoteAsset = addresses.quoteAsset;
    baseAsset = addresses.baseAsset;
  }

  ////////////
  // Errors //
  ////////////

  error ExchangerBaseReceivedTooLow(address thrower, uint baseExpected, uint baseReceived);
  error ExchangerQuoteReceivedTooLow(address thrower, uint quoteExpected, uint quoteReceived);
}
