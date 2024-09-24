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

import {
    BasicOrder_additionalRecipients_length_cdPtr,
    BasicOrder_common_params_size,
    BasicOrder_startTime_cdPtr,
    BasicOrder_startTimeThroughZoneHash_size,
    Common_amount_offset,
    Common_identifier_offset,
    Common_token_offset,
    generateOrder_base_tail_offset,
    generateOrder_context_head_offset,
    generateOrder_head_offset,
    generateOrder_maximumSpent_head_offset,
    generateOrder_minimumReceived_head_offset,
    generateOrder_selector_offset,
    generateOrder_selector,
    OneWord,
    OneWordShift,
    OnlyFullWordMask,
    OrderFulfilled_baseDataSize,
    OrderFulfilled_offer_length_baseOffset,
    OrderParameters_consideration_head_offset,
    OrderParameters_endTime_offset,
    OrderParameters_offer_head_offset,
    OrderParameters_startTime_offset,
    OrderParameters_zoneHash_offset,
    ratifyOrder_base_tail_offset,
    ratifyOrder_consideration_head_offset,
    ratifyOrder_context_head_offset,
    ratifyOrder_contractNonce_offset,
    ratifyOrder_head_offset,
    ratifyOrder_orderHashes_head_offset,
    ratifyOrder_selector_offset,
    ratifyOrder_selector,
    ReceivedItem_size,
    Selector_length,
    SixtyThreeBytes,
    SpentItem_size_shift,
    SpentItem_size,
    validateOrder_head_offset,
    validateOrder_selector_offset,
    validateOrder_selector,
    validateOrder_zoneParameters_offset,
    ZoneParameters_base_tail_offset,
    ZoneParameters_basicOrderFixedElements_length,
    ZoneParameters_consideration_head_offset,
    ZoneParameters_endTime_offset,
    ZoneParameters_extraData_head_offset,
    ZoneParameters_fulfiller_offset,
    ZoneParameters_offer_head_offset,
    ZoneParameters_offerer_offset,
    ZoneParameters_orderHashes_head_offset,
    ZoneParameters_selectorAndPointer_length,
    ZoneParameters_startTime_offset,
    ZoneParameters_zoneHash_offset
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

import {BasicOrderParameters, OrderParameters} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {CalldataPointer, getFreeMemoryPointer, MemoryPointer} from "OpenSea-Seaport/seaport-types/src/helpers/PointerLibraries.sol";

contract ConsiderationEncoder {
    /**
     * @dev Takes a bytes array and casts it to a memory pointer.
     *
     * @param obj A bytes array in memory.
     *
     * @return ptr A memory pointer to the start of the bytes array in memory.
     */
    function toMemoryPointer(bytes memory obj) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Takes an array of bytes32 types and casts it to a memory pointer.
     *
     * @param obj An array of bytes32 types in memory.
     *
     * @return ptr A memory pointer to the start of the array of bytes32 types
     *             in memory.
     */
    function toMemoryPointer(bytes32[] memory obj) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Takes a bytes array in memory and copies it to a new location in
     *      memory.
     *
     * @param src A memory pointer referencing the bytes array to be copied (and
     *            pointing to the length of the bytes array).
     * @param src A memory pointer referencing the location in memory to copy
     *            the bytes array to (and pointing to the length of the copied
     *            bytes array).
     *
     * @return size The size of the bytes array.
     */
    function _encodeBytes(MemoryPointer src, MemoryPointer dst) internal view returns (uint256 size) {
        unchecked {
            // Mask the length of the bytes array to protect against overflow
            // and round up to the nearest word.
            // Note: `size` also includes the 1 word that stores the length.
            size = (src.readUint256() + SixtyThreeBytes) & OnlyFullWordMask;

            // Copy the bytes array to the new memory location.
            src.copy(dst, size);
        }
    }

    /**
     * @dev Takes an OrderParameters struct and a context bytes array in memory
     *      and encodes it as `generateOrder` calldata.
     *
     * @param orderParameters The OrderParameters struct used to construct the
     *                        encoded `generateOrder` calldata.
     * @param context         The context bytes array used to construct the
     *                        encoded `generateOrder` calldata.
     *
     * @return dst  A memory pointer referencing the encoded `generateOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeGenerateOrder(OrderParameters memory orderParameters, bytes memory context)
        internal
        view
        returns (MemoryPointer dst, uint256 size)
    {
        // Get the memory pointer for the OrderParameters struct.
        MemoryPointer src = orderParameters.toMemoryPointer();

        // Get free memory pointer to write calldata to.
        dst = getFreeMemoryPointer();

        // Write generateOrder selector and get pointer to start of calldata.
        dst.write(generateOrder_selector);
        dst = dst.offset(generateOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(generateOrder_head_offset);

        // Write `fulfiller` to calldata.
        dstHead.write(msg.sender);

        // Initialize tail offset, used to populate the minimumReceived array.
        uint256 tailOffset = generateOrder_base_tail_offset;

        // Write offset to minimumReceived.
        dstHead.offset(generateOrder_minimumReceived_head_offset).write(tailOffset);

        // Get memory pointer to `orderParameters.offer.length`.
        MemoryPointer srcOfferPointer = src.offset(OrderParameters_offer_head_offset).readMemoryPointer();

        // Encode the offer array as a `SpentItem[]`.
        uint256 minimumReceivedSize = _encodeSpentItems(srcOfferPointer, dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate maximumSpent array.
            tailOffset += minimumReceivedSize;
        }

        // Write offset to maximumSpent.
        dstHead.offset(generateOrder_maximumSpent_head_offset).write(tailOffset);

        // Get memory pointer to `orderParameters.consideration.length`.
        MemoryPointer srcConsiderationPointer =
            src.offset(OrderParameters_consideration_head_offset).readMemoryPointer();

        // Encode the consideration array as a `SpentItem[]`.
        uint256 maximumSpentSize = _encodeSpentItems(srcConsiderationPointer, dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate context array.
            tailOffset += maximumSpentSize;
        }

        // Write offset to context.
        dstHead.offset(generateOrder_context_head_offset).write(tailOffset);

        // Get memory pointer to context.
        MemoryPointer srcContext = toMemoryPointer(context);

        // Encode context as a bytes array.
        uint256 contextSize = _encodeBytes(srcContext, dstHead.offset(tailOffset));

        unchecked {
            // Increment the tail offset, now used to determine final size.
            tailOffset += contextSize;

            // Derive the final size by including the selector.
            size = Selector_length + tailOffset;
        }
    }

    /**
     * @dev Takes an order hash (e.g. offerer shifted 96 bits to the left XOR'd
     *      with the contract nonce in the case of contract orders), an
     *      OrderParameters struct, context bytes array, and an array of order
     *      hashes for each order included as part of the current fulfillment
     *      and encodes it as `ratifyOrder` calldata.
     *
     * @param orderHash       The order hash (e.g. shl(0x60, offerer) ^ nonce).
     * @param orderParameters The OrderParameters struct used to construct the
     *                        encoded `ratifyOrder` calldata.
     * @param context         The context bytes array used to construct the
     *                        encoded `ratifyOrder` calldata.
     * @param orderHashes     An array of bytes32 values representing the order
     *                        hashes of all orders included as part of the
     *                        current fulfillment.
     * @param shiftedOfferer  The offerer for the order, shifted 96 bits to the
     *                        left.
     *
     * @return dst  A memory pointer referencing the encoded `ratifyOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeRatifyOrder(
        bytes32 orderHash, // e.g. shl(0x60, offerer) ^ contract nonce
        OrderParameters memory orderParameters,
        bytes memory context, // encoded based on the schemaID
        bytes32[] memory orderHashes,
        uint256 shiftedOfferer
    ) internal view returns (MemoryPointer dst, uint256 size) {
        // Get free memory pointer to write calldata to. This isn't allocated as
        // it is only used for a single function call.
        dst = getFreeMemoryPointer();

        // Write ratifyOrder selector and get pointer to start of calldata.
        dst.write(ratifyOrder_selector);
        dst = dst.offset(ratifyOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(ratifyOrder_head_offset);

        // Write contractNonce to calldata via xor(orderHash, shiftedOfferer).
        dstHead.offset(ratifyOrder_contractNonce_offset).write(uint256(orderHash) ^ shiftedOfferer);

        // Initialize tail offset, used to populate the offer array.
        uint256 tailOffset = ratifyOrder_base_tail_offset;
        MemoryPointer src = orderParameters.toMemoryPointer();

        // Write offset to `offer`.
        dstHead.write(tailOffset);

        // Get memory pointer to `orderParameters.offer.length`.
        MemoryPointer srcOfferPointer = src.offset(OrderParameters_offer_head_offset).readMemoryPointer();

        // Encode the offer array as a `SpentItem[]`.
        uint256 offerSize = _encodeSpentItems(srcOfferPointer, dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate consideration array.
            tailOffset += offerSize;
        }

        // Write offset to consideration.
        dstHead.offset(ratifyOrder_consideration_head_offset).write(tailOffset);

        // Get pointer to `orderParameters.consideration.length`.
        MemoryPointer srcConsiderationPointer =
            src.offset(OrderParameters_consideration_head_offset).readMemoryPointer();

        // Encode the consideration array as a `ReceivedItem[]`.
        uint256 considerationSize =
            _encodeConsiderationAsReceivedItems(srcConsiderationPointer, dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate context array.
            tailOffset += considerationSize;
        }

        // Write offset to context.
        dstHead.offset(ratifyOrder_context_head_offset).write(tailOffset);

        // Encode context.
        uint256 contextSize = _encodeBytes(toMemoryPointer(context), dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate orderHashes array.
            tailOffset += contextSize;
        }

        // Write offset to orderHashes.
        dstHead.offset(ratifyOrder_orderHashes_head_offset).write(tailOffset);

        // Encode orderHashes.
        uint256 orderHashesSize = _encodeOrderHashes(toMemoryPointer(orderHashes), dstHead.offset(tailOffset));

        unchecked {
            // Increment the tail offset, now used to determine final size.
            tailOffset += orderHashesSize;

            // Derive the final size by including the selector.
            size = Selector_length + tailOffset;
        }
    }

    /**
     * @dev Takes an order hash, OrderParameters struct, extraData bytes array,
     *      and array of order hashes for each order included as part of the
     *      current fulfillment and encodes it as `validateOrder` calldata.
     *      Note that future, new versions of this contract may end up writing
     *      to a memory region that might have been potentially dirtied by the
     *      accumulator. Since the book-keeping for the accumulator does not
     *      update the free memory pointer, it will be necessary to ensure that
     *      all bytes in the memory in the range [dst, dst+size) are fully
     *      updated/written to in this function.
     *
     * @param orderHash       The order hash.
     * @param orderParameters The OrderParameters struct used to construct the
     *                        encoded `validateOrder` calldata.
     * @param extraData       The extraData bytes array used to construct the
     *                        encoded `validateOrder` calldata.
     * @param orderHashes     An array of bytes32 values representing the order
     *                        hashes of all orders included as part of the
     *                        current fulfillment.
     *
     * @return dst  A memory pointer referencing the encoded `validateOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeValidateOrder(
        bytes32 orderHash,
        OrderParameters memory orderParameters,
        bytes memory extraData,
        bytes32[] memory orderHashes
    ) internal view returns (MemoryPointer dst, uint256 size) {
        // Get free memory pointer to write calldata to. This isn't allocated as
        // it is only used for a single function call.
        dst = getFreeMemoryPointer();

        // Write validateOrder selector and get pointer to start of calldata.
        dst.write(validateOrder_selector);
        dst = dst.offset(validateOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(validateOrder_head_offset);

        // Write offset to zoneParameters to start of calldata.
        dstHead.write(validateOrder_zoneParameters_offset);

        // Reuse `dstHead` as pointer to zoneParameters.
        dstHead = dstHead.offset(validateOrder_zoneParameters_offset);

        // Write orderHash and fulfiller to zoneParameters.
        dstHead.writeBytes32(orderHash);
        dstHead.offset(ZoneParameters_fulfiller_offset).write(msg.sender);

        // Get the memory pointer to the order parameters struct.
        MemoryPointer src = orderParameters.toMemoryPointer();

        // Copy offerer, startTime, endTime and zoneHash to zoneParameters.
        dstHead.offset(ZoneParameters_offerer_offset).write(src.readUint256());
        dstHead.offset(ZoneParameters_startTime_offset).write(
            src.offset(OrderParameters_startTime_offset).readUint256()
        );
        dstHead.offset(ZoneParameters_endTime_offset).write(src.offset(OrderParameters_endTime_offset).readUint256());
        dstHead.offset(ZoneParameters_zoneHash_offset).write(src.offset(OrderParameters_zoneHash_offset).readUint256());

        // Initialize tail offset, used to populate the offer array.
        uint256 tailOffset = ZoneParameters_base_tail_offset;

        // Write offset to `offer`.
        dstHead.offset(ZoneParameters_offer_head_offset).write(tailOffset);

        // Get pointer to `orderParameters.offer.length`.
        MemoryPointer srcOfferPointer = src.offset(OrderParameters_offer_head_offset).readMemoryPointer();

        // Encode the offer array as a `SpentItem[]`.
        uint256 offerSize = _encodeSpentItems(srcOfferPointer, dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate consideration array.
            tailOffset += offerSize;
        }

        // Write offset to consideration.
        dstHead.offset(ZoneParameters_consideration_head_offset).write(tailOffset);

        // Get pointer to `orderParameters.consideration.length`.
        MemoryPointer srcConsiderationPointer =
            src.offset(OrderParameters_consideration_head_offset).readMemoryPointer();

        // Encode the consideration array as a `ReceivedItem[]`.
        uint256 considerationSize =
            _encodeConsiderationAsReceivedItems(srcConsiderationPointer, dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate extraData array.
            tailOffset += considerationSize;
        }

        // Write offset to extraData.
        dstHead.offset(ZoneParameters_extraData_head_offset).write(tailOffset);
        // Copy extraData.
        uint256 extraDataSize = _encodeBytes(toMemoryPointer(extraData), dstHead.offset(tailOffset));

        unchecked {
            // Increment tail offset, now used to populate orderHashes array.
            tailOffset += extraDataSize;
        }

        // Write offset to orderHashes.
        dstHead.offset(ZoneParameters_orderHashes_head_offset).write(tailOffset);

        // Encode the order hashes array.
        uint256 orderHashesSize = _encodeOrderHashes(toMemoryPointer(orderHashes), dstHead.offset(tailOffset));

        unchecked {
            // Increment the tail offset, now used to determine final size.
            tailOffset += orderHashesSize;

            // Derive final size including selector and ZoneParameters pointer.
            size = ZoneParameters_selectorAndPointer_length + tailOffset;
        }
    }

    /**
     * @dev Takes an order hash and BasicOrderParameters struct (from calldata)
     *      and encodes it as `validateOrder` calldata.
     *
     * @param orderHash  The order hash.
     * @param parameters The BasicOrderParameters struct used to construct the
     *                   encoded `validateOrder` calldata.
     *
     * @return dst  A memory pointer referencing the encoded `validateOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeValidateBasicOrder(bytes32 orderHash, BasicOrderParameters calldata parameters)
        internal
        view
        returns (MemoryPointer dst, uint256 size)
    {
        // Get free memory pointer to write calldata to. This isn't allocated as
        // it is only used for a single function call.
        dst = getFreeMemoryPointer();

        // Write validateOrder selector and get pointer to start of calldata.
        dst.write(validateOrder_selector);
        dst = dst.offset(validateOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(validateOrder_head_offset);

        // Write offset to zoneParameters to start of calldata.
        dstHead.write(validateOrder_zoneParameters_offset);

        // Reuse `dstHead` as pointer to zoneParameters.
        dstHead = dstHead.offset(validateOrder_zoneParameters_offset);

        // Write offerer, orderHash and fulfiller to zoneParameters.
        dstHead.writeBytes32(orderHash);
        dstHead.offset(ZoneParameters_fulfiller_offset).write(msg.sender);
        dstHead.offset(ZoneParameters_offerer_offset).write(parameters.offerer);

        // Copy startTime, endTime and zoneHash to zoneParameters.
        CalldataPointer.wrap(BasicOrder_startTime_cdPtr).copy(
            dstHead.offset(ZoneParameters_startTime_offset), BasicOrder_startTimeThroughZoneHash_size
        );

        // Initialize tail offset, used for the offer + consideration arrays.
        uint256 tailOffset = ZoneParameters_base_tail_offset;

        // Write offset to offer from event data into target calldata.
        dstHead.offset(ZoneParameters_offer_head_offset).write(tailOffset);

        unchecked {
            // Write consideration offset next (located 5 words after offer).
            dstHead.offset(ZoneParameters_consideration_head_offset).write(tailOffset + BasicOrder_common_params_size);

            // Retrieve the offset to the length of additional recipients.
            uint256 additionalRecipientsLength =
                CalldataPointer.wrap(BasicOrder_additionalRecipients_length_cdPtr).readUint256();

            // Derive offset to event data using base offset & total recipients.
            uint256 offerDataOffset = OrderFulfilled_offer_length_baseOffset + additionalRecipientsLength * OneWord;

            // Derive size of offer and consideration data.
            // 2 words (lengths) + 4 (offer data) + 5 (consideration 1) + 5 * ar
            uint256 offerAndConsiderationSize =
                OrderFulfilled_baseDataSize + (additionalRecipientsLength * ReceivedItem_size);

            // Copy offer and consideration data from event data to calldata.
            MemoryPointer.wrap(offerDataOffset).copy(dstHead.offset(tailOffset), offerAndConsiderationSize);

            // Increment tail offset, now used to populate extraData array.
            tailOffset += offerAndConsiderationSize;
        }

        // Write empty bytes for extraData.
        dstHead.offset(ZoneParameters_extraData_head_offset).write(tailOffset);
        dstHead.offset(tailOffset).write(0);

        unchecked {
            // Increment tail offset, now used to populate orderHashes array.
            tailOffset += OneWord;
        }

        // Write offset to orderHashes.
        dstHead.offset(ZoneParameters_orderHashes_head_offset).write(tailOffset);

        // Write length = 1 to the orderHashes array.
        dstHead.offset(tailOffset).write(1);

        unchecked {
            // Write the single order hash to the orderHashes array.
            dstHead.offset(tailOffset + OneWord).writeBytes32(orderHash);

            // Final size: selector, ZoneParameters pointer, orderHashes & tail.
            size = ZoneParameters_basicOrderFixedElements_length + tailOffset;
        }
    }

    /**
     * @dev Takes a memory pointer to an array of bytes32 values representing
     *      the order hashes included as part of the fulfillment and a memory
     *      pointer to a location to copy it to, and copies the source data to
     *      the destination in memory.
     *
     * @param srcLength A memory pointer referencing the order hashes array to
     *                  be copied (and pointing to the length of the array).
     * @param dstLength A memory pointer referencing the location in memory to
     *                  copy the orderHashes array to (and pointing to the
     *                  length of the copied array).
     *
     * @return size The size of the order hashes array (including the length).
     */
    function _encodeOrderHashes(MemoryPointer srcLength, MemoryPointer dstLength)
        internal
        view
        returns (uint256 size)
    {
        // Read length of the array from source and write to destination.
        uint256 length = srcLength.readUint256();
        dstLength.write(length);

        unchecked {
            // Determine head & tail size as one word per element in the array.
            uint256 headAndTailSize = length << OneWordShift;

            // Copy the tail starting from the next element of the source to the
            // next element of the destination.
            srcLength.next().copy(dstLength.next(), headAndTailSize);

            // Set size to the length of the tail plus one word for length.
            size = headAndTailSize + OneWord;
        }
    }

    /**
     * @dev Takes a memory pointer to an offer or consideration array and a
     *      memory pointer to a location to copy it to, and copies the source
     *      data to the destination in memory as a SpentItem array.
     *
     * @param srcLength A memory pointer referencing the offer or consideration
     *                  array to be copied as a SpentItem array (and pointing to
     *                  the length of the original array).
     * @param dstLength A memory pointer referencing the location in memory to
     *                  copy the offer array to (and pointing to the length of
     *                  the copied array).
     *
     * @return size The size of the SpentItem array (including the length).
     */
    function _encodeSpentItems(MemoryPointer srcLength, MemoryPointer dstLength) internal pure returns (uint256 size) {
        assembly {
            // Read length of the array from source and write to destination.
            let length := mload(srcLength)
            mstore(dstLength, length)

            // Get pointer to first item's head position in the array,
            // containing the item's pointer in memory. The head pointer will be
            // incremented until it reaches the tail position (start of the
            // array data).
            let mPtrHead := add(srcLength, OneWord)

            // Position in memory to write next item for calldata. Since
            // SpentItem has a fixed length, the array elements do not contain
            // head elements in calldata, they are concatenated together after
            // the array length.
            let cdPtrData := add(dstLength, OneWord)

            // Pointer to end of array head in memory.
            let mPtrHeadEnd := add(mPtrHead, shl(OneWordShift, length))

            for {} lt(mPtrHead, mPtrHeadEnd) {} {
                // Read pointer to data for array element from head position.
                let mPtrTail := mload(mPtrHead)

                // Copy itemType, token, identifier, amount to calldata.
                mstore(cdPtrData, mload(mPtrTail))
                mstore(add(cdPtrData, Common_token_offset), mload(add(mPtrTail, Common_token_offset)))
                mstore(add(cdPtrData, Common_identifier_offset), mload(add(mPtrTail, Common_identifier_offset)))
                mstore(add(cdPtrData, Common_amount_offset), mload(add(mPtrTail, Common_amount_offset)))

                mPtrHead := add(mPtrHead, OneWord)
                cdPtrData := add(cdPtrData, SpentItem_size)
            }

            size := add(OneWord, shl(SpentItem_size_shift, length))
        }
    }

    /**
     * @dev Takes a memory pointer to an consideration array and a memory
     *      pointer to a location to copy it to, and copies the source data to
     *      the destination in memory as a ReceivedItem array.
     *
     * @param srcLength A memory pointer referencing the consideration array to
     *                  be copied as a ReceivedItem array (and pointing to the
     *                  length of the original array).
     * @param dstLength A memory pointer referencing the location in memory to
     *                  copy the consideration array to as a ReceivedItem array
     *                  (and pointing to the length of the new array).
     *
     * @return size The size of the ReceivedItem array (including the length).
     */
    function _encodeConsiderationAsReceivedItems(MemoryPointer srcLength, MemoryPointer dstLength)
        internal
        view
        returns (uint256 size)
    {
        unchecked {
            // Read length of the array from source and write to destination.
            uint256 length = srcLength.readUint256();
            dstLength.write(length);

            // Get pointer to first item's head position in the array,
            // containing the item's pointer in memory. The head pointer will be
            // incremented until it reaches the tail position (start of the
            // array data).
            MemoryPointer srcHead = srcLength.next();
            MemoryPointer srcHeadEnd = srcHead.offset(length << OneWordShift);

            // Position in memory to write next item for calldata. Since
            // ReceivedItem has a fixed length, the array elements do not
            // contain offsets in calldata, they are concatenated together after
            // the array length.
            MemoryPointer dstHead = dstLength.next();
            while (srcHead.lt(srcHeadEnd)) {
                MemoryPointer srcTail = srcHead.pptr();
                srcTail.copy(dstHead, ReceivedItem_size);
                srcHead = srcHead.next();
                dstHead = dstHead.offset(ReceivedItem_size);
            }

            size = OneWord + (length * ReceivedItem_size);
        }
    }
}
