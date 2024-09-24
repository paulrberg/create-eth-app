/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Aave-V3?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

contract MockPeripheryContractV1 {
  address private _manager;
  uint256 private _value;

  function initialize(address manager, uint256 value) external {
    _manager = manager;
    _value = value;
  }

  function getManager() external view returns (address) {
    return _manager;
  }

  function setManager(address newManager) external {
    _manager = newManager;
  }
}

contract MockPeripheryContractV2 {
  address private _manager;
  uint256 private _value;
  address private _addressesProvider;

  function initialize(address addressesProvider) external {
    _addressesProvider = addressesProvider;
  }

  function getManager() external view returns (address) {
    return _manager;
  }

  function setManager(address newManager) external {
    _manager = newManager;
  }

  function getAddressesProvider() external view returns (address) {
    return _addressesProvider;
  }
}
