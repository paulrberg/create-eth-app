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
import {UnsafeMath} from "../../src/libraries/UnsafeMath.sol";

contract UnsafeMathTest is Test {
    using UnsafeMath for uint256;

    uint256 constant Q128 = 2 ** 128;
    uint256 constant MAX_UINT256 = type(uint256).max;

    function test_divRoundingUp_zeroDoesNotRevert(uint256 x) public pure {
        x.divRoundingUp(0);
    }

    function test_divRoundingUp_maxInput() public pure {
        assertEq(MAX_UINT256.divRoundingUp(MAX_UINT256), 1);
    }

    function test_divRoundingUp_RoundsUp() public pure {
        uint256 result = Q128 / 3 + 1;
        assertEq(Q128.divRoundingUp(3), result);
    }

    function test_fuzz_divRoundingUp(uint256 x, uint256 y) public pure {
        vm.assume(y != 0);
        uint256 result = x.divRoundingUp(y);
        assertTrue(result == x / y || result == x / y + 1);
    }

    function test_invariant_divRoundingUp(uint256 x, uint256 y) public pure {
        vm.assume(y != 0);
        uint256 z = x.divRoundingUp(y);
        uint256 diff = z - (x / y);
        if (x % y == 0) {
            assertEq(diff, 0);
        } else {
            assertEq(diff, 1);
        }
    }
}
