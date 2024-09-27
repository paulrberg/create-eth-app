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

import "Uniswap-V4/forge-std/Test.sol";
import {Uint256x256Math} from "../../../../src/pool-bin/libraries/math/Uint256x256Math.sol";

contract Uint256x256MathTest is Test {
    using Uint256x256Math for uint256;

    function testFuzz_MulDivRoundDown(uint256 x, uint256 y, uint256 denominator) external {
        if (denominator == 0) {
            vm.expectRevert();
            x.mulDivRoundDown(y, denominator);
        } else {
            if (x == 0 || y == 0) {
                assertEq(x.mulDivRoundDown(y, denominator), 0, "testFuzz_MulDivRoundDown::1");
            } else {
                (, uint256 prod1) = _getProds(x, y);

                if (prod1 != 0 && denominator <= prod1) {
                    vm.expectRevert(Uint256x256Math.Uint256x256Math__MulDivOverflow.selector);
                    x.mulDivRoundDown(y, denominator);
                } else {
                    assertEq(
                        x.mulDivRoundDown(y, denominator),
                        _trustedMulDiv(x, y, denominator),
                        "testFuzz_MulDivRoundDown::2"
                    );
                }
            }
        }
    }

    function testFuzz_MulDivRoundUp(uint256 x, uint256 y, uint256 denominator) external {
        if (denominator == 0) {
            vm.expectRevert();
            x.mulDivRoundUp(y, denominator);
        }

        (, uint256 prod1) = _getProds(x, y);

        if (prod1 != 0 && denominator <= prod1) {
            vm.expectRevert(Uint256x256Math.Uint256x256Math__MulDivOverflow.selector);
            x.mulDivRoundDown(y, denominator);
        } else {
            uint256 result = x.mulDivRoundDown(y, denominator);
            if (mulmod(x, y, denominator) != 0) {
                if (result == type(uint256).max) {
                    vm.expectRevert();
                    x.mulDivRoundUp(y, denominator);
                    return;
                } else {
                    result += 1;
                }
            }

            assertEq(x.mulDivRoundUp(y, denominator), result, "testFuzz_MulDivRoundUp::1");
        }
    }

    function testFuzz_mulShiftRoundDown(uint256 x, uint256 y, uint8 shift) external {
        (, uint256 prod1) = _getProds(x, y);
        if (prod1 >> shift != 0) {
            vm.expectRevert(Uint256x256Math.Uint256x256Math__MulShiftOverflow.selector);
            x.mulShiftRoundDown(y, shift);
        } else {
            assertEq(x.mulShiftRoundDown(y, shift), x.mulDivRoundDown(y, 1 << shift), "testFuzz_MulShiftRoundDown::1");
        }
    }

    function testFuzz_mulShiftRoundUp(uint256 x, uint256 y, uint8 shift) external {
        (, uint256 prod1) = _getProds(x, y);
        if (prod1 >> shift != 0) {
            vm.expectRevert(Uint256x256Math.Uint256x256Math__MulShiftOverflow.selector);
            x.mulShiftRoundUp(y, shift);
        } else {
            assertEq(x.mulShiftRoundUp(y, shift), x.mulDivRoundUp(y, 1 << shift), "testFuzz_MulShiftRoundUp::1");
        }
    }

    function testFuzz_ShiftDivRoundDown(uint256 x, uint8 shift, uint256 denominator) external {
        if (denominator == 0) {
            vm.expectRevert();
            x.shiftDivRoundDown(shift, denominator);
        } else {
            (, uint256 prod1) = _getProds(x, 1 << shift);

            if (prod1 != 0 && denominator <= prod1) {
                vm.expectRevert(Uint256x256Math.Uint256x256Math__MulDivOverflow.selector);
                x.shiftDivRoundDown(shift, denominator);
            } else {
                assertEq(
                    x.shiftDivRoundDown(shift, denominator),
                    _trustedMulDiv(x, 1 << shift, denominator),
                    "testFuzz_ShiftDivRoundDown::1"
                );
            }
        }
    }

    function testFuzz_ShiftDivRoundUp(uint256 x, uint8 shift, uint256 denominator) external {
        if (denominator == 0) {
            vm.expectRevert();
            x.shiftDivRoundUp(shift, denominator);
        } else {
            (, uint256 prod1) = _getProds(x, 1 << shift);

            if (prod1 != 0 && denominator <= prod1) {
                vm.expectRevert(Uint256x256Math.Uint256x256Math__MulDivOverflow.selector);
                x.shiftDivRoundUp(shift, denominator);
            } else {
                uint256 result = _trustedMulDiv(x, 1 << shift, denominator);
                if (mulmod(x, 1 << shift, denominator) != 0) {
                    if (result == type(uint256).max) {
                        vm.expectRevert();
                        x.shiftDivRoundUp(shift, denominator);
                        return;
                    } else {
                        result += 1;
                    }
                }

                assertEq(x.shiftDivRoundUp(shift, denominator), result, "testFuzz_ShiftDivRoundUp::1");
            }
        }
    }

    function _getProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /**
     * Trusted muldiv implementation, used to verify that the muldiv is right.
     */

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function _trustedMulDiv(uint256 x, uint256 y, uint256 denominator) private pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }
}
