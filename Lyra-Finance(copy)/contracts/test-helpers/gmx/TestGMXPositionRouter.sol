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

import "../../synthetix/DecimalMath.sol";
import "../../interfaces/gmx/IVault.sol";
import "../../synthetix/Owned.sol";
import "../TestERC20.sol";

contract TestGMXPositionRouter is Owned {
  using DecimalMath for uint;

  uint public callbackGasLimit = 800000;
  address public vault;

  constructor(address _vaultAddr) {
    vault = _vaultAddr;
  }

  function getPositions(
    address, // _vault
    address, // _account
    address[] memory, // _collateralTokens
    address[] memory, // _indexTokens
    bool[] memory // _isLong
  ) external pure returns (uint[] memory) {
    uint[] memory vals = new uint[](8);
    return vals;
  }

  function maxGlobalLongSizes(address) external pure returns (uint) {
    return 0;
  }

  function maxGlobalShortSizes(address) external pure returns (uint) {
    return 0;
  }
}
