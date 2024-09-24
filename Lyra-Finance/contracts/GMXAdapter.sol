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
import "./libraries/Math.sol";

// Inherited
import "./BaseExchangeAdapter.sol";

// Interfaces
import "./interfaces/gmx/IVault.sol";
import "./interfaces/IAggregatorV3.sol";
import "./interfaces/IERC20Decimals.sol";
import "./OptionMarket.sol";

/**
 * @title GMXAdapter
 * @author Lyra
 * @dev Manages access to exchange functions on GMX.
 */
contract GMXAdapter is BaseExchangeAdapter {
  using DecimalMath for uint;
  using SafeCast for uint;
  using SafeCast for int;

  /////
  // View struct

  struct GMXAdapterState {
    AggregatorV2V3Interface chainlinkFeed;
    MarketPricingParams marketPricingParams;
    int rateAndCarry;
    uint clPrice;
    uint gmxMinPrice;
    uint gmxMaxPrice;
  }

  /////
  // State struct

  struct MarketPricingParams {
    uint staticSwapFeeEstimate;
    uint gmxUsageThreshold;
    uint priceVarianceCBPercent;
    uint chainlinkStalenessCheck;
  }

  IVault public vault;

  /// @dev Asset to chainlink feed
  mapping(address => AggregatorV2V3Interface) public chainlinkFeeds;

  /// @dev option market to min percentage that swap should return compared to amount calculated by prices. 1e18 is 100%
  mapping(address => MarketPricingParams) public marketPricingParams;

  /// @dev option market to risk free interest rate
  mapping(address => int) public override rateAndCarry;

  uint public constant GMX_PRICE_PRECISION = 10 ** 30;

  ///////////
  // Admin //
  ///////////

  /// @notice Sets the GMX vault contract
  function setVaultContract(IVault _vault) external onlyOwner {
    if (address(_vault) == address(0)) revert InvalidAddress(address(this), address(_vault));

    vault = _vault;

    emit GMXVaultAddressUpdated(address(_vault));
  }

  /**
   * @notice Sets an assets chainlink pricefeed
   */
  function setChainlinkFeed(address _asset, AggregatorV2V3Interface _assetPriceFeed) external onlyOwner {
    if (_asset == address(0)) revert InvalidAddress(address(this), _asset);
    if (address(_assetPriceFeed) == (address(0))) revert InvalidPriceFeedAddress(address(this), _assetPriceFeed);

    chainlinkFeeds[_asset] = _assetPriceFeed;

    emit ChainlinkAggregatorUpdated(_asset, address(_assetPriceFeed));
  }

  /**
   * @notice set min return percentage for an option market
   */
  function setMarketPricingParams(
    address _optionMarket,
    MarketPricingParams memory _marketPricingParams
  ) external onlyOwner {
    if (_marketPricingParams.staticSwapFeeEstimate < 1e18) {
      revert InvalidMarketPricingParams(_marketPricingParams);
    }

    marketPricingParams[_optionMarket] = _marketPricingParams;

    emit MarketPricingParamsUpdated(_optionMarket, _marketPricingParams);
  }

  /**
   * @notice update risk free rate by owner
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
    uint clPrice = _getChainlinkPrice(optionMarket);

    // skip variance check on max and min if reference price is requested
    if (pricing == PriceType.REFERENCE) {
      return clPrice;
    }

    address baseAsset = address(OptionMarket(optionMarket).baseAsset());

    // check both min and max prices are within deviation threshold from reference price
    uint maxPrice = _getMaxPrice(baseAsset);
    uint minPrice = _getMinPrice(baseAsset);

    uint maxVariance = _getPriceVariance(maxPrice, clPrice);
    uint minVariance = _getPriceVariance(minPrice, clPrice);

    // Prevent opening and closing in the case where the feeds differ by a great amount, but allow force closes.
    if (pricing == PriceType.MAX_PRICE || pricing == PriceType.MIN_PRICE) {
      uint varianceThreshold = marketPricingParams[optionMarket].priceVarianceCBPercent;
      if (minVariance > varianceThreshold || maxVariance > varianceThreshold) {
        revert PriceVarianceTooHigh(address(this), minPrice, maxPrice, clPrice, varianceThreshold);
      }
    }

    // In the case where the gmxUsageThreshold is crossed, we want to use the worst case price between cl and gmx
    bool useWorstCase = false;
    if (
      (minVariance > marketPricingParams[optionMarket].gmxUsageThreshold ||
        maxVariance > marketPricingParams[optionMarket].gmxUsageThreshold)
    ) {
      useWorstCase = true;
    }

    if (pricing == PriceType.FORCE_MIN || pricing == PriceType.MIN_PRICE) {
      return (useWorstCase && minPrice > clPrice) ? clPrice : minPrice;
    } else {
      return (useWorstCase && maxPrice < clPrice) ? clPrice : maxPrice;
    }
  }

  /**
   * @dev check that the price is within variance tolerance with the reference price
   */
  function _getPriceVariance(uint price, uint refPrice) internal pure returns (uint variance) {
    return Math.abs(price.divideDecimalRound(refPrice).toInt256() - SignedDecimalMath.UNIT);
  }

  /**
   * @notice Gets spot price of the optionMarket's base asset used for settlement
   */
  function getSettlementPriceForMarket(
    address optionMarket,
    uint
  ) external view override notPaused(optionMarket) returns (uint spotPrice) {
    return _getChainlinkPrice(optionMarket);
  }

  /**
   * @notice get min price from GMX vault
   * @return price in 18 decimals
   */
  function _getMinPrice(address asset) internal view returns (uint) {
    uint minPrice = vault.getMinPrice(asset);
    return ConvertDecimals.normaliseTo18(minPrice, GMX_PRICE_PRECISION);
  }

  /**
   * @notice get max price from GMX vault
   * @return price in 18 decimals
   */
  function _getMaxPrice(address asset) internal view returns (uint) {
    uint maxPrice = vault.getMaxPrice(asset);
    return ConvertDecimals.normaliseTo18(maxPrice, GMX_PRICE_PRECISION);
  }

  /**
   * @notice get base asset price from Chainlink aggregator
   * @param optionMarket option market address
   * @return spotPrice price in 18 decimals
   */
  function _getChainlinkPrice(address optionMarket) internal view notPaused(optionMarket) returns (uint spotPrice) {
    AggregatorV2V3Interface assetPriceFeed = chainlinkFeeds[address(OptionMarket(optionMarket).baseAsset())];
    if (assetPriceFeed == AggregatorV2V3Interface(address(0))) {
      revert InvalidPriceFeedAddress(address(this), assetPriceFeed);
    }

    // use latestRoundData because getLatestAnswer is deprecated
    (, int answer, , uint updatedAt, ) = assetPriceFeed.latestRoundData();
    if (answer <= 0 || block.timestamp - updatedAt > marketPricingParams[optionMarket].chainlinkStalenessCheck) {
      revert InvalidAnswer(address(this), answer, updatedAt, block.timestamp);
    }
    spotPrice = ConvertDecimals.convertTo18(answer.toUint256(), assetPriceFeed.decimals());
  }

  ////////////////////
  // Estimate swaps //
  ////////////////////

  /**
   * @notice Returns the base needed to swap from the amount quote
   * @dev All rates are denominated in terms of quoteAsset.
   */
  function estimateExchangeToExactQuote(
    address _optionMarket,
    uint _amountQuote
  ) public view override returns (uint baseNeeded) {
    uint tokenInPrice = _getMinPrice(address(OptionMarket(_optionMarket).baseAsset()));
    uint tokenOutPrice = _getMaxPrice(address(OptionMarket(_optionMarket).quoteAsset()));

    return _estimateExchangeCost(_optionMarket, tokenInPrice, tokenOutPrice, _amountQuote);
  }

  /**
   * @notice Returns the quote needed to swap from the amount base
   * @dev All rates are denominated in terms of quoteAsset.
   */
  function estimateExchangeToExactBase(
    address _optionMarket,
    uint _amountBase
  ) public view override returns (uint quoteNeeded) {
    uint tokenInPrice = _getMinPrice(address(OptionMarket(_optionMarket).quoteAsset()));
    uint tokenOutPrice = _getMaxPrice(address(OptionMarket(_optionMarket).baseAsset()));

    return _estimateExchangeCost(_optionMarket, tokenInPrice, tokenOutPrice, _amountBase);
  }

  /**
   * @dev estimate amount of input needed, estimate with static swap fee
   * @param optionMarket option market address to map to estimate fee
   * @param tokenInPrice input token price
   * @param tokenOutPrice output token price
   * @param tokenOutAmt amount of output token needed
   * @param tokenInAmt amount needed, considering fees
   */
  function _estimateExchangeCost(
    address optionMarket,
    uint tokenInPrice,
    uint tokenOutPrice,
    uint tokenOutAmt
  ) internal view returns (uint tokenInAmt) {
    if (marketPricingParams[optionMarket].staticSwapFeeEstimate < 1e18) {
      revert InvalidStaticSwapFeeEstimate();
    }
    return
      tokenOutPrice
        .multiplyDecimalRound(tokenOutAmt)
        .multiplyDecimalRound(marketPricingParams[optionMarket].staticSwapFeeEstimate)
        .divideDecimal(tokenInPrice);
  }

  ///////////
  // Swaps //
  ///////////

  /**
   * @notice Swaps base for quote
   * @dev All rates are denominated in terms of quoteAsset.
   *
   * @param _optionMarket the baseAsset used for this _optionMarket
   * @param _amountBase the amount of base to be swapped. In 18 decimals
   * @return quoteReceived amount quote received in 18 decimals
   */
  function exchangeFromExactBase(
    address _optionMarket,
    uint _amountBase
  ) public override notPaused(_optionMarket) returns (uint quoteReceived) {
    IERC20Decimals baseAsset = OptionMarket(_optionMarket).baseAsset();
    IERC20Decimals quoteAsset = OptionMarket(_optionMarket).quoteAsset();

    uint tokenInPrice = _getChainlinkPrice(_optionMarket);
    uint tokenOutPrice = _getMaxPrice(address(quoteAsset));

    if (marketPricingParams[_optionMarket].staticSwapFeeEstimate < 1e18) {
      revert InvalidStaticSwapFeeEstimate();
    }

    uint minOut = tokenInPrice
      .divideDecimal(marketPricingParams[_optionMarket].staticSwapFeeEstimate)
      .multiplyDecimal(_amountBase)
      .divideDecimal(tokenOutPrice);

    // Transfer base to vault for the swap
    uint scaledAmtBase = _receiveAsset(baseAsset, _amountBase);
    _transferAsset(baseAsset, address(vault), _amountBase);

    // Swap and transfer directly to the requester
    uint rawQuoteReceived = vault.swap(address(baseAsset), address(quoteAsset), msg.sender);

    // complying to standard of adapter always taking in 1e18 and returning 1e18
    quoteReceived = ConvertDecimals.convertTo18(rawQuoteReceived, quoteAsset.decimals());

    if (quoteReceived < minOut) {
      revert InsufficientSwap(address(this), quoteReceived, minOut, baseAsset, quoteAsset, msg.sender);
    }

    emit BaseSwappedForQuote(_optionMarket, msg.sender, scaledAmtBase, quoteReceived);
  }

  /**
   * @notice Swaps quote for base
   * @dev All rates are denominated in terms of quoteAsset.
   * @dev this implementation "WILL NOT" give you exact base after swap.
   *
   * @param _optionMarket the baseAsset used for this _optionMarket
   * @param _amountBase the desired amount of base to receive
   * @param _quoteLimit the max amount of quote that can be used
   */
  function exchangeToExactBaseWithLimit(
    address _optionMarket,
    uint _amountBase,
    uint _quoteLimit
  ) public override notPaused(_optionMarket) returns (uint quoteSpent, uint baseReceived) {
    IERC20Decimals quoteAsset = OptionMarket(_optionMarket).quoteAsset();
    IERC20Decimals baseAsset = OptionMarket(_optionMarket).baseAsset();

    uint quoteNeeded = estimateExchangeToExactBase(_optionMarket, _amountBase);
    if (quoteNeeded > _quoteLimit) {
      // We'll still try the transfer with the given limit, but if we receive too little we'll revert
      quoteNeeded = _quoteLimit;
    }

    quoteSpent = _receiveAsset(quoteAsset, quoteNeeded);
    _transferAsset(quoteAsset, address(vault), quoteNeeded);

    // GMX Vault swaps and then sends tokenOut to msg.sender
    baseReceived = vault.swap(address(quoteAsset), address(baseAsset), msg.sender);

    // convert to 18 decimals
    uint convertedBaseReceived = ConvertDecimals.convertTo18(baseReceived, baseAsset.decimals());

    if (convertedBaseReceived < _amountBase) {
      revert InsufficientSwap(address(this), convertedBaseReceived, _amountBase, quoteAsset, baseAsset, msg.sender);
    }

    emit QuoteSwappedForBase(_optionMarket, msg.sender, quoteSpent, convertedBaseReceived);
    return (quoteNeeded, convertedBaseReceived);
  }

  function getAdapterState(address _optionMarket) external view returns (GMXAdapterState memory) {
    address baseAsset = address(OptionMarket(_optionMarket).baseAsset());
    return
      GMXAdapterState({
        chainlinkFeed: chainlinkFeeds[baseAsset],
        marketPricingParams: marketPricingParams[_optionMarket],
        rateAndCarry: rateAndCarry[_optionMarket],
        clPrice: _getChainlinkPrice(_optionMarket),
        gmxMinPrice: _getMinPrice(baseAsset),
        gmxMaxPrice: _getMaxPrice(baseAsset)
      });
  }

  ////////////
  // Errors //
  ////////////
  error InvalidMarketPricingParams(MarketPricingParams params);
  error InvalidStaticSwapFeeEstimate();
  error InvalidPriceFeedAddress(address thrower, AggregatorV2V3Interface inputAddress);
  error InvalidAnswer(address thrower, int answer, uint updatedAt, uint blockTimestamp);
  error PriceVarianceTooHigh(address thrower, uint minPrice, uint maxPrice, uint clPrice, uint priceVarianceCBPercent);
  error InvalidRiskFreeRate();

  //////////////
  //  Events  //
  //////////////
  event GMXVaultAddressUpdated(address vault);
  event ChainlinkAggregatorUpdated(address indexed asset, address indexed aggregator);
  event MarketPricingParamsUpdated(address indexed optionMarket, MarketPricingParams marketPricingParams);
  event RiskFreeRateUpdated(address indexed optionMarket, int256 newRate);
}
