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

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {Hooks} from "../src/libraries/Hooks.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IProtocolFees} from "../src/interfaces/IProtocolFees.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolManager} from "../src/PoolManager.sol";
import {PoolSwapTest} from "../src/test/PoolSwapTest.sol";
import {Deployers} from "./utils/Deployers.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Currency, CurrencyLibrary} from "../src/types/Currency.sol";
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {Constants} from "../test/utils/Constants.sol";
import {SkipCallsTestHook} from "../src/test/SkipCallsTestHook.sol";

contract SkipCallsTest is Test, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;

    PoolSwapTest.TestSettings testSettings = PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

    function deploy(SkipCallsTestHook skipCallsTestHook) private {
        SkipCallsTestHook impl = new SkipCallsTestHook();
        vm.etch(address(skipCallsTestHook), address(impl).code);
        deployFreshManagerAndRouters();
        skipCallsTestHook.setManager(IPoolManager(manager));
        (currency0, currency1) = deployMintAndApprove2Currencies();

        assertEq(skipCallsTestHook.counter(), 0);

        (key,) = initPool(currency0, currency1, IHooks(address(skipCallsTestHook)), 3000, SQRT_PRICE_1_1, ZERO_BYTES);
    }

    function approveAndAddLiquidity(SkipCallsTestHook skipCallsTestHook) private {
        MockERC20(Currency.unwrap(key.currency0)).approve(address(skipCallsTestHook), Constants.MAX_UINT256);
        MockERC20(Currency.unwrap(key.currency1)).approve(address(skipCallsTestHook), Constants.MAX_UINT256);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, abi.encode(address(this)));
    }

    function test_beforeInitialize_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.BEFORE_INITIALIZE_FLAG))
        );

        // initializes pool and increments counter
        deploy(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 1);
    }

    function test_afterInitialize_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.AFTER_INITIALIZE_FLAG))
        );

        // initializes pool and increments counter
        deploy(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 1);
    }

    function test_beforeAddLiquidity_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.BEFORE_ADD_LIQUIDITY_FLAG))
        );

        deploy(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // adds liquidity and increments counter
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 1);
        // adds liquidity again and increments counter
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_afterAddLiquidity_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.AFTER_ADD_LIQUIDITY_FLAG))
        );

        deploy(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // adds liquidity and increments counter
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 1);
        // adds liquidity and increments counter again
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_beforeRemoveLiquidity_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG))
        );

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // removes liquidity and increments counter
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 1);
        // adds liquidity again
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, abi.encode(address(this)));
        // removes liquidity again and increments counter
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_afterRemoveLiquidity_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG))
        );

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // removes liquidity and increments counter
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 1);
        // adds liquidity again
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, abi.encode(address(this)));
        // removes liquidity again and increments counter
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_beforeSwap_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.BEFORE_SWAP_FLAG))
        );

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // swaps and increments counter
        swapRouter.swap(key, SWAP_PARAMS, testSettings, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 1);
        // swaps again and increments counter
        swapRouter.swap(key, SWAP_PARAMS, testSettings, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_gas_beforeSwap_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.BEFORE_SWAP_FLAG))
        );

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // swaps and increments counter
        swapRouter.swap(key, SWAP_PARAMS, testSettings, abi.encode(address(this)));
        snapLastCall("swap skips hook call if hook is caller");
        assertEq(skipCallsTestHook.counter(), 1);
    }

    function test_afterSwap_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook =
            SkipCallsTestHook(address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.AFTER_SWAP_FLAG)));

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // swaps and increments counter
        swapRouter.swap(key, SWAP_PARAMS, testSettings, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 1);
        // swaps again and increments counter
        swapRouter.swap(key, SWAP_PARAMS, testSettings, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_beforeDonate_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.BEFORE_DONATE_FLAG))
        );

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // donates and increments counter
        donateRouter.donate(key, 100, 200, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 1);
        // donates again and increments counter
        donateRouter.donate(key, 100, 200, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }

    function test_afterDonate_skipIfCalledByHook() public {
        SkipCallsTestHook skipCallsTestHook = SkipCallsTestHook(
            address(uint160(type(uint160).max & clearAllHookPermissionsMask | Hooks.AFTER_DONATE_FLAG))
        );

        deploy(skipCallsTestHook);
        approveAndAddLiquidity(skipCallsTestHook);
        assertEq(skipCallsTestHook.counter(), 0);

        // donates and increments counter
        donateRouter.donate(key, 100, 200, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 1);
        // donates again and increments counter
        donateRouter.donate(key, 100, 200, abi.encode(address(this)));
        assertEq(skipCallsTestHook.counter(), 2);
    }
}
