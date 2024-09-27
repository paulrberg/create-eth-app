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
import {TickMathTestHelper} from "../helpers/TickMathTestHelper.sol";
import {TickMath} from "../../../src/pool-cl/libraries/TickMath.sol";

contract TickMathTestTest is Test {
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = -MIN_TICK;

    uint160 constant MIN_SQRT_RATIO = 4295128739;
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    uint160 constant SQRT_RATIO_1_1 = 79228162514264337593543950336;

    uint256 constant ONE_PIP = 1e6;

    uint160[] getSqrtRatioAtTickFuzzResults;
    int24[] getTickAtSqrtRatioFuzzResults;

    TickMathTestHelper tickMath;

    function setUp() public {
        tickMath = new TickMathTestHelper();
        delete getSqrtRatioAtTickFuzzResults;
        delete getTickAtSqrtRatioFuzzResults;
    }

    function test_MIN_TICK_equalsNegativeMAX_TICK() public {
        // this invariant is required in the Tick#tickSpacingToMaxLiquidityPerTick formula
        int24 minTick = tickMath.MIN_TICK();
        assertEq(minTick, tickMath.MAX_TICK() * -1);
        assertEq(minTick, MIN_TICK);
    }

    function test_MAX_TICK_equalsNegativeMIN_TICK() public {
        // this invariant is required in the Tick#tickSpacingToMaxLiquidityPerTick formula
        // this test is redundant with the above MIN_TICK test
        int24 maxTick = tickMath.MAX_TICK();
        assertEq(maxTick, tickMath.MIN_TICK() * -1);
        assertEq(maxTick, MAX_TICK);
    }

    function test_getSqrtRatioAtTick_throwsForTooLow() public {
        vm.expectRevert(TickMath.InvalidTick.selector);
        tickMath.getSqrtRatioAtTick(MIN_TICK - 1);
    }

    function test_getSqrtRatioAtTick_throwsForTooHigh() public {
        vm.expectRevert(TickMath.InvalidTick.selector);
        tickMath.getSqrtRatioAtTick(MAX_TICK + 1);
    }

    function test_getSqrtRatioAtTick_isValidMinTick() public {
        assertEq(tickMath.getSqrtRatioAtTick(MIN_TICK), tickMath.MIN_SQRT_RATIO());
        assertEq(tickMath.getSqrtRatioAtTick(MIN_TICK), 4295128739);
    }

    function test_getSqrtRatioAtTick_isValidMinTickAddOne() public {
        assertEq(tickMath.getSqrtRatioAtTick(MIN_TICK + 1), 4295343490);
    }

    function test_getSqrtRatioAtTick_isValidMaxTick() public {
        assertEq(tickMath.getSqrtRatioAtTick(MAX_TICK), tickMath.MAX_SQRT_RATIO());
        assertEq(tickMath.getSqrtRatioAtTick(MAX_TICK), 1461446703485210103287273052203988822378723970342);
    }

    function test_getSqrtRatioAtTick_isValidMaxTickSubOne() public {
        assertEq(tickMath.getSqrtRatioAtTick(MAX_TICK - 1), 1461373636630004318706518188784493106690254656249);
    }

    function test_getSqrtRatioAtTick_isLessThanJSImplMinTick() public {
        // sqrt(1 / 2 ** 127) * 2 ** 96
        uint160 jsMinSqrtRatio = 6085630636;
        uint160 solMinSqrtRatio = tickMath.getSqrtRatioAtTick(MIN_TICK);
        assertLt(solMinSqrtRatio, jsMinSqrtRatio);
    }

    function test_getSqrtRatioAtTick_isGreaterThanJSImplMaxTick() public {
        // sqrt(2 ** 127) * 2 ** 96
        uint160 jsMaxSqrtRatio = 1033437718471923706666374484006904511252097097914;
        uint160 solMaxSqrtRatio = tickMath.getSqrtRatioAtTick(MAX_TICK);
        assertGt(solMaxSqrtRatio, jsMaxSqrtRatio);
    }

    function test_getTickAtSqrtRatio_throwsForTooLow() public {
        vm.expectRevert(TickMath.InvalidSqrtRatio.selector);
        tickMath.getTickAtSqrtRatio(MIN_SQRT_RATIO - 1);
    }

    function test_getTickAtSqrtRatio_throwsForTooHigh() public {
        vm.expectRevert(TickMath.InvalidSqrtRatio.selector);
        tickMath.getTickAtSqrtRatio(MAX_SQRT_RATIO + 1);
    }

    function test_getTickAtSqrtRatio_isValidMinSqrtRatio() public {
        assertEq(tickMath.getTickAtSqrtRatio(MIN_SQRT_RATIO), MIN_TICK);
    }

    function test_getTickAtSqrtRatio_isValidMinSqrtRatioPlusOne() public {
        assertEq(tickMath.getTickAtSqrtRatio(4295343490), MIN_TICK + 1);
    }

    function test_getTickAtSqrtRatio_isValidRatioClosestToMaxTick() public {
        assertEq(tickMath.getTickAtSqrtRatio(MAX_SQRT_RATIO - 1), MAX_TICK - 1);
    }

    function test_getTickAtSqrtRatio_isValidMaxSqrtRatioMinusOne() public {
        assertEq(tickMath.getTickAtSqrtRatio(1461373636630004318706518188784493106690254656249), MAX_TICK - 1);
    }

    function test_getSqrtRatioAtTick_matchesJavaScriptImplByOneHundrethOfABip() public {
        string memory jsParameters = "";
        string[] memory runJsInputs = new string[](4);

        // build ffi command string
        runJsInputs[0] = "npx";
        runJsInputs[1] = "ts-node";
        runJsInputs[2] = "test/js-scripts/getSqrtRatioAtTick.ts";

        int24 tick = 50;

        while (true) {
            if (tick > MAX_TICK) break;
            // test negative and positive tick
            for (uint256 i = 0; i < 2; i++) {
                tick = tick * -1;
                if (tick != -50) jsParameters = string(abi.encodePacked(jsParameters, ",")); // do not leave comma in front of first number
                // add tick to javascript parameters to be calulated inside script
                jsParameters = string(abi.encodePacked(jsParameters, vm.toString(int256(tick))));
                // track solidity result for tick
                getSqrtRatioAtTickFuzzResults.push(tickMath.getSqrtRatioAtTick(tick));
            }
            tick = tick * 2;
        }

        runJsInputs[3] = jsParameters;
        bytes memory jsResult = vm.ffi(runJsInputs);
        uint160[] memory jsSqrtRatios = abi.decode(jsResult, (uint160[]));

        for (uint256 i = 0; i < jsSqrtRatios.length; i++) {
            uint160 jsSqrtRatio = jsSqrtRatios[i];
            uint160 solResult = getSqrtRatioAtTickFuzzResults[i];
            (uint160 gtResult, uint160 ltResult) =
                jsSqrtRatio > solResult ? (jsSqrtRatio, solResult) : (solResult, jsSqrtRatio);
            uint160 resultsDiff = gtResult - ltResult;

            // assert solc/js result is at most off by 1/100th of a bip (aka one pip)
            assertEq(resultsDiff * ONE_PIP / jsSqrtRatio, 0);
        }
    }

    function test_getTickAtSqrtRatio_matchesJavascriptImplWithin1() public {
        string memory jsParameters = "";
        string[] memory runJsInputs = new string[](4);

        // build ffi command string
        runJsInputs[0] = "npx";
        runJsInputs[1] = "ts-node";
        runJsInputs[2] = "test/js-scripts/getTickAtSqrtRatio.ts";

        uint160 sqrtRatio = MIN_SQRT_RATIO;
        unchecked {
            while (sqrtRatio < sqrtRatio * 16) {
                if (sqrtRatio != MIN_SQRT_RATIO) jsParameters = string(abi.encodePacked(jsParameters, ",")); // do not leave comma in front of first number
                // add tick to javascript parameters to be calulated inside script
                jsParameters = string(abi.encodePacked(jsParameters, vm.toString(sqrtRatio)));
                // track solidity result for sqrtRatio
                getTickAtSqrtRatioFuzzResults.push(tickMath.getTickAtSqrtRatio(sqrtRatio));
                sqrtRatio = sqrtRatio * 16;
            }
        }

        runJsInputs[3] = jsParameters;
        bytes memory jsResult = vm.ffi(runJsInputs);
        int24[] memory jsTicks = abi.decode(jsResult, (int24[]));

        for (uint256 i = 0; i < jsTicks.length; i++) {
            int24 jsTick = jsTicks[i];
            int24 solTick = getTickAtSqrtRatioFuzzResults[i];

            (int24 gtResult, int24 ltResult) = jsTick > solTick ? (jsTick, solTick) : (solTick, jsTick);
            int24 resultsDiff = gtResult - ltResult;
            assertLt(resultsDiff, 2);
        }
    }
}
