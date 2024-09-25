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
import {Constants} from "../../../../src/pool-bin/libraries/Constants.sol";
import {PackedUint128Math} from "../../../../src/pool-bin/libraries/math/PackedUint128Math.sol";

contract PackedUint128MathTest is Test {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;

    function testFuzz_Encode(uint128 x1, uint128 x2) external {
        assertEq(bytes32(x1 | (uint256(x2) << 128)), x1.encode(x2), "testFuzz_Encode::1");
    }

    function testFuzz_EncodeFirst(uint128 x1) external {
        assertEq(bytes32(uint256(x1)), x1.encodeFirst(), "testFuzz_EncodeFirst::1");
    }

    function testFuzz_EncodeSecond(uint128 x2) external {
        assertEq(bytes32(uint256(x2) << 128), x2.encodeSecond(), "testFuzz_EncodeSecond::1");
    }

    function testFuzz_EncodeBool(uint128 x, bool first) external {
        assertEq(bytes32(uint256(x) << (first ? 0 : 128)), x.encode(first), "testFuzz_EncodeBool::1");
    }

    function testFuzz_Decode(bytes32 x) external {
        (uint128 x1, uint128 x2) = x.decode();

        assertEq(x1, uint128(uint256(x)), "testFuzz_Decode::1");
        assertEq(x2, uint128(uint256(x) >> 128), "testFuzz_Decode::2");
    }

    function testFuzz_decodeX(bytes32 x) external {
        assertEq(uint128(uint256(x)), x.decodeX(), "testFuzz_decodeX::1");
    }

    function testFuzz_decodeY(bytes32 x) external {
        assertEq(uint128(uint256(x) >> 128), x.decodeY(), "testFuzz_decodeY::1");
    }

    function testFuzz_DecodeBool(bytes32 x, bool first) external {
        assertEq(uint128(uint256(x) >> (first ? 0 : 128)), x.decode(first), "testFuzz_DecodeBool::1");
    }

    function test_AddSelf() external {
        bytes32 x = bytes32(uint256((1 << 128) | 1));

        assertEq(x.add(x), bytes32(uint256((2 << 128) | 2)), "testFuzz_AddSelf::1");
    }

    function test_AddOverflow() external {
        bytes32 x = bytes32(type(uint256).max);

        bytes32 y1 = bytes32(uint256(1));
        bytes32 y2 = bytes32(uint256(1 << 128));
        bytes32 y3 = y1 | y2;

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        x.add(y1);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        x.add(y2);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        x.add(y3);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        y1.add(x);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        y2.add(x);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        y3.add(x);
    }

    function testFuzz_Add(bytes32 x, bytes32 y) external {
        uint128 x1 = uint128(uint256(x));
        uint128 x2 = uint128(uint256(x >> 128));

        uint128 y1 = uint128(uint256(y));
        uint128 y2 = uint128(uint256(y >> 128));

        if (x1 <= type(uint128).max - y1 && x2 <= type(uint128).max - y2) {
            assertEq(x.add(y), bytes32(uint256(x1 + y1) | (uint256(x2 + y2) << 128)), "testFuzz_Add::1");
        } else {
            vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
            x.add(y);
        }
    }

    function test_SubSelf() external {
        bytes32 x = bytes32(uint256((1 << 128) | 1));

        assertEq(x.sub(x), bytes32(0), "testFuzz_SubSelf::1");
    }

    function test_SubUnderflow() external {
        bytes32 x = bytes32(0);

        bytes32 y1 = bytes32(uint256(1));
        bytes32 y2 = bytes32(uint256(1 << 128));
        bytes32 y3 = y1 | y2;

        assertEq(y1.sub(x), y1, "testFuzz_SubUnderflow::1");
        assertEq(y2.sub(x), y2, "testFuzz_SubUnderflow::2");
        assertEq(y3.sub(x), y3, "testFuzz_SubUnderflow::3");

        vm.expectRevert(PackedUint128Math.PackedUint128Math__SubUnderflow.selector);
        x.sub(y1);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__SubUnderflow.selector);
        x.sub(y2);

        vm.expectRevert(PackedUint128Math.PackedUint128Math__SubUnderflow.selector);
        x.sub(y3);
    }

    function testFuzz_Sub(bytes32 x, bytes32 y) external {
        uint128 x1 = uint128(uint256(x));
        uint128 x2 = uint128(uint256(x >> 128));

        uint128 y1 = uint128(uint256(y));
        uint128 y2 = uint128(uint256(y >> 128));

        if (x1 >= y1 && x2 >= y2) {
            assertEq(x.sub(y), bytes32(uint256(x1 - y1) | (uint256(x2 - y2) << 128)), "testFuzz_Sub::1");
        } else {
            vm.expectRevert(PackedUint128Math.PackedUint128Math__SubUnderflow.selector);
            x.sub(y);
        }
    }

    function testFuzz_LessThan(bytes32 x, bytes32 y) external {
        (uint128 x1, uint128 x2) = x.decode();
        (uint128 y1, uint128 y2) = y.decode();

        assertEq(x.lt(y), x1 < y1 || x2 < y2, "testFuzz_LessThan::1");
    }

    function testFuzz_GreaterThan(bytes32 x, bytes32 y) external {
        (uint128 x1, uint128 x2) = x.decode();
        (uint128 y1, uint128 y2) = y.decode();

        assertEq(x.gt(y), x1 > y1 || x2 > y2, "testFuzz_GreaterThan::1");
    }

    function testFuzz_getExternalFeeAmt(bytes32 x, uint16 fee) external {
        (uint128 x1, uint128 x2) = x.decode();

        if (fee == 0) {
            assertEq(x.getExternalFeeAmt(fee), 0);
        } else {
            uint16 fee0 = fee % 256;
            uint16 fee1 = fee >> 8;

            uint128 x1Fee = fee0 > 0 ? x1 / fee0 : 0;
            uint128 x2Fee = fee1 > 0 ? x2 / fee1 : 0;
            assertEq(x.getExternalFeeAmt(fee), uint128(x1Fee).encode(uint128(x2Fee)));
        }
    }

    function test_getExternalFeeAmt() external {
        {
            // 0% fee
            bytes32 x = uint128(100).encode(uint128(100));
            uint16 fee = (0 << 8) + 0; // amt / 0 = 0%
            assertEq(x.getExternalFeeAmt(fee), 0);
        }

        {
            // 20% fee
            bytes32 x = uint128(100).encode(uint128(100));
            uint16 fee = (5 << 8) + 5; // amt / 5 = 20%
            assertEq(x.getExternalFeeAmt(fee), uint128(20).encode(uint128(20)));
        }

        {
            // 100% fee
            bytes32 x = uint128(100).encode(uint128(100));
            uint16 fee = (1 << 8) + 1; // amt / 1 = 100%
            assertEq(x.getExternalFeeAmt(fee), x);
        }
    }
}
