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

import {Currency} from "../types/Currency.sol";
import {IVault} from "../interfaces/IVault.sol";

/// @notice This is a workaround when transient keyword is absent. It manages:
///  - 0: address locker
///  - 1: uint256 unsettledDeltasCount
///  - 2: mapping(address, mapping(Currency => int256)) currencyDelta
library SettlementGuard {
    uint256 constant LOCKER_SLOT = uint256(keccak256("SETTLEMENT_LOCKER")) - 1;
    uint256 constant UNSETTLED_DELTAS_COUNT = uint256(keccak256("SETTLEMENT_UNSETTLEMENTD_DELTAS_COUNT")) - 1;
    uint256 constant CURRENCY_DELTA = uint256(keccak256("SETTLEMENT_CURRENCY_DELTA")) - 1;

    function setLocker(address newLocker) internal {
        address currentLocker = getLocker();

        // either set from non-zero to zero (set) or from zero to non-zero (reset)
        if (currentLocker == newLocker) return;
        if (currentLocker != address(0) && newLocker != address(0)) revert IVault.LockerAlreadySet(currentLocker);

        uint256 slot = LOCKER_SLOT;
        assembly {
            tstore(slot, newLocker)
        }
    }

    function getLocker() internal view returns (address locker) {
        uint256 slot = LOCKER_SLOT;
        assembly {
            locker := tload(slot)
        }
    }

    function getUnsettledDeltasCount() internal view returns (uint256 count) {
        uint256 slot = UNSETTLED_DELTAS_COUNT;
        assembly {
            count := tload(slot)
        }
    }

    function accountDelta(address settler, Currency currency, int256 newlyAddedDelta) internal {
        if (newlyAddedDelta == 0) return;

        uint256 slot = CURRENCY_DELTA;
        uint256 countSlot = UNSETTLED_DELTAS_COUNT;

        /// @dev update the count of non-zero deltas if necessary
        int256 currentDelta = getCurrencyDelta(settler, currency);
        int256 nextDelta = currentDelta + newlyAddedDelta;
        unchecked {
            if (nextDelta == 0) {
                assembly {
                    tstore(countSlot, sub(tload(countSlot), 1))
                }
            } else if (currentDelta == 0) {
                assembly {
                    tstore(countSlot, add(tload(countSlot), 1))
                }
            }
        }

        /// @dev ref: https://docs.soliditylang.org/en/v0.8.24/internals/layout_in_storage.html#mappings-and-dynamic-arrays
        /// simulating mapping index but with a single hash
        /// save one keccak256 hash compared to built-in nested mapping
        uint256 elementSlot = uint256(keccak256(abi.encode(settler, currency, slot)));
        assembly {
            tstore(elementSlot, nextDelta)
        }
    }

    function getCurrencyDelta(address settler, Currency currency) internal view returns (int256 delta) {
        uint256 slot = CURRENCY_DELTA;
        uint256 elementSlot = uint256(keccak256(abi.encode(settler, currency, slot)));
        assembly {
            delta := tload(elementSlot)
        }
    }
}
