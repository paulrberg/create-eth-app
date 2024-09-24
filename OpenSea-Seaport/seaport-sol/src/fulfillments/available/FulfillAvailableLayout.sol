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
    FulfillAvailableHelperStorageLayout,
    FulfillmentHelperCounterLayout,
    AggregatableConsideration,
    AggregatableOffer
} from "../lib/Structs.sol";
import {FULFILL_AVAILABLE_COUNTER_KEY, FULFILL_AVAILABLE_STORAGE_BASE_KEY} from "../lib/Constants.sol";

library FulfillAvailableLayout {
    /**
     * @notice Check if a token already exists in a mapping by checking the length of the array at that slot
     * @param token token to check
     * @param layout storage layout
     */
    function aggregatableConsiderationExists(
        AggregatableConsideration memory token,
        FulfillAvailableHelperStorageLayout storage layout
    ) internal view returns (bool) {
        return layout.considerationMap[token.recipient][token.contractAddress][token.tokenId].length > 0;
    }

    /**
     * @notice Check if an entry into the offer component mapping already exists by checking its length
     */
    function aggregatableOfferExists(AggregatableOffer memory offer, FulfillAvailableHelperStorageLayout storage layout)
        internal
        view
        returns (bool)
    {
        return layout.offerMap[offer.contractAddress][offer.tokenId][offer.offerer][offer.conduitKey].length > 0;
    }

    /**
     * @notice load storage layout for the current fulfillmentCounter
     */
    function getStorageLayout() internal view returns (FulfillAvailableHelperStorageLayout storage layout) {
        FulfillmentHelperCounterLayout storage counterLayout = getCounterLayout();
        uint256 counter = counterLayout.fulfillmentCounter;
        bytes32 storageLayoutKey = FULFILL_AVAILABLE_STORAGE_BASE_KEY;
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
        bytes32 counterLayoutKey = FULFILL_AVAILABLE_COUNTER_KEY;
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
        bytes32 counterKey = FULFILL_AVAILABLE_COUNTER_KEY;
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
        bytes32 counterKey = FULFILL_AVAILABLE_COUNTER_KEY;
        assembly {
            mstore(0, key)
            mstore(0x20, sload(counterKey))
            tokens.slot := keccak256(0, 0x40)
        }
    }
}
