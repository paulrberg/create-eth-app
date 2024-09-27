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
import {SafeCast} from "../../src/libraries/SafeCast.sol";

contract SafeCastTest is Test {
    function test_fuzz_toUint160(uint256 x) public {
        if (x <= type(uint160).max) {
            assertEq(uint256(SafeCast.toUint160(x)), x);
        } else {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            SafeCast.toUint160(x);
        }
    }

    function test_toUint160() public {
        assertEq(uint256(SafeCast.toUint160(0)), 0);
        assertEq(uint256(SafeCast.toUint160(type(uint160).max)), type(uint160).max);
        vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        SafeCast.toUint160(type(uint160).max + uint256(1));
    }

    function test_fuzz_toUint128(uint256 x) public {
        if (x <= type(uint128).max) {
            assertEq(uint256(SafeCast.toUint128(x)), x);
        } else {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            SafeCast.toUint128(x);
        }
    }

    function test_toUint128() public {
        assertEq(uint256(SafeCast.toUint128(0)), 0);
        assertEq(uint256(SafeCast.toUint128(type(uint128).max)), type(uint128).max);
        vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        SafeCast.toUint128(type(uint128).max + uint256(1));
    }

    function test_fuzz_toInt128_fromInt256(int256 x) public {
        if (x <= type(int128).max && x >= type(int128).min) {
            assertEq(int256(SafeCast.toInt128(x)), x);
        } else {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            SafeCast.toInt128(x);
        }
    }

    function test_toInt128_fromInt256() public {
        assertEq(int256(SafeCast.toInt128(int256(0))), 0);
        assertEq(int256(SafeCast.toInt128(type(int128).max)), type(int128).max);
        assertEq(int256(SafeCast.toInt128(type(int128).min)), type(int128).min);
        vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        SafeCast.toInt128(type(int128).max + int256(1));
        vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        SafeCast.toInt128(type(int128).min - int256(1));
    }

    function test_fuzz_toInt256(uint256 x) public {
        if (x <= uint256(type(int256).max)) {
            assertEq(uint256(SafeCast.toInt256(x)), x);
        } else {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            SafeCast.toInt256(x);
        }
    }

    function test_toInt256() public {
        assertEq(uint256(SafeCast.toInt256(0)), 0);
        assertEq(uint256(SafeCast.toInt256(uint256(type(int256).max))), uint256(type(int256).max));
        vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        SafeCast.toInt256(uint256(type(int256).max) + uint256(1));
    }

    function test_fuzz_toInt128_fromUint256(uint256 x) public {
        if (x <= uint128(type(int128).max)) {
            assertEq(uint128(SafeCast.toInt128(x)), x);
        } else {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
            SafeCast.toInt128(x);
        }
    }

    function test_toInt128_fromUint256() public {
        assertEq(uint128(SafeCast.toInt128(uint256(0))), 0);
        assertEq(uint128(SafeCast.toInt128(uint256(uint128(type(int128).max)))), uint128(type(int128).max));
        vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        SafeCast.toInt128(uint256(uint128(type(int128).max)) + uint256(1));
    }
}
