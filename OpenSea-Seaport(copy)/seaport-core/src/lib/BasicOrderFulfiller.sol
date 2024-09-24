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

import {BasicOrderRouteType, ItemType, OrderType} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {BasicOrderParameters} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {OrderValidator} from "./OrderValidator.sol";

import {
    _revertInsufficientNativeTokensSupplied,
    _revertInvalidMsgValue,
    _revertInvalidERC721TransferAmount,
    _revertUnusedItemParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrors.sol";

import {
    AccumulatorDisarmed,
    AdditionalRecipient_size_shift,
    AdditionalRecipient_size,
    BasicOrder_additionalRecipients_data_cdPtr,
    BasicOrder_additionalRecipients_length_cdPtr,
    BasicOrder_basicOrderType_cdPtr,
    BasicOrder_common_params_size,
    BasicOrder_considerationAmount_cdPtr,
    BasicOrder_considerationHashesArray_ptr,
    BasicOrder_considerationIdentifier_cdPtr,
    BasicOrder_considerationItem_endAmount_ptr,
    BasicOrder_considerationItem_identifier_ptr,
    BasicOrder_considerationItem_itemType_ptr,
    BasicOrder_considerationItem_startAmount_ptr,
    BasicOrder_considerationItem_token_ptr,
    BasicOrder_considerationItem_typeHash_ptr,
    BasicOrder_considerationToken_cdPtr,
    BasicOrder_endTime_cdPtr,
    BasicOrder_fulfillerConduit_cdPtr,
    BasicOrder_offerAmount_cdPtr,
    BasicOrder_offeredItemByteMap,
    BasicOrder_offerer_cdPtr,
    BasicOrder_offererConduit_cdPtr,
    BasicOrder_offerIdentifier_cdPtr,
    BasicOrder_offerItem_endAmount_ptr,
    BasicOrder_offerItem_itemType_ptr,
    BasicOrder_offerItem_token_ptr,
    BasicOrder_offerItem_typeHash_ptr,
    BasicOrder_offerToken_cdPtr,
    BasicOrder_order_considerationHashes_ptr,
    BasicOrder_order_counter_ptr,
    BasicOrder_order_offerer_ptr,
    BasicOrder_order_offerHashes_ptr,
    BasicOrder_order_orderType_ptr,
    BasicOrder_order_startTime_ptr,
    BasicOrder_order_typeHash_ptr,
    BasicOrder_receivedItemByteMap,
    BasicOrder_startTime_cdPtr,
    BasicOrder_totalOriginalAdditionalRecipients_cdPtr,
    BasicOrder_zone_cdPtr,
    Common_token_offset,
    Conduit_execute_ConduitTransfer_length_ptr,
    Conduit_execute_ConduitTransfer_length,
    Conduit_execute_ConduitTransfer_offset_ptr,
    Conduit_execute_ConduitTransfer_ptr,
    Conduit_execute_signature,
    Conduit_execute_transferAmount_ptr,
    Conduit_execute_transferIdentifier_ptr,
    Conduit_execute_transferFrom_ptr,
    Conduit_execute_transferItemType_ptr,
    Conduit_execute_transferTo_ptr,
    Conduit_execute_transferToken_ptr,
    EIP712_ConsiderationItem_size,
    EIP712_OfferItem_size,
    EIP712_Order_size,
    FiveWords,
    FourWords,
    FreeMemoryPointerSlot,
    MaskOverLastTwentyBytes,
    OneConduitExecute_size,
    OneWord,
    OneWordShift,
    OrderFulfilled_baseOffset,
    OrderFulfilled_baseSize,
    OrderFulfilled_consideration_body_offset,
    OrderFulfilled_consideration_head_offset,
    OrderFulfilled_consideration_length_baseOffset,
    OrderFulfilled_fulfiller_offset,
    OrderFulfilled_offer_body_offset,
    OrderFulfilled_offer_head_offset,
    OrderFulfilled_offer_length_baseOffset,
    OrderFulfilled_selector,
    ReceivedItem_amount_offset,
    ReceivedItem_size,
    receivedItemsHash_ptr,
    ThreeWords,
    TwoWords,
    ZeroSlot
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

import {
    Error_selector_offset,
    InvalidBasicOrderParameterEncoding_error_length,
    InvalidBasicOrderParameterEncoding_error_selector,
    InvalidTime_error_endTime_ptr,
    InvalidTime_error_length,
    InvalidTime_error_selector,
    InvalidTime_error_startTime_ptr,
    MissingOriginalConsiderationItems_error_length,
    MissingOriginalConsiderationItems_error_selector,
    UnusedItemParameters_error_length,
    UnusedItemParameters_error_selector
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrorConstants.sol";

/**
 * @title BasicOrderFulfiller
 * @author 0age
 * @notice BasicOrderFulfiller contains functionality for fulfilling "basic"
 *         orders with minimal overhead. See documentation for details on what
 *         qualifies as a basic order.
 */
contract BasicOrderFulfiller is OrderValidator {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) OrderValidator(conduitController) {}

    /**
     * @dev Internal function to fulfill an order offering an ERC20, ERC721, or
     *      ERC1155 item by supplying Ether (or other native tokens), ERC20
     *      tokens, an ERC721 item, or an ERC1155 item as consideration. Six
     *      permutations are supported: Native token to ERC721, Native token to
     *      ERC1155, ERC20 to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and
     *      ERC1155 to ERC20 (with native tokens supplied as msg.value). For an
     *      order to be eligible for fulfillment via this method, it must
     *      contain a single offer item (though that item may have a greater
     *      amount if the item is not an ERC721). An arbitrary number of
     *      "additional recipients" may also be supplied which will each receive
     *      native tokens or ERC20 items from the fulfiller as consideration.
     *      Refer to the documentation for a more comprehensive summary of how
     *      to utilize this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` in order to receive those
     *                   items.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function _validateAndFulfillBasicOrder(BasicOrderParameters calldata parameters) internal returns (bool) {
        // Declare enums for order type & route to extract from basicOrderType.
        BasicOrderRouteType route;
        OrderType orderType;

        // Declare additional recipient item type to derive from the route type.
        ItemType additionalRecipientsItemType;

        bytes32 orderHash;

        // Utilize assembly to extract the order type and the basic order route.
        assembly {
            // Read basicOrderType from calldata.
            let basicOrderType := calldataload(BasicOrder_basicOrderType_cdPtr)

            // Mask all but 2 least-significant bits to derive the order type.
            orderType := and(basicOrderType, 3)

            // Divide basicOrderType by four to derive the route.
            route := shr(2, basicOrderType)

            // If route > 1 additionalRecipient items are ERC20 (1) else native
            // token (0).
            additionalRecipientsItemType := gt(route, 1)
        }

        {
            // Declare temporary variable for enforcing payable status.
            bool correctPayableStatus;

            // Utilize assembly to compare the route to the callvalue.
            assembly {
                // route 0 and 1 are payable, otherwise route is not payable.
                correctPayableStatus := eq(additionalRecipientsItemType, iszero(callvalue()))
            }

            // Revert if msg.value has not been supplied as part of payable
            // routes or has been supplied as part of non-payable routes.
            if (!correctPayableStatus) {
                _revertInvalidMsgValue(msg.value);
            }
        }

        // Declare more arguments that will be derived from route and calldata.
        address additionalRecipientsToken;
        ItemType offeredItemType;
        bool offerTypeIsAdditionalRecipientsType;

        // Declare scope for received item type to manage stack pressure.
        {
            ItemType receivedItemType;

            // Utilize assembly to retrieve function arguments and cast types.
            assembly {
                // Check if offered item type == additional recipient item type.
                offerTypeIsAdditionalRecipientsType := gt(route, 3)

                // If route > 3 additionalRecipientsToken is at 0xc4 else 0x24.
                additionalRecipientsToken :=
                    calldataload(
                        add(
                            BasicOrder_considerationToken_cdPtr,
                            mul(offerTypeIsAdditionalRecipientsType, BasicOrder_common_params_size)
                        )
                    )

                // If route > 2, receivedItemType is route - 2. If route is 2,
                // the receivedItemType is ERC20 (1). Otherwise, it is native
                // token (0).
                receivedItemType := byte(route, BasicOrder_receivedItemByteMap)

                // If route > 3, offeredItemType is ERC20 (1). Route is 2 or 3,
                // offeredItemType = route. Route is 0 or 1, it is route + 2.
                offeredItemType := byte(route, BasicOrder_offeredItemByteMap)
            }

            // Derive & validate order using parameters and update order status.
            orderHash = _prepareBasicFulfillmentFromCalldata(
                parameters,
                orderType,
                receivedItemType,
                additionalRecipientsItemType,
                additionalRecipientsToken,
                offeredItemType
            );
        }

        // Declare conduitKey argument used by transfer functions.
        bytes32 conduitKey;

        // Utilize assembly to derive conduit (if relevant) based on route.
        assembly {
            // use offerer conduit for routes 0-3, fulfiller conduit otherwise.
            conduitKey :=
                calldataload(add(BasicOrder_offererConduit_cdPtr, shl(OneWordShift, offerTypeIsAdditionalRecipientsType)))
        }

        // Transfer tokens based on the route.
        if (additionalRecipientsItemType == ItemType.NATIVE) {
            // Ensure neither consideration token nor identifier are set. Note
            // that dirty upper bits in the consideration token will still cause
            // this error to be thrown.
            assembly {
                if or(
                    calldataload(BasicOrder_considerationToken_cdPtr),
                    calldataload(BasicOrder_considerationIdentifier_cdPtr)
                ) {
                    // Store left-padded selector with push4 (reduces bytecode),
                    // mem[28:32] = selector
                    mstore(0, UnusedItemParameters_error_selector)

                    // revert(abi.encodeWithSignature("UnusedItemParameters()"))
                    revert(Error_selector_offset, UnusedItemParameters_error_length)
                }
            }

            // Transfer the ERC721 or ERC1155 item, bypassing the accumulator.
            _transferIndividual721Or1155Item(offeredItemType, conduitKey);

            // Transfer native to recipients, return excess to caller & wrap up.
            _transferNativeTokensAndFinalize();
        } else {
            // Initialize an accumulator array. From this point forward, no new
            // memory regions can be safely allocated until the accumulator is
            // no longer being utilized, as the accumulator operates in an
            // open-ended fashion from this memory pointer; existing memory may
            // still be accessed and modified, however.
            bytes memory accumulator = new bytes(AccumulatorDisarmed);

            // Choose transfer method for ERC721 or ERC1155 item based on route.
            if (route == BasicOrderRouteType.ERC20_TO_ERC721) {
                // Transfer ERC721 to caller using offerer's conduit preference.
                _transferERC721(
                    parameters.offerToken,
                    parameters.offerer,
                    msg.sender,
                    parameters.offerIdentifier,
                    parameters.offerAmount,
                    conduitKey,
                    accumulator
                );
            } else if (route == BasicOrderRouteType.ERC20_TO_ERC1155) {
                // Transfer ERC1155 to caller with offerer's conduit preference.
                _transferERC1155(
                    parameters.offerToken,
                    parameters.offerer,
                    msg.sender,
                    parameters.offerIdentifier,
                    parameters.offerAmount,
                    conduitKey,
                    accumulator
                );
            } else if (route == BasicOrderRouteType.ERC721_TO_ERC20) {
                // Transfer ERC721 to offerer using caller's conduit preference.
                _transferERC721(
                    parameters.considerationToken,
                    msg.sender,
                    parameters.offerer,
                    parameters.considerationIdentifier,
                    parameters.considerationAmount,
                    conduitKey,
                    accumulator
                );
            } else {
                // route == BasicOrderRouteType.ERC1155_TO_ERC20

                // Transfer ERC1155 to offerer with caller's conduit preference.
                _transferERC1155(
                    parameters.considerationToken,
                    msg.sender,
                    parameters.offerer,
                    parameters.considerationIdentifier,
                    parameters.considerationAmount,
                    conduitKey,
                    accumulator
                );
            }

            // Transfer ERC20 tokens to all recipients and wrap up.
            _transferERC20AndFinalize(offerTypeIsAdditionalRecipientsType, accumulator);

            // Trigger any remaining accumulated transfers via call to conduit.
            _triggerIfArmed(accumulator);
        }

        // Determine whether order is restricted and, if so, that it is valid.
        _assertRestrictedBasicOrderValidity(orderHash, orderType, parameters);

        // Clear the reentrancy guard.
        _clearReentrancyGuard();

        return true;
    }

    /**
     * @dev Internal function to prepare fulfillment of a basic order with
     *      manual calldata and memory access. This calculates the order hash,
     *      emits an OrderFulfilled event, and asserts basic order validity.
     *      Note that calldata offsets must be validated as this function
     *      accesses constant calldata pointers for dynamic types that match
     *      default ABI encoding, but valid ABI encoding can use arbitrary
     *      offsets. Checking that the offsets were produced by default encoding
     *      will ensure that other functions using Solidity's calldata accessors
     *      (which calculate pointers from the stored offsets) are reading the
     *      same data as the order hash is derived from. Also note that this
     *      function accesses memory directly.
     *
     * @param parameters                   The parameters of the basic order.
     * @param orderType                    The order type.
     * @param receivedItemType             The item type of the initial
     *                                     consideration item on the order.
     * @param additionalRecipientsItemType The item type of any additional
     *                                     consideration item on the order.
     * @param additionalRecipientsToken    The ERC20 token contract address (if
     *                                     applicable) for any additional
     *                                     consideration item on the order.
     * @param offeredItemType              The item type of the offered item on
     *                                     the order.
     * @return orderHash The calculated order hash.
     */
    function _prepareBasicFulfillmentFromCalldata(
        BasicOrderParameters calldata parameters,
        OrderType orderType,
        ItemType receivedItemType,
        ItemType additionalRecipientsItemType,
        address additionalRecipientsToken,
        ItemType offeredItemType
    ) internal returns (bytes32 orderHash) {
        // Ensure this function cannot be triggered during a reentrant call.
        _setReentrancyGuard(false); // Native tokens rejected during execution.

        // Verify that calldata offsets for all dynamic types were produced by
        // default encoding. This ensures that the constants used for calldata
        // pointers to dynamic types are the same as those calculated by
        // Solidity using their offsets. Also verify that the basic order type
        // is within range.
        _assertValidBasicOrderParameters();

        // Check for invalid time and missing original consideration items.
        // Utilize assembly so that constant calldata pointers can be applied.
        assembly {
            // Ensure current timestamp is between order start time & end time.
            if or(
                gt(calldataload(BasicOrder_startTime_cdPtr), timestamp()),
                iszero(gt(calldataload(BasicOrder_endTime_cdPtr), timestamp()))
            ) {
                // Store left-padded selector with push4 (reduces bytecode),
                // mem[28:32] = selector
                mstore(0, InvalidTime_error_selector)

                // Store arguments.
                mstore(InvalidTime_error_startTime_ptr, calldataload(BasicOrder_startTime_cdPtr))
                mstore(InvalidTime_error_endTime_ptr, calldataload(BasicOrder_endTime_cdPtr))

                // revert(abi.encodeWithSignature(
                //     "InvalidTime(uint256,uint256)",
                //     startTime,
                //     endTime
                // ))
                revert(Error_selector_offset, InvalidTime_error_length)
            }

            // Ensure consideration array length isn't less than total original.
            if lt(
                calldataload(BasicOrder_additionalRecipients_length_cdPtr),
                calldataload(BasicOrder_totalOriginalAdditionalRecipients_cdPtr)
            ) {
                // Store left-padded selector with push4 (reduces bytecode),
                // mem[28:32] = selector
                mstore(0, MissingOriginalConsiderationItems_error_selector)

                // revert(abi.encodeWithSignature(
                //     "MissingOriginalConsiderationItems()"
                // ))
                revert(Error_selector_offset, MissingOriginalConsiderationItems_error_length)
            }
        }

        {
            /**
             * First, handle consideration items. Memory Layout:
             *  0x60: final hash of the array of consideration item hashes
             *  0x80-0x160: reused space for EIP712 hashing of each item
             *   - 0x80: ConsiderationItem EIP-712 typehash (constant)
             *   - 0xa0: itemType
             *   - 0xc0: token
             *   - 0xe0: identifier
             *   - 0x100: startAmount
             *   - 0x120: endAmount
             *   - 0x140: recipient
             *  0x160-END_ARR: array of consideration item hashes
             *   - 0x160: primary consideration item EIP712 hash
             *   - 0x180-END_ARR: additional recipient item EIP712 hashes
             *  END_ARR: beginning of data for OrderFulfilled event
             *   - END_ARR + 0x120: length of ReceivedItem array
             *   - END_ARR + 0x140: beginning of data for first ReceivedItem
             * (Note: END_ARR = 0x180 + RECIPIENTS_LENGTH * 0x20)
             */

            // Load consideration item typehash from runtime and place on stack.
            bytes32 typeHash = _CONSIDERATION_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions and use
            // constant pointers when possible.
            assembly {
                /*
                 * 1. Calculate the EIP712 ConsiderationItem hash for the
                 * primary consideration item of the basic order.
                 */

                // Write ConsiderationItem type hash and item type to memory.
                mstore(BasicOrder_considerationItem_typeHash_ptr, typeHash)
                mstore(BasicOrder_considerationItem_itemType_ptr, receivedItemType)

                // Copy calldata region with (token, identifier, amount) from
                // BasicOrderParameters to ConsiderationItem. The
                // considerationAmount is written to startAmount and endAmount
                // as basic orders do not have dynamic amounts.
                calldatacopy(BasicOrder_considerationItem_token_ptr, BasicOrder_considerationToken_cdPtr, ThreeWords)

                // Copy calldata region with considerationAmount and offerer
                // from BasicOrderParameters to endAmount and recipient in
                // ConsiderationItem.
                calldatacopy(BasicOrder_considerationItem_endAmount_ptr, BasicOrder_considerationAmount_cdPtr, TwoWords)

                // Calculate EIP712 ConsiderationItem hash and store it in the
                // array of EIP712 consideration hashes.
                mstore(
                    BasicOrder_considerationHashesArray_ptr,
                    keccak256(BasicOrder_considerationItem_typeHash_ptr, EIP712_ConsiderationItem_size)
                )

                /*
                 * 2. Write a ReceivedItem struct for the primary consideration
                 * item to the consideration array in OrderFulfilled.
                 */

                // Get the length of the additional recipients array.
                let totalAdditionalRecipients := calldataload(BasicOrder_additionalRecipients_length_cdPtr)

                // Calculate pointer to length of OrderFulfilled consideration
                // array.
                let eventConsiderationArrPtr :=
                    add(OrderFulfilled_consideration_length_baseOffset, shl(OneWordShift, totalAdditionalRecipients))

                // Set the length of the consideration array to the number of
                // additional recipients, plus one for the primary consideration
                // item.
                mstore(eventConsiderationArrPtr, add(totalAdditionalRecipients, 1))

                // Overwrite the consideration array pointer so it points to the
                // body of the first element
                eventConsiderationArrPtr := add(eventConsiderationArrPtr, OneWord)

                // Set itemType at start of the ReceivedItem memory region.
                mstore(eventConsiderationArrPtr, receivedItemType)

                // Copy calldata region (token, identifier, amount & recipient)
                // from BasicOrderParameters to ReceivedItem memory.
                calldatacopy(
                    add(eventConsiderationArrPtr, Common_token_offset), BasicOrder_considerationToken_cdPtr, FourWords
                )

                /*
                 * 3. Calculate EIP712 ConsiderationItem hashes for original
                 * additional recipients and add a ReceivedItem for each to the
                 * consideration array in the OrderFulfilled event. The original
                 * additional recipients are all the consideration items signed
                 * by the offerer aside from the primary consideration items of
                 * the order. Uses memory region from 0x80-0x160 as a buffer for
                 * calculating EIP712 ConsiderationItem hashes.
                 */

                // Put pointer to consideration hashes array on the stack.
                // This will be updated as each additional recipient is hashed
                let considerationHashesPtr := BasicOrder_considerationHashesArray_ptr

                // Write item type, token, & identifier for additional recipient
                // to memory region for hashing EIP712 ConsiderationItem; these
                // values will be reused for each recipient.
                mstore(BasicOrder_considerationItem_itemType_ptr, additionalRecipientsItemType)
                mstore(BasicOrder_considerationItem_token_ptr, additionalRecipientsToken)
                mstore(BasicOrder_considerationItem_identifier_ptr, 0)

                // Declare a stack variable where all additional recipients will
                // be combined to guard against providing dirty upper bits.
                let combinedAdditionalRecipients

                // Read length of the additionalRecipients array from calldata
                // and iterate.
                totalAdditionalRecipients := calldataload(BasicOrder_totalOriginalAdditionalRecipients_cdPtr)
                let i := 0
                for {} lt(i, totalAdditionalRecipients) { i := add(i, 1) } {
                    /*
                     * Calculate EIP712 ConsiderationItem hash for recipient.
                     */

                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr :=
                        add(BasicOrder_additionalRecipients_data_cdPtr, mul(AdditionalRecipient_size, i))

                    // Copy startAmount from calldata to the ConsiderationItem
                    // struct.
                    calldatacopy(BasicOrder_considerationItem_startAmount_ptr, additionalRecipientCdPtr, OneWord)

                    // Copy endAmount and recipient from calldata to the
                    // ConsiderationItem struct.
                    calldatacopy(
                        BasicOrder_considerationItem_endAmount_ptr, additionalRecipientCdPtr, AdditionalRecipient_size
                    )

                    // Include the recipient as part of combined recipients.
                    combinedAdditionalRecipients :=
                        or(combinedAdditionalRecipients, calldataload(add(additionalRecipientCdPtr, OneWord)))

                    // Add 1 word to the pointer as part of each loop to reduce
                    // operations needed to get local offset into the array.
                    considerationHashesPtr := add(considerationHashesPtr, OneWord)

                    // Calculate EIP712 ConsiderationItem hash and store it in
                    // the array of consideration hashes.
                    mstore(
                        considerationHashesPtr,
                        keccak256(BasicOrder_considerationItem_typeHash_ptr, EIP712_ConsiderationItem_size)
                    )

                    /*
                     * Write ReceivedItem to OrderFulfilled data.
                     */

                    // At this point, eventConsiderationArrPtr points to the
                    // beginning of the ReceivedItem struct of the previous
                    // element in the array. Increase it by the size of the
                    // struct to arrive at the pointer for the current element.
                    eventConsiderationArrPtr := add(eventConsiderationArrPtr, ReceivedItem_size)

                    // Write itemType to the ReceivedItem struct.
                    mstore(eventConsiderationArrPtr, additionalRecipientsItemType)

                    // Write token to the next word of the ReceivedItem struct.
                    mstore(add(eventConsiderationArrPtr, OneWord), additionalRecipientsToken)

                    // Copy endAmount & recipient words to ReceivedItem struct.
                    calldatacopy(
                        add(eventConsiderationArrPtr, ReceivedItem_amount_offset), additionalRecipientCdPtr, TwoWords
                    )
                }

                /*
                 * 4. Hash packed array of ConsiderationItem EIP712 hashes:
                 *   `keccak256(abi.encodePacked(receivedItemHashes))`
                 * Note that it is set at 0x60 — all other memory begins at
                 * 0x80. 0x60 is the "zero slot" and will be restored at the end
                 * of the assembly section and before required by the compiler.
                 */
                mstore(
                    receivedItemsHash_ptr,
                    keccak256(
                        BasicOrder_considerationHashesArray_ptr, shl(OneWordShift, add(totalAdditionalRecipients, 1))
                    )
                )

                /*
                 * 5. Add a ReceivedItem for each tip to the consideration array
                 * in the OrderFulfilled event. The tips are all the
                 * consideration items that were not signed by the offerer and
                 * were provided by the fulfiller.
                 */

                // Overwrite length to length of the additionalRecipients array.
                totalAdditionalRecipients := calldataload(BasicOrder_additionalRecipients_length_cdPtr)

                for {} lt(i, totalAdditionalRecipients) { i := add(i, 1) } {
                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr :=
                        add(BasicOrder_additionalRecipients_data_cdPtr, mul(AdditionalRecipient_size, i))

                    // At this point, eventConsiderationArrPtr points to the
                    // beginning of the ReceivedItem struct of the previous
                    // element in the array. Increase it by the size of the
                    // struct to arrive at the pointer for the current element.
                    eventConsiderationArrPtr := add(eventConsiderationArrPtr, ReceivedItem_size)

                    // Write itemType to the ReceivedItem struct.
                    mstore(eventConsiderationArrPtr, additionalRecipientsItemType)

                    // Write token to the next word of the ReceivedItem struct.
                    mstore(add(eventConsiderationArrPtr, OneWord), additionalRecipientsToken)

                    // Copy endAmount & recipient words to ReceivedItem struct.
                    calldatacopy(
                        add(eventConsiderationArrPtr, ReceivedItem_amount_offset), additionalRecipientCdPtr, TwoWords
                    )

                    // Include the recipient as part of combined recipients.
                    combinedAdditionalRecipients :=
                        or(combinedAdditionalRecipients, calldataload(add(additionalRecipientCdPtr, OneWord)))
                }

                // Ensure no dirty upper bits on combined additional recipients.
                if gt(combinedAdditionalRecipients, MaskOverLastTwentyBytes) {
                    // Store left-padded selector with push4 (reduces bytecode),
                    // mem[28:32] = selector
                    mstore(0, InvalidBasicOrderParameterEncoding_error_selector)

                    // revert(abi.encodeWithSignature(
                    //     "InvalidBasicOrderParameterEncoding()"
                    // ))
                    revert(Error_selector_offset, InvalidBasicOrderParameterEncoding_error_length)
                }
            }
        }

        {
            /**
             * Next, handle offered items. Memory Layout:
             *  EIP712 data for OfferItem
             *   - 0x80:  OfferItem EIP-712 typehash (constant)
             *   - 0xa0:  itemType
             *   - 0xc0:  token
             *   - 0xe0:  identifier (reused for offeredItemsHash)
             *   - 0x100: startAmount
             *   - 0x120: endAmount
             */

            // Place offer item typehash on the stack.
            bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions when possible.
            assembly {
                /*
                 * 1. Calculate OfferItem EIP712 hash
                 */

                // Write the OfferItem typeHash to memory.
                mstore(BasicOrder_offerItem_typeHash_ptr, typeHash)

                // Write the OfferItem item type to memory.
                mstore(BasicOrder_offerItem_itemType_ptr, offeredItemType)

                // Copy calldata region with (offerToken, offerIdentifier,
                // offerAmount) from OrderParameters to (token, identifier,
                // startAmount) in OfferItem struct. The offerAmount is written
                // to startAmount and endAmount as basic orders do not have
                // dynamic amounts.
                calldatacopy(BasicOrder_offerItem_token_ptr, BasicOrder_offerToken_cdPtr, ThreeWords)

                // Copy offerAmount from calldata to endAmount in OfferItem
                // struct.
                calldatacopy(BasicOrder_offerItem_endAmount_ptr, BasicOrder_offerAmount_cdPtr, OneWord)

                // Compute EIP712 OfferItem hash, write result to scratch space:
                //   `keccak256(abi.encode(offeredItem))`
                mstore(0, keccak256(BasicOrder_offerItem_typeHash_ptr, EIP712_OfferItem_size))

                /*
                 * 2. Calculate hash of array of EIP712 hashes and write the
                 * result to the corresponding OfferItem struct:
                 *   `keccak256(abi.encodePacked(offerItemHashes))`
                 */
                mstore(BasicOrder_order_offerHashes_ptr, keccak256(0, OneWord))

                /*
                 * 3. Write SpentItem to offer array in OrderFulfilled event.
                 */
                let eventConsiderationArrPtr :=
                    add(
                        OrderFulfilled_offer_length_baseOffset,
                        shl(OneWordShift, calldataload(BasicOrder_additionalRecipients_length_cdPtr))
                    )

                // Set a length of 1 for the offer array.
                mstore(eventConsiderationArrPtr, 1)

                // Write itemType to the SpentItem struct.
                mstore(add(eventConsiderationArrPtr, OneWord), offeredItemType)

                // Copy calldata region with (offerToken, offerIdentifier,
                // offerAmount) from OrderParameters to (token, identifier,
                // amount) in SpentItem struct.
                calldatacopy(
                    add(eventConsiderationArrPtr, AdditionalRecipient_size), BasicOrder_offerToken_cdPtr, ThreeWords
                )
            }
        }

        {
            /**
             * Once consideration items and offer items have been handled,
             * derive the final order hash. Memory Layout:
             *  0x80-0x1c0: EIP712 data for order
             *   - 0x80:   Order EIP-712 typehash (constant)
             *   - 0xa0:   orderParameters.offerer
             *   - 0xc0:   orderParameters.zone
             *   - 0xe0:   keccak256(abi.encodePacked(offerHashes))
             *   - 0x100:  keccak256(abi.encodePacked(considerationHashes))
             *   - 0x120:  orderParameters.basicOrderType (% 4 = orderType)
             *   - 0x140:  orderParameters.startTime
             *   - 0x160:  orderParameters.endTime
             *   - 0x180:  orderParameters.zoneHash
             *   - 0x1a0:  orderParameters.salt
             *   - 0x1c0:  orderParameters.conduitKey
             *   - 0x1e0:  _counters[orderParameters.offerer] (from storage)
             */

            // Read the offerer from calldata and place on the stack.
            address offerer;
            assembly {
                offerer := calldataload(BasicOrder_offerer_cdPtr)
            }

            // Read offerer's current counter from storage and place on stack.
            uint256 counter = _getCounter(offerer);

            // Load order typehash from runtime code and place on stack.
            bytes32 typeHash = _ORDER_TYPEHASH;

            assembly {
                // Set the OrderItem typeHash in memory.
                mstore(BasicOrder_order_typeHash_ptr, typeHash)

                // Copy offerer and zone from OrderParameters in calldata to the
                // Order struct.
                calldatacopy(BasicOrder_order_offerer_ptr, BasicOrder_offerer_cdPtr, TwoWords)

                // Copy receivedItemsHash from zero slot to the Order struct.
                mstore(BasicOrder_order_considerationHashes_ptr, mload(receivedItemsHash_ptr))

                // Write the supplied orderType to the Order struct.
                mstore(BasicOrder_order_orderType_ptr, orderType)

                // Copy startTime, endTime, zoneHash, salt & conduit from
                // calldata to the Order struct.
                calldatacopy(BasicOrder_order_startTime_ptr, BasicOrder_startTime_cdPtr, FiveWords)

                // Write offerer's counter, retrieved from storage, to struct.
                mstore(BasicOrder_order_counter_ptr, counter)

                // Compute the EIP712 Order hash.
                orderHash := keccak256(BasicOrder_order_typeHash_ptr, EIP712_Order_size)
            }
        }

        assembly {
            /**
             * After the order hash has been derived, emit OrderFulfilled event:
             *   event OrderFulfilled(
             *     bytes32 orderHash,
             *     address indexed offerer,
             *     address indexed zone,
             *     address fulfiller,
             *     SpentItem[] offer,
             *       > (itemType, token, id, amount)
             *     ReceivedItem[] consideration
             *       > (itemType, token, id, amount, recipient)
             *   )
             * topic0 - OrderFulfilled event signature
             * topic1 - offerer
             * topic2 - zone
             * data:
             *  - 0x00: orderHash
             *  - 0x20: fulfiller
             *  - 0x40: offer arr ptr (0x80)
             *  - 0x60: consideration arr ptr (0x120)
             *  - 0x80: offer arr len (1)
             *  - 0xa0: offer.itemType
             *  - 0xc0: offer.token
             *  - 0xe0: offer.identifier
             *  - 0x100: offer.amount
             *  - 0x120: 1 + recipients.length
             *  - 0x140: recipient 0
             */

            // Derive pointer to start of OrderFulfilled event data.
            let eventDataPtr :=
                add(
                    OrderFulfilled_baseOffset, shl(OneWordShift, calldataload(BasicOrder_additionalRecipients_length_cdPtr))
                )

            // Write the order hash to the head of the event's data region.
            mstore(eventDataPtr, orderHash)

            // Write the fulfiller (i.e. the caller) next for receiver argument.
            mstore(add(eventDataPtr, OrderFulfilled_fulfiller_offset), caller())

            // Write the SpentItem and ReceivedItem array offsets (constants).
            mstore(
                // SpentItem array offset
                add(eventDataPtr, OrderFulfilled_offer_head_offset),
                OrderFulfilled_offer_body_offset
            )
            mstore(
                // ReceivedItem array offset
                add(eventDataPtr, OrderFulfilled_consideration_head_offset),
                OrderFulfilled_consideration_body_offset
            )

            // Derive total data size including SpentItem and ReceivedItem data.
            // SpentItem portion is already included in the baseSize constant,
            // as there can only be one element in the array.
            let dataSize :=
                add(
                    OrderFulfilled_baseSize,
                    mul(calldataload(BasicOrder_additionalRecipients_length_cdPtr), ReceivedItem_size)
                )

            // Emit OrderFulfilled log with three topics (the event signature
            // as well as the two indexed arguments, the offerer and the zone).
            log3(
                // Supply the pointer for event data in memory.
                eventDataPtr,
                // Supply the size of event data in memory.
                dataSize,
                // Supply the OrderFulfilled event signature.
                OrderFulfilled_selector,
                // Supply the first topic (the offerer).
                calldataload(BasicOrder_offerer_cdPtr),
                // Supply the second topic (the zone).
                calldataload(BasicOrder_zone_cdPtr)
            )

            // Restore the zero slot.
            mstore(ZeroSlot, 0)

            // Update the free memory pointer so that event data is persisted.
            mstore(FreeMemoryPointerSlot, add(eventDataPtr, dataSize))
        }

        // Verify and update the status of the derived order.
        _validateBasicOrderAndUpdateStatus(orderHash, parameters.signature);

        // Return the derived order hash.
        return orderHash;
    }

    /**
     * @dev Internal function to transfer an individual ERC721 or ERC1155 item
     *      from a given originator to a given recipient. The accumulator will
     *      be bypassed, meaning that this function should be utilized in cases
     *      where multiple item transfers can be accumulated into a single
     *      conduit call. Sufficient approvals must be set, either on the
     *      respective conduit or on this contract. Note that this function may
     *      only be safely called as part of basic orders, as it assumes a
     *      specific calldata encoding structure that must first be validated.
     *
     * @param itemType   The type of item to transfer, either ERC721 or ERC1155.
     * @param conduitKey A bytes32 value indicating what corresponding conduit,
     *                   if any, to source token approvals from. The zero hash
     *                   signifies that no conduit should be used, with direct
     *                   approvals set on this contract.
     */
    function _transferIndividual721Or1155Item(ItemType itemType, bytes32 conduitKey) internal {
        // Retrieve token, from, identifier, and amount from calldata using
        // fixed calldata offsets based on strict basic parameter encoding.
        address token;
        address from;
        uint256 identifier;
        uint256 amount;
        assembly {
            token := calldataload(BasicOrder_offerToken_cdPtr)
            from := calldataload(BasicOrder_offerer_cdPtr)
            identifier := calldataload(BasicOrder_offerIdentifier_cdPtr)
            amount := calldataload(BasicOrder_offerAmount_cdPtr)
        }

        // Determine if the transfer is to be performed via a conduit.
        if (conduitKey != bytes32(0)) {
            // Use free memory pointer as calldata offset for the conduit call.
            uint256 callDataOffset;

            // Utilize assembly to place each argument in free memory.
            assembly {
                // Retrieve the free memory pointer and use it as the offset.
                callDataOffset := mload(FreeMemoryPointerSlot)

                // Write ConduitInterface.execute.selector to memory.
                mstore(callDataOffset, Conduit_execute_signature)

                // Write the offset to the ConduitTransfer array in memory.
                mstore(
                    add(callDataOffset, Conduit_execute_ConduitTransfer_offset_ptr), Conduit_execute_ConduitTransfer_ptr
                )

                // Write the length of the ConduitTransfer array to memory.
                mstore(
                    add(callDataOffset, Conduit_execute_ConduitTransfer_length_ptr),
                    Conduit_execute_ConduitTransfer_length
                )

                // Write the item type to memory.
                mstore(add(callDataOffset, Conduit_execute_transferItemType_ptr), itemType)

                // Write the token to memory.
                mstore(add(callDataOffset, Conduit_execute_transferToken_ptr), token)

                // Write the transfer source to memory.
                mstore(add(callDataOffset, Conduit_execute_transferFrom_ptr), from)

                // Write the transfer recipient (the caller) to memory.
                mstore(add(callDataOffset, Conduit_execute_transferTo_ptr), caller())

                // Write the token identifier to memory.
                mstore(add(callDataOffset, Conduit_execute_transferIdentifier_ptr), identifier)

                // Write the transfer amount to memory.
                mstore(add(callDataOffset, Conduit_execute_transferAmount_ptr), amount)
            }

            // Perform the call to the conduit.
            _callConduitUsingOffsets(conduitKey, callDataOffset, OneConduitExecute_size);
        } else {
            // Otherwise, determine whether it is an ERC721 or ERC1155 item.
            if (itemType == ItemType.ERC721) {
                // Ensure that exactly one 721 item is being transferred.
                if (amount != 1) {
                    _revertInvalidERC721TransferAmount(amount);
                }

                // Perform transfer to caller via the token contract directly.
                _performERC721Transfer(token, from, msg.sender, identifier);
            } else {
                // Perform transfer to caller via the token contract directly.
                _performERC1155Transfer(token, from, msg.sender, identifier, amount);
            }
        }
    }

    /**
     * @dev Internal function to transfer Ether (or other native tokens) to a
     *      given recipient as part of basic order fulfillment. Note that
     *      conduits are not utilized for native tokens as the transferred
     *      amount must be provided as msg.value. Also note that this function
     *      may only be safely called as part of basic orders, as it assumes a
     *      specific calldata encoding structure that must first be validated.
     */
    function _transferNativeTokensAndFinalize() internal {
        // Put native token value supplied by the caller on the stack.
        uint256 nativeTokensRemaining = msg.value;

        // Retrieve consideration amount, offerer, and total size of additional
        // recipients data from calldata using fixed offsets and place on stack.
        uint256 amount;
        address payable to;
        uint256 totalAdditionalRecipientsDataSize;
        assembly {
            amount := calldataload(BasicOrder_considerationAmount_cdPtr)
            to := calldataload(BasicOrder_offerer_cdPtr)
            totalAdditionalRecipientsDataSize :=
                shl(AdditionalRecipient_size_shift, calldataload(BasicOrder_additionalRecipients_length_cdPtr))
        }

        uint256 additionalRecipientAmount;
        address payable recipient;

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Iterate over additional recipient data by two-word element.
            for (uint256 i = 0; i < totalAdditionalRecipientsDataSize; i += AdditionalRecipient_size) {
                assembly {
                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr := add(BasicOrder_additionalRecipients_data_cdPtr, i)

                    additionalRecipientAmount := calldataload(additionalRecipientCdPtr)
                    recipient := calldataload(add(OneWord, additionalRecipientCdPtr))
                }

                // Ensure that sufficient native tokens are available.
                if (additionalRecipientAmount > nativeTokensRemaining) {
                    _revertInsufficientNativeTokensSupplied();
                }

                // Reduce native token value available. Skip underflow check as
                // subtracted value is confirmed above as less than remaining.
                nativeTokensRemaining -= additionalRecipientAmount;

                // Transfer native tokens to the additional recipient.
                _transferNativeTokens(recipient, additionalRecipientAmount);
            }
        }

        // Ensure that sufficient native tokens are still available.
        if (amount > nativeTokensRemaining) {
            _revertInsufficientNativeTokensSupplied();
        }

        // Transfer native tokens to the offerer.
        _transferNativeTokens(to, amount);

        // If any native tokens remain after transfers, return to the caller.
        if (nativeTokensRemaining > amount) {
            // Skip underflow check as nativeTokensRemaining > amount.
            unchecked {
                // Transfer remaining native tokens to the caller.
                _transferNativeTokens(payable(msg.sender), nativeTokensRemaining - amount);
            }
        }
    }

    /**
     * @dev Internal function to transfer ERC20 tokens to a given recipient as
     *      part of basic order fulfillment. Note that this function may only be
     *      safely called as part of basic orders, as it assumes a specific
     *      calldata encoding structure that must first be validated. Also note
     *      that basic order parameters are retrieved using fixed offsets, this
     *      requires that strict basic order encoding has already been verified.
     *
     * @param fromOfferer A boolean indicating whether to decrement amount from
     *                    the offered amount.
     * @param accumulator An open-ended array that collects transfers to execute
     *                    against a given conduit in a single call.
     */
    function _transferERC20AndFinalize(bool fromOfferer, bytes memory accumulator) internal {
        // Declare from and to variables determined by fromOfferer value.
        address from;
        address to;

        // Declare token and amount variables determined by fromOfferer value.
        address token;
        uint256 amount;

        // Declare and check identifier variable within an isolated scope.
        {
            // Declare identifier variable determined by fromOfferer value.
            uint256 identifier;

            // Set ERC20 token transfer variables based on fromOfferer boolean.
            if (fromOfferer) {
                // Use offerer as from value, msg.sender as to value, and offer
                // token, identifier, & amount values if token is from offerer.
                assembly {
                    from := calldataload(BasicOrder_offerer_cdPtr)
                    to := caller()
                    token := calldataload(BasicOrder_offerToken_cdPtr)
                    identifier := calldataload(BasicOrder_offerIdentifier_cdPtr)
                    amount := calldataload(BasicOrder_offerAmount_cdPtr)
                }
            } else {
                // Otherwise, use msg.sender as from value, offerer as to value,
                // and consideration token, identifier, and amount values.
                assembly {
                    from := caller()
                    to := calldataload(BasicOrder_offerer_cdPtr)
                    token := calldataload(BasicOrder_considerationToken_cdPtr)
                    identifier := calldataload(BasicOrder_considerationIdentifier_cdPtr)
                    amount := calldataload(BasicOrder_considerationAmount_cdPtr)
                }
            }

            // Ensure that no identifier is supplied.
            if (identifier != 0) {
                _revertUnusedItemParameters();
            }
        }

        // Determine the appropriate conduit to utilize.
        bytes32 conduitKey;

        // Utilize assembly to derive conduit (if relevant) based on route.
        assembly {
            // Use offerer conduit if fromOfferer, fulfiller conduit otherwise.
            conduitKey := calldataload(sub(BasicOrder_fulfillerConduit_cdPtr, shl(OneWordShift, fromOfferer)))
        }

        // Retrieve total size of additional recipients data and place on stack.
        uint256 totalAdditionalRecipientsDataSize;
        assembly {
            totalAdditionalRecipientsDataSize :=
                shl(AdditionalRecipient_size_shift, calldataload(BasicOrder_additionalRecipients_length_cdPtr))
        }

        uint256 additionalRecipientAmount;
        address recipient;

        // Iterate over each additional recipient.
        for (uint256 i = 0; i < totalAdditionalRecipientsDataSize;) {
            assembly {
                // Retrieve calldata pointer for additional recipient.
                let additionalRecipientCdPtr := add(BasicOrder_additionalRecipients_data_cdPtr, i)

                additionalRecipientAmount := calldataload(additionalRecipientCdPtr)
                recipient := calldataload(add(OneWord, additionalRecipientCdPtr))
            }

            // Decrement the amount to transfer to fulfiller if indicated.
            if (fromOfferer) {
                amount -= additionalRecipientAmount;
            }

            // Transfer ERC20 tokens to additional recipient given approval.
            _transferERC20(token, from, recipient, additionalRecipientAmount, conduitKey, accumulator);

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                i += AdditionalRecipient_size;
            }
        }

        // Transfer ERC20 token amount (from account must have proper approval).
        _transferERC20(token, from, to, amount, conduitKey, accumulator);
    }
}
