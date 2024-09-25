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

import {AmountDeriverHelper} from "../lib/fulfillment/AmountDeriverHelper.sol";

import {AdvancedOrderLib} from "../lib/AdvancedOrderLib.sol";

import {SpentItemLib} from "../lib/SpentItemLib.sol";

import {ReceivedItemLib} from "../lib/ReceivedItemLib.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    Order,
    ReceivedItem,
    SpentItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {ItemType, Side} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {FulfillmentDetails, OrderDetails} from "../fulfillments/lib/Structs.sol";

import {UnavailableReason} from "../SpaceEnums.sol";

/**
 * @dev Helper contract for deriving explicit and executions from orders and
 *      fulfillment details
 *
 * @dev TODO: move to the tests folder? not really useful for normal scripting
 */
library ExecutionHelper {
    using AdvancedOrderLib for AdvancedOrder[];
    using SpentItemLib for SpentItem[];
    using ReceivedItemLib for ReceivedItem[];

    /**
     * @dev get explicit and implicit executions for a fulfillAvailable call
     *
     * @param fulfillmentDetails        the fulfillment details
     * @param offerFulfillments         2d array of offer fulfillment components
     * @param considerationFulfillments 2d array of consideration fulfillment
     *
     * @return explicitExecutions the explicit executions
     * @return implicitExecutionsPre the implicit executions (unspecified offer
     *                            items)
     * @return implicitExecutionsPost the implicit executions (unspecified offer
     *                            items)
     */
    function getFulfillAvailableExecutions(
        FulfillmentDetails memory fulfillmentDetails,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        OrderDetails[] memory orderDetails
    )
        public
        pure
        returns (
            Execution[] memory explicitExecutions,
            Execution[] memory implicitExecutionsPre,
            Execution[] memory implicitExecutionsPost,
            uint256 nativeTokensReturned
        )
    {
        FulfillmentDetails memory details = copy(fulfillmentDetails);

        bool[] memory availableOrders = new bool[](orderDetails.length);

        for (uint256 i = 0; i < orderDetails.length; ++i) {
            availableOrders[i] = orderDetails[i].unavailableReason == UnavailableReason.AVAILABLE;
        }

        implicitExecutionsPre = processImplicitPreOrderExecutions(details, availableOrders);

        explicitExecutions = processExplicitExecutionsFromAggregatedComponents(
            details, offerFulfillments, considerationFulfillments, availableOrders
        );

        implicitExecutionsPost = processImplicitPostOrderExecutions(details, availableOrders);

        nativeTokensReturned =
            _handleExcessNativeTokens(details, explicitExecutions, implicitExecutionsPre, implicitExecutionsPost);
    }

    /**
     * @dev Process an array of fulfillments into an array of explicit and
     *         implicit executions.
     *
     * @param fulfillmentDetails The fulfillment details.
     * @param fulfillments An array of fulfillments.
     *
     * @return explicitExecutions The explicit executions
     * @return implicitExecutionsPre The implicit executions
     * @return implicitExecutionsPost The implicit executions
     */
    function getMatchExecutions(FulfillmentDetails memory fulfillmentDetails, Fulfillment[] memory fulfillments)
        internal
        pure
        returns (
            Execution[] memory explicitExecutions,
            Execution[] memory implicitExecutionsPre,
            Execution[] memory implicitExecutionsPost,
            uint256 nativeTokensReturned
        )
    {
        FulfillmentDetails memory details = copy(fulfillmentDetails);

        explicitExecutions = new Execution[](fulfillments.length);

        uint256 filteredExecutions = 0;

        bool[] memory availableOrders = new bool[](details.orders.length);

        for (uint256 i = 0; i < details.orders.length; ++i) {
            availableOrders[i] = true;
        }

        implicitExecutionsPre = processImplicitPreOrderExecutions(details, availableOrders);

        for (uint256 i = 0; i < fulfillments.length; i++) {
            Execution memory execution = processExecutionFromFulfillment(details, fulfillments[i]);

            if (execution.item.recipient == execution.offerer && execution.item.itemType != ItemType.NATIVE) {
                filteredExecutions++;
            } else {
                explicitExecutions[i - filteredExecutions] = execution;
            }
        }

        // If some number of executions have been filtered...
        if (filteredExecutions != 0) {
            // reduce the total length of the executions array.
            assembly {
                mstore(explicitExecutions, sub(mload(explicitExecutions), filteredExecutions))
            }
        }

        implicitExecutionsPost = processImplicitPostOrderExecutions(details, availableOrders);

        nativeTokensReturned =
            _handleExcessNativeTokens(details, explicitExecutions, implicitExecutionsPre, implicitExecutionsPost);
    }

    function processExcessNativeTokens(
        Execution[] memory explicitExecutions,
        Execution[] memory implicitExecutionsPre,
        Execution[] memory implicitExecutionsPost
    ) internal pure returns (uint256 excessNativeTokens) {
        for (uint256 i; i < implicitExecutionsPre.length; i++) {
            excessNativeTokens += implicitExecutionsPre[i].item.amount;
        }
        for (uint256 i; i < explicitExecutions.length; i++) {
            ReceivedItem memory item = explicitExecutions[i].item;
            if (item.itemType == ItemType.NATIVE) {
                if (item.amount > excessNativeTokens) {
                    revert("ExecutionsHelper: explicit execution amount exceeds seaport balance");
                }
                excessNativeTokens -= item.amount;
            }
        }
        for (uint256 i; i < implicitExecutionsPost.length; i++) {
            ReceivedItem memory item = implicitExecutionsPost[i].item;
            if (item.itemType == ItemType.NATIVE) {
                if (item.amount > excessNativeTokens) {
                    revert("ExecutionsHelper: post execution amount exceeds seaport balance");
                }
                excessNativeTokens -= item.amount;
            }
        }
    }

    function getStandardExecutions(FulfillmentDetails memory details)
        public
        pure
        returns (Execution[] memory implicitExecutions, uint256 nativeTokensReturned)
    {
        if (details.orders.length != 1) {
            revert("ExecutionHelper: bad orderDetails length for standard");
        }

        return getStandardExecutions(
            details.orders[0],
            details.fulfiller,
            details.fulfillerConduitKey,
            details.recipient,
            details.nativeTokensSupplied,
            details.seaport
        );
    }

    /**
     * @dev Return executions for fulfilOrder and fulfillAdvancedOrder.
     */
    function getStandardExecutions(
        OrderDetails memory orderDetails,
        address fulfiller,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 nativeTokensSupplied,
        address seaport
    ) public pure returns (Execution[] memory implicitExecutions, uint256 nativeTokensReturned) {
        uint256 currentSeaportBalance = 0;

        // implicit executions (use max and resize at end):
        //  - supplying native tokens (0-1)
        //  - providing native tokens from contract offerer (0-offer.length)
        //  - transferring offer items to recipient (offer.length)
        //  - transferring consideration items to each recipient (consideration.length)
        //  - returning unspent native tokens (0-1)
        implicitExecutions = new Execution[](
            2 *
                orderDetails.offer.length +
                orderDetails.consideration.length +
                2
        );

        uint256 executionIndex = 0;

        if (nativeTokensSupplied > 0) {
            implicitExecutions[executionIndex++] = Execution({
                offerer: fulfiller,
                conduitKey: fulfillerConduitKey,
                item: ReceivedItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifier: uint256(0),
                    amount: nativeTokensSupplied,
                    recipient: payable(seaport)
                })
            });
            currentSeaportBalance += nativeTokensSupplied;
        }

        if (orderDetails.isContract) {
            for (uint256 i = 0; i < orderDetails.offer.length; i++) {
                SpentItem memory item = orderDetails.offer[i];
                if (item.itemType == ItemType.NATIVE) {
                    implicitExecutions[executionIndex++] = Execution({
                        offerer: orderDetails.offerer,
                        conduitKey: orderDetails.conduitKey,
                        item: ReceivedItem({
                            itemType: ItemType.NATIVE,
                            token: address(0),
                            identifier: uint256(0),
                            amount: orderDetails.offer[i].amount,
                            recipient: payable(seaport)
                        })
                    });
                    currentSeaportBalance += orderDetails.offer[i].amount;
                }
            }
        }

        for (uint256 i = 0; i < orderDetails.offer.length; i++) {
            SpentItem memory item = orderDetails.offer[i];
            implicitExecutions[executionIndex++] = Execution({
                offerer: item.itemType == ItemType.NATIVE ? seaport : orderDetails.offerer,
                conduitKey: orderDetails.conduitKey,
                item: ReceivedItem({
                    itemType: item.itemType,
                    token: item.token,
                    identifier: item.identifier,
                    amount: item.amount,
                    recipient: payable(recipient)
                })
            });
            if (item.itemType == ItemType.NATIVE) {
                if (item.amount > currentSeaportBalance) {
                    revert("ExecutionHelper: offer item amount exceeds seaport balance");
                }

                currentSeaportBalance -= item.amount;
            }
        }

        for (uint256 i = 0; i < orderDetails.consideration.length; i++) {
            ReceivedItem memory item = orderDetails.consideration[i];
            implicitExecutions[executionIndex++] = Execution({
                offerer: item.itemType == ItemType.NATIVE ? seaport : fulfiller,
                conduitKey: fulfillerConduitKey,
                item: item
            });
            if (item.itemType == ItemType.NATIVE) {
                if (item.amount > currentSeaportBalance) {
                    revert("ExecutionHelper: consideration item amount exceeds seaport balance");
                }

                currentSeaportBalance -= item.amount;
            }
        }

        nativeTokensReturned = currentSeaportBalance;

        if (currentSeaportBalance > 0) {
            implicitExecutions[executionIndex++] = Execution({
                offerer: seaport,
                conduitKey: bytes32(0),
                item: ReceivedItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifier: 0,
                    amount: currentSeaportBalance,
                    recipient: payable(fulfiller)
                })
            });
        }

        // Set actual length of the implicit executions array.
        assembly {
            mstore(implicitExecutions, executionIndex)
        }
    }

    function getBasicExecutions(FulfillmentDetails memory details)
        public
        pure
        returns (Execution[] memory implicitExecutions, uint256 nativeTokensReturned)
    {
        if (details.orders.length != 1) {
            revert("ExecutionHelper: bad orderDetails length for basic");
        }

        return getBasicExecutions(
            details.orders[0],
            details.fulfiller,
            details.fulfillerConduitKey,
            details.nativeTokensSupplied,
            details.seaport
        );
    }

    /**
     * @dev return executions for fulfillBasicOrder and
     *      fulfillBasicOrderEfficient.
     */
    function getBasicExecutions(
        OrderDetails memory orderDetails,
        address fulfiller,
        bytes32 fulfillerConduitKey,
        uint256 nativeTokensSupplied,
        address seaport
    ) public pure returns (Execution[] memory implicitExecutions, uint256 nativeTokensReturned) {
        if (orderDetails.offer.length != 1) {
            revert("not a basic order");
        }

        if (orderDetails.offer[0].itemType == ItemType.ERC20) {
            require(nativeTokensSupplied == 0, "native tokens not allowed");
            require(orderDetails.consideration.length > 0, "no items received");

            implicitExecutions = new Execution[](
                1 + orderDetails.consideration.length
            );

            implicitExecutions[0] =
                Execution({offerer: fulfiller, conduitKey: fulfillerConduitKey, item: orderDetails.consideration[0]});

            uint256 additionalAmounts = 0;

            for (uint256 i = 1; i < orderDetails.consideration.length; i++) {
                implicitExecutions[i] = Execution({
                    offerer: orderDetails.offerer,
                    conduitKey: orderDetails.conduitKey,
                    item: orderDetails.consideration[i]
                });
                additionalAmounts += orderDetails.consideration[i].amount;
            }

            implicitExecutions[orderDetails.consideration.length] = Execution({
                offerer: orderDetails.offerer,
                conduitKey: orderDetails.conduitKey,
                item: ReceivedItem({
                    itemType: orderDetails.offer[0].itemType,
                    token: orderDetails.offer[0].token,
                    identifier: orderDetails.offer[0].identifier,
                    amount: orderDetails.offer[0].amount - additionalAmounts,
                    recipient: payable(fulfiller)
                })
            });
        } else {
            uint256 currentSeaportBalance = 0;

            // implicit executions (use max and resize at end):
            //  - supplying native tokens (0-1)
            //  - transferring offer item to recipient (1)
            //  - transfer additional recipient consideration items (consideration.length - 1)
            //  - transfer first consideration item to the fulfiller (1)
            //  - returning unspent native tokens (0-1)
            implicitExecutions = new Execution[](
                orderDetails.consideration.length + 3
            );

            uint256 executionIndex = 0;

            if (nativeTokensSupplied > 0) {
                implicitExecutions[executionIndex++] = Execution({
                    offerer: fulfiller,
                    conduitKey: fulfillerConduitKey,
                    item: ReceivedItem({
                        itemType: ItemType.NATIVE,
                        token: address(0),
                        identifier: uint256(0),
                        amount: nativeTokensSupplied,
                        recipient: payable(seaport)
                    })
                });
                currentSeaportBalance += nativeTokensSupplied;
            }

            {
                if (orderDetails.offer.length != 1) {
                    revert("ExecutionHelper: wrong length for basic offer");
                }
                SpentItem memory offerItem = orderDetails.offer[0];
                implicitExecutions[executionIndex++] = Execution({
                    offerer: orderDetails.offerer,
                    conduitKey: orderDetails.conduitKey,
                    item: ReceivedItem({
                        itemType: offerItem.itemType,
                        token: offerItem.token,
                        identifier: offerItem.identifier,
                        amount: offerItem.amount,
                        recipient: payable(fulfiller)
                    })
                });
            }

            for (uint256 i = 1; i < orderDetails.consideration.length; i++) {
                ReceivedItem memory item = orderDetails.consideration[i];
                implicitExecutions[executionIndex++] = Execution({
                    offerer: item.itemType == ItemType.NATIVE ? seaport : fulfiller,
                    conduitKey: fulfillerConduitKey,
                    item: item
                });
                if (item.itemType == ItemType.NATIVE) {
                    if (item.amount > currentSeaportBalance) {
                        revert("ExecutionHelper: basic consideration item amount exceeds seaport balance");
                    }

                    currentSeaportBalance -= item.amount;
                }
            }

            {
                if (orderDetails.consideration.length < 1) {
                    revert("ExecutionHelper: wrong length for basic consideration");
                }
                ReceivedItem memory item = orderDetails.consideration[0];
                implicitExecutions[executionIndex++] = Execution({
                    offerer: item.itemType == ItemType.NATIVE ? seaport : fulfiller,
                    conduitKey: fulfillerConduitKey,
                    item: item
                });
                if (item.itemType == ItemType.NATIVE) {
                    if (item.amount > currentSeaportBalance) {
                        revert("ExecutionHelper: first basic consideration item amount exceeds seaport balance");
                    }

                    currentSeaportBalance -= item.amount;
                }
            }

            nativeTokensReturned = currentSeaportBalance;

            if (currentSeaportBalance > 0) {
                implicitExecutions[executionIndex++] = Execution({
                    offerer: seaport,
                    conduitKey: bytes32(0),
                    item: ReceivedItem({
                        itemType: ItemType.NATIVE,
                        token: address(0),
                        identifier: 0,
                        amount: currentSeaportBalance,
                        recipient: payable(fulfiller)
                    })
                });
            }

            // Set actual length of the implicit executions array.
            assembly {
                mstore(implicitExecutions, executionIndex)
            }
        }
    }

    /**
     * @dev Get the item and recipient for a given fulfillment component.
     *
     * @param fulfillmentDetails The order fulfillment details
     * @param offerRecipient     The offer recipient
     * @param component          The fulfillment component
     * @param side               The side of the order
     *
     * @return item          The item
     * @return trueRecipient The actual recipient
     */
    function getItemAndRecipient(
        FulfillmentDetails memory fulfillmentDetails,
        address payable offerRecipient,
        FulfillmentComponent memory component,
        Side side
    ) internal pure returns (SpentItem memory item, address payable trueRecipient) {
        OrderDetails memory details = fulfillmentDetails.orders[component.orderIndex];

        if (side == Side.OFFER) {
            item = details.offer[component.itemIndex];
            trueRecipient = offerRecipient;
        } else {
            ReceivedItem memory _item = details.consideration[component.itemIndex];
            // cast to SpentItem
            assembly {
                item := _item
            }
            trueRecipient = _item.recipient;
        }
    }

    /**
     * @dev Process the aggregated fulfillment components for a given side of an
     *      order.
     *
     * @param fulfillmentDetails   The order fulfillment details
     * @param offerRecipient       The recipient for any offer items. Note: may
     *                             not be FulfillmentDetails' recipient, eg,
     *                             when processing matchOrders fulfillments
     * @param aggregatedComponents The aggregated fulfillment components
     * @param side                 The side of the order
     *
     * @return The execution
     */
    function processExecutionFromAggregatedFulfillmentComponents(
        FulfillmentDetails memory fulfillmentDetails,
        address payable offerRecipient,
        FulfillmentComponent[] memory aggregatedComponents,
        Side side
    ) internal pure returns (Execution memory) {
        // aggregate the amounts of each item
        uint256 aggregatedAmount;
        for (uint256 j = 0; j < aggregatedComponents.length; j++) {
            (SpentItem memory item,) =
                getItemAndRecipient(fulfillmentDetails, offerRecipient, aggregatedComponents[j], side);
            aggregatedAmount += item.amount;
        }

        // use the first fulfillment component to get the order details
        FulfillmentComponent memory first = aggregatedComponents[0];
        (SpentItem memory firstItem, address payable trueRecipient) =
            getItemAndRecipient(fulfillmentDetails, offerRecipient, first, side);
        OrderDetails memory details = fulfillmentDetails.orders[first.orderIndex];

        return Execution({
            offerer: side == Side.OFFER ? details.offerer : fulfillmentDetails.fulfiller,
            conduitKey: side == Side.OFFER ? details.conduitKey : fulfillmentDetails.fulfillerConduitKey,
            item: ReceivedItem({
                itemType: firstItem.itemType,
                token: firstItem.token,
                identifier: firstItem.identifier,
                amount: aggregatedAmount,
                recipient: trueRecipient
            })
        });
    }

    /**
     * @dev Process explicit executions from 2d aggregated fulfillAvailable
     *      fulfillment components arrays. Note that amounts on OrderDetails are
     *      modified in-place during fulfillment processing.
     *
     * @param fulfillmentDetails      The fulfillment details
     * @param offerComponents         The offer components
     * @param considerationComponents The consideration components
     *
     * @return explicitExecutions The explicit executions
     */
    function processExplicitExecutionsFromAggregatedComponents(
        FulfillmentDetails memory fulfillmentDetails,
        FulfillmentComponent[][] memory offerComponents,
        FulfillmentComponent[][] memory considerationComponents,
        bool[] memory availableOrders
    ) internal pure returns (Execution[] memory explicitExecutions) {
        explicitExecutions = new Execution[](
            offerComponents.length + considerationComponents.length
        );

        uint256 filteredExecutions = 0;

        // process offer components
        // iterate over each array of fulfillment components
        for (uint256 i = 0; i < offerComponents.length; i++) {
            FulfillmentComponent[] memory aggregatedComponents = offerComponents[i];

            // aggregate & zero-out the amounts of each offer item
            uint256 aggregatedAmount;
            for (uint256 j = 0; j < aggregatedComponents.length; j++) {
                FulfillmentComponent memory component = aggregatedComponents[j];

                if (!availableOrders[component.orderIndex]) {
                    continue;
                }

                OrderDetails memory offerOrderDetails = fulfillmentDetails.orders[component.orderIndex];

                if (component.itemIndex < offerOrderDetails.offer.length) {
                    SpentItem memory item = offerOrderDetails.offer[component.itemIndex];

                    aggregatedAmount += item.amount;

                    item.amount = 0;
                }
            }

            if (aggregatedAmount == 0) {
                filteredExecutions++;
                continue;
            }

            // use the first fulfillment component to get the order details
            FulfillmentComponent memory first = aggregatedComponents[0];
            OrderDetails memory details = fulfillmentDetails.orders[first.orderIndex];
            SpentItem memory firstItem = details.offer[first.itemIndex];

            if (fulfillmentDetails.recipient == details.offerer && firstItem.itemType != ItemType.NATIVE) {
                filteredExecutions++;
            } else {
                explicitExecutions[i - filteredExecutions] = Execution({
                    offerer: details.offerer,
                    conduitKey: details.conduitKey,
                    item: ReceivedItem({
                        itemType: firstItem.itemType,
                        token: firstItem.token,
                        identifier: firstItem.identifier,
                        amount: aggregatedAmount,
                        recipient: fulfillmentDetails.recipient
                    })
                });
            }
        }

        // process consideration components
        // iterate over each array of fulfillment components
        for (uint256 i; i < considerationComponents.length; i++) {
            FulfillmentComponent[] memory aggregatedComponents = considerationComponents[i];

            // aggregate & zero-out the amounts of each offer item
            uint256 aggregatedAmount;
            for (uint256 j = 0; j < aggregatedComponents.length; j++) {
                FulfillmentComponent memory component = aggregatedComponents[j];

                if (!availableOrders[component.orderIndex]) {
                    continue;
                }

                OrderDetails memory considerationOrderDetails = fulfillmentDetails.orders[component.orderIndex];

                if (component.itemIndex < considerationOrderDetails.consideration.length) {
                    ReceivedItem memory item = considerationOrderDetails.consideration[component.itemIndex];

                    aggregatedAmount += item.amount;

                    item.amount = 0;
                }
            }

            if (aggregatedAmount == 0) {
                filteredExecutions++;
                continue;
            }

            // use the first fulfillment component to get the order details
            FulfillmentComponent memory first = aggregatedComponents[0];
            OrderDetails memory details = fulfillmentDetails.orders[first.orderIndex];
            ReceivedItem memory firstItem = details.consideration[first.itemIndex];

            if (firstItem.recipient == fulfillmentDetails.fulfiller && firstItem.itemType != ItemType.NATIVE) {
                filteredExecutions++;
            } else {
                explicitExecutions[i + offerComponents.length - filteredExecutions] = Execution({
                    offerer: fulfillmentDetails.fulfiller,
                    conduitKey: fulfillmentDetails.fulfillerConduitKey,
                    item: ReceivedItem({
                        itemType: firstItem.itemType,
                        token: firstItem.token,
                        identifier: firstItem.identifier,
                        amount: aggregatedAmount,
                        recipient: firstItem.recipient
                    })
                });
            }
        }

        // If some number of executions have been filtered...
        if (filteredExecutions != 0) {
            // reduce the total length of the executions array.
            assembly {
                mstore(explicitExecutions, sub(mload(explicitExecutions), filteredExecutions))
            }
        }
    }

    /**
     * @dev Process an array of *sorted* fulfillment components into an array of
     *      executions. Note that components must be sorted.
     *
     * @param orderDetails The order details
     * @param components   The fulfillment components
     * @param recipient    The recipient of implicit executions
     *
     * @return executions The executions
     */
    function processExecutionsFromIndividualOfferFulfillmentComponents(
        OrderDetails[] memory orderDetails,
        address payable recipient,
        FulfillmentComponent[] memory components
    ) internal pure returns (Execution[] memory executions) {
        executions = new Execution[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            FulfillmentComponent memory component = components[i];
            OrderDetails memory details = orderDetails[component.orderIndex];
            SpentItem memory item = details.offer[component.itemIndex];
            executions[i] = Execution({
                offerer: details.offerer,
                conduitKey: details.conduitKey,
                item: ReceivedItem({
                    itemType: item.itemType,
                    token: item.token,
                    identifier: item.identifier,
                    amount: item.amount,
                    recipient: recipient
                })
            });
        }
    }

    /**
     * @dev Generate implicit Executions for a set of orders by getting all
     *      offer items that are not fully spent as part of a fulfillment.
     *
     * @param fulfillmentDetails fulfillment details
     *
     * @return implicitExecutions The implicit executions
     */
    function processImplicitPreOrderExecutions(
        FulfillmentDetails memory fulfillmentDetails,
        bool[] memory availableOrders
    ) internal pure returns (Execution[] memory implicitExecutions) {
        // Get the maximum possible number of implicit executions.
        uint256 maxPossible = 1;
        for (uint256 i = 0; i < fulfillmentDetails.orders.length; ++i) {
            if (availableOrders[i]) {
                maxPossible += fulfillmentDetails.orders[i].offer.length;
            }
        }
        implicitExecutions = new Execution[](maxPossible);

        uint256 executionIndex;
        if (fulfillmentDetails.nativeTokensSupplied > 0) {
            implicitExecutions[executionIndex++] = Execution({
                offerer: fulfillmentDetails.fulfiller,
                conduitKey: bytes32(0),
                item: ReceivedItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifier: uint256(0),
                    amount: fulfillmentDetails.nativeTokensSupplied,
                    recipient: payable(fulfillmentDetails.seaport)
                })
            });
        }

        for (uint256 o; o < fulfillmentDetails.orders.length; o++) {
            OrderDetails memory orderDetails = fulfillmentDetails.orders[o];
            if (!availableOrders[o]) {
                continue;
            }

            if (orderDetails.isContract) {
                for (uint256 i = 0; i < orderDetails.offer.length; i++) {
                    SpentItem memory item = orderDetails.offer[i];
                    if (item.itemType == ItemType.NATIVE) {
                        implicitExecutions[executionIndex++] = Execution({
                            offerer: orderDetails.offerer,
                            conduitKey: bytes32(0),
                            item: ReceivedItem({
                                itemType: ItemType.NATIVE,
                                token: address(0),
                                identifier: uint256(0),
                                amount: item.amount,
                                recipient: payable(fulfillmentDetails.seaport)
                            })
                        });
                    }
                }
            }
        }

        // Set the final length of the implicit executions array.
        // Leave space for possible excess native token return.
        assembly {
            mstore(implicitExecutions, executionIndex)
        }
    }

    /**
     * @dev Generate implicit Executions for a set of orders by getting all
     *      offer items that are not fully spent as part of a fulfillment.
     *
     * @param fulfillmentDetails fulfillment details
     *
     * @return implicitExecutions The implicit executions
     */
    function processImplicitPostOrderExecutions(
        FulfillmentDetails memory fulfillmentDetails,
        bool[] memory availableOrders
    ) internal pure returns (Execution[] memory implicitExecutions) {
        OrderDetails[] memory orderDetails = fulfillmentDetails.orders;

        // Get the maximum possible number of implicit executions.
        uint256 maxPossible = 1;
        for (uint256 i = 0; i < orderDetails.length; ++i) {
            if (availableOrders[i]) {
                maxPossible += orderDetails[i].offer.length;
            }
        }

        // Insert an implicit execution for each non-zero offer item.
        implicitExecutions = new Execution[](maxPossible);
        uint256 insertionIndex = 0;
        for (uint256 i = 0; i < orderDetails.length; ++i) {
            if (!availableOrders[i]) {
                continue;
            }

            OrderDetails memory details = orderDetails[i];
            for (uint256 j; j < details.offer.length; ++j) {
                SpentItem memory item = details.offer[j];
                if (item.amount != 0) {
                    // Insert the item and increment insertion index.
                    implicitExecutions[insertionIndex++] = Execution({
                        offerer: item.itemType == ItemType.NATIVE ? fulfillmentDetails.seaport : details.offerer,
                        conduitKey: details.conduitKey,
                        item: ReceivedItem({
                            itemType: item.itemType,
                            token: item.token,
                            identifier: item.identifier,
                            amount: item.amount,
                            recipient: fulfillmentDetails.recipient
                        })
                    });
                }
            }
        }

        // Set the final length of the implicit executions array.
        // Leave space for possible excess native token return.
        assembly {
            mstore(implicitExecutions, add(insertionIndex, 1))
        }
    }

    /**
     * @dev Process a Fulfillment into an Execution
     *
     * @param fulfillmentDetails fulfillment details
     * @param fulfillment A Fulfillment.
     *
     * @return An Execution.
     */
    function processExecutionFromFulfillment(
        FulfillmentDetails memory fulfillmentDetails,
        Fulfillment memory fulfillment
    ) internal pure returns (Execution memory) {
        // aggregate & zero-out the amounts of each offer item
        uint256 aggregatedOfferAmount;
        for (uint256 j = 0; j < fulfillment.offerComponents.length; j++) {
            FulfillmentComponent memory component = fulfillment.offerComponents[j];

            OrderDetails memory details = fulfillmentDetails.orders[component.orderIndex];

            if (component.itemIndex < details.offer.length) {
                SpentItem memory offerSpentItem = details.offer[component.itemIndex];

                aggregatedOfferAmount += offerSpentItem.amount;

                offerSpentItem.amount = 0;
            }
        }

        // aggregate & zero-out the amounts of each offer item
        uint256 aggregatedConsiderationAmount;
        for (uint256 j = 0; j < fulfillment.considerationComponents.length; j++) {
            FulfillmentComponent memory component = fulfillment.considerationComponents[j];

            OrderDetails memory details = fulfillmentDetails.orders[component.orderIndex];

            if (component.itemIndex < details.consideration.length) {
                ReceivedItem memory considerationSpentItem = details.consideration[component.itemIndex];

                aggregatedConsiderationAmount += considerationSpentItem.amount;

                considerationSpentItem.amount = 0;
            }
        }

        // Get the first item on each side
        FulfillmentComponent memory firstOfferComponent = fulfillment.offerComponents[0];
        OrderDetails memory sourceOrder = fulfillmentDetails.orders[firstOfferComponent.orderIndex];

        FulfillmentComponent memory firstConsiderationComponent = fulfillment.considerationComponents[0];
        ReceivedItem memory item = fulfillmentDetails.orders[firstConsiderationComponent.orderIndex].consideration[firstConsiderationComponent
            .itemIndex];

        // put back any extra (TODO: put it on first *in-range* item)
        uint256 amount = aggregatedOfferAmount;
        if (aggregatedOfferAmount > aggregatedConsiderationAmount) {
            sourceOrder.offer[firstOfferComponent.itemIndex].amount +=
                (aggregatedOfferAmount - aggregatedConsiderationAmount);
            amount = aggregatedConsiderationAmount;
        } else if (aggregatedOfferAmount < aggregatedConsiderationAmount) {
            item.amount += (aggregatedConsiderationAmount - aggregatedOfferAmount);
        }

        return Execution({
            offerer: sourceOrder.offerer,
            conduitKey: sourceOrder.conduitKey,
            item: ReceivedItem({
                itemType: item.itemType,
                token: item.token,
                identifier: item.identifier,
                amount: amount,
                recipient: item.recipient
            })
        });
    }

    /**
     * @dev Process excess native tokens.  If there are excess native tokens,
     *      insert an implicit execution at the end of the implicitExecutions
     *      array. If not, reduce the length of the implicitExecutions array.
     *
     * @param fulfillmentDetails fulfillment details
     * @param explicitExecutions explicit executions
     * @param implicitExecutionsPre implicit executions
     * @param implicitExecutionsPost implicit executions
     */
    function _handleExcessNativeTokens(
        FulfillmentDetails memory fulfillmentDetails,
        Execution[] memory explicitExecutions,
        Execution[] memory implicitExecutionsPre,
        Execution[] memory implicitExecutionsPost
    ) internal pure returns (uint256 excessNativeTokens) {
        excessNativeTokens =
            processExcessNativeTokens(explicitExecutions, implicitExecutionsPre, implicitExecutionsPost);

        if (excessNativeTokens > 0) {
            implicitExecutionsPost[implicitExecutionsPost.length - 1] = Execution({
                offerer: fulfillmentDetails.seaport,
                conduitKey: bytes32(0),
                item: ReceivedItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifier: 0,
                    amount: excessNativeTokens,
                    recipient: fulfillmentDetails.fulfiller
                })
            });
        } else {
            // Reduce length of the implicit executions array by one.
            assembly {
                mstore(implicitExecutionsPost, sub(mload(implicitExecutionsPost), 1))
            }
        }
    }

    function copy(OrderDetails[] memory orderDetails)
        internal
        pure
        returns (OrderDetails[] memory copiedOrderDetails)
    {
        copiedOrderDetails = new OrderDetails[](orderDetails.length);
        for (uint256 i = 0; i < orderDetails.length; ++i) {
            OrderDetails memory order = orderDetails[i];

            copiedOrderDetails[i] = OrderDetails({
                offerer: order.offerer,
                conduitKey: order.conduitKey,
                offer: order.offer.copy(),
                consideration: order.consideration.copy(),
                isContract: order.isContract,
                orderHash: order.orderHash,
                unavailableReason: order.unavailableReason
            });
        }
    }

    function copy(FulfillmentDetails memory fulfillmentDetails) internal pure returns (FulfillmentDetails memory) {
        return FulfillmentDetails({
            orders: copy(fulfillmentDetails.orders),
            recipient: fulfillmentDetails.recipient,
            fulfiller: fulfillmentDetails.fulfiller,
            nativeTokensSupplied: fulfillmentDetails.nativeTokensSupplied,
            fulfillerConduitKey: fulfillmentDetails.fulfillerConduitKey,
            seaport: fulfillmentDetails.seaport
        });
    }
}
