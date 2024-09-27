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
import {Hooks} from "../libraries/Hooks.sol";
import {BinPool} from "./libraries/BinPool.sol";
import {BinPoolParametersHelper} from "./libraries/BinPoolParametersHelper.sol";
import {Currency, CurrencyLibrary} from "../types/Currency.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IBinPoolManager} from "./interfaces/IBinPoolManager.sol";
import {IBinDynamicFeeManager} from "./interfaces/IBinDynamicFeeManager.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../types/BalanceDelta.sol";
import {IVault} from "../interfaces/IVault.sol";
import {BinPosition} from "./libraries/BinPosition.sol";
import {FeeLibrary} from "../libraries/FeeLibrary.sol";
import {PackedUint128Math} from "./libraries/math/PackedUint128Math.sol";
import {Extsload} from "../Extsload.sol";
import "./interfaces/IBinHooks.sol";

/// @notice Holds the state for all bin pools
contract BinPoolManager is IBinPoolManager, Fees, Extsload {
    using PoolIdLibrary for PoolKey;
    using BinPool for *;
    using BinPosition for mapping(bytes32 => BinPosition.Info);
    using BinPoolParametersHelper for bytes32;
    using FeeLibrary for uint24;
    using PackedUint128Math for bytes32;
    using Hooks for bytes32;

    /// @inheritdoc IBinPoolManager
    uint16 public constant override MIN_BIN_STEP = 1;

    /// @inheritdoc IBinPoolManager
    uint16 public override MAX_BIN_STEP = 100;

    mapping(PoolId id => BinPool.State) public pools;

    /// @inheritdoc IBinPoolManager
    address public override masterChef;

    constructor(IVault vault, uint256 controllerGasLimit) Fees(vault, controllerGasLimit) {}

    /// @notice pool manager specified in the pool key must match current contract
    modifier poolManagerMatch(address poolManager) {
        if (address(this) != poolManager) revert PoolManagerMismatch();
        _;
    }

    function _getPool(PoolKey memory key) private view returns (BinPool.State storage) {
        return pools[key.toId()];
    }

    /// @inheritdoc IBinPoolManager
    function getSlot0(PoolId id) external view override returns (uint24 activeId, uint16 protocolFee, uint24 swapFee) {
        BinPool.Slot0 memory slot0 = pools[id].slot0;

        return (slot0.activeId, slot0.protocolFee, slot0.swapFee);
    }

    /// @inheritdoc IBinPoolManager
    function getBin(PoolId id, uint24 binId)
        external
        view
        override
        returns (uint128 binReserveX, uint128 binReserveY)
    {
        (binReserveX, binReserveY) = pools[id].getBin(binId);
    }

    /// @inheritdoc IBinPoolManager
    function getPosition(PoolId id, address owner, uint24 binId)
        external
        view
        override
        returns (BinPosition.Info memory position)
    {
        return pools[id].positions.get(owner, binId);
    }

    /// @inheritdoc IBinPoolManager
    function getNextNonEmptyBin(PoolId id, bool swapForY, uint24 binId)
        external
        view
        override
        returns (uint24 nextId)
    {
        nextId = pools[id].getNextNonEmptyBin(swapForY, binId);
    }

    /// @inheritdoc IBinPoolManager
    function getLmPool(PoolId id) external view override returns (address lmPool) {
        lmPool = pools[id].getLmPool();
    }

    /// @inheritdoc IBinPoolManager
    function initialize(PoolKey memory key, uint24 activeId, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
    {
        /// @dev Accept up to FeeLibrary.TEN_PERCENT_FEE for fee. Add +1 as isStaticFeeTooLarge function checks >=
        if (key.fee.isStaticFeeTooLarge(FeeLibrary.TEN_PERCENT_FEE + 1)) revert FeeTooLarge();

        uint16 binStep = key.parameters.getBinStep();
        if (binStep < MIN_BIN_STEP) revert BinStepTooSmall();
        if (binStep > MAX_BIN_STEP) revert BinStepTooLarge();
        if (key.currency0 >= key.currency1) revert CurrenciesInitializedOutOfOrder();

        IBinHooks hooks = IBinHooks(address(key.hooks));
        Hooks.validateHookConfig(key);
        _validateHookNoOp(key);

        if (key.parameters.shouldCall(HOOKS_BEFORE_INITIALIZE_OFFSET)) {
            if (hooks.beforeInitialize(msg.sender, key, activeId, hookData) != IBinHooks.beforeInitialize.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        PoolId id = key.toId();

        (, uint16 protocolFee) = _fetchProtocolFee(key);
        uint24 swapFee = key.fee.isDynamicFee() ? _fetchDynamicSwapFee(key) : key.fee.getStaticFee();
        pools[id].initialize(activeId, protocolFee, swapFee);

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Initialize(id, key.currency0, key.currency1, key.fee, binStep, hooks);

        if (key.parameters.shouldCall(HOOKS_AFTER_INITIALIZE_OFFSET)) {
            if (hooks.afterInitialize(msg.sender, key, activeId, hookData) != IBinHooks.afterInitialize.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc IBinPoolManager
    function swap(PoolKey memory key, bool swapForY, uint128 amountIn, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (BalanceDelta delta)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        IBinHooks hooks = IBinHooks(address(key.hooks));
        if (key.parameters.shouldCall(HOOKS_BEFORE_SWAP_OFFSET)) {
            bytes4 selector = hooks.beforeSwap(msg.sender, key, swapForY, amountIn, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return BalanceDeltaLibrary.MAXIMUM_DELTA;
            } else if (selector != IBinHooks.beforeSwap.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        /// @dev fix stack too deep
        {
            bytes32 feeForProtocol;
            uint24 activeId;
            uint24 swapFee;
            (delta, feeForProtocol, activeId, swapFee) =
                pools[id].swap(BinPool.SwapParams({swapForY: swapForY, binStep: key.parameters.getBinStep()}), amountIn);

            vault.accountPoolBalanceDelta(key, delta, msg.sender);

            unchecked {
                if (feeForProtocol > 0) {
                    protocolFeesAccrued[key.currency0] += feeForProtocol.decodeX();
                    protocolFeesAccrued[key.currency1] += feeForProtocol.decodeY();
                }
            }

            /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
            emit Swap(id, msg.sender, delta.amount0(), delta.amount1(), activeId, swapFee, feeForProtocol);
        }

        if (key.parameters.shouldCall(HOOKS_AFTER_SWAP_OFFSET)) {
            if (hooks.afterSwap(msg.sender, key, swapForY, amountIn, delta, hookData) != IBinHooks.afterSwap.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc IBinPoolManager
    function getSwapIn(PoolKey memory key, bool swapForY, uint128 amountOut)
        external
        view
        override
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        uint24 totalSwapFee;
        if (key.fee.isDynamicFee()) {
            totalSwapFee = IBinDynamicFeeManager(address(key.hooks)).getFeeForSwapInSwapOut(
                msg.sender, key, swapForY, 0, amountOut
            );
            if (totalSwapFee > FeeLibrary.TEN_PERCENT_FEE) revert FeeTooLarge();
        } else {
            // clear the top 4 bits since they may be flagged
            totalSwapFee = key.fee.getStaticFee();
        }

        (amountIn, amountOutLeft, fee) = pools[id].getSwapIn(
            BinPool.SwapViewParams({swapForY: swapForY, binStep: key.parameters.getBinStep(), fee: totalSwapFee}),
            amountOut
        );
    }

    /// @inheritdoc IBinPoolManager
    function getSwapOut(PoolKey memory key, bool swapForY, uint128 amountIn)
        external
        view
        override
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        uint24 totalSwapFee;
        if (key.fee.isDynamicFee()) {
            totalSwapFee =
                IBinDynamicFeeManager(address(key.hooks)).getFeeForSwapInSwapOut(msg.sender, key, swapForY, amountIn, 0);
            if (totalSwapFee > FeeLibrary.TEN_PERCENT_FEE) revert FeeTooLarge();
        } else {
            totalSwapFee = key.fee.getStaticFee();
        }

        (amountInLeft, amountOut, fee) = pools[id].getSwapOut(
            BinPool.SwapViewParams({swapForY: swapForY, binStep: key.parameters.getBinStep(), fee: totalSwapFee}),
            amountIn
        );
    }

    /// @inheritdoc IBinPoolManager
    function mint(PoolKey memory key, IBinPoolManager.MintParams calldata params, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (BalanceDelta delta, BinPool.MintArrays memory mintArray)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        IBinHooks hooks = IBinHooks(address(key.hooks));
        if (key.parameters.shouldCall(HOOKS_BEFORE_MINT_OFFSET)) {
            bytes4 selector = hooks.beforeMint(msg.sender, key, params, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return (BalanceDeltaLibrary.MAXIMUM_DELTA, mintArray);
            } else if (selector != IBinHooks.beforeMint.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        bytes32 feeForProtocol;
        bytes32 compositionFee;
        (delta, feeForProtocol, mintArray, compositionFee) = pools[id].mint(
            BinPool.MintParams({
                to: msg.sender,
                liquidityConfigs: params.liquidityConfigs,
                amountIn: params.amountIn,
                binStep: key.parameters.getBinStep()
            })
        );

        vault.accountPoolBalanceDelta(key, delta, msg.sender);

        unchecked {
            if (feeForProtocol > 0) {
                protocolFeesAccrued[key.currency0] += feeForProtocol.decodeX();
                protocolFeesAccrued[key.currency1] += feeForProtocol.decodeY();
            }
        }

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Mint(id, msg.sender, mintArray.ids, mintArray.amounts, compositionFee, feeForProtocol);

        if (key.parameters.shouldCall(HOOKS_AFTER_MINT_OFFSET)) {
            if (hooks.afterMint(msg.sender, key, params, delta, hookData) != IBinHooks.afterMint.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    /// @inheritdoc IBinPoolManager
    function burn(PoolKey memory key, IBinPoolManager.BurnParams memory params, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (BalanceDelta delta)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        IBinHooks hooks = IBinHooks(address(key.hooks));
        if (key.parameters.shouldCall(HOOKS_BEFORE_BURN_OFFSET)) {
            bytes4 selector = hooks.beforeBurn(msg.sender, key, params, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return BalanceDeltaLibrary.MAXIMUM_DELTA;
            } else if (selector != IBinHooks.beforeBurn.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        uint256[] memory binIds;
        bytes32[] memory amountRemoved;
        (delta, binIds, amountRemoved) =
            pools[id].burn(BinPool.BurnParams({from: msg.sender, ids: params.ids, amountsToBurn: params.amountsToBurn}));

        vault.accountPoolBalanceDelta(key, delta, msg.sender);

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Burn(id, msg.sender, binIds, amountRemoved);

        if (key.parameters.shouldCall(HOOKS_AFTER_BURN_OFFSET)) {
            if (hooks.afterBurn(msg.sender, key, params, delta, hookData) != IBinHooks.afterBurn.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    function donate(PoolKey memory key, uint128 amount0, uint128 amount1, bytes calldata hookData)
        external
        override
        poolManagerMatch(address(key.poolManager))
        returns (BalanceDelta delta, uint24 binId)
    {
        PoolId id = key.toId();
        _checkPoolInitialized(id);

        IBinHooks hooks = IBinHooks(address(key.hooks));
        if (key.parameters.shouldCall(HOOKS_BEFORE_DONATE_OFFSET)) {
            bytes4 selector = hooks.beforeDonate(msg.sender, key, amount0, amount1, hookData);
            if (key.parameters.isValidNoOpCall(HOOKS_NO_OP_OFFSET, selector)) {
                // Sentinel return value used to signify that a NoOp occurred.
                return (BalanceDeltaLibrary.MAXIMUM_DELTA, binId);
            } else if (selector != IBinHooks.beforeDonate.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }

        (delta, binId) = pools[id].donate(key.parameters.getBinStep(), amount0, amount1);

        vault.accountPoolBalanceDelta(key, delta, msg.sender);

        /// @notice Make sure the first event is noted, so that later events from afterHook won't get mixed up with this one
        emit Donate(id, msg.sender, delta.amount0(), delta.amount1(), binId);

        if (key.parameters.shouldCall(HOOKS_AFTER_DONATE_OFFSET)) {
            if (hooks.afterDonate(msg.sender, key, amount0, amount1, hookData) != IBinHooks.afterDonate.selector) {
                revert Hooks.InvalidHookResponse();
            }
        }
    }

    function setProtocolFee(PoolKey memory key) external override {
        (bool success, uint16 newProtocolFee) = _fetchProtocolFee(key);
        if (!success) revert ProtocolFeeControllerCallFailedOrInvalidResult();
        PoolId id = key.toId();
        pools[id].setProtocolFee(newProtocolFee);
        emit ProtocolFeeUpdated(id, newProtocolFee);
    }

    /// @inheritdoc IBinPoolManager
    function setMaxBinStep(uint16 maxBinStep) external override onlyOwner {
        if (maxBinStep <= MIN_BIN_STEP) revert MaxBinStepTooSmall(maxBinStep);

        MAX_BIN_STEP = maxBinStep;
        emit SetMaxBinStep(maxBinStep);
    }

    /// @inheritdoc IBinPoolManager
    function setMasterChef(address _masterChef) external override onlyOwner {
        masterChef = _masterChef;
        emit SetMasterChef(_masterChef);
    }

    /// @inheritdoc IBinPoolManager
    function setLmPool(PoolKey memory key, address lmPool) external override {
        if (msg.sender != masterChef && msg.sender != owner()) revert UnauthorizedCaller();
        PoolId id = key.toId();
        pools[id].setLmPool(lmPool);
        emit SetLmPool(id, lmPool);
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
        dynamicSwapFee = IBinDynamicFeeManager(address(key.hooks)).getFee(msg.sender, key);
        if (dynamicSwapFee > FeeLibrary.TEN_PERCENT_FEE) revert FeeTooLarge();
    }

    function _checkPoolInitialized(PoolId id) internal view {
        if (pools[id].isNotInitialized()) revert PoolNotInitialized();
    }

    function _validateHookNoOp(PoolKey memory key) internal pure {
        // if no-op is active for hook, there must be a before* hook active too
        if (key.parameters.shouldCall(HOOKS_NO_OP_OFFSET)) {
            if (
                !key.parameters.shouldCall(HOOKS_BEFORE_MINT_OFFSET)
                    && !key.parameters.shouldCall(HOOKS_BEFORE_BURN_OFFSET)
                    && !key.parameters.shouldCall(HOOKS_BEFORE_SWAP_OFFSET)
                    && !key.parameters.shouldCall(HOOKS_BEFORE_DONATE_OFFSET)
            ) {
                revert Hooks.NoOpHookMissingBeforeCall();
            }
        }
    }
}
