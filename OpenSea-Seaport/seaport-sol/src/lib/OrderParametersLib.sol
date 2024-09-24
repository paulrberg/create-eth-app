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

import { ItemType, Side } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    ConsiderationItem,
    CriteriaResolver,
    OrderComponents,
    OrderParameters,
    OfferItem,
    ReceivedItem,
    SpentItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { OrderType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { StructCopier } from "./StructCopier.sol";

import { OfferItemLib } from "./OfferItemLib.sol";

import { ConsiderationItemLib } from "./ConsiderationItemLib.sol";

/**
 * @title OrderParametersLib
 * @author James Wenzel (emo.eth)
 * @notice OrderParametersLib is a library for managing OrderParameters structs
 *         and arrays. It allows chaining of functions to make struct creation
 *         more readable.
 */
library OrderParametersLib {
    using OrderParametersLib for OrderParameters;
    using OfferItemLib for OfferItem[];
    using ConsiderationItemLib for ConsiderationItem[];
    using ConsiderationItemLib for ConsiderationItem;
    using OfferItemLib for OfferItem;

    bytes32 private constant ORDER_PARAMETERS_MAP_POSITION =
        keccak256("seaport.OrderParametersDefaults");
    bytes32 private constant ORDER_PARAMETERS_ARRAY_MAP_POSITION =
        keccak256("seaport.OrderParametersArrayDefaults");
    bytes32 private constant EMPTY_ORDER_PARAMETERS =
        keccak256(
            abi.encode(
                OrderParameters({
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
                    totalOriginalConsiderationItems: 0
                })
            )
        );

    /**
     * @dev Clears an OrderParameters from storage.
     *
     * @param parameters the OrderParameters to clear
     */
    function clear(OrderParameters storage parameters) internal {
        // uninitialized pointers take up no new memory (versus one word for initializing length-0)
        OfferItem[] memory offer;
        ConsiderationItem[] memory consideration;

        // clear all fields
        parameters.offerer = address(0);
        parameters.zone = address(0);
        StructCopier.setOfferItems(parameters.offer, offer);
        StructCopier.setConsiderationItems(
            parameters.consideration,
            consideration
        );
        parameters.orderType = OrderType(0);
        parameters.startTime = 0;
        parameters.endTime = 0;
        parameters.zoneHash = bytes32(0);
        parameters.salt = 0;
        parameters.conduitKey = bytes32(0);
        parameters.totalOriginalConsiderationItems = 0;
    }

    /**
     * @dev Clears an array of OrderParameters from storage.
     *
     * @param parameters the OrderParameters array to clear
     */
    function clear(OrderParameters[] storage parameters) internal {
        while (parameters.length > 0) {
            clear(parameters[parameters.length - 1]);
            parameters.pop();
        }
    }

    /**
     * @dev Clears a default OrderParameters from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => OrderParameters)
            storage orderParametersMap = _orderParametersMap();
        OrderParameters storage parameters = orderParametersMap[defaultName];
        parameters.clear();
    }

    /**
     * @dev Creates a new empty OrderParameters struct.
     *
     * @return item the new OrderParameters
     */
    function empty() internal pure returns (OrderParameters memory item) {
        OfferItem[] memory offer;
        ConsiderationItem[] memory consideration;
        item = OrderParameters({
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
            totalOriginalConsiderationItems: 0
        });
    }

    /**
     * @dev Gets a default OrderParameters from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the default OrderParameters
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (OrderParameters memory item) {
        mapping(string => OrderParameters)
            storage orderParametersMap = _orderParametersMap();
        item = orderParametersMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_ORDER_PARAMETERS) {
            revert("Empty OrderParameters selected.");
        }
    }

    /**
     * @dev Gets a default OrderParameters array from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the default OrderParameters array
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (OrderParameters[] memory items) {
        mapping(string => OrderParameters[])
            storage orderParametersArrayMap = _orderParametersArrayMap();
        items = orderParametersArrayMap[defaultName];

        if (items.length == 0) {
            revert("Empty OrderParameters array selected.");
        }
    }

    /**
     * @dev Saves an OrderParameters as a named default.
     *
     * @param orderParameters the OrderParameters to save as a default
     * @param defaultName     the name of the default for retrieval
     *
     * @return _orderParameters the OrderParameters that was saved
     */
    function saveDefault(
        OrderParameters memory orderParameters,
        string memory defaultName
    ) internal returns (OrderParameters memory _orderParameters) {
        mapping(string => OrderParameters)
            storage orderParametersMap = _orderParametersMap();
        OrderParameters storage destination = orderParametersMap[defaultName];
        StructCopier.setOrderParameters(destination, orderParameters);
        return orderParameters;
    }

    /**
     * @dev Saves an OrderParameters array as a named default.
     *
     * @param orderParameters the OrderParameters array to save as a default
     * @param defaultName     the name of the default for retrieval
     *
     * @return _orderParameters the OrderParameters array that was saved
     */
    function saveDefaultMany(
        OrderParameters[] memory orderParameters,
        string memory defaultName
    ) internal returns (OrderParameters[] memory _orderParameters) {
        mapping(string => OrderParameters[])
            storage orderParametersArrayMap = _orderParametersArrayMap();
        OrderParameters[] storage destination = orderParametersArrayMap[
            defaultName
        ];
        StructCopier.setOrderParameters(destination, orderParameters);
        return orderParameters;
    }

    /**
     * @dev Makes a copy of an OrderParameters in-memory.
     *
     * @param item the OrderParameters to make a copy of in-memory
     *
     * @custom:return copiedOrderParameters the copied OrderParameters
     */
    function copy(
        OrderParameters memory item
    ) internal pure returns (OrderParameters memory) {
        return
            OrderParameters({
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
                totalOriginalConsiderationItems: item
                    .totalOriginalConsiderationItems
            });
    }

    /**
     * @dev Gets the storage position of the default OrderParameters map.
     *
     * @custom:return position the storage position of the default
     *                         OrderParameters map
     */
    function _orderParametersMap()
        private
        pure
        returns (mapping(string => OrderParameters) storage orderParametersMap)
    {
        bytes32 position = ORDER_PARAMETERS_MAP_POSITION;
        assembly {
            orderParametersMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default OrderParameters array map.
     *
     * @custom:return position the storage position of the default
     *                         OrderParameters array map
     */
    function _orderParametersArrayMap()
        private
        pure
        returns (
            mapping(string => OrderParameters[]) storage orderParametersArrayMap
        )
    {
        bytes32 position = ORDER_PARAMETERS_ARRAY_MAP_POSITION;
        assembly {
            orderParametersArrayMap.slot := position
        }
    }

    // Methods for configuring a single of each of a OrderParameters's fields,
    // which modify the OrderParameters struct in-place and return it.

    /**
     * @dev Sets the offerer field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param offerer    the new value for the offerer field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withOfferer(
        OrderParameters memory parameters,
        address offerer
    ) internal pure returns (OrderParameters memory) {
        parameters.offerer = offerer;
        return parameters;
    }

    /**
     * @dev Sets the zone field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param zone       the new value for the zone field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withZone(
        OrderParameters memory parameters,
        address zone
    ) internal pure returns (OrderParameters memory) {
        parameters.zone = zone;
        return parameters;
    }

    /**
     * @dev Sets the offer field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param offer      the new value for the offer field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withOffer(
        OrderParameters memory parameters,
        OfferItem[] memory offer
    ) internal pure returns (OrderParameters memory) {
        parameters.offer = offer;
        return parameters;
    }

    /**
     * @dev Sets the consideration field of a OrderParameters struct in-place.
     *
     * @param parameters    the OrderParameters struct to modify
     * @param consideration the new value for the consideration field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withConsideration(
        OrderParameters memory parameters,
        ConsiderationItem[] memory consideration
    ) internal pure returns (OrderParameters memory) {
        parameters.consideration = consideration;
        return parameters;
    }

    /**
     * @dev Sets the consideration field of a OrderParameters struct in-place
     *      and updates the totalOriginalConsiderationItems field accordingly.
     *
     * @param parameters    the OrderParameters struct to modify
     * @param consideration the new value for the consideration field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withTotalConsideration(
        OrderParameters memory parameters,
        ConsiderationItem[] memory consideration
    ) internal pure returns (OrderParameters memory) {
        parameters.consideration = consideration;
        parameters.totalOriginalConsiderationItems = consideration.length;
        return parameters;
    }

    /**
     * @dev Sets the orderType field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param orderType  the new value for the orderType field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withOrderType(
        OrderParameters memory parameters,
        OrderType orderType
    ) internal pure returns (OrderParameters memory) {
        parameters.orderType = orderType;
        return parameters;
    }

    /**
     * @dev Sets the startTime field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param startTime  the new value for the startTime field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withStartTime(
        OrderParameters memory parameters,
        uint256 startTime
    ) internal pure returns (OrderParameters memory) {
        parameters.startTime = startTime;
        return parameters;
    }

    /**
     * @dev Sets the endTime field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param endTime    the new value for the endTime field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withEndTime(
        OrderParameters memory parameters,
        uint256 endTime
    ) internal pure returns (OrderParameters memory) {
        parameters.endTime = endTime;
        return parameters;
    }

    /**
     * @dev Sets the zoneHash field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param zoneHash   the new value for the zoneHash field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withZoneHash(
        OrderParameters memory parameters,
        bytes32 zoneHash
    ) internal pure returns (OrderParameters memory) {
        parameters.zoneHash = zoneHash;
        return parameters;
    }

    /**
     * @dev Sets the salt field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param salt       the new value for the salt field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withSalt(
        OrderParameters memory parameters,
        uint256 salt
    ) internal pure returns (OrderParameters memory) {
        parameters.salt = salt;
        return parameters;
    }

    /**
     * @dev Sets the conduitKey field of a OrderParameters struct in-place.
     *
     * @param parameters the OrderParameters struct to modify
     * @param conduitKey the new value for the conduitKey field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withConduitKey(
        OrderParameters memory parameters,
        bytes32 conduitKey
    ) internal pure returns (OrderParameters memory) {
        parameters.conduitKey = conduitKey;
        return parameters;
    }

    /**
     * @dev Sets the totalOriginalConsiderationItems field of a OrderParameters
     *      struct in-place.
     *
     * @param parameters                      the OrderParameters struct to
     *                                        modify
     * @param totalOriginalConsiderationItems the new value for the
     *                                        totalOriginalConsiderationItems
     *                                        field
     *
     * @custom:return _parameters the modified OrderParameters struct
     */
    function withTotalOriginalConsiderationItems(
        OrderParameters memory parameters,
        uint256 totalOriginalConsiderationItems
    ) internal pure returns (OrderParameters memory) {
        parameters
            .totalOriginalConsiderationItems = totalOriginalConsiderationItems;
        return parameters;
    }

    /**
     * @dev Converts an OrderParameters struct into an OrderComponents struct.
     *
     * @param parameters the OrderParameters struct to convert
     * @param counter    the counter to use for the OrderComponents struct
     *
     * @return components the OrderComponents struct
     */
    function toOrderComponents(
        OrderParameters memory parameters,
        uint256 counter
    ) internal pure returns (OrderComponents memory components) {
        components.offerer = parameters.offerer;
        components.zone = parameters.zone;
        components.offer = parameters.offer.copy();
        components.consideration = parameters.consideration.copy();
        components.orderType = parameters.orderType;
        components.startTime = parameters.startTime;
        components.endTime = parameters.endTime;
        components.zoneHash = parameters.zoneHash;
        components.salt = parameters.salt;
        components.conduitKey = parameters.conduitKey;
        components.counter = counter;
    }

    function isAvailable(
        OrderParameters memory parameters
    ) internal view returns (bool) {
        return
            block.timestamp >= parameters.startTime &&
            block.timestamp < parameters.endTime;
    }

    function getSpentAndReceivedItems(
        OrderParameters memory parameters,
        uint256 numerator,
        uint256 denominator,
        uint256 orderIndex,
        CriteriaResolver[] memory criteriaResolvers
    )
        internal
        view
        returns (SpentItem[] memory spent, ReceivedItem[] memory received)
    {
        if (isAvailable(parameters)) {
            spent = getSpentItems(parameters, numerator, denominator);
            received = getReceivedItems(parameters, numerator, denominator);

            applyCriteriaResolvers(
                spent,
                received,
                orderIndex,
                criteriaResolvers
            );
        }
    }

    function applyCriteriaResolvers(
        SpentItem[] memory spentItems,
        ReceivedItem[] memory receivedItems,
        uint256 orderIndex,
        CriteriaResolver[] memory criteriaResolvers
    ) internal pure {
        for (uint256 i = 0; i < criteriaResolvers.length; i++) {
            CriteriaResolver memory resolver = criteriaResolvers[i];
            if (resolver.orderIndex != orderIndex) {
                continue;
            }
            if (resolver.side == Side.OFFER) {
                SpentItem memory item = spentItems[resolver.index];
                item.itemType = convertCriteriaItemType(item.itemType);
                item.identifier = resolver.identifier;
            } else {
                ReceivedItem memory item = receivedItems[resolver.index];
                item.itemType = convertCriteriaItemType(item.itemType);
                item.identifier = resolver.identifier;
            }
        }
    }

    function convertCriteriaItemType(
        ItemType itemType
    ) internal pure returns (ItemType) {
        if (itemType == ItemType.ERC721_WITH_CRITERIA) {
            return ItemType.ERC721;
        } else if (itemType == ItemType.ERC1155_WITH_CRITERIA) {
            return ItemType.ERC1155;
        } else {
            revert(
                "OrderParametersLib: amount deriver helper resolving non criteria item type"
            );
        }
    }

    function getSpentItems(
        OrderParameters memory parameters,
        uint256 numerator,
        uint256 denominator
    ) internal view returns (SpentItem[] memory) {
        return
            getSpentItems(
                parameters.offer,
                parameters.startTime,
                parameters.endTime,
                numerator,
                denominator
            );
    }

    function getReceivedItems(
        OrderParameters memory parameters,
        uint256 numerator,
        uint256 denominator
    ) internal view returns (ReceivedItem[] memory) {
        return
            getReceivedItems(
                parameters.consideration,
                parameters.startTime,
                parameters.endTime,
                numerator,
                denominator
            );
    }

    function getSpentItems(
        OfferItem[] memory items,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) internal view returns (SpentItem[] memory) {
        SpentItem[] memory spentItems = new SpentItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            spentItems[i] = getSpentItem(
                items[i],
                startTime,
                endTime,
                numerator,
                denominator
            );
        }
        return spentItems;
    }

    function getReceivedItems(
        ConsiderationItem[] memory considerationItems,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) internal view returns (ReceivedItem[] memory) {
        ReceivedItem[] memory receivedItems = new ReceivedItem[](
            considerationItems.length
        );
        for (uint256 i = 0; i < considerationItems.length; i++) {
            receivedItems[i] = getReceivedItem(
                considerationItems[i],
                startTime,
                endTime,
                numerator,
                denominator
            );
        }
        return receivedItems;
    }

    function getSpentItem(
        OfferItem memory item,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) internal view returns (SpentItem memory spent) {
        spent = SpentItem({
            itemType: item.itemType,
            token: item.token,
            identifier: item.identifierOrCriteria,
            amount: _applyFraction({
                numerator: numerator,
                denominator: denominator,
                startAmount: item.startAmount,
                endAmount: item.endAmount,
                startTime: startTime,
                endTime: endTime,
                roundUp: false
            })
        });
    }

    function getReceivedItem(
        ConsiderationItem memory considerationItem,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) internal view returns (ReceivedItem memory received) {
        received = ReceivedItem({
            itemType: considerationItem.itemType,
            token: considerationItem.token,
            identifier: considerationItem.identifierOrCriteria,
            amount: _applyFraction({
                numerator: numerator,
                denominator: denominator,
                startAmount: considerationItem.startAmount,
                endAmount: considerationItem.endAmount,
                startTime: startTime,
                endTime: endTime,
                roundUp: true
            }),
            recipient: considerationItem.recipient
        });
    }

    function _applyFraction(
        uint256 startAmount,
        uint256 endAmount,
        uint256 numerator,
        uint256 denominator,
        uint256 startTime,
        uint256 endTime,
        bool roundUp
    ) internal view returns (uint256 amount) {
        // If start amount equals end amount, apply fraction to end amount.
        if (startAmount == endAmount) {
            // Apply fraction to end amount.
            amount = _getFraction(numerator, denominator, endAmount);
        } else {
            // Otherwise, apply fraction to both and interpolated final amount.
            amount = _locateCurrentAmount(
                _getFraction(numerator, denominator, startAmount),
                _getFraction(numerator, denominator, endAmount),
                startTime,
                endTime,
                roundUp
            );
        }
    }

    function _getFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 value
    ) internal pure returns (uint256 newValue) {
        // Return value early in cases where the fraction resolves to 1.
        if (numerator == denominator) {
            return value;
        }

        bool failure = false;

        // Ensure fraction can be applied to the value with no remainder. Note
        // that the denominator cannot be zero.
        assembly {
            // Ensure new value contains no remainder via mulmod operator.
            // Credit to @hrkrshnn + @axic for proposing this optimal solution.
            if mulmod(value, numerator, denominator) {
                failure := true
            }
        }

        if (failure) {
            revert("OrderParametersLib: bad fraction");
        }

        // Multiply the numerator by the value and ensure no overflow occurs.
        uint256 valueTimesNumerator = value * numerator;

        // Divide and check for remainder. Note that denominator cannot be zero.
        assembly {
            // Perform division without zero check.
            newValue := div(valueTimesNumerator, denominator)
        }
    }

    function _locateCurrentAmount(
        uint256 startAmount,
        uint256 endAmount,
        uint256 startTime,
        uint256 endTime,
        bool roundUp
    ) internal view returns (uint256 amount) {
        // Only modify end amount if it doesn't already equal start amount.
        if (startAmount != endAmount) {
            // Declare variables to derive in the subsequent unchecked scope.
            uint256 duration;
            uint256 elapsed;
            uint256 remaining;

            // Skip underflow checks as startTime <= block.timestamp < endTime.
            unchecked {
                // Derive the duration for the order and place it on the stack.
                duration = endTime - startTime;

                // Derive time elapsed since the order started & place on stack.
                elapsed = block.timestamp - startTime;

                // Derive time remaining until order expires and place on stack.
                remaining = duration - elapsed;
            }

            // Aggregate new amounts weighted by time with rounding factor.
            uint256 totalBeforeDivision = ((startAmount * remaining) +
                (endAmount * elapsed));

            // Use assembly to combine operations and skip divide-by-zero check.
            assembly {
                // Multiply by iszero(iszero(totalBeforeDivision)) to ensure
                // amount is set to zero if totalBeforeDivision is zero,
                // as intermediate overflow can occur if it is zero.
                amount := mul(
                    iszero(iszero(totalBeforeDivision)),
                    // Subtract 1 from the numerator and add 1 to the result if
                    // roundUp is true to get the proper rounding direction.
                    // Division is performed with no zero check as duration
                    // cannot be zero as long as startTime < endTime.
                    add(
                        div(sub(totalBeforeDivision, roundUp), duration),
                        roundUp
                    )
                )
            }

            // Return the current amount.
            return amount;
        }

        // Return the original amount as startAmount == endAmount.
        return endAmount;
    }
}
