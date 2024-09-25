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
import {BitMath} from "../../../../src/pool-bin/libraries/math/BitMath.sol";

contract BitMathTest is Test {
    using BitMath for uint256;

    function test_MostSignificantBit() external {
        for (uint256 i = 0; i < 256; i++) {
            assertEq(uint256(1 << i).mostSignificantBit(), i, "test_MostSignificantBit::1");
        }
    }

    function testFuzz_MostSignificantBit(uint256 x) external {
        uint256 msb = x.mostSignificantBit();

        if (x == 0) {
            assertEq(msb, 0, "testFuzz_MostSignificantBit::1");
        } else {
            assertEq(x >> msb, 1, "testFuzz_MostSignificantBit::2");
        }
    }

    function test_LeastSignificantBit() external {
        for (uint256 i = 0; i < 256; i++) {
            assertEq(uint256(1 << i).leastSignificantBit(), i, "test_LeastSignificantBit::1");
        }
    }

    function testFuzz_LeastSignificantBit(uint256 x) external {
        uint256 lsb = x.leastSignificantBit();

        if (x == 0) {
            assertEq(lsb, 255, "testFuzz_LeastSignificantBit::1");
        } else {
            assertEq(x << (255 - lsb), 1 << 255, "testFuzz_LeastSignificantBit::2");
        }
    }

    function test_ClosestBitRight() external {
        for (uint256 i = 0; i < 256; i++) {
            assertEq(uint256(1 << i).closestBitRight(255), i, "test_ClosestBitRight::1");
        }
    }

    function testFuzz_ClosestBitRight(uint256 x, uint8 bit) external {
        uint256 cbr = x.closestBitRight(bit);

        if (cbr == type(uint256).max) {
            assertEq(x << (255 - bit), 0, "testFuzz_ClosestBitRight::1");
        } else {
            assertLe(cbr, bit, "testFuzz_ClosestBitRight::2");
            assertGe(x << (255 - cbr), 1 << 255, "testFuzz_ClosestBitRight::3");
        }
    }

    function test_ClosestBitLeft() external {
        for (uint256 i = 0; i < 256; i++) {
            assertEq(uint256(1 << i).closestBitLeft(0), i, "test_ClosestBitLeft::1");
        }
    }

    function testFuzz_ClosestBitLeft(uint256 x, uint8 bit) external {
        uint256 cbl = x.closestBitLeft(bit);

        if (cbl == type(uint256).max) {
            assertEq(x >> bit, 0, "testFuzz_ClosestBitLeft::1");
        } else {
            assertGe(cbl, bit, "testFuzz_ClosestBitLeft::2");
            assertGe(x >> cbl, 1, "testFuzz_ClosestBitLeft::3");
        }
    }
}
