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
import {Uint128x128Math} from "../../../../src/pool-bin/libraries/math/Uint128x128Math.sol";

contract Uint128x128MathTest is Test {
    using Uint128x128Math for uint256;

    function test_Pow() external {
        uint256 res = _toUint128x128(1.0001e18).pow(100_000);

        assertApproxEqRel(_toUint256(res), 22015.456048527954e18, 1e12, "test_Pow::1");
    }

    function test_PowAndLog() external {
        uint256 base = _toUint128x128(1.0001e18);
        uint256 res = base.pow(100_000);

        int256 baselog2 = base.log2();

        assertGt(baselog2, 0, "test_PowAndLog::1");
        assertApproxEqRel(res.log2() / baselog2, 100_000, 1e12, "test_PowAndLog::2");
    }

    function _toUint128x128(uint256 x) internal pure returns (uint256) {
        return (x << 128) / 1e18;
    }

    function _toUint256(uint256 x) internal pure returns (uint256) {
        return (x * 1e18) >> 128;
    }

    function _abs(int256 x) internal pure returns (uint256) {
        return x < 0 ? uint256(-x) : uint256(x);
    }
}
