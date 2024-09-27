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

import {Uint128x128Math} from "./math/Uint128x128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";

/// @notice This library contains functions to calculate prices
library PriceHelper {
    using Uint128x128Math for uint256;
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    int256 private constant REAL_ID_SHIFT = 1 << 23;

    /// @dev Calculates the price from the id and the bin step
    /// @param id The id
    /// @param binStep The bin step
    /// @return price The price as a 128.128-binary fixed-point number
    function getPriceFromId(uint24 id, uint16 binStep) internal pure returns (uint256 price) {
        uint256 base = getBase(binStep);
        int256 exponent = getExponent(id);

        price = base.pow(exponent);
    }

    /// @dev Calculates the id from the price and the bin step
    /// @param price The price as a 128.128-binary fixed-point number
    /// @param binStep The bin step
    /// @return id The id
    function getIdFromPrice(uint256 price, uint16 binStep) internal pure returns (uint24 id) {
        uint256 base = getBase(binStep);
        int256 realId = price.log2() / base.log2();

        unchecked {
            id = uint256(REAL_ID_SHIFT + realId).safe24();
        }
    }

    /// @dev Calculates the base from the bin step, which is `1 + binStep / BASIS_POINT_MAX`
    /// @param binStep The bin step
    /// @return base The base
    function getBase(uint16 binStep) internal pure returns (uint256) {
        unchecked {
            return Constants.SCALE + (uint256(binStep) << Constants.SCALE_OFFSET) / Constants.BASIS_POINT_MAX;
        }
    }

    /// @dev Calculates the exponent from the id, which is `id - REAL_ID_SHIFT`
    /// @param id The id
    /// @return exponent The exponent
    function getExponent(uint24 id) internal pure returns (int256) {
        unchecked {
            return int256(uint256(id)) - REAL_ID_SHIFT;
        }
    }

    /// @dev Converts a price with 18 decimals to a 128.128-binary fixed-point number
    /// @param price The price with 18 decimals
    /// @return price128x128 The 128.128-binary fixed-point number
    function convertDecimalPriceTo128x128(uint256 price) internal pure returns (uint256) {
        return price.shiftDivRoundDown(Constants.SCALE_OFFSET, Constants.PRECISION);
    }

    /// @dev Converts a 128.128-binary fixed-point number to a price with 18 decimals
    /// @param price128x128 The 128.128-binary fixed-point number
    /// @return price The price with 18 decimals
    function convert128x128PriceToDecimal(uint256 price128x128) internal pure returns (uint256) {
        return price128x128.mulShiftRoundDown(Constants.PRECISION, Constants.SCALE_OFFSET);
    }
}
