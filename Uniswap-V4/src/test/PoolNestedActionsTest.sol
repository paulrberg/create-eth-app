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

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IUnlockCallback} from "../interfaces/callback/IUnlockCallback.sol";
import {PoolTestBase} from "./PoolTestBase.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {Constants} from "../../test/utils/Constants.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {Currency} from "../types/Currency.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {CurrencySettleTake} from "../libraries/CurrencySettleTake.sol";
import {StateLibrary} from "../libraries/StateLibrary.sol";
import {TransientStateLibrary} from "../libraries/TransientStateLibrary.sol";

enum Action {
    NESTED_SELF_UNLOCK,
    NESTED_EXECUTOR_UNLOCK,
    SWAP_AND_SETTLE,
    DONATE_AND_SETTLE,
    ADD_LIQUIDITY_AND_SETTLE,
    REMOVE_LIQUIDITY_AND_SETTLE,
    INITIALIZE
}

contract PoolNestedActionsTest is Test, IUnlockCallback {
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    IPoolManager manager;
    NestedActionExecutor public executor;
    address user;

    constructor(IPoolManager _manager) {
        manager = _manager;
        user = msg.sender;
        executor = new NestedActionExecutor(manager, user);
    }

    function unlock(bytes calldata data) external {
        manager.unlock(data);
    }

    /// @notice Called by the pool manager on `msg.sender` when the manager is unlocked
    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        Action[] memory actions = abi.decode(data, (Action[]));
        if (actions.length == 1 && actions[0] == Action.NESTED_SELF_UNLOCK) {
            _nestedUnlock();
        } else {
            executor.execute(actions);
        }
        return "";
    }

    function _nestedUnlock() internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        vm.expectRevert(abi.encodeWithSelector(IPoolManager.AlreadyUnlocked.selector));
        manager.unlock("");
        unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
    }
}

