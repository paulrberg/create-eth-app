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

import {Constants} from "../Constants.sol";

/// @notice This library contains functions to encode and decode two uint128 into a single bytes32
///         and interact with the encoded bytes32.
library PackedUint128Math {
    error PackedUint128Math__AddOverflow();
    error PackedUint128Math__SubUnderflow();

    uint256 private constant OFFSET = 128;
    uint256 private constant MASK_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MASK_128_PLUS_ONE = MASK_128 + 1;

    /// @dev Encodes two uint128 into a single bytes32
    /// @param x1 The first uint128
    /// @param x2 The second uint128
    /// @return z The encoded bytes32 as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    function encode(uint128 x1, uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := or(and(x1, MASK_128), shl(OFFSET, x2))
        }
    }

    /// @dev Encodes a uint128 into a single bytes32 as the first uint128
    /// @param x1 The uint128
    /// @return z The encoded bytes32 as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: empty
    function encodeFirst(uint128 x1) internal pure returns (bytes32 z) {
        assembly {
            z := and(x1, MASK_128)
        }
    }

    /// @dev Encodes a uint128 into a single bytes32 as the second uint128
    /// @param x2 The uint128
    // @return z The encoded bytes32 as follows:
    /// [0 - 128[: empty
    /// [128 - 256[: x2
    function encodeSecond(uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := shl(OFFSET, x2)
        }
    }

    /// @dev Encodes a uint128 into a single bytes32 as the first or second uint128
    /// @param x The uint128
    /// @param first Whether to encode as the first or second uint128
    /// @return z The encoded bytes32 as follows:
    /// if first:
    /// [0 - 128[: x
    /// [128 - 256[: empty
    /// else:
    /// [0 - 128[: empty
    /// [128 - 256[: x
    function encode(uint128 x, bool first) internal pure returns (bytes32 z) {
        return first ? encodeFirst(x) : encodeSecond(x);
    }

    /// @dev Decodes a bytes32 into two uint128
    /// @param z The encoded bytes32 as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @return x1 The first uint128
    /// @return x2 The second uint128
    function decode(bytes32 z) internal pure returns (uint128 x1, uint128 x2) {
        assembly {
            x1 := and(z, MASK_128)
            x2 := shr(OFFSET, z)
        }
    }

    /// @dev Decodes a bytes32 into a uint128 as the first uint128
    /// @param z The encoded bytes32 as follows:
    /// [0 - 128[: x
    /// [128 - 256[: any
    /// @return x The first uint128
    function decodeX(bytes32 z) internal pure returns (uint128 x) {
        assembly {
            x := and(z, MASK_128)
        }
    }

    /// @dev Decodes a bytes32 into a uint128 as the second uint128
    /// @param z The encoded bytes32 as follows:
    /// [0 - 128[: any
    /// [128 - 256[: y
    /// @return y The second uint128
    function decodeY(bytes32 z) internal pure returns (uint128 y) {
        assembly {
            y := shr(OFFSET, z)
        }
    }

    /// @dev Decodes a bytes32 into a uint128 as the first or second uint128
    /// @param z The encoded bytes32 as follows:
    /// if first:
    ///   [0 - 128[: x1
    ///   [128 - 256[: empty
    /// else:
    ///   [0 - 128[: empty
    ///  [128 - 256[: x2
    /// @param first Whether to decode as the first or second uint128
    /// @return x The decoded uint128
    function decode(bytes32 z, bool first) internal pure returns (uint128 x) {
        return first ? decodeX(z) : decodeY(z);
    }

    /// @dev Adds two encoded bytes32, reverting on overflow on any of the uint128
    /// @param x The first bytes32 encoded as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @param y The second bytes32 encoded as follows:
    /// [0 - 128[: y1
    /// [128 - 256[: y2
    /// @return z The sum of x and y encoded as follows:
    /// [0 - 128[: x1 + y1
    /// [128 - 256[: x2 + y2
    function add(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := add(x, y)
        }

        if (z < x || uint128(uint256(z)) < uint128(uint256(x))) {
            revert PackedUint128Math__AddOverflow();
        }
    }

    /// @dev Adds an encoded bytes32 and two uint128, reverting on overflow on any of the uint128
    /// @param x The bytes32 encoded as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @param y1 The first uint128
    /// @param y2 The second uint128
    /// @return z The sum of x and y encoded as follows:
    /// [0 - 128[: x1 + y1
    /// [128 - 256[: x2 + y2
    function add(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return add(x, encode(y1, y2));
    }

    /// @dev Subtracts two encoded bytes32, reverting on underflow on any of the uint128
    /// @param x The first bytes32 encoded as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @param y The second bytes32 encoded as follows:
    /// [0 - 128[: y1
    /// [128 - 256[: y2
    /// @return z The difference of x and y encoded as follows:
    /// [0 - 128[: x1 - y1
    /// [128 - 256[: x2 - y2
    function sub(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := sub(x, y)
        }

        if (z > x || uint128(uint256(z)) > uint128(uint256(x))) {
            revert PackedUint128Math__SubUnderflow();
        }
    }

    /// @dev Subtracts an encoded bytes32 and two uint128, reverting on underflow on any of the uint128
    /// @param x The bytes32 encoded as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @param y1 The first uint128
    /// @param y2 The second uint128
    /// @return z The difference of x and y encoded as follows:
    /// [0 - 128[: x1 - y1
    /// [128 - 256[: x2 - y2
    function sub(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return sub(x, encode(y1, y2));
    }

    /// @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
    /// @param x The first bytes32 encoded as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @param y The second bytes32 encoded as follows:
    /// [0 - 128[: y1
    /// [128 - 256[: y2
    /// @return x1 < y1 || x2 < y2
    function lt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 < y1 || x2 < y2;
    }

    /// @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
    /// @param x The first bytes32 encoded as follows:
    /// [0 - 128[: x1
    /// [128 - 256[: x2
    /// @param y The second bytes32 encoded as follows:
    /// [0 - 128[: y1
    /// [128 - 256[: y2
    /// @return x1 < y1 || x2 < y2
    function gt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 > y1 || x2 > y2;
    }

    /// @dev given amount and protocolFee, calculate and return external protocol fee amt
    /// @param amount encoded bytes with (x, y)
    /// @param fee protocolFee
    function getExternalFeeAmt(bytes32 amount, uint16 fee) internal pure returns (bytes32 z) {
        if (fee == 0) return 0;

        (uint128 amountX, uint128 amountY) = decode(amount);

        uint16 fee0 = fee % 256;
        uint16 fee1 = fee >> 8;

        uint128 feeForX = fee0 == 0 ? 0 : amountX / fee0;
        uint128 feeForY = fee1 == 0 ? 0 : amountY / fee1;

        return encode(feeForX, feeForY);
    }
}
