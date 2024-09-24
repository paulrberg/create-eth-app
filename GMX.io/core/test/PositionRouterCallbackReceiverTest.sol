/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/GMX.io?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../interfaces/IPositionRouterCallbackReceiver.sol";

contract PositionRouterCallbackReceiverTest is IPositionRouterCallbackReceiver {
    event CallbackCalled(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    );

    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) override external {
        emit CallbackCalled(positionKey, isExecuted, isIncrease);
    }
}
