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
    AdditionalRecipient,
    AdvancedOrder,
    BasicOrderParameters,
    ConsiderationItem,
    OfferItem,
    Order,
    OrderParameters,
    OrderType
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { BasicOrderType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { OrderParametersLib } from "./OrderParametersLib.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title AdvancedOrderLib
 * @author James Wenzel (emo.eth)
 * @notice AdvancedOrderLib is a library for managing AdvancedOrder
 *         structs and arrays. It allows chaining of functions to make struct
 *         creation more readable.
 */
library OrderLib {
    bytes32 private constant ORDER_MAP_POSITION =
        keccak256("seaport.OrderDefaults");
    bytes32 private constant ORDERS_MAP_POSITION =
        keccak256("seaport.OrdersDefaults");
    bytes32 private constant EMPTY_ORDER =
        keccak256(
            abi.encode(
                Order({
                    parameters: OrderParameters({
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
                    }),
                    signature: ""
                })
            )
        );

    using OrderParametersLib for OrderParameters;

    /**
     * @dev Clears a default Order from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => Order) storage orderMap = _orderMap();
        Order storage item = orderMap[defaultName];
        clear(item);
    }

    /**
     * @dev Clears all fields on an Order.
     *
     * @param order the Order to clear
     */
    function clear(Order storage order) internal {
        // clear all fields
        order.parameters.clear();
        order.signature = "";
    }

    /**
     * @dev Clears an array of Orders from storage.
     *
     * @param order the Orders to clear
     */
    function clear(Order[] storage order) internal {
        while (order.length > 0) {
            clear(order[order.length - 1]);
            order.pop();
        }
    }

    /**
     * @dev Gets a default Order from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the default Order
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (Order memory item) {
        mapping(string => Order) storage orderMap = _orderMap();
        item = orderMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_ORDER) {
            revert("Empty Order selected.");
        }
    }

    /**
     * @dev Gets a default Order array from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the default Order array
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (Order[] memory) {
        mapping(string => Order[]) storage ordersMap = _ordersMap();
        Order[] memory items = ordersMap[defaultName];

        if (items.length == 0) {
            revert("Empty Order array selected.");
        }

        return items;
    }

    /**
     * @dev Saves an Order as a named default.
     *
     * @param order the Order to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _order the Order saved as a default
     */
    function saveDefault(
        Order memory order,
        string memory defaultName
    ) internal returns (Order memory _order) {
        mapping(string => Order) storage orderMap = _orderMap();
        StructCopier.setOrder(orderMap[defaultName], order);
        return order;
    }

    /**
     * @dev Saves an Order array as a named default.
     *
     * @param orders the Order array to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _orders the Order array saved as a default
     */
    function saveDefaultMany(
        Order[] memory orders,
        string memory defaultName
    ) internal returns (Order[] memory _orders) {
        mapping(string => Order[]) storage ordersMap = _ordersMap();
        StructCopier.setOrders(ordersMap[defaultName], orders);
        return orders;
    }

    /**
     * @dev Makes a copy of an Order in-memory.
     *
     * @param item the Order to make a copy of in-memory
     *
     * @custom:return copiedOrder the copied Order
     */
    function copy(Order memory item) internal pure returns (Order memory) {
        return
            Order({
                parameters: item.parameters.copy(),
                signature: item.signature
            });
    }

    /**
     * @dev Makes a copy of an Order array in-memory.
     *
     * @param items the Order array to make a copy of in-memory
     *
     * @custom:return copiedOrders the copied Order array
     */
    function copy(Order[] memory items) internal pure returns (Order[] memory) {
        Order[] memory copiedItems = new Order[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            copiedItems[i] = copy(items[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Create an empty Order.
     *
     * @custom:return emptyOrder the empty Order
     */
    function empty() internal pure returns (Order memory) {
        return Order({ parameters: OrderParametersLib.empty(), signature: "" });
    }

    /**
     * @dev Gets the storage position of the default Order map.
     *
     * @return orderMap the storage position of the default Order map
     */
    function _orderMap()
        private
        pure
        returns (mapping(string => Order) storage orderMap)
    {
        bytes32 position = ORDER_MAP_POSITION;
        assembly {
            orderMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default Order array map.
     *
     * @return ordersMap the storage position of the default Order array map
     */
    function _ordersMap()
        private
        pure
        returns (mapping(string => Order[]) storage ordersMap)
    {
        bytes32 position = ORDERS_MAP_POSITION;
        assembly {
            ordersMap.slot := position
        }
    }

    // Methods for configuring a single of each of an Order's fields, which
    // modify the Order in-place and return it.

    /**
     * @dev Sets the parameters of an Order.
     *
     * @param order the Order to set the parameters of
     * @param parameters the parameters to set
     *
     * @return _order the Order with the parameters set
     */
    function withParameters(
        Order memory order,
        OrderParameters memory parameters
    ) internal pure returns (Order memory) {
        order.parameters = parameters.copy();
        return order;
    }

    /**
     * @dev Sets the signature of an Order.
     *
     * @param order the Order to set the signature of
     * @param signature the signature to set
     *
     * @return _order the Order with the signature set
     */
    function withSignature(
        Order memory order,
        bytes memory signature
    ) internal pure returns (Order memory) {
        order.signature = signature;
        return order;
    }

    /**
     * @dev Converts an Order to an AdvancedOrder.
     *
     * @param order the Order to convert
     * @param numerator the numerator to set
     * @param denominator the denominator to set
     * @param extraData the extra data to set
     *
     * @return advancedOrder the AdvancedOrder
     */
    function toAdvancedOrder(
        Order memory order,
        uint120 numerator,
        uint120 denominator,
        bytes memory extraData
    ) internal pure returns (AdvancedOrder memory advancedOrder) {
        advancedOrder.parameters = order.parameters.copy();
        advancedOrder.numerator = numerator;
        advancedOrder.denominator = denominator;
        advancedOrder.signature = order.signature;
        advancedOrder.extraData = extraData;
    }

    /**
     * @dev Converts Orders to AdvancedOrders in bulk.
     *
     * @param orders the Orders to convert
     * @param numerator the numerator to set for all
     * @param denominator the denominator to set for all
     * @param extraData the extra data to set for all
     *
     * @return _advancedOrders the AdvancedOrders
     */
    function toAdvancedOrders(
        Order[] memory orders,
        uint120 numerator,
        uint120 denominator,
        bytes memory extraData
    ) internal pure returns (AdvancedOrder[] memory _advancedOrders) {
        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](
            orders.length
        );
        for (uint256 i = 0; i < orders.length; i++) {
            advancedOrders[i] = toAdvancedOrder(
                orders[i],
                numerator,
                denominator,
                extraData
            );
        }
        return advancedOrders;
    }

    /**
     * @dev Converts an Order to a BasicOrderParameters.
     *
     * @param order          the Order to convert
     * @param basicOrderType the BasicOrderType to set
     *
     * @return basicOrderParameters the BasicOrderParameters
     */
    function toBasicOrderParameters(
        Order memory order,
        BasicOrderType basicOrderType
    ) internal pure returns (BasicOrderParameters memory basicOrderParameters) {
        basicOrderParameters.considerationToken = order
            .parameters
            .consideration[0]
            .token;
        basicOrderParameters.considerationIdentifier = order
            .parameters
            .consideration[0]
            .identifierOrCriteria;
        basicOrderParameters.considerationAmount = order
            .parameters
            .consideration[0]
            .endAmount;
        basicOrderParameters.offerer = payable(order.parameters.offerer);
        basicOrderParameters.zone = order.parameters.zone;
        basicOrderParameters.offerToken = order.parameters.offer[0].token;
        basicOrderParameters.offerIdentifier = order
            .parameters
            .offer[0]
            .identifierOrCriteria;
        basicOrderParameters.offerAmount = order.parameters.offer[0].endAmount;
        basicOrderParameters.basicOrderType = basicOrderType;
        basicOrderParameters.startTime = order.parameters.startTime;
        basicOrderParameters.endTime = order.parameters.endTime;
        basicOrderParameters.zoneHash = order.parameters.zoneHash;
        basicOrderParameters.salt = order.parameters.salt;
        basicOrderParameters.offererConduitKey = order.parameters.conduitKey;
        basicOrderParameters.fulfillerConduitKey = order.parameters.conduitKey;
        basicOrderParameters.totalOriginalAdditionalRecipients =
            order.parameters.totalOriginalConsiderationItems -
            1;

        AdditionalRecipient[]
            memory additionalRecipients = new AdditionalRecipient[](
                order.parameters.consideration.length - 1
            );
        for (uint256 i = 1; i < order.parameters.consideration.length; i++) {
            additionalRecipients[i - 1] = AdditionalRecipient({
                recipient: order.parameters.consideration[i].recipient,
                amount: order.parameters.consideration[i].startAmount
            });
        }

        basicOrderParameters.additionalRecipients = additionalRecipients;
        basicOrderParameters.signature = order.signature;

        return basicOrderParameters;
    }
}
