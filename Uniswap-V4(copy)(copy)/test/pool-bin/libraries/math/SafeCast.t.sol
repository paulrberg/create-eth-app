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
import {SafeCast} from "../../../../src/pool-bin/libraries/math/SafeCast.sol";

contract SafeCastTest is Test {
    using SafeCast for uint256;
    using SafeCast for uint128;

    function testFuzz_SafeCast248(uint256 x) external {
        if (x > type(uint248).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds248Bits.selector);
            x.safe248();
        } else {
            assertEq(x.safe248(), uint248(x), "testFuzz_SafeCast248::1");
        }
    }

    function testFuzz_SafeCast240(uint256 x) external {
        if (x > type(uint240).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds240Bits.selector);
            x.safe240();
        } else {
            assertEq(x.safe240(), uint240(x), "testFuzz_SafeCast240::1");
        }
    }

    function testFuzz_SafeCast232(uint256 x) external {
        if (x > type(uint232).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds232Bits.selector);
            x.safe232();
        } else {
            assertEq(x.safe232(), uint232(x), "testFuzz_SafeCast232::1");
        }
    }

    function testFuzz_SafeCast224(uint256 x) external {
        if (x > type(uint224).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds224Bits.selector);
            x.safe224();
        } else {
            assertEq(x.safe224(), uint224(x), "testFuzz_SafeCast224::1");
        }
    }

    function testFuzz_SafeCast216(uint256 x) external {
        if (x > type(uint216).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds216Bits.selector);
            x.safe216();
        } else {
            assertEq(x.safe216(), uint216(x), "testFuzz_SafeCast216::1");
        }
    }

    function testFuzz_SafeCast208(uint256 x) external {
        if (x > type(uint208).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds208Bits.selector);
            x.safe208();
        } else {
            assertEq(x.safe208(), uint208(x), "testFuzz_SafeCast208::1");
        }
    }

    function testFuzz_SafeCast200(uint256 x) external {
        if (x > type(uint200).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds200Bits.selector);
            x.safe200();
        } else {
            assertEq(x.safe200(), uint200(x), "testFuzz_SafeCast200::1");
        }
    }

    function testFuzz_SafeCast192(uint256 x) external {
        if (x > type(uint192).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds192Bits.selector);
            x.safe192();
        } else {
            assertEq(x.safe192(), uint192(x), "testFuzz_SafeCast192::1");
        }
    }

    function testFuzz_SafeCast184(uint256 x) external {
        if (x > type(uint184).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds184Bits.selector);
            x.safe184();
        } else {
            assertEq(x.safe184(), uint184(x), "testFuzz_SafeCast184::1");
        }
    }

    function testFuzz_SafeCast176(uint256 x) external {
        if (x > type(uint176).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds176Bits.selector);
            x.safe176();
        } else {
            assertEq(x.safe176(), uint176(x), "testFuzz_SafeCast176::1");
        }
    }

    function testFuzz_SafeCast168(uint256 x) external {
        if (x > type(uint168).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds168Bits.selector);
            x.safe168();
        } else {
            assertEq(x.safe168(), uint168(x), "testFuzz_SafeCast168::1");
        }
    }

    function testFuzz_SafeCast160(uint256 x) external {
        if (x > type(uint160).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds160Bits.selector);
            x.safe160();
        } else {
            assertEq(x.safe160(), uint160(x), "testFuzz_SafeCast160::1");
        }
    }

    function testFuzz_SafeCast152(uint256 x) external {
        if (x > type(uint152).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds152Bits.selector);
            x.safe152();
        } else {
            assertEq(x.safe152(), uint152(x), "testFuzz_SafeCast152::1");
        }
    }

    function testFuzz_SafeCast144(uint256 x) external {
        if (x > type(uint144).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds144Bits.selector);
            x.safe144();
        } else {
            assertEq(x.safe144(), uint144(x), "testFuzz_SafeCast144::1");
        }
    }

    function testFuzz_SafeCast136(uint256 x) external {
        if (x > type(uint136).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds136Bits.selector);
            x.safe136();
        } else {
            assertEq(x.safe136(), uint136(x), "testFuzz_SafeCast136::1");
        }
    }

    function testFuzz_SafeCast128(uint256 x) external {
        if (x > type(uint128).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds128Bits.selector);
            x.safe128();
        } else {
            assertEq(x.safe128(), uint128(x), "testFuzz_SafeCast128::1");
        }
    }

    function testFuzz_SafeCast120(uint256 x) external {
        if (x > type(uint120).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds120Bits.selector);
            x.safe120();
        } else {
            assertEq(x.safe120(), uint120(x), "testFuzz_SafeCast120::1");
        }
    }

    function testFuzz_SafeCast112(uint256 x) external {
        if (x > type(uint112).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds112Bits.selector);
            x.safe112();
        } else {
            assertEq(x.safe112(), uint112(x), "testFuzz_SafeCast112::1");
        }
    }

    function testFuzz_SafeCast104(uint256 x) external {
        if (x > type(uint104).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds104Bits.selector);
            x.safe104();
        } else {
            assertEq(x.safe104(), uint104(x), "testFuzz_SafeCast104::1");
        }
    }

    function testFuzz_SafeCast96(uint256 x) external {
        if (x > type(uint96).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds96Bits.selector);
            x.safe96();
        } else {
            assertEq(x.safe96(), uint96(x), "testFuzz_SafeCast96::1");
        }
    }

    function testFuzz_SafeCast88(uint256 x) external {
        if (x > type(uint88).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds88Bits.selector);
            x.safe88();
        } else {
            assertEq(x.safe88(), uint88(x), "testFuzz_SafeCast88::1");
        }
    }

    function testFuzz_SafeCast80(uint256 x) external {
        if (x > type(uint80).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds80Bits.selector);
            x.safe80();
        } else {
            assertEq(x.safe80(), uint80(x), "testFuzz_SafeCast80::1");
        }
    }

    function testFuzz_SafeCast72(uint256 x) external {
        if (x > type(uint72).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds72Bits.selector);
            x.safe72();
        } else {
            assertEq(x.safe72(), uint72(x), "testFuzz_SafeCast72::1");
        }
    }

    function testFuzz_SafeCast64(uint256 x) external {
        if (x > type(uint64).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds64Bits.selector);
            x.safe64();
        } else {
            assertEq(x.safe64(), uint64(x), "testFuzz_SafeCast64::1");
        }
    }

    function testFuzz_SafeCast56(uint256 x) external {
        if (x > type(uint56).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds56Bits.selector);
            x.safe56();
        } else {
            assertEq(x.safe56(), uint56(x), "testFuzz_SafeCast56::1");
        }
    }

    function testFuzz_SafeCast48(uint256 x) external {
        if (x > type(uint48).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds48Bits.selector);
            x.safe48();
        } else {
            assertEq(x.safe48(), uint48(x), "testFuzz_SafeCast48::1");
        }
    }

    function testFuzz_SafeCast40(uint256 x) external {
        if (x > type(uint40).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds40Bits.selector);
            x.safe40();
        } else {
            assertEq(x.safe40(), uint40(x), "testFuzz_SafeCast40::1");
        }
    }

    function testFuzz_SafeCast32(uint256 x) external {
        if (x > type(uint32).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds32Bits.selector);
            x.safe32();
        } else {
            assertEq(x.safe32(), uint32(x), "testFuzz_SafeCast32::1");
        }
    }

    function testFuzz_SafeCast24(uint256 x) external {
        if (x > type(uint24).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds24Bits.selector);
            x.safe24();
        } else {
            assertEq(x.safe24(), uint24(x), "testFuzz_SafeCast24::1");
        }
    }

    function testFuzz_SafeCast16(uint256 x) external {
        if (x > type(uint16).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds16Bits.selector);
            x.safe16();
        } else {
            assertEq(x.safe16(), uint16(x), "testFuzz_SafeCast16::1");
        }
    }

    function testFuzz_SafeCast8(uint256 x) external {
        if (x > type(uint8).max) {
            vm.expectRevert(SafeCast.SafeCast__Exceeds8Bits.selector);
            x.safe8();
        } else {
            assertEq(x.safe8(), uint8(x), "testFuzz_SafeCast8::1");
        }
    }

    function testFuzz_SafeCastInt128(uint128 x) external {
        if (x > uint128(type(int128).max)) {
            vm.expectRevert(SafeCast.SafeCastOverflow.selector);
        }

        assertEq(x.safeInt128(), int128(x), "testFuzz_SafeCastInt128::1");
    }
}
