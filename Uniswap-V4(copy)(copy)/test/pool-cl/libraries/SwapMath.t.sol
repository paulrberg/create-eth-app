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
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {SwapMath} from "../../../src/pool-cl/libraries/SwapMath.sol";
import {FixedPoint96} from "../../../src/pool-cl/libraries/FixedPoint96.sol";
import {FixedPointMathLib} from "Uniswap-V4/solmate/utils/FixedPointMathLib.sol";
import {SqrtPriceMath} from "../../../src/pool-cl/libraries/SqrtPriceMath.sol";

contract SwapMathTest is Test, GasSnapshot {
    function testComputeSwapTest_sufficientAmountInOneForZero() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(101 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 amountRemaining = 1 ether;
        uint24 feePips = 600;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, amountRemaining, feePips);

        assertEq(amountIn, 9975124224178055);
        assertEq(feeAmount, 5988667735148);
        assertEq(amountOut, 9925619580021728);

        // there is still some amount remaining
        assertLt(amountIn + feeAmount, uint256(amountRemaining));

        uint160 priceX96IfAllRemainingIn =
            SqrtPriceMath.getNextSqrtPriceFromInput(priceX96, liquidity, uint256(amountRemaining), false);

        assertEq(sqrtRatioNextX96, targetPriceX96);
        assertLt(sqrtRatioNextX96, priceX96IfAllRemainingIn);
    }

    function testComputeSwapTest_sufficientAmountOutOneForZero() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(101 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        // expecting to get exactly 1 ether out
        int256 amountWantedOut = -1 ether;
        uint24 feePips = 600;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, amountWantedOut, feePips);

        assertEq(amountIn, 9975124224178055);
        assertEq(feeAmount, 5988667735148);
        assertEq(amountOut, 9925619580021728);

        // amountOut in this case is less than user's expectation
        assertLt(amountOut, uint256(-amountWantedOut));

        uint160 priceX96IfAllWantedOut =
            SqrtPriceMath.getNextSqrtPriceFromOutput(priceX96, liquidity, uint256(-amountWantedOut), false);

        assertEq(sqrtRatioNextX96, targetPriceX96);
        assertLt(sqrtRatioNextX96, priceX96IfAllWantedOut);
    }

    function testComputeSwapTest_insufficientAmountIntOneForZero() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(1000 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        // expecting to get exactly 1 ether out
        int256 actualAmountIn = 1 ether;
        uint24 feePips = 600;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualAmountIn, feePips);

        assertEq(amountIn, 999400000000000000);
        assertEq(feeAmount, 600000000000000);
        assertEq(amountOut, 666399946655997866);
        assertEq(amountIn + feeAmount, uint256(actualAmountIn));

        uint160 priceX96IfAllAmountIn =
            SqrtPriceMath.getNextSqrtPriceFromInput(priceX96, liquidity, uint256(actualAmountIn) - feeAmount, false);

        assertLt(sqrtRatioNextX96, targetPriceX96);
        assertEq(sqrtRatioNextX96, priceX96IfAllAmountIn);
    }

    function testComputeSwapTest_insufficientAmountOutOneForZero() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(1000 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        // expecting to get exactly 1 ether out
        int256 amountWantedOut = -1 ether;
        uint24 feePips = 600;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, amountWantedOut, feePips);

        assertEq(amountIn, 2000000000000000000);
        assertEq(feeAmount, 1200720432259356);
        assertEq(amountOut, uint256(-amountWantedOut));

        uint160 priceX96IfwantedAmountOut =
            SqrtPriceMath.getNextSqrtPriceFromOutput(priceX96, liquidity, uint256(-amountWantedOut), false);

        assertLt(sqrtRatioNextX96, targetPriceX96);
        assertEq(sqrtRatioNextX96, priceX96IfwantedAmountOut);
    }

    function testComputeSwapTest_amountWantedOutEq1() external {
        uint160 priceX96 = 417332158212080721273783715441582;
        uint160 targetPriceX96 = 1452870262520218020823638996;
        uint128 liquidity = 159344665391607089467575320103;
        int256 amountWantedOut = -1;
        uint24 feePips = 1;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, amountWantedOut, feePips);

        assertEq(amountIn, 1);
        assertEq(feeAmount, 1);
        assertEq(amountOut, 1);
        assertEq(sqrtRatioNextX96, 417332158212080721273783715441581);
    }

    function testComputeSwapTest_partialInputToPriceEq1() external {
        uint160 priceX96 = 2;
        uint160 targetPriceX96 = 1;
        uint128 liquidity = 1;
        int256 actualAmountIn = 3915081100057732413702495386755767;
        uint24 feePips = 1;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualAmountIn, feePips);

        assertEq(amountIn, 39614081257132168796771975168);
        assertEq(feeAmount, 39614120871253040049813);
        assertLe(amountIn + feeAmount, 3915081100057732413702495386755767);
        assertEq(amountOut, 0);
        assertEq(sqrtRatioNextX96, 1);
    }

    function testComputeSwapTest_entireInputAmountTakenAsFee() external {
        uint160 priceX96 = 2413;
        uint160 targetPriceX96 = 79887613182836312;
        uint128 liquidity = 1985041575832132834610021537970;
        int256 actualAmountIn = 10;
        uint24 feePips = 1872;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualAmountIn, feePips);

        assertEq(amountIn, 0);
        assertEq(feeAmount, 10);
        assertEq(amountOut, 0);
        assertEq(sqrtRatioNextX96, 2413);
    }

    function testComputeSwapTest_insufficientLiquidityExactOutputInZeroForOne() external {
        uint160 priceX96 = 20282409603651670423947251286016;
        uint160 targetPriceX96 = priceX96 * 11 / 10;
        uint128 liquidity = 1024;
        // virtual reserves of one are only 4
        // https://www.wolframalpha.com/input/?i=1024+%2F+%2820282409603651670423947251286016+%2F+2**96%29
        int256 wantedOutputAmount = -4;
        uint24 feePips = 3000;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, wantedOutputAmount, feePips);

        assertEq(amountIn, 26215);
        assertEq(feeAmount, 79);
        assertEq(amountOut, 0);
        assertEq(sqrtRatioNextX96, targetPriceX96);
    }

    function testComputeSwapTest_insufficientLiquidityExactOutputInOneForZero() external {
        uint160 priceX96 = 20282409603651670423947251286016;
        uint160 targetPriceX96 = priceX96 * 9 / 10;
        uint128 liquidity = 1024;
        // virtual reserves of zero are only 262144
        // https://www.wolframalpha.com/input/?i=1024+*+%2820282409603651670423947251286016+%2F+2**96%29
        int256 wantedOutputAmount = -263000;
        uint24 feePips = 3000;

        (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, wantedOutputAmount, feePips);

        assertEq(amountIn, 1);
        assertEq(feeAmount, 1);
        assertEq(amountOut, 26214);
        assertEq(sqrtRatioNextX96, targetPriceX96);
    }

    function testComputeSwapTest_gasSwapOneForZeroExactInCapped() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(101 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 actualAmountIn = 1 ether;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapOneForZeroExactInCapped");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualAmountIn, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapZeroForOneExactInCapped() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(99 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 actualAmountIn = 1 ether;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapZeroForOneExactInCapped");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualAmountIn, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapOneForZeroExactOutCapped() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(101 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 wantedOutputAmount = -1 ether;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapOneForZeroExactOutCapped");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, wantedOutputAmount, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapZeroForOneExactOutCapped() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(99 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 wantedOutputAmount = -1 ether;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapZeroForOneExactOutCapped");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, wantedOutputAmount, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapOneForZeroExactInPartial() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(1010 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 actualInputAmount = 1000;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapOneForZeroExactInPartial");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualInputAmount, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapZeroForOneExactInPartial() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(99 * FixedPoint96.Q96 ** 2 / 1000));
        uint128 liquidity = 2 ether;
        int256 actualInputAmount = 1000;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapZeroForOneExactInPartial");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualInputAmount, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapOneForZeroExactOutPartial() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(1010 * FixedPoint96.Q96 ** 2 / 100));
        uint128 liquidity = 2 ether;
        int256 actualInputAmount = 1000;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapOneForZeroExactOutPartial");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualInputAmount, feePips);
        snapEnd();
    }

    function testComputeSwapTest_gasSwapZeroForOneExactOutPartial() external {
        // (y / x) ^ 0.5 * 2^(96 * 2 * 0.5)
        // (y / x) ^ 0.5 * 2^ (192 * 0.5)
        //  (y / x * 2^192) ^ 0.5
        uint160 priceX96 = uint160(FixedPointMathLib.sqrt(1 * FixedPoint96.Q96 ** 2));
        uint160 targetPriceX96 = uint160(FixedPointMathLib.sqrt(99 * FixedPoint96.Q96 ** 2 / 1000));
        uint128 liquidity = 2 ether;
        int256 actualInputAmount = 1000;
        uint24 feePips = 600;

        snapStart("SwapMathTest#SwapZeroForOneExactOutPartial");
        SwapMath.computeSwapStep(priceX96, targetPriceX96, liquidity, actualInputAmount, feePips);
        snapEnd();
    }
}
