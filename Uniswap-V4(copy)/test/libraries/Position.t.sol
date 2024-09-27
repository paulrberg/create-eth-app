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
import {Position} from "../../src/libraries/Position.sol";
import {SafeCast} from "../../src/libraries/SafeCast.sol";

contract PositionTest is Test {
    using Position for mapping(bytes32 => Position.Info);

    mapping(bytes32 => Position.Info) internal positions;

    function test_fuzz_get(address owner, int24 tickLower, int24 tickUpper, bytes32 salt) public view {
        bytes32 positionKey = keccak256(abi.encodePacked(owner, tickLower, tickUpper, salt));
        Position.Info storage expectedPosition = positions[positionKey];
        Position.Info storage position = positions.get(owner, tickLower, tickUpper, salt);
        bytes32 expectedPositionSlot;
        bytes32 positionSlot;
        assembly ("memory-safe") {
            expectedPositionSlot := expectedPosition.slot
            positionSlot := position.slot
        }
        assertEq(positionSlot, expectedPositionSlot, "slots not equal");
    }

    function test_fuzz_update(
        int128 liquidityDelta,
        Position.Info memory pos,
        uint256 newFeeGrowthInside0X128,
        uint256 newFeeGrowthInside1X128
    ) public {
        Position.Info storage position = positions[0];
        position.liquidity = pos.liquidity;
        position.feeGrowthInside0LastX128 = pos.feeGrowthInside0LastX128;
        position.feeGrowthInside1LastX128 = pos.feeGrowthInside1LastX128;

        uint128 oldLiquidity = position.liquidity;

        if (position.liquidity == 0 && liquidityDelta == 0) {
            vm.expectRevert(Position.CannotUpdateEmptyPosition.selector);
        }

        // new liquidity cannot overflow/underflow uint128
        uint256 absLiquidityDelta;
        if (liquidityDelta > 0) {
            absLiquidityDelta = uint256(uint128(liquidityDelta));
            uint256 newLiquidity = position.liquidity + absLiquidityDelta;
            if (newLiquidity > type(uint128).max) {
                vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            }
        } else if (liquidityDelta < 0) {
            if (liquidityDelta == type(int128).min) {
                absLiquidityDelta = uint256(uint128(type(int128).max)) + 1;
            } else {
                absLiquidityDelta = uint256(uint128(-liquidityDelta));
            }
            if (position.liquidity < absLiquidityDelta) {
                vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            }
        }

        Position.update(position, liquidityDelta, newFeeGrowthInside0X128, newFeeGrowthInside1X128);
        if (liquidityDelta == 0) {
            assertEq(position.liquidity, oldLiquidity);
        } else if (liquidityDelta > 0) {
            assertEq(position.liquidity, oldLiquidity + absLiquidityDelta);
        } else {
            assertEq(position.liquidity, oldLiquidity - absLiquidityDelta);
        }

        assertEq(position.feeGrowthInside0LastX128, newFeeGrowthInside0X128);
        assertEq(position.feeGrowthInside1LastX128, newFeeGrowthInside1X128);
    }
}
