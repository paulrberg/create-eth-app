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

import {Hooks} from "../../../src/libraries/Hooks.sol";
import {ICLHooks} from "../../../src/pool-cl/interfaces/ICLHooks.sol";
import {ICLPoolManager} from "../../../src/pool-cl/interfaces/ICLPoolManager.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BalanceDelta} from "../../../src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";

contract MockHooks is ICLHooks {
    using PoolIdLibrary for PoolKey;
    using Hooks for ICLHooks;

    bytes public beforeInitializeData;
    bytes public afterInitializeData;
    bytes public beforeAddLiquidityData;
    bytes public afterAddLiquidityData;
    bytes public beforeRemoveLiquidityData;
    bytes public afterRemoveLiquidityData;
    bytes public beforeSwapData;
    bytes public afterSwapData;
    bytes public beforeDonateData;
    bytes public afterDonateData;

    mapping(bytes4 => bytes4) public returnValues;

    mapping(PoolId => uint16) public swapFees;

    function getHooksRegistrationBitmap() external pure returns (uint16) {
        return 0xffff;
    }

    function beforeInitialize(address, PoolKey calldata, uint160, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        beforeInitializeData = hookData;
        bytes4 selector = MockHooks.beforeInitialize.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        afterInitializeData = hookData;
        bytes4 selector = MockHooks.afterInitialize.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) external override returns (bytes4) {
        beforeAddLiquidityData = hookData;
        bytes4 selector = MockHooks.beforeAddLiquidity.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        afterAddLiquidityData = hookData;
        bytes4 selector = MockHooks.afterAddLiquidity.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) external override returns (bytes4) {
        beforeRemoveLiquidityData = hookData;
        bytes4 selector = MockHooks.beforeRemoveLiquidity.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        afterRemoveLiquidityData = hookData;
        bytes4 selector = MockHooks.afterRemoveLiquidity.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function beforeSwap(address, PoolKey calldata, ICLPoolManager.SwapParams calldata, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        beforeSwapData = hookData;
        bytes4 selector = MockHooks.beforeSwap.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function afterSwap(
        address,
        PoolKey calldata,
        ICLPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4) {
        afterSwapData = hookData;
        bytes4 selector = MockHooks.afterSwap.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        beforeDonateData = hookData;
        bytes4 selector = MockHooks.beforeDonate.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        afterDonateData = hookData;
        bytes4 selector = MockHooks.afterDonate.selector;
        return returnValues[selector] == bytes4(0) ? selector : returnValues[selector];
    }

    function setReturnValue(bytes4 key, bytes4 value) external {
        returnValues[key] = value;
    }

    function setSwapFee(PoolKey calldata key, uint16 value) external {
        swapFees[key.toId()] = value;
    }
}
