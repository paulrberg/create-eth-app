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

import "../../interfaces/ISynthetix.sol";
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IDelegateApprovals.sol";

// Debug
import "../ITestERC20.sol";
import "../../synthetix/DecimalMath.sol";

import "./../SynthetixAdapter.sol";

contract TestSynthetix is ISynthetix {
  using DecimalMath for uint;

  SynthetixAdapter internal synthetixAdapter;
  IAddressResolver public addressResolver;
  ITestERC20 internal quoteAsset;

  bytes32 private constant CONTRACT_DELEGATE_APPROVALS = "DelegateApprovals";

  mapping(bytes32 => ITestERC20) public baseAssets;
  mapping(bytes32 => address) public markets;

  event Exchange(
    address exchangeForAddress,
    bytes32 sourceCurrencyKey,
    uint sourceAmount,
    bytes32 destinationCurrencyKey
  );

  bool public initialized = false;

  constructor() {}

  function init(
    SynthetixAdapter _synthetixAdapter,
    ITestERC20 _quoteAsset,
    IAddressResolver _addressResolver
  ) external {
    require(!initialized, "Already initialized");
    synthetixAdapter = _synthetixAdapter;
    quoteAsset = _quoteAsset;
    addressResolver = _addressResolver;
    initialized = true;
  }

  function addBaseAsset(bytes32 ticker, ITestERC20 baseAsset, address market) external {
    require(baseAsset != ITestERC20(address(0)), "ERC20 cannot have zero address");
    require(market != address(0), "Market cannot have zero address");
    baseAssets[ticker] = baseAsset;
    markets[ticker] = market;
  }

  function exchange(
    bytes32 sourceCurrencyKey,
    uint sourceAmount,
    bytes32 destinationCurrencyKey
  ) public virtual override returns (uint amountReceived) {
    emit Exchange(msg.sender, sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    return exchangeOnBehalf(msg.sender, sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
  }

  function exchangeOnBehalfWithTracking(
    address exchangeForAddress,
    bytes32 sourceCurrencyKey,
    uint sourceAmount,
    bytes32 destinationCurrencyKey,
    address,
    bytes32
  ) public virtual override returns (uint amountReceived) {
    require(
      IDelegateApprovals(addressResolver.getAddress(CONTRACT_DELEGATE_APPROVALS)).canExchangeOnBehalf(
        msg.sender,
        exchangeForAddress
      ),
      "Not approved to act on behalf"
    );

    emit Exchange(msg.sender, sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    return exchangeOnBehalf(exchangeForAddress, sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
  }

  function exchangeOnBehalf(
    address exchangeForAddress,
    bytes32 sourceCurrencyKey,
    uint sourceAmount,
    bytes32 destinationCurrencyKey
  ) public returns (uint amountReceived) {
    uint fromRate;
    uint feeRate = 0;
    uint toRate;
    require(
      IDelegateApprovals(addressResolver.getAddress(CONTRACT_DELEGATE_APPROVALS)).canExchangeOnBehalf(
        msg.sender,
        exchangeForAddress
      ),
      "Not approved to act on behalf"
    );

    if (sourceCurrencyKey == "sUSD") {
      fromRate = 1e18;
      quoteAsset.burn(exchangeForAddress, sourceAmount);
    } else {
      address market = markets[sourceCurrencyKey];
      require(market != address(0), "invalid source currency key");
      SynthetixAdapter.ExchangeParams memory exchangeParams = synthetixAdapter.getExchangeParams(market);
      ITestERC20 baseAsset = baseAssets[sourceCurrencyKey];
      require(baseAsset != ITestERC20(address(0)), "ERC20 cannot have zero address");
      baseAsset.burn(exchangeForAddress, sourceAmount);
      fromRate = exchangeParams.spotPrice;
      feeRate = exchangeParams.baseQuoteFeeRate;
    }

    if (destinationCurrencyKey == "sUSD") {
      uint amountConverted = sourceAmount.multiplyDecimalRound(fromRate);
      amountReceived = amountConverted.multiplyDecimalRound(1e18 - feeRate);
      quoteAsset.mint(exchangeForAddress, amountReceived);
    } else {
      address market = markets[destinationCurrencyKey];
      require(market != address(0), "invalid destination currency key");
      SynthetixAdapter.ExchangeParams memory exchangeParams = synthetixAdapter.getExchangeParams(market);
      ITestERC20 baseAsset = baseAssets[destinationCurrencyKey];
      toRate = exchangeParams.spotPrice;
      if (feeRate == 0) {
        feeRate = exchangeParams.quoteBaseFeeRate;
      }

      uint amountConverted = sourceAmount.multiplyDecimalRound(fromRate).divideDecimalRound(toRate);
      amountReceived = amountConverted.multiplyDecimalRound(1e18 - feeRate);

      baseAsset.mint(exchangeForAddress, amountReceived);
    }
  }
}
