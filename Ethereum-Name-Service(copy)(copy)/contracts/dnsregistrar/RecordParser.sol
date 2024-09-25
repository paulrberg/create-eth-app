/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../dnssec-oracle/BytesUtils.sol";

library RecordParser {
    using BytesUtils for bytes;

    /**
     * @dev Parses a key-value record into a key and value.
     * @param input The input string
     * @param offset The offset to start reading at
     */
    function readKeyValue(
        bytes memory input,
        uint256 offset,
        uint256 len
    )
        internal
        pure
        returns (bytes memory key, bytes memory value, uint256 nextOffset)
    {
        uint256 separator = input.find(offset, len, "=");
        if (separator == type(uint256).max) {
            return ("", "", type(uint256).max);
        }

        uint256 terminator = input.find(
            separator,
            len + offset - separator,
            " "
        );
        if (terminator == type(uint256).max) {
            terminator = input.length;
        }

        key = input.substring(offset, separator - offset);
        value = input.substring(separator + 1, terminator - separator - 1);
        nextOffset = terminator + 1;
    }
}
