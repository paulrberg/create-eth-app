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
import {PackedUint128Math} from "../../../../src/pool-bin/libraries/math/PackedUint128Math.sol";
import {LiquidityConfigurations} from "../../../../src/pool-bin/libraries/math/LiquidityConfigurations.sol";

contract LiquidityConfigurationsTest is Test {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using LiquidityConfigurations for bytes32;

    function testFuzz_EncodeParams(uint64 distributionX, uint64 distributionY, uint24 id) external {
        bytes32 config = LiquidityConfigurations.encodeParams(distributionX, distributionY, id);

        assertEq(
            uint256(config),
            (uint256(distributionX) << 88) | (uint256(distributionY) << 24) | id,
            "testFuzz_EncodeParams::1"
        );
    }

    function testFuzz_DecodeParams(bytes32 config) external {
        uint64 distributionX = uint64(uint256(config) >> 88);
        uint64 distributionY = uint64(uint256(config) >> 24);
        uint24 id = uint24(uint256(config));

        if (uint256(config) > type(uint152).max || distributionX > 1e18 || distributionY > 1e18) {
            vm.expectRevert(LiquidityConfigurations.LiquidityConfigurations__InvalidConfig.selector);
        }

        (uint64 _distributionX, uint64 _distributionY, uint24 _id) = config.decodeParams();

        assertEq(_distributionX, distributionX, "testFuzz_DecodeParams::1");
        assertEq(_distributionY, distributionY, "testFuzz_DecodeParams::2");
        assertEq(_id, id, "testFuzz_DecodeParams::3");
    }

    function testFuzz_GetAmountsAndId(bytes32 config, bytes32 amounts) external {
        uint64 distributionX = uint64(uint256(config) >> 88);
        uint64 distributionY = uint64(uint256(config) >> 24);
        uint24 id = uint24(uint256(config));

        if (uint256(config) > type(uint152).max || distributionX > 1e18 || distributionY > 1e18) {
            vm.expectRevert(LiquidityConfigurations.LiquidityConfigurations__InvalidConfig.selector);
        }

        (distributionX, distributionY, id) = config.decodeParams();

        (uint128 x1, uint128 x2) = amounts.decode();

        uint128 y1 = uint128((uint256(x1) * distributionX) / 1e18);
        uint128 y2 = uint128((uint256(x2) * distributionY) / 1e18);

        bytes32 amountsInToBin = y1.encode(y2);

        (bytes32 _amountsInToBin, uint24 _id) = config.getAmountsAndId(amounts);

        assertEq(_amountsInToBin, amountsInToBin, "testFuzz_GetAmountsAndId::1");
        assertEq(_id, id, "testFuzz_GetAmountsAndId::2");
    }
}