contract NestedActionExecutor is Test, PoolTestBase {
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;
    using CurrencySettleTake for Currency;
    using PoolIdLibrary for PoolKey;

    PoolKey internal key;
    address user;

    error KeyNotSet();

    IPoolManager.ModifyLiquidityParams internal ADD_LIQUIDITY_PARAMS =
        IPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1e18, salt: 0});

    IPoolManager.ModifyLiquidityParams internal REMOVE_LIQUIDITY_PARAMS =
        IPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: -1e18, salt: 0});

    IPoolManager.SwapParams internal SWAP_PARAMS =
        IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -100, sqrtPriceLimitX96: Constants.SQRT_PRICE_1_2});

    uint256 internal DONATE_AMOUNT0 = 12345e6;
    uint256 internal DONATE_AMOUNT1 = 98765e4;

    constructor(IPoolManager _manager, address _user) PoolTestBase(_manager) {
        user = _user;
    }

    function setKey(PoolKey memory _key) external {
        key = _key;
    }

    function execute(Action[] memory actions) public {
        if (Currency.unwrap(key.currency0) == address(0)) revert KeyNotSet();
        for (uint256 i = 0; i < actions.length; i++) {
            Action action = actions[i];
            if (action == Action.NESTED_EXECUTOR_UNLOCK) _nestedUnlock();
            else if (action == Action.SWAP_AND_SETTLE) _swap(msg.sender);
            else if (action == Action.ADD_LIQUIDITY_AND_SETTLE) _addLiquidity(msg.sender);
            else if (action == Action.REMOVE_LIQUIDITY_AND_SETTLE) _removeLiquidity(msg.sender);
            else if (action == Action.DONATE_AND_SETTLE) _donate(msg.sender);
            else if (action == Action.INITIALIZE) _initialize();
        }
    }

    function _nestedUnlock() internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        vm.expectRevert(abi.encodeWithSelector(IPoolManager.AlreadyUnlocked.selector));
        manager.unlock("");
        unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
    }

    function _swap(address caller) internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        (,, int256 deltaCallerBefore0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerBefore1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisBefore0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisBefore1) = _fetchBalances(key.currency1, user, address(this));

        BalanceDelta delta = manager.swap(key, SWAP_PARAMS, "");

        (,, int256 deltaCallerAfter0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerAfter1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisAfter0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisAfter1) = _fetchBalances(key.currency1, user, address(this));

        assertEq(deltaCallerBefore0, deltaCallerAfter0, "Caller delta 0");
        assertEq(deltaCallerBefore1, deltaCallerAfter1, "Caller delta 1");
        assertEq(deltaThisBefore0 + SWAP_PARAMS.amountSpecified, deltaThisAfter0, "Executor delta 0");
        assertEq(deltaThisBefore1 + 98, deltaThisAfter1, "Executor delta 1");
        assertEq(delta.amount0(), deltaThisAfter0, "Swap delta 0");
        assertEq(delta.amount1(), deltaThisAfter1, "Swap delta 1");

        key.currency0.settle(manager, user, uint256(-deltaThisAfter0), false);
        key.currency1.take(manager, user, uint256(deltaThisAfter1), false);
    }

    function _addLiquidity(address caller) internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        (,, int256 deltaCallerBefore0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerBefore1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisBefore0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisBefore1) = _fetchBalances(key.currency1, user, address(this));

        (BalanceDelta delta,) = manager.modifyLiquidity(key, ADD_LIQUIDITY_PARAMS, "");

        (,, int256 deltaCallerAfter0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerAfter1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisAfter0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisAfter1) = _fetchBalances(key.currency1, user, address(this));

        assertEq(deltaCallerBefore0, deltaCallerAfter0, "Caller delta 0");
        assertEq(deltaCallerBefore1, deltaCallerAfter1, "Caller delta 1");
        assertEq(deltaThisBefore0 + delta.amount0(), deltaThisAfter0, "Executor delta 0");
        assertEq(deltaThisBefore1 + delta.amount1(), deltaThisAfter1, "Executor delta 1");

        key.currency0.settle(manager, user, uint256(-deltaThisAfter0), false);
        key.currency1.settle(manager, user, uint256(-deltaThisAfter1), false);
    }

    // cannot remove non-existent liquidity - need to perform an add before this removal
    function _removeLiquidity(address caller) internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        (,, int256 deltaCallerBefore0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerBefore1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisBefore0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisBefore1) = _fetchBalances(key.currency1, user, address(this));

        (BalanceDelta delta,) = manager.modifyLiquidity(key, REMOVE_LIQUIDITY_PARAMS, "");

        (,, int256 deltaCallerAfter0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerAfter1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisAfter0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisAfter1) = _fetchBalances(key.currency1, user, address(this));

        assertEq(deltaCallerBefore0, deltaCallerAfter0, "Caller delta 0");
        assertEq(deltaCallerBefore1, deltaCallerAfter1, "Caller delta 1");
        assertEq(deltaThisBefore0 + delta.amount0(), deltaThisAfter0, "Executor delta 0");
        assertEq(deltaThisBefore1 + delta.amount1(), deltaThisAfter1, "Executor delta 1");

        key.currency0.take(manager, user, uint256(deltaThisAfter0), false);
        key.currency1.take(manager, user, uint256(deltaThisAfter1), false);
    }

    function _donate(address caller) internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        (,, int256 deltaCallerBefore0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerBefore1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisBefore0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisBefore1) = _fetchBalances(key.currency1, user, address(this));

        BalanceDelta delta = manager.donate(key, DONATE_AMOUNT0, DONATE_AMOUNT1, "");

        (,, int256 deltaCallerAfter0) = _fetchBalances(key.currency0, user, caller);
        (,, int256 deltaCallerAfter1) = _fetchBalances(key.currency1, user, caller);
        (,, int256 deltaThisAfter0) = _fetchBalances(key.currency0, user, address(this));
        (,, int256 deltaThisAfter1) = _fetchBalances(key.currency1, user, address(this));

        assertEq(deltaCallerBefore0, deltaCallerAfter0, "Caller delta 0");
        assertEq(deltaCallerBefore1, deltaCallerAfter1, "Caller delta 1");
        assertEq(deltaThisBefore0 - int256(DONATE_AMOUNT0), deltaThisAfter0, "Executor delta 0");
        assertEq(deltaThisBefore1 - int256(DONATE_AMOUNT1), deltaThisAfter1, "Executor delta 1");
        assertEq(-delta.amount0(), int256(DONATE_AMOUNT0), "Donate delta 0");
        assertEq(-delta.amount1(), int256(DONATE_AMOUNT1), "Donate delta 1");

        key.currency0.settle(manager, user, uint256(-deltaThisAfter0), false);
        key.currency1.settle(manager, user, uint256(-deltaThisAfter1), false);
    }

    function _initialize() internal {
        bool unlocked = manager.isUnlocked();
        assertEq(unlocked, true);
        key.tickSpacing = 50;
        PoolId id = key.toId();
        (uint256 price,,,) = manager.getSlot0(id);
        assertEq(price, 0);
        manager.initialize(key, Constants.SQRT_PRICE_1_2, Constants.ZERO_BYTES);
        (price,,,) = manager.getSlot0(id);
        assertEq(price, Constants.SQRT_PRICE_1_2);
    }

    // This will never actually be used - its just to allow us to use the PoolTestBase helper contact
    function unlockCallback(bytes calldata) external pure override returns (bytes memory) {
        return "";
    }
}
