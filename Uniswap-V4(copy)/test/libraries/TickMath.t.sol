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

import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {TickMathTest} from "Uniswap-V4/src/test/TickMathTest.sol";
import {TickMath} from "Uniswap-V4/src/libraries/TickMath.sol";
import {JavascriptFfi} from "Uniswap-V4/test/utils/JavascriptFfi.sol";

contract TickMathTestTest is Test, JavascriptFfi, GasSnapshot {
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = -MIN_TICK;

    uint160 constant MIN_SQRT_PRICE = 4295128739;
    uint160 constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;

    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    uint256 constant ONE_PIP = 1e6;

    uint160[] getSqrtPriceAtTickFuzzResults;
    int24[] getTickAtSqrtPriceFuzzResults;

    TickMathTest tickMath;

    function setUp() public {
        tickMath = new TickMathTest();
        delete getSqrtPriceAtTickFuzzResults;
        delete getTickAtSqrtPriceFuzzResults;
    }

    function test_MIN_TICK_equalsNegativeMAX_TICK() public view {
        // this invariant is required in the Tick#tickSpacingToMaxLiquidityPerTick formula
        int24 minTick = tickMath.MIN_TICK();
        assertEq(minTick, tickMath.MAX_TICK() * -1);
        assertEq(minTick, MIN_TICK);
    }

    function test_MAX_TICK_equalsNegativeMIN_TICK() public view {
        // this invariant is required in the Tick#tickSpacingToMaxLiquidityPerTick formula
        // this test is redundant with the above MIN_TICK test
        int24 maxTick = tickMath.MAX_TICK();
        assertEq(maxTick, tickMath.MIN_TICK() * -1);
        assertEq(maxTick, MAX_TICK);
    }

    function test_getSqrtPriceAtTick_throwsForInt24Min() public {
        vm.expectRevert(TickMath.InvalidTick.selector);
        tickMath.getSqrtPriceAtTick(type(int24).min);
    }

    function test_getSqrtPriceAtTick_throwsForTooLow() public {
        vm.expectRevert(TickMath.InvalidTick.selector);
        tickMath.getSqrtPriceAtTick(MIN_TICK - 1);
    }

    function test_getSqrtPriceAtTick_throwsForTooHigh() public {
        vm.expectRevert(TickMath.InvalidTick.selector);
        tickMath.getSqrtPriceAtTick(MAX_TICK + 1);
    }

    function test_fuzz_getSqrtPriceAtTick_throwsForTooLarge(int24 tick) public {
        if (tick > 0) {
            tick = int24(bound(tick, MAX_TICK + 1, type(int24).max));
        } else {
            tick = int24(bound(tick, type(int24).min, MIN_TICK - 1));
        }
        vm.expectRevert(TickMath.InvalidTick.selector);
        tickMath.getSqrtPriceAtTick(tick);
    }

    function test_getSqrtPriceAtTick_isValidMinTick() public view {
        assertEq(tickMath.getSqrtPriceAtTick(MIN_TICK), tickMath.MIN_SQRT_PRICE());
        assertEq(tickMath.getSqrtPriceAtTick(MIN_TICK), 4295128739);
    }

    function test_getSqrtPriceAtTick_isValidMinTickAddOne() public view {
        assertEq(tickMath.getSqrtPriceAtTick(MIN_TICK + 1), 4295343490);
    }

    function test_getSqrtPriceAtTick_isValidMaxTick() public view {
        assertEq(tickMath.getSqrtPriceAtTick(MAX_TICK), tickMath.MAX_SQRT_PRICE());
        assertEq(tickMath.getSqrtPriceAtTick(MAX_TICK), 1461446703485210103287273052203988822378723970342);
    }

    function test_getSqrtPriceAtTick_isValidMaxTickSubOne() public view {
        assertEq(tickMath.getSqrtPriceAtTick(MAX_TICK - 1), 1461373636630004318706518188784493106690254656249);
    }

    function test_getSqrtPriceAtTick_isLessThanJSImplMinTick() public view {
        // sqrt(1 / 2 ** 127) * 2 ** 96
        uint160 jsMinSqrtPrice = 6085630636;
        uint160 solMinSqrtPrice = tickMath.getSqrtPriceAtTick(MIN_TICK);
        assertLt(solMinSqrtPrice, jsMinSqrtPrice);
    }

    function test_getSqrtPriceAtTick_isGreaterThanJSImplMaxTick() public view {
        // sqrt(2 ** 127) * 2 ** 96
        uint160 jsMaxSqrtPrice = 1033437718471923706666374484006904511252097097914;
        uint160 solMaxSqrtPrice = tickMath.getSqrtPriceAtTick(MAX_TICK);
        assertGt(solMaxSqrtPrice, jsMaxSqrtPrice);
    }

    function test_getTickAtSqrtPrice_throwsForTooLow() public {
        vm.expectRevert(TickMath.InvalidSqrtPrice.selector);
        tickMath.getTickAtSqrtPrice(MIN_SQRT_PRICE - 1);
    }

    function test_getTickAtSqrtPrice_throwsForTooHigh() public {
        vm.expectRevert(TickMath.InvalidSqrtPrice.selector);
        tickMath.getTickAtSqrtPrice(MAX_SQRT_PRICE);
    }

    function test_fuzz_getTickAtSqrtPrice_throwsForInvalid(uint160 sqrtPriceX96, bool gte) public {
        if (gte) {
            sqrtPriceX96 = uint160(bound(sqrtPriceX96, MAX_SQRT_PRICE, type(uint160).max));
        } else {
            sqrtPriceX96 = uint160(bound(sqrtPriceX96, 0, MIN_SQRT_PRICE - 1));
        }
        vm.expectRevert(TickMath.InvalidSqrtPrice.selector);
        tickMath.getTickAtSqrtPrice(sqrtPriceX96);
    }

    function test_getTickAtSqrtPrice_isValidMinSqrtPrice() public view {
        assertEq(tickMath.getTickAtSqrtPrice(MIN_SQRT_PRICE), MIN_TICK);
    }

    function test_getTickAtSqrtPrice_isValidMinSqrtPricePlusOne() public view {
        assertEq(tickMath.getTickAtSqrtPrice(4295343490), MIN_TICK + 1);
    }

    function test_getTickAtSqrtPrice_isValidPriceClosestToMaxTick() public view {
        assertEq(tickMath.getTickAtSqrtPrice(MAX_SQRT_PRICE - 1), MAX_TICK - 1);
    }

    function test_getTickAtSqrtPrice_isValidMaxSqrtPriceMinusOne() public view {
        assertEq(tickMath.getTickAtSqrtPrice(1461373636630004318706518188784493106690254656249), MAX_TICK - 1);
    }

    function test_getSqrtPriceAtTick_matchesJavaScriptImplByOneHundrethOfABip() public {
        string memory jsParameters = "";

        int24 tick = 50;

        while (true) {
            if (tick > MAX_TICK) break;
            // test negative and positive tick
            for (uint256 i = 0; i < 2; i++) {
                tick = tick * -1;
                if (tick != -50) jsParameters = string(abi.encodePacked(jsParameters, ",")); // do not leave comma in front of first number
                // add tick to javascript parameters to be calculated inside script
                jsParameters = string(abi.encodePacked(jsParameters, vm.toString(int256(tick))));
                // track solidity result for tick
                getSqrtPriceAtTickFuzzResults.push(tickMath.getSqrtPriceAtTick(tick));
            }
            tick = tick * 2;
        }

        bytes memory jsResult = runScript("forge-test-getSqrtPriceAtTick", jsParameters);
        uint160[] memory jsSqrtPrices = abi.decode(jsResult, (uint160[]));

        for (uint256 i = 0; i < jsSqrtPrices.length; i++) {
            uint160 jsSqrtPrice = jsSqrtPrices[i];
            uint160 solResult = getSqrtPriceAtTickFuzzResults[i];
            (uint160 gtResult, uint160 ltResult) =
                jsSqrtPrice > solResult ? (jsSqrtPrice, solResult) : (solResult, jsSqrtPrice);
            uint160 resultsDiff = gtResult - ltResult;

            // assert solc/js result is at most off by 1/100th of a bip (aka one pip)
            assertEq(resultsDiff * ONE_PIP / jsSqrtPrice, 0);
        }
    }

    function test_getTickAtSqrtPrice_matchesJavascriptImplWithin1() public {
        string memory jsParameters = "";

        uint160 sqrtPrice = MIN_SQRT_PRICE;
        unchecked {
            while (sqrtPrice < sqrtPrice * 16) {
                if (sqrtPrice != MIN_SQRT_PRICE) jsParameters = string(abi.encodePacked(jsParameters, ",")); // do not leave comma in front of first number
                // add tick to javascript parameters to be calculated inside script
                jsParameters = string(abi.encodePacked(jsParameters, vm.toString(sqrtPrice)));
                // track solidity result for sqrtPrice
                getTickAtSqrtPriceFuzzResults.push(tickMath.getTickAtSqrtPrice(sqrtPrice));
                sqrtPrice = sqrtPrice * 16;
            }
        }

        bytes memory jsResult = runScript("forge-test-getTickAtSqrtPrice", jsParameters);
        int24[] memory jsTicks = abi.decode(jsResult, (int24[]));

        for (uint256 i = 0; i < jsTicks.length; i++) {
            int24 jsTick = jsTicks[i];
            int24 solTick = getTickAtSqrtPriceFuzzResults[i];

            (int24 gtResult, int24 ltResult) = jsTick > solTick ? (jsTick, solTick) : (solTick, jsTick);
            int24 resultsDiff = gtResult - ltResult;
            assertLt(resultsDiff, 2);
        }
    }

    /// @notice Benchmark the gas cost of `getSqrtPriceAtTick`
    function test_getSqrtPriceAtTick_gasCost() public {
        snapStart("TickMathGetSqrtPriceAtTick");
        unchecked {
            for (int24 tick = -50; tick < 50;) {
                TickMath.getSqrtPriceAtTick(tick++);
            }
        }
        snapEnd();
    }

    /// @notice Benchmark the gas cost of `getTickAtSqrtPrice`
    function test_getTickAtSqrtPrice_gasCost() public {
        snapStart("TickMathGetTickAtSqrtPrice");
        unchecked {
            uint160 sqrtPriceX96 = 1 << 33;
            for (uint256 i; i++ < 100; sqrtPriceX96 <<= 1) {
                TickMath.getTickAtSqrtPrice(sqrtPriceX96);
            }
        }
        snapEnd();
    }
}
