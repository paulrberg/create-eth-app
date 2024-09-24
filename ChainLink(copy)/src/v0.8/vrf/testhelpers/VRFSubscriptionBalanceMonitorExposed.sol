/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ChainLink?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../dev/VRFSubscriptionBalanceMonitor.sol";

contract VRFSubscriptionBalanceMonitorExposed is VRFSubscriptionBalanceMonitor {
  constructor(
    address linkTokenAddress,
    address coordinatorAddress,
    address keeperRegistryAddress,
    uint256 minWaitPeriodSeconds
  ) VRFSubscriptionBalanceMonitor(linkTokenAddress, coordinatorAddress, keeperRegistryAddress, minWaitPeriodSeconds) {}

  function setLastTopUpXXXTestOnly(uint64 target, uint56 lastTopUpTimestamp) external {
    s_targets[target].lastTopUpTimestamp = lastTopUpTimestamp;
  }
}
