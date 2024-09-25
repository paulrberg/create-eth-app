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
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Currency} from "../types/Currency.sol";

library Reserves {
    /// uint256(keccak256("ReservesOf")) - 1
    uint256 constant RESERVES_OF_SLOT = uint256(0x1e0745a7db1623981f0b2a5d4232364c00787266eb75ad546f190e6cebe9bd95);
    /// @notice The transient reserves for pools with no balance is set to the max as a sentinel to track that it has been synced.
    uint256 public constant ZERO_BALANCE = type(uint256).max;

    /// @notice Thrown when someone has not called sync before calling settle for the first time.
    error ReservesMustBeSynced();

    function setReserves(Currency currency, uint256 value) internal {
        if (value == 0) value = ZERO_BALANCE;
        bytes32 key = _getKey(currency);
        assembly {
            tstore(key, value)
        }
    }

    function getReserves(Currency currency) internal view returns (uint256 value) {
        bytes32 key = _getKey(currency);
        assembly {
            value := tload(key)
        }
        if (value == 0) revert ReservesMustBeSynced();
        if (value == ZERO_BALANCE) value = 0;
    }

    function _getKey(Currency currency) private pure returns (bytes32 key) {
        uint256 slot = RESERVES_OF_SLOT;
        assembly {
            mstore(0, slot)
            mstore(32, currency)
            key := keccak256(0, 64)
        }
    }
}
