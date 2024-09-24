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
pragma solidity 0.8.17;

import {ItemType, Side} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    AdvancedOrder, Execution, FulfillmentComponent, ReceivedItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    _revertMismatchedFulfillmentOfferAndConsiderationComponents,
    _revertMissingFulfillmentComponentOnAggregation,
    _revertOfferAndConsiderationRequiredOnFulfillment
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrors.sol";

import {FulfillmentApplicationErrors} from "OpenSea-Seaport/seaport-types/src/interfaces/FulfillmentApplicationErrors.sol";

import {
    AdvancedOrder_numerator_offset,
    Common_amount_offset,
    Common_identifier_offset,
    Common_token_offset,
    Execution_conduit_offset,
    Execution_offerer_offset,
    Fulfillment_itemIndex_offset,
    OneWord,
    OneWordShift,
    OrderParameters_conduit_offset,
    OrderParameters_consideration_head_offset,
    OrderParameters_offer_head_offset,
    ReceivedItem_CommonParams_size,
    ReceivedItem_recipient_offset,
    ReceivedItem_size
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

import {
    Error_selector_offset,
    InvalidFulfillmentComponentData_error_length,
    InvalidFulfillmentComponentData_error_selector,
    MissingItemAmount_error_length,
    MissingItemAmount_error_selector,
    Panic_arithmetic,
    Panic_error_code_ptr,
    Panic_error_length,
    Panic_error_selector
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrorConstants.sol";

/**
 * @title FulfillmentApplier
 * @author 0age
 * @notice FulfillmentApplier contains logic related to applying fulfillments,
 *         both as part of order matching (where offer items are matched to
 *         consideration items) as well as fulfilling available orders (where
 *         order items and consideration items are independently aggregated).
 */
contract FulfillmentApplier is FulfillmentApplicationErrors {
    /**
     * @dev Internal pure function to match offer items to consideration items
     *      on a group of orders via a supplied fulfillment.
     *
     * @param advancedOrders          The orders to match.
     * @param offerComponents         An array designating offer components to
     *                                match to consideration components.
     * @param considerationComponents An array designating consideration
     *                                components to match to offer components.
     *                                Note that each consideration amount must
     *                                be zero in order for the match operation
     *                                to be valid.
     * @param fulfillmentIndex        The index of the fulfillment being
     *                                applied.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _applyFulfillment(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory offerComponents,
        FulfillmentComponent[] memory considerationComponents,
        uint256 fulfillmentIndex
    ) internal pure returns (Execution memory execution) {
        // Ensure 1+ of both offer and consideration components are supplied.
        if (offerComponents.length == 0 || considerationComponents.length == 0) {
            _revertOfferAndConsiderationRequiredOnFulfillment();
        }

        // Declare a new Execution struct.
        Execution memory considerationExecution;

        // Validate & aggregate consideration items to new Execution object.
        _aggregateValidFulfillmentConsiderationItems(advancedOrders, considerationComponents, considerationExecution);

        // Retrieve the consideration item from the execution struct.
        ReceivedItem memory considerationItem = considerationExecution.item;

        // Skip aggregating offer items if no consideration items are available.
        if (considerationItem.amount == 0) {
            // Set the offerer and recipient to null address and the item type
            // to a non-native item type if the execution amount is zero. This
            // will cause the execution item to be skipped.
            considerationExecution.offerer = address(0);
            considerationExecution.item.recipient = payable(0);
            considerationExecution.item.itemType = ItemType.ERC20;
            return considerationExecution;
        }

        // Recipient does not need to be specified because it will always be set
        // to that of the consideration.
        // Validate & aggregate offer items to Execution object.
        _aggregateValidFulfillmentOfferItems(advancedOrders, offerComponents, execution);

        // Ensure offer & consideration item types, tokens, & identifiers match.
        // (a != b || c != d || e != f) == (((a ^ b) | (c ^ d) | (e ^ f)) != 0),
        // but the second expression requires less gas to evaluate.
        if (
            (
                (uint8(execution.item.itemType) ^ uint8(considerationItem.itemType))
                    | (uint160(execution.item.token) ^ uint160(considerationItem.token))
                    | (execution.item.identifier ^ considerationItem.identifier)
            ) != 0
        ) {
            _revertMismatchedFulfillmentOfferAndConsiderationComponents(fulfillmentIndex);
        }

        // If total consideration amount exceeds the offer amount...
        if (considerationItem.amount > execution.item.amount) {
            // Retrieve the first consideration component from the fulfillment.
            FulfillmentComponent memory targetComponent = (considerationComponents[0]);

            // Skip underflow check as the conditional being true implies that
            // considerationItem.amount > execution.item.amount.
            unchecked {
                // Add excess consideration item amount to original order array.
                advancedOrders[targetComponent.orderIndex].parameters.consideration[targetComponent.itemIndex]
                    .startAmount = (considerationItem.amount - execution.item.amount);
            }
        } else {
            // Retrieve the first offer component from the fulfillment.
            FulfillmentComponent memory targetComponent = offerComponents[0];

            // Skip underflow check as the conditional being false implies that
            // execution.item.amount >= considerationItem.amount.
            unchecked {
                // Add excess offer item amount to the original array of orders.
                advancedOrders[targetComponent.orderIndex].parameters.offer[targetComponent.itemIndex].startAmount =
                    (execution.item.amount - considerationItem.amount);
            }

            // Reduce total offer amount to equal the consideration amount.
            execution.item.amount = considerationItem.amount;
        }

        // Reuse consideration recipient.
        execution.item.recipient = considerationItem.recipient;

        // Return the final execution that will be triggered for relevant items.
        return execution; // Execution(considerationItem, offerer, conduitKey);
    }

    /**
     * @dev Internal view function to aggregate offer or consideration items
     *      from a group of orders into a single execution via a supplied array
     *      of fulfillment components. Items that are not available to aggregate
     *      will not be included in the aggregated execution.
     *
     * @param advancedOrders        The orders to aggregate.
     * @param side                  The side (i.e. offer or consideration).
     * @param fulfillmentComponents An array designating item components to
     *                              aggregate if part of an available order.
     * @param fulfillerConduitKey   A bytes32 value indicating what conduit, if
     *                              any, to source the fulfiller's token
     *                              approvals from. The zero hash signifies that
     *                              no conduit should be used, with approvals
     *                              set directly on this contract.
     * @param recipient             The intended recipient for all received
     *                              items.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _aggregateAvailable(
        AdvancedOrder[] memory advancedOrders,
        Side side,
        FulfillmentComponent[] memory fulfillmentComponents,
        bytes32 fulfillerConduitKey,
        address recipient
    ) internal view returns (Execution memory execution) {
        // Skip overflow / underflow checks; conditions checked or unreachable.
        unchecked {
            // Retrieve fulfillment components array length and place on stack.
            // Ensure at least one fulfillment component has been supplied.
            if (fulfillmentComponents.length == 0) {
                _revertMissingFulfillmentComponentOnAggregation(side);
            }

            // Retrieve the received item on the execution being returned.
            ReceivedItem memory item = execution.item;

            // If the fulfillment components are offer components...
            if (side == Side.OFFER) {
                // Set the supplied recipient on the execution item.
                item.recipient = payable(recipient);

                // Return execution for aggregated items provided by offerer.
                _aggregateValidFulfillmentOfferItems(advancedOrders, fulfillmentComponents, execution);
            } else {
                // Otherwise, fulfillment components are consideration
                // components. Return execution for aggregated items provided by
                // the fulfiller.
                _aggregateValidFulfillmentConsiderationItems(advancedOrders, fulfillmentComponents, execution);

                // Set the caller as the offerer on the execution.
                execution.offerer = msg.sender;

                // Set fulfiller conduit key as the conduit key on execution.
                execution.conduitKey = fulfillerConduitKey;
            }

            // Set the offerer and recipient to null address and the item type
            // to a non-native item type if the execution amount is zero. This
            // will cause the execution item to be skipped.
            if (item.amount == 0) {
                execution.offerer = address(0);
                item.recipient = payable(0);
                item.itemType = ItemType.ERC20;
            }
        }
    }

    /**
     * @dev Internal pure function to aggregate a group of offer items using
     *      supplied directives on which component items are candidates for
     *      aggregation, skipping items on orders that are not available.
     *
     * @param advancedOrders  The orders to aggregate offer items from.
     * @param offerComponents An array of FulfillmentComponent structs
     *                        indicating the order index and item index of each
     *                        candidate offer item for aggregation.
     * @param execution       The execution to apply the aggregation to.
     */
    function _aggregateValidFulfillmentOfferItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory offerComponents,
        Execution memory execution
    ) internal pure {
        assembly {
            // Declare a variable for the final aggregated item amount.
            let amount

            // Declare a variable to track errors encountered with amount.
            let errorBuffer

            // Declare a variable for the hash of itemType, token, & identifier.
            let dataHash

            // Iterate over each offer component.
            for {
                // Create variable to track position in offerComponents head.
                let fulfillmentHeadPtr := offerComponents

                // Get position one word past last element in head of array.
                let endPtr := add(offerComponents, shl(OneWordShift, mload(offerComponents)))
            } lt(fulfillmentHeadPtr, endPtr) {} {
                // Increment position in considerationComponents head.
                fulfillmentHeadPtr := add(fulfillmentHeadPtr, OneWord)

                // Retrieve the order index using the fulfillment pointer.
                let orderIndex := mload(mload(fulfillmentHeadPtr))

                // Ensure that the order index is not out of range.
                if iszero(lt(orderIndex, mload(advancedOrders))) { throwInvalidFulfillmentComponentData() }

                // Read advancedOrders[orderIndex] pointer from its array head.
                let orderPtr :=
                    mload(
                        // Calculate head position of advancedOrders[orderIndex].
                        add(add(advancedOrders, OneWord), shl(OneWordShift, orderIndex))
                    )

                // Read the pointer to OrderParameters from the AdvancedOrder.
                let paramsPtr := mload(orderPtr)

                // Retrieve item index using an offset of fulfillment pointer.
                let itemIndex := mload(add(mload(fulfillmentHeadPtr), Fulfillment_itemIndex_offset))

                let offerItemPtr
                {
                    // Load the offer array pointer.
                    let offerArrPtr := mload(add(paramsPtr, OrderParameters_offer_head_offset))

                    // If the offer item index is out of range or the numerator
                    // is zero, skip this item.
                    if or(
                        iszero(lt(itemIndex, mload(offerArrPtr))),
                        iszero(mload(add(orderPtr, AdvancedOrder_numerator_offset)))
                    ) { continue }

                    // Retrieve offer item pointer using the item index.
                    offerItemPtr :=
                        mload(
                            add(
                                // Get pointer to beginning of receivedItem.
                                add(offerArrPtr, OneWord),
                                // Calculate offset to pointer for desired order.
                                shl(OneWordShift, itemIndex)
                            )
                        )
                }

                // Declare a separate scope for the amount update.
                {
                    // Retrieve amount pointer using consideration item pointer.
                    let amountPtr := add(offerItemPtr, Common_amount_offset)

                    // Add offer item amount to execution amount.
                    let newAmount := add(amount, mload(amountPtr))

                    // Update error buffer:
                    // 1 = zero amount, 2 = overflow, 3 = both.
                    errorBuffer := or(errorBuffer, or(shl(1, lt(newAmount, amount)), iszero(mload(amountPtr))))

                    // Update the amount to the new, summed amount.
                    amount := newAmount

                    // Zero out amount on original item to indicate it is spent.
                    mstore(amountPtr, 0)
                }

                // Retrieve ReceivedItem pointer from Execution.
                let receivedItem := mload(execution)

                // Check if this is the first valid fulfillment item.
                switch iszero(dataHash)
                case 1 {
                    // On first valid item, populate the received item in memory
                    // for later comparison.

                    // Set the item type on the received item.
                    mstore(receivedItem, mload(offerItemPtr))

                    // Set the token on the received item.
                    mstore(add(receivedItem, Common_token_offset), mload(add(offerItemPtr, Common_token_offset)))

                    // Set the identifier on the received item.
                    mstore(
                        add(receivedItem, Common_identifier_offset), mload(add(offerItemPtr, Common_identifier_offset))
                    )

                    // Set offerer on returned execution using order pointer.
                    mstore(add(execution, Execution_offerer_offset), mload(paramsPtr))

                    // Set execution conduitKey via order pointer offset.
                    mstore(
                        add(execution, Execution_conduit_offset), mload(add(paramsPtr, OrderParameters_conduit_offset))
                    )

                    // Calculate the hash of (itemType, token, identifier).
                    dataHash := keccak256(receivedItem, ReceivedItem_CommonParams_size)

                    // If component index > 0, swap component pointer with
                    // pointer to first component so that any remainder after
                    // fulfillment can be added back to the first item.
                    let firstFulfillmentHeadPtr := add(offerComponents, OneWord)
                    if xor(firstFulfillmentHeadPtr, fulfillmentHeadPtr) {
                        let firstFulfillmentPtr := mload(firstFulfillmentHeadPtr)
                        let fulfillmentPtr := mload(fulfillmentHeadPtr)
                        mstore(firstFulfillmentHeadPtr, fulfillmentPtr)
                    }
                }
                default {
                    // Compare every subsequent item to the first.
                    if or(
                        or(
                            // The offerer must match on both items.
                            xor(mload(paramsPtr), mload(add(execution, Execution_offerer_offset))),
                            // The conduit key must match on both items.
                            xor(
                                mload(add(paramsPtr, OrderParameters_conduit_offset)),
                                mload(add(execution, Execution_conduit_offset))
                            )
                        ),
                        // The itemType, token, and identifier must match.
                        xor(dataHash, keccak256(offerItemPtr, ReceivedItem_CommonParams_size))
                    ) {
                        // Throw if any of the requirements are not met.
                        throwInvalidFulfillmentComponentData()
                    }
                }
            }

            // Write final amount to execution.
            mstore(add(mload(execution), Common_amount_offset), amount)

            // Determine whether the error buffer contains a nonzero error code.
            if errorBuffer {
                // If errorBuffer is 1, an item had an amount of zero.
                if eq(errorBuffer, 1) {
                    // Store left-padded selector with push4 (reduces bytecode)
                    // mem[28:32] = selector
                    mstore(0, MissingItemAmount_error_selector)

                    // revert(abi.encodeWithSignature("MissingItemAmount()"))
                    revert(Error_selector_offset, MissingItemAmount_error_length)
                }

                // If errorBuffer is not 1 or 0, the sum overflowed.
                // Panic!
                throwOverflow()
            }

            // Declare function for reverts on invalid fulfillment data.
            function throwInvalidFulfillmentComponentData() {
                // Store left-padded selector (uses push4 and reduces code size)
                mstore(0, InvalidFulfillmentComponentData_error_selector)

                // revert(abi.encodeWithSignature(
                //     "InvalidFulfillmentComponentData()"
                // ))
                revert(Error_selector_offset, InvalidFulfillmentComponentData_error_length)
            }

            // Declare function for reverts due to arithmetic overflows.
            function throwOverflow() {
                // Store the Panic error signature.
                mstore(0, Panic_error_selector)
                // Store the arithmetic (0x11) panic code.
                mstore(Panic_error_code_ptr, Panic_arithmetic)
                // revert(abi.encodeWithSignature("Panic(uint256)", 0x11))
                revert(Error_selector_offset, Panic_error_length)
            }
        }
    }

    /**
     * @dev Internal pure function to aggregate a group of consideration items
     *      using supplied directives on which component items are candidates
     *      for aggregation, skipping items on orders that are not available.
     *      Note that this function depends on memory layout affected by an
     *      earlier call to _validateOrdersAndPrepareToFulfill.  The memory for
     *      the consideration arrays needs to be updated before calling
     *      _aggregateValidFulfillmentConsiderationItems.
     *      _validateOrdersAndPrepareToFulfill is called in _matchAdvancedOrders
     *      and _fulfillAvailableAdvancedOrders in the current version.
     *
     * @param advancedOrders          The orders to aggregate consideration
     *                                items from.
     * @param considerationComponents An array of FulfillmentComponent structs
     *                                indicating the order index and item index
     *                                of each candidate consideration item for
     *                                aggregation.
     * @param execution               The execution to apply the aggregation to.
     */
    function _aggregateValidFulfillmentConsiderationItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory considerationComponents,
        Execution memory execution
    ) internal pure {
        // Utilize assembly in order to efficiently aggregate the items.
        assembly {
            // Declare a variable for the final aggregated item amount.
            let amount

            // Create variable to track errors encountered with amount.
            let errorBuffer

            // Declare variable for hash(itemType, token, identifier, recipient)
            let dataHash

            // Iterate over each consideration component.
            for {
                // Track position in considerationComponents head.
                let fulfillmentHeadPtr := considerationComponents

                // Get position one word past last element in head of array.
                let endPtr := add(considerationComponents, shl(OneWordShift, mload(considerationComponents)))
            } lt(fulfillmentHeadPtr, endPtr) {} {
                // Increment position in considerationComponents head.
                fulfillmentHeadPtr := add(fulfillmentHeadPtr, OneWord)

                // Retrieve the order index using the fulfillment pointer.
                let orderIndex := mload(mload(fulfillmentHeadPtr))

                // Ensure that the order index is not out of range.
                if iszero(lt(orderIndex, mload(advancedOrders))) { throwInvalidFulfillmentComponentData() }

                // Read advancedOrders[orderIndex] pointer from its array head.
                let orderPtr :=
                    mload(
                        // Calculate head position of advancedOrders[orderIndex].
                        add(add(advancedOrders, OneWord), shl(OneWordShift, orderIndex))
                    )

                // Retrieve item index using an offset of fulfillment pointer.
                let itemIndex := mload(add(mload(fulfillmentHeadPtr), Fulfillment_itemIndex_offset))

                let considerationItemPtr
                {
                    // Load consideration array pointer.
                    let considerationArrPtr :=
                        mload(
                            add(
                                // Read OrderParameters pointer from AdvancedOrder.
                                mload(orderPtr),
                                OrderParameters_consideration_head_offset
                            )
                        )

                    // If the consideration item index is out of range or the
                    // numerator is zero, skip this item.
                    if or(
                        iszero(lt(itemIndex, mload(considerationArrPtr))),
                        iszero(mload(add(orderPtr, AdvancedOrder_numerator_offset)))
                    ) { continue }

                    // Retrieve consideration item pointer using the item index.
                    considerationItemPtr :=
                        mload(
                            add(
                                // Get pointer to beginning of receivedItem.
                                add(considerationArrPtr, OneWord),
                                // Calculate offset to pointer for desired order.
                                shl(OneWordShift, itemIndex)
                            )
                        )
                }

                // Declare a separate scope for the amount update.
                {
                    // Retrieve amount pointer using consideration item pointer.
                    let amountPtr := add(considerationItemPtr, Common_amount_offset)

                    // Add consideration item amount to execution amount.
                    let newAmount := add(amount, mload(amountPtr))

                    // Update error buffer:
                    // 1 = zero amount, 2 = overflow, 3 = both.
                    errorBuffer := or(errorBuffer, or(shl(1, lt(newAmount, amount)), iszero(mload(amountPtr))))

                    // Update the amount to the new, summed amount.
                    amount := newAmount

                    // Zero out original item amount to indicate it is credited.
                    mstore(amountPtr, 0)
                }

                // Retrieve ReceivedItem pointer from Execution.
                let receivedItem := mload(execution)

                switch iszero(dataHash)
                case 1 {
                    // On first valid item, populate the received item in
                    // memory for later comparison.

                    // Set the item type on the received item.
                    mstore(receivedItem, mload(considerationItemPtr))

                    // Set the token on the received item.
                    mstore(
                        add(receivedItem, Common_token_offset), mload(add(considerationItemPtr, Common_token_offset))
                    )

                    // Set the identifier on the received item.
                    mstore(
                        add(receivedItem, Common_identifier_offset),
                        mload(add(considerationItemPtr, Common_identifier_offset))
                    )

                    // Set the recipient on the received item. Note that this
                    // depends on the memory layout established by the
                    // _validateOrdersAndPrepareToFulfill function.
                    mstore(
                        add(receivedItem, ReceivedItem_recipient_offset),
                        mload(add(considerationItemPtr, ReceivedItem_recipient_offset))
                    )

                    // Calculate the hash of (itemType, token, identifier,
                    // recipient). This is run after amount is set to zero, so
                    // there will be one blank word after identifier included in
                    // the hash buffer.
                    dataHash := keccak256(considerationItemPtr, ReceivedItem_size)

                    // If component index > 0, swap component pointer with
                    // pointer to first component so that any remainder after
                    // fulfillment can be added back to the first item.
                    let firstFulfillmentHeadPtr := add(considerationComponents, OneWord)
                    if xor(firstFulfillmentHeadPtr, fulfillmentHeadPtr) {
                        let firstFulfillmentPtr := mload(firstFulfillmentHeadPtr)
                        let fulfillmentPtr := mload(fulfillmentHeadPtr)
                        mstore(firstFulfillmentHeadPtr, fulfillmentPtr)
                    }
                }
                default {
                    // Compare every subsequent item to the first; the item
                    // type, token, identifier and recipient must match.
                    if xor(
                        dataHash,
                        // Calculate the hash of (itemType, token, identifier,
                        // recipient). This is run after amount is set to zero,
                        // so there will be one blank word after identifier
                        // included in the hash buffer.
                        keccak256(considerationItemPtr, ReceivedItem_size)
                    ) {
                        // Throw if any of the requirements are not met.
                        throwInvalidFulfillmentComponentData()
                    }
                }
            }

            // Retrieve ReceivedItem pointer from Execution.
            let receivedItem := mload(execution)

            // Write final amount to execution.
            mstore(add(receivedItem, Common_amount_offset), amount)

            // Determine whether the error buffer contains a nonzero error code.
            if errorBuffer {
                // If errorBuffer is 1, an item had an amount of zero.
                if eq(errorBuffer, 1) {
                    // Store left-padded selector with push4, mem[28:32]
                    mstore(0, MissingItemAmount_error_selector)

                    // revert(abi.encodeWithSignature("MissingItemAmount()"))
                    revert(Error_selector_offset, MissingItemAmount_error_length)
                }

                // If errorBuffer is not 1 or 0, `amount` overflowed.
                // Panic!
                throwOverflow()
            }

            // Declare function for reverts on invalid fulfillment data.
            function throwInvalidFulfillmentComponentData() {
                // Store the InvalidFulfillmentComponentData error signature.
                mstore(0, InvalidFulfillmentComponentData_error_selector)

                // revert(abi.encodeWithSignature(
                //     "InvalidFulfillmentComponentData()"
                // ))
                revert(Error_selector_offset, InvalidFulfillmentComponentData_error_length)
            }

            // Declare function for reverts due to arithmetic overflows.
            function throwOverflow() {
                // Store the Panic error signature.
                mstore(0, Panic_error_selector)
                // Store the arithmetic (0x11) panic code.
                mstore(Panic_error_code_ptr, Panic_arithmetic)
                // revert(abi.encodeWithSignature("Panic(uint256)", 0x11))
                revert(Error_selector_offset, Panic_error_length)
            }
        }
    }
}
