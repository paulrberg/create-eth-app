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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolId} from "../types/PoolId.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {Currency} from "../types/Currency.sol";
import {Position} from "./Position.sol";

library TransientStateLibrary {
    /// bytes32(uint256(keccak256("ReservesOf")) - 1)
    bytes32 public constant RESERVES_OF_SLOT = 0x1e0745a7db1623981f0b2a5d4232364c00787266eb75ad546f190e6cebe9bd95;

    // The slot holding the number of nonzero deltas. bytes32(uint256(keccak256("NonzeroDeltaCount")) - 1)
    bytes32 public constant NONZERO_DELTA_COUNT_SLOT =
        0x7d4b3164c6e45b97e7d87b7125a44c5828d005af88f9d751cfd78729c5d99a0b;

    // The slot holding the unlocked state, transiently. bytes32(uint256(keccak256("Unlocked")) - 1)
    bytes32 public constant IS_UNLOCKED_SLOT = 0xc090fc4683624cfc3884e9d8de5eca132f2d0ec062aff75d43c0465d5ceeab23;

    /// @notice returns the reserves of a currency
    /// @param manager The pool manager contract.
    /// @param currency The currency to get the reserves for.
    /// @return value The reserves of the currency.
    /// @dev returns 0 if the reserves are not synced
    /// @dev returns type(uint256).max if the reserves are synced but the value is 0
    function getReserves(IPoolManager manager, Currency currency) internal view returns (uint256) {
        bytes32 slot = RESERVES_OF_SLOT;
        bytes32 key;
        assembly {
            mstore(0, slot)
            mstore(32, currency)
            key := keccak256(0, 64)
        }
        return uint256(manager.exttload(key));
    }

    /// @notice Returns the number of nonzero deltas open on the PoolManager that must be zerod out before the contract is locked
    function getNonzeroDeltaCount(IPoolManager manager) internal view returns (uint256) {
        return uint256(manager.exttload(NONZERO_DELTA_COUNT_SLOT));
    }

    /// @notice Get the current delta for a caller in the given currency
    /// @param caller_ The address of the caller
    /// @param currency The currency for which to lookup the delta
    function currencyDelta(IPoolManager manager, address caller_, Currency currency) internal view returns (int256) {
        bytes32 key;
        assembly {
            mstore(0, caller_)
            mstore(32, currency)
            key := keccak256(0, 64)
        }
        return int256(uint256(manager.exttload(key)));
    }

    /// @notice Returns whether the contract is unlocked or not
    function isUnlocked(IPoolManager manager) internal view returns (bool) {
        return manager.exttload(IS_UNLOCKED_SLOT) != 0x0;
    }
}
