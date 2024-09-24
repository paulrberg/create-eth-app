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
import "../synthetix/DecimalMath.sol";

// Inherited
import "../synthetix/OwnedUpgradeable.sol";

// Interfaces
import "../interfaces/ISynthetix.sol";
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/IExchangeRates.sol";

import "../LiquidityPool.sol";
import "../interfaces/IDelegateApprovals.sol";

/**
 * @title SynthetixAdapterV2
 * @author Lyra
 * @dev Copy of SynthetixAdapter but returns 10x the spot price in getExchangeParams.
 * Used for testing upgradeability.
 */
contract TestSynthetixAdapterV2 is BaseExchangeAdapter {
  using DecimalMath for uint;

  /**
   * @dev Structs to help reduce the number of calls between other contracts and this one
   * Grouped in usage for a particular contract/use case
   */
  struct ExchangeParams {
    uint spotPrice;
    bytes32 quoteKey;
    bytes32 baseKey;
    uint quoteBaseFeeRate;
    uint baseQuoteFeeRate;
  }

  IAddressResolver public addressResolver;

  bytes32 private constant CONTRACT_SYNTHETIX = "ProxySynthetix";
  bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
  bytes32 private constant CONTRACT_EXCHANGE_RATES = "ExchangeRates";
  bytes32 private constant CONTRACT_DELEGATE_APPROVALS = "DelegateApprovals";

  // Cached addresses that can be updated via a public function
  ISynthetix public synthetix;
  IExchanger public exchanger;
  IExchangeRates public exchangeRates;
  IDelegateApprovals public delegateApprovals;

  // Variables related to calculating premium/fees
  mapping(address => bytes32) public quoteKey;
  mapping(address => bytes32) public baseKey;
  mapping(address => address) public rewardAddress;
  mapping(address => bytes32) public trackingCode;
  mapping(address => int256) public override rateAndCarry;

  /////////////
  // Setters //
  /////////////

  /**
   * @dev Set the address of the Synthetix address resolver.
   *
   * @param _addressResolver The address of Synthetix's AddressResolver.
   */
  function setAddressResolver(IAddressResolver _addressResolver) external onlyOwner {
    addressResolver = _addressResolver;
    updateSynthetixAddresses();
    emit AddressResolverSet(addressResolver);
  }

  /**
   * @dev Set the synthetixAdapter for a specific OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _quoteKey The key of the quoteAsset.
   * @param _baseKey The key of the baseAsset.
   */
  function setGlobalsForContract(
    address _contractAddress,
    bytes32 _quoteKey,
    bytes32 _baseKey,
    address _rewardAddress,
    bytes32 _trackingCode
  ) external onlyOwner {
    quoteKey[_contractAddress] = _quoteKey;
    baseKey[_contractAddress] = _baseKey;
    rewardAddress[_contractAddress] = _rewardAddress;
    trackingCode[_contractAddress] = _trackingCode;
  }

  //////////////////////
  // Address Resolver //
  //////////////////////

  /**
   * @dev Public function to update synthetix addresses Lyra uses. The addresses are cached this way for gas efficiency.
   */
  function updateSynthetixAddresses() public {
    synthetix = ISynthetix(addressResolver.getAddress(CONTRACT_SYNTHETIX));
    exchanger = IExchanger(addressResolver.getAddress(CONTRACT_EXCHANGER));
    exchangeRates = IExchangeRates(addressResolver.getAddress(CONTRACT_EXCHANGE_RATES));
    delegateApprovals = IDelegateApprovals(addressResolver.getAddress(CONTRACT_DELEGATE_APPROVALS));

    emit SynthetixAddressesUpdated(synthetix, exchanger, exchangeRates, delegateApprovals);
  }

  /////////////
  // Getters //
  /////////////
  /**
   * @notice Returns the price of the baseAsset.
   *
   * @param _contractAddress The address of the OptionMarket.
   */
  function getSpotPriceForMarket(address _contractAddress) public view notPaused(_contractAddress) returns (uint) {
    return getSpotPrice(baseKey[_contractAddress]);
  }

  /**
   * @notice Gets spot price of an asset.
   * @dev All rates are denominated in terms of sUSD,
   * so the price of sUSD is always $1.00, and is never stale.
   *
   * @param to The key of the synthetic asset.
   */
  function getSpotPrice(bytes32 to) public view returns (uint) {
    (uint rate, bool invalid) = exchangeRates.rateAndInvalid(to);
    require(!invalid && rate != 0, "RateIsInvalid");
    return rate;
  }

  /**
   * @notice Returns the ExchangeParams.
   *
   * @param _contractAddress The address of the OptionMarket.
   */
  function getExchangeParams(
    address _contractAddress
  ) public view notPaused(_contractAddress) returns (ExchangeParams memory exchangeParams) {
    exchangeParams = ExchangeParams({
      spotPrice: 0,
      quoteKey: quoteKey[_contractAddress],
      baseKey: baseKey[_contractAddress],
      quoteBaseFeeRate: 0,
      baseQuoteFeeRate: 0
    });
    // upgraded logic
    exchangeParams.spotPrice = getSpotPrice(exchangeParams.baseKey).multiplyDecimal(10 * DecimalMath.UNIT);
    exchangeParams.quoteBaseFeeRate = exchanger.feeRateForExchange(exchangeParams.quoteKey, exchangeParams.baseKey);
    exchangeParams.baseQuoteFeeRate = exchanger.feeRateForExchange(exchangeParams.baseKey, exchangeParams.quoteKey);
  }

  //////////////
  // Swapping //
  //////////////

  function exchangeToExactBaseWithLimit(
    ExchangeParams memory exchangeParams,
    address optionMarket,
    uint amountBase,
    uint quoteLimit
  ) external returns (uint received) {
    uint quoteToSpend = amountBase
      .divideDecimalRound(DecimalMath.UNIT - exchangeParams.quoteBaseFeeRate)
      .multiplyDecimalRound(exchangeParams.spotPrice);

    require(quoteToSpend <= quoteLimit, "Not enough free quote to exchange");

    return _exchangeQuoteForBase(msg.sender, optionMarket, quoteToSpend);
  }

  function exchangeForExactBase(
    ExchangeParams memory exchangeParams,
    address optionMarket,
    uint amountBase
  ) public returns (uint received) {
    uint quoteToSpend = estimateExchangeForExactBase(exchangeParams, amountBase);

    return _exchangeQuoteForBase(msg.sender, optionMarket, quoteToSpend);
  }

  function exchangeFromExactQuote(address optionMarket, uint amountQuote) public override returns (uint received) {
    return _exchangeQuoteForBase(msg.sender, optionMarket, amountQuote);
  }

  function _exchangeQuoteForBase(
    address sender,
    address optionMarket,
    uint amountQuote
  ) internal returns (uint received) {
    if (amountQuote == 0) {
      return 0;
    }
    received = synthetix.exchangeOnBehalfWithTracking(
      sender,
      quoteKey[optionMarket],
      amountQuote,
      baseKey[optionMarket],
      rewardAddress[optionMarket],
      trackingCode[optionMarket]
    );
    if (amountQuote > 1e10) {
      require(received > 0, "ReceivedZeroFromExchange");
    }
    emit QuoteSwappedForBase(optionMarket, sender, amountQuote, received);
  }

  function exchangeFromExactBase(address optionMarket, uint amountBase) external override returns (uint received) {
    if (amountBase == 0) {
      return 0;
    }
    // swap exactly `amountBase` baseAsset for quoteAsset
    received = synthetix.exchangeOnBehalfWithTracking(
      msg.sender,
      baseKey[optionMarket],
      amountBase,
      quoteKey[optionMarket],
      rewardAddress[optionMarket],
      trackingCode[optionMarket]
    );
    if (amountBase > 1e10) {
      require(received > 0, "ReceivedZeroFromExchange");
    }
    emit BaseSwappedForQuote(optionMarket, msg.sender, amountBase, received);
  }

  function estimateExchangeForExactBase(
    ExchangeParams memory exchangeParams,
    uint amountBase
  ) public pure returns (uint quoteNeeded) {
    return
      amountBase.divideDecimalRound(DecimalMath.UNIT - exchangeParams.quoteBaseFeeRate).multiplyDecimalRound(
        exchangeParams.spotPrice
      );
  }

  function estimateExchangeForExactQuote(
    ExchangeParams memory exchangeParams,
    uint amountQuote
  ) public pure returns (uint baseNeeded) {
    return
      amountQuote.divideDecimalRound(DecimalMath.UNIT - exchangeParams.baseQuoteFeeRate).divideDecimalRound(
        exchangeParams.spotPrice
      );
  }

  ////////////
  // Events //
  ////////////

  /**
   * @dev Emitted when the address resolver is set.
   */
  event AddressResolverSet(IAddressResolver addressResolver);
  /**
   * @dev Emitted when synthetix contracts are updated.
   */
  event SynthetixAddressesUpdated(
    ISynthetix synthetix,
    IExchanger exchanger,
    IExchangeRates exchangeRates,
    IDelegateApprovals delegateApprovals
  );
  /**
   * @dev Emitted when GlobalPause.
   */
  event GlobalPaused(bool isPaused);
  /**
   * @dev Emitted when single market paused.
   */
  event MarketPaused(address contractAddress, bool isPaused);
  /**
   * @dev Emitted when trading cut-off is set.
   */
  event TradingCutoffSet(address indexed contractAddress, uint tradingCutoff);
  /**
   * @dev Emitted when quote key is set.
   */
  event QuoteKeySet(address indexed contractAddress, bytes32 quoteKey);
  /**
   * @dev Emitted when base key is set.
   */
  event BaseKeySet(address indexed contractAddress, bytes32 baseKey);
}
