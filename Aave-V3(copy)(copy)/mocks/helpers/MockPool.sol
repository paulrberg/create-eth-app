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

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';

contract MockPool {
  // Reserved storage space to avoid layout collisions.
  uint256[100] private ______gap;

  address internal _addressesProvider;
  address[] internal _reserveList;

  function initialize(address provider) external {
    _addressesProvider = provider;
  }

  function addReserveToReservesList(address reserve) external {
    _reserveList.push(reserve);
  }

  function getReservesList() external view returns (address[] memory) {
    address[] memory reservesList = new address[](_reserveList.length);
    for (uint256 i; i < _reserveList.length; i++) {
      reservesList[i] = _reserveList[i];
    }
    return reservesList;
  }
}

import {Pool} from '../../protocol/pool/Pool.sol';

contract MockPoolInherited is Pool {
  uint16 internal _maxNumberOfReserves = 128;

  function getRevision() internal pure override returns (uint256) {
    return 0x3;
  }

  constructor(IPoolAddressesProvider provider) Pool(provider) {}

  function setMaxNumberOfReserves(uint16 newMaxNumberOfReserves) public {
    _maxNumberOfReserves = newMaxNumberOfReserves;
  }

  function MAX_NUMBER_RESERVES() public view override returns (uint16) {
    return _maxNumberOfReserves;
  }

  function dropReserve(address asset) external override {
    _reservesList[_reserves[asset].id] = address(0);
    delete _reserves[asset];
  }
}
