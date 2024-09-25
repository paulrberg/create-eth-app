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
    FreeMemoryPointerSlot,
    OneWord,
    OneWordShift,
    ThirtyOneBytes
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

/**
 * @title TypehashDirectory
 * @notice The typehash directory contains 24 bulk order EIP-712 typehashes,
 *         depending on the height of the tree in each bulk order payload, as
 *         its runtime code (with an invalid opcode prefix so that the contract
 *         cannot be called normally). This runtime code is designed to be read
 *         from by Seaport using `extcodecopy` while verifying bulk signatures.
 */
contract TypehashDirectory {
    // Encodes "[2]" for use in deriving typehashes.
    bytes3 internal constant twoSubstring = 0x5B325D;
    uint256 internal constant twoSubstringLength = 0x3;

    // Dictates maximum bulk order group size; 24 => 2^24 => 16,777,216 orders.
    uint256 internal constant MaxTreeHeight = 0x18;

    uint256 internal constant InvalidOpcode = 0xfe;

    /**
     * @dev Derive 24 bulk order EIP-712 typehashes, one for each supported
     *      tree height from 1 to 24, and write them to runtime code.
     */
    constructor() {
        // Declare an array where each type hash will be written.
        bytes32[] memory typeHashes = new bytes32[](MaxTreeHeight);

        // Derive a string of 24 "[2]" substrings.
        bytes memory brackets = getMaxTreeBrackets(MaxTreeHeight);

        // Derive a string of subtypes for the order parameters.
        bytes memory subTypes = getTreeSubTypes();

        // Cache memory pointer before each loop so memory doesn't expand by the
        // full string size on each loop.
        uint256 freeMemoryPointer;
        assembly {
            freeMemoryPointer := mload(FreeMemoryPointerSlot)
        }

        // Iterate over each tree height.
        for (uint256 i = 0; i < MaxTreeHeight; ) {
            // The actual height is one greater than its respective index.
            uint256 height = i + 1;

            // Slice brackets length to size needed for `height`.
            assembly {
                mstore(brackets, mul(twoSubstringLength, height))
            }

            // Encode the type string for the BulkOrder struct.
            bytes memory bulkOrderTypeString = bytes.concat(
                "BulkOrder(OrderComponents",
                brackets,
                " tree)",
                subTypes
            );

            // Derive EIP712 type hash.
            bytes32 typeHash = keccak256(bulkOrderTypeString);
            typeHashes[i] = typeHash;

            // Reset the free memory pointer.
            assembly {
                mstore(FreeMemoryPointerSlot, freeMemoryPointer)
            }

            unchecked {
                ++i;
            }
        }

        assembly {
            // Overwrite length with zero to give the contract an INVALID prefix
            // and deploy the type hashes array as a contract.
            mstore(typeHashes, InvalidOpcode)

            return(
                add(typeHashes, ThirtyOneBytes),
                add(shl(OneWordShift, MaxTreeHeight), 1)
            )
        }
    }

    /**
     * @dev Internal pure function that returns a string of "[2]" substrings,
     *      with a number of substrings equal to the provided height.
     *
     * @param maxHeight The number of "[2]" substrings to include.
     *
     * @return A bytes array representing the string.
     */
    function getMaxTreeBrackets(
        uint256 maxHeight
    ) internal pure returns (bytes memory) {
        bytes memory suffixes = new bytes(twoSubstringLength * maxHeight);
        assembly {
            // Retrieve the pointer to the array head.
            let ptr := add(suffixes, OneWord)

            // Derive the terminal pointer.
            let endPtr := add(ptr, mul(maxHeight, twoSubstringLength))

            // Iterate over each pointer until terminal pointer is reached.
            for {

            } lt(ptr, endPtr) {
                ptr := add(ptr, twoSubstringLength)
            } {
                // Insert "[2]" substring directly at current pointer location.
                mstore(ptr, twoSubstring)
            }
        }

        // Return the fully populated array of substrings.
        return suffixes;
    }

    /**
     * @dev Internal pure function that returns a string of subtypes used in
     *      generating bulk order EIP-712 typehashes.
     *
     * @return A bytes array representing the string.
     */
    function getTreeSubTypes() internal pure returns (bytes memory) {
        // Construct the OfferItem type string.
        bytes memory offerItemTypeString = bytes(
            "OfferItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount"
            ")"
        );

        // Construct the ConsiderationItem type string.
        bytes memory considerationItemTypeString = bytes(
            "ConsiderationItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount,"
            "address recipient"
            ")"
        );

        // Construct the OrderComponents type string, not including the above.
        bytes memory orderComponentsPartialTypeString = bytes(
            "OrderComponents("
            "address offerer,"
            "address zone,"
            "OfferItem[] offer,"
            "ConsiderationItem[] consideration,"
            "uint8 orderType,"
            "uint256 startTime,"
            "uint256 endTime,"
            "bytes32 zoneHash,"
            "uint256 salt,"
            "bytes32 conduitKey,"
            "uint256 counter"
            ")"
        );

        // Return the combined string.
        return
            bytes.concat(
                considerationItemTypeString,
                offerItemTypeString,
                orderComponentsPartialTypeString
            );
    }
}
