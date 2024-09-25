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
import "Lyra-Finance/openzeppelin-contracts-4.4.1/utils/math/SafeCast.sol";

// Inherited
import "./synthetix/Owned.sol";
import "./libraries/SimpleInitializable.sol";
import "./libraries/PoolHedger.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/security/ReentrancyGuard.sol";

// Interfaces
import "Lyra-Finance/openzeppelin-contracts-4.4.1/token/ERC20/ERC20.sol";
import "./LiquidityPool.sol";
import "./interfaces/ISynthetix.sol";
import "./interfaces/ICollateralShort.sol";
import "./OptionMarket.sol";
import "./OptionGreekCache.sol";
import "./interfaces/perpsV2/IPerpsV2MarketConsolidated.sol";
import "./interfaces/perpsV2/IPerpsV2MarketSettings.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/perpsV2/ISystemStatus.sol";
import "./interfaces/IAddressResolver.sol";

/**
 * @title SNXPerpsV2PoolHedger
 * @author Lyra
 */
contract SNXPerpsV2PoolHedger is PoolHedger, Owned, SimpleInitializable, ReentrancyGuard {
  using DecimalMath for uint;
  using SignedDecimalMath for int;

  struct SNXPerpsV2PoolHedgerParameters {
    uint targetLeverage;
    uint maximumFundingRate; // the absolute maximum funding rate per delta that the futures pool hedger is willing to pay.
    uint deltaThreshold; // Bypass interaction delay if delta is outside of a certain range.
    uint marketDepthBuffer; // percentage buffer. toBN(1.1) -> 10% buffer.
    uint priceDeltaBuffer; // percentage buffer. toBN(1.1) -> 10% buffer.
    uint worstStableRate; // the worst exchange rate the hedger is willing to accept for a swap, toBN('1.1')
    uint maxOrderCap; // the maxmimum number of deltas that can be hedged in a single order
  }

  struct HedgerState {
    uint lastInteraction;
    int hedgedDelta;
    uint margin;
    uint leverage;
    uint hedgerQuoteBalance;
    uint hedgerMarginQuoteBalance;
    bool canHedgeDeltaIncrease;
    bool canHedgeDeltaDecrease;
    int cappedExpectedHedge;
    bool snxHasEnoughMarketDepth;
    bool marketSuspended;
    bool curveRateStable;
    uint pendingDeltaLiquidity;
    uint usedDeltaLiquidity;
    int pendingDelta;
    uint pendingMargin;
    int fundingRate;
    bytes32 trackingCode;
    address optionMarket;
    address perpsMarket;
    address curveSwap;
    address quoteAsset;
    SNXPerpsV2PoolHedgerParameters futuresPoolHedgerParams;
    PoolHedgerParameters poolHedgerParams;
  }

  ///////////////
  // Variables //
  ///////////////

  // @dev Tracking code for Synthetix-tracking purposes
  bytes32 public trackingCode = bytes32("LYRA");
  bytes32 constant FUTURES_SETTINGS_CONTRACT = bytes32("PerpsV2MarketSettings"); // the futuresMarketSettings contract that has a one to many with that market
  bytes32 constant SYSTEM_STATUS = bytes32("SystemStatus"); // the system status contract

  IAddressResolver public addressResolver;
  BaseExchangeAdapter public exchangeAdapter;
  OptionMarket internal optionMarket;
  OptionGreekCache internal optionGreekCache;
  IPerpsV2MarketConsolidated public perpsMarket;
  ICurve public curveSwap;

  ERC20 internal quoteAsset;
  ERC20 internal sUSD;

  // e.g. sETH
  bytes32 public marketKey;

  // FuturesMarket Parameters
  // used for managing the exposure and minimum liquidity of the hedger.
  SNXPerpsV2PoolHedgerParameters public futuresPoolHedgerParams;

  ///////////
  // Setup //
  ///////////

  constructor() Owned() {}

  /**
   * @dev Initialize the contract.
   *
   * @param _exchangeAdapter ExchangeAdapter address
   * @param _optionMarket OptionMarket address
   * @param _liquidityPool LiquidityPool address
   * @param _quoteAsset Quote asset address(usdc normally)
   * @param _sUSD sUSD address
   * @param _curveSwap Curve swap address
   * @param _marketKey E.g. ETH
   */
  function init(
    IAddressResolver _addressResolver,
    BaseExchangeAdapter _exchangeAdapter,
    OptionMarket _optionMarket,
    OptionGreekCache _optionGreekCache,
    LiquidityPool _liquidityPool,
    IPerpsV2MarketConsolidated _perpMarketProxy,
    ERC20 _quoteAsset,
    ERC20 _sUSD,
    ICurve _curveSwap,
    bytes32 _marketKey
  ) external onlyOwner initializer {
    addressResolver = _addressResolver;
    exchangeAdapter = _exchangeAdapter;
    optionMarket = _optionMarket;
    optionGreekCache = _optionGreekCache;
    liquidityPool = _liquidityPool;
    quoteAsset = _quoteAsset;
    curveSwap = _curveSwap;
    sUSD = _sUSD;

    marketKey = _marketKey;
    perpsMarket = _perpMarketProxy;

    // approve curve
    quoteAsset.approve(address(curveSwap), type(uint).max);
    sUSD.approve(address(curveSwap), type(uint).max);
  }

  ///////////
  // Admin //
  ///////////

  /**
   * @dev set Tracking code
   */
  function setTrackingCode(bytes32 _trackingCode) external onlyOwner {
    trackingCode = _trackingCode;
    emit TrackingCodeSet(_trackingCode);
  }

  /**
   * @dev Update pool hedger parameters.
   */
  function setPoolHedgerParams(PoolHedgerParameters memory _poolHedgerParams) external onlyOwner {
    _setPoolHedgerParams(_poolHedgerParams);
  }

  /**
   * @dev updates the futures hedger parameters
   */
  function setFuturesPoolHedgerParams(
    SNXPerpsV2PoolHedgerParameters memory _futuresPoolHedgerParams
  ) external onlyOwner {
    if (
      _futuresPoolHedgerParams.targetLeverage == 0 ||
      _futuresPoolHedgerParams.targetLeverage > _getMarketMaxLeverage() ||
      _futuresPoolHedgerParams.worstStableRate < 1e18
    ) {
      revert InvalidFuturesPoolHedgerParams(address(this), _futuresPoolHedgerParams);
    }
    futuresPoolHedgerParams = _futuresPoolHedgerParams;
    emit FuturesPoolHedgerParamsSet(futuresPoolHedgerParams);
  }

  /////////////
  // Getters //
  /////////////

  /**
   * @notice Returns pending delta hedge liquidity and used delta hedge liquidity
   * @dev include funds potentially transferred to the contract
   */
  function getHedgingLiquidity(
    uint spotPrice
  ) public view override returns (uint pendingDeltaLiquidity, uint usedDeltaLiquidity) {
    usedDeltaLiquidity = getCurrentPositionMargin() + _getPriceAdjustedQuote();
    pendingDeltaLiquidity = _getPendingMargin(spotPrice, usedDeltaLiquidity, _getCappedExpectedHedge());
  }

  /**
   * @notice Returns the current value of sUSD in terms of the quote asset.
   * @dev include funds potentially transferred to the contract
   */
  function _getPriceAdjustedQuote() internal view returns (uint) {
    uint quoteBalance = quoteAsset.balanceOf(address(this));
    uint sUSDBalance = sUSD.balanceOf(address(this));
    /// @note possibly could include a revert here for if either of the stables go off peg
    if (sUSDBalance > 0) {
      sUSDBalance = _getBestRate(sUSD, quoteAsset, sUSDBalance);
      sUSDBalance =  ConvertDecimals.convertTo18(sUSDBalance, quoteAsset.decimals());
    }

    return ConvertDecimals.convertTo18(quoteBalance, quoteAsset.decimals()) + sUSDBalance;
  }

  /**
   * @dev external function to get the current delta hedged by the pool hedger
   */
  function getCurrentHedgedNetDelta() public view override returns (int) {
    IPerpsV2MarketConsolidated.Position memory pos = perpsMarket.positions(address(this));
    return pos.size;
  }

  /**
   * @dev View to return the expected delta hedge that the hedger must perform to offset it's delta risk
   */
  function getCappedExpectedHedge() public view override returns (int) {
    return _getCappedExpectedHedge();
  }

  /**
   * @dev Calculates the expected delta hedge that hedger must perform and
   * adjusts the result down to the hedgeCap param if needed.
   */
  function _getCappedExpectedHedge() internal view returns (int cappedExpectedHedge) {
    // The sum of delta for all options in the market from the traders perspective
    int expectedHedge = optionGreekCache.getGlobalNetDelta();

    bool exceedsCap = Math.abs(expectedHedge) > poolHedgerParams.hedgeCap;
    
    // Cap expected hedge & based on maxValueUSD
    if (expectedHedge < 0 && exceedsCap) {
      cappedExpectedHedge = -SafeCast.toInt256(poolHedgerParams.hedgeCap);
    } else if (expectedHedge >= 0 && exceedsCap) {
      cappedExpectedHedge = SafeCast.toInt256(poolHedgerParams.hedgeCap);
    } else {
      cappedExpectedHedge = expectedHedge;
    }
  }

  ///////////////
  // Can Hedge //
  ///////////////

  /**
   * @dev Return whether the hedger can hedge the additional delta risk introduced by the option being traded.
   */
  function canHedge(uint /*tradeSize*/, bool deltaIncrease, uint /*strikeId*/) external view override returns (bool) {
    if (_isMarketSuspended()) {
      return false;
    }

    int expectedHedge = _getCappedExpectedHedge();
    int currentHedge = getCurrentHedgedNetDelta();
    if (Math.abs(expectedHedge) <= Math.abs(currentHedge) 
      && expectedHedge * currentHedge >= 0) {
      // Delta is shrinking (potentially flipping, but still smaller than current hedge), so we skip the check
      return true;
    }

    // expected hedge is positive, and trade increases delta of the pool - risk is reduced, so accept trade
    if (deltaIncrease && expectedHedge >= 0) {
      return true;
    }

    // expected hedge is negative, and trade decreases delta of the pool - risk is reduced, so accept trade
    if (!deltaIncrease && expectedHedge <= 0) {
      return true;
    }

    uint pendingMargin = _getPendingMargin(_getSpotPrice(), getCurrentPositionMargin(), expectedHedge);

    // check that the curve swap rates are acceptable
    if (!_isCurveRateStable(pendingMargin)) {
      return false;
    }

    if (Math.abs(expectedHedge) > Math.abs(currentHedge)) {
      // check funding rate is within bounds and so is liquidity
      int fundingRate = perpsMarket.currentFundingRate();
      if (Math.abs(fundingRate) > futuresPoolHedgerParams.maximumFundingRate) {
        return false;
      }
    }

    // Check remaining market liquidity
    if (expectedHedge * currentHedge > 0) {
      // same sign - so just check the difference
      if (!_hasEnoughMarketDepth(expectedHedge - currentHedge)) {
        return false;
      }
    } else {
      // flipping the hedge, so check the entire hedge size
      if (!_hasEnoughMarketDepth(expectedHedge)) {
        return false;
      }
    }

    return true;
  }

  /**
   * @dev determines if there is enough market depth to hedge position
   */
  function _hasEnoughMarketDepth(int hedge) internal view returns (bool) {
    (uint longInterest, uint shortInterest) = perpsMarket.marketSizes();

    uint maxMarketSize = _getFuturesMarketSettings().maxMarketValue(marketKey);

    uint marketUsage = hedge < 0 ? shortInterest : longInterest;

    marketUsage += Math.abs(hedge).multiplyDecimal(futuresPoolHedgerParams.marketDepthBuffer);

    return marketUsage < maxMarketSize;
  }

  /////////////////
  // Hedge Delta //
  /////////////////

  /**
   * @notice Retrieves the netDelta from the OptionGreekCache and updates the hedge position of the liquidityPool to
   * offset the delta exposure.
   */
  function hedgeDelta() external payable override nonReentrant {
    // Dont update if there is a pending order
    _checkPendingOrder();

    int currentHedgedDelta = getCurrentHedgedNetDelta();
    int expectedHedge = _getCappedExpectedHedge();

    // Bypass interactionDelay if we want to set hedge to exactly 0
    if (
      expectedHedge != 0 &&
      lastInteraction + poolHedgerParams.interactionDelay > block.timestamp &&
      Math.abs(expectedHedge - currentHedgedDelta) < futuresPoolHedgerParams.deltaThreshold
    ) {
      revert InteractionDelayNotExpired(
        address(this),
        lastInteraction,
        poolHedgerParams.interactionDelay,
        block.timestamp
      );
    }
    _hedgeDelta(expectedHedge);
  }

  /**
   * @dev Updates the hedge position.
   * @param expectedHedge The expected final hedge value.
   */
  function _hedgeDelta(int expectedHedge) internal {
    int currHedgedNetDelta = getCurrentHedgedNetDelta();

    if (expectedHedge == currHedgedNetDelta) {
      return;
    }

    int sizeDelta = expectedHedge - currHedgedNetDelta;

    // here would be the place to put the order cap
    if (Math.abs(sizeDelta) > futuresPoolHedgerParams.maxOrderCap) {
      // sizeDelta is equal to the maxOrderCap
      if (sizeDelta < 0)
        sizeDelta = -int(futuresPoolHedgerParams.maxOrderCap);
      else {
        sizeDelta = int(futuresPoolHedgerParams.maxOrderCap);
      }
    } 
  
    uint spotPrice = _getSpotPrice();
    uint requiredMargin = _getPendingMargin(spotPrice, getCurrentPositionMargin(), sizeDelta + currHedgedNetDelta);

    requiredMargin = _addFeeToMargin(sizeDelta, requiredMargin);

    uint currentMargin = getCurrentPositionMargin();
    if (currentMargin < requiredMargin) {
      _addToMarginAccount(requiredMargin - currentMargin);
    }

    _submitOffchainOrder(sizeDelta, spotPrice);

    if (expectedHedge != 0) {
      lastInteraction = block.timestamp;
    }

    emit PositionUpdateSubmitted(currHedgedNetDelta, sizeDelta, expectedHedge);
  }

  function _addFeeToMargin(int sizeDelta, uint requiredMargin) internal view returns (uint) {
    uint minMargin = _getFuturesMarketSettings().minInitialMargin();
    if (requiredMargin < minMargin) {
      requiredMargin = minMargin;
    }
    // OrderFee includes the keeper fee when passing in this type
    (uint feeDollars, ) = perpsMarket.orderFee(sizeDelta, IPerpsV2MarketConsolidated.OrderType.Offchain);

    /// @note The order fee function does not include the keeper fee
    feeDollars += _getFuturesMarketSettings().minKeeperFee();

    return requiredMargin + feeDollars;
  }

  ///////////////////////
  // Update Collateral //
  ///////////////////////

  /**
   * @notice Updates the collateral held in the short to prevent liquidations and return excess collateral
   */
  function updateCollateral() external payable override nonReentrant {
    // Dont update if there is a pending order
    _checkPendingOrder();

    uint spotPrice = _getSpotPrice();

    uint margin = getCurrentPositionMargin();

    _updateCollateral(spotPrice, margin, getCurrentHedgedNetDelta());

    // Return any excess to the LP
    _sendAllQuoteToLP();

    emit CollateralUpdated(margin, getCurrentPositionMargin());
  }

  function _updateCollateral(uint spotPrice, uint currentCollateral, int size) internal {
    uint desiredCollateral = Math.abs(size).multiplyDecimal(spotPrice).divideDecimal(
      futuresPoolHedgerParams.targetLeverage
    );
    uint minMargin = _getFuturesMarketSettings().minInitialMargin();
    // minimum margin requirement

    if (desiredCollateral < minMargin && getCurrentHedgedNetDelta() != 0) {
      desiredCollateral = minMargin;
    }

    if (currentCollateral < desiredCollateral) {
      _addToMarginAccount(desiredCollateral - currentCollateral);
    } else if (currentCollateral > desiredCollateral) {
      perpsMarket.transferMargin(int(desiredCollateral) - int(currentCollateral));
    }
  }

  //////////////
  // Internal //
  //////////////

  function _getPendingMargin(
    uint spot,
    uint currentMargin,
    int expectedHedge
  ) internal view returns (uint extraMargin) {
    uint pendingMargin = Math.abs(expectedHedge).multiplyDecimal(spot).divideDecimal(
      futuresPoolHedgerParams.targetLeverage
    );
    if (pendingMargin > currentMargin) {
      return pendingMargin - currentMargin;
    } else {
      return 0;
    }
  }

  function _addToMarginAccount(uint amountMargin) internal {
    uint amountSUSD = _getSUSD(amountMargin);
    if (amountSUSD > 0) {
      perpsMarket.transferMargin(int(amountSUSD));
    }
  }

  /**
   * @dev Sends all quote asset deposited in this contract to the `LiquidityPool`.
   */
  function _sendAllQuoteToLP() internal {
    _swapExcessSUSDToQuote();

    uint quoteBal = quoteAsset.balanceOf(address(this));
    if (!quoteAsset.transfer(address(liquidityPool), quoteBal)) {
      revert QuoteTransferFailed(address(this), address(this), address(liquidityPool), quoteBal);
    }

    emit QuoteReturnedToLP(quoteBal);
  }

  function _getSpotPrice() internal view returns (uint) {
    return exchangeAdapter.getSpotPriceForMarket(address(optionMarket), BaseExchangeAdapter.PriceType.REFERENCE);
  }

  /////////////////
  // SNX Helpers //
  /////////////////

  /// @dev checks if there's a pending order and reverts if there is
  function _checkPendingOrder() internal view {
    int pendingOrderDelta = _getPendingOrderDelta();
    if (pendingOrderDelta != 0) {
      revert PendingOrderDeltaError(pendingOrderDelta);
    }
  }

  function _submitOffchainOrder(int sizeDelta, uint spotPrice) internal {
    uint desiredFillPrice = 
      sizeDelta > 0 ? spotPrice.multiplyDecimal(futuresPoolHedgerParams.priceDeltaBuffer) : spotPrice.divideDecimal(futuresPoolHedgerParams.priceDeltaBuffer);
   
    perpsMarket.submitOffchainDelayedOrderWithTracking(
      sizeDelta,
      desiredFillPrice,
      trackingCode
    );
  }

  /// @notice remaining margin is inclusive of pnl and margin
  function getCurrentPositionMargin() public view returns (uint) {
    (uint margin, bool invalid) = perpsMarket.remainingMargin(address(this));

    if (invalid) {
      revert PerpMarketReturnedInvalid();
    }

    return margin;
  }

  /**
   * @dev Gets if the the current market is suspended only applicable on forex/ commodities pairs
   */
  function _isMarketSuspended() internal view returns (bool) {
    (bool suspended, ) = ISystemStatus(addressResolver.getAddress(SYSTEM_STATUS)).futuresMarketSuspension(marketKey);
    return suspended;
  }

  /**
   * @dev Resolve the futuresMarketSettings
   */
  function _getFuturesMarketSettings() internal view returns (IPerpsV2MarketSettings) {
    return IPerpsV2MarketSettings(addressResolver.getAddress(FUTURES_SETTINGS_CONTRACT));
  }

  /**
   * @dev Returns the max market leverage for the futures market
   */
  function _getMarketMaxLeverage() internal view returns (uint) {
    return _getFuturesMarketSettings().maxLeverage(marketKey);
  }

  /**
   * @dev function checks if there is a pending delayed order and adds that to the current delta
   */
  function _getPendingOrderDelta() internal view returns (int) {
    IPerpsV2MarketConsolidated.DelayedOrder memory delayedOrder = perpsMarket.delayedOrders(address(this));
    return delayedOrder.sizeDelta;
  }

  ///////////////////
  // Curve helpers //
  ///////////////////

  function _isCurveRateStable(uint pendingMargin) internal view returns (bool) {
    if (pendingMargin == 0) {
      return true;
    }

    uint amountOut = _getBestRate(quoteAsset, sUSD, pendingMargin);

    uint invertedRate = pendingMargin.divideDecimal(amountOut);


    return (invertedRate <= futuresPoolHedgerParams.worstStableRate &&
      DecimalMath.UNIT.divideDecimal(invertedRate) <= futuresPoolHedgerParams.worstStableRate);
  }

  function _getBestRate(ERC20 inAsset, ERC20 outAsset, uint amount) internal view returns (uint) {
    // need to convert amount to InAsset decimals
    amount = ConvertDecimals.convertFrom18(amount, inAsset.decimals());

    (, uint amountOut) = curveSwap.get_best_rate(address(inAsset), address(outAsset), amount);
    /// @note this will be in the terms of the _to token, 8dp when going from sUSD to USDC
    return amountOut;
  }

  function _getSUSD(uint amount) internal returns (uint amountOut) {
    uint amountReq = _estimateInputAmountNeeded(amount, address(quoteAsset), address(sUSD));

    uint amountIn = liquidityPool.transferQuoteToHedge(amountReq);
    amountIn = ConvertDecimals.convertFrom18(amountIn, quoteAsset.decimals());

    uint minOut = ConvertDecimals.convertTo18(amountIn.divideDecimal(futuresPoolHedgerParams.worstStableRate), sUSD.decimals());

    amountOut = curveSwap.exchange_with_best_rate(
      address(quoteAsset),
      address(sUSD),
      amountIn,
      minOut,
      address(this)
    );

    emit USDCCollateralSwapForMargin(address(sUSD), address(quoteAsset), amountIn, amountOut);
  }

  /**
   * @notice Swap excess sUSD to the quote asset
   * @dev This function will revert if the swap is out side of the slippage parameters
   */
  function _swapExcessSUSDToQuote() internal {
    uint sUSDBalance = sUSD.balanceOf(address(this));
    if (sUSDBalance == 0) {
      return;
    }

    uint minOut = ConvertDecimals.convertFrom18(sUSDBalance, quoteAsset.decimals());
    minOut = minOut.divideDecimal(futuresPoolHedgerParams.worstStableRate);

    uint amountOut = curveSwap.exchange_with_best_rate(
      address(sUSD),
      address(quoteAsset),
      sUSDBalance,
      minOut,
      address(this)
    );

    emit sUSDCollateralSwap(address(sUSD), address(quoteAsset), sUSDBalance, amountOut);
  }

  function _estimateInputAmountNeeded(uint amount, address inAsset, address outAsset) internal view returns (uint) {
    uint amountOut = _getBestRate(ERC20(inAsset), ERC20(outAsset), amount);
    // e.g. 100 in 110 out -> 0.9. Invert to check against the parameter
    uint inverseSwapRate = amount.divideDecimal(amountOut);
    // The approx amountIn to get the amount desired:
    return amount.multiplyDecimal(inverseSwapRate);
  }

  /////////////
  // Helpers //
  /////////////

  /**
   * @dev Returns the current hedged net delta.
   * @notice Summary of the current state
   */
  function getHedgerState() external view returns (HedgerState memory) {
    uint margin = getCurrentPositionMargin();
    uint spot = _getSpotPrice();
    int expectedHedge = _getCappedExpectedHedge();
    uint pendingMargin = _getPendingMargin(_getSpotPrice(), getCurrentPositionMargin(), expectedHedge);
    (uint pendingDeltaLiquidity, uint usedDeltaLiquidity) = getHedgingLiquidity(spot);
    int fundingRate = perpsMarket.currentFundingRate();

    return (
      HedgerState({
        lastInteraction: lastInteraction,
        hedgedDelta: getCurrentHedgedNetDelta(),
        margin: margin,
        leverage: futuresPoolHedgerParams.targetLeverage,
        hedgerQuoteBalance: quoteAsset.balanceOf(address(this)),
        hedgerMarginQuoteBalance: sUSD.balanceOf(address(this)),
        canHedgeDeltaIncrease: this.canHedge(0, true, 0),
        canHedgeDeltaDecrease: this.canHedge(0, false, 0),
        cappedExpectedHedge: expectedHedge,
        snxHasEnoughMarketDepth: _hasEnoughMarketDepth(expectedHedge),
        marketSuspended: _isMarketSuspended(),
        curveRateStable: _isCurveRateStable(margin),
        pendingDeltaLiquidity: pendingDeltaLiquidity,
        usedDeltaLiquidity: usedDeltaLiquidity,
        pendingDelta: _getPendingOrderDelta(),
        pendingMargin: pendingMargin,
        fundingRate: fundingRate,
        trackingCode: trackingCode,
        optionMarket: address(optionMarket),
        perpsMarket: address(perpsMarket),
        curveSwap: address(curveSwap),
        quoteAsset: address(quoteAsset),
        futuresPoolHedgerParams: futuresPoolHedgerParams,
        poolHedgerParams: poolHedgerParams
      })
    );
  }

  ////////////
  // Events //
  ////////////
  /**
   * @dev Emitted when the perp related parameters are updated.
   */
  event FuturesPoolHedgerParamsSet(SNXPerpsV2PoolHedgerParameters params);
  /**
   * @dev Emitted when the hedge position is updated.
   */
  event PositionUpdateSubmitted(int oldNetDelta, int currentNetDelta, int expectedNetDelta);
  /**
   * @dev Emitted when proceeds of the short are sent back to the LP.
   */
  event QuoteReturnedToLP(uint amountQuote);
  /**
   * @dev Emitted when delegation approvals change
   */
  event CollateralUpdated(uint oldCollat, uint newCollat);
  /**
   * @dev Emmited when the slippage of the curve swap is out of bounds
   */
  event SlippageOutOfBounds(address quoteAsset, address sUSD, uint curve_rate, uint maxSlippage);
  /**
   * @dev Emitted when sUSD is swapped
   */
  event sUSDCollateralSwap(address quoteAsset, address sUSD, uint amountIn, uint amountOut);
  /**
   * @dev Emitted when usdc is swapped
   */
  event USDCCollateralSwapForMargin(address quoteAsset, address sUSD, uint amountIn, uint amountOut);
  /**
   * @dev Emitted when a new tracking code is set
   */
  event TrackingCodeSet(bytes32 trackingCode);

  ////////////
  // Errors //
  ////////////
  // Admin
  error InvalidFuturesPoolHedgerParams(address thrower, SNXPerpsV2PoolHedgerParameters params);

  // Hedging
  error InteractionDelayNotExpired(address thrower, uint lastInteraction, uint interactionDelta, uint currentTime);
  error PendingOrderDeltaError(int pendingDelta);
  // Token transfers
  error QuoteTransferFailed(address thrower, address from, address to, uint amount);
  error PerpMarketReturnedInvalid();
}
