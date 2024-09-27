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
import {IHooks} from "../src/interfaces/IHooks.sol";
import {Hooks} from "../src/libraries/Hooks.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IProtocolFees} from "../src/interfaces/IProtocolFees.sol";
import {IProtocolFeeController} from "../src/interfaces/IProtocolFeeController.sol";
import {PoolManager} from "../src/PoolManager.sol";
import {FeeTakingHook} from "../src/test/FeeTakingHook.sol";
import {CustomCurveHook} from "../src/test/CustomCurveHook.sol";
import {DeltaReturningHook} from "../src/test/DeltaReturningHook.sol";
import {TickMath} from "../src/libraries/TickMath.sol";
import {Pool} from "../src/libraries/Pool.sol";
import {Deployers} from "./utils/Deployers.sol";
import {Currency, CurrencyLibrary} from "../src/types/Currency.sol";
import {MockHooks} from "../src/test/MockHooks.sol";
import {MockContract} from "../src/test/MockContract.sol";
import {EmptyTestHooks} from "../src/test/EmptyTestHooks.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {PoolModifyLiquidityTest} from "../src/test/PoolModifyLiquidityTest.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../src/types/BalanceDelta.sol";
import {PoolSwapTest} from "../src/test/PoolSwapTest.sol";
import {PoolSettleTest} from "../src/test/PoolSettleTest.sol";
import {TestInvalidERC20} from "../src/test/TestInvalidERC20.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {PoolEmptyUnlockTest} from "../src/test/PoolEmptyUnlockTest.sol";
import {Action} from "../src/test/PoolNestedActionsTest.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {LPFeeLibrary} from "../src/libraries/LPFeeLibrary.sol";
import {Position} from "../src/libraries/Position.sol";
import {Constants} from "./utils/Constants.sol";
import {SafeCast} from "../src/libraries/SafeCast.sol";
import {AmountHelpers} from "./utils/AmountHelpers.sol";
import {ProtocolFeeLibrary} from "../src/libraries/ProtocolFeeLibrary.sol";
import {IProtocolFees} from "../src/interfaces/IProtocolFees.sol";
import {StateLibrary} from "../src/libraries/StateLibrary.sol";

