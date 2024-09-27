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

import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {BitMath} from "../../../src/pool-cl/libraries/BitMath.sol";

contract BitMathTest is Test, GasSnapshot {
    function testMostSignificantBitZero() public {
        vm.expectRevert();
        BitMath.mostSignificantBit(0);
    }

    function testMostSignificantBitOne() public {
        assertEq(BitMath.mostSignificantBit(1), 0);
    }

    function testMostSignificantBitTwo() public {
        assertEq(BitMath.mostSignificantBit(2), 1);
    }

    function testMostSignificantBitPowersOfTwo() public {
        for (uint256 i = 0; i < 255; i++) {
            uint256 x = 1 << i;
            assertEq(BitMath.mostSignificantBit(x), i);
        }
    }

    function testMostSignificantBitMaxUint256() public {
        assertEq(BitMath.mostSignificantBit(type(uint256).max), 255);
    }

    function testMostSignificantBit(uint256 x) public {
        vm.assume(x != 0);
        assertEq(BitMath.mostSignificantBit(x), mostSignificantBitReference(x));
    }

    function testMsbGas() public {
        snapStart("BitMathTest#mostSignificantBitSmallNumber");
        BitMath.mostSignificantBit(3568);
        snapEnd();

        snapStart("BitMathTest#mostSignificantBitMaxUint128");
        BitMath.mostSignificantBit(type(uint128).max);
        snapEnd();

        snapStart("BitMathTest#mostSignificantBitMaxUint256");
        BitMath.mostSignificantBit(type(uint256).max);
        snapEnd();
    }

    function testLeastSignificantBitZero() public {
        vm.expectRevert();
        BitMath.leastSignificantBit(0);
    }

    function testLeastSignificantBitOne() public {
        assertEq(BitMath.leastSignificantBit(1), 0);
    }

    function testLeastSignificantBitTwo() public {
        assertEq(BitMath.leastSignificantBit(2), 1);
    }

    function testLeastSignificantBitPowersOfTwo() public {
        for (uint256 i = 0; i < 255; i++) {
            uint256 x = 1 << i;
            assertEq(BitMath.leastSignificantBit(x), i);
        }
    }

    function testLeastSignificantBitMaxUint256() public {
        assertEq(BitMath.leastSignificantBit(type(uint256).max), 0);
    }

    function testLeastSignificantBit(uint256 x) public {
        vm.assume(x != 0);
        assertEq(BitMath.leastSignificantBit(x), leastSignificantBitReference(x));
    }

    function testLsbGas() public {
        snapStart("BitMathTest#leastSignificantBitSmallNumber");
        BitMath.leastSignificantBit(3568);
        snapEnd();

        snapStart("BitMathTest#leastSignificantBitMaxUint128");
        BitMath.leastSignificantBit(type(uint128).max);
        snapEnd();

        snapStart("BitMathTest#leastSignificantBitMaxUint256");
        BitMath.leastSignificantBit(type(uint256).max);
        snapEnd();
    }

    function mostSignificantBitReference(uint256 x) private pure returns (uint256) {
        uint256 i = 0;
        while ((x >>= 1) > 0) {
            ++i;
        }
        return i;
    }

    function leastSignificantBitReference(uint256 x) private pure returns (uint256) {
        require(x > 0, "BitMath: zero has no least significant bit");

        uint256 i = 0;
        while ((x >> i) & 1 == 0) {
            ++i;
        }
        return i;
    }
}
