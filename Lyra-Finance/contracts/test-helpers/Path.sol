/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "./BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library Path {
  using BytesLib for bytes;

  /// @dev The length of the bytes encoded address
  uint private constant ADDR_SIZE = 20;
  /// @dev The length of the bytes encoded fee
  uint private constant FEE_SIZE = 3;

  /// @dev The offset of a single token address and pool fee
  uint private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
  /// @dev The offset of an encoded pool key
  uint private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
  /// @dev The minimum length of an encoding that contains 2 or more pools
  uint private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

  /// @notice Returns true iff the path contains two or more pools
  /// @param path The encoded swap path
  /// @return True if path contains two or more pools, otherwise false
  function hasMultiplePools(bytes memory path) internal pure returns (bool) {
    return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
  }

  /// @notice Returns the number of pools in the path
  /// @param path The encoded swap path
  /// @return The number of pools in the path
  function numPools(bytes memory path) internal pure returns (uint) {
    // Ignore the first token address. From then on every fee and token offset indicates a pool.
    return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
  }

  /// @notice Decodes the first pool in path
  /// @param path The bytes encoded swap path
  /// @return tokenA The first token of the given pool
  /// @return tokenB The second token of the given pool
  /// @return fee The fee level of the pool
  function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
    tokenA = path.toAddress(0);
    fee = path.toUint24(ADDR_SIZE);
    tokenB = path.toAddress(NEXT_OFFSET);
  }

  /// @notice Gets the segment corresponding to the first pool in the path
  /// @param path The bytes encoded swap path
  /// @return The segment containing all data necessary to target the first pool in the path
  function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(0, POP_OFFSET);
  }

  /// @notice Skips a token + fee element from the buffer and returns the remainder
  /// @param path The swap path
  /// @return The remaining token + fee elements in the path
  function skipToken(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
  }
}
