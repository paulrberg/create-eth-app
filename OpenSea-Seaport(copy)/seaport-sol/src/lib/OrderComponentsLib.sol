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
    ConsiderationItem,
    OfferItem,
    OrderComponents,
    OrderParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    BasicOrderType,
    ItemType,
    OrderType
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { StructCopier } from "./StructCopier.sol";

import { OfferItemLib } from "./OfferItemLib.sol";

import { ConsiderationItemLib } from "./ConsiderationItemLib.sol";

/**
 * @title OrderComponentsLib
 * @author James Wenzel (emo.eth)
 * @notice OrderComponentsLib is a library for managing OrderComponents structs
 *         and arrays. It allows chaining of functions to make struct creation
 *         more readable.
 */
library OrderComponentsLib {
    using OrderComponentsLib for OrderComponents;
    using OfferItemLib for OfferItem[];
    using ConsiderationItemLib for ConsiderationItem[];

    bytes32 private constant ORDER_COMPONENTS_MAP_POSITION =
        keccak256("seaport.OrderComponentsDefaults");
    bytes32 private constant ORDER_COMPONENTS_ARRAY_MAP_POSITION =
        keccak256("seaport.OrderComponentsArrayDefaults");
    bytes32 private constant EMPTY_ORDER_COMPONENTS =
        keccak256(
            abi.encode(
                OrderComponents({
                    offerer: address(0),
                    zone: address(0),
                    offer: new OfferItem[](0),
                    consideration: new ConsiderationItem[](0),
                    orderType: OrderType(0),
                    startTime: 0,
                    endTime: 0,
                    zoneHash: bytes32(0),
                    salt: 0,
                    conduitKey: bytes32(0),
                    counter: 0
                })
            )
        );

    /**
     * @dev Clears anOrderComponents from storage.
     *
     * @param components the OrderComponents to clear
     */
    function clear(OrderComponents storage components) internal {
        // uninitialized pointers take up no new memory (versus one word for initializing length-0)
        OfferItem[] memory offer;
        ConsiderationItem[] memory consideration;

        // clear all fields
        components.offerer = address(0);
        components.zone = address(0);
        StructCopier.setOfferItems(components.offer, offer);
        StructCopier.setConsiderationItems(
            components.consideration,
            consideration
        );
        components.orderType = OrderType(0);
        components.startTime = 0;
        components.endTime = 0;
        components.zoneHash = bytes32(0);
        components.salt = 0;
        components.conduitKey = bytes32(0);
        components.counter = 0;
    }

    /**
     * @dev Clears an array of OrderComponents from storage.
     *
     * @param components the OrderComponents to clear
     */
    function clear(OrderComponents[] storage components) internal {
        while (components.length > 0) {
            clear(components[components.length - 1]);
            components.pop();
        }
    }

    /**
     * @dev Clears a default OrderComponents from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => OrderComponents)
            storage orderComponentsMap = _orderComponentsMap();
        OrderComponents storage components = orderComponentsMap[defaultName];
        components.clear();
    }

    /**
     * @dev Creates a new OrderComponents struct.
     *
     * @return item the new OrderComponents struct
     */
    function empty() internal pure returns (OrderComponents memory item) {
        OfferItem[] memory offer;
        ConsiderationItem[] memory consideration;
        item = OrderComponents({
            offerer: address(0),
            zone: address(0),
            offer: offer,
            consideration: consideration,
            orderType: OrderType(0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0),
            salt: 0,
            conduitKey: bytes32(0),
            counter: 0
        });
    }

    /**
     * @dev Gets a default OrderComponents from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the default OrderComponents
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (OrderComponents memory item) {
        mapping(string => OrderComponents)
            storage orderComponentsMap = _orderComponentsMap();
        item = orderComponentsMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_ORDER_COMPONENTS) {
            revert("Empty OrderComponents selected.");
        }
    }

    /**
     * @dev Gets a default OrderComponents array from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the default OrderComponents array
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (OrderComponents[] memory items) {
        mapping(string => OrderComponents[])
            storage orderComponentsArrayMap = _orderComponentsArrayMap();
        items = orderComponentsArrayMap[defaultName];

        if (items.length == 0) {
            revert("Empty OrderComponents array selected.");
        }
    }

    /**
     * @dev Saves an OrderComponents as a named default.
     *
     * @param orderComponents the OrderComponents to save as a default
     * @param defaultName     the name of the default for retrieval
     *
     * @return _orderComponents the OrderComponents that was saved
     */
    function saveDefault(
        OrderComponents memory orderComponents,
        string memory defaultName
    ) internal returns (OrderComponents memory _orderComponents) {
        mapping(string => OrderComponents)
            storage orderComponentsMap = _orderComponentsMap();
        OrderComponents storage destination = orderComponentsMap[defaultName];
        StructCopier.setOrderComponents(destination, orderComponents);
        return orderComponents;
    }

    /**
     * @dev Saves an OrderComponents array as a named default.
     *
     * @param orderComponents the OrderComponents array to save as a default
     * @param defaultName     the name of the default for retrieval
     *
     * @return _orderComponents the OrderComponents array that was saved
     */
    function saveDefaultMany(
        OrderComponents[] memory orderComponents,
        string memory defaultName
    ) internal returns (OrderComponents[] memory _orderComponents) {
        mapping(string => OrderComponents[])
            storage orderComponentsArrayMap = _orderComponentsArrayMap();
        OrderComponents[] storage destination = orderComponentsArrayMap[
            defaultName
        ];
        StructCopier.setOrderComponents(destination, orderComponents);
        return orderComponents;
    }

    /**
     * @dev Makes a copy of an OrderComponents in-memory.
     *
     * @param item the OrderComponents to make a copy of in-memory
     *
     * @return the copy of the OrderComponents
     */
    function copy(
        OrderComponents memory item
    ) internal pure returns (OrderComponents memory) {
        return
            OrderComponents({
                offerer: item.offerer,
                zone: item.zone,
                offer: item.offer.copy(),
                consideration: item.consideration.copy(),
                orderType: item.orderType,
                startTime: item.startTime,
                endTime: item.endTime,
                zoneHash: item.zoneHash,
                salt: item.salt,
                conduitKey: item.conduitKey,
                counter: item.counter
            });
    }

    /**
     * @dev Gets the storage position of the default OrderComponents map.
     *
     * @custom:return position the storage position of the default
     *                         OrderComponents map
     */
    function _orderComponentsMap()
        private
        pure
        returns (mapping(string => OrderComponents) storage orderComponentsMap)
    {
        bytes32 position = ORDER_COMPONENTS_MAP_POSITION;
        assembly {
            orderComponentsMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default OrderComponents array map.
     *
     * @custom:return position the storage position of the default
     *                         OrderComponents array map
     */
    function _orderComponentsArrayMap()
        private
        pure
        returns (
            mapping(string => OrderComponents[]) storage orderComponentsArrayMap
        )
    {
        bytes32 position = ORDER_COMPONENTS_ARRAY_MAP_POSITION;
        assembly {
            orderComponentsArrayMap.slot := position
        }
    }

    // Methods for configuring a single of each of a OrderComponents's fields,
    // which modify the OrderComponents struct in-place and return it.

    /**
     * @dev Sets the offerer field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param offerer    the new value for the offerer field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withOfferer(
        OrderComponents memory components,
        address offerer
    ) internal pure returns (OrderComponents memory) {
        components.offerer = offerer;
        return components;
    }

    /**
     * @dev Sets the zone field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param zone       the new value for the zone field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withZone(
        OrderComponents memory components,
        address zone
    ) internal pure returns (OrderComponents memory) {
        components.zone = zone;
        return components;
    }

    /**
     * @dev Sets the offer field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param offer      the new value for the offer field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withOffer(
        OrderComponents memory components,
        OfferItem[] memory offer
    ) internal pure returns (OrderComponents memory) {
        components.offer = offer;
        return components;
    }

    /**
     * @dev Sets the consideration field of an OrderComponents struct in-place.
     *
     * @param components    the OrderComponents struct to modify
     * @param consideration the new value for the consideration field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withConsideration(
        OrderComponents memory components,
        ConsiderationItem[] memory consideration
    ) internal pure returns (OrderComponents memory) {
        components.consideration = consideration;
        return components;
    }

    /**
     * @dev Sets the orderType field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param orderType  the new value for the orderType field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withOrderType(
        OrderComponents memory components,
        OrderType orderType
    ) internal pure returns (OrderComponents memory) {
        components.orderType = orderType;
        return components;
    }

    /**
     * @dev Sets the startTime field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param startTime  the new value for the startTime field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withStartTime(
        OrderComponents memory components,
        uint256 startTime
    ) internal pure returns (OrderComponents memory) {
        components.startTime = startTime;
        return components;
    }

    /**
     * @dev Sets the endTime field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param endTime    the new value for the endTime field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withEndTime(
        OrderComponents memory components,
        uint256 endTime
    ) internal pure returns (OrderComponents memory) {
        components.endTime = endTime;
        return components;
    }

    /**
     * @dev Sets the zoneHash field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param zoneHash   the new value for the zoneHash field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withZoneHash(
        OrderComponents memory components,
        bytes32 zoneHash
    ) internal pure returns (OrderComponents memory) {
        components.zoneHash = zoneHash;
        return components;
    }

    /**
     * @dev Sets the salt field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param salt       the new value for the salt field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withSalt(
        OrderComponents memory components,
        uint256 salt
    ) internal pure returns (OrderComponents memory) {
        components.salt = salt;
        return components;
    }

    /**
     * @dev Sets the conduitKey field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param conduitKey the new value for the conduitKey field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withConduitKey(
        OrderComponents memory components,
        bytes32 conduitKey
    ) internal pure returns (OrderComponents memory) {
        components.conduitKey = conduitKey;
        return components;
    }

    /**
     * @dev Sets the counter field of an OrderComponents struct in-place.
     *
     * @param components the OrderComponents struct to modify
     * @param counter    the new value for the counter field
     *
     * @custom:return _orderComponents the modified OrderComponents struct
     */
    function withCounter(
        OrderComponents memory components,
        uint256 counter
    ) internal pure returns (OrderComponents memory) {
        components.counter = counter;
        return components;
    }

    /**
     * @dev Converts an OrderComponents struct into an OrderParameters struct.
     *
     * @param components the OrderComponents struct to convert
     *
     * @custom:return _orderParameters the converted OrderParameters struct
     */
    function toOrderParameters(
        OrderComponents memory components
    ) internal pure returns (OrderParameters memory parameters) {
        parameters.offerer = components.offerer;
        parameters.zone = components.zone;
        parameters.offer = components.offer.copy();
        parameters.consideration = components.consideration.copy();
        parameters.orderType = components.orderType;
        parameters.startTime = components.startTime;
        parameters.endTime = components.endTime;
        parameters.zoneHash = components.zoneHash;
        parameters.salt = components.salt;
        parameters.conduitKey = components.conduitKey;
        parameters.totalOriginalConsiderationItems = components
            .consideration
            .length;
    }
}
