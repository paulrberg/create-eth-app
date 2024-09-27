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
import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {SqrtPriceMath} from "../../src/libraries/SqrtPriceMath.sol";
import {SwapMath} from "../../src/libraries/SwapMath.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";

contract SwapMathTest is Test, GasSnapshot {
    uint160 private constant SQRT_PRICE_1_1 = 79228162514264337593543950336;
    uint160 private constant SQRT_PRICE_99_100 = 78831026366734652303669917531;
    uint160 private constant SQRT_PRICE_99_1000 = 24928559360766947368818086097;
    uint160 private constant SQRT_PRICE_101_100 = 79623317895830914510639640423;
    uint160 private constant SQRT_PRICE_1000_100 = 250541448375047931186413801569;
    uint160 private constant SQRT_PRICE_1010_100 = 251791039410471229173201122529;
    uint160 private constant SQRT_PRICE_10000_100 = 792281625142643375935439503360;

    function test_fuzz_getSqrtPriceTarget(bool zeroForOne, uint160 sqrtPriceNextX96, uint160 sqrtPriceLimitX96)
        public
        pure
    {
        assertEq(
            SwapMath.getSqrtPriceTarget(zeroForOne, sqrtPriceNextX96, sqrtPriceLimitX96),
            (zeroForOne ? sqrtPriceNextX96 < sqrtPriceLimitX96 : sqrtPriceNextX96 > sqrtPriceLimitX96)
                ? sqrtPriceLimitX96
                : sqrtPriceNextX96
        );
    }

    function test_computeSwapStep_exactAmountIn_oneForZero_thatGetsCappedAtPriceTargetIn() public pure {
        uint160 priceTarget = SQRT_PRICE_101_100;
        uint160 price = SQRT_PRICE_1_1;
        uint128 liquidity = 2 ether;
        int256 amount = (1 ether) * -1;
        uint24 lpFee = 600;
        bool zeroForOne = false;

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(price, priceTarget, liquidity, amount, lpFee);

        assertEq(amountIn, 9975124224178055);
        assertEq(amountOut, 9925619580021728);
        assertEq(feeAmount, 5988667735148);
        assert(amountIn + feeAmount < uint256(amount * -1));

        uint256 priceAfterWholeInputAmount =
            SqrtPriceMath.getNextSqrtPriceFromInput(price, liquidity, uint256(amount * -1), zeroForOne);

        assertEq(sqrtQ, priceTarget);
        assert(sqrtQ < priceAfterWholeInputAmount);
    }

    function test_computeSwapStep_exactAmountOut_oneForZero_thatGetsCappedAtPriceTargetIn() public pure {
        uint160 priceTarget = SQRT_PRICE_101_100;
        uint160 price = SQRT_PRICE_1_1;
        uint128 liquidity = 2 ether;
        int256 amount = 1 ether;
        uint24 lpFee = 600;
        bool zeroForOne = false;

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(price, priceTarget, liquidity, amount, lpFee);

        assertEq(amountIn, 9975124224178055);
        assertEq(amountOut, 9925619580021728);
        assertEq(feeAmount, 5988667735148);
        assert(amountOut < uint256(amount));

        uint256 priceAfterWholeOutputAmount =
            SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, uint256(amount), zeroForOne);

        assertEq(sqrtQ, priceTarget);
        assert(sqrtQ < priceAfterWholeOutputAmount);
    }

    function test_computeSwapStep_exactAmountIn_oneForZero_thatIsFullySpentIn() public pure {
        uint160 priceTarget = SQRT_PRICE_1000_100;
        uint160 price = SQRT_PRICE_1_1;
        uint128 liquidity = 2 ether;
        int256 amount = 1 ether * -1;
        uint24 lpFee = 600;
        bool zeroForOne = false;

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(price, priceTarget, liquidity, amount, lpFee);

        assertEq(amountIn, 999400000000000000);
        assertEq(amountOut, 666399946655997866);
        assertEq(feeAmount, 600000000000000);
        assertEq(amountIn + feeAmount, uint256(-amount));

        uint256 priceAfterWholeInputAmountLessFee =
            SqrtPriceMath.getNextSqrtPriceFromInput(price, liquidity, uint256(uint256(-amount) - feeAmount), zeroForOne);

        assert(sqrtQ < priceTarget);
        assertEq(sqrtQ, priceAfterWholeInputAmountLessFee);
    }

    function test_computeSwapStep_exactAmountOut_oneForZero_thatIsFullyReceivedIn() public pure {
        uint160 priceTarget = SQRT_PRICE_10000_100;
        uint160 price = SQRT_PRICE_1_1;
        uint128 liquidity = 2 ether;
        int256 amount = (1 ether);
        uint24 lpFee = 600;
        bool zeroForOne = false;

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(price, priceTarget, liquidity, amount, lpFee);

        assertEq(amountIn, 2000000000000000000);
        assertEq(feeAmount, 1200720432259356);
        assertEq(amountOut, uint256(amount));

        uint256 priceAfterWholeOutputAmount =
            SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, uint256(amount), zeroForOne);

        assert(sqrtQ < priceTarget);
        assertEq(sqrtQ, priceAfterWholeOutputAmount);
    }

    function test_computeSwapStep_amountOut_isCappedAtTheDesiredAmountOut() public pure {
        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = SwapMath.computeSwapStep(
            417332158212080721273783715441582, 1452870262520218020823638996, 159344665391607089467575320103, 1, 1
        );

        assertEq(amountIn, 1);
        assertEq(feeAmount, 1);
        assertEq(amountOut, 1); // would be 2 if not capped
        assertEq(sqrtQ, 417332158212080721273783715441581);
    }

    function test_computeSwapStep_targetPriceOf1UsesPartialInputAmount() public pure {
        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(2, 1, 1, -3915081100057732413702495386755767, 1);
        assertEq(amountIn, 39614081257132168796771975168);
        assertEq(feeAmount, 39614120871253040049813);
        assert(amountIn + feeAmount <= 3915081100057732413702495386755767);
        assertEq(amountOut, 0);
        assertEq(sqrtQ, 1);
    }

    function test_computeSwapStep_entireInputAmountTakenAsFee() public pure {
        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(2413, 79887613182836312, 1985041575832132834610021537970, -10, 1872);

        assertEq(amountIn, 0);
        assertEq(feeAmount, 10);
        assertEq(amountOut, 0);
        assertEq(sqrtQ, 2413);
    }

    function test_computeSwapStep_zeroForOne_handlesIntermediateInsufficientLiquidityInExactOutputCase() public pure {
        uint160 sqrtP = 20282409603651670423947251286016;
        uint160 sqrtPTarget = (sqrtP * 11) / 10;
        uint128 liquidity = 1024;
        // virtual reserves of one are only 4
        // https://www.wolframalpha.com/input/?i=1024+%2F+%2820282409603651670423947251286016+%2F+2**96%29
        int256 amountRemaining = 4;
        uint24 feePips = 3000;

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(sqrtP, sqrtPTarget, liquidity, amountRemaining, feePips);

        assertEq(amountOut, 0);
        assertEq(sqrtQ, sqrtPTarget);
        assertEq(amountIn, 26215);
        assertEq(feeAmount, 79);
    }

    function test_computeSwapStep_oneForZero_handlesIntermediateInsufficientLiquidityInExactOutputCase() public pure {
        uint160 sqrtP = 20282409603651670423947251286016;
        uint160 sqrtPTarget = (sqrtP * 9) / 10;
        uint128 liquidity = 1024;
        // virtual reserves of zero are only 262144
        // https://www.wolframalpha.com/input/?i=1024+*+%2820282409603651670423947251286016+%2F+2**96%29
        int256 amountRemaining = 263000;
        uint24 feePips = 3000;

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(sqrtP, sqrtPTarget, liquidity, amountRemaining, feePips);

        assertEq(amountOut, 26214);
        assertEq(sqrtQ, sqrtPTarget);
        assertEq(amountIn, 1);
        assertEq(feeAmount, 1);
    }

    function test_fuzz_computeSwapStep(
        uint160 sqrtPriceRaw,
        uint160 sqrtPriceTargetRaw,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) public pure {
        vm.assume(sqrtPriceRaw > 0);
        vm.assume(sqrtPriceTargetRaw > 0);
        vm.assume(feePips >= 0);

        if (amountRemaining >= 0) {
            vm.assume(feePips < 1e6);
        } else {
            vm.assume(feePips <= 1e6);
        }

        (uint160 sqrtQ, uint256 amountIn, uint256 amountOut, uint256 feeAmount) =
            SwapMath.computeSwapStep(sqrtPriceRaw, sqrtPriceTargetRaw, liquidity, amountRemaining, feePips);

        assertLe(amountIn, type(uint256).max - feeAmount);

        unchecked {
            if (amountRemaining >= 0) {
                assertLe(amountOut, uint256(amountRemaining));
            } else {
                assertLe(amountIn + feeAmount, uint256(-amountRemaining));
            }
        }

        if (sqrtPriceRaw == sqrtPriceTargetRaw) {
            assertEq(amountIn, 0);
            assertEq(amountOut, 0);
            assertEq(feeAmount, 0);
            assertEq(sqrtQ, sqrtPriceTargetRaw);
        }

        // didn't reach price target, entire amount must be consumed
        if (sqrtQ != sqrtPriceTargetRaw) {
            uint256 absAmtRemaining;
            if (amountRemaining == type(int256).min) {
                absAmtRemaining = uint256(type(int256).max) + 1;
            } else if (amountRemaining < 0) {
                absAmtRemaining = uint256(-amountRemaining);
            } else {
                absAmtRemaining = uint256(amountRemaining);
            }
            if (amountRemaining > 0) assertEq(amountOut, absAmtRemaining);
            else assertEq(amountIn + feeAmount, absAmtRemaining);
        }

        // next price is between price and price target
        if (sqrtPriceTargetRaw <= sqrtPriceRaw) {
            assertLe(sqrtQ, sqrtPriceRaw);
            assertGe(sqrtQ, sqrtPriceTargetRaw);
        } else {
            assertGe(sqrtQ, sqrtPriceRaw);
            assertLe(sqrtQ, sqrtPriceTargetRaw);
        }
    }

    function test_computeSwapStep_swapOneForZero_exactInCapped() public {
        snapStart("SwapMath_oneForZero_exactInCapped");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_101_100, 2 ether, (1 ether) * -1, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapZeroForOne_exactInCapped() public {
        snapStart("SwapMath_zeroForOne_exactInCapped");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_99_100, 2 ether, (1 ether) * -1, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapOneForZero_exactOutCapped() public {
        snapStart("SwapMath_oneForZero_exactOutCapped");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_101_100, 2 ether, 1 ether, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapZeroForOne_exactOutCapped() public {
        snapStart("SwapMath_zeroForOne_exactOutCapped");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_99_100, 2 ether, 1 ether, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapOneForZero_exactInPartial() public {
        snapStart("SwapMath_oneForZero_exactInPartial");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_1010_100, 2 ether, 1_000 * -1, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapZeroForOne_exactInPartial() public {
        snapStart("SwapMath_zeroForOne_exactInPartial");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_99_1000, 2 ether, 1_000 * -1, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapOneForZero_exactOutPartial() public {
        snapStart("SwapMath_oneForZero_exactOutPartial");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_1010_100, 2 ether, 1_000, 600);
        snapEnd();
    }

    function test_computeSwapStep_swapZeroForOne_exactOutPartial() public {
        snapStart("SwapMath_zeroForOne_exactOutPartial");
        SwapMath.computeSwapStep(SQRT_PRICE_1_1, SQRT_PRICE_99_1000, 2 ether, 1_000, 600);
        snapEnd();
    }
}
