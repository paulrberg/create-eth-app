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
  
  //SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
  struct Status {
    bool canSuspend;
    bool canResume;
  }

  struct Suspension {
    bool suspended;
    // reason is an integer code,
    // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
    uint248 reason;
  }

  // Views
  function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

  function requireSystemActive() external view;

  function systemSuspended() external view returns (bool);

  function requireIssuanceActive() external view;

  function requireExchangeActive() external view;

  function requireFuturesActive() external view;

  function requireFuturesMarketActive(bytes32 marketKey) external view;

  function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

  function requireSynthActive(bytes32 currencyKey) external view;

  function synthSuspended(bytes32 currencyKey) external view returns (bool);

  function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

  function systemSuspension() external view returns (bool suspended, uint248 reason);

  function issuanceSuspension() external view returns (bool suspended, uint248 reason);

  function exchangeSuspension() external view returns (bool suspended, uint248 reason);

  function futuresSuspension() external view returns (bool suspended, uint248 reason);

  function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

  function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

  function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

  function getSynthExchangeSuspensions(
    bytes32[] calldata synths
  ) external view returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

  function getSynthSuspensions(
    bytes32[] calldata synths
  ) external view returns (bool[] memory suspensions, uint256[] memory reasons);

  function getFuturesMarketSuspensions(
    bytes32[] calldata marketKeys
  ) external view returns (bool[] memory suspensions, uint256[] memory reasons);

  // Restricted functions
  function suspendIssuance(uint256 reason) external;

  function suspendSynth(bytes32 currencyKey, uint256 reason) external;

  function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

  function updateAccessControl(bytes32 section, address account, bool canSuspend, bool canResume) external;
}
