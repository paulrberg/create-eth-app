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

import "../../src/libraries/LPFeeLibrary.sol";
import "Uniswap-V4/forge-std/Test.sol";

contract LPFeeLibraryTest is Test {
    function test_isDynamicFee_returnsTrue() public pure {
        uint24 dynamicFee = 0x800000;
        assertTrue(LPFeeLibrary.isDynamicFee(dynamicFee));
    }

    function test_isDynamicFee_returnsTrue_forMaxValue() public pure {
        uint24 dynamicFee = 0xFFFFFF;
        assertTrue(LPFeeLibrary.isDynamicFee(dynamicFee));
    }

    function test_isDynamicFee_returnsFalse() public pure {
        uint24 dynamicFee = 0x7FFFFF;
        assertFalse(LPFeeLibrary.isDynamicFee(dynamicFee));
    }

    function test_fuzz_isDynamicFee(uint24 fee) public pure {
        assertEq((fee >> 23 == 1), LPFeeLibrary.isDynamicFee(fee));
    }

    function test_validate_doesNotRevertWithNoFee() public pure {
        uint24 fee = 0;
        LPFeeLibrary.validate(fee);
    }

    function test_validate_doesNotRevert() public pure {
        uint24 fee = 500000; // 50%
        LPFeeLibrary.validate(fee);
    }

    function test_validate_doesNotRevertWithMaxFee() public pure {
        uint24 maxFee = 1000000; // 100%
        LPFeeLibrary.validate(maxFee);
    }

    function test_validate_revertsWithFeeTooLarge() public {
        uint24 fee = 1000001;
        vm.expectRevert(LPFeeLibrary.FeeTooLarge.selector);
        LPFeeLibrary.validate(fee);
    }

    function test_fuzz_validate(uint24 fee) public {
        if (fee > 1000000) {
            vm.expectRevert(LPFeeLibrary.FeeTooLarge.selector);
        }
        LPFeeLibrary.validate(fee);
    }

    function test_getInitialLPFee_forStaticFeeIsCorrect() public pure {
        uint24 staticFee = 3000; // 30 bps
        assertEq(LPFeeLibrary.getInitialLPFee(staticFee), staticFee);
    }

    function test_getInitialLPFee_revertsWithFeeTooLarge_forStaticFee() public {
        uint24 staticFee = 1000001;
        vm.expectRevert(LPFeeLibrary.FeeTooLarge.selector);
        LPFeeLibrary.getInitialLPFee(staticFee);
    }

    function test_getInitialLPFee_forDynamicFeeIsZero() public pure {
        uint24 dynamicFee = 0x800BB8;
        assertEq(LPFeeLibrary.getInitialLPFee(dynamicFee), 0);
    }

    function test_fuzz_getInitialLPFee(uint24 fee) public {
        if (fee >> 23 == 1) {
            assertEq(LPFeeLibrary.getInitialLPFee(fee), 0);
        } else if (fee > 1000000) {
            vm.expectRevert(LPFeeLibrary.FeeTooLarge.selector);
            LPFeeLibrary.getInitialLPFee(fee);
        } else {
            assertEq(LPFeeLibrary.getInitialLPFee(fee), fee);
        }
    }
}
