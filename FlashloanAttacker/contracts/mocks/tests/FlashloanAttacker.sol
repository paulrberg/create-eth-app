/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/FlashloanAttacker?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {FlashLoanSimpleReceiverBase} from '../../flashloan/base/FlashLoanSimpleReceiverBase.sol';
import {MintableERC20} from '../tokens/MintableERC20.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

contract FlashloanAttacker is FlashLoanSimpleReceiverBase {
  using GPv2SafeERC20 for IERC20;
  using SafeMath for uint256;

  IPoolAddressesProvider internal _provider;
  IPool internal _pool;

  constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {
    _pool = IPool(provider.getPool());
  }

  function supplyAsset(address asset, uint256 amount) public {
    MintableERC20 token = MintableERC20(asset);
    token.mint(amount);
    token.approve(address(_pool), type(uint256).max);
    _pool.supply(asset, amount, address(this), 0);
  }

  function _innerBorrow(address asset) internal {
    DataTypes.ReserveData memory config = _pool.getReserveData(asset);
    IERC20 token = IERC20(asset);
    uint256 avail = token.balanceOf(config.aTokenAddress);
    _pool.borrow(asset, avail, 2, 0, address(this));
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    MintableERC20 token = MintableERC20(asset);
    uint256 amountToReturn = amount.add(premium);

    // Also do a normal borrow here in the middle
    _innerBorrow(asset);

    token.mint(premium);
    IERC20(asset).approve(address(POOL), amountToReturn);

    return true;
  }
}
