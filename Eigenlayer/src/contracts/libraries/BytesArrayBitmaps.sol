/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Eigenlayer?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.12;

/**
 * @title Library for converting between an array of bytes and a bitmap.
 * @author Layr Labs, Inc.
 */
library BytesArrayBitmaps {
    /**
     * @notice Byte arrays are meant to contain unique bytes.
     * If the array length exceeds 256, then it's impossible for all entries to be unique.
     * This constant captures the max allowed array length (inclusive, i.e. 256 is allowed).
     */
    uint256 constant MAX_BYTE_ARRAY_LENGTH = 256;

    /**
     * @notice Converts an array of bytes into a bitmap.
     * @param bytesArray The array of bytes to convert/compress into a bitmap.
     * @return The resulting bitmap.
     * @dev Each byte in the input is processed as indicating a single bit to flip in the bitmap
     * @dev This function will also revert if the `bytesArray` input contains any duplicate entries (i.e. duplicate bytes).
     */
    function bytesArrayToBitmap(bytes calldata bytesArray) internal pure returns (uint256) {
        // sanity-check on input. a too-long input would fail later on due to having duplicate entry(s)
        require(bytesArray.length <= MAX_BYTE_ARRAY_LENGTH,
            "BytesArrayBitmaps.bytesArrayToBitmap: bytesArray is too long");

        // return empty bitmap early if length of array is 0
        if (bytesArray.length == 0) {
            return uint256(0);
        }

        // initialize the empty bitmap, to be built inside the loop
        uint256 bitmap;
        // initialize an empty uint256 to be used as a bitmask inside the loop
        uint256 bitMask;

        // perform the 0-th loop iteration with the ordering check *omitted* (since it is unnecessary / will always pass)
        // construct a single-bit mask from the numerical value of the 0th byte of the array, and immediately add it to the bitmap
        bitmap = uint256(1 << uint8(bytesArray[0]));

        // loop through each byte in the array to construct the bitmap
        for (uint256 i = 1; i < bytesArray.length; ++i) {
            // construct a single-bit mask from the numerical value of the next byte out of the array
            bitMask = uint256(1 << uint8(bytesArray[i]));
            // check that the entry is not a repeat
            require(bitmap & bitMask == 0, "BytesArrayBitmaps.bytesArrayToBitmap: repeat entry in bytesArray");
            // add the entry to the bitmap
            bitmap = (bitmap | bitMask);
        }
        return bitmap;
    }

    /**
     * @notice Converts an ordered array of bytes into a bitmap.
     * @param orderedBytesArray The array of bytes to convert/compress into a bitmap. Must be in strictly ascending order.
     * @return The resulting bitmap.
     * @dev Each byte in the input is processed as indicating a single bit to flip in the bitmap.
     * @dev This function will eventually revert in the event that the `orderedBytesArray` is not properly ordered (in ascending order).
     * @dev This function will also revert if the `orderedBytesArray` input contains any duplicate entries (i.e. duplicate bytes).
     */
    function orderedBytesArrayToBitmap(bytes calldata orderedBytesArray) internal pure returns (uint256) {
        // sanity-check on input. a too-long input would fail later on due to having duplicate entry(s)
        require(orderedBytesArray.length <= MAX_BYTE_ARRAY_LENGTH,
            "BytesArrayBitmaps.orderedBytesArrayToBitmap: orderedBytesArray is too long");

        // return empty bitmap early if length of array is 0
        if (orderedBytesArray.length == 0) {
            return uint256(0);
        }

        // initialize the empty bitmap, to be built inside the loop
        uint256 bitmap;
        // initialize an empty uint256 to be used as a bitmask inside the loop
        uint256 bitMask;

        // perform the 0-th loop iteration with the ordering check *omitted* (since it is unnecessary / will always pass)
        // construct a single-bit mask from the numerical value of the 0th byte of the array, and immediately add it to the bitmap
        bitmap = uint256(1 << uint8(orderedBytesArray[0]));

        // loop through each byte in the array to construct the bitmap
        for (uint256 i = 1; i < orderedBytesArray.length; ++i) {
            // construct a single-bit mask from the numerical value of the next byte of the array
            bitMask = uint256(1 << uint8(orderedBytesArray[i]));
            // check strictly ascending array ordering by comparing the mask to the bitmap so far (revert if mask isn't greater than bitmap)
            require(bitMask > bitmap, "BytesArrayBitmaps.orderedBytesArrayToBitmap: orderedBytesArray is not ordered");
            // add the entry to the bitmap
            bitmap = (bitmap | bitMask);
        }
        return bitmap;
    }

    /**
     * @notice Converts an ordered array of bytes into a bitmap. Optimized, Yul-heavy version of `orderedBytesArrayToBitmap`.
     * @param orderedBytesArray The array of bytes to convert/compress into a bitmap. Must be in strictly ascending order.
     * @return The resulting bitmap.
     * @dev Each byte in the input is processed as indicating a single bit to flip in the bitmap.
     * @dev This function will eventually revert in the event that the `orderedBytesArray` is not properly ordered (in ascending order).
     * @dev This function will also revert if the `orderedBytesArray` input contains any duplicate entries (i.e. duplicate bytes).
     */
    function orderedBytesArrayToBitmap_Yul(bytes calldata orderedBytesArray) internal pure returns (uint256) {
        // sanity-check on input. a too-long input would fail later on due to having duplicate entry(s)
        require(orderedBytesArray.length <= MAX_BYTE_ARRAY_LENGTH,
            "BytesArrayBitmaps.orderedBytesArrayToBitmap: orderedBytesArray is too long");

        // return empty bitmap early if length of array is 0
        if (orderedBytesArray.length == 0) {
            return uint256(0);
        }

        assembly {
            // get first entry in bitmap (single byte => single-bit mask)
            let bitmap :=
                shl(
                    // extract single byte to get the correct value for the left shift
                    shr(
                        248,
                        calldataload(
                            orderedBytesArray.offset
                        )
                    ),
                    1
                )
            // loop through other entries (byte by byte)
            for { let i := 1 } lt(i, orderedBytesArray.length) { i := add(i, 1) } {
                // first construct the single-bit mask by left-shifting a '1'
                let bitMask := 
                    shl(
                        // extract single byte to get the correct value for the left shift
                        shr(
                            248,
                            calldataload(
                                add(
                                    orderedBytesArray.offset,
                                    i
                                )
                            )
                        ),
                        1
                    )
                // check strictly ascending ordering by comparing the mask to the bitmap so far (revert if mask isn't greater than bitmap)
                // TODO: revert with a good message instead of using `revert(0, 0)`
                // REFERENCE: require(bitMask > bitmap, "BytesArrayBitmaps.orderedBytesArrayToBitmap: orderedBytesArray is not ordered");
                if iszero(gt(bitMask, bitmap)) { revert(0, 0) }
                // update the bitmap by adding the single bit in the mask
                bitmap := or(bitmap, bitMask)
            }
            // after the loop is complete, store the bitmap at the value encoded at the free memory pointer, then return it
            mstore(mload(0x40), bitmap)
            return(mload(0x40), 32)
        }
    }

    /**
     * @notice Converts an array of bytes into a bitmap. Optimized, Yul-heavy version of `bytesArrayToBitmap`.
     * @param bytesArray The array of bytes to convert/compress into a bitmap.
     * @return The resulting bitmap.
     * @dev Each byte in the input is processed as indicating a single bit to flip in the bitmap.
     * @dev This function will eventually revert in the event that the `bytesArray` is not properly ordered (in ascending order).
     * @dev This function will also revert if the `bytesArray` input contains any duplicate entries (i.e. duplicate bytes).
     */
    function bytesArrayToBitmap_Yul(bytes calldata bytesArray) internal pure returns (uint256) {
        // sanity-check on input. a too-long input would fail later on due to having duplicate entry(s)
        require(bytesArray.length <= MAX_BYTE_ARRAY_LENGTH,
            "BytesArrayBitmaps.bytesArrayToBitmap: bytesArray is too long");

        // return empty bitmap early if length of array is 0
        if (bytesArray.length == 0) {
            return uint256(0);
        }

        assembly {
            // get first entry in bitmap (single byte => single-bit mask)
            let bitmap :=
                shl(
                    // extract single byte to get the correct value for the left shift
                    shr(
                        248,
                        calldataload(
                            bytesArray.offset
                        )
                    ),
                    1
                )
            // loop through other entries (byte by byte)
            for { let i := 1 } lt(i, bytesArray.length) { i := add(i, 1) } {
                // first construct the single-bit mask by left-shifting a '1'
                let bitMask := 
                    shl(
                        // extract single byte to get the correct value for the left shift
                        shr(
                            248,
                            calldataload(
                                add(
                                    bytesArray.offset,
                                    i
                                )
                            )
                        ),
                        1
                    )
                // check against duplicates by comparing the bitmask and bitmap (revert if the bitmap already contains the entry, i.e. bitmap & bitMask != 0)
                // TODO: revert with a good message instead of using `revert(0, 0)`
                // REFERENCE: require(bitmap & bitMask == 0, "BytesArrayBitmaps.bytesArrayToBitmap: repeat entry in bytesArray");
                if gt(and(bitmap, bitMask), 0) { revert(0, 0) }
                // update the bitmap by adding the single bit in the mask
                bitmap := or(bitmap, bitMask)
            }
            // after the loop is complete, store the bitmap at the value encoded at the free memory pointer, then return it
            mstore(mload(0x40), bitmap)
            return(mload(0x40), 32)
        }
    }

    /**
     * @notice Utility function for checking if a bytes array is strictly ordered, in ascending order.
     * @param bytesArray the bytes array of interest
     * @return Returns 'true' if the array is ordered in strictly ascending order, and 'false' otherwise.
     * @dev This function returns 'true' for the edge case of the `bytesArray` having zero length.
     * It also returns 'false' early for arrays with length in excess of MAX_BYTE_ARRAY_LENGTH (i.e. so long that they cannot be strictly ordered)
     */
    function isArrayStrictlyAscendingOrdered(bytes calldata bytesArray) internal pure returns (bool) {
        // return 'false' early for too-long (i.e. unorderable) arrays
        if (bytesArray.length > MAX_BYTE_ARRAY_LENGTH) {
            return false;
        }

        // return 'true' early if length of array is 0
        if (bytesArray.length == 0) {
            return true;
        }

        // initialize an empty byte object, to be re-used inside the loop
        bytes1 singleByte;

        // perform the 0-th loop iteration with the ordering check *omitted* (otherwise it will break with an out-of-bounds error)
        // pull the 0th byte out of the array
        singleByte = bytesArray[0];

        // loop through each byte in the array to construct the bitmap
        for (uint256 i = 1; i < bytesArray.length; ++i) {
            // check if the entry is *less than or equal to* the previous entry. if it is, then the array isn't strictly ordered!
            if (uint256(uint8(bytesArray[i])) <= uint256(uint8(singleByte))) {
                return false;
            }
            // pull the next byte out of the array
            singleByte = bytesArray[i];
        }
        return true;
    }

    /**
     * @notice Converts a bitmap into an array of bytes.
     * @param bitmap The bitmap to decompress/convert to an array of bytes.
     * @return bytesArray The resulting bitmap array of bytes.
     * @dev Each byte in the input is processed as indicating a single bit to flip in the bitmap
     */
    function bitmapToBytesArray(uint256 bitmap) internal pure returns (bytes memory bytesArray) {
        // initialize an empty uint256 to be used as a bitmask inside the loop
        uint256 bitMask;
        // loop through each index in the bitmap to construct the array
        for (uint256 i = 0; i < 256; ++i) {
            // construct a single-bit mask for the i-th bit
            bitMask = uint256(1 << i);
            // check if the i-th bit is flipped in the bitmap
            if (bitmap & bitMask != 0) {
                // if the i-th bit is flipped, then add a byte encoding the value 'i' to the `bytesArray`
                bytesArray = bytes.concat(bytesArray, bytes1(uint8(i)));
            }
        }
        return bytesArray;
    }
}
