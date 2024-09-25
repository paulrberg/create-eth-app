/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MatchComponent, MatchComponentType} from "../../lib/types/MatchComponentType.sol";
import {
    MatchFulfillmentStorageLayout,
    FulfillmentHelperCounterLayout,
    AggregatableConsideration
} from "../lib/Structs.sol";
import {MATCH_FULFILLMENT_COUNTER_KEY, MATCH_FULFILLMENT_STORAGE_BASE_KEY} from "../lib/Constants.sol";

library MatchFulfillmentLayout {
    /**
     * @notice load storage layout for the current fulfillmentCounter
     */
    function getStorageLayout() internal view returns (MatchFulfillmentStorageLayout storage layout) {
        FulfillmentHelperCounterLayout storage counterLayout = getCounterLayout();
        uint256 counter = counterLayout.fulfillmentCounter;
        bytes32 storageLayoutKey = MATCH_FULFILLMENT_STORAGE_BASE_KEY;
        assembly {
            mstore(0, counter)
            mstore(0x20, storageLayoutKey)
            layout.slot := keccak256(0, 0x40)
        }
    }

    /**
     * @notice load storage layout for the counter itself
     */
    function getCounterLayout() internal pure returns (FulfillmentHelperCounterLayout storage layout) {
        bytes32 counterLayoutKey = MATCH_FULFILLMENT_COUNTER_KEY;
        assembly {
            layout.slot := counterLayoutKey
        }
    }

    /**
     * @notice increment the fulfillmentCounter to effectively clear the mappings and enumerations between calls
     */
    function incrementFulfillmentCounter() internal {
        FulfillmentHelperCounterLayout storage counterLayout = getCounterLayout();
        counterLayout.fulfillmentCounter += 1;
    }

    /**
     * @notice Get the mapping of tokens for a given key (offer or consideration), derived from the hash of the key and the current fulfillmentCounter value
     * @param key Original key used to derive the slot of the enumeration
     */
    function getMap(bytes32 key)
        internal
        view
        returns (
            mapping(
                address /*offererOrRecipient*/
                    => mapping(address /*tokenContract*/ => mapping(uint256 /*identifier*/ => MatchComponent[] /*components*/))
                ) storage map
        )
    {
        bytes32 counterKey = MATCH_FULFILLMENT_COUNTER_KEY;
        assembly {
            mstore(0, key)
            mstore(0x20, sload(counterKey))
            map.slot := keccak256(0, 0x40)
        }
    }

    /**
     * @notice Get the enumeration of AggregatableConsiderations for a given key (offer or consideration), derived from the hash of the key and the current fulfillmentCounter value
     * @param key Original key used to derive the slot of the enumeration
     */
    function getEnumeration(bytes32 key) internal view returns (AggregatableConsideration[] storage tokens) {
        bytes32 counterKey = MATCH_FULFILLMENT_COUNTER_KEY;
        assembly {
            mstore(0, key)
            mstore(0x20, sload(counterKey))
            tokens.slot := keccak256(0, 0x40)
        }
    }
}
