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

import { MerkleLib } from "./MerkleLib.sol";

error TokenIdNotFound();

struct HashAndIntTuple {
    uint256 num;
    bytes32 hash;
}

/**
 * @notice Helper library for calculating criteria resolver Merkle roots and
 *         proofs from integer token ids.
 */
library CriteriaHelperLib {
    error CannotDeriveRootForSingleTokenId();
    error CannotDeriveProofForSingleTokenId();

    /**
     * @notice Calculate the Merkle root of a criteria tree containing the given
     *         integer token ids.
     */
    function criteriaRoot(
        uint256[] memory tokenIds
    ) internal pure returns (bytes32) {
        if (tokenIds.length == 0) {
            return bytes32(0);
        } else if (tokenIds.length == 1) {
            revert CannotDeriveRootForSingleTokenId();
        } else {
            return
                MerkleLib.getRoot(
                    toSortedHashes(tokenIds),
                    MerkleLib.merkleHash
                );
        }
    }

    /**
     * @notice Calculate the Merkle proof that the given token id is a member of
     *         the criteria tree containing the provided tokenIds.
     */
    function criteriaProof(
        uint256[] memory tokenIds,
        uint256 id
    ) internal pure returns (bytes32[] memory) {
        if (tokenIds.length == 0) {
            return new bytes32[](0);
        } else if (tokenIds.length == 1) {
            revert CannotDeriveProofForSingleTokenId();
        } else {
            bytes32 idHash = keccak256(abi.encode(id));
            uint256 idx;
            bool found;
            bytes32[] memory idHashes = toSortedHashes(tokenIds);
            for (; idx < idHashes.length; idx++) {
                if (idHashes[idx] == idHash) {
                    found = true;
                    break;
                }
            }
            if (!found) revert TokenIdNotFound();
            return MerkleLib.getProof(idHashes, idx, MerkleLib.merkleHash);
        }
    }

    /**
     * @notice Sort an array of integer token ids by their hashed values.
     */
    function sortByHash(
        uint256[] memory tokenIds
    ) internal pure returns (uint256[] memory sortedIds) {
        HashAndIntTuple[] memory toSort = new HashAndIntTuple[](
            tokenIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            toSort[i] = HashAndIntTuple(
                tokenIds[i],
                keccak256(abi.encode(tokenIds[i]))
            );
        }

        _quickSort(toSort, 0, int256(toSort.length - 1));

        sortedIds = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            sortedIds[i] = toSort[i].num;
        }
    }

    /**
     * @notice Convert an array of integer token ids to a sorted array of
     *         their hashed values.
     */
    function toSortedHashes(
        uint256[] memory tokenIds
    ) internal pure returns (bytes32[] memory hashes) {
        hashes = new bytes32[](tokenIds.length);
        uint256[] memory ids = sortByHash(tokenIds);
        for (uint256 i; i < ids.length; ++i) {
            hashes[i] = keccak256(abi.encode(ids[i]));
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
