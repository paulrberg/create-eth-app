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

import {Hooks} from "../libraries/Hooks.sol";
import {BaseTestHooks} from "./BaseTestHooks.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {IERC20Minimal} from "../interfaces/external/IERC20Minimal.sol";
import {CurrencyLibrary, Currency} from "../types/Currency.sol";
import {PoolTestBase} from "./PoolTestBase.sol";
import {Constants} from "../../test/utils/Constants.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {CurrencySettleTake} from "../libraries/CurrencySettleTake.sol";
import {StateLibrary} from "../libraries/StateLibrary.sol";
import {TransientStateLibrary} from "../libraries/TransientStateLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "../types/BeforeSwapDelta.sol";

contract SkipCallsTestHook is BaseTestHooks, Test {
    using CurrencySettleTake for Currency;
    using PoolIdLibrary for PoolKey;
    using Hooks for IHooks;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    uint256 public counter;
    IPoolManager manager;

    function setManager(IPoolManager _manager) external {
        manager = _manager;
    }

    function beforeInitialize(address, PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        counter++;
        _initialize(key, sqrtPriceX96, hookData);
        return IHooks.beforeInitialize.selector;
    }

    function afterInitialize(address, PoolKey calldata key, uint160 sqrtPriceX96, int24, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        counter++;
        _initialize(key, sqrtPriceX96, hookData);
        return IHooks.afterInitialize.selector;
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        counter++;
        _addLiquidity(key, params, hookData);
        return IHooks.beforeAddLiquidity.selector;
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4, BalanceDelta) {
        counter++;
        _addLiquidity(key, params, hookData);
        return (IHooks.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        counter++;
        _removeLiquidity(key, params, hookData);
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4, BalanceDelta) {
        counter++;
        _removeLiquidity(key, params, hookData);
        return (IHooks.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata hookData)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        counter++;
        _swap(key, params, hookData);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4, int128) {
        counter++;
        _swap(key, params, hookData);
        return (IHooks.afterSwap.selector, 0);
    }

    function beforeDonate(address, PoolKey calldata key, uint256 amt0, uint256 amt1, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        counter++;
        _donate(key, amt0, amt1, hookData);
        return IHooks.beforeDonate.selector;
    }

    function afterDonate(address, PoolKey calldata key, uint256 amt0, uint256 amt1, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        counter++;
        _donate(key, amt0, amt1, hookData);
        return IHooks.afterDonate.selector;
    }

    function _initialize(PoolKey memory key, uint160 sqrtPriceX96, bytes calldata hookData) public {
        // initialize a new pool with different fee
        key.fee = 2000;
        IPoolManager(manager).initialize(key, sqrtPriceX96, hookData);
    }

    function _swap(PoolKey calldata key, IPoolManager.SwapParams memory params, bytes calldata hookData) public {
        IPoolManager(manager).swap(key, params, hookData);
        address payer = abi.decode(hookData, (address));
        int256 delta0 = IPoolManager(manager).currencyDelta(address(this), key.currency0);
        assertEq(delta0, params.amountSpecified);
        int256 delta1 = IPoolManager(manager).currencyDelta(address(this), key.currency1);
        assert(delta1 > 0);
        key.currency0.settle(manager, payer, uint256(-delta0), false);
        key.currency1.take(manager, payer, uint256(delta1), false);
    }

    function _addLiquidity(
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) public {
        IPoolManager(manager).modifyLiquidity(key, params, hookData);
        address payer = abi.decode(hookData, (address));
        int256 delta0 = IPoolManager(manager).currencyDelta(address(this), key.currency0);
        int256 delta1 = IPoolManager(manager).currencyDelta(address(this), key.currency1);

        assert(delta0 < 0 || delta1 < 0);
        assert(!(delta0 > 0 || delta1 > 0));

        key.currency0.settle(manager, payer, uint256(-delta0), false);
        key.currency1.settle(manager, payer, uint256(-delta1), false);
    }

    function _removeLiquidity(
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) public {
        // first hook needs to add liquidity for itself
        IPoolManager.ModifyLiquidityParams memory newParams =
            IPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1e18, salt: 0});
        IPoolManager(manager).modifyLiquidity(key, newParams, hookData);
        // hook removes liquidity
        IPoolManager(manager).modifyLiquidity(key, params, hookData);
        address payer = abi.decode(hookData, (address));
        int256 delta0 = IPoolManager(manager).currencyDelta(address(this), key.currency0);
        int256 delta1 = IPoolManager(manager).currencyDelta(address(this), key.currency1);

        assert(delta0 < 0 || delta1 < 0);
        assert(!(delta0 > 0 || delta1 > 0));

        key.currency0.settle(manager, payer, uint256(-delta0), false);
        key.currency1.settle(manager, payer, uint256(-delta1), false);
    }

    function _donate(PoolKey calldata key, uint256 amt0, uint256 amt1, bytes calldata hookData) public {
        IPoolManager(manager).donate(key, amt0, amt1, hookData);
        address payer = abi.decode(hookData, (address));
        int256 delta0 = IPoolManager(manager).currencyDelta(address(this), key.currency0);
        int256 delta1 = IPoolManager(manager).currencyDelta(address(this), key.currency1);
        key.currency0.settle(manager, payer, uint256(-delta0), false);
        key.currency1.settle(manager, payer, uint256(-delta1), false);
    }
}
