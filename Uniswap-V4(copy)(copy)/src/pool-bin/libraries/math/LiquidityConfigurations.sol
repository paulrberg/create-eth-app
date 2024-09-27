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
  
  // SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.24;

import {PackedUint128Math} from "./PackedUint128Math.sol";
import {Encoded} from "../../../libraries/math/Encoded.sol";

/// @notice This library contains functions to encode and decode the config of a pool and interact with the encoded bytes32.
library LiquidityConfigurations {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Encoded for bytes32;

    error LiquidityConfigurations__InvalidConfig();

    uint256 private constant OFFSET_ID = 0;
    uint256 private constant OFFSET_DISTRIBUTION_Y = 24;
    uint256 private constant OFFSET_DISTRIBUTION_X = 88;

    uint256 private constant PRECISION = 1e18;

    /// @dev Encode the distributionX, distributionY and id into a single bytes32
    /// @param distributionX The distribution of the first token
    /// @param distributionY The distribution of the second token
    /// @param id The id of the pool
    /// @return config The encoded config as follows:
    /// [0 - 24[: id
    /// [24 - 88[: distributionY
    /// [88 - 152[: distributionX
    /// [152 - 256[: empty
    function encodeParams(uint64 distributionX, uint64 distributionY, uint24 id)
        internal
        pure
        returns (bytes32 config)
    {
        config = config.set(distributionX, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_X);
        config = config.set(distributionY, Encoded.MASK_UINT64, OFFSET_DISTRIBUTION_Y);
        config = config.set(id, Encoded.MASK_UINT24, OFFSET_ID);
    }

    /// @dev Decode the distributionX, distributionY and id from a single bytes32
    /// @param config The encoded config as follows:
    /// [0 - 24[: id
    /// [24 - 88[: distributionY
    /// [88 - 152[: distributionX
    /// [152 - 256[: empty
    /// @return distributionX The distribution of the first token
    /// @return distributionY The distribution of the second token
    /// @return id The id of the bin to add the liquidity to
    function decodeParams(bytes32 config)
        internal
        pure
        returns (uint64 distributionX, uint64 distributionY, uint24 id)
    {
        distributionX = config.decodeUint64(OFFSET_DISTRIBUTION_X);
        distributionY = config.decodeUint64(OFFSET_DISTRIBUTION_Y);
        id = config.decodeUint24(OFFSET_ID);

        if (uint256(config) > type(uint152).max || distributionX > PRECISION || distributionY > PRECISION) {
            revert LiquidityConfigurations__InvalidConfig();
        }
    }

    /// @dev Get the amounts and id from a config and amountsIn
    /// @param config The encoded config as follows:
    /// [0 - 24[: id
    /// [24 - 88[: distributionY
    /// [88 - 152[: distributionX
    /// [152 - 256[: empty
    /// @param amountsIn The amounts to distribute as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @return amounts The distributed amounts as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @return id The id of the bin to add the liquidity to
    function getAmountsAndId(bytes32 config, bytes32 amountsIn) internal pure returns (bytes32, uint24) {
        (uint64 distributionX, uint64 distributionY, uint24 id) = decodeParams(config);

        (uint128 x1, uint128 x2) = amountsIn.decode();

        assembly {
            x1 := div(mul(x1, distributionX), PRECISION)
            x2 := div(mul(x2, distributionY), PRECISION)
        }

        return (x1.encode(x2), id);
    }
}
