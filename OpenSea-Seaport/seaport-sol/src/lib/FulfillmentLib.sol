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

import {
    Fulfillment,
    FulfillmentComponent
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { FulfillmentComponentLib } from "./FulfillmentComponentLib.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title FulfillmentLib
 * @author James Wenzel (emo.eth)
 * @notice FulfillmentLib is a library for managing Fulfillment structs and
 *         arrays. It allows chaining of functions to make struct creation more
 *         readable.
 */
library FulfillmentLib {
    bytes32 private constant FULFILLMENT_MAP_POSITION =
        keccak256("seaport.FulfillmentDefaults");
    bytes32 private constant FULFILLMENTS_MAP_POSITION =
        keccak256("seaport.FulfillmentsDefaults");

    using FulfillmentComponentLib for FulfillmentComponent[];
    using StructCopier for FulfillmentComponent[];

    /**
     * @dev Clears a default Fulfillment from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => Fulfillment)
            storage fulfillmentMap = _fulfillmentMap();
        Fulfillment storage _fulfillment = fulfillmentMap[defaultName];
        // clear all fields
        FulfillmentComponent[] memory components;
        _fulfillment.offerComponents.setFulfillmentComponents(components);
        _fulfillment.considerationComponents.setFulfillmentComponents(
            components
        );
    }

    /**
     * @dev Gets a default Fulfillment from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the Fulfillment retrieved from storage
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (Fulfillment memory item) {
        mapping(string => Fulfillment)
            storage fulfillmentMap = _fulfillmentMap();
        item = fulfillmentMap[defaultName];
    }

    /**
     * @dev Gets a default Fulfillment array from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the Fulfillment array retrieved from storage
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (Fulfillment[] memory items) {
        mapping(string => Fulfillment[])
            storage fulfillmentsMap = _fulfillmentsMap();
        items = fulfillmentsMap[defaultName];
    }

    /**
     * @dev Saves a Fulfillment as a named default.
     *
     * @param fulfillment the Fulfillment to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _fulfillment the Fulfillment saved as a default
     */
    function saveDefault(
        Fulfillment memory fulfillment,
        string memory defaultName
    ) internal returns (Fulfillment memory _fulfillment) {
        mapping(string => Fulfillment)
            storage fulfillmentMap = _fulfillmentMap();
        StructCopier.setFulfillment(fulfillmentMap[defaultName], fulfillment);

        return fulfillment;
    }

    /**
     * @dev Saves a Fulfillment array as a named default.
     *
     * @param fulfillments the Fulfillment array to save as a default
     * @param defaultName  the name of the default for retrieval
     *
     * @return _fulfillments the Fulfillment array saved as a default
     */
    function saveDefaultMany(
        Fulfillment[] memory fulfillments,
        string memory defaultName
    ) internal returns (Fulfillment[] memory _fulfillments) {
        mapping(string => Fulfillment[])
            storage fulfillmentsMap = _fulfillmentsMap();
        StructCopier.setFulfillments(
            fulfillmentsMap[defaultName],
            fulfillments
        );
        return fulfillments;
    }

    /**
     * @dev Makes a copy of a Fulfillment in-memory.
     *
     * @param _fulfillment the Fulfillment to make a copy of in-memory
     *
     * @custom:return copiedFulfillment the copied Fulfillment
     */
    function copy(
        Fulfillment memory _fulfillment
    ) internal pure returns (Fulfillment memory) {
        return
            Fulfillment({
                offerComponents: _fulfillment.offerComponents.copy(),
                considerationComponents: _fulfillment
                    .considerationComponents
                    .copy()
            });
    }

    /**
     * @dev Makes a copy of a Fulfillment array in-memory.
     *
     * @param _fulfillments the Fulfillment array to make a copy of in-memory
     *
     * @custom:return copiedFulfillments the copied Fulfillment array
     */
    function copy(
        Fulfillment[] memory _fulfillments
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory copiedItems = new Fulfillment[](
            _fulfillments.length
        );
        for (uint256 i = 0; i < _fulfillments.length; i++) {
            copiedItems[i] = copy(_fulfillments[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Creates an empty Fulfillment in-memory.
     *
     * @custom:return emptyFulfillment the empty Fulfillment
     */
    function empty() internal pure returns (Fulfillment memory) {
        FulfillmentComponent[] memory components;
        return
            Fulfillment({
                offerComponents: components,
                considerationComponents: components
            });
    }

    /**
     * @dev Gets the storage position of the default Fulfillment map
     *
     * @return fulfillmentMap the storage position of the default Fulfillment
     *                        map
     */
    function _fulfillmentMap()
        private
        pure
        returns (mapping(string => Fulfillment) storage fulfillmentMap)
    {
        bytes32 position = FULFILLMENT_MAP_POSITION;
        assembly {
            fulfillmentMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default Fulfillment array map
     *
     * @return fulfillmentsMap the storage position of the default Fulfillment
     *                         array map
     */
    function _fulfillmentsMap()
        private
        pure
        returns (mapping(string => Fulfillment[]) storage fulfillmentsMap)
    {
        bytes32 position = FULFILLMENTS_MAP_POSITION;
        assembly {
            fulfillmentsMap.slot := position
        }
    }

    // Methods for configuring a single of each of a Fulfillment's fields, which
    // modify the FulfillmentComponent in-place and return it.

    /**
     * @dev Sets the offer components of a Fulfillment in-place.
     *
     * @param _fulfillment the Fulfillment to set the offer components of
     * @param components   the FulfillmentComponent array to set as the offer
     *                     components
     *
     * @custom:return _fulfillment the Fulfillment with the offer components set
     */
    function withOfferComponents(
        Fulfillment memory _fulfillment,
        FulfillmentComponent[] memory components
    ) internal pure returns (Fulfillment memory) {
        _fulfillment.offerComponents = components.copy();
        return _fulfillment;
    }

    /**
     * @dev Sets the consideration components of a Fulfillment in-place.
     *
     * @param _fulfillment the Fulfillment to set the consideration components
     *                     of
     * @param components   the FulfillmentComponent array to set as the
     *                     consideration components
     *
     * @custom:return _fulfillment the Fulfillment with the consideration
     *                             components set
     */
    function withConsiderationComponents(
        Fulfillment memory _fulfillment,
        FulfillmentComponent[] memory components
    ) internal pure returns (Fulfillment memory) {
        _fulfillment.considerationComponents = components.copy();
        return _fulfillment;
    }
}
