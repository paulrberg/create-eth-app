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

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {CLPool} from "../../../src/pool-cl/libraries/CLPool.sol";
import {CLPoolManager} from "../../../src/pool-cl/CLPoolManager.sol";
import {CLPosition} from "../../../src/pool-cl/libraries/CLPosition.sol";
import {TickMath} from "../../../src/pool-cl/libraries/TickMath.sol";
import {TickBitmap} from "../../../src/pool-cl/libraries/TickBitmap.sol";
import {Tick} from "../../../src/pool-cl/libraries/Tick.sol";
import {ICLLmPool} from "../../../src/pool-cl/interfaces/ICLLmPool.sol";
import {FixedPoint96} from "../../../src/pool-cl/libraries/FixedPoint96.sol";
import {SafeCast} from "../../../src/libraries/SafeCast.sol";
import {LiquidityAmounts} from "../helpers/LiquidityAmounts.sol";
import {CLLmPool} from "../helpers/CLLmPool.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";
import {FullMath} from "../../../src/pool-cl/libraries/FullMath.sol";
import {FixedPoint128} from "../../../src/pool-cl/libraries/FixedPoint128.sol";

contract PoolTest is Test {
    using CLPool for CLPool.State;

    CLPool.State state;

    function testPoolInitialize(uint160 sqrtPriceX96, uint16 protocolFee, uint24 swapFee) public {
        protocolFee = uint16(bound(protocolFee, 0, 2 ** 16 - 1));
        swapFee = uint24(bound(swapFee, 0, 999999));

        if (sqrtPriceX96 < TickMath.MIN_SQRT_RATIO || sqrtPriceX96 >= TickMath.MAX_SQRT_RATIO) {
            vm.expectRevert(TickMath.InvalidSqrtRatio.selector);
            state.initialize(sqrtPriceX96, protocolFee, swapFee);
        } else {
            state.initialize(sqrtPriceX96, protocolFee, swapFee);
            assertEq(state.slot0.sqrtPriceX96, sqrtPriceX96);
            assertEq(state.slot0.protocolFee, protocolFee);
            assertEq(state.slot0.tick, TickMath.getTickAtSqrtRatio(sqrtPriceX96));
            assertLt(state.slot0.tick, TickMath.MAX_TICK);
            assertGt(state.slot0.tick, TickMath.MIN_TICK - 1);
            assertEq(state.slot0.swapFee, swapFee);
        }
    }

    function testModifyPosition(uint160 sqrtPriceX96, CLPool.ModifyLiquidityParams memory params, uint24 swapFee)
        public
    {
        // Assumptions tested in PoolManager.t.sol
        params.tickSpacing = int24(bound(params.tickSpacing, 1, 32767));
        swapFee = uint24(bound(swapFee, 0, FeeLibrary.ONE_HUNDRED_PERCENT_FEE - 1));

        testPoolInitialize(sqrtPriceX96, 0, swapFee);

        if (params.tickLower >= params.tickUpper) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TicksMisordered.selector, params.tickLower, params.tickUpper));
        } else if (params.tickLower < TickMath.MIN_TICK) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TickLowerOutOfBounds.selector, params.tickLower));
        } else if (params.tickUpper > TickMath.MAX_TICK) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TickUpperOutOfBounds.selector, params.tickUpper));
        } else if (params.liquidityDelta < 0) {
            vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        } else if (params.liquidityDelta == 0) {
            vm.expectRevert(CLPosition.CannotUpdateEmptyPosition.selector);
        } else if (params.liquidityDelta > int128(Tick.tickSpacingToMaxLiquidityPerTick(params.tickSpacing))) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TickLiquidityOverflow.selector, params.tickLower));
        } else if (params.tickLower % params.tickSpacing != 0) {
            vm.expectRevert(
                abi.encodeWithSelector(TickBitmap.TickMisaligned.selector, params.tickLower, params.tickSpacing)
            );
        } else if (params.tickUpper % params.tickSpacing != 0) {
            vm.expectRevert(
                abi.encodeWithSelector(TickBitmap.TickMisaligned.selector, params.tickUpper, params.tickSpacing)
            );
        } else {
            // We need the assumptions above to calculate this
            uint256 maxInt128InTypeU256 = uint256(uint128(type(int128).max));
            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(params.tickLower),
                TickMath.getSqrtRatioAtTick(params.tickUpper),
                uint128(params.liquidityDelta)
            );

            if ((amount0 > maxInt128InTypeU256) || (amount1 > maxInt128InTypeU256)) {
                vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflow.selector));
            }
        }

        params.owner = address(this);
        state.modifyLiquidity(params);
    }

    function testSwap(
        uint160 sqrtPriceX96,
        CLPool.ModifyLiquidityParams memory modifyLiquidityParams,
        CLPool.SwapParams memory swapParams,
        uint24 swapFee,
        ICLLmPool lmPool
    ) public {
        testModifyPosition(sqrtPriceX96, modifyLiquidityParams, swapFee);

        swapParams.tickSpacing = modifyLiquidityParams.tickSpacing;
        CLPool.Slot0 memory slot0 = state.slot0;

        if (address(lmPool) != address(0)) {
            state.lmPool = new CLLmPool();
            /// @dev Calls to mocked addresses may revert if there is no code on the address.
            /// This is because Solidity inserts an extcodesize check before some contract calls.
            /// To circumvent this, use the etch cheatcode if the mocked address has no code.
            vm.mockCall(address(state.lmPool), abi.encodeWithSelector(ICLLmPool.accumulateReward.selector), "");
            vm.mockCall(address(state.lmPool), abi.encodeWithSelector(ICLLmPool.crossLmTick.selector), "");

            vm.warp(1641070800);
            vm.expectCall(
                address(state.lmPool), abi.encodeWithSelector(ICLLmPool.accumulateReward.selector, 1641070800), 1
            );
        }

        if (swapParams.amountSpecified == 0) {
            vm.expectRevert(CLPool.SwapAmountCannotBeZero.selector);
        } else if (swapParams.zeroForOne) {
            if (swapParams.sqrtPriceLimitX96 >= slot0.sqrtPriceX96) {
                vm.expectRevert(
                    abi.encodeWithSelector(
                        CLPool.InvalidSqrtPriceLimit.selector, slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96
                    )
                );
            } else if (swapParams.sqrtPriceLimitX96 <= TickMath.MIN_SQRT_RATIO) {
                vm.expectRevert(
                    abi.encodeWithSelector(
                        CLPool.InvalidSqrtPriceLimit.selector, slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96
                    )
                );
            }
        } else if (!swapParams.zeroForOne) {
            if (swapParams.sqrtPriceLimitX96 <= slot0.sqrtPriceX96) {
                vm.expectRevert(
                    abi.encodeWithSelector(
                        CLPool.InvalidSqrtPriceLimit.selector, slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96
                    )
                );
            } else if (swapParams.sqrtPriceLimitX96 >= TickMath.MAX_SQRT_RATIO) {
                vm.expectRevert(
                    abi.encodeWithSelector(
                        CLPool.InvalidSqrtPriceLimit.selector, slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96
                    )
                );
            }
        }

        state.swap(swapParams);

        if (
            modifyLiquidityParams.liquidityDelta == 0
                || (swapParams.zeroForOne && slot0.tick < modifyLiquidityParams.tickLower)
                || (!swapParams.zeroForOne && slot0.tick >= modifyLiquidityParams.tickUpper)
        ) {
            // no liquidity, hence all the way to the limit
            if (swapParams.zeroForOne) {
                assertEq(state.slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96);
            } else {
                assertEq(state.slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96);
            }
        } else {
            if (swapParams.zeroForOne) {
                assertGe(state.slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96);
            } else {
                assertLe(state.slot0.sqrtPriceX96, swapParams.sqrtPriceLimitX96);
            }
        }
    }

    function testDonate(
        uint160 sqrtPriceX96,
        CLPool.ModifyLiquidityParams memory params,
        uint24 swapFee,
        uint256 amount0,
        uint256 amount1
    ) public {
        testModifyPosition(sqrtPriceX96, params, swapFee);

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        if (!(params.liquidityDelta > 0 && tick >= params.tickLower && tick < params.tickUpper)) {
            vm.expectRevert(CLPool.NoLiquidityToReceiveFees.selector);
        }
        /// @dev due to "delta = toBalanceDelta(amount0.toInt128(), amount1.toInt128());"
        /// amount0 and amount1 must be less than or equal to type(int128).max
        else if (amount0 > uint128(type(int128).max) || amount1 > uint128(type(int128).max)) {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        }

        uint256 feeGrowthGlobal0BeforeDonate = state.feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1BeforeDonate = state.feeGrowthGlobal1X128;
        state.donate(amount0, amount1);
        uint256 feeGrowthGlobal0AfterDonate = state.feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1AftereDonate = state.feeGrowthGlobal1X128;

        if (state.liquidity != 0) {
            assertEq(
                feeGrowthGlobal0AfterDonate - feeGrowthGlobal0BeforeDonate,
                FullMath.mulDiv(amount0, FixedPoint128.Q128, state.liquidity)
            );
            assertEq(
                feeGrowthGlobal1AftereDonate - feeGrowthGlobal1BeforeDonate,
                FullMath.mulDiv(amount1, FixedPoint128.Q128, state.liquidity)
            );
        }
    }
}
