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
  
  pragma solidity ^0.8.0;

import "../../interfaces/perpsV2/ISystemStatus.sol";

contract MockSystemStatus is ISystemStatus {
  bool private _futuresMarketSuspended;
  uint248 private _futuresMarketReason;

  // Setters for `futuresMarketSuspension` function
  function setFuturesMarketSuspended(bool suspended) external {
    _futuresMarketSuspended = suspended;
  }

  function setFuturesMarketReason(uint248 reason) external {
    _futuresMarketReason = reason;
  }

  function accessControl(bytes32 /*section*/, address /*account*/) external view override returns (bool, bool) {}

  function requireSystemActive() external view override {}

  function systemSuspended() external view override returns (bool) {}

  function requireIssuanceActive() external view override {}

  function requireExchangeActive() external view override {}

  function requireFuturesActive() external view override {}

  function requireFuturesMarketActive(bytes32 /*marketKey*/) external view override {}

  function requireExchangeBetweenSynthsAllowed(
    bytes32 /*sourceCurrencyKey*/,
    bytes32 /*destinationCurrencyKey*/
  ) external view override {}

  function requireSynthActive(bytes32 /*currencyKey*/) external view override {}

  function synthSuspended(bytes32 /*currencyKey*/) external view override returns (bool) {}

  function requireSynthsActive(
    bytes32 /*sourceCurrencyKey*/,
    bytes32 /*destinationCurrencyKey*/
  ) external view override {}

  function systemSuspension() external view override returns (bool, uint248) {}

  function issuanceSuspension() external view override returns (bool, uint248) {}

  function exchangeSuspension() external view override returns (bool, uint248) {}

  function futuresSuspension() external view override returns (bool, uint248) {}

  function synthExchangeSuspension(bytes32 /*currencyKey*/) external view override returns (bool, uint248) {}

  function synthSuspension(bytes32 /*currencyKey*/) external view override returns (bool, uint248) {}

  function futuresMarketSuspension(
    bytes32 /*marketKey*/
  ) external view override returns (bool suspended, uint248 reason) {
    return (_futuresMarketSuspended, _futuresMarketReason);
  }

  function getSynthExchangeSuspensions(
    bytes32[] calldata /*synths*/
  ) external view override returns (bool[] memory, uint256[] memory) {}

  function getSynthSuspensions(
    bytes32[] calldata /*synths*/
  ) external view override returns (bool[] memory, uint256[] memory) {}

  function getFuturesMarketSuspensions(
    bytes32[] calldata /*marketKeys*/
  ) external view override returns (bool[] memory, uint256[] memory) {}

  function suspendIssuance(uint256 /*reason*/) external override {}

  function suspendSynth(bytes32 /*currencyKey*/, uint256 /*reason*/) external override {}

  function suspendFuturesMarket(bytes32 /*marketKey*/, uint256 /*reason*/) external override {}

  function updateAccessControl(
    bytes32 /*section*/,
    address /*account*/,
    bool /*canSuspend*/,
    bool /*canResume*/
  ) external override {}
}
