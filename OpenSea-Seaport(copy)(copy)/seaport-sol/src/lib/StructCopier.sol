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
pragma solidity ^0.8.13;

import {
    AdditionalRecipient,
    AdvancedOrder,
    BasicOrderParameters,
    ConsiderationItem,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    OfferItem,
    Order,
    OrderComponents,
    OrderParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ArrayLib } from "./ArrayLib.sol";

library StructCopier {
    function _basicOrderParameters()
        private
        pure
        returns (BasicOrderParameters storage empty)
    {
        bytes32 position = keccak256("StructCopier.EmptyBasicOrderParameters");
        assembly {
            empty.slot := position
        }
        return empty;
    }

    function _criteriaResolver()
        private
        pure
        returns (CriteriaResolver storage empty)
    {
        bytes32 position = keccak256("StructCopier.EmptyCriteriaResolver");
        assembly {
            empty.slot := position
        }
        return empty;
    }

    function _fulfillment() private pure returns (Fulfillment storage empty) {
        bytes32 position = keccak256("StructCopier.EmptyFulfillment");
        assembly {
            empty.slot := position
        }
        return empty;
    }

    function _orderComponents()
        private
        pure
        returns (OrderComponents storage empty)
    {
        bytes32 position = keccak256("StructCopier.EmptyOrderComponents");
        assembly {
            empty.slot := position
        }
        return empty;
    }

    function _orderParameters()
        private
        pure
        returns (OrderParameters storage empty)
    {
        bytes32 position = keccak256("StructCopier.EmptyOrderParameters");
        assembly {
            empty.slot := position
        }
        return empty;
    }

    function _order() private pure returns (Order storage empty) {
        bytes32 position = keccak256("StructCopier.EmptyOrder");
        assembly {
            empty.slot := position
        }
        return empty;
    }

    function setBasicOrderParameters(
        BasicOrderParameters storage dest,
        BasicOrderParameters memory src
    ) internal {
        dest.considerationToken = src.considerationToken;
        dest.considerationIdentifier = src.considerationIdentifier;
        dest.considerationAmount = src.considerationAmount;
        dest.offerer = src.offerer;
        dest.zone = src.zone;
        dest.offerToken = src.offerToken;
        dest.offerIdentifier = src.offerIdentifier;
        dest.offerAmount = src.offerAmount;
        dest.basicOrderType = src.basicOrderType;
        dest.startTime = src.startTime;
        dest.endTime = src.endTime;
        dest.zoneHash = src.zoneHash;
        dest.salt = src.salt;
        dest.offererConduitKey = src.offererConduitKey;
        dest.fulfillerConduitKey = src.fulfillerConduitKey;
        dest.totalOriginalAdditionalRecipients = src
            .totalOriginalAdditionalRecipients;
        setAdditionalRecipients(
            dest.additionalRecipients,
            src.additionalRecipients
        );
        dest.signature = src.signature;
    }

    function setOrderComponents(
        OrderComponents storage dest,
        OrderComponents memory src
    ) internal {
        dest.offerer = src.offerer;
        dest.zone = src.zone;
        setOfferItems(dest.offer, src.offer);
        setConsiderationItems(dest.consideration, src.consideration);
        dest.orderType = src.orderType;
        dest.startTime = src.startTime;
        dest.endTime = src.endTime;
        dest.zoneHash = src.zoneHash;
        dest.salt = src.salt;
        dest.conduitKey = src.conduitKey;
        dest.counter = src.counter;
    }

    function setOrderComponents(
        OrderComponents[] storage dest,
        OrderComponents[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        OrderComponents storage empty = _orderComponents();
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(empty);
            setOrderComponents(dest[i], src[i]);
        }
    }

    function setBasicOrderParameters(
        BasicOrderParameters[] storage dest,
        BasicOrderParameters[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        BasicOrderParameters storage empty = _basicOrderParameters();
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(empty);
            setBasicOrderParameters(dest[i], src[i]);
        }
    }

    function setAdditionalRecipients(
        AdditionalRecipient[] storage dest,
        AdditionalRecipient[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(src[i]);
        }
    }

    function setCriteriaResolver(
        CriteriaResolver storage dest,
        CriteriaResolver memory src
    ) internal {
        dest.orderIndex = src.orderIndex;
        dest.side = src.side;
        dest.index = src.index;
        dest.identifier = src.identifier;
        ArrayLib.setBytes32s(dest.criteriaProof, src.criteriaProof);
    }

    function setCriteriaResolvers(
        CriteriaResolver[] storage dest,
        CriteriaResolver[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        CriteriaResolver storage empty = _criteriaResolver();
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(empty);
            setCriteriaResolver(dest[i], src[i]);
        }
    }

    function setOrder(Order storage dest, Order memory src) internal {
        setOrderParameters(dest.parameters, src.parameters);
        dest.signature = src.signature;
    }

    bytes32 constant TEMP_ORDER = keccak256("seaport-sol.temp.Order");
    bytes32 constant TEMP_COUNTER_SLOT = keccak256("seaport-sol.temp.Counter");

    /**
     * @notice Get a counter used to derive a temporary storage slot.
     * @dev    Solidity does not allow copying dynamic types from memory to storage.
     *         We need a "clean" (empty) temp pointer to make an exact copy of a struct with dynamic members, but
     *         Solidity does not allow calling "delete" on a storage pointer either.
     *         By hashing a struct's temp slot with a monotonically increasing counter, we can derive a new temp slot
     *         that is basically "guaranteed" to have all successive storage slots empty.
     *         TODO: We can revisit adding "clear" methods that definitively wipe all dynamic components of a struct,
     *         but that will require an equal amount of SSTOREs; this is obviously more expensive gas-wise, but may not
     *         make a difference performance-wise when running simiulations locally (though this needs to be tested)
     */
    function _getAndIncrementTempCounter() internal returns (uint256 counter) {
        // get counter slot
        bytes32 counterSlot = TEMP_COUNTER_SLOT;
        assembly {
            // load current value
            counter := sload(counterSlot)
            // store incremented value
            sstore(counterSlot, add(counter, 1))
        }
        // return original value
        return counter;
    }

    function _deriveTempSlotWithCounter(
        bytes32 libSlot
    ) internal returns (uint256 derivedSlot) {
        uint256 counter = _getAndIncrementTempCounter();
        assembly {
            // store lib slot in first mem position
            mstore(0x0, libSlot)
            // store temp counter in second position
            mstore(0x20, counter)
            // hash original slot with counter to get new temp slot, which has a low probability of being dirty
            // (~1/2**256)
            derivedSlot := keccak256(0x0, 0x40)
        }
    }

    function _getTempOrder() internal returns (Order storage _tempOrder) {
        uint256 position = _deriveTempSlotWithCounter(TEMP_ORDER);
        assembly {
            _tempOrder.slot := position
        }
    }

    function setOrders(Order[] storage dest, Order[] memory src) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        Order storage empty = _order();
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(empty);
            setOrder(dest[i], src[i]);
        }
    }

    function setAdvancedOrder(
        AdvancedOrder storage dest,
        AdvancedOrder memory src
    ) internal {
        setOrderParameters(dest.parameters, src.parameters);
        dest.numerator = src.numerator;
        dest.denominator = src.denominator;
        dest.signature = src.signature;
        dest.extraData = src.extraData;
    }

    bytes32 constant TEMP_ADVANCED_ORDER =
        keccak256("seaport-sol.temp.AdvancedOrder");

    function _getTempAdvancedOrder()
        internal
        returns (AdvancedOrder storage _tempAdvancedOrder)
    {
        uint256 position = _deriveTempSlotWithCounter(TEMP_ADVANCED_ORDER);
        assembly {
            _tempAdvancedOrder.slot := position
        }
    }

    function setAdvancedOrders(
        AdvancedOrder[] storage dest,
        AdvancedOrder[] memory src
    ) internal {
        AdvancedOrder storage _tempAdvancedOrder = _getTempAdvancedOrder();

        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            setAdvancedOrder(_tempAdvancedOrder, src[i]);
            dest.push(_tempAdvancedOrder);
        }
    }

    function setOrderParameters(
        OrderParameters storage dest,
        OrderParameters memory src
    ) internal {
        dest.offerer = src.offerer;
        dest.zone = src.zone;
        setOfferItems(dest.offer, src.offer);
        setConsiderationItems(dest.consideration, src.consideration);
        dest.orderType = src.orderType;
        dest.startTime = src.startTime;
        dest.endTime = src.endTime;
        dest.zoneHash = src.zoneHash;
        dest.salt = src.salt;
        dest.conduitKey = src.conduitKey;
        dest.totalOriginalConsiderationItems = src
            .totalOriginalConsiderationItems;
    }

    function setOfferItems(
        OfferItem[] storage dest,
        OfferItem[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(src[i]);
        }
    }

    function setConsiderationItems(
        ConsiderationItem[] storage dest,
        ConsiderationItem[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(src[i]);
        }
    }

    function setFulfillment(
        Fulfillment storage dest,
        Fulfillment memory src
    ) internal {
        setFulfillmentComponents(dest.offerComponents, src.offerComponents);
        setFulfillmentComponents(
            dest.considerationComponents,
            src.considerationComponents
        );
    }

    function setFulfillments(
        Fulfillment[] storage dest,
        Fulfillment[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        Fulfillment storage empty = _fulfillment();
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(empty);
            setFulfillment(dest[i], src[i]);
        }
    }

    function setFulfillmentComponents(
        FulfillmentComponent[] storage dest,
        FulfillmentComponent[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(src[i]);
        }
    }

    bytes32 constant TEMP_FULFILLMENT_COMPONENTS =
        keccak256("seaport-sol.temp.FulfillmentComponents");

    function _getTempFulfillmentComponents()
        internal
        pure
        returns (FulfillmentComponent[] storage _tempFulfillmentComponents)
    {
        bytes32 position = TEMP_FULFILLMENT_COMPONENTS;
        assembly {
            _tempFulfillmentComponents.slot := position
        }
    }

    function pushFulFillmentComponents(
        FulfillmentComponent[][] storage dest,
        FulfillmentComponent[] memory src
    ) internal {
        FulfillmentComponent[]
            storage _tempFulfillmentComponents = _getTempFulfillmentComponents();
        setFulfillmentComponents(_tempFulfillmentComponents, src);
        dest.push(_tempFulfillmentComponents);
    }

    function setFulfillmentComponentsArray(
        FulfillmentComponent[][] storage dest,
        FulfillmentComponent[][] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            pushFulFillmentComponents(dest, src[i]);
        }
    }

    function toConsiderationItems(
        OfferItem[] memory _offerItems,
        address payable receiver
    ) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](
            _offerItems.length
        );
        for (uint256 i = 0; i < _offerItems.length; ++i) {
            considerationItems[i] = ConsiderationItem(
                _offerItems[i].itemType,
                _offerItems[i].token,
                _offerItems[i].identifierOrCriteria,
                _offerItems[i].startAmount,
                _offerItems[i].endAmount,
                receiver
            );
        }
        return considerationItems;
    }

    function toOfferItems(
        ConsiderationItem[] memory _considerationItems
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory _offerItems = new OfferItem[](
            _considerationItems.length
        );
        for (uint256 i = 0; i < _offerItems.length; i++) {
            _offerItems[i] = OfferItem(
                _considerationItems[i].itemType,
                _considerationItems[i].token,
                _considerationItems[i].identifierOrCriteria,
                _considerationItems[i].startAmount,
                _considerationItems[i].endAmount
            );
        }
        return _offerItems;
    }

    function createMirrorOrderParameters(
        OrderParameters memory orderParameters,
        address payable offerer,
        address zone,
        bytes32 conduitKey
    ) public pure returns (OrderParameters memory) {
        OfferItem[] memory _offerItems = toOfferItems(
            orderParameters.consideration
        );
        ConsiderationItem[] memory _considerationItems = toConsiderationItems(
            orderParameters.offer,
            offerer
        );

        OrderParameters memory _mirrorOrderParameters = OrderParameters(
            offerer,
            zone,
            _offerItems,
            _considerationItems,
            orderParameters.orderType,
            orderParameters.startTime,
            orderParameters.endTime,
            orderParameters.zoneHash,
            orderParameters.salt,
            conduitKey,
            _considerationItems.length
        );
        return _mirrorOrderParameters;
    }

    function setExecutions(
        Execution[] storage dest,
        Execution[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(src[i]);
        }
    }

    function setOrderParameters(
        OrderParameters[] storage dest,
        OrderParameters[] memory src
    ) internal {
        while (dest.length != 0) {
            dest.pop();
        }
        OrderParameters storage empty = _orderParameters();
        for (uint256 i = 0; i < src.length; ++i) {
            dest.push(empty);
            setOrderParameters(dest[i], src[i]);
        }
    }
}
