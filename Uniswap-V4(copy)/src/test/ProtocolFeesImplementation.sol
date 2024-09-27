/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ProtocolFees} from "../ProtocolFees.sol";
import {IProtocolFeeController} from "../interfaces/IProtocolFeeController.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {Currency} from "../types/Currency.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {Pool} from "../libraries/Pool.sol";
import {Slot0} from "../types/Slot0.sol";

contract ProtocolFeesImplementation is ProtocolFees {
    using PoolIdLibrary for PoolKey;

    mapping(PoolId id => Pool.State) internal _pools;

    constructor(uint256 _controllerGasLimit) ProtocolFees(_controllerGasLimit) {}

    // Used to set the price of a pool to pretend that the pool has been initialized in order to successfully set a protocol fee
    function setPrice(PoolKey memory key, uint160 sqrtPriceX96) public {
        Pool.State storage pool = _getPool(key.toId());
        pool.slot0 = pool.slot0.setSqrtPriceX96(sqrtPriceX96);
    }

    function _getPool(PoolId id) internal view override returns (Pool.State storage) {
        return _pools[id];
    }

    function fetchProtocolFee(PoolKey memory key) public returns (bool, uint24) {
        return ProtocolFees._fetchProtocolFee(key);
    }

    function updateProtocolFees(Currency currency, uint256 amount) public {
        ProtocolFees._updateProtocolFees(currency, amount);
    }
}
