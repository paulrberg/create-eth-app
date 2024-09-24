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

import {Side, ItemType, OrderType} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    OfferItem,
    OrderParameters,
    ReceivedItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {OrderFulfiller} from "./OrderFulfiller.sol";

import {FulfillmentApplier} from "./FulfillmentApplier.sol";

import {
    _revertConsiderationNotMet,
    _revertInsufficientNativeTokensSupplied,
    _revertInvalidNativeOfferItem,
    _revertNoSpecifiedOrdersAvailable
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrors.sol";

import {
    AccumulatorDisarmed,
    ConsiderationItem_recipient_offset,
    Execution_offerer_offset,
    NonMatchSelector_InvalidErrorValue,
    NonMatchSelector_MagicMask,
    OneWord,
    OneWordShift,
    OrdersMatchedTopic0,
    ReceivedItem_amount_offset,
    ReceivedItem_recipient_offset,
    TwoWords
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

/**
 * @title OrderCombiner
 * @author 0age
 * @notice OrderCombiner contains logic for fulfilling combinations of orders,
 *         either by matching offer items to consideration items or by
 *         fulfilling orders where available.
 */
contract OrderCombiner is OrderFulfiller, FulfillmentApplier {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderFulfiller(conduitController) {}

    /**
     * @notice Internal function to attempt to fill a group of orders, fully or
     *         partially, with an arbitrary number of items for offer and
     *         consideration per order alongside criteria resolvers containing
     *         specific token identifiers and associated proofs. Any order that
     *         is not currently active, has already been fully filled, or has
     *         been cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or a conduit if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used (and
     *                                  direct approvals set on Consideration).
     * @param recipient                 The intended recipient for all received
     *                                  items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function _fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    ) internal returns (bool[] memory, /* availableOrders */ Execution[] memory /* executions */ ) {
        // Validate orders, apply amounts, & determine if they use conduits.
        (bytes32[] memory orderHashes, bool containsNonOpen) = _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            false, // Signifies that invalid orders should NOT revert.
            maximumFulfilled,
            recipient
        );

        // Aggregate used offer and consideration items and execute transfers.
        return _executeAvailableFulfillments(
            advancedOrders,
            offerFulfillments,
            considerationFulfillments,
            fulfillerConduitKey,
            recipient,
            orderHashes,
            containsNonOpen
        );
    }

    /**
     * @dev Internal function to validate a group of orders, update their
     *      statuses, reduce amounts by their previously filled fractions, apply
     *      criteria resolvers, and emit OrderFulfilled events. Note that this
     *      function needs to be called before
     *      _aggregateValidFulfillmentConsiderationItems to set the memory
     *      layout that _aggregateValidFulfillmentConsiderationItems depends on.
     *
     * @param advancedOrders    The advanced orders to validate and reduce by
     *                          their previously filled amounts.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          a root of zero indicates that any transferable
     *                          token identifier is valid and that no proof
     *                          needs to be supplied.
     * @param revertOnInvalid   A boolean indicating whether to revert on any
     *                          order being invalid; setting this to false will
     *                          instead cause the invalid order to be skipped.
     * @param maximumFulfilled  The maximum number of orders to fulfill.
     * @param recipient         The intended recipient for all items that do not
     *                          already have a designated recipient and are not
     *                          already used as part of a provided fulfillment.
     *
     * @return orderHashes     The hashes of the orders being fulfilled.
     * @return containsNonOpen A boolean indicating whether any restricted or
     *                         contract orders are present within the provided
     *                         array of advanced orders.
     */
    function _validateOrdersAndPrepareToFulfill(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        bool revertOnInvalid,
        uint256 maximumFulfilled,
        address recipient
    ) internal returns (bytes32[] memory orderHashes, bool containsNonOpen) {
        // Ensure this function cannot be triggered during a reentrant call.
        _setReentrancyGuard(true); // Native tokens accepted during execution.

        // Declare an error buffer indicating status of any native offer items.
        // Native tokens may only be provided as part of contract orders or when
        // fulfilling via matchOrders or matchAdvancedOrders; if bits indicating
        // these conditions are not met have been set, throw.
        uint256 invalidNativeOfferItemErrorBuffer;

        // Use assembly to set the value for the second bit of the error buffer.
        assembly {
            /**
             * Use the 231st bit of the error buffer to indicate whether the
             * current function is not matchAdvancedOrders or matchOrders.
             *
             * sig                                func
             * -----------------------------------------------------------------
             * 1010100000010111010001000 0 000100 matchOrders
             * 1111001011010001001010110 0 010010 matchAdvancedOrders
             * 1110110110011000101001010 1 110100 fulfillAvailableOrders
             * 1000011100100000000110110 1 000001 fulfillAvailableAdvancedOrders
             *                           ^ 7th bit
             */
            invalidNativeOfferItemErrorBuffer := and(NonMatchSelector_MagicMask, calldataload(0))
        }

        // Declare variables for later use.
        AdvancedOrder memory advancedOrder;
        uint256 terminalMemoryOffset;

        unchecked {
            // Read length of orders array and place on the stack.
            uint256 totalOrders = advancedOrders.length;

            // Track the order hash for each order being fulfilled.
            orderHashes = new bytes32[](totalOrders);

            // Determine the memory offset to terminate on during loops.
            terminalMemoryOffset = (totalOrders + 1) << OneWordShift;
        }

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Declare inner variables.
            OfferItem[] memory offer;
            ConsiderationItem[] memory consideration;

            // Iterate over each order.
            for (uint256 i = OneWord; i < terminalMemoryOffset; i += OneWord) {
                // Retrieve order using assembly to bypass out-of-range check.
                assembly {
                    advancedOrder := mload(add(advancedOrders, i))
                }

                // Determine if max number orders have already been fulfilled.
                if (maximumFulfilled == 0) {
                    // Mark fill fraction as zero as the order will not be used.
                    advancedOrder.numerator = 0;

                    // Continue iterating through the remaining orders.
                    continue;
                }

                // Validate it, update status, and determine fraction to fill.
                (bytes32 orderHash, uint256 numerator, uint256 denominator) =
                    _validateOrderAndUpdateStatus(advancedOrder, revertOnInvalid);

                // Do not track hash or adjust prices if order is not fulfilled.
                if (numerator == 0) {
                    // Mark fill fraction as zero if the order is not fulfilled.
                    advancedOrder.numerator = 0;

                    // Continue iterating through the remaining orders.
                    continue;
                }

                // Otherwise, track the order hash in question.
                assembly {
                    mstore(add(orderHashes, i), orderHash)
                }

                // Decrement the number of fulfilled orders.
                // Skip underflow check as the condition before
                // implies that maximumFulfilled > 0.
                --maximumFulfilled;

                // Place the start time for the order on the stack.
                uint256 startTime = advancedOrder.parameters.startTime;

                // Place the end time for the order on the stack.
                uint256 endTime = advancedOrder.parameters.endTime;

                // Retrieve array of offer items for the order in question.
                offer = advancedOrder.parameters.offer;

                // Read length of offer array and place on the stack.
                uint256 totalOfferItems = offer.length;

                {
                    // Determine the order type, used to check for eligibility
                    // for native token offer items as well as for the presence
                    // of restricted and contract orders (or non-open orders).
                    OrderType orderType = advancedOrder.parameters.orderType;

                    // Utilize assembly to efficiently check for order types.
                    // Note that these checks expect that there are no order
                    // types beyond the current set (0-4) and will need to be
                    // modified if more order types are added.
                    assembly {
                        // Declare a variable indicating if the order is not a
                        // contract order. Cache in scratch space to avoid stack
                        // depth errors.
                        let isNonContract := lt(orderType, 4)
                        mstore(0, isNonContract)

                        // Update the variable indicating if the order is not an
                        // open order, remaining set if it has been set already.
                        containsNonOpen := or(containsNonOpen, gt(orderType, 1))
                    }
                }

                // Iterate over each offer item on the order.
                for (uint256 j = 0; j < totalOfferItems; ++j) {
                    // Retrieve the offer item.
                    OfferItem memory offerItem = offer[j];

                    // If the offer item is for the native token and the order
                    // type is not a contract order type, set the first bit of
                    // the error buffer to true.
                    assembly {
                        invalidNativeOfferItemErrorBuffer :=
                            or(invalidNativeOfferItemErrorBuffer, lt(mload(offerItem), mload(0)))
                    }

                    // Apply order fill fraction to offer item end amount.
                    uint256 endAmount = _getFraction(numerator, denominator, offerItem.endAmount);

                    // Reuse same fraction if start and end amounts are equal.
                    if (offerItem.startAmount == offerItem.endAmount) {
                        // Apply derived amount to both start and end amount.
                        offerItem.startAmount = endAmount;
                    } else {
                        // Apply order fill fraction to offer item start amount.
                        offerItem.startAmount = _getFraction(numerator, denominator, offerItem.startAmount);
                    }

                    // Adjust offer amount using current time; round down.
                    uint256 currentAmount = _locateCurrentAmount(
                        offerItem.startAmount,
                        endAmount,
                        startTime,
                        endTime,
                        false // round down
                    );

                    // Update amounts in memory to match the current amount.
                    // Note that the end amount is used to track spent amounts.
                    offerItem.startAmount = currentAmount;
                    offerItem.endAmount = currentAmount;
                }

                // Retrieve array of consideration items for order in question.
                consideration = (advancedOrder.parameters.consideration);

                // Read length of consideration array and place on the stack.
                uint256 totalConsiderationItems = consideration.length;

                // Iterate over each consideration item on the order.
                for (uint256 j = 0; j < totalConsiderationItems; ++j) {
                    // Retrieve the consideration item.
                    ConsiderationItem memory considerationItem = (consideration[j]);

                    // Apply fraction to consideration item end amount.
                    uint256 endAmount = _getFraction(numerator, denominator, considerationItem.endAmount);

                    // Reuse same fraction if start and end amounts are equal.
                    if (considerationItem.startAmount == considerationItem.endAmount) {
                        // Apply derived amount to both start and end amount.
                        considerationItem.startAmount = endAmount;
                    } else {
                        // Apply fraction to consideration item start amount.
                        considerationItem.startAmount =
                            _getFraction(numerator, denominator, considerationItem.startAmount);
                    }

                    // Adjust consideration amount using current time; round up.
                    uint256 currentAmount = (
                        _locateCurrentAmount(
                            considerationItem.startAmount,
                            endAmount,
                            startTime,
                            endTime,
                            true // round up
                        )
                    );

                    considerationItem.startAmount = currentAmount;

                    // Utilize assembly to manually "shift" the recipient value,
                    // then to copy the start amount to the recipient.
                    // Note that this sets up the memory layout that is
                    // subsequently relied upon by
                    // _aggregateValidFulfillmentConsiderationItems.
                    assembly {
                        // Derive the pointer to the recipient using the item
                        // pointer along with the offset to the recipient.
                        let considerationItemRecipientPtr :=
                            add(
                                considerationItem,
                                ConsiderationItem_recipient_offset // recipient
                            )

                        // Write recipient to endAmount, as endAmount is not
                        // used from this point on and can be repurposed to fit
                        // the layout of a ReceivedItem.
                        mstore(
                            add(
                                considerationItem,
                                ReceivedItem_recipient_offset // old endAmount
                            ),
                            mload(considerationItemRecipientPtr)
                        )

                        // Write startAmount to recipient, as recipient is not
                        // used from this point on and can be repurposed to
                        // track received amounts.
                        mstore(considerationItemRecipientPtr, currentAmount)
                    }
                }
            }
        }

        // If the first bit is set, a native offer item was encountered on an
        // order that is not a contract order. If the 231st bit is set in the
        // error buffer, the current function is not matchOrders or
        // matchAdvancedOrders. If the value is 1 + (1 << 230), then both the
        // 1st and 231st bits were set; in that case, revert with an error.
        if (invalidNativeOfferItemErrorBuffer == NonMatchSelector_InvalidErrorValue) {
            _revertInvalidNativeOfferItem();
        }

        // Apply criteria resolvers to each order as applicable.
        _applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Emit an event for each order signifying that it has been fulfilled.
        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            bytes32 orderHash;

            // Iterate over each order.
            for (uint256 i = OneWord; i < terminalMemoryOffset; i += OneWord) {
                assembly {
                    orderHash := mload(add(orderHashes, i))
                }

                // Do not emit an event if no order hash is present.
                if (orderHash == bytes32(0)) {
                    continue;
                }

                // Retrieve order using assembly to bypass out-of-range check.
                assembly {
                    advancedOrder := mload(add(advancedOrders, i))
                }

                // Retrieve parameters for the order in question.
                OrderParameters memory orderParameters = (advancedOrder.parameters);

                // Emit an OrderFulfilled event.
                _emitOrderFulfilledEvent(
                    orderHash,
                    orderParameters.offerer,
                    orderParameters.zone,
                    recipient,
                    orderParameters.offer,
                    orderParameters.consideration
                );
            }
        }
    }

    /**
     * @dev Internal function to fulfill a group of validated orders, fully or
     *      partially, with an arbitrary number of items for offer and
     *      consideration per order and to execute transfers. Any order that is
     *      not currently active, has already been fully filled, or has been
     *      cancelled will be omitted. Remaining offer and consideration items
     *      will then be aggregated where possible as indicated by the supplied
     *      offer and consideration component arrays and aggregated items will
     *      be transferred to the fulfiller or to each intended recipient,
     *      respectively. Note that a failing item transfer or an issue with
     *      order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or the conduit if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on Consideration.
     * @param recipient                 The intended recipient for all items
     *                                  that do not already have a designated
     *                                  recipient and are not already used as
     *                                  part of a provided fulfillment.
     * @param orderHashes               An array of order hashes for each order.
     * @param containsNonOpen           A boolean indicating whether any
     *                                  restricted or contract orders are
     *                                  present within the provided array of
     *                                  advanced orders.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function _executeAvailableFulfillments(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        bytes32[] memory orderHashes,
        bool containsNonOpen
    ) internal returns (bool[] memory availableOrders, Execution[] memory executions) {
        // Retrieve length of offer fulfillments array and place on the stack.
        uint256 totalOfferFulfillments = offerFulfillments.length;

        // Retrieve length of consideration fulfillments array & place on stack.
        uint256 totalConsiderationFulfillments = (considerationFulfillments.length);

        // Allocate an execution for each offer and consideration fulfillment.
        executions = new Execution[](
            totalOfferFulfillments + totalConsiderationFulfillments
        );

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Track number of filtered executions.
            uint256 totalFilteredExecutions = 0;

            // Iterate over each offer fulfillment.
            for (uint256 i = 0; i < totalOfferFulfillments;) {
                // Derive aggregated execution corresponding with fulfillment.
                Execution memory execution = _aggregateAvailable(
                    advancedOrders, Side.OFFER, offerFulfillments[i], fulfillerConduitKey, recipient
                );

                // If the execution is filterable...
                if (_isFilterableExecution(execution)) {
                    // Increment total filtered executions.
                    ++totalFilteredExecutions;
                } else {
                    // Otherwise, assign the execution to the executions array.
                    executions[i - totalFilteredExecutions] = execution;
                }

                // Increment iterator.
                ++i;
            }

            // Iterate over each consideration fulfillment.
            for (uint256 i = 0; i < totalConsiderationFulfillments;) {
                // Derive aggregated execution corresponding with fulfillment.
                Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.CONSIDERATION,
                    considerationFulfillments[i],
                    fulfillerConduitKey,
                    address(0) // unused
                );

                // If the execution is filterable...
                if (_isFilterableExecution(execution)) {
                    // Increment total filtered executions.
                    ++totalFilteredExecutions;
                } else {
                    // Otherwise, assign the execution to the executions array.
                    executions[i + totalOfferFulfillments - totalFilteredExecutions] = execution;
                }

                // Increment iterator.
                ++i;
            }

            // If some number of executions have been filtered...
            if (totalFilteredExecutions != 0) {
                // reduce the total length of the executions array.
                assembly {
                    mstore(executions, sub(mload(executions), totalFilteredExecutions))
                }
            }
        }

        // Revert if no orders are available.
        if (executions.length == 0) {
            _revertNoSpecifiedOrdersAvailable();
        }

        // Perform final checks and return.
        availableOrders =
            _performFinalChecksAndExecuteOrders(advancedOrders, executions, orderHashes, recipient, containsNonOpen);

        return (availableOrders, executions);
    }

    /**
     * @dev Internal function to perform a final check that each consideration
     *      item for an arbitrary number of fulfilled orders has been met and to
     *      trigger associated executions, transferring the respective items.
     *
     * @param advancedOrders  The orders to check and perform executions for.
     * @param executions      An array of elements indicating the sequence of
     *                        transfers to perform when fulfilling the given
     *                        orders.
     * @param orderHashes     An array of order hashes for each order.
     * @param recipient       The intended recipient for all items that do not
     *                        already have a designated recipient and are not
     *                        used as part of a provided fulfillment.
     * @param containsNonOpen A boolean indicating whether any restricted or
     *                        contract orders are present within the provided
     *                        array of advanced orders.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     */
    function _performFinalChecksAndExecuteOrders(
        AdvancedOrder[] memory advancedOrders,
        Execution[] memory executions,
        bytes32[] memory orderHashes,
        address recipient,
        bool containsNonOpen
    ) internal returns (bool[] memory /* availableOrders */ ) {
        // Retrieve the length of the advanced orders array and place on stack.
        uint256 totalOrders = advancedOrders.length;

        // Initialize array for tracking available orders.
        bool[] memory availableOrders = new bool[](totalOrders);

        // Initialize an accumulator array. From this point forward, no new
        // memory regions can be safely allocated until the accumulator is no
        // longer being utilized, as the accumulator operates in an open-ended
        // fashion from this memory pointer; existing memory may still be
        // accessed and modified, however.
        bytes memory accumulator = new bytes(AccumulatorDisarmed);

        {
            // Declare a variable for the available native token balance.
            uint256 nativeTokenBalance;

            // Retrieve the length of the executions array and place on stack.
            uint256 totalExecutions = executions.length;

            // Iterate over each execution.
            for (uint256 i = 0; i < totalExecutions;) {
                // Retrieve the execution and the associated received item.
                Execution memory execution = executions[i];
                ReceivedItem memory item = execution.item;

                // If execution transfers native tokens, reduce value available.
                if (item.itemType == ItemType.NATIVE) {
                    // Get the current available balance of native tokens.
                    assembly {
                        nativeTokenBalance := selfbalance()
                    }

                    // Ensure that sufficient native tokens are still available.
                    if (item.amount > nativeTokenBalance) {
                        _revertInsufficientNativeTokensSupplied();
                    }
                }

                // Transfer the item specified by the execution.
                _transfer(item, execution.offerer, execution.conduitKey, accumulator);

                // Skip overflow check as for loop is indexed starting at zero.
                unchecked {
                    ++i;
                }
            }
        }

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the order in question.
                AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip the order in question if not being not fulfilled.
                if (advancedOrder.numerator == 0) {
                    // Explicitly set availableOrders at the given index to
                    // guard against the possibility of dirtied memory.
                    availableOrders[i] = false;
                    continue;
                }

                // Mark the order as available.
                availableOrders[i] = true;

                // Retrieve the order parameters.
                OrderParameters memory parameters = advancedOrder.parameters;

                {
                    // Retrieve offer items.
                    OfferItem[] memory offer = parameters.offer;

                    // Read length of offer array & place on the stack.
                    uint256 totalOfferItems = offer.length;

                    // Iterate over each offer item to restore it.
                    for (uint256 j = 0; j < totalOfferItems; ++j) {
                        // Retrieve the offer item in question.
                        OfferItem memory offerItem = offer[j];

                        // Transfer to recipient if unspent amount is not zero.
                        // Note that the transfer will not be reflected in the
                        // executions array.
                        if (offerItem.startAmount != 0) {
                            // Replace the endAmount parameter with the recipient to
                            // make offerItem compatible with the ReceivedItem input
                            // to _transfer and cache the original endAmount so it
                            // can be restored after the transfer.
                            uint256 originalEndAmount = _replaceEndAmountWithRecipient(offerItem, recipient);

                            // Transfer excess offer item amount to recipient.
                            _toOfferItemInput(_transfer)(
                                offerItem, parameters.offerer, parameters.conduitKey, accumulator
                            );

                            // Restore the original endAmount in offerItem.
                            assembly {
                                mstore(add(offerItem, ReceivedItem_recipient_offset), originalEndAmount)
                            }
                        }

                        // Restore original amount on the offer item.
                        offerItem.startAmount = offerItem.endAmount;
                    }
                }

                {
                    // Read consideration items & ensure they are fulfilled.
                    ConsiderationItem[] memory consideration = (parameters.consideration);

                    // Read length of consideration array & place on stack.
                    uint256 totalConsiderationItems = consideration.length;

                    // Iterate over each consideration item.
                    for (uint256 j = 0; j < totalConsiderationItems; ++j) {
                        ConsiderationItem memory considerationItem = (consideration[j]);

                        // Retrieve remaining amount on consideration item.
                        uint256 unmetAmount = considerationItem.startAmount;

                        // Revert if the remaining amount is not zero.
                        if (unmetAmount != 0) {
                            _revertConsiderationNotMet(i, j, unmetAmount);
                        }

                        // Utilize assembly to restore the original value.
                        assembly {
                            // Write recipient to startAmount.
                            mstore(
                                add(considerationItem, ReceivedItem_amount_offset),
                                mload(add(considerationItem, ConsiderationItem_recipient_offset))
                            )
                        }
                    }
                }
            }
        }

        // Trigger any accumulated transfers via call to the conduit.
        _triggerIfArmed(accumulator);

        // Determine whether any native token balance remains.
        uint256 remainingNativeTokenBalance;
        assembly {
            remainingNativeTokenBalance := selfbalance()
        }

        // Return any remaining native token balance to the caller.
        if (remainingNativeTokenBalance != 0) {
            _transferNativeTokens(payable(msg.sender), remainingNativeTokenBalance);
        }

        // If any restricted or contract orders are present in the group of
        // orders being fulfilled, perform any validateOrder or ratifyOrder
        // calls after all executions and related transfers are complete.
        if (containsNonOpen) {
            // Iterate over each order a second time.
            for (uint256 i = 0; i < totalOrders;) {
                // Ensure the order in question is being fulfilled.
                if (availableOrders[i]) {
                    // Check restricted orders and contract orders.
                    _assertRestrictedAdvancedOrderValidity(advancedOrders[i], orderHashes, orderHashes[i]);
                }

                // Skip overflow checks as for loop is indexed starting at zero.
                unchecked {
                    ++i;
                }
            }
        }

        // Clear the reentrancy guard.
        _clearReentrancyGuard();

        // Return the array containing available orders.
        return availableOrders;
    }

    /**
     * @dev Internal function to emit an OrdersMatched event using the same
     *      memory region as the existing order hash array.
     *
     * @param orderHashes An array of order hashes to include as an argument for
     *                    the OrdersMatched event.
     */
    function _emitOrdersMatched(bytes32[] memory orderHashes) internal {
        assembly {
            // Load the array length from memory.
            let length := mload(orderHashes)

            // Get the full size of the event data - one word for the offset,
            // one for the array length and one per hash.
            let dataSize := add(TwoWords, shl(OneWordShift, length))

            // Get pointer to start of data, reusing word before array length
            // for the offset.
            let dataPointer := sub(orderHashes, OneWord)

            // Cache the existing word in memory at the offset pointer.
            let cache := mload(dataPointer)

            // Write an offset of 32.
            mstore(dataPointer, OneWord)

            // Emit the OrdersMatched event.
            log1(dataPointer, dataSize, OrdersMatchedTopic0)

            // Restore the cached word.
            mstore(dataPointer, cache)
        }
    }

    /**
     * @dev Internal function to match an arbitrary number of full or partial
     *      orders, each with an arbitrary number of items for offer and
     *      consideration, supplying criteria resolvers containing specific
     *      token identifiers and associated proofs as well as fulfillments
     *      allocating offer components to consideration components.
     *
     * @param advancedOrders    The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or their conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     * @param recipient         The intended recipient for all unspent offer
     *                          item amounts.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function _matchAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        Fulfillment[] memory fulfillments,
        address recipient
    ) internal returns (Execution[] memory /* executions */ ) {
        // Validate orders, update order status, and determine item amounts.
        (bytes32[] memory orderHashes, bool containsNonOpen) = _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            true, // Signifies that invalid orders should revert.
            advancedOrders.length,
            recipient
        );

        // Emit OrdersMatched event, providing an array of matched order hashes.
        _emitOrdersMatched(orderHashes);

        // Fulfill the orders using the supplied fulfillments and recipient.
        return _fulfillAdvancedOrders(advancedOrders, fulfillments, orderHashes, recipient, containsNonOpen);
    }

    /**
     * @dev Internal function to fulfill an arbitrary number of orders, either
     *      full or partial, after validating, adjusting amounts, and applying
     *      criteria resolvers.
     *
     * @param advancedOrders  The orders to match, including a fraction to
     *                        attempt to fill for each order.
     * @param fulfillments    An array of elements allocating offer components
     *                        to consideration components. Note that the final
     *                        amount of each consideration component must be
     *                        zero for a match operation to be considered valid.
     * @param orderHashes     An array of order hashes for each order.
     * @param recipient       The intended recipient for all items that do not
     *                        already have a designated recipient and are not
     *                        used as part of a provided fulfillment.
     * @param containsNonOpen A boolean indicating whether any restricted or
     *                        contract orders are present within the provided
     *                        array of advanced orders.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function _fulfillAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        Fulfillment[] memory fulfillments,
        bytes32[] memory orderHashes,
        address recipient,
        bool containsNonOpen
    ) internal returns (Execution[] memory executions) {
        // Retrieve fulfillments array length and place on the stack.
        uint256 totalFulfillments = fulfillments.length;

        // Allocate executions by fulfillment and apply them to each execution.
        executions = new Execution[](totalFulfillments);

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Track number of filtered executions.
            uint256 totalFilteredExecutions = 0;

            // Iterate over each fulfillment.
            for (uint256 i = 0; i < totalFulfillments; ++i) {
                /// Retrieve the fulfillment in question.
                Fulfillment memory fulfillment = fulfillments[i];

                // Derive the execution corresponding with the fulfillment.
                Execution memory execution = _applyFulfillment(
                    advancedOrders, fulfillment.offerComponents, fulfillment.considerationComponents, i
                );

                // If the execution is filterable...
                if (_isFilterableExecution(execution)) {
                    // Increment total filtered executions.
                    ++totalFilteredExecutions;
                } else {
                    // Otherwise, assign the execution to the executions array.
                    executions[i - totalFilteredExecutions] = execution;
                }
            }

            // If some number of executions have been filtered...
            if (totalFilteredExecutions != 0) {
                // reduce the total length of the executions array.
                assembly {
                    mstore(executions, sub(mload(executions), totalFilteredExecutions))
                }
            }
        }

        // Perform final checks and execute orders.
        _performFinalChecksAndExecuteOrders(advancedOrders, executions, orderHashes, recipient, containsNonOpen);

        // Return the executions array.
        return executions;
    }

    /**
     * @dev Internal pure function to determine whether a given execution is
     *      filterable and may be removed from the executions array. The offerer
     *      and the recipient must be the same address and the item type cannot
     *      indicate a native token transfer.
     *
     * @param execution The execution to check for filterability.
     *
     * @return filterable A boolean indicating whether the execution in question
     *                    can be filtered from the executions array.
     */
    function _isFilterableExecution(Execution memory execution) internal pure returns (bool filterable) {
        // Utilize assembly to efficiently determine if execution is filterable.
        assembly {
            // Retrieve the received item referenced by the execution.
            let item := mload(execution)

            // Determine whether the execution is filterable.
            filterable :=
                and(
                    // Determine if offerer and recipient are the same address.
                    eq(
                        // Retrieve the recipient's address from the received item.
                        mload(add(item, ReceivedItem_recipient_offset)),
                        // Retrieve the offerer's address from the execution.
                        mload(add(execution, Execution_offerer_offset))
                    ),
                    // Determine if received item's item type is non-zero, thereby
                    // indicating that the execution does not involve native tokens.
                    iszero(iszero(mload(item)))
                )
        }
    }
}
