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

import {SeaportInterface} from "OpenSea-Seaport/seaport-types/src/interfaces/SeaportInterface.sol";
import {AmountDeriver} from "OpenSea-Seaport/seaport-core/src/lib/AmountDeriver.sol";
import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    OfferItem,
    Order,
    OrderComponents,
    OrderParameters,
    OrderType,
    ReceivedItem,
    SpentItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";
import {Side, ItemType} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItemLib} from "../OfferItemLib.sol";
import {ConsiderationItemLib} from "../ConsiderationItemLib.sol";
import {OrderParametersLib} from "../OrderParametersLib.sol";
import {OrderDetails} from "../../fulfillments/lib/Structs.sol";
import {UnavailableReason} from "../../SpaceEnums.sol";

/**
 * @notice Note that this contract relies on current block.timestamp to determine amounts.
 */
contract AmountDeriverHelper is AmountDeriver {
    using OfferItemLib for OfferItem[];
    using ConsiderationItemLib for ConsiderationItem[];
    using OrderParametersLib for OrderParameters;

    struct ContractNonceDetails {
        bool set;
        address offerer;
        uint256 currentNonce;
    }

    function getSpentAndReceivedItems(Order calldata order)
        external
        view
        returns (SpentItem[] memory spent, ReceivedItem[] memory received)
    {
        return getSpentAndReceivedItems(order.parameters);
    }

    function getSpentAndReceivedItems(AdvancedOrder calldata order)
        external
        view
        returns (SpentItem[] memory spent, ReceivedItem[] memory received)
    {
        CriteriaResolver[] memory resolvers;
        return getSpentAndReceivedItems(order.parameters, order.numerator, order.denominator, 0, resolvers);
    }

    function getSpentAndReceivedItems(
        AdvancedOrder calldata order,
        uint256 orderIndex,
        CriteriaResolver[] calldata criteriaResolvers
    ) external view returns (SpentItem[] memory spent, ReceivedItem[] memory received) {
        return getSpentAndReceivedItems(
            order.parameters, order.numerator, order.denominator, orderIndex, criteriaResolvers
        );
    }

    function getSpentAndReceivedItems(OrderParameters calldata parameters)
        public
        view
        returns (SpentItem[] memory spent, ReceivedItem[] memory received)
    {
        if (parameters.isAvailable()) {
            spent = getSpentItems(parameters);
            received = getReceivedItems(parameters);
        }
    }

    function toOrderDetails(OrderParameters memory order, bytes32 orderHash, UnavailableReason unavailableReason)
        internal
        view
        returns (OrderDetails memory)
    {
        (SpentItem[] memory offer, ReceivedItem[] memory consideration) = this.getSpentAndReceivedItems(order);
        return OrderDetails({
            offerer: order.offerer,
            conduitKey: order.conduitKey,
            offer: offer,
            consideration: consideration,
            isContract: order.orderType == OrderType.CONTRACT,
            orderHash: orderHash,
            unavailableReason: unavailableReason
        });
    }

    function toOrderDetails(
        Order[] memory order,
        bytes32[] memory orderHashes,
        UnavailableReason[] memory unavailableReasons
    ) public view returns (OrderDetails[] memory) {
        OrderDetails[] memory orderDetails = new OrderDetails[](order.length);
        for (uint256 i = 0; i < order.length; i++) {
            orderDetails[i] = toOrderDetails(order[i].parameters, orderHashes[i], unavailableReasons[i]);
        }
        return orderDetails;
    }

    function toOrderDetails(
        AdvancedOrder[] memory orders,
        CriteriaResolver[] memory resolvers,
        bytes32[] memory orderHashes,
        UnavailableReason[] memory unavailableReasons
    ) public view returns (OrderDetails[] memory) {
        OrderDetails[] memory orderDetails = new OrderDetails[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            orderDetails[i] = toOrderDetails(orders[i], i, resolvers, orderHashes[i], unavailableReasons[i]);
        }
        return orderDetails;
    }

    function toOrderDetails(
        AdvancedOrder memory order,
        uint256 orderIndex,
        CriteriaResolver[] memory resolvers,
        bytes32 orderHash,
        UnavailableReason unavailableReason
    ) internal view returns (OrderDetails memory) {
        (SpentItem[] memory offer, ReceivedItem[] memory consideration) =
            this.getSpentAndReceivedItems(order, orderIndex, resolvers);

        return OrderDetails({
            offerer: order.parameters.offerer,
            conduitKey: order.parameters.conduitKey,
            offer: offer,
            consideration: consideration,
            isContract: order.parameters.orderType == OrderType.CONTRACT,
            orderHash: orderHash,
            unavailableReason: unavailableReason
        });
    }

    function getSpentAndReceivedItems(
        OrderParameters memory parameters,
        uint256 numerator,
        uint256 denominator,
        uint256 orderIndex,
        CriteriaResolver[] memory criteriaResolvers
    ) private view returns (SpentItem[] memory spent, ReceivedItem[] memory received) {
        if (parameters.isAvailable()) {
            spent = getSpentItems(parameters, numerator, denominator);
            received = getReceivedItems(parameters, numerator, denominator);

            applyCriteriaResolvers(spent, received, orderIndex, criteriaResolvers);
        }
    }

    function applyCriteriaResolvers(
        SpentItem[] memory spentItems,
        ReceivedItem[] memory receivedItems,
        uint256 orderIndex,
        CriteriaResolver[] memory criteriaResolvers
    ) private pure {
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

    function convertCriteriaItemType(ItemType itemType) internal pure returns (ItemType) {
        if (itemType == ItemType.ERC721_WITH_CRITERIA) {
            return ItemType.ERC721;
        } else if (itemType == ItemType.ERC1155_WITH_CRITERIA) {
            return ItemType.ERC1155;
        } else {
            revert("amount deriver helper resolving non criteria item type");
        }
    }

    function getSpentItems(OrderParameters memory parameters, uint256 numerator, uint256 denominator)
        private
        view
        returns (SpentItem[] memory)
    {
        return getSpentItems(parameters.offer, parameters.startTime, parameters.endTime, numerator, denominator);
    }

    function getSpentItems(OrderParameters memory parameters) private view returns (SpentItem[] memory) {
        return getSpentItems(parameters.offer, parameters.startTime, parameters.endTime);
    }

    function getSpentItems(OfferItem[] memory offerItems, uint256 startTime, uint256 endTime)
        private
        view
        returns (SpentItem[] memory)
    {
        SpentItem[] memory spentItems = new SpentItem[](offerItems.length);
        for (uint256 i = 0; i < offerItems.length; i++) {
            spentItems[i] = getSpentItem(offerItems[i], startTime, endTime);
        }
        return spentItems;
    }

    function getSpentItems(
        OfferItem[] memory items,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) private view returns (SpentItem[] memory) {
        SpentItem[] memory spentItems = new SpentItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            spentItems[i] = getSpentItem(items[i], startTime, endTime, numerator, denominator);
        }
        return spentItems;
    }

    function getSpentItem(OfferItem memory offerItem, uint256 startTime, uint256 endTime)
        private
        view
        returns (SpentItem memory spent)
    {
        spent = SpentItem({
            itemType: offerItem.itemType,
            token: offerItem.token,
            identifier: offerItem.identifierOrCriteria,
            amount: _locateCurrentAmount({item: offerItem, startTime: startTime, endTime: endTime})
        });
    }

    function getSpentItem(
        OfferItem memory item,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) private view returns (SpentItem memory spent) {
        // Detect if the order has an invalid time;
        // if so, set amount to zero
        spent = SpentItem({
            itemType: item.itemType,
            token: item.token,
            identifier: item.identifierOrCriteria,
            amount: (block.timestamp < startTime || block.timestamp >= endTime)
                ? 0
                : _applyFraction({
                    numerator: numerator,
                    denominator: denominator,
                    item: item,
                    startTime: startTime,
                    endTime: endTime
                })
        });
    }

    function getReceivedItems(OrderParameters memory parameters) private view returns (ReceivedItem[] memory) {
        return getReceivedItems(parameters.consideration, parameters.startTime, parameters.endTime);
    }

    function getReceivedItems(OrderParameters memory parameters, uint256 numerator, uint256 denominator)
        private
        view
        returns (ReceivedItem[] memory)
    {
        return
            getReceivedItems(parameters.consideration, parameters.startTime, parameters.endTime, numerator, denominator);
    }

    function getReceivedItems(ConsiderationItem[] memory considerationItems, uint256 startTime, uint256 endTime)
        private
        view
        returns (ReceivedItem[] memory)
    {
        ReceivedItem[] memory receivedItems = new ReceivedItem[](
            considerationItems.length
        );
        for (uint256 i = 0; i < considerationItems.length; i++) {
            receivedItems[i] = getReceivedItem(considerationItems[i], startTime, endTime);
        }
        return receivedItems;
    }

    function getReceivedItems(
        ConsiderationItem[] memory considerationItems,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) private view returns (ReceivedItem[] memory) {
        ReceivedItem[] memory receivedItems = new ReceivedItem[](
            considerationItems.length
        );
        for (uint256 i = 0; i < considerationItems.length; i++) {
            receivedItems[i] = getReceivedItem(considerationItems[i], startTime, endTime, numerator, denominator);
        }
        return receivedItems;
    }

    function getReceivedItem(ConsiderationItem memory considerationItem, uint256 startTime, uint256 endTime)
        private
        view
        returns (ReceivedItem memory received)
    {
        received = ReceivedItem({
            itemType: considerationItem.itemType,
            token: considerationItem.token,
            identifier: considerationItem.identifierOrCriteria,
            amount: _locateCurrentAmount({item: considerationItem, startTime: startTime, endTime: endTime}),
            recipient: considerationItem.recipient
        });
    }

    function getReceivedItem(
        ConsiderationItem memory considerationItem,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) private view returns (ReceivedItem memory received) {
        // Detect if the order has an invalid time;
        // if so, set amount to zero
        received = ReceivedItem({
            itemType: considerationItem.itemType,
            token: considerationItem.token,
            identifier: considerationItem.identifierOrCriteria,
            amount: (block.timestamp < startTime || block.timestamp >= endTime)
                ? 0
                : _applyFraction({
                    numerator: numerator,
                    denominator: denominator,
                    item: considerationItem,
                    startTime: startTime,
                    endTime: endTime
                }),
            recipient: considerationItem.recipient
        });
    }

    function _locateCurrentAmount(OfferItem memory item, uint256 startTime, uint256 endTime)
        private
        view
        returns (uint256)
    {
        return _locateCurrentAmount({
            startAmount: item.startAmount,
            endAmount: item.endAmount,
            startTime: startTime,
            endTime: endTime,
            roundUp: false
        });
    }

    function deriveFractionCompatibleAmounts(
        uint256 originalStartAmount,
        uint256 originalEndAmount,
        uint256 startTime,
        uint256 endTime,
        uint256 numerator,
        uint256 denominator
    ) public pure returns (uint256 newStartAmount, uint256 newEndAmount) {
        if (
            startTime >= endTime || numerator > denominator || numerator == 0 || denominator == 0
                || (originalStartAmount == 0 && originalEndAmount == 0)
        ) {
            revert("AmountDeriverHelper: bad inputs to deriveFractionCompatibleAmounts");
        }

        uint256 duration = endTime - startTime;

        // determine if duration or numerator is more likely to overflow when multiplied by value
        uint256 overflowBottleneck = (numerator > duration) ? numerator : duration;

        uint256 absoluteMax = type(uint256).max / overflowBottleneck;
        uint256 fractionCompatibleMax = (absoluteMax / denominator) * denominator;

        newStartAmount = originalStartAmount % fractionCompatibleMax;
        newStartAmount = (newStartAmount / denominator) * denominator;
        newStartAmount = (newStartAmount == 0) ? denominator : newStartAmount;

        newEndAmount = originalEndAmount % fractionCompatibleMax;
        newEndAmount = (newEndAmount / denominator) * denominator;
        newEndAmount = (newEndAmount == 0) ? denominator : newEndAmount;

        if (newStartAmount == 0 && newEndAmount == 0) {
            revert("AmountDeriverHelper: derived amount will always be zero");
        }
    }

    function _locateCurrentAmount(ConsiderationItem memory item, uint256 startTime, uint256 endTime)
        private
        view
        returns (uint256)
    {
        return _locateCurrentAmount({
            startAmount: item.startAmount,
            endAmount: item.endAmount,
            startTime: startTime,
            endTime: endTime,
            roundUp: true
        });
    }

    function _applyFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 startTime,
        uint256 endTime,
        OfferItem memory item
    ) internal view returns (uint256) {
        uint256 startAmount = item.startAmount;
        uint256 endAmount = item.endAmount;
        return _applyFraction({
            numerator: numerator,
            denominator: denominator,
            startAmount: startAmount,
            endAmount: endAmount,
            startTime: startTime,
            endTime: endTime,
            roundUp: false // don't round up offers
        });
    }

    function _applyFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 startTime,
        uint256 endTime,
        ConsiderationItem memory item
    ) internal view returns (uint256) {
        uint256 startAmount = item.startAmount;
        uint256 endAmount = item.endAmount;

        return _applyFraction({
            numerator: numerator,
            denominator: denominator,
            startAmount: startAmount,
            endAmount: endAmount,
            startTime: startTime,
            endTime: endTime,
            roundUp: true // round up considerations
        });
    }
}
