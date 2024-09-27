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
pragma solidity ^0.8.19;

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {FullMath} from "../../src/libraries/FullMath.sol";

contract FullMathTest is Test {
    using FullMath for uint256;

    uint256 constant Q128 = 2 ** 128;
    uint256 constant MAX_UINT256 = type(uint256).max;

    function test_fuzz_mulDiv_revertsWith0Denominator(uint256 x, uint256 y) public {
        vm.expectRevert();
        x.mulDiv(y, 0);
    }

    function test_mulDiv_revertsWithOverflowingNumeratorAndZeroDenominator() public {
        vm.expectRevert();
        Q128.mulDiv(Q128, 0);
    }

    function test_mulDiv_revertsIfOutputOverflows() public {
        vm.expectRevert();
        Q128.mulDiv(Q128, 1);
    }

    function test_mulDiv_revertsOverflowWithAllMaxInputs() public {
        vm.expectRevert();
        MAX_UINT256.mulDiv(MAX_UINT256, MAX_UINT256 - 1);
    }

    function test_mulDiv_validAllMaxInputs() public pure {
        assertEq(MAX_UINT256.mulDiv(MAX_UINT256, MAX_UINT256), MAX_UINT256);
    }

    function test_mulDiv_validWithoutPhantomOverflow() public pure {
        uint256 result = Q128 / 3;
        assertEq(Q128.mulDiv(50 * Q128 / 100, 150 * Q128 / 100), result);
    }

    function test_mulDiv_validWithPhantomOverflow() public pure {
        uint256 result = 4375 * Q128 / 1000;
        assertEq(Q128.mulDiv(35 * Q128, 8 * Q128), result);
    }

    function test_mulDiv_phantomOverflowRepeatingDecimal() public pure {
        uint256 result = 1 * Q128 / 3;
        assertEq(Q128.mulDiv(1000 * Q128, 3000 * Q128), result);
    }

    function test_fuzz_mulDiv(uint256 x, uint256 y, uint256 d) public pure {
        vm.assume(d != 0);
        vm.assume(y != 0);
        x = bound(x, 0, type(uint256).max / y);
        assertEq(FullMath.mulDiv(x, y, d), x * y / d);
    }

    function test_fuzz_mulDivRoundingUp_revertsWith0Denominator(uint256 x, uint256 y) public {
        vm.expectRevert();
        x.mulDivRoundingUp(y, 0);
    }

    function test_mulDivRoundingUp_validWithAllMaxInputs() public pure {
        assertEq(MAX_UINT256.mulDivRoundingUp(MAX_UINT256, MAX_UINT256), MAX_UINT256);
    }

    function test_mulDivRoundingUp_validWithNoPhantomOverflow() public pure {
        uint256 result = Q128 / 3 + 1;
        assertEq(Q128.mulDivRoundingUp(50 * Q128 / 100, 150 * Q128 / 100), result);
    }

    function test_mulDivRoundingUp_validWithPhantomOverflow() public pure {
        uint256 result = 4375 * Q128 / 1000;
        assertEq(Q128.mulDiv(35 * Q128, 8 * Q128), result);
    }

    function test_mulDivRoundingUp_validWithPhantomOverflowRepeatingDecimal() public pure {
        uint256 result = 1 * Q128 / 3 + 1;
        assertEq(Q128.mulDivRoundingUp(1000 * Q128, 3000 * Q128), result);
    }

    function test_mulDivRoundingUp_revertsIfMulDivOverflows256BitsAfterRoundingUp() public {
        vm.expectRevert();
        FullMath.mulDivRoundingUp(535006138814359, 432862656469423142931042426214547535783388063929571229938474969, 2);
    }

    function test_mulDivRoundingUp_revertsIfMulDivOverflows256BitsAfterRoundingUpCase2() public {
        vm.expectRevert();
        FullMath.mulDivRoundingUp(
            115792089237316195423570985008687907853269984659341747863450311749907997002549,
            115792089237316195423570985008687907853269984659341747863450311749907997002550,
            115792089237316195423570985008687907853269984653042931687443039491902864365164
        );
    }

    function test_fuzz_mulDivRoundingUp(uint256 x, uint256 y, uint256 d) public pure {
        vm.assume(d != 0);
        vm.assume(y != 0);
        x = bound(x, 0, type(uint256).max / y);
        uint256 numerator = x * y;
        uint256 result = FullMath.mulDivRoundingUp(x, y, d);
        if (mulmod(x, y, d) > 0) {
            assertEq(result, numerator / d + 1);
        } else {
            assertEq(result, numerator / d);
        }
    }

    function test_invariant_mulDivRounding(uint256 x, uint256 y, uint256 d) public pure {
        unchecked {
            vm.assume(d > 0);
            vm.assume(!resultOverflows(x, y, d));

            uint256 ceiled = FullMath.mulDivRoundingUp(x, y, d);

            uint256 floored = FullMath.mulDiv(x, y, d);

            if (mulmod(x, y, d) > 0) {
                assertEq(ceiled - floored, 1);
            } else {
                assertEq(ceiled, floored);
            }
        }
    }

    function test_invariant_mulDiv(uint256 x, uint256 y, uint256 d) public pure {
        unchecked {
            vm.assume(d > 0);
            vm.assume(!resultOverflows(x, y, d));
            uint256 z = FullMath.mulDiv(x, y, d);
            if (x == 0 || y == 0) {
                assertEq(z, 0);
                return;
            }

            // recompute x and y via mulDiv of the result of floor(x*y/d), should always be less than original inputs by < d
            uint256 x2 = FullMath.mulDiv(z, d, y);
            uint256 y2 = FullMath.mulDiv(z, d, x);
            assertLe(x2, x);
            assertLe(y2, y);

            assertLt(x - x2, d);
            assertLt(y - y2, d);
        }
    }

    function test_invariant_mulDivRoundingUp(uint256 x, uint256 y, uint256 d) external pure {
        unchecked {
            vm.assume(d > 0);
            vm.assume(!resultOverflows(x, y, d));
            uint256 z = FullMath.mulDivRoundingUp(x, y, d);
            if (x == 0 || y == 0) {
                assertEq(z, 0);
                return;
            }

            vm.assume(!resultOverflows(z, d, y));
            vm.assume(!resultOverflows(z, d, x));
            // recompute x and y via mulDiv of the result of ceil(x*y/d), should always be greater than original inputs by < d
            uint256 x2 = FullMath.mulDiv(z, d, y);
            uint256 y2 = FullMath.mulDiv(z, d, x);
            assertGe(x2, x);
            assertGe(y2, y);

            assertLt(x2 - x, d);
            assertLt(y2 - y, d);
        }
    }

    function test_resultOverflows_helper() public pure {
        assertFalse(resultOverflows(0, 0, 1));
        assertFalse(resultOverflows(1, 0, 1));
        assertFalse(resultOverflows(0, 1, 1));
        assertFalse(resultOverflows(1, 1, 1));
        assertFalse(resultOverflows(10000000, 10000000, 1));
        assertFalse(resultOverflows(Q128, 50 * Q128 / 100, 150 * Q128 / 100));
        assertFalse(resultOverflows(Q128, 35 * Q128, 8 * Q128));
        assertTrue(resultOverflows(type(uint256).max, type(uint256).max, type(uint256).max - 1));
        assertTrue(resultOverflows(Q128, type(uint256).max, 1));
    }

    function resultOverflows(uint256 x, uint256 y, uint256 d) private pure returns (bool) {
        require(d > 0);

        // If x or y is zero, the result will be zero, and there's no overflow
        if (x == 0 || y == 0) {
            return false;
        }

        // If intermediate multiplication doesn't overflow, there's no overflow
        if (x <= type(uint256).max / y) return false;

        uint256 remainder = mulmod(x, y, type(uint256).max);
        uint256 small;
        uint256 big;
        unchecked {
            small = x * y;
            big = (remainder - small) - (remainder < small ? 1 : 0);
        }

        bool mulDivResultOverflows = d <= big;
        bool mulDivRoundingUpResultOverflows = mulDivResultOverflows;

        // must catch edgecase where mulDiv doesn't overflow but roundingUp does
        if (!mulDivResultOverflows) {
            mulDivRoundingUpResultOverflows = FullMath.mulDiv(x, y, d) == type(uint256).max;
        }

        return mulDivResultOverflows || mulDivRoundingUpResultOverflows;
    }
}
