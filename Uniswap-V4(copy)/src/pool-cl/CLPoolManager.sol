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
  
  // SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.24;

import {Fees} from "../Fees.sol";
import {ICLPoolManager} from "./interfaces/ICLPoolManager.sol";
import {IVault} from "../interfaces/IVault.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {CLPool} from "./libraries/CLPool.sol";
import {CLPosition} from "./libraries/CLPosition.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import "./interfaces/ICLHooks.sol";
import {ICLDynamicFeeManager} from "./interfaces/ICLDynamicFeeManager.sol";
import {Hooks} from "../libraries/Hooks.sol";
import {CLPoolParametersHelper} from "./libraries/CLPoolParametersHelper.sol";
import {FeeLibrary} from "../libraries/FeeLibrary.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../types/BalanceDelta.sol";
import {Extsload} from "../Extsload.sol";
import {SafeCast} from "../libraries/SafeCast.sol";

contract CLPoolManager is ICLPoolManager, Fees, Extsload {
    using SafeCast for int256;
    using PoolIdLibrary for PoolKey;
    using Hooks for bytes32;
    using FeeLibrary for uint24;
    using CLPoolParametersHelper for bytes32;
    using CLPool for *;
    using CLPosition for mapping(bytes32 => CLPosition.Info);

    /// @inheritdoc ICLPoolManager
    int24 public constant override MAX_TICK_SPACING = type(int16).max;

    /// @inheritdoc ICLPoolManager
    int24 public constant override MIN_TICK_SPACING = 1;

    mapping(PoolId id => CLPool.State) public pools;

    /// @inheritdoc ICLPoolManager
    address public override masterChef;

    constructor(IVault _vault, uint256 controllerGasLimit) Fees(_vault, controllerGasLimit) {}

    /// @notice pool manager specified in the pool key must match current contract
    modifier poolManagerMatch(address poolManager) {
        if (address(this) != poolManager) revert PoolManagerMismatch();
        _;
    }

    /// @inheritdoc ICLPoolManager
    function getSlot0(PoolId id)
        external
        view
        override
        returns (uint160 sqrtPriceX96, int24 tick, uint16 protocolFee, uint24 swapFee)
    {
        CLPool.Slot0 memory slot0 = pools[id].slot0;
        return (slot0.sqrtPriceX96, slot0.tick, slot0.protocolFee, slot0.swapFee);
    }

    /// @inheritdoc ICLPoolManager
    function getLiquidity(PoolId id) external view override returns (uint128 liquidity) {
        return pools[id].liquidity;
    }

    /// @inheritdoc ICLPoolManager
    function getLiquidity(PoolId id, address _owner, int24 tickLower, int24 tickUpper)
        external
        view
        override
        returns (uint128 liquidity)
    {
        return pools[id].positions.get(_owner, tickLower, tickUpper).liquidity;
    }

    /// @inheritdoc ICLPoolManager
    function getPosition(PoolId id, address owner, int24 tickLower, int24 tickUpper)
        external
        view
        override
        returns (CLPosition.Info memory position)
    {
        return pools[id].positions.get(owner, tickLower, tickUpper);
    }

    /// @inheritdoc ICLPoolManager
    function getLmPool(PoolId id) external view override returns (address lmPool) {
        lmPool = pools[id].getLmPool();
    }

    /// @inheritdoc ICLPoolManager
    function initialize(PoolKey memory key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (int24 tick)
    {
        if (key.fee.isStaticFeeTooLarge(FeeLibrary.ONE_HUNDRED_PERCENT_FEE)) revert FeeTooLarge();

        int24 tickSpacing = key.parameters.getTickSpacing();
        if (tickSpacing > MAX_TICK_SPACING) revert TickSpacingTooLarge();
        if (tickSpacing < MIN_TICK_SPACING) revert TickSpacingTooSmall();
        if (key.currency0 >= key.currency1) revert CurrenciesInitializedOutOfOrder();

        ICLHooks hooks = ICLHooks(address(key.hooks));
        Hooks.validateHookConfig(key);
        _validateHookNoOp(key);

        if (key.parameters.shouldCall(HOOKS_BEFORE_INITIALIZE_OFFSET)) {
            if (hooks.beforeInitialize(msg.sender, key, sqrtPriceX96, hookData) != ICLHooks.beforeInitialize.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        PoolId id = key.toId();
        (, uint16 protocolFee) = _fetchProtocolFee(key);
        uint24 swapFee = key.fee.isDynamicFee() ? _fetchDynamicSwapFee(key) : key.fee.getStaticFee();
        tick = pools[id].initialize(sqrtPriceX96, protocolFee, swapFee);

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Initialize(id, key.currency0, key.currency1, key.fee, tickSpacing, hooks);

        if (key.parameters.shouldCall(HOOKS_AFTER_INITIALIZE_OFFSET)) {
            if (
                hooks.afterInitialize(msg.sender, key, sqrtPriceX96, tick, hookData)
                    != ICLHooks.afterInitialize.selector
            ) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc ICLPoolManager
    function modifyLiquidity(
        PoolKey memory key,
        ICLPoolManager.ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) external override poolManagerMatch(address(key.poolManager)) returns (BalanceDelta delta) {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        ICLHooks hooks = ICLHooks(address(key.hooks));

        if (params.liquidityDelta > 0 && key.parameters.shouldCall(HOOKS_BEFORE_ADD_LIQUIDITY_OFFSET)) {
            bytes4 selector = hooks.beforeAddLiquidity(msg.sender, key, params, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return BalanceDeltaLibrary.MAXIMUM_DELTA;
            } else if (selector != ICLHooks.beforeAddLiquidity.selector) {
                revert Hooks.InvalidHookResponse();
            }
        } else if (params.liquidityDelta <= 0 && key.parameters.shouldCall(HOOKS_BEFORE_REMOVE_LIQUIDITY_OFFSET)) {
            bytes4 selector = hooks.beforeRemoveLiquidity(msg.sender, key, params, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return BalanceDeltaLibrary.MAXIMUM_DELTA;
            } else if (selector != ICLHooks.beforeRemoveLiquidity.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        delta = pools[id].modifyLiquidity(
            CLPool.ModifyLiquidityParams({
                owner: msg.sender,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                liquidityDelta: params.liquidityDelta.toInt128(),
                tickSpacing: key.parameters.getTickSpacing()
            })
        );

        vault.accountPoolBalanceDelta(key, delta, msg.sender);

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit ModifyLiquidity(id, msg.sender, params.tickLower, params.tickUpper, params.liquidityDelta);

        if (params.liquidityDelta > 0 && key.parameters.shouldCall(HOOKS_AFTER_ADD_LIQUIDITY_OFFSET)) {
            if (
                hooks.afterAddLiquidity(msg.sender, key, params, delta, hookData) != ICLHooks.afterAddLiquidity.selector
            ) {
                revert Hooks.InvalidHookResponse();
            }
        } else if (params.liquidityDelta <= 0 && key.parameters.shouldCall(HOOKS_AFTER_REMOVE_LIQUIDITY_OFFSET)) {
            if (
                hooks.afterRemoveLiquidity(msg.sender, key, params, delta, hookData)
                    != ICLHooks.afterRemoveLiquidity.selector
            ) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc ICLPoolManager
    function swap(PoolKey memory key, ICLPoolManager.SwapParams memory params, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (BalanceDelta delta)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        ICLHooks hooks = ICLHooks(address(key.hooks));

        if (key.parameters.shouldCall(HOOKS_BEFORE_SWAP_OFFSET)) {
            bytes4 selector = hooks.beforeSwap(msg.sender, key, params, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return BalanceDeltaLibrary.MAXIMUM_DELTA;
            } else if (selector != ICLHooks.beforeSwap.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        CLPool.SwapState memory state;
        (delta, state) = pools[id].swap(
            CLPool.SwapParams({
                tickSpacing: key.parameters.getTickSpacing(),
                zeroForOne: params.zeroForOne,
                amountSpecified: params.amountSpecified,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );

        /// @dev delta already includes protocol fee
        /// all tokens go into the vault
        vault.accountPoolBalanceDelta(key, delta, msg.sender);

        unchecked {
            if (state.protocolFee > 0) {
                protocolFeesAccrued[params.zeroForOne ? key.currency0 : key.currency1] += state.protocolFee;
            }
        }

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Swap(
            id,
            msg.sender,
            delta.amount0(),
            delta.amount1(),
            state.sqrtPriceX96,
            state.liquidity,
            state.tick,
            state.swapFee,
            state.protocolFee
        );

        if (key.parameters.shouldCall(HOOKS_AFTER_SWAP_OFFSET)) {
            if (hooks.afterSwap(msg.sender, key, params, delta, hookData) != ICLHooks.afterSwap.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc ICLPoolManager
    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (BalanceDelta delta)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        ICLHooks hooks = ICLHooks(address(key.hooks));
        if (key.parameters.shouldCall(HOOKS_BEFORE_DONATE_OFFSET)) {
            bytes4 selector = hooks.beforeDonate(msg.sender, key, amount0, amount1, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return BalanceDeltaLibrary.MAXIMUM_DELTA;
            } else if (selector != ICLHooks.beforeDonate.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        int24 tick;
        (delta, tick) = pools[id].donate(amount0, amount1);
        vault.accountPoolBalanceDelta(key, delta, msg.sender);

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Donate(id, msg.sender, amount0, amount1, tick);

        if (key.parameters.shouldCall(HOOKS_AFTER_DONATE_OFFSET)) {
            if (hooks.afterDonate(msg.sender, key, amount0, amount1, hookData) != ICLHooks.afterDonate.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc ICLPoolManager
    function setMasterChef(address _masterChef) external override onlyOwner {
        masterChef = _masterChef;
        emit SetMasterChef(_masterChef);
    }

    /// @inheritdoc ICLPoolManager
    function setLmPool(PoolKey memory key, address lmPool) external override {
        if (msg.sender != masterChef && msg.sender != owner()) revert UnauthorizedCaller();

        PoolId id = key.toId();
        pools[id].setLmPool(lmPool);
        emit SetLmPool(id, lmPool);
    }

    /// @inheritdoc IPoolManager
    function setProtocolFee(PoolKey memory key) external {
        (bool success, uint16 newProtocolFee) = _fetchProtocolFee(key);
        if (!success) revert ProtocolFeeControllerCallFailedOrInvalidResult();
        PoolId id = key.toId();
        pools[id].setProtocolFee(newProtocolFee);
        emit ProtocolFeeUpdated(id, newProtocolFee);
    }

    /// @inheritdoc IPoolManager
    function updateDynamicSwapFee(PoolKey memory key) external override {
        if (key.fee.isDynamicFee()) {
            uint24 newDynamicSwapFee = _fetchDynamicSwapFee(key);
            PoolId id = key.toId();
            pools[id].setSwapFee(newDynamicSwapFee);
            emit DynamicSwapFeeUpdated(id, newDynamicSwapFee);
        } else {
            revert FeeNotDynamic();
        }
    }

    function _fetchDynamicSwapFee(PoolKey memory key) internal view returns (uint24 dynamicSwapFee) {
        dynamicSwapFee = ICLDynamicFeeManager(address(key.hooks)).getFee(msg.sender, key);
        if (dynamicSwapFee >= FeeLibrary.ONE_HUNDRED_PERCENT_FEE) revert FeeTooLarge();
    }

    function _checkPoolInitialized(PoolId id) internal view {
        if (pools[id].isNotInitialized()) revert PoolNotInitialized();
    }

    function _validateHookNoOp(PoolKey memory key) internal pure {
        // if no-op is active for hook, there must be a before* hook active too
        if (key.parameters.shouldCall(HOOKS_NO_OP_OFFSET)) {
            if (
                !key.parameters.shouldCall(HOOKS_BEFORE_ADD_LIQUIDITY_OFFSET)
                    && !key.parameters.shouldCall(HOOKS_BEFORE_REMOVE_LIQUIDITY_OFFSET)
                    && !key.parameters.shouldCall(HOOKS_BEFORE_SWAP_OFFSET)
                    && !key.parameters.shouldCall(HOOKS_BEFORE_DONATE_OFFSET)
            ) {
                revert Hooks.NoOpHookMissingBeforeCall();
            }
        }
    }

    /// @notice not accept ether
    // receive() external payable {}
    // fallback() external payable {}
}
