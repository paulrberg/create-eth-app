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
import {Encoded} from "../../../src/libraries/math/Encoded.sol";

contract EncodedTest is Test {
    using Encoded for bytes32;

    function testFuzz_Set(bytes32 x, uint256 v, uint256 mask, uint256 offset) external {
        bytes32 y = x.set(v, mask, offset);

        bytes32 expected = x;
        expected &= bytes32(~(mask << offset));
        expected |= bytes32((v & mask) << offset);

        assertEq(y, expected, "test_Set::1");
    }

    function testFuzz_Decode(bytes32 x, uint256 mask, uint256 offset) external {
        uint256 v = x.decode(mask, offset);
        assertEq(v, (uint256(x) >> offset) & mask, "test_Decode::1");
    }

    function testFuzz_SetAndDecode(bytes32 x, uint256 v, uint256 mask, uint256 offset) external {
        bytes32 y = x.set(v, mask, offset);
        uint256 v2 = y.decode(mask, offset);

        assertEq(v2, ((v << offset) >> offset) & mask, "test_SetAndDecode::1");
    }

    function testFuzz_decodeBool(bytes32 x, uint256 offset) external {
        bool v = x.decodeBool(offset);
        assertEq(v ? 1 : 0, (uint256(x) >> offset) & 1, "test_decodeUint1::1");
    }

    function testFuzz_decodeUint16(bytes32 x, uint256 offset) external {
        uint256 v = x.decodeUint16(offset);
        assertEq(v, (uint256(x) >> offset) & 0xffff, "test_decodeUint16::1");
    }

    function testFuzz_decodeUint24(bytes32 x, uint256 offset) external {
        uint256 v = x.decodeUint24(offset);
        assertEq(v, (uint256(x) >> offset) & 0xffffff, "test_decodeUint24::1");
    }

    function testFuzz_decodeUint64(bytes32 x, uint256 offset) external {
        uint256 v = x.decodeUint64(offset);
        assertEq(v, (uint256(x) >> offset) & 0xffffffffffffffff, "test_decodeUint64::1");
    }
}