contract PoolManagerTest is Test, Deployers, GasSnapshot {
    using Hooks for IHooks;
    using PoolIdLibrary for PoolKey;
    using LPFeeLibrary for uint24;
    using CurrencyLibrary for Currency;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using ProtocolFeeLibrary for uint24;
    using StateLibrary for IPoolManager;

    event UnlockCallback();
    event ProtocolFeeControllerUpdated(address feeController);
    event ModifyLiquidity(
        PoolId indexed poolId, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta
    );
    event Swap(
        PoolId indexed poolId,
        address sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    event Transfer(
        address caller, address indexed sender, address indexed receiver, uint256 indexed id, uint256 amount
    );

    PoolEmptyUnlockTest emptyUnlockRouter;

    uint24 constant MAX_PROTOCOL_FEE_BOTH_TOKENS = (1000 << 12) | 1000; // 1000 1000

    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));

        emptyUnlockRouter = new PoolEmptyUnlockTest(manager);
    }

    function test_bytecodeSize() public {
        snapSize("poolManager bytecode size", address(manager));
    }

    function test_addLiquidity_failsIfNotInitialized() public {
        vm.expectRevert(Pool.PoolNotInitialized.selector);
        modifyLiquidityRouter.modifyLiquidity(uninitializedKey, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.modifyLiquidity(uninitializedKey, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_failsIfNotInitialized() public {
        vm.expectRevert(Pool.PoolNotInitialized.selector);
        modifyLiquidityRouter.modifyLiquidity(uninitializedKey, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_succeedsIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(
            key.toId(),
            address(modifyLiquidityRouter),
            LIQUIDITY_PARAMS.tickLower,
            LIQUIDITY_PARAMS.tickUpper,
            LIQUIDITY_PARAMS.liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_succeedsIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(
            key.toId(),
            address(modifyLiquidityRouter),
            REMOVE_LIQUIDITY_PARAMS.tickLower,
            REMOVE_LIQUIDITY_PARAMS.tickUpper,
            REMOVE_LIQUIDITY_PARAMS.liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_withFeeTakingHook() public {
        address hookAddr =
            address(uint160(Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG));
        FeeTakingHook impl = new FeeTakingHook(manager);
        vm.etch(hookAddr, address(impl).code);

        (key,) = initPool(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);

        uint256 balanceBefore0 = currency0.balanceOf(address(this));
        uint256 balanceBefore1 = currency1.balanceOf(address(this));
        uint256 hookBalanceBefore0 = currency0.balanceOf(hookAddr);
        uint256 hookBalanceBefore1 = currency1.balanceOf(hookAddr);
        uint256 managerBalanceBefore0 = currency0.balanceOf(address(manager));
        uint256 managerBalanceBefore1 = currency1.balanceOf(address(manager));

        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
        snapLastCall("addLiquidity CA fee");

        uint256 hookGain0 = currency0.balanceOf(hookAddr) - hookBalanceBefore0;
        uint256 hookGain1 = currency1.balanceOf(hookAddr) - hookBalanceBefore1;
        uint256 thisLoss0 = balanceBefore0 - currency0.balanceOf(address(this));
        uint256 thisLoss1 = balanceBefore1 - currency1.balanceOf(address(this));
        uint256 managerGain0 = currency0.balanceOf(address(manager)) - managerBalanceBefore0;
        uint256 managerGain1 = currency1.balanceOf(address(manager)) - managerBalanceBefore1;

        // Assert that the hook got 5.43% of the added liquidity
        assertEq(hookGain0, managerGain0 * 543 / 10000, "hook amount 0");
        assertEq(hookGain1, managerGain1 * 543 / 10000, "hook amount 1");
        assertEq(thisLoss0 - hookGain0, managerGain0, "manager amount 0");
        assertEq(thisLoss1 - hookGain1, managerGain1, "manager amount 1");
    }

    function test_removeLiquidity_withFeeTakingHook() public {
        address hookAddr =
            address(uint160(Hooks.AFTER_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG));
        FeeTakingHook impl = new FeeTakingHook(manager);
        vm.etch(hookAddr, address(impl).code);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);

        uint256 balanceBefore0 = currency0.balanceOf(address(this));
        uint256 balanceBefore1 = currency1.balanceOf(address(this));
        uint256 hookBalanceBefore0 = currency0.balanceOf(hookAddr);
        uint256 hookBalanceBefore1 = currency1.balanceOf(hookAddr);
        uint256 managerBalanceBefore0 = currency0.balanceOf(address(manager));
        uint256 managerBalanceBefore1 = currency1.balanceOf(address(manager));

        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
        snapLastCall("removeLiquidity CA fee");

        uint256 hookGain0 = currency0.balanceOf(hookAddr) - hookBalanceBefore0;
        uint256 hookGain1 = currency1.balanceOf(hookAddr) - hookBalanceBefore1;
        uint256 thisGain0 = currency0.balanceOf(address(this)) - balanceBefore0;
        uint256 thisGain1 = currency1.balanceOf(address(this)) - balanceBefore1;
        uint256 managerLoss0 = managerBalanceBefore0 - currency0.balanceOf(address(manager));
        uint256 managerLoss1 = managerBalanceBefore1 - currency1.balanceOf(address(manager));

        // Assert that the hook got 5.43% of the withdrawn liquidity
        assertEq(hookGain0, managerLoss0 * 543 / 10000, "hook amount 0");
        assertEq(hookGain1, managerLoss1 * 543 / 10000, "hook amount 1");
        assertEq(thisGain0 + hookGain0, managerLoss0, "manager amount 0");
        assertEq(thisGain1 + hookGain1, managerLoss1, "manager amount 1");
    }

    function test_addLiquidity_succeedsForNativeTokensIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(
            nativeKey.toId(),
            address(modifyLiquidityRouter),
            LIQUIDITY_PARAMS.tickLower,
            LIQUIDITY_PARAMS.tickUpper,
            LIQUIDITY_PARAMS.liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity{value: 1 ether}(nativeKey, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_succeedsForNativeTokensIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(
            nativeKey.toId(),
            address(modifyLiquidityRouter),
            REMOVE_LIQUIDITY_PARAMS.tickLower,
            REMOVE_LIQUIDITY_PARAMS.tickUpper,
            REMOVE_LIQUIDITY_PARAMS.liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity{value: 1 ether}(nativeKey, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_succeedsWithHooksIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        address payable mockAddr =
            payable(address(uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG)));
        address payable hookAddr = payable(Constants.ALL_HOOKS);

        vm.etch(hookAddr, vm.getDeployedCode("EmptyTestHooks.sol:EmptyTestHooks"));
        MockContract mockContract = new MockContract();
        vm.etch(mockAddr, address(mockContract).code);

        MockContract(mockAddr).setImplementation(hookAddr);

        (key,) = initPool(currency0, currency1, IHooks(mockAddr), 3000, sqrtPriceX96, ZERO_BYTES);

        BalanceDelta balanceDelta = modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);

        bytes32 beforeSelector = MockHooks.beforeAddLiquidity.selector;
        bytes memory beforeParams = abi.encode(address(modifyLiquidityRouter), key, LIQUIDITY_PARAMS, ZERO_BYTES);
        bytes32 afterSelector = MockHooks.afterAddLiquidity.selector;
        bytes memory afterParams =
            abi.encode(address(modifyLiquidityRouter), key, LIQUIDITY_PARAMS, balanceDelta, ZERO_BYTES);

        assertEq(MockContract(mockAddr).timesCalledSelector(beforeSelector), 1);
        assertTrue(MockContract(mockAddr).calledWithSelector(beforeSelector, beforeParams));
        assertEq(MockContract(mockAddr).timesCalledSelector(afterSelector), 1);
        assertTrue(MockContract(mockAddr).calledWithSelector(afterSelector, afterParams));
    }

    function test_removeLiquidity_succeedsWithHooksIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        address payable mockAddr =
            payable(address(uint160(Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG)));
        address payable hookAddr = payable(Constants.ALL_HOOKS);

        vm.etch(hookAddr, vm.getDeployedCode("EmptyTestHooks.sol:EmptyTestHooks"));
        MockContract mockContract = new MockContract();
        vm.etch(mockAddr, address(mockContract).code);

        MockContract(mockAddr).setImplementation(hookAddr);

        (key,) = initPool(currency0, currency1, IHooks(mockAddr), 3000, sqrtPriceX96, ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
        BalanceDelta balanceDelta = modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);

        bytes32 beforeSelector = MockHooks.beforeRemoveLiquidity.selector;
        bytes memory beforeParams = abi.encode(address(modifyLiquidityRouter), key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
        bytes32 afterSelector = MockHooks.afterRemoveLiquidity.selector;
        bytes memory afterParams =
            abi.encode(address(modifyLiquidityRouter), key, REMOVE_LIQUIDITY_PARAMS, balanceDelta, ZERO_BYTES);

        assertEq(MockContract(mockAddr).timesCalledSelector(beforeSelector), 1);
        assertTrue(MockContract(mockAddr).calledWithSelector(beforeSelector, beforeParams));
        assertEq(MockContract(mockAddr).timesCalledSelector(afterSelector), 1);
        assertTrue(MockContract(mockAddr).calledWithSelector(afterSelector, afterParams));
    }

    function test_addLiquidity_failsWithIncorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPool(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeAddLiquidity.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterAddLiquidity.selector, bytes4(0xdeadbeef));

        // Fails at beforeAddLiquidity hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);

        // Fail at afterAddLiquidity hook.
        mockHooks.setReturnValue(mockHooks.beforeAddLiquidity.selector, mockHooks.beforeAddLiquidity.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_failsWithIncorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPool(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeRemoveLiquidity.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterRemoveLiquidity.selector, bytes4(0xdeadbeef));

        // Fails at beforeRemoveLiquidity hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);

        // Fail at afterRemoveLiquidity hook.
        mockHooks.setReturnValue(mockHooks.beforeRemoveLiquidity.selector, mockHooks.beforeRemoveLiquidity.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_succeedsWithCorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPool(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeAddLiquidity.selector, mockHooks.beforeAddLiquidity.selector);
        mockHooks.setReturnValue(mockHooks.afterAddLiquidity.selector, mockHooks.afterAddLiquidity.selector);

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(
            key.toId(),
            address(modifyLiquidityRouter),
            LIQUIDITY_PARAMS.tickLower,
            LIQUIDITY_PARAMS.tickUpper,
            LIQUIDITY_PARAMS.liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_succeedsWithCorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPool(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeRemoveLiquidity.selector, mockHooks.beforeRemoveLiquidity.selector);
        mockHooks.setReturnValue(mockHooks.afterRemoveLiquidity.selector, mockHooks.afterRemoveLiquidity.selector);

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(
            key.toId(),
            address(modifyLiquidityRouter),
            REMOVE_LIQUIDITY_PARAMS.tickLower,
            REMOVE_LIQUIDITY_PARAMS.tickUpper,
            REMOVE_LIQUIDITY_PARAMS.liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_6909() public {
        // convert test tokens into ERC6909 claims
        claimsRouter.deposit(currency0, address(this), 10_000e18);
        claimsRouter.deposit(currency1, address(this), 10_000e18);
        assertEq(manager.balanceOf(address(this), currency0.toId()), 10_000e18);
        assertEq(manager.balanceOf(address(this), currency1.toId()), 10_000e18);

        uint256 currency0BalanceBefore = currency0.balanceOfSelf();
        uint256 currency1BalanceBefore = currency1.balanceOfSelf();
        uint256 currency0PMBalanceBefore = currency0.balanceOf(address(manager));
        uint256 currency1PMBalanceBefore = currency1.balanceOf(address(manager));

        // allow liquidity router to burn our 6909 tokens
        manager.setOperator(address(modifyLiquidityRouter), true);

        // add liquidity with 6909: settleUsingBurn=true, takeClaims=true (unused)
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES, true, true);

        assertLt(manager.balanceOf(address(this), currency0.toId()), 10_000e18);
        assertLt(manager.balanceOf(address(this), currency1.toId()), 10_000e18);

        // ERC20s are unspent
        assertEq(currency0.balanceOfSelf(), currency0BalanceBefore);
        assertEq(currency1.balanceOfSelf(), currency1BalanceBefore);

        // PoolManager did not receive net-new ERC20s
        assertEq(currency0.balanceOf(address(manager)), currency0PMBalanceBefore);
        assertEq(currency1.balanceOf(address(manager)), currency1PMBalanceBefore);
    }

    function test_removeLiquidity_6909() public {
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);

        assertEq(manager.balanceOf(address(this), currency0.toId()), 0);
        assertEq(manager.balanceOf(address(this), currency1.toId()), 0);

        uint256 currency0BalanceBefore = currency0.balanceOfSelf();
        uint256 currency1BalanceBefore = currency1.balanceOfSelf();
        uint256 currency0PMBalanceBefore = currency0.balanceOf(address(manager));
        uint256 currency1PMBalanceBefore = currency1.balanceOf(address(manager));

        // remove liquidity as 6909: settleUsingBurn=true (unused), takeClaims=true
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES, true, true);

        assertTrue(manager.balanceOf(address(this), currency0.toId()) > 0);
        assertTrue(manager.balanceOf(address(this), currency1.toId()) > 0);

        // ERC20s are unspent
        assertEq(currency0.balanceOfSelf(), currency0BalanceBefore);
        assertEq(currency1.balanceOfSelf(), currency1BalanceBefore);

        // PoolManager did lose ERC-20s
        assertEq(currency0.balanceOf(address(manager)), currency0PMBalanceBefore);
        assertEq(currency1.balanceOf(address(manager)), currency1PMBalanceBefore);
    }

    function test_addLiquidity_gas() public {
        IPoolManager.ModifyLiquidityParams memory uniqueParams =
            IPoolManager.ModifyLiquidityParams({tickLower: -300, tickUpper: -180, liquidityDelta: 1e18, salt: 0});
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);
        snapLastCall("simple addLiquidity");
    }

    function test_addLiquidity_secondAdditionSameRange_gas() public {
        IPoolManager.ModifyLiquidityParams memory uniqueParams =
            IPoolManager.ModifyLiquidityParams({tickLower: -300, tickUpper: -180, liquidityDelta: 1e18, salt: 0});
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);
        snapLastCall("simple addLiquidity second addition same range");
    }

    function test_removeLiquidity_gas() public {
        IPoolManager.ModifyLiquidityParams memory uniqueParams =
            IPoolManager.ModifyLiquidityParams({tickLower: -300, tickUpper: -180, liquidityDelta: 1e18, salt: 0});
        // add some liquidity to remove
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);

        uniqueParams.liquidityDelta *= -1;
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);
        snapLastCall("simple removeLiquidity");
    }

    function test_removeLiquidity_someLiquidityRemains_gas() public {
        // add double the liquidity to remove
        IPoolManager.ModifyLiquidityParams memory uniqueParams =
            IPoolManager.ModifyLiquidityParams({tickLower: -300, tickUpper: -180, liquidityDelta: 1e18, salt: 0});
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);

        uniqueParams.liquidityDelta /= -2;
        modifyLiquidityNoChecks.modifyLiquidity(key, uniqueParams, ZERO_BYTES);
        snapLastCall("simple removeLiquidity some liquidity remains");
    }

    function test_addLiquidity_succeeds() public {
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_removeLiquidity_succeeds() public {
        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
    }

    function test_addLiquidity_withNative_gas() public {
        modifyLiquidityRouter.modifyLiquidity{value: 1 ether}(nativeKey, LIQUIDITY_PARAMS, ZERO_BYTES);
        snapLastCall("addLiquidity with native token");
    }

    function test_removeLiquidity_withNative_gas() public {
        modifyLiquidityRouter.modifyLiquidity{value: 1 ether}(nativeKey, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
        snapLastCall("removeLiquidity with native token");
    }

    function test_addLiquidity_withHooks_gas() public {
        address allHooksAddr = Constants.ALL_HOOKS;
        MockHooks impl = new MockHooks();
        vm.etch(allHooksAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(allHooksAddr);

        (key,) = initPool(currency0, currency1, mockHooks, 3000, SQRT_PRICE_1_1, ZERO_BYTES);

        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
        snapLastCall("addLiquidity with empty hook");
    }

    function test_removeLiquidity_withHooks_gas() public {
        address allHooksAddr = Constants.ALL_HOOKS;
        MockHooks impl = new MockHooks();
        vm.etch(allHooksAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(allHooksAddr);

        (key,) = initPool(currency0, currency1, mockHooks, 3000, SQRT_PRICE_1_1, ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);

        modifyLiquidityRouter.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, ZERO_BYTES);
        snapLastCall("removeLiquidity with empty hook");
    }

    function test_swap_failsIfNotInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        key.fee = 100;
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -100, sqrtPriceLimitX96: sqrtPriceX96});

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        vm.expectRevert(Pool.PoolNotInitialized.selector);
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
    }

    function test_swap_succeedsIfInitialized() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        vm.expectEmit(true, true, true, true);
        emit Swap(
            key.toId(), address(swapRouter), int128(-100), int128(98), 79228162514264329749955861424, 1e18, -1, 3000
        );

        swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);
    }

    function test_swap_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.swap(key, SWAP_PARAMS, ZERO_BYTES);
    }

    function test_swap_succeedsWithNativeTokensIfInitialized() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        vm.expectEmit(true, true, true, true);
        emit Swap(
            nativeKey.toId(),
            address(swapRouter),
            int128(-100),
            int128(98),
            79228162514264329749955861424,
            1e18,
            -1,
            3000
        );

        swapRouter.swap{value: 100}(nativeKey, SWAP_PARAMS, testSettings, ZERO_BYTES);
    }

    function test_swap_succeedsWithHooksIfInitialized() public {
        address payable mockAddr = payable(address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG)));
        address payable hookAddr = payable(Constants.ALL_HOOKS);

        vm.etch(hookAddr, vm.getDeployedCode("EmptyTestHooks.sol:EmptyTestHooks"));
        MockContract mockContract = new MockContract();
        vm.etch(mockAddr, address(mockContract).code);

        MockContract(mockAddr).setImplementation(hookAddr);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(mockAddr), 3000, SQRT_PRICE_1_1, ZERO_BYTES);

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        BalanceDelta balanceDelta = swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);

        bytes32 beforeSelector = MockHooks.beforeSwap.selector;
        bytes memory beforeParams = abi.encode(address(swapRouter), key, SWAP_PARAMS, ZERO_BYTES);

        bytes32 afterSelector = MockHooks.afterSwap.selector;
        bytes memory afterParams = abi.encode(address(swapRouter), key, SWAP_PARAMS, balanceDelta, ZERO_BYTES);

        assertEq(MockContract(mockAddr).timesCalledSelector(beforeSelector), 1);
        assertTrue(MockContract(mockAddr).calledWithSelector(beforeSelector, beforeParams));
        assertEq(MockContract(mockAddr).timesCalledSelector(afterSelector), 1);
        assertTrue(MockContract(mockAddr).calledWithSelector(afterSelector, afterParams));
    }

    function test_swap_failsWithIncorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);

        IPoolManager.SwapParams memory swapParams =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 10, sqrtPriceLimitX96: SQRT_PRICE_1_2});

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterSwap.selector, bytes4(0xdeadbeef));

        // Fails at beforeSwap hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        swapRouter.swap(key, swapParams, testSettings, ZERO_BYTES);

        // Fail at afterSwap hook.
        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, mockHooks.beforeSwap.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        swapRouter.swap(key, swapParams, testSettings, ZERO_BYTES);
    }

    function test_swap_succeedsWithCorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);

        IPoolManager.SwapParams memory swapParams =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -10, sqrtPriceLimitX96: SQRT_PRICE_1_2});

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, mockHooks.beforeSwap.selector);
        mockHooks.setReturnValue(mockHooks.afterSwap.selector, mockHooks.afterSwap.selector);

        vm.expectEmit(true, true, true, true);
        emit Swap(key.toId(), address(swapRouter), -10, 8, 79228162514264336880490487708, 1e18, -1, 100);

        swapRouter.swap(key, swapParams, testSettings, ZERO_BYTES);
    }

    function test_swap_succeeds() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);
    }

    function test_swap_gas() public {
        swapRouterNoChecks.swap(key, SWAP_PARAMS);
        snapLastCall("simple swap");
    }

    function test_swap_withNative_succeeds() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        swapRouter.swap{value: 100}(nativeKey, SWAP_PARAMS, testSettings, ZERO_BYTES);
    }

    function test_swap_withNative_gas() public {
        swapRouterNoChecks.swap{value: 100}(nativeKey, SWAP_PARAMS);
        snapLastCall("simple swap with native");
    }

    function test_swap_withHooks_gas() public {
        address allHooksAddr = Constants.ALL_HOOKS;

        MockHooks impl = new MockHooks();
        vm.etch(allHooksAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(allHooksAddr);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, mockHooks, 3000, SQRT_PRICE_1_1, ZERO_BYTES);

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);

        IPoolManager.SwapParams memory swapParams =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -100, sqrtPriceLimitX96: SQRT_PRICE_1_4});
        testSettings = PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        swapRouter.swap(key, swapParams, testSettings, ZERO_BYTES);
        snapLastCall("swap with hooks");
    }

    function test_swap_mint6909IfOutputNotTaken_gas() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        vm.expectEmit();
        emit Transfer(address(swapRouter), address(0), address(this), CurrencyLibrary.toId(currency1), 98);
        swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);
        snapLastCall("swap mint output as 6909");

        uint256 erc6909Balance = manager.balanceOf(address(this), CurrencyLibrary.toId(currency1));
        assertEq(erc6909Balance, 98);
    }

    function test_swap_mint6909IfNativeOutputNotTaken_gas() public {
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: false, amountSpecified: -100, sqrtPriceLimitX96: SQRT_PRICE_2_1});

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        vm.expectEmit();
        emit Transfer(address(swapRouter), address(0), address(this), CurrencyLibrary.toId(CurrencyLibrary.NATIVE), 98);
        swapRouter.swap(nativeKey, params, testSettings, ZERO_BYTES);
        snapLastCall("swap mint native output as 6909");

        uint256 erc6909Balance = manager.balanceOf(address(this), CurrencyLibrary.toId(CurrencyLibrary.NATIVE));
        assertEq(erc6909Balance, 98);
    }

    function test_swap_burn6909AsInput_gas() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        vm.expectEmit();
        emit Transfer(address(swapRouter), address(0), address(this), CurrencyLibrary.toId(currency1), 98);
        swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);

        uint256 erc6909Balance = manager.balanceOf(address(this), uint256(uint160(Currency.unwrap(currency1))));
        assertEq(erc6909Balance, 98);

        // give permission for swapRouter to burn the 6909s
        manager.setOperator(address(swapRouter), true);

        // swap from currency1 to currency0 again, using 6909s as input tokens
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: false, amountSpecified: 25, sqrtPriceLimitX96: SQRT_PRICE_4_1});
        testSettings = PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: true});

        vm.expectEmit();
        emit Transfer(address(swapRouter), address(this), address(0), CurrencyLibrary.toId(currency1), 27);
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        snapLastCall("swap burn 6909 for input");

        erc6909Balance = manager.balanceOf(address(this), CurrencyLibrary.toId(currency1));
        assertEq(erc6909Balance, 71);
    }

    function test_swap_burnNative6909AsInput_gas() public {
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: false, amountSpecified: -100, sqrtPriceLimitX96: SQRT_PRICE_2_1});

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: true, settleUsingBurn: false});

        vm.expectEmit();
        emit Transfer(address(swapRouter), address(0), address(this), CurrencyLibrary.toId(CurrencyLibrary.NATIVE), 98);
        swapRouter.swap(nativeKey, params, testSettings, ZERO_BYTES);

        uint256 erc6909Balance = manager.balanceOf(address(this), CurrencyLibrary.toId(CurrencyLibrary.NATIVE));
        assertEq(erc6909Balance, 98);

        // give permission for swapRouter to burn the 6909s
        manager.setOperator(address(swapRouter), true);

        // swap from currency0 to currency1, using 6909s as input tokens
        params = IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 25, sqrtPriceLimitX96: SQRT_PRICE_1_4});
        testSettings = PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: true});

        vm.expectEmit();
        emit Transfer(address(swapRouter), address(this), address(0), CurrencyLibrary.toId(CurrencyLibrary.NATIVE), 27);
        // don't have to send in native currency since burning 6909 for input
        swapRouter.swap(nativeKey, params, testSettings, ZERO_BYTES);
        snapLastCall("swap burn native 6909 for input");

        erc6909Balance = manager.balanceOf(address(this), CurrencyLibrary.toId(CurrencyLibrary.NATIVE));
        assertEq(erc6909Balance, 71);
    }

    function test_swap_againstLiquidity_gas() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);

        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -100, sqrtPriceLimitX96: SQRT_PRICE_1_4});

        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        snapLastCall("swap against liquidity");
    }

    function test_swap_againstLiqWithNative_gas() public {
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        swapRouter.swap{value: 1 ether}(nativeKey, SWAP_PARAMS, testSettings, ZERO_BYTES);

        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -100, sqrtPriceLimitX96: SQRT_PRICE_1_4});

        swapRouter.swap{value: 1 ether}(nativeKey, params, testSettings, ZERO_BYTES);
        snapLastCall("swap against liquidity with native token");
    }

    function test_swap_afterSwapFeeOnUnspecified_exactInput() public {
        address hookAddr = address(uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG));
        FeeTakingHook impl = new FeeTakingHook(manager);
        vm.etch(hookAddr, address(impl).code);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);

        uint256 balanceBefore0 = currency0.balanceOf(address(this));
        uint256 balanceBefore1 = currency1.balanceOf(address(this));

        uint256 amountToSwap = 1000;
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(amountToSwap),
            sqrtPriceLimitX96: SQRT_PRICE_1_2
        });
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        snapLastCall("swap CA fee on unspecified");

        // input is 1000 for output of 998 with this much liquidity available
        // plus a fee of 1.23% on unspecified (output) => (998*123)/10000 = 12
        assertEq(currency0.balanceOf(address(this)), balanceBefore0 - amountToSwap, "amount 0");
        assertEq(currency1.balanceOf(address(this)), balanceBefore1 + (998 - 12), "amount 1");
    }

    function test_swap_afterSwapFeeOnUnspecified_exactOutput() public {
        address hookAddr = address(uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG));
        FeeTakingHook impl = new FeeTakingHook(manager);
        vm.etch(hookAddr, address(impl).code);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);

        uint256 balanceBefore0 = currency0.balanceOf(address(this));
        uint256 balanceBefore1 = currency1.balanceOf(address(this));

        uint256 amountToSwap = 1000;
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(amountToSwap),
            sqrtPriceLimitX96: SQRT_PRICE_1_2
        });
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);

        // input is 1002 for output of 1000 with this much liquidity available
        // plus a fee of 1.23% on unspecified (input) => (1002*123)/10000 = 12
        assertEq(currency0.balanceOf(address(this)), balanceBefore0 - 1002 - 12, "amount 0");
        assertEq(currency1.balanceOf(address(this)), balanceBefore1 + amountToSwap, "amount 1");
    }

    function test_swap_beforeSwapNoOpsSwap_exactInput() public {
        address hookAddr = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG));
        CustomCurveHook impl = new CustomCurveHook(manager);
        vm.etch(hookAddr, address(impl).code);

        (key,) = initPool(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);
        // add liquidity by sending tokens straight into the contract
        key.currency0.transfer(hookAddr, 10e18);
        key.currency1.transfer(hookAddr, 10e18);

        uint256 balanceBefore0 = currency0.balanceOf(address(this));
        uint256 balanceBefore1 = currency1.balanceOf(address(this));

        uint256 amountToSwap = 123456;
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(amountToSwap),
            sqrtPriceLimitX96: SQRT_PRICE_1_2
        });
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);
        snapLastCall("swap CA custom curve + swap noop");

        // the custom curve hook is 1-1 linear
        assertEq(currency0.balanceOf(address(this)), balanceBefore0 - amountToSwap, "amount 0");
        assertEq(currency1.balanceOf(address(this)), balanceBefore1 + amountToSwap, "amount 1");
    }

    function test_swap_beforeSwapNoOpsSwap_exactOutput() public {
        address hookAddr = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG));
        CustomCurveHook impl = new CustomCurveHook(manager);
        vm.etch(hookAddr, address(impl).code);

        (key,) = initPool(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);
        // add liquidity by sending tokens straight into the contract
        key.currency0.transfer(hookAddr, 10e18);
        key.currency1.transfer(hookAddr, 10e18);

        uint256 balanceBefore0 = currency0.balanceOf(address(this));
        uint256 balanceBefore1 = currency1.balanceOf(address(this));

        uint256 amountToSwap = 123456;
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(amountToSwap),
            sqrtPriceLimitX96: SQRT_PRICE_1_2
        });
        swapRouter.swap(key, params, testSettings, ZERO_BYTES);

        // the custom curve hook is 1-1 linear
        assertEq(currency0.balanceOf(address(this)), balanceBefore0 - amountToSwap, "amount 0");
        assertEq(currency1.balanceOf(address(this)), balanceBefore1 + amountToSwap, "amount 1");
    }

    // maximum available liquidity in each direction for the pool in fuzz_swap_beforeSwapReturnsDelta
    int128 maxPossibleIn_fuzz_test = -6018336102428409;
    int128 maxPossibleOut_fuzz_test = 5981737760509662;

    function test_fuzz_swap_beforeSwapReturnsDelta(int128 hookDeltaSpecified, int256 amountSpecified, bool zeroForOne)
        public
    {
        // ------------------------ SETUP ------------------------
        Currency specifiedCurrency;
        bool isExactIn;
        address hookAddr = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG));

        // stack too deep management
        {
            // setup the hook and the pool

            DeltaReturningHook impl = new DeltaReturningHook(manager);
            vm.etch(hookAddr, address(impl).code);

            // initialize the pool and give the hook tokens to pay into swaps
            (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hookAddr), 100, SQRT_PRICE_1_1, ZERO_BYTES);
            key.currency0.transfer(hookAddr, type(uint128).max);
            key.currency1.transfer(hookAddr, type(uint128).max);

            // bound amount specified to be a fair amount less than the amount of liquidity we have
            amountSpecified = int128(bound(amountSpecified, -3e11, 3e11));
            isExactIn = amountSpecified < 0;
            specifiedCurrency = (isExactIn == zeroForOne) ? key.currency0 : key.currency1;

            // bound delta in specified to not take more than the reserves available, nor be the minimum int to
            // stop the hook reverting on take/settle
            uint128 reservesOfSpecified = uint128(specifiedCurrency.balanceOf(address(manager)));
            hookDeltaSpecified = int128(bound(hookDeltaSpecified, type(int128).min + 1, int128(reservesOfSpecified)));
            DeltaReturningHook(hookAddr).setDeltaSpecified(hookDeltaSpecified);
        }

        // setup swap variables
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: (zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT)
        });

        // ------------------------ FUZZING CASES ------------------------
        // with an amount specified of 0: the trade reverts
        if (amountSpecified == 0) {
            vm.expectRevert(IPoolManager.SwapAmountCannotBeZero.selector);
            swapRouter.swap(key, params, testSettings, ZERO_BYTES);

            // trade is exact input of n:, the hook cannot TAKE (+ve hookDeltaSpecified) more than n in input
            // otherwise the user would have to send more than n in input
        } else if (isExactIn && (hookDeltaSpecified > -amountSpecified)) {
            vm.expectRevert(Hooks.HookDeltaExceedsSwapAmount.selector);
            swapRouter.swap(key, params, testSettings, ZERO_BYTES);

            // exact output of n: the hook cannot GIVE (-ve hookDeltaSpecified) more than n in output
            // otherwise the user would receive more than n in output
        } else if (!isExactIn && (amountSpecified < -hookDeltaSpecified)) {
            vm.expectRevert(Hooks.HookDeltaExceedsSwapAmount.selector);
            swapRouter.swap(key, params, testSettings, ZERO_BYTES);

            // successful swaps !
        } else {
            uint256 balanceThisBefore = specifiedCurrency.balanceOf(address(this));
            uint256 balanceHookBefore = specifiedCurrency.balanceOf(hookAddr);
            uint256 balanceManagerBefore = specifiedCurrency.balanceOf(address(manager));

            BalanceDelta delta = swapRouter.swap(key, params, testSettings, ZERO_BYTES);
            int128 deltaSpecified = (zeroForOne == isExactIn) ? delta.amount0() : delta.amount1();

            // in all cases the hook gets what they took, and the user gets the swap's output delta (checked more below)
            assertEq(
                balanceHookBefore.toInt256() + hookDeltaSpecified,
                specifiedCurrency.balanceOf(hookAddr).toInt256(),
                "hook balance change incorrect"
            );
            assertEq(
                balanceThisBefore.toInt256() + deltaSpecified,
                specifiedCurrency.balanceOf(address(this)).toInt256(),
                "swapper balance change incorrect"
            );

            // exact input, where there arent enough input reserves available to pay swap and hook
            // note: all 3 values are negative, so we use <
            if (isExactIn && (hookDeltaSpecified + amountSpecified < maxPossibleIn_fuzz_test)) {
                // the hook will have taken hookDeltaSpecified of the maxPossibleIn
                assertEq(deltaSpecified, maxPossibleIn_fuzz_test - hookDeltaSpecified, "deltaSpecified exact input");
                // the manager received all possible input tokens
                assertEq(
                    balanceManagerBefore.toInt256() - maxPossibleIn_fuzz_test,
                    specifiedCurrency.balanceOf(address(manager)).toInt256(),
                    "manager balance change exact input"
                );

                // exact output, where there isnt enough output reserves available to pay swap and hook
            } else if (!isExactIn && (hookDeltaSpecified + amountSpecified > maxPossibleOut_fuzz_test)) {
                // the hook will have taken hookDeltaSpecified of the maxPossibleOut
                assertEq(deltaSpecified, maxPossibleOut_fuzz_test - hookDeltaSpecified, "deltaSpecified exact output");
                // the manager sent out all possible output tokens
                assertEq(
                    balanceManagerBefore.toInt256() - maxPossibleOut_fuzz_test,
                    specifiedCurrency.balanceOf(address(manager)).toInt256(),
                    "manager balance change exact output"
                );

                // enough reserves were available, so the user got what they desired
            } else {
                assertEq(deltaSpecified, amountSpecified, "deltaSpecified not amountSpecified");
                assertEq(
                    balanceManagerBefore.toInt256() - amountSpecified - hookDeltaSpecified,
                    specifiedCurrency.balanceOf(address(manager)).toInt256(),
                    "manager balance change not"
                );
            }
        }
    }

    function test_swap_accruesProtocolFees(uint16 protocolFee0, uint16 protocolFee1, int256 amountSpecified) public {
        protocolFee0 = uint16(bound(protocolFee0, 0, 1000));
        protocolFee1 = uint16(bound(protocolFee1, 0, 1000));
        vm.assume(amountSpecified != 0);

        uint24 protocolFee = (uint24(protocolFee1) << 12) | uint24(protocolFee0);

        (,, uint24 slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, 0);

        vm.prank(address(feeController));
        manager.setProtocolFee(key, protocolFee);

        (,, slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, protocolFee);

        // Add liquidity - Fees dont accrue for positive liquidity delta.
        IPoolManager.ModifyLiquidityParams memory params = LIQUIDITY_PARAMS;
        modifyLiquidityRouter.modifyLiquidity(key, params, ZERO_BYTES);

        assertEq(manager.protocolFeesAccrued(currency0), 0);
        assertEq(manager.protocolFeesAccrued(currency1), 0);

        // Remove liquidity - Fees dont accrue for negative liquidity delta.
        params.liquidityDelta = -LIQUIDITY_PARAMS.liquidityDelta;
        modifyLiquidityRouter.modifyLiquidity(key, params, ZERO_BYTES);

        assertEq(manager.protocolFeesAccrued(currency0), 0);
        assertEq(manager.protocolFeesAccrued(currency1), 0);

        // Now re-add the liquidity to test swap
        params.liquidityDelta = LIQUIDITY_PARAMS.liquidityDelta;
        modifyLiquidityRouter.modifyLiquidity(key, params, ZERO_BYTES);

        IPoolManager.SwapParams memory swapParams =
            IPoolManager.SwapParams(false, amountSpecified, TickMath.MAX_SQRT_PRICE - 1);
        BalanceDelta delta = swapRouter.swap(key, swapParams, PoolSwapTest.TestSettings(false, false), ZERO_BYTES);
        uint256 expectedProtocolFee =
            uint256(uint128(-delta.amount1())) * protocolFee1 / ProtocolFeeLibrary.PIPS_DENOMINATOR;
        assertEq(manager.protocolFeesAccrued(currency0), 0);
        assertEq(manager.protocolFeesAccrued(currency1), expectedProtocolFee);
    }

    function test_donate_failsIfNotInitialized() public {
        vm.expectRevert(Pool.PoolNotInitialized.selector);
        donateRouter.donate(uninitializedKey, 100, 100, ZERO_BYTES);
    }

    function test_donate_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.donate(key, 100, 100, ZERO_BYTES);
    }

    function test_donate_failsIfNoLiquidity(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1));

        (key,) = initPool(currency0, currency1, IHooks(address(0)), 100, sqrtPriceX96, ZERO_BYTES);

        vm.expectRevert(Pool.NoLiquidityToReceiveFees.selector);
        donateRouter.donate(key, 100, 100, ZERO_BYTES);
    }

    // test successful donation if pool has liquidity
    function test_donate_succeedsWhenPoolHasLiquidity() public {
        (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = manager.getFeeGrowthGlobals(key.toId());
        assertEq(feeGrowthGlobal0X128, 0);
        assertEq(feeGrowthGlobal1X128, 0);

        donateRouter.donate(key, 100, 200, ZERO_BYTES);
        snapLastCall("donate gas with 2 tokens");

        (feeGrowthGlobal0X128, feeGrowthGlobal1X128) = manager.getFeeGrowthGlobals(key.toId());
        assertEq(feeGrowthGlobal0X128, 34028236692093846346337);
        assertEq(feeGrowthGlobal1X128, 68056473384187692692674);
    }

    function test_donate_succeedsForNativeTokensWhenPoolHasLiquidity() public {
        (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = manager.getFeeGrowthGlobals(nativeKey.toId());
        assertEq(feeGrowthGlobal0X128, 0);
        assertEq(feeGrowthGlobal1X128, 0);

        donateRouter.donate{value: 100}(nativeKey, 100, 200, ZERO_BYTES);

        (feeGrowthGlobal0X128, feeGrowthGlobal1X128) = manager.getFeeGrowthGlobals(nativeKey.toId());
        assertEq(feeGrowthGlobal0X128, 34028236692093846346337);
        assertEq(feeGrowthGlobal1X128, 68056473384187692692674);
    }

    function test_donate_failsWithIncorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_DONATE_FLAG | Hooks.AFTER_DONATE_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterDonate.selector, bytes4(0xdeadbeef));

        // Fails at beforeDonate hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        donateRouter.donate(key, 100, 200, ZERO_BYTES);

        // Fail at afterDonate hook.
        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, mockHooks.beforeDonate.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        donateRouter.donate(key, 100, 200, ZERO_BYTES);
    }

    function test_donate_succeedsWithCorrectSelectors() public {
        address hookAddr = address(uint160(Hooks.BEFORE_DONATE_FLAG | Hooks.AFTER_DONATE_FLAG));

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        (key,) = initPoolAndAddLiquidity(currency0, currency1, mockHooks, 100, SQRT_PRICE_1_1, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, mockHooks.beforeDonate.selector);
        mockHooks.setReturnValue(mockHooks.afterDonate.selector, mockHooks.afterDonate.selector);

        donateRouter.donate(key, 100, 200, ZERO_BYTES);
    }

    function test_donate_OneToken_gas() public {
        donateRouter.donate(key, 100, 0, ZERO_BYTES);
        snapLastCall("donate gas with 1 token");
    }

    function test_take_failsWithNoLiquidity() public {
        deployFreshManagerAndRouters();

        vm.expectRevert();
        takeRouter.take(key, 100, 0);
    }

    function test_take_failsWithInvalidTokensThatDoNotReturnTrueOnTransfer() public {
        TestInvalidERC20 invalidToken = new TestInvalidERC20(2 ** 255);
        Currency invalidCurrency = Currency.wrap(address(invalidToken));
        invalidToken.approve(address(modifyLiquidityRouter), type(uint256).max);
        invalidToken.approve(address(takeRouter), type(uint256).max);

        bool currency0Invalid = invalidCurrency < currency0;

        (key,) = initPoolAndAddLiquidity(
            (currency0Invalid ? invalidCurrency : currency0),
            (currency0Invalid ? currency0 : invalidCurrency),
            IHooks(address(0)),
            3000,
            SQRT_PRICE_1_1,
            ZERO_BYTES
        );

        (uint256 amount0, uint256 amount1) = currency0Invalid ? (1, 0) : (0, 1);
        vm.expectRevert(CurrencyLibrary.ERC20TransferFailed.selector);
        takeRouter.take(key, amount0, amount1);

        // should not revert when non zero amount passed in for valid currency
        // assertions inside takeRouter because it takes then settles
        (amount0, amount1) = currency0Invalid ? (0, 1) : (1, 0);
        takeRouter.take(key, amount0, amount1);
    }

    function test_take_succeedsWithPoolWithLiquidity() public {
        takeRouter.take(key, 1, 1); // assertions inside takeRouter because it takes then settles
    }

    function test_take_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.take(key.currency0, address(this), 1);
    }

    function test_take_succeedsWithPoolWithLiquidityWithNativeToken() public {
        takeRouter.take{value: 1}(nativeKey, 1, 1); // assertions inside takeRouter because it takes then settles
    }

    function test_settle_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.settle(key.currency0);
    }

    function test_settle_revertsSendingNativeWithToken() public {
        vm.expectRevert(IPoolManager.NonZeroNativeValue.selector);
        settleRouter.settle{value: 1}(key);
    }

    function test_mint_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.mint(address(this), key.currency0.toId(), 1);
    }

    function test_burn_failsIfLocked() public {
        vm.expectRevert(IPoolManager.ManagerLocked.selector);
        manager.burn(address(this), key.currency0.toId(), 1);
    }

    function test_collectProtocolFees_ERC20_accumulateFees_gas() public {
        uint256 expectedFees = 10;

        (,, uint24 slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, 0);

        vm.prank(address(feeController));
        manager.setProtocolFee(key, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        (,, slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        swapRouter.swap(
            key,
            IPoolManager.SwapParams(true, -10000, SQRT_PRICE_1_2),
            PoolSwapTest.TestSettings(false, false),
            ZERO_BYTES
        );

        assertEq(manager.protocolFeesAccrued(currency0), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency1), 0);
        assertEq(currency0.balanceOf(address(1)), 0);
        vm.prank(address(feeController));
        manager.collectProtocolFees(address(1), currency0, expectedFees);
        snapLastCall("erc20 collect protocol fees");
        assertEq(currency0.balanceOf(address(1)), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency0), 0);
    }

    function test_collectProtocolFees_ERC20_accumulateFees_exactOutput() public {
        uint256 expectedFees = 10;

        (,, uint24 slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, 0);

        vm.prank(address(feeController));
        manager.setProtocolFee(key, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        (,, slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        swapRouter.swap(
            key,
            IPoolManager.SwapParams(true, 10000, SQRT_PRICE_1_2),
            PoolSwapTest.TestSettings(false, false),
            ZERO_BYTES
        );

        assertEq(manager.protocolFeesAccrued(currency0), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency1), 0);
        assertEq(currency0.balanceOf(address(1)), 0);
        vm.prank(address(feeController));
        manager.collectProtocolFees(address(1), currency0, expectedFees);
        assertEq(currency0.balanceOf(address(1)), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency0), 0);
    }

    function test_collectProtocolFees_ERC20_returnsAllFeesIf0IsProvidedAsParameter() public {
        uint256 expectedFees = 10;

        (,, uint24 slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, 0);

        vm.prank(address(feeController));
        manager.setProtocolFee(key, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        (,, slot0ProtocolFee,) = manager.getSlot0(key.toId());
        assertEq(slot0ProtocolFee, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        swapRouter.swap(
            key,
            IPoolManager.SwapParams(false, -10000, TickMath.MAX_SQRT_PRICE - 1),
            PoolSwapTest.TestSettings(false, false),
            ZERO_BYTES
        );

        assertEq(manager.protocolFeesAccrued(currency0), 0);
        assertEq(manager.protocolFeesAccrued(currency1), expectedFees);
        assertEq(currency1.balanceOf(address(1)), 0);
        vm.prank(address(feeController));
        manager.collectProtocolFees(address(1), currency1, 0);
        assertEq(currency1.balanceOf(address(1)), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency1), 0);
    }

    function test_collectProtocolFees_nativeToken_accumulateFees_gas() public {
        uint256 expectedFees = 10;
        Currency nativeCurrency = CurrencyLibrary.NATIVE;

        (,, uint24 slot0ProtocolFee,) = manager.getSlot0(nativeKey.toId());
        assertEq(slot0ProtocolFee, 0);

        vm.prank(address(feeController));
        manager.setProtocolFee(nativeKey, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        (,, slot0ProtocolFee,) = manager.getSlot0(nativeKey.toId());
        assertEq(slot0ProtocolFee, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        swapRouter.swap{value: 10000}(
            nativeKey,
            IPoolManager.SwapParams(true, -10000, SQRT_PRICE_1_2),
            PoolSwapTest.TestSettings(false, false),
            ZERO_BYTES
        );

        assertEq(manager.protocolFeesAccrued(nativeCurrency), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency1), 0);
        assertEq(nativeCurrency.balanceOf(address(1)), 0);
        vm.prank(address(feeController));
        manager.collectProtocolFees(address(1), nativeCurrency, expectedFees);
        snapLastCall("native collect protocol fees");
        assertEq(nativeCurrency.balanceOf(address(1)), expectedFees);
        assertEq(manager.protocolFeesAccrued(nativeCurrency), 0);
    }

    function test_collectProtocolFees_nativeToken_returnsAllFeesIf0IsProvidedAsParameter() public {
        uint256 expectedFees = 10;
        Currency nativeCurrency = CurrencyLibrary.NATIVE;

        (,, uint24 slot0ProtocolFee,) = manager.getSlot0(nativeKey.toId());
        assertEq(slot0ProtocolFee, 0);

        vm.prank(address(feeController));
        manager.setProtocolFee(nativeKey, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        (,, slot0ProtocolFee,) = manager.getSlot0(nativeKey.toId());
        assertEq(slot0ProtocolFee, MAX_PROTOCOL_FEE_BOTH_TOKENS);

        swapRouter.swap{value: 10000}(
            nativeKey,
            IPoolManager.SwapParams(true, -10000, SQRT_PRICE_1_2),
            PoolSwapTest.TestSettings(false, false),
            ZERO_BYTES
        );

        assertEq(manager.protocolFeesAccrued(nativeCurrency), expectedFees);
        assertEq(manager.protocolFeesAccrued(currency1), 0);
        assertEq(nativeCurrency.balanceOf(address(1)), 0);
        vm.prank(address(feeController));
        manager.collectProtocolFees(address(1), nativeCurrency, 0);
        assertEq(nativeCurrency.balanceOf(address(1)), expectedFees);
        assertEq(manager.protocolFeesAccrued(nativeCurrency), 0);
    }

    function test_unlock_EmitsCorrectId() public {
        vm.expectEmit(false, false, false, true);
        emit UnlockCallback();
        emptyUnlockRouter.unlock();
    }

    Action[] actions;

    function test_unlock_cannotBeCalledTwiceByCaller() public {
        actions = [Action.NESTED_SELF_UNLOCK];
        nestedActionRouter.unlock(abi.encode(actions));
    }

    function test_unlock_cannotBeCalledTwiceByDifferentCallers() public {
        actions = [Action.NESTED_EXECUTOR_UNLOCK];
        nestedActionRouter.unlock(abi.encode(actions));
    }

    // function testExtsloadForPoolPrice() public {
    //     IPoolManager.key = IPoolManager.PoolKey({
    //         currency0: currency0,
    //         currency1: currency1,
    //         fee: 100,
    //         hooks: IHooks(address(0)),
    //         tickSpacing: 10
    //     });
    //     manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

    //     PoolId poolId = key.toId();
    //     bytes32 slot0Bytes = manager.extsload(keccak256(abi.encode(poolId, POOL_SLOT)));
    //     snapLastCall("poolExtsloadSlot0");

    //     uint160 sqrtPriceX96Extsload;
    //     assembly {
    //         sqrtPriceX96Extsload := and(slot0Bytes, sub(shl(160, 1), 1))
    //     }
    //     (uint160 sqrtPriceX96Slot0,,,,,) = manager.getSlot0(poolId);

    //     // assert that extsload loads the correct storage slot which matches the true slot0
    //     assertEq(sqrtPriceX96Extsload, sqrtPriceX96Slot0);
    // }

    // function testExtsloadMultipleSlots() public {
    //     IPoolManager.key = IPoolManager.PoolKey({
    //         currency0: currency0,
    //         currency1: currency1,
    //         fee: 100,
    //         hooks: IHooks(address(0)),
    //         tickSpacing: 10
    //     });
    //     manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

    //     // populate feeGrowthGlobalX128 struct w/ modify + swap
    //     modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-120, 120, 5 ether, 0));
    //     swapRouter.swap(
    //         key,
    //         IPoolManager.SwapParams(false, 1 ether, TickMath.MAX_SQRT_PRICE - 1),
    //         PoolSwapTest.TestSettings(true, true)
    //     );
    //     swapRouter.swap(
    //         key,
    //         IPoolManager.SwapParams(true, 5 ether, TickMath.MIN_SQRT_PRICE + 1),
    //         PoolSwapTest.TestSettings(true, true)
    //     );

    //     PoolId poolId = key.toId();
    //     bytes memory value = manager.extsload(bytes32(uint256(keccak256(abi.encode(poolId, POOL_SLOT))) + 1), 2);
    //     snapLastCall("poolExtsloadTickInfoStruct");

    //     uint256 feeGrowthGlobal0X128Extsload;
    //     uint256 feeGrowthGlobal1X128Extsload;
    //     assembly {
    //         feeGrowthGlobal0X128Extsload := and(mload(add(value, 0x20)), sub(shl(256, 1), 1))
    //         feeGrowthGlobal1X128Extsload := and(mload(add(value, 0x40)), sub(shl(256, 1), 1))
    //     }

    //     assertEq(feeGrowthGlobal0X128Extsload, 408361710565269213475534193967158);
    //     assertEq(feeGrowthGlobal1X128Extsload, 204793365386061595215803889394593);
    // }

    function test_getPosition() public view {
        Position.Info memory managerPosition =
            manager.getPosition(key.toId(), address(modifyLiquidityRouter), -120, 120, 0);
        assert(LIQUIDITY_PARAMS.liquidityDelta > 0);
        assertEq(managerPosition.liquidity, uint128(uint256(LIQUIDITY_PARAMS.liquidityDelta)));
    }

    function supportsInterface(bytes4) external pure returns (bool) {
        return true;
    }
}
