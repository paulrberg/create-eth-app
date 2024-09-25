/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Umbra-Cash?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IUmbraHookReceiver.sol";

/// @dev Mock implementation of UmbraHookable used for testing
contract MockHook is IUmbraHookReceiver {
  struct CallHookData {
    uint256 amount;
    address stealthAddr;
    address acceptor;
    address tokenAddr;
    address sponsor;
    uint256 sponsorFee;
    bytes data;
  }

  CallHookData public lastCallData;

  function tokensWithdrawn(
    uint256 _amount,
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    bytes memory _data
  ) external override {
    lastCallData = CallHookData({
      amount: _amount,
      stealthAddr: _stealthAddr,
      acceptor: _acceptor,
      tokenAddr: _tokenAddr,
      sponsor: _sponsor,
      sponsorFee: _sponsorFee,
      data: _data
    });
  }
}
