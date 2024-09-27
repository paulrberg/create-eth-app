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
pragma solidity ^0.8.24;

import {IBinPoolManager} from "../../../src/pool-bin/interfaces/IBinPoolManager.sol";
import {IBinHooks} from "../../../src/pool-bin/interfaces/IBinHooks.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {IBinDynamicFeeManager} from "../../../src/pool-bin/interfaces/IBinDynamicFeeManager.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BaseBinTestHook} from "./BaseBinTestHook.sol";

contract BinFeeManagerHook is BaseBinTestHook, IBinDynamicFeeManager {
    using PoolIdLibrary for PoolKey;

    uint16 bitmap;
    uint24 internal fee = 3000; // default 0.3%
    IBinPoolManager public immutable binManager;

    constructor(IBinPoolManager _binManager) {
        binManager = _binManager;
    }

    function setHooksRegistrationBitmap(uint16 _bitmap) external {
        bitmap = _bitmap;
    }

    function getHooksRegistrationBitmap() external view override returns (uint16) {
        return bitmap;
    }

    function setFee(uint24 _fee) external {
        fee = _fee;
    }

    function getFee(address, PoolKey calldata) external view returns (uint24) {
        return fee;
    }

    function getFeeForSwapInSwapOut(address, PoolKey calldata, bool, uint128, uint128) external view returns (uint24) {
        return fee;
    }

    /// @dev handle mint composition fee related test
    function beforeMint(address, PoolKey calldata key, IBinPoolManager.MintParams calldata, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        if (hookData.length > 0) {
            (bool _update, uint24 _fee) = abi.decode(hookData, (bool, uint24));
            if (_update) {
                fee = _fee;
                binManager.updateDynamicSwapFee(key);
            }
        }

        return IBinHooks.beforeMint.selector;
    }

    function beforeSwap(address, PoolKey calldata key, bool, uint128, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        if (hookData.length > 0) {
            (bool _update, uint24 _fee) = abi.decode(hookData, (bool, uint24));
            if (_update) {
                fee = _fee;
                binManager.updateDynamicSwapFee(key);
            }
        }

        return IBinHooks.beforeSwap.selector;
    }
}
