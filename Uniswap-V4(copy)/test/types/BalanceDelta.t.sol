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
import {BalanceDelta, toBalanceDelta} from "../../src/types/BalanceDelta.sol";

contract TestBalanceDelta is Test {
    function test_toBalanceDelta() public pure {
        BalanceDelta balanceDelta = toBalanceDelta(0, 0);
        assertEq(balanceDelta.amount0(), 0);
        assertEq(balanceDelta.amount1(), 0);

        balanceDelta = toBalanceDelta(0, 1);
        assertEq(balanceDelta.amount0(), 0);
        assertEq(balanceDelta.amount1(), 1);

        balanceDelta = toBalanceDelta(1, 0);
        assertEq(balanceDelta.amount0(), 1);
        assertEq(balanceDelta.amount1(), 0);

        balanceDelta = toBalanceDelta(type(int128).max, type(int128).max);
        assertEq(balanceDelta.amount0(), type(int128).max);
        assertEq(balanceDelta.amount1(), type(int128).max);

        balanceDelta = toBalanceDelta(type(int128).min, type(int128).min);
        assertEq(balanceDelta.amount0(), type(int128).min);
        assertEq(balanceDelta.amount1(), type(int128).min);
    }

    function test_fuzz_toBalanceDelta(int128 x, int128 y) public pure {
        BalanceDelta balanceDelta = toBalanceDelta(x, y);
        int256 expectedBD = int256(uint256(bytes32(abi.encodePacked(x, y))));
        assertEq(BalanceDelta.unwrap(balanceDelta), expectedBD);
    }

    function test_fuzz_amount0_amount1(int128 x, int128 y) public pure {
        BalanceDelta balanceDelta = toBalanceDelta(x, y);
        assertEq(balanceDelta.amount0(), x);
        assertEq(balanceDelta.amount1(), y);
    }

    function test_add() public pure {
        BalanceDelta balanceDelta = toBalanceDelta(0, 0) + toBalanceDelta(0, 0);
        assertEq(balanceDelta.amount0(), 0);
        assertEq(balanceDelta.amount1(), 0);

        balanceDelta = toBalanceDelta(-1000, 1000) + toBalanceDelta(1000, -1000);
        assertEq(balanceDelta.amount0(), 0);
        assertEq(balanceDelta.amount1(), 0);

        balanceDelta =
            toBalanceDelta(type(int128).min, type(int128).max) + toBalanceDelta(type(int128).max, type(int128).min);
        assertEq(balanceDelta.amount0(), -1);
        assertEq(balanceDelta.amount1(), -1);

        balanceDelta = toBalanceDelta(type(int128).max / 2 + 1, type(int128).max / 2 + 1)
            + toBalanceDelta(type(int128).max / 2, type(int128).max / 2);
        assertEq(balanceDelta.amount0(), type(int128).max);
        assertEq(balanceDelta.amount1(), type(int128).max);
    }

    function test_add_revertsOnOverflow() public {
        // should revert because type(int128).max + 1 is not possible
        vm.expectRevert();
        toBalanceDelta(type(int128).max, 0) + toBalanceDelta(1, 0);

        vm.expectRevert();
        toBalanceDelta(0, type(int128).max) + toBalanceDelta(0, 1);
    }

    function test_fuzz_add(int128 a, int128 b, int128 c, int128 d) public {
        int256 ac = int256(a) + c;
        int256 bd = int256(b) + d;

        // if the addition overflows it should revert
        if (ac != int128(ac) || bd != int128(bd)) {
            vm.expectRevert();
        }

        BalanceDelta balanceDelta = toBalanceDelta(a, b) + toBalanceDelta(c, d);
        assertEq(balanceDelta.amount0(), ac);
        assertEq(balanceDelta.amount1(), bd);
    }

    function test_sub() public pure {
        BalanceDelta balanceDelta = toBalanceDelta(0, 0) - toBalanceDelta(0, 0);
        assertEq(balanceDelta.amount0(), 0);
        assertEq(balanceDelta.amount1(), 0);

        balanceDelta = toBalanceDelta(-1000, 1000) - toBalanceDelta(1000, -1000);
        assertEq(balanceDelta.amount0(), -2000);
        assertEq(balanceDelta.amount1(), 2000);

        balanceDelta =
            toBalanceDelta(-1000, -1000) - toBalanceDelta(-(type(int128).min + 1000), -(type(int128).min + 1000));
        assertEq(balanceDelta.amount0(), type(int128).min);
        assertEq(balanceDelta.amount1(), type(int128).min);

        balanceDelta = toBalanceDelta(type(int128).min / 2, type(int128).min / 2)
            - toBalanceDelta(-(type(int128).min / 2), -(type(int128).min / 2));
        assertEq(balanceDelta.amount0(), type(int128).min);
        assertEq(balanceDelta.amount1(), type(int128).min);
    }

    function test_sub_revertsOnUnderflow() public {
        // should revert because type(int128).min - 1 is not possible
        vm.expectRevert();
        toBalanceDelta(type(int128).min, 0) - toBalanceDelta(1, 0);

        vm.expectRevert();
        toBalanceDelta(0, type(int128).min) - toBalanceDelta(0, 1);
    }

    function test_fuzz_sub(int128 a, int128 b, int128 c, int128 d) public {
        int256 ac = int256(a) - c;
        int256 bd = int256(b) - d;

        // if the subtraction underflows it should revert
        if (ac != int128(ac) || bd != int128(bd)) {
            vm.expectRevert();
        }

        BalanceDelta balanceDelta = toBalanceDelta(a, b) - toBalanceDelta(c, d);
        assertEq(balanceDelta.amount0(), ac);
        assertEq(balanceDelta.amount1(), bd);
    }

    function test_fuzz_eq(int128 a, int128 b, int128 c, int128 d) public pure {
        bool isEqual = (toBalanceDelta(a, b) == toBalanceDelta(c, d));
        if (a == c && b == d) assertTrue(isEqual);
        else assertFalse(isEqual);
    }

    function test_fuzz_neq(int128 a, int128 b, int128 c, int128 d) public pure {
        bool isNotEqual = (toBalanceDelta(a, b) != toBalanceDelta(c, d));
        if (a != c || b != d) assertTrue(isNotEqual);
        else assertFalse(isNotEqual);
    }
}
