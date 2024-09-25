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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {StdUtils} from "Uniswap-V4/forge-std/StdUtils.sol";

import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {Pool} from "../libraries/Pool.sol";
import {PoolModifyLiquidityTest} from "./PoolModifyLiquidityTest.sol";
import {LiquidityAmounts} from "../../test/utils/LiquidityAmounts.sol";
import {SafeCast} from "../../src/libraries/SafeCast.sol";

contract Fuzzers is StdUtils {
    using SafeCast for uint256;

    Vm internal constant _vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function boundLiquidityDelta(PoolKey memory key, int256 liquidityDeltaUnbounded, int256 liquidityMaxByAmount)
        internal
        pure
        returns (int256)
    {
        int256 liquidityMaxPerTick = int256(uint256(Pool.tickSpacingToMaxLiquidityPerTick(key.tickSpacing)));

        // Finally bound the seeded liquidity by either the max per tick, or by the amount allowed in the position range.
        int256 liquidityMax = liquidityMaxByAmount > liquidityMaxPerTick ? liquidityMaxPerTick : liquidityMaxByAmount;
        return bound(liquidityDeltaUnbounded, 1, liquidityMax);
    }

    // Uses tickSpacingToMaxLiquidityPerTick/2 as one of the possible bounds.
    // Potentially adjust this value to be more strict for positions that touch the same tick.
    function boundLiquidityDeltaTightly(PoolKey memory key, int256 liquidityDeltaUnbounded, int256 liquidityMaxByAmount)
        internal
        pure
        returns (int256)
    {
        // Divide by half to bound liquidity more. TODO: Probably a better way to do this.
        int256 liquidityMaxTightBound = int256(uint256(Pool.tickSpacingToMaxLiquidityPerTick(key.tickSpacing)) / 2);

        // Finally bound the seeded liquidity by either the max per tick, or by the amount allowed in the position range.
        int256 liquidityMax =
            liquidityMaxByAmount > liquidityMaxTightBound ? liquidityMaxTightBound : liquidityMaxByAmount;
        return bound(liquidityDeltaUnbounded, 1, liquidityMax);
    }

    function getLiquidityDeltaFromAmounts(int24 tickLower, int24 tickUpper, uint160 sqrtPriceX96)
        internal
        pure
        returns (int256)
    {
        // First get the maximum amount0 and maximum amount1 that can be deposited at this range.
        (uint256 maxAmount0, uint256 maxAmount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            uint128(type(int128).max)
        );

        // Compare the max amounts (defined by the range of the position) to the max amount constrained by the type container.
        // The true maximum should be the minimum of the two.
        // (ie If the position range allows a deposit of more then int128.max in any token, then here we cap it at int128.max.)

        uint256 amount0 = uint256(type(uint128).max / 2);
        uint256 amount1 = uint256(type(uint128).max / 2);

        maxAmount0 = maxAmount0 > amount0 ? amount0 : maxAmount0;
        maxAmount1 = maxAmount1 > amount1 ? amount1 : maxAmount1;

        int256 liquidityMaxByAmount = uint256(
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtPriceAtTick(tickLower),
                TickMath.getSqrtPriceAtTick(tickUpper),
                maxAmount0,
                maxAmount1
            )
        ).toInt256();

        return liquidityMaxByAmount;
    }

    function boundTicks(int24 tickLower, int24 tickUpper, int24 tickSpacing) internal pure returns (int24, int24) {
        tickLower = int24(
            bound(
                int256(tickLower),
                int256(TickMath.minUsableTick(tickSpacing)),
                int256(TickMath.maxUsableTick(tickSpacing))
            )
        );
        tickUpper = int24(
            bound(
                int256(tickUpper),
                int256(TickMath.minUsableTick(tickSpacing)),
                int256(TickMath.maxUsableTick(tickSpacing))
            )
        );

        // round down ticks
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = (tickUpper / tickSpacing) * tickSpacing;

        (tickLower, tickUpper) = tickLower < tickUpper ? (tickLower, tickUpper) : (tickUpper, tickLower);

        _vm.assume(tickLower != tickUpper);

        return (tickLower, tickUpper);
    }

    function boundTicks(PoolKey memory key, int24 tickLower, int24 tickUpper) internal pure returns (int24, int24) {
        return boundTicks(tickLower, tickUpper, key.tickSpacing);
    }

    function createRandomSqrtPriceX96(PoolKey memory key, int256 seed) internal pure returns (uint160) {
        int24 tickSpacing = key.tickSpacing;
        int256 min = int256(TickMath.minUsableTick(tickSpacing));
        int256 max = int256(TickMath.maxUsableTick(tickSpacing));
        int256 randomTick = bound(seed, min, max);
        return TickMath.getSqrtPriceAtTick(int24(randomTick));
    }

    /// @dev Obtain fuzzed and bounded parameters for creating liquidity
    /// @param key The pool key
    /// @param params IPoolManager.ModifyLiquidityParams Note that these parameters are unbounded
    /// @param sqrtPriceX96 The current sqrt price
    function createFuzzyLiquidityParams(
        PoolKey memory key,
        IPoolManager.ModifyLiquidityParams memory params,
        uint160 sqrtPriceX96
    ) internal pure returns (IPoolManager.ModifyLiquidityParams memory result) {
        (result.tickLower, result.tickUpper) = boundTicks(key, params.tickLower, params.tickUpper);
        int256 liquidityDeltaFromAmounts =
            getLiquidityDeltaFromAmounts(result.tickLower, result.tickUpper, sqrtPriceX96);
        result.liquidityDelta = boundLiquidityDelta(key, params.liquidityDelta, liquidityDeltaFromAmounts);
    }

    // Creates liquidity parameters with a stricter bound. Should be used if multiple positions being intitialized on the pool, with potential for tick overlap.
    function createFuzzyLiquidityParamsWithTightBound(
        PoolKey memory key,
        IPoolManager.ModifyLiquidityParams memory params,
        uint160 sqrtPriceX96
    ) internal pure returns (IPoolManager.ModifyLiquidityParams memory result) {
        (result.tickLower, result.tickUpper) = boundTicks(key, params.tickLower, params.tickUpper);
        int256 liquidityDeltaFromAmounts =
            getLiquidityDeltaFromAmounts(result.tickLower, result.tickUpper, sqrtPriceX96);

        result.liquidityDelta = boundLiquidityDeltaTightly(key, params.liquidityDelta, liquidityDeltaFromAmounts);
    }

    function createFuzzyLiquidity(
        PoolModifyLiquidityTest modifyLiquidityRouter,
        PoolKey memory key,
        IPoolManager.ModifyLiquidityParams memory params,
        uint160 sqrtPriceX96,
        bytes memory hookData
    ) internal returns (IPoolManager.ModifyLiquidityParams memory result, BalanceDelta delta) {
        result = createFuzzyLiquidityParams(key, params, sqrtPriceX96);
        delta = modifyLiquidityRouter.modifyLiquidity(key, result, hookData);
    }

    // There exists possible positions in the pool, so we tighten the boundaries of liquidity.
    function createFuzzyLiquidityWithTightBound(
        PoolModifyLiquidityTest modifyLiquidityRouter,
        PoolKey memory key,
        IPoolManager.ModifyLiquidityParams memory params,
        uint160 sqrtPriceX96,
        bytes memory hookData
    ) internal returns (IPoolManager.ModifyLiquidityParams memory result, BalanceDelta delta) {
        result = createFuzzyLiquidityParamsWithTightBound(key, params, sqrtPriceX96);
        delta = modifyLiquidityRouter.modifyLiquidity(key, result, hookData);
    }
}
