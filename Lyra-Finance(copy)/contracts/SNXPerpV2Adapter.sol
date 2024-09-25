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
pragma solidity =0.8.16;

import "Lyra-Finance/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// Libraries
import "./libraries/ConvertDecimals.sol";

// Inherited
import "./BaseExchangeAdapter.sol";

// Interfaces
import "./interfaces/perpsV2/IPerpsV2MarketConsolidated.sol";
import "./interfaces/perpsV2/ISystemStatus.sol";
import "./interfaces/IERC20Decimals.sol";
import "./interfaces/IAddressResolver.sol";
import "./OptionMarket.sol";

/**
 * @title SNXPerpV2Adapter
 * @author Lyra
 * @dev adapter that get prices from SNX PerpV2 markets, and swap tokens on Uniswap
 */
contract SNXPerpV2Adapter is BaseExchangeAdapter {
  using DecimalMath for uint;
  using SafeCast for uint;
  using SafeCast for int;
  using ConvertDecimals for uint;

  bytes32 internal constant SYSTEM_STATUS = "SystemStatus";

  IAddressResolver public addressResolver;
  ISystemStatus public systemStatus;
  ISwapRouter public swapRouter;

  uint public uniDeviation;

  struct UniswapPoolInfo {
    address pool;
    uint24 feeTier;
  }

  struct MarketAdapterConfiguration {
    /// @dev static estimation discount, applied to spot in estimateExchangeToExactQuote
    /// @dev 1e18 = 100%, 1e16 means we assume we need 1% more asset than calculated by spot price
    uint staticEstimationDiscount;
    /// @dev SNX PerpV2 market address
    address snxPerpV2MarketAddress;
    /// @dev Uniswap v3 pool address and fee tier
    UniswapPoolInfo uniswapInfo;
  }

  struct MarketAdapterState {
    MarketAdapterConfiguration config;
    uint snxPrice;
    int riskFreeRate;
  }

  mapping(address => MarketAdapterConfiguration) public marketConfigurations;

  /// @dev market to risk free interest rate
  mapping(address => int) public override rateAndCarry;

  ///////////
  // Admin //
  ///////////

  /**
   * @dev set the swap router
   */
  function setUniswapRouter(ISwapRouter _swapRouter) external onlyOwner {
    swapRouter = _swapRouter;
    emit UniswapRouterUpdated(address(_swapRouter));
  }

  function setAddressResolver(IAddressResolver _addressResolver) external onlyOwner {
    addressResolver = _addressResolver;
    updateSynthetixAddresses();
    emit AddressResolverUpdated(address(addressResolver));
  }

  function setUniSwapDeviation(uint _deviation) external onlyOwner {
    uniDeviation = _deviation;
    emit UniDeviationUpdated(_deviation);
  }

  function updateSynthetixAddresses() public {
    systemStatus = ISystemStatus(addressResolver.getAddress(SYSTEM_STATUS));
    emit SynthetixSystemStatusUpdated(address(systemStatus));
  }

  /**
   * @dev approve the uniswap router to spend the asset
   * @dev this has to be called for all assets for all option market
   */
  function approveRouter(IERC20Decimals asset) external onlyOwner {
    asset.approve(address(swapRouter), type(uint).max);

    emit RouterApproved(address(asset), address(swapRouter));
  }

  /**
   * @dev function to set all config for a pool
   */
  function setMarketAdapterConfiguration(
    address _optionMarket,
    uint _staticEstimationDiscount,
    address _snxPerpV2MarketAddress,
    address _uniswapPool,
    uint24 _uniswapFeeTier
  ) external onlyOwner {
    // static estimation discount cannot be higher than 20%
    if (_staticEstimationDiscount > 0.2e18) revert InvalidStaticEstimationDiscount();

    marketConfigurations[_optionMarket].staticEstimationDiscount = _staticEstimationDiscount;
    marketConfigurations[_optionMarket].snxPerpV2MarketAddress = _snxPerpV2MarketAddress;
    marketConfigurations[_optionMarket].uniswapInfo = UniswapPoolInfo(
      _uniswapPool,
      _uniswapFeeTier
    );

    emit MarketAdapterConfigurationUpdated(
      _optionMarket,
      _staticEstimationDiscount,
      _snxPerpV2MarketAddress,
      _uniswapPool,
      _uniswapFeeTier
    );
  }

  /**
   * @notice update risk free rate
   * @param _rate risk free rate with 18 decimals
   */
  function setRiskFreeRate(address _optionMarket, int _rate) external onlyOwner {
    if (_rate > 50e18 || _rate < -50e18) revert InvalidRiskFreeRate();
    rateAndCarry[_optionMarket] = _rate;

    emit RiskFreeRateUpdated(_optionMarket, _rate);
  }

  /////////////
  // Getters //
  /////////////

  /**
   * @notice Gets spot price of the optionMarket's base asset.
   * @dev All rates are denominated in terms of quoteAsset.
   * @param optionMarket optionMarket address
   * @param pricing enum to specify which pricing to use
   */
  function getSpotPriceForMarket(
    address optionMarket,
    PriceType pricing
  ) external view override notPaused(optionMarket) returns (uint spotPrice) {
    // get price from the snx perp market (chainlink)
    uint snxPrice = _getSNXPerpV2Price(optionMarket, pricing != PriceType.REFERENCE);

    return snxPrice;
  }

  /**
   * @notice Gets spot price of the optionMarket's base asset used for settlement
   */
  function getSettlementPriceForMarket(
    address _optionMarket,
    uint
  ) external view override notPaused(_optionMarket) returns (uint spotPrice) {
    return _getSNXPerpV2Price(_optionMarket, false);
  }

  /**
   * @notice Gets the price of the base asset from SNX PerpV2 market
   */
  function _getSNXPerpV2Price(address _optionMarket, bool revertOnSuspended) internal view returns (uint) {
    address market = marketConfigurations[_optionMarket].snxPerpV2MarketAddress;

    // check market status
    bytes32 marketKey = IPerpsV2MarketConsolidated(market).marketKey();
    (bool suspended, uint248 reason) = systemStatus.futuresMarketSuspension(marketKey);
    if (revertOnSuspended && suspended) revert SNXPerpV2MarketSuspended(_optionMarket, reason);

    (uint price, bool invalid) = IPerpsV2MarketConsolidated(market).assetPrice();
    if (invalid) revert InvalidSNXPerpV2Price();

    return price;
  }

  /**
   * @notice Gets both the uniswap price and the snx settlement price
   */
  function getPrices(address optionMarket) external view returns(uint) {
    return _getSNXPerpV2Price(optionMarket, true);
  }

  /**
   * @notice Gets the state of the hedger in a single call 
   */
  function getAdapterState(address optionMarket) external view returns (MarketAdapterState memory) {
    return(
      MarketAdapterState({
        snxPrice: _getSNXPerpV2Price(optionMarket, true),
        riskFreeRate: rateAndCarry[optionMarket],
        config: marketConfigurations[optionMarket]
      })
    );
  }

  ////////////////////
  // Estimate swaps //
  ////////////////////

  /**
   * @notice Returns the base (ETH) needed to swap from the amount quote (USD)
   * @dev this function estimate the amount needed by applying a fixed percentage of slippage
   *      on worse price between SNX and Uniswap oracles
   */
  function estimateExchangeToExactQuote(
    address _optionMarket,
    uint _amountQuoteD18
  ) public view override returns (uint baseNeededD18) {
    // get the lower of the two prices
    uint price = _getSNXPerpV2Price(_optionMarket, true);

    // apply a fixed percentage of slippage to the price, and calculate base needed
    uint discount = marketConfigurations[_optionMarket].staticEstimationDiscount;
    uint priceWithBuffer = price.multiplyDecimal(DecimalMath.UNIT - discount);
    baseNeededD18 = _amountQuoteD18.divideDecimal(priceWithBuffer);
  }

  /**
   * @notice Returns the quote (USD) needed to swap for amount base (ETH)
   * @dev this function estimate the amount needed by applying a fixed percentage of slippage
   *      on worse price between SNX and Uniswap oracles
   */
  function estimateExchangeToExactBase(
    address _optionMarket,
    uint _amountBaseD18
  ) public view override returns (uint quoteNeededD18) {
    // get the higher of the two prices
    uint price = _getSNXPerpV2Price(_optionMarket, true);

    // apply a fixed percentage of slippage to the price, and calculate base needed
    uint discount = marketConfigurations[_optionMarket].staticEstimationDiscount;
    uint priceWithBuffer = price.multiplyDecimal(DecimalMath.UNIT + discount);
    quoteNeededD18 = _amountBaseD18.multiplyDecimal(priceWithBuffer);
  }

  ///////////
  // Swaps //
  ///////////

  /**
   * @notice Swaps base for quote
   * @dev This function is only used in liquidity pool if baseAsset balance > 0
   *
   * @param _optionMarket the baseAsset used for this _optionMarket
   * @param _amountBaseD18 the amount of base to be swapped. In 18 decimals
   * @return quoteReceivedD18 amount quote received in 18 decimals
   */
  function exchangeFromExactBase(
    address _optionMarket,
    uint _amountBaseD18
  ) public override notPaused(_optionMarket) returns (uint quoteReceivedD18) {
    IERC20Decimals quote = OptionMarket(_optionMarket).quoteAsset();
    IERC20Decimals base = OptionMarket(_optionMarket).baseAsset();

    // transfer token in from msg.sender
    uint amountBaseInAsset = _receiveAsset(base, _amountBaseD18);
    // calculate min quote needed by snx price * (0.97)
    uint price = _getSNXPerpV2Price(_optionMarket, true);
    uint minQuoteOutE18 = _amountBaseD18.multiplyDecimal(price).multiplyDecimal(uniDeviation);
    uint minQuoteOut = minQuoteOutE18.convertFrom18(quote.decimals());

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: address(base),
      tokenOut: address(quote),
      fee: marketConfigurations[_optionMarket].uniswapInfo.feeTier,
      recipient: msg.sender,
      deadline: block.timestamp + 5,
      amountIn: amountBaseInAsset,
      amountOutMinimum: minQuoteOut,
      sqrtPriceLimitX96: 0
    });
    // swap will revert if amountOutMinimum is not met
    quoteReceivedD18 = swapRouter.exactInputSingle(params).convertTo18(quote.decimals());
    emit ExchangedFromExactBase(
      _optionMarket,
      quoteReceivedD18,
      _amountBaseD18
    );
  }

  /**
   * @notice Swaps quote for base
   * @dev All rates are denominated in terms of quoteAsset.
   * @param _optionMarket the baseAsset used for this _optionMarket
   * @param _amountBaseD18 the desired amount of base to receive
   * @param _quoteLimitD18 the max amount of quote that can be used, (all free liquidity)
   */
  function exchangeToExactBaseWithLimit(
    address _optionMarket,
    uint _amountBaseD18,
    uint _quoteLimitD18
  ) public override notPaused(_optionMarket) returns (uint quoteSpentD18, uint baseReceivedD18) {
    IERC20Decimals quote = OptionMarket(_optionMarket).quoteAsset();
    IERC20Decimals base = OptionMarket(_optionMarket).baseAsset();

    // calculate max quote willing to send by snx price * (1.03)
    uint price = _getSNXPerpV2Price(_optionMarket, true);
    uint maxQuoteD18 = _amountBaseD18.multiplyDecimal(price).multiplyDecimal(DecimalMath.UNIT + (DecimalMath.UNIT - uniDeviation));
    uint amountBase = _amountBaseD18.convertFrom18(base.decimals());

    // We'll still try the trade with the given limit, but if we receive too little we'll revert
    if (maxQuoteD18 > _quoteLimitD18) {
      maxQuoteD18 = _quoteLimitD18;
    }

    uint24 feeTier;
    // Stack too deep, so we declare the variable here
    feeTier = marketConfigurations[_optionMarket].uniswapInfo.feeTier;
    
    {
      // transfer max amount of quote from msg.sender
      uint maxQuoteIn = _receiveAsset(quote, maxQuoteD18);

      // this will revert if max quote in is not enough to get the desired base out
      ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
        tokenIn: address(quote),
        tokenOut: address(base),
        fee: feeTier,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountOut: amountBase,
        amountInMaximum: maxQuoteIn,
        sqrtPriceLimitX96: 0
      });

      // swap will revert if amountOutMinimum is not met
      uint quoteSpent = swapRouter.exactOutputSingle(params);
      quoteSpentD18 = quoteSpent.convertTo18(quote.decimals());
      baseReceivedD18 = _amountBaseD18;

      if (quoteSpent < maxQuoteIn) {
        // refund unused quote
        quote.transfer(msg.sender, quote.balanceOf(address(this)));
      }
    }
    emit ExchangeToExactBaseWithLimit(
      _optionMarket,
      quoteSpentD18,
      baseReceivedD18
    );
  }

  ////////////
  // Errors //
  ////////////
  error InvalidRiskFreeRate();
  error InvalidSNXPerpV2Price();
  error InvalidStaticEstimationDiscount();
  error SNXPerpV2MarketSuspended(address optionMarket, uint248 reason);

  //////////////
  //  Events  //
  //////////////
  event MarketAdapterConfigurationUpdated(
    address indexed optionMarket,
    uint staticEstimationDiscount,
    address snxPerpV2Market,
    address uniswapPool,
    uint feeTier
  );
  event RiskFreeRateUpdated(address indexed optionMarket, int riskFreeRate);
  event AddressResolverUpdated(address addressResolver);
  event UniswapRouterUpdated(address uniswapRouter);
  event RouterApproved(address indexed asset, address uniswapRouter);
  event SynthetixSystemStatusUpdated(address synthetixSystemStatus);
  event UniDeviationUpdated(uint deviation);
  event ExchangedFromExactBase(
    address indexed optionMarket,
    uint quoteSpentD18,
    uint baseAssetinD18
  );
  event ExchangeToExactBaseWithLimit(
    address indexed optionMarket,
    uint quoteSpentD18,
    uint baseAssetinD18
  );
}
