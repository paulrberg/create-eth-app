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
  
  // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {Test} from "Uniswap-V4/forge-std/Test.sol";

import {FeeLibrary} from "../../src/libraries/FeeLibrary.sol";

contract FeeLibraryTest is Test {
    function testIsDynamicFee() public {
        // 1000 0000 0000 0000 0000 0000
        assertEq(FeeLibrary.isDynamicFee(0x800000), true);

        // 0100 0000 0000 0000 0000 0000
        assertEq(FeeLibrary.isDynamicFee(0x400000), false);

        // 0010 0000 0000 0000 0000 0000
        assertEq(FeeLibrary.isDynamicFee(0x200000), false);

        // 0001 0000 0000 0000 0000 0000
        assertEq(FeeLibrary.isDynamicFee(0x100000), false);

        // 1111 1111 1111 1111 1111 1111
        assertEq(FeeLibrary.isDynamicFee(0xFFFFFF), true);

        // 0111 1111 1111 1111 1111 1111
        assertEq(FeeLibrary.isDynamicFee(0x7FFFF), false);
    }

    function testGetStaticFee() public {
        assertEq(FeeLibrary.getStaticFee(0x000001), 0x000001);
        assertEq(FeeLibrary.getStaticFee(0x000002), 0x000002);
        assertEq(FeeLibrary.getStaticFee(0x0F0003), 0x0F0003);
        assertEq(FeeLibrary.getStaticFee(0x001004), 0x001004);
        assertEq(FeeLibrary.getStaticFee(0xF00F05), 0x000F05);
        assertEq(FeeLibrary.getStaticFee(0x800310), 0x000310);
        assertEq(FeeLibrary.getStaticFee(0x111020), 0x011020);
        assertEq(FeeLibrary.getStaticFee(0x101020), 0x001020);
    }

    function testFuzzIsStaicFeeTooLarge(uint24 self, uint24 maxFee) public {
        assertEq(FeeLibrary.getStaticFee(self) >= maxFee, FeeLibrary.isStaticFeeTooLarge(self, maxFee));
    }
}
