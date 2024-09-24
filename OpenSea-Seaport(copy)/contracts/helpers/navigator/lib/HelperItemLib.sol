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

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    NavigatorOfferItem,
    NavigatorConsiderationItem
} from "./SeaportNavigatorTypes.sol";

library HelperItemLib {
    error InvalidIdentifier(uint256 identifier, uint256[] candidateIdentifiers);
    error InvalidItemTypeForCandidateIdentifiers();

    /**
     * @dev Internal error: Could not convert item type.
     */
    error UnknownItemType();

    function normalizeType(
        NavigatorOfferItem memory item
    ) internal pure returns (ItemType) {
        ItemType itemType = item.itemType;
        if (hasCriteria(item)) {
            if (
                itemType == ItemType.ERC721 ||
                itemType == ItemType.ERC721_WITH_CRITERIA
            ) {
                return ItemType.ERC721_WITH_CRITERIA;
            } else if (
                itemType == ItemType.ERC1155 ||
                itemType == ItemType.ERC1155_WITH_CRITERIA
            ) {
                return ItemType.ERC1155_WITH_CRITERIA;
            } else {
                revert UnknownItemType();
            }
        } else {
            return itemType;
        }
    }

    function normalizeType(
        NavigatorConsiderationItem memory item
    ) internal pure returns (ItemType) {
        ItemType itemType = item.itemType;
        if (hasCriteria(item)) {
            if (
                itemType == ItemType.ERC721 ||
                itemType == ItemType.ERC721_WITH_CRITERIA
            ) {
                return ItemType.ERC721_WITH_CRITERIA;
            } else if (
                itemType == ItemType.ERC1155 ||
                itemType == ItemType.ERC1155_WITH_CRITERIA
            ) {
                return ItemType.ERC1155_WITH_CRITERIA;
            } else {
                revert UnknownItemType();
            }
        } else {
            return itemType;
        }
    }

    function hasCriteria(
        NavigatorOfferItem memory item
    ) internal pure returns (bool) {
        return item.candidateIdentifiers.length > 0;
    }

    function hasCriteria(
        NavigatorConsiderationItem memory item
    ) internal pure returns (bool) {
        return item.candidateIdentifiers.length > 0;
    }

    function validate(NavigatorOfferItem memory item) internal pure {
        ItemType itemType = item.itemType;
        if (itemType == ItemType.ERC20 || itemType == ItemType.NATIVE) {
            if (item.candidateIdentifiers.length > 0) {
                revert InvalidItemTypeForCandidateIdentifiers();
            } else {
                return;
            }
        }
        // If the item has candidate identifiers, the item identifier must be
        // zero for wildcard or one of the candidates.
        if (item.candidateIdentifiers.length == 0 && item.identifier == 0) {
            revert InvalidIdentifier(
                item.identifier,
                item.candidateIdentifiers
            );
        }
        if (item.candidateIdentifiers.length > 0) {
            bool identifierFound;
            for (uint256 i; i < item.candidateIdentifiers.length; i++) {
                if (item.candidateIdentifiers[i] == item.identifier) {
                    identifierFound = true;
                    break;
                }
            }
            if (!identifierFound && item.identifier != 0) {
                revert InvalidIdentifier(
                    item.identifier,
                    item.candidateIdentifiers
                );
            }
        }
    }

    function validate(NavigatorConsiderationItem memory item) internal pure {
        ItemType itemType = item.itemType;
        if (itemType == ItemType.ERC20 || itemType == ItemType.NATIVE) {
            if (item.candidateIdentifiers.length > 0) {
                revert InvalidItemTypeForCandidateIdentifiers();
            } else {
                return;
            }
        }
        // If the item has candidate identifiers, the item identifier must be
        // zero for wildcard or one of the candidates.
        if (item.candidateIdentifiers.length == 0 && item.identifier == 0) {
            revert InvalidIdentifier(
                item.identifier,
                item.candidateIdentifiers
            );
        }
        if (item.candidateIdentifiers.length > 0) {
            bool identifierFound;
            for (uint256 i; i < item.candidateIdentifiers.length; i++) {
                if (item.candidateIdentifiers[i] == item.identifier) {
                    identifierFound = true;
                    break;
                }
            }
            if (!identifierFound && item.identifier != 0) {
                revert InvalidIdentifier(
                    item.identifier,
                    item.candidateIdentifiers
                );
            }
        }
    }
}
