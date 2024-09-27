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

import {Hooks} from "../libraries/Hooks.sol";
import {SafeCast} from "../libraries/SafeCast.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta, toBalanceDelta} from "../types/BalanceDelta.sol";
import {Currency} from "../types/Currency.sol";
import {BaseTestHooks} from "./BaseTestHooks.sol";

contract FeeTakingHook is BaseTestHooks {
    using Hooks for IHooks;
    using SafeCast for uint256;
    using SafeCast for int128;

    IPoolManager immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(manager));
        _;
    }

    uint128 public constant LIQUIDITY_FEE = 543; // 543/10000 = 5.43%
    uint128 public constant SWAP_FEE_BIPS = 123; // 123/10000 = 1.23%
    uint128 public constant TOTAL_BIPS = 10000;

    function afterSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, int128) {
        // fee will be in the unspecified token of the swap
        bool specifiedTokenIs0 = (params.amountSpecified < 0 == params.zeroForOne);
        (Currency feeCurrency, int128 swapAmount) =
            (specifiedTokenIs0) ? (key.currency1, delta.amount1()) : (key.currency0, delta.amount0());
        // if fee is on output, get the absolute output amount
        if (swapAmount < 0) swapAmount = -swapAmount;

        uint256 feeAmount = uint128(swapAmount) * SWAP_FEE_BIPS / TOTAL_BIPS;
        manager.take(feeCurrency, address(this), feeAmount);

        return (IHooks.afterSwap.selector, feeAmount.toInt128());
    }

    function afterRemoveLiquidity(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        BalanceDelta delta,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, BalanceDelta) {
        assert(delta.amount0() >= 0 && delta.amount1() >= 0);

        uint128 feeAmount0 = uint128(delta.amount0()) * LIQUIDITY_FEE / TOTAL_BIPS;
        uint128 feeAmount1 = uint128(delta.amount1()) * LIQUIDITY_FEE / TOTAL_BIPS;

        manager.take(key.currency0, address(this), feeAmount0);
        manager.take(key.currency1, address(this), feeAmount1);

        return (IHooks.afterRemoveLiquidity.selector, toBalanceDelta(int128(feeAmount0), int128(feeAmount1)));
    }

    function afterAddLiquidity(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        BalanceDelta delta,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, BalanceDelta) {
        assert(delta.amount0() <= 0 && delta.amount1() <= 0);

        uint128 feeAmount0 = uint128(-delta.amount0()) * LIQUIDITY_FEE / TOTAL_BIPS;
        uint128 feeAmount1 = uint128(-delta.amount1()) * LIQUIDITY_FEE / TOTAL_BIPS;

        manager.take(key.currency0, address(this), feeAmount0);
        manager.take(key.currency1, address(this), feeAmount1);

        return (IHooks.afterAddLiquidity.selector, toBalanceDelta(int128(feeAmount0), int128(feeAmount1)));
    }
}
