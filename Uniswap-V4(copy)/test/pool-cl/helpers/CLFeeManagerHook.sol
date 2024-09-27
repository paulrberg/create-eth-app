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

import {ICLPoolManager} from "../../../src/pool-cl/interfaces/ICLPoolManager.sol";
import {ICLHooks} from "../../../src/pool-cl/interfaces/ICLHooks.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {ICLDynamicFeeManager} from "../../../src/pool-cl/interfaces/ICLDynamicFeeManager.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BaseCLTestHook} from "./BaseCLTestHook.sol";

contract CLFeeManagerHook is BaseCLTestHook, ICLDynamicFeeManager {
    using PoolIdLibrary for PoolKey;

    uint16 bitmap;
    uint24 internal fee = 3000; // default 0.3%
    ICLPoolManager public immutable clManager;

    constructor(ICLPoolManager _clManager) {
        clManager = _clManager;
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

    function beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        if (hookData.length > 0) {
            (bool _update, uint24 _fee) = abi.decode(hookData, (bool, uint24));
            if (_update) {
                fee = _fee;
                clManager.updateDynamicSwapFee(key);
            }
        }

        return ICLHooks.beforeSwap.selector;
    }
}
