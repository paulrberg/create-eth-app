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
import {stdError} from "Uniswap-V4/forge-std/StdError.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Constants} from "../helpers/Constants.sol";
import {CLPool} from "../../../src/pool-cl/libraries/CLPool.sol";
import {TickMath} from "../../../src/pool-cl/libraries/TickMath.sol";
import {Tick} from "../../../src/pool-cl/libraries/Tick.sol";

contract TickTest is Test, GasSnapshot {
    // using CLPool for CLPool.State;
    using Tick for mapping(int24 => Tick.Info);

    int24 constant LOW_TICK_SPACING = 10;
    int24 constant MEDIUM_TICK_SPACING = 60;
    int24 constant HIGH_TICK_SPACING = 200;

    CLPool.State public pool;

    function ticks(int24 tick) internal view returns (Tick.Info memory) {
        return pool.ticks[tick];
    }

    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
        return Tick.tickSpacingToMaxLiquidityPerTick(tickSpacing);
    }

    function setTick(int24 tick, Tick.Info memory info) internal {
        pool.ticks[tick] = info;
    }

    function getFeeGrowthInside(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        pool.slot0.tick = tickCurrent;
        pool.feeGrowthGlobal0X128 = feeGrowthGlobal0X128;
        pool.feeGrowthGlobal1X128 = feeGrowthGlobal1X128;
        return pool.ticks.getFeeGrowthInside(
            tickLower, tickUpper, pool.slot0.tick, pool.feeGrowthGlobal0X128, pool.feeGrowthGlobal1X128
        );
    }

    function update(
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper
    ) internal returns (bool flipped, uint128 liquidityGrossAfter) {
        pool.slot0.tick = tickCurrent;
        pool.feeGrowthGlobal0X128 = feeGrowthGlobal0X128;
        pool.feeGrowthGlobal1X128 = feeGrowthGlobal1X128;
        flipped = pool.ticks.update(
            tick,
            tickCurrent,
            liquidityDelta,
            feeGrowthGlobal0X128,
            feeGrowthGlobal1X128,
            upper,
            tickSpacingToMaxLiquidityPerTick(LOW_TICK_SPACING)
        );

        liquidityGrossAfter = pool.ticks[tick].liquidityGross;
    }

    function update(
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper,
        uint128 maxLiquidityPerTick
    ) internal returns (bool flipped, uint128 liquidityGrossAfter) {
        pool.slot0.tick = tickCurrent;
        pool.feeGrowthGlobal0X128 = feeGrowthGlobal0X128;
        pool.feeGrowthGlobal1X128 = feeGrowthGlobal1X128;
        flipped = pool.ticks.update(
            tick, tickCurrent, liquidityDelta, feeGrowthGlobal0X128, feeGrowthGlobal1X128, upper, maxLiquidityPerTick
        );

        liquidityGrossAfter = pool.ticks[tick].liquidityGross;
    }

    function clear(int24 tick) internal {
        pool.ticks.clear(tick);
    }

    function cross(int24 tick, uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128)
        internal
        returns (int128 liquidityNet)
    {
        return pool.ticks.cross(tick, feeGrowthGlobal0X128, feeGrowthGlobal1X128);
    }

    function getMinTick(int24 tickSpacing) internal pure returns (int256) {
        return (Constants.MIN_TICK / tickSpacing) * tickSpacing;
    }

    function getMaxTick(int24 tickSpacing) internal pure returns (int256) {
        return (Constants.MAX_TICK / tickSpacing) * tickSpacing;
    }

    function checkCantOverflow(int24 tickSpacing, uint128 maxLiquidityPerTick) internal {
        assertLe(
            uint256(
                uint256(maxLiquidityPerTick)
                    * uint256((getMaxTick(tickSpacing) - getMinTick(tickSpacing)) / tickSpacing + 1)
            ),
            uint256(Constants.MAX_UINT128)
        );
    }

    function testTickFuzz_checkTicks(int24 tickLower, int24 tickUpper) public {
        if (tickLower >= tickUpper) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TicksMisordered.selector, tickLower, tickUpper));
        } else if (tickLower < TickMath.MIN_TICK) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TickLowerOutOfBounds.selector, tickLower));
        } else if (tickUpper > TickMath.MAX_TICK) {
            vm.expectRevert(abi.encodeWithSelector(Tick.TickUpperOutOfBounds.selector, tickUpper));
        }

        Tick.checkTicks(tickLower, tickUpper);
    }

    function testTick_checkTicks_gasCost() public {
        snapStart("TickTest#checkTicks");
        Tick.checkTicks(TickMath.MIN_TICK, TickMath.MAX_TICK);
        snapEnd();
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_returnsTheCorrectValueForLowFee() public {
        uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(LOW_TICK_SPACING);

        assertEq(maxLiquidityPerTick, 1917569901783203986719870431555990);
        checkCantOverflow(LOW_TICK_SPACING, maxLiquidityPerTick);
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_returnsTheCorrectValueForMediumFee() public {
        uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(MEDIUM_TICK_SPACING);

        assertEq(maxLiquidityPerTick, 11505743598341114571880798222544994); // 113.1 bits
        checkCantOverflow(MEDIUM_TICK_SPACING, maxLiquidityPerTick);
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_returnsTheCorrectValueForHighFee() public {
        uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(HIGH_TICK_SPACING);

        assertEq(maxLiquidityPerTick, 38350317471085141830651933667504588); // 114.7 bits
        checkCantOverflow(HIGH_TICK_SPACING, maxLiquidityPerTick);
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_returnsTheCorrectValueFor1() public {
        uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(1);

        assertEq(maxLiquidityPerTick, 191757530477355301479181766273477); // 126 bits
        checkCantOverflow(1, maxLiquidityPerTick);
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_returnsTheCorrectValueForEntireRange() public {
        uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(887272);

        assertEq(maxLiquidityPerTick, Constants.MAX_UINT128 / 3); // 126 bits
        checkCantOverflow(887272, maxLiquidityPerTick);
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_returnsTheCorrectValueFor2302() public {
        uint128 maxLiquidityPerTick = tickSpacingToMaxLiquidityPerTick(2302);

        assertEq(maxLiquidityPerTick, 441351967472034323558203122479595605); // 118 bits
        checkCantOverflow(2302, maxLiquidityPerTick);
    }

    function testTick_tickSpacingToMaxLiquidityPerTick_gasCost10TickSpacing() public {
        snapStart("TickTest#tickSpacingToMaxLiquidityPerTick");
        Tick.tickSpacingToMaxLiquidityPerTick(10);
        snapEnd();
    }

    function testTick_getFeeGrowthInside_gasCost() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 2;
        info.feeGrowthOutside1X128 = 3;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(2, info);

        snapStart("TickTest#getFeeGrowthInside");
        getFeeGrowthInside(-2, 2, 0, 15, 15);
        snapEnd();
    }

    function testTick_getFeeGrowthInside_returnsAllForTwoUninitializedTicksIfTickIsInside() public {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, 0, 15, 15);

        assertEq(feeGrowthInside0X128, 15);
        assertEq(feeGrowthInside1X128, 15);
    }

    function testTick_getFeeGrowthInside_returns0ForTwoUninitializedTicksIfTickIsAbove() public {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, 4, 15, 15);

        assertEq(feeGrowthInside0X128, 0);
        assertEq(feeGrowthInside1X128, 0);
    }

    function testTick_getFeeGrowthInside_returns0ForTwoUninitializedTicksIfTickIsBelow() public {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, -4, 15, 15);

        assertEq(feeGrowthInside0X128, 0);
        assertEq(feeGrowthInside1X128, 0);
    }

    function testTick_getFeeGrowthInside_subtractsUpperTickIfBelow() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 2;
        info.feeGrowthOutside1X128 = 3;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(2, info);

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, 0, 15, 15);

        assertEq(feeGrowthInside0X128, 13);
        assertEq(feeGrowthInside1X128, 12);
    }

    function testTick_getFeeGrowthInside_subtractsLowerTickIfAbove() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 2;
        info.feeGrowthOutside1X128 = 3;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(-2, info);

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, 0, 15, 15);

        assertEq(feeGrowthInside0X128, 13);
        assertEq(feeGrowthInside1X128, 12);
    }

    function testTick_getFeeGrowthInside_subtractsUpperAndLowerTickIfInside() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 2;
        info.feeGrowthOutside1X128 = 3;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(-2, info);

        info.feeGrowthOutside0X128 = 4;
        info.feeGrowthOutside1X128 = 1;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(2, info);

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, 0, 15, 15);

        assertEq(feeGrowthInside0X128, 9);
        assertEq(feeGrowthInside1X128, 11);
    }

    function testTick_getFeeGrowthInside_worksCorrectlyWithOverflowOnInsideTick() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = Constants.MAX_UINT256 - 3;
        info.feeGrowthOutside1X128 = Constants.MAX_UINT256 - 2;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(-2, info);

        info.feeGrowthOutside0X128 = 3;
        info.feeGrowthOutside1X128 = 5;
        info.liquidityGross = 0;
        info.liquidityNet = 0;

        setTick(2, info);

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(-2, 2, 0, 15, 15);

        assertEq(feeGrowthInside0X128, 16);
        assertEq(feeGrowthInside1X128, 13);
    }

    function testTick_update_gasCost() public {
        snapStart("TickTest#update");
        update(1, 1, 1, 6, 7, false);
        snapEnd();
    }

    function testTick_update_flipsFromZeroToNonzero() public {
        (bool flipped, uint128 liquidityGrossAfter) = update(0, 0, 1, 0, 0, false);

        assertEq(flipped, true);
        assertEq(liquidityGrossAfter, 1);
    }

    function testTick_update_doesNotFlipFromNonzeroToGreaterNonzero() public {
        update(0, 0, 1, 0, 0, false);
        (bool flipped, uint128 liquidityGrossAfter) = update(0, 0, 1, 0, 0, false);

        assertEq(flipped, false);
        assertEq(liquidityGrossAfter, 2);
    }

    function testTick_update_flipsFromNonzeroToZero() public {
        update(0, 0, 1, 0, 0, false);
        (bool flipped, uint128 liquidityGrossAfter) = update(0, 0, -1, 0, 0, false);

        assertEq(flipped, true);
        assertEq(liquidityGrossAfter, 0);
    }

    function testTick_update_doesNotFlipFromNonzeroToLesserZero() public {
        update(0, 0, 2, 0, 0, false);
        (bool flipped, uint128 liquidityGrossAfter) = update(0, 0, -1, 0, 0, false);

        assertEq(flipped, false);
        assertEq(liquidityGrossAfter, 1);
    }

    function testTick_update_netsTheLiquidityBasedOnUpperFlag() public {
        Tick.Info memory tickInfo;

        update(0, 0, 2, 0, 0, false);
        update(0, 0, 1, 0, 0, true);
        update(0, 0, 3, 0, 0, true);
        update(0, 0, 1, 0, 0, false);
        tickInfo = ticks(0);

        assertEq(tickInfo.liquidityGross, 2 + 1 + 3 + 1);
        assertEq(tickInfo.liquidityNet, 2 - 1 - 3 + 1);
    }

    function testTick_update_revertsOnOverflowLiquidityNet() public {
        update(0, 0, int128(Constants.MAX_UINT128 / 2 - 1), 0, 0, false, Constants.MAX_UINT128);

        vm.expectRevert(stdError.arithmeticError);
        update(0, 0, int128(Constants.MAX_UINT128 / 2 - 1), 0, 0, false, Constants.MAX_UINT128);
    }

    function testTick_update_revertsOnTickLiquidityOverflow() public {
        vm.expectRevert(abi.encodeWithSelector(Tick.TickLiquidityOverflow.selector, 0));
        update(0, 0, int128(Constants.MAX_UINT128 / 2 - 1), 0, 0, false);
    }

    function testTick_update_revertsOnTickLiquidityOverflow2() public {
        vm.expectRevert(abi.encodeWithSelector(Tick.TickLiquidityOverflow.selector, 0));
        update(0, 0, int128(tickSpacingToMaxLiquidityPerTick(LOW_TICK_SPACING) + 1), 0, 0, false);
    }

    function testTick_update_assumesAllGrowthHappensBelowTicksLteCurrentTick() public {
        Tick.Info memory tickInfo;

        update(1, 1, 1, 1, 2, false);
        tickInfo = ticks(1);

        assertEq(tickInfo.feeGrowthOutside0X128, 1);
        assertEq(tickInfo.feeGrowthOutside1X128, 2);
    }

    function testTick_update_doesNotSetAnyGrowthFieldsIfTickIsAlreadyInitialized() public {
        Tick.Info memory tickInfo;

        update(1, 1, 1, 1, 2, false);
        update(1, 1, 1, 6, 7, false);
        tickInfo = ticks(1);

        assertEq(tickInfo.feeGrowthOutside0X128, 1);
        assertEq(tickInfo.feeGrowthOutside1X128, 2);
    }

    function testTick_update_doesNotSetAnyGrowthFieldsForTicksGtCurrentTick() public {
        Tick.Info memory tickInfo;

        update(2, 1, 1, 1, 2, false);
        tickInfo = ticks(2);

        assertEq(tickInfo.feeGrowthOutside0X128, 0);
        assertEq(tickInfo.feeGrowthOutside1X128, 0);
    }

    function testTick_update_liquidityParsing_parsesMaxUint128StoredLiquidityGrossBeforeUpdate() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 0;
        info.feeGrowthOutside1X128 = 0;
        info.liquidityGross = Constants.MAX_UINT128;
        info.liquidityNet = 0;

        setTick(2, info);
        update(2, 1, -1, 1, 2, false, Constants.MAX_UINT128);

        info = ticks(2);

        assertEq(info.liquidityGross, Constants.MAX_UINT128 - 1);
        assertEq(info.liquidityNet, -1);
    }

    function testTick_update_liquidityParsing_parsesMaxUint128StoredLiquidityGrossAfterUpdate() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 0;
        info.feeGrowthOutside1X128 = 0;
        info.liquidityGross = (Constants.MAX_UINT128 / 2) + 1;
        info.liquidityNet = 0;

        setTick(2, info);

        update(2, 1, int128(Constants.MAX_UINT128 / 2), 1, 2, false, Constants.MAX_UINT128);

        info = ticks(2);

        assertEq(info.liquidityGross, Constants.MAX_UINT128);
        assertEq(info.liquidityNet, int128(Constants.MAX_UINT128 / 2));
    }

    function testTick_update_liquidityParsing_parsesMaxInt128StoredLiquidityGrossBeforeUpdate() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 0;
        info.feeGrowthOutside1X128 = 0;
        info.liquidityGross = 1;
        info.liquidityNet = int128(Constants.MAX_UINT128 / 2);

        setTick(2, info);
        update(2, 1, -1, 1, 2, false);

        info = ticks(2);

        assertEq(info.liquidityGross, 0);
        assertEq(info.liquidityNet, int128(Constants.MAX_UINT128 / 2 - 1));
    }

    function testTick_update_liquidityParsing_parsesMaxInt128StoredLiquidityGrossAfterUpdate() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 0;
        info.feeGrowthOutside1X128 = 0;
        info.liquidityGross = 0;
        info.liquidityNet = int128(Constants.MAX_UINT128 / 2 - 1);

        setTick(2, info);

        update(2, 1, 1, 1, 2, false);

        info = ticks(2);

        assertEq(info.liquidityGross, 1);
        assertEq(info.liquidityNet, int128(Constants.MAX_UINT128 / 2));
    }

    function testTick_clear_deletesAllTheDataInTheTick() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 1;
        info.feeGrowthOutside1X128 = 2;
        info.liquidityGross = 3;
        info.liquidityNet = 4;

        setTick(2, info);

        clear(2);

        info = ticks(2);

        assertEq(info.feeGrowthOutside0X128, 0);
        assertEq(info.feeGrowthOutside1X128, 0);
        assertEq(info.liquidityGross, 0);
        assertEq(info.liquidityNet, 0);
    }

    function testTick_cross_flipsTheGrowthVariables() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 1;
        info.feeGrowthOutside1X128 = 2;
        info.liquidityGross = 3;
        info.liquidityNet = 4;

        setTick(2, info);

        cross(2, 7, 9);

        info = ticks(2);

        assertEq(info.feeGrowthOutside0X128, 6);
        assertEq(info.feeGrowthOutside1X128, 7);
    }

    function testTick_cross_twoFlipsAreNoOp() public {
        Tick.Info memory info;

        info.feeGrowthOutside0X128 = 1;
        info.feeGrowthOutside1X128 = 2;
        info.liquidityGross = 3;
        info.liquidityNet = 4;

        setTick(2, info);

        cross(2, 7, 9);
        cross(2, 7, 9);

        info = ticks(2);

        assertEq(info.feeGrowthOutside0X128, 1);
        assertEq(info.feeGrowthOutside1X128, 2);
    }

    function testTick_tickSpacingToParametersInvariants_fuzz(int24 tickSpacing) public {
        tickSpacing = int24(bound(tickSpacing, 1, TickMath.MAX_TICK));

        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;

        uint128 maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(tickSpacing);

        // symmetry around 0 tick
        assertEq(maxTick, -minTick);
        // positive max tick
        assertGt(maxTick, 0);
        // divisibility
        assertEq((maxTick - minTick) % tickSpacing, 0);

        uint256 numTicks = uint256(int256((maxTick - minTick) / tickSpacing)) + 1;
        // max liquidity at every tick is less than the cap
        assertGe(type(uint128).max, uint256(maxLiquidityPerTick) * numTicks);
    }
}
