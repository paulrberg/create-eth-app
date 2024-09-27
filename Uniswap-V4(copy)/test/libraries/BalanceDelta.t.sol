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
import {BalanceDelta, toBalanceDelta} from "../../src/types/BalanceDelta.sol";

contract TestBalanceDelta is Test {
    function testToBalanceDelta() public {
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

    function testToBalanceDelta(int128 x, int128 y) public {
        BalanceDelta balanceDelta = toBalanceDelta(x, y);
        assertEq(balanceDelta.amount0(), x);
        assertEq(balanceDelta.amount1(), y);
    }

    function testAdd(int128 a, int128 b, int128 c, int128 d) public {
        int256 ac = int256(a) + c;
        int256 bd = int256(b) + d;

        // make sure the addition doesn't overflow
        if (ac != int128(ac) || bd != int128(bd)) {
            vm.expectRevert();
        }

        BalanceDelta balanceDelta = toBalanceDelta(a, b) + toBalanceDelta(c, d);
        assertEq(balanceDelta.amount0(), ac);
        assertEq(balanceDelta.amount1(), bd);
    }

    function testSub(int128 a, int128 b, int128 c, int128 d) public {
        int256 ac = int256(a) - c;
        int256 bd = int256(b) - d;

        // make sure the subtraction doesn't underflow
        vm.assume(ac == int128(ac));
        vm.assume(bd == int128(bd));

        BalanceDelta balanceDelta = toBalanceDelta(a, b) - toBalanceDelta(c, d);
        assertEq(balanceDelta.amount0(), ac);
        assertEq(balanceDelta.amount1(), bd);
    }
}
