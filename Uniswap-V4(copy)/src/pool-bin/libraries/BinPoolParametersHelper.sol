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

import {Encoded} from "../../libraries/math/Encoded.sol";

/// @title Bin Pool Pair Parameter Helper Library
/// @dev This library contains functions to get and set parameters of a pair
/// The parameters are stored in a single bytes32 variable in the following format:
/// [0 - 16[: reserve for hooks
/// [16 - 31[: binStep (16 bits)
library BinPoolParametersHelper {
    using Encoded for bytes32;

    uint256 internal constant OFFSET_BIN_STEP = 16;

    /// @dev Get binstep from the encoded pair parameters
    /// @param params The encoded pair parameters, as follows:
    /// [0 - 15[: bitmap for hooks registration
    /// [16 - 31[: binSteps (16 bits)
    /// [32 - 256[: other parameters
    /// @return binStep The binStep
    function getBinStep(bytes32 params) internal pure returns (uint16 binStep) {
        binStep = params.decodeUint16(OFFSET_BIN_STEP);
    }

    /**
     * @dev Helper method to set bin step in the encoded pair parameter
     * @return The new encoded pair parameter
     */
    function setBinStep(bytes32 params, uint16 binStep) external pure returns (bytes32) {
        return params.set(binStep, Encoded.MASK_UINT16, OFFSET_BIN_STEP);
    }
}
