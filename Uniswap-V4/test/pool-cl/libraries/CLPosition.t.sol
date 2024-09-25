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

import {stdError} from "Uniswap-V4/forge-std/StdError.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {CLPosition} from "../../../src/pool-cl/libraries/CLPosition.sol";
import {CLPool} from "../../../src/pool-cl/libraries/CLPool.sol";
import {FixedPoint128} from "../../../src/pool-cl/libraries/FixedPoint128.sol";

contract CLPositionTest is Test, GasSnapshot {
    using CLPosition for mapping(bytes32 => CLPosition.Info);
    using CLPosition for CLPosition.Info;

    CLPool.State public pool;

    function test_get_emptyPosition() public {
        CLPosition.Info memory info = pool.positions.get(address(this), 1, 2);
        assertEq(info.liquidity, 0);
        assertEq(info.feeGrowthInside0LastX128, 0);
        assertEq(info.feeGrowthInside1LastX128, 0);
    }

    function test_set_updateEmptyPositionFuzz(
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) public {
        CLPosition.Info storage info = pool.positions.get(address(this), 1, 2);

        if (liquidityDelta == 0) {
            vm.expectRevert(CLPosition.CannotUpdateEmptyPosition.selector);
        } else if (liquidityDelta < 0) {
            vm.expectRevert(stdError.arithmeticError);
        }
        (uint256 feesOwed0, uint256 feesOwed1) = info.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        assertEq(feesOwed0, 0);
        assertEq(feesOwed1, 0);
        assertEq(info.liquidity, uint128(liquidityDelta));
        assertEq(info.feeGrowthInside0LastX128, feeGrowthInside0X128);
        assertEq(info.feeGrowthInside1LastX128, feeGrowthInside1X128);
    }

    function test_set_updateNonEmptyPosition() public {
        CLPosition.Info storage info = pool.positions.get(address(this), 1, 2);

        // init
        {
            (uint256 feesOwed0, uint256 feesOwed1) = info.update(3, 5 * FixedPoint128.Q128, 6 * FixedPoint128.Q128);
            assertEq(feesOwed0, 0);
            assertEq(feesOwed1, 0);
        }

        // add
        {
            snapStart("CLPositionTest#Position_update_add");
            (uint256 feesOwed0, uint256 feesOwed1) = info.update(0, 10 * FixedPoint128.Q128, 12 * FixedPoint128.Q128);
            snapEnd();
            assertEq(feesOwed0, (10 - 5) * 3);
            assertEq(feesOwed1, (12 - 6) * 3);

            assertEq(info.liquidity, 3);
            assertEq(info.feeGrowthInside0LastX128, 10 * FixedPoint128.Q128);
            assertEq(info.feeGrowthInside1LastX128, 12 * FixedPoint128.Q128);
        }

        // remove
        {
            (uint256 feesOwed0, uint256 feesOwed1) = info.update(-1, 10 * FixedPoint128.Q128, 12 * FixedPoint128.Q128);
            assertEq(feesOwed0, 0);
            assertEq(feesOwed1, 0);

            assertEq(info.liquidity, 2);
            assertEq(info.feeGrowthInside0LastX128, 10 * FixedPoint128.Q128);
            assertEq(info.feeGrowthInside1LastX128, 12 * FixedPoint128.Q128);
        }

        // remove all
        {
            snapStart("CLPositionTest#Position_update_remove");
            (uint256 feesOwed0, uint256 feesOwed1) = info.update(-2, 20 * FixedPoint128.Q128, 15 * FixedPoint128.Q128);
            snapEnd();
            assertEq(feesOwed0, (20 - 10) * 2);
            assertEq(feesOwed1, (15 - 12) * 2);

            assertEq(info.liquidity, 0);
            assertEq(info.feeGrowthInside0LastX128, 20 * FixedPoint128.Q128);
            assertEq(info.feeGrowthInside1LastX128, 15 * FixedPoint128.Q128);
        }
    }
}
