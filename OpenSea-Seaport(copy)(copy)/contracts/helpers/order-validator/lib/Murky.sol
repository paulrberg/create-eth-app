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
pragma solidity ^0.8.10;

import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./ErrorsAndWarnings.sol";

import { IssueParser, MerkleIssue } from "./SeaportValidatorTypes.sol";

contract Murky {
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using IssueParser for MerkleIssue;

    bool internal constant HASH_ODD_WITH_ZERO = false;

    function _verifyProof(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 valueToProve
    ) internal pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = valueToProve;
        uint256 length = proof.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                rollingHash = _hashLeafPairs(rollingHash, proof[i]);
            }
        }
        return root == rollingHash;
    }

    /********************
     * HASHING FUNCTION *
     ********************/

    /// ascending sort and concat prior to hashing
    function _hashLeafPairs(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 _hash)
    {
        assembly {
            switch lt(left, right)
            case 0 {
                mstore(0x0, right)
                mstore(0x20, left)
            }
            default {
                mstore(0x0, left)
                mstore(0x20, right)
            }
            _hash := keccak256(0x0, 0x40)
        }
    }

    /********************
     * PROOF GENERATION *
     ********************/

    function _getRoot(uint256[] memory data)
        internal
        pure
        returns (bytes32 result, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (data.length < 2) {
            errorsAndWarnings.addError(MerkleIssue.SingleLeaf.parseInt());
            return (0, errorsAndWarnings);
        }

        bool hashOddWithZero = HASH_ODD_WITH_ZERO;

        if (!_processInput(data)) {
            errorsAndWarnings.addError(MerkleIssue.Unsorted.parseInt());
            return (0, errorsAndWarnings);
        }

        assembly {
            function hashLeafPairs(left, right) -> _hash {
                switch lt(left, right)
                case 0 {
                    mstore(0x0, right)
                    mstore(0x20, left)
                }
                default {
                    mstore(0x0, left)
                    mstore(0x20, right)
                }
                _hash := keccak256(0x0, 0x40)
            }
            function hashLevel(_data, length, _hashOddWithZero) -> newLength {
                // we will be modifying data in-place, so set result pointer to data pointer
                let _result := _data
                // get length of original data array
                // let length := mload(_data)
                // bool to track if we need to hash the last element of an odd-length array with zero
                let oddLength

                // if length is odd, we need to hash the last element with zero
                switch and(length, 1)
                case 1 {
                    // if length is odd, add 1 so division by 2 will round up
                    newLength := add(1, div(length, 2))
                    oddLength := 1
                }
                default {
                    newLength := div(length, 2)
                }
                // todo: necessary?
                // mstore(_data, newLength)
                let resultIndexPointer := add(0x20, _data)
                let dataIndexPointer := resultIndexPointer

                // stop iterating over for loop at length-1
                let stopIteration := add(_data, mul(length, 0x20))
                // write result array in-place over data array
                for {

                } lt(dataIndexPointer, stopIteration) {

                } {
                    // get next two elements from data, hash them together
                    let data1 := mload(dataIndexPointer)
                    let data2 := mload(add(dataIndexPointer, 0x20))
                    let hashedPair := hashLeafPairs(data1, data2)
                    // overwrite an element of data array with
                    mstore(resultIndexPointer, hashedPair)
                    // increment result pointer by 1 slot
                    resultIndexPointer := add(0x20, resultIndexPointer)
                    // increment data pointer by 2 slot
                    dataIndexPointer := add(0x40, dataIndexPointer)
                }
                // we did not yet hash last index if odd-length
                if oddLength {
                    let data1 := mload(dataIndexPointer)
                    let nextValue
                    switch _hashOddWithZero
                    case 0 {
                        nextValue := data1
                    }
                    default {
                        nextValue := hashLeafPairs(data1, 0)
                    }
                    mstore(resultIndexPointer, nextValue)
                }
            }

            let dataLength := mload(data)
            for {

            } gt(dataLength, 1) {

            } {
                dataLength := hashLevel(data, dataLength, hashOddWithZero)
            }
            result := mload(add(0x20, data))
        }
    }

    function _getProof(uint256[] memory data, uint256 node)
        internal
        pure
        returns (
            bytes32[] memory result,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (data.length < 2) {
            errorsAndWarnings.addError(MerkleIssue.SingleLeaf.parseInt());
            return (new bytes32[](0), errorsAndWarnings);
        }

        bool hashOddWithZero = HASH_ODD_WITH_ZERO;

        if (!_processInput(data)) {
            errorsAndWarnings.addError(MerkleIssue.Unsorted.parseInt());
            return (new bytes32[](0), errorsAndWarnings);
        }

        // The size of the proof is equal to the ceiling of log2(numLeaves)
        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        assembly {
            function hashLeafPairs(left, right) -> _hash {
                switch lt(left, right)
                case 0 {
                    mstore(0x0, right)
                    mstore(0x20, left)
                }
                default {
                    mstore(0x0, left)
                    mstore(0x20, right)
                }
                _hash := keccak256(0x0, 0x40)
            }
            function hashLevel(_data, length, _hashOddWithZero) -> newLength {
                // we will be modifying data in-place, so set result pointer to data pointer
                let _result := _data
                // get length of original data array
                // let length := mload(_data)
                // bool to track if we need to hash the last element of an odd-length array with zero
                let oddLength

                // if length is odd, we'll need to hash the last element with zero
                switch and(length, 1)
                case 1 {
                    // if length is odd, add 1 so division by 2 will round up
                    newLength := add(1, div(length, 2))
                    oddLength := 1
                }
                default {
                    newLength := div(length, 2)
                }
                // todo: necessary?
                // mstore(_data, newLength)
                let resultIndexPointer := add(0x20, _data)
                let dataIndexPointer := resultIndexPointer

                // stop iterating over for loop at length-1
                let stopIteration := add(_data, mul(length, 0x20))
                // write result array in-place over data array
                for {

                } lt(dataIndexPointer, stopIteration) {

                } {
                    // get next two elements from data, hash them together
                    let data1 := mload(dataIndexPointer)
                    let data2 := mload(add(dataIndexPointer, 0x20))
                    let hashedPair := hashLeafPairs(data1, data2)
                    // overwrite an element of data array with
                    mstore(resultIndexPointer, hashedPair)
                    // increment result pointer by 1 slot
                    resultIndexPointer := add(0x20, resultIndexPointer)
                    // increment data pointer by 2 slot
                    dataIndexPointer := add(0x40, dataIndexPointer)
                }
                // we did not yet hash last index if odd-length
                if oddLength {
                    let data1 := mload(dataIndexPointer)
                    let nextValue
                    switch _hashOddWithZero
                    case 0 {
                        nextValue := data1
                    }
                    default {
                        nextValue := hashLeafPairs(data1, 0)
                    }
                    mstore(resultIndexPointer, nextValue)
                }
            }

            // set result pointer to free memory
            result := mload(0x40)
            // get pointer to first index of result
            let resultIndexPtr := add(0x20, result)
            // declare so we can use later
            let newLength
            // put length of data onto stack
            let dataLength := mload(data)
            for {
                // repeat until only one element is left
            } gt(dataLength, 1) {

            } {
                // bool if node is odd
                let oddNodeIndex := and(node, 1)
                // bool if node is last
                let lastNodeIndex := eq(dataLength, add(1, node))
                // store both bools in one value so we can switch on it
                let switchVal := or(shl(1, lastNodeIndex), oddNodeIndex)
                switch switchVal
                // 00 - neither odd nor last
                case 0 {
                    // store data[node+1] at result[i]
                    // get pointer to result[node+1] by adding 2 to node and multiplying by 0x20
                    // to account for the fact that result points to array length, not first index
                    mstore(
                        resultIndexPtr,
                        mload(add(data, mul(0x20, add(2, node))))
                    )
                }
                // 10 - node is last
                case 2 {
                    // store 0 at result[i]
                    mstore(resultIndexPtr, 0)
                }
                // 01 or 11 - node is odd (and possibly also last)
                default {
                    // store data[node-1] at result[i]
                    mstore(resultIndexPtr, mload(add(data, mul(0x20, node))))
                }
                // increment result index
                resultIndexPtr := add(0x20, resultIndexPtr)

                // get new node index
                node := div(node, 2)
                // keep track of how long result array is
                newLength := add(1, newLength)
                // compute the next hash level, overwriting data, and get the new length
                dataLength := hashLevel(data, dataLength, hashOddWithZero)
            }
            // store length of result array at pointer
            mstore(result, newLength)
            // set free mem pointer to word after end of result array
            mstore(0x40, resultIndexPtr)
        }
    }

    /**
     * Hashes each element of the input array in place using keccak256
     */
    function _processInput(uint256[] memory data)
        private
        pure
        returns (bool sorted)
    {
        sorted = true;

        // Hash inputs with keccak256
        for (uint256 i = 0; i < data.length; ++i) {
            assembly {
                mstore(
                    add(data, mul(0x20, add(1, i))),
                    keccak256(add(data, mul(0x20, add(1, i))), 0x20)
                )
                // for every element after the first, hashed value must be greater than the last one
                if and(
                    gt(i, 0),
                    iszero(
                        gt(
                            mload(add(data, mul(0x20, add(1, i)))),
                            mload(add(data, mul(0x20, add(1, sub(i, 1)))))
                        )
                    )
                ) {
                    sorted := 0 // Elements not ordered by hash
                }
            }
        }
    }

    // Sort uint256 in order of the keccak256 hashes
    struct HashAndIntTuple {
        uint256 num;
        bytes32 hash;
    }

    function _sortUint256ByHash(uint256[] memory values)
        internal
        pure
        returns (uint256[] memory sortedValues)
    {
        HashAndIntTuple[] memory toSort = new HashAndIntTuple[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            toSort[i] = HashAndIntTuple(
                values[i],
                keccak256(abi.encode(values[i]))
            );
        }

        _quickSort(toSort, 0, int256(toSort.length - 1));

        sortedValues = new uint256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            sortedValues[i] = toSort[i].num;
        }
    }

    function _quickSort(
        HashAndIntTuple[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        bytes32 pivot = arr[uint256(left + (right - left) / 2)].hash;
        while (i <= j) {
            while (arr[uint256(i)].hash < pivot) i++;
            while (pivot < arr[uint256(j)].hash) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }
}
