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
    ConsiderationInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ConsiderationInterface.sol";

import {
    AdvancedOrder,
    Execution,
    SpentItem,
    ReceivedItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { UnavailableReason } from "OpenSea-Seaport/seaport-sol/src/SpaceEnums.sol";

import { OrderDetails } from "OpenSea-Seaport/seaport-sol/src/fulfillments/lib/Structs.sol";

import { AdvancedOrderLib } from "OpenSea-Seaport/seaport-sol/src/lib/AdvancedOrderLib.sol";

import { Family, Structure, OrderStructureLib } from "./OrderStructureLib.sol";

import { NavigatorContext } from "./SeaportNavigatorTypes.sol";

library NavigatorSuggestedActionLib {
    using OrderStructureLib for AdvancedOrder;
    using OrderStructureLib for AdvancedOrder[];
    using AdvancedOrderLib for AdvancedOrder;
    using AdvancedOrderLib for AdvancedOrder[];

    /**
     * @dev Bad request error: provided orders cannot be fulfilled.
     */
    error CannotFulfillProvidedCombinedOrder();

    /**
     * @dev Bad request error: provided orders include an invalid combination of
     *      native tokens and unavailable orders.
     */
    error InvalidNativeTokenUnavailableCombination();

    /**
     * @dev Internal error: Could not find selector for the suggested action.
     */
    error UnknownSelector();

    /**
     * @dev Choose a suggested fulfillment method based on the structure of the
     *      orders and add it to the NavigatorResponse.
     */
    function withSuggestedAction(
        NavigatorContext memory context
    ) internal view returns (NavigatorContext memory) {
        bytes memory callData = suggestedCallData(context);
        bytes4 selector = bytes4(callData);
        context.response.suggestedActionName = actionName(selector);
        context.response.suggestedCallData = callData;
        return context;
    }

    /**
     * @dev Add the human-readable name of the selected fulfillment method to
     *      the NavigatorResponse.
     */
    function actionName(bytes4 selector) internal pure returns (string memory) {
        if (selector == 0xe7acab24) return "fulfillAdvancedOrder";
        if (selector == 0x87201b41) return "fulfillAvailableAdvancedOrders";
        if (selector == 0xed98a574) return "fulfillAvailableOrders";
        if (selector == 0xfb0f3ee1) return "fulfillBasicOrder";
        if (selector == 0x00000000) return "fulfillBasicOrder_efficient_6GL6yc";
        if (selector == 0xb3a34c4c) return "fulfillOrder";
        if (selector == 0xf2d12b12) return "matchAdvancedOrders";
        if (selector == 0xa8174404) return "matchOrders";

        revert UnknownSelector();
    }

    /**
     * @dev Choose a suggested fulfillment method based on the structure of the
     *      orders.
     */
    function suggestedCallData(
        NavigatorContext memory context
    ) internal view returns (bytes memory) {
        Family family = context.response.orders.getFamily();

        bool invalidOfferItemsLocated = mustUseMatch(context);

        Structure structure = context.response.orders.getStructure(
            address(context.request.seaport)
        );

        bool hasUnavailable = context.request.maximumFulfilled <
            context.response.orders.length;
        for (uint256 i = 0; i < context.response.orderDetails.length; ++i) {
            if (
                context.response.orderDetails[i].unavailableReason !=
                UnavailableReason.AVAILABLE
            ) {
                hasUnavailable = true;
                break;
            }
        }

        if (hasUnavailable) {
            if (invalidOfferItemsLocated) {
                revert InvalidNativeTokenUnavailableCombination();
            }

            if (structure == Structure.ADVANCED) {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillAvailableAdvancedOrders,
                        (
                            context.response.orders,
                            context.response.criteriaResolvers,
                            context.response.offerFulfillments,
                            context.response.considerationFulfillments,
                            context.request.fulfillerConduitKey,
                            context.request.recipient,
                            context.request.maximumFulfilled
                        )
                    );
            } else {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillAvailableOrders,
                        (
                            context.response.orders.toOrders(),
                            context.response.offerFulfillments,
                            context.response.considerationFulfillments,
                            context.request.fulfillerConduitKey,
                            context.request.maximumFulfilled
                        )
                    );
            }
        }

        if (family == Family.SINGLE && !invalidOfferItemsLocated) {
            if (structure == Structure.BASIC) {
                AdvancedOrder memory order = context.response.orders[0];
                return
                    abi.encodeCall(
                        ConsiderationInterface
                            .fulfillBasicOrder_efficient_6GL6yc,
                        (
                            order.toBasicOrderParameters(
                                order.getBasicOrderType()
                            )
                        )
                    );
            }

            if (structure == Structure.STANDARD) {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillOrder,
                        (
                            context.response.orders[0].toOrder(),
                            context.request.fulfillerConduitKey
                        )
                    );
            }

            if (structure == Structure.ADVANCED) {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillAdvancedOrder,
                        (
                            context.response.orders[0],
                            context.response.criteriaResolvers,
                            context.request.fulfillerConduitKey,
                            context.request.recipient
                        )
                    );
            }
        }

        bool cannotMatch = (context
            .response
            .unmetConsiderationComponents
            .length !=
            0 ||
            hasUnavailable);

        if (cannotMatch && invalidOfferItemsLocated) {
            revert CannotFulfillProvidedCombinedOrder();
        }

        if (cannotMatch) {
            if (structure == Structure.ADVANCED) {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillAvailableAdvancedOrders,
                        (
                            context.response.orders,
                            context.response.criteriaResolvers,
                            context.response.offerFulfillments,
                            context.response.considerationFulfillments,
                            context.request.fulfillerConduitKey,
                            context.request.recipient,
                            context.request.maximumFulfilled
                        )
                    );
            } else {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillAvailableOrders,
                        (
                            context.response.orders.toOrders(),
                            context.response.offerFulfillments,
                            context.response.considerationFulfillments,
                            context.request.fulfillerConduitKey,
                            context.request.maximumFulfilled
                        )
                    );
            }
        } else if (invalidOfferItemsLocated) {
            if (structure == Structure.ADVANCED) {
                return
                    abi.encodeCall(
                        ConsiderationInterface.fulfillAvailableAdvancedOrders,
                        (
                            context.response.orders,
                            context.response.criteriaResolvers,
                            context.response.offerFulfillments,
                            context.response.considerationFulfillments,
                            context.request.fulfillerConduitKey,
                            context.request.recipient,
                            context.request.maximumFulfilled
                        )
                    );
            } else {
                return
                    abi.encodeCall(
                        ConsiderationInterface.matchOrders,
                        (
                            context.response.orders.toOrders(),
                            context.response.fulfillments
                        )
                    );
            }
        } else {
            if (structure == Structure.ADVANCED) {
                if (context.request.preferMatch) {
                    return
                        abi.encodeCall(
                            ConsiderationInterface.matchAdvancedOrders,
                            (
                                context.response.orders,
                                context.response.criteriaResolvers,
                                context.response.fulfillments,
                                context.request.recipient
                            )
                        );
                } else {
                    return
                        abi.encodeCall(
                            ConsiderationInterface
                                .fulfillAvailableAdvancedOrders,
                            (
                                context.response.orders,
                                context.response.criteriaResolvers,
                                context.response.offerFulfillments,
                                context.response.considerationFulfillments,
                                context.request.fulfillerConduitKey,
                                context.request.recipient,
                                context.request.maximumFulfilled
                            )
                        );
                }
            } else {
                if (context.request.preferMatch) {
                    return
                        abi.encodeCall(
                            ConsiderationInterface.matchOrders,
                            (
                                context.response.orders.toOrders(),
                                context.response.fulfillments
                            )
                        );
                } else {
                    return
                        abi.encodeCall(
                            ConsiderationInterface.fulfillAvailableOrders,
                            (
                                context.response.orders.toOrders(),
                                context.response.offerFulfillments,
                                context.response.considerationFulfillments,
                                context.request.fulfillerConduitKey,
                                context.request.maximumFulfilled
                            )
                        );
                }
            }
        }
    }

    /**
     * @dev Return whether the provided orders must be matched using matchOrders
     *      or matchAdvancedOrders.
     */
    function mustUseMatch(
        NavigatorContext memory context
    ) internal pure returns (bool) {
        OrderDetails[] memory orders = context.response.orderDetails;

        for (uint256 i = 0; i < orders.length; ++i) {
            OrderDetails memory order = orders[i];

            if (order.isContract) {
                continue;
            }

            for (uint256 j = 0; j < order.offer.length; ++j) {
                if (order.offer[j].itemType == ItemType.NATIVE) {
                    return true;
                }
            }
        }

        if (context.request.caller == context.request.recipient) {
            return false;
        }

        for (uint256 i = 0; i < orders.length; ++i) {
            OrderDetails memory order = orders[i];

            for (uint256 j = 0; j < order.offer.length; ++j) {
                SpentItem memory item = order.offer[j];

                if (item.itemType != ItemType.ERC721) {
                    continue;
                }

                for (uint256 k = 0; k < orders.length; ++k) {
                    OrderDetails memory comparisonOrder = orders[k];
                    for (
                        uint256 l = 0;
                        l < comparisonOrder.consideration.length;
                        ++l
                    ) {
                        ReceivedItem memory considerationItem = comparisonOrder
                            .consideration[l];

                        if (
                            considerationItem.itemType == ItemType.ERC721 &&
                            considerationItem.identifier == item.identifier &&
                            considerationItem.token == item.token
                        ) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }
}
