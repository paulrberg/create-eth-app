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
import "./libraries/ConvertDecimals.sol";

// Inherited
import "./synthetix/OwnedUpgradeable.sol";

// Interfaces
import "./interfaces/IERC20Decimals.sol";

/**
 * @title BaseExchangeAdapter
 * @author Lyra
 * @dev Base contract for managing access to exchange functions.
 */
abstract contract BaseExchangeAdapter is OwnedUpgradeable {
  enum PriceType {
    MIN_PRICE, // minimise the spot based on logic in adapter - can revert
    MAX_PRICE, // maximise the spot based on logic in adapter
    REFERENCE,
    FORCE_MIN, // minimise the spot based on logic in adapter - shouldn't revert unless feeds are compromised
    FORCE_MAX
  }

  /// @dev Pause the whole market. Note; this will not pause settling previously expired options.
  mapping(address => bool) public isMarketPaused;
  // @dev Pause the whole system.
  bool public isGlobalPaused;

  uint[48] private __gap;

  ////////////////////
  // Initialization //
  ////////////////////
  function initialize() external initializer {
    __Ownable_init();
  }

  /////////////
  // Pausing //
  /////////////

  ///@dev Pauses all market actions for a given market.
  function setMarketPaused(address optionMarket, bool isPaused) external onlyOwner {
    if (optionMarket == address(0)) {
      revert InvalidAddress(address(this), optionMarket);
    }
    isMarketPaused[optionMarket] = isPaused;
    emit MarketPausedSet(optionMarket, isPaused);
  }

  /**
   * @dev Pauses all market actions across all markets.
   */
  function setGlobalPaused(bool isPaused) external onlyOwner {
    isGlobalPaused = isPaused;
    emit GlobalPausedSet(isPaused);
  }

  /// @dev Revert if the global state is paused
  function requireNotGlobalPaused(address /*optionMarket*/) external view {
    _checkNotGlobalPaused();
  }

  /// @dev Revert if the global state or market is paused
  function requireNotMarketPaused(address optionMarket) external view notPaused(optionMarket) {}

  /////////////
  // Getters //
  /////////////

  /**
   * @notice get the risk-free interest rate
   */
  function rateAndCarry(address /*_optionMarket*/) external view virtual returns (int) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Gets spot price of the optionMarket's base asset.
   * @dev All rates are denominated in terms of quoteAsset.
   *
   * @param /*pricing enum to specify which pricing to use
   */
  function getSpotPriceForMarket(
    address optionMarket,
    PriceType /*pricing*/
  ) external view virtual notPaused(optionMarket) returns (uint /*spotPrice*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Gets spot price of the optionMarket's base asset used for settlement
   * @dev All rates are denominated in terms of quoteAsset.
   *
   * @param optionMarket the baseAsset for this optionMarket
   */
  function getSettlementPriceForMarket(
    address optionMarket,
    uint /*expiry*/
  ) external view virtual notPaused(optionMarket) returns (uint /*spotPrice*/) {
    revert NotImplemented(address(this));
  }

  ////////////////////
  // Estimate swaps //
  ////////////////////

  /**
   * @notice Returns the base needed to swap for the amount in quote
   * @dev All rates are denominated in terms of quoteAsset.
   *
   * @param /*optionMarket the baseAsset used for this optionMarket
   * @param /*amountQuote the requested amount of quote
   */
  function estimateExchangeToExactQuote(
    address /*optionMarket*/,
    uint /*amountQuote*/
  ) external view virtual returns (uint /*baseNeeded*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Returns the quote needed to swap for the amount in base
   * @dev All rates are denominated in terms of quoteAsset.
   */
  function estimateExchangeToExactBase(
    address /*optionMarket*/,
    uint /*amountBase*/
  ) external view virtual returns (uint /*quoteNeeded*/) {
    revert NotImplemented(address(this));
  }

  ///////////
  // Swaps //
  ///////////

  /**
   * @notice Swaps base for quote
   * @dev All rates are denominated in terms of quoteAsset.
   */
  function exchangeFromExactBase(
    address /*optionMarket*/,
    uint /*amountBase*/
  ) external virtual returns (uint /*quoteReceived*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @dev Swap an exact amount of quote for base.
   */
  function exchangeFromExactQuote(
    address /*optionMarket*/,
    uint /*amountQuote*/
  ) external virtual returns (uint /*baseReceived*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Swaps quote for base
   * @dev All rates are denominated in terms of quoteAsset.
   *
   * @param /*quoteLimit The max amount of quote that can be used to receive `amountBase`.
   */
  function exchangeToExactBaseWithLimit(
    address /*optionMarket*/,
    uint /*amountBase*/,
    uint /*quoteLimit*/
  ) external virtual returns (uint /*quoteSpent*/, uint /*baseReceived*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Swap an exact amount of base for any amount of quote.
   */
  function exchangeToExactBase(
    address /*optionMarket*/,
    uint /*amountBase*/
  ) external virtual returns (uint /*quoteSpent*/, uint /*baseReceived*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Swaps quote for base
   * @dev All rates are denominated in terms of quoteAsset.
   *
   * @param /*baseLimit The max amount of base that can be used to receive `amountQuote`.
   */
  function exchangeToExactQuoteWithLimit(
    address /*optionMarket*/,
    uint /*amountQuote*/,
    uint /*baseLimit*/
  ) external virtual returns (uint /*quoteSpent*/, uint /*baseReceived*/) {
    revert NotImplemented(address(this));
  }

  /**
   * @notice Swap to an exact amount of quote for any amount of base.
   */
  function exchangeToExactQuote(
    address /*optionMarket*/,
    uint /*amountQuote*/
  ) external virtual returns (uint /*baseSpent*/, uint /*quoteReceived*/) {
    revert NotImplemented(address(this));
  }

  //////////////
  // Internal //
  //////////////
  function _receiveAsset(IERC20Decimals asset, uint amount) internal returns (uint convertedAmount) {
    convertedAmount = ConvertDecimals.convertFrom18(amount, asset.decimals());
    if (!asset.transferFrom(msg.sender, address(this), convertedAmount)) {
      revert AssetTransferFailed(address(this), asset, msg.sender, address(this), convertedAmount);
    }
  }

  function _transferAsset(IERC20Decimals asset, address recipient, uint amount) internal {
    uint convertedAmount = ConvertDecimals.convertFrom18(amount, asset.decimals());
    if (!asset.transfer(recipient, convertedAmount)) {
      revert AssetTransferFailed(address(this), asset, address(this), recipient, convertedAmount);
    }
  }

  function _checkNotGlobalPaused() internal view {
    if (isGlobalPaused) {
      revert AllMarketsPaused(address(this));
    }
  }

  function _checkNotMarketPaused(address contractAddress) internal view {
    if (isMarketPaused[contractAddress]) {
      revert MarketIsPaused(address(this), contractAddress);
    }
  }

  ///////////////
  // Modifiers //
  ///////////////

  modifier notPaused(address contractAddress) {
    _checkNotGlobalPaused();
    _checkNotMarketPaused(contractAddress);
    _;
  }

  ////////////
  // Events //
  ////////////

  /// @dev Emitted when GlobalPause.
  event GlobalPausedSet(bool isPaused);
  /// @dev Emitted when single market paused.
  event MarketPausedSet(address indexed contractAddress, bool isPaused);

  /**
   * @dev Emitted when an exchange for base to quote occurs.
   * Which base and quote were swapped can be determined by the given marketAddress.
   */
  event BaseSwappedForQuote(
    address indexed marketAddress,
    address indexed exchanger,
    uint baseSwapped,
    uint quoteReceived
  );

  /**
   * @dev Emitted when an exchange for quote to base occurs.
   * Which base and quote were swapped can be determined by the given marketAddress.
   */
  event QuoteSwappedForBase(
    address indexed marketAddress,
    address indexed exchanger,
    uint quoteSwapped,
    uint baseReceived
  );

  ////////////
  // Errors //
  ////////////

  // Admin
  error InvalidAddress(address thrower, address inputAddress);
  error NotImplemented(address thrower);

  // Market Paused
  error AllMarketsPaused(address thrower);
  error MarketIsPaused(address thrower, address marketAddress);

  // Swapping errors
  error AssetTransferFailed(address thrower, IERC20Decimals asset, address sender, address receiver, uint amount);
  error TransferFailed(address thrower, IERC20Decimals asset, address from, address to, uint amount);
  error InsufficientSwap(
    address thrower,
    uint amountOut,
    uint minAcceptedOut,
    IERC20Decimals tokenIn,
    IERC20Decimals tokenOut,
    address receiver
  );
  error QuoteBaseExchangeExceedsLimit(
    address thrower,
    uint amountBaseRequested,
    uint quoteToSpend,
    uint quoteLimit,
    uint spotPrice,
    bytes32 quoteKey,
    bytes32 baseKey
  );

  error BaseQuoteExchangeExceedsLimit(
    address thrower,
    uint amountQuoteRequested,
    uint baseToSpend,
    uint baseLimit,
    uint spotPrice,
    bytes32 baseKey,
    bytes32 quoteKey
  );
}
