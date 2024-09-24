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

import {
    ConsiderationItem,
    OfferItem,
    SpentItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title OfferItemLib
 * @author James Wenzel (emo.eth)
 * @notice OfferItemLib is a library for managing OfferItem structs and arrays.
 *         It allows chaining of functions to make struct creation more readable.
 */
library OfferItemLib {
    bytes32 private constant OFFER_ITEM_MAP_POSITION =
        keccak256("seaport.OfferItemDefaults");
    bytes32 private constant OFFER_ITEMS_MAP_POSITION =
        keccak256("seaport.OfferItemsDefaults");
    bytes32 private constant EMPTY_OFFER_ITEM =
        keccak256(
            abi.encode(
                OfferItem({
                    itemType: ItemType(0),
                    token: address(0),
                    identifierOrCriteria: 0,
                    startAmount: 0,
                    endAmount: 0
                })
            )
        );

    /**
     * @dev Clears an OfferItem from storage.
     *
     * @param item the item to clear
     */
    function _clear(OfferItem storage item) internal {
        // clear all fields
        item.itemType = ItemType.NATIVE;
        item.token = address(0);
        item.identifierOrCriteria = 0;
        item.startAmount = 0;
        item.endAmount = 0;
    }

    /**
     * @dev Clears an OfferItem from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => OfferItem) storage offerItemMap = _offerItemMap();
        OfferItem storage item = offerItemMap[defaultName];
        _clear(item);
    }

    /**
     * @dev Clears an array of OfferItems from storage.
     *
     * @param defaultsName the name of the default to clear
     */
    function clearMany(string memory defaultsName) internal {
        mapping(string => OfferItem[]) storage offerItemsMap = _offerItemsMap();
        OfferItem[] storage items = offerItemsMap[defaultsName];
        while (items.length > 0) {
            _clear(items[items.length - 1]);
            items.pop();
        }
    }

    /**
     * @dev Gets a default OfferItem from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the OfferItem retrieved from storage
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (OfferItem memory item) {
        mapping(string => OfferItem) storage offerItemMap = _offerItemMap();
        item = offerItemMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_OFFER_ITEM) {
            revert("Empty OfferItem selected.");
        }
    }

    /**
     * @dev Gets a default OfferItem from storage.
     *
     * @param defaultsName the name of the default for retrieval
     *
     * @return items the OfferItems retrieved from storage
     */
    function fromDefaultMany(
        string memory defaultsName
    ) internal view returns (OfferItem[] memory items) {
        mapping(string => OfferItem[]) storage offerItemsMap = _offerItemsMap();
        items = offerItemsMap[defaultsName];

        if (items.length == 0) {
            revert("Empty OfferItem array selected.");
        }
    }

    /**
     * @dev Saves an OfferItem as a named default.
     *
     * @param offerItem   the OfferItem to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _offerItem the OfferItem saved as a default
     */
    function saveDefault(
        OfferItem memory offerItem,
        string memory defaultName
    ) internal returns (OfferItem memory _offerItem) {
        mapping(string => OfferItem) storage offerItemMap = _offerItemMap();
        offerItemMap[defaultName] = offerItem;
        return offerItem;
    }

    /**
     * @dev Saves an array of OfferItems as a named default.
     *
     * @param offerItems   the OfferItems to save as a default
     * @param defaultsName the name of the default for retrieval
     *
     * @return _offerItems the OfferItems saved as a default
     */
    function saveDefaultMany(
        OfferItem[] memory offerItems,
        string memory defaultsName
    ) internal returns (OfferItem[] memory _offerItems) {
        mapping(string => OfferItem[]) storage offerItemsMap = _offerItemsMap();
        OfferItem[] storage items = offerItemsMap[defaultsName];
        clearMany(defaultsName);
        StructCopier.setOfferItems(items, offerItems);
        return offerItems;
    }

    /**
     * @dev Makes a copy of an OfferItem in-memory.
     *
     * @param item the OfferItem to make a copy of in-memory
     *
     * @custom:return copiedItem the copied OfferItem
     */
    function copy(
        OfferItem memory item
    ) internal pure returns (OfferItem memory) {
        return
            OfferItem({
                itemType: item.itemType,
                token: item.token,
                identifierOrCriteria: item.identifierOrCriteria,
                startAmount: item.startAmount,
                endAmount: item.endAmount
            });
    }

    /**
     * @dev Makes a copy of an array of OfferItems in-memory.
     *
     * @param items the OfferItems to make a copy of in-memory
     *
     * @custom:return copiedItems the copied OfferItems
     */
    function copy(
        OfferItem[] memory items
    ) internal pure returns (OfferItem[] memory) {
        OfferItem[] memory copiedItems = new OfferItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            copiedItems[i] = copy(items[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Creates an empty OfferItem.
     *
     * @custom:return emptyItem the empty OfferItem
     */
    function empty() internal pure returns (OfferItem memory) {
        return
            OfferItem({
                itemType: ItemType.NATIVE,
                token: address(0),
                identifierOrCriteria: 0,
                startAmount: 0,
                endAmount: 0
            });
    }

    /**
     * @dev Gets the storage position of the default OfferItem map.
     *
     * @custom:return offerItemMap the default OfferItem map position
     */
    function _offerItemMap()
        private
        pure
        returns (mapping(string => OfferItem) storage offerItemMap)
    {
        bytes32 position = OFFER_ITEM_MAP_POSITION;
        assembly {
            offerItemMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default OfferItem array map
     *
     * @custom:return offerItemMap the default OfferItem array map position
     */
    function _offerItemsMap()
        private
        pure
        returns (mapping(string => OfferItem[]) storage offerItemMap)
    {
        bytes32 position = OFFER_ITEMS_MAP_POSITION;
        assembly {
            offerItemMap.slot := position
        }
    }

    // Methods for configuring a single of each of a OfferItem's fields, which
    // modify the OfferItem in-place and return it.

    /**
     * @dev Sets the item type of an OfferItem.
     *
     * @param item the OfferItem to modify
     * @param itemType the item type to set
     *
     * @custom:return _offerItem the modified OfferItem
     */
    function withItemType(
        OfferItem memory item,
        ItemType itemType
    ) internal pure returns (OfferItem memory) {
        item.itemType = itemType;
        return item;
    }

    /**
     * @dev Sets the token of an OfferItem.
     *
     * @param item the OfferItem to modify
     * @param token the token to set
     *
     * @custom:return _offerItem the modified OfferItem
     */
    function withToken(
        OfferItem memory item,
        address token
    ) internal pure returns (OfferItem memory) {
        item.token = token;
        return item;
    }

    /**
     * @dev Sets the identifierOrCriteria of an OfferItem.
     *
     * @param item the OfferItem to modify
     * @param identifierOrCriteria the identifier or criteria to set
     *
     * @custom:return _offerItem the modified OfferItem
     */
    function withIdentifierOrCriteria(
        OfferItem memory item,
        uint256 identifierOrCriteria
    ) internal pure returns (OfferItem memory) {
        item.identifierOrCriteria = identifierOrCriteria;
        return item;
    }

    /**
     * @dev Sets the startAmount of an OfferItem.
     *
     * @param item the OfferItem to modify
     * @param startAmount the start amount to set
     *
     * @custom:return _offerItem the modified OfferItem
     */
    function withStartAmount(
        OfferItem memory item,
        uint256 startAmount
    ) internal pure returns (OfferItem memory) {
        item.startAmount = startAmount;
        return item;
    }

    /**
     * @dev Sets the endAmount of an OfferItem.
     *
     * @param item the OfferItem to modify
     * @param endAmount the end amount to set
     *
     * @custom:return _offerItem the modified OfferItem
     */
    function withEndAmount(
        OfferItem memory item,
        uint256 endAmount
    ) internal pure returns (OfferItem memory) {
        item.endAmount = endAmount;
        return item;
    }

    /**
     * @dev Sets the startAmount and endAmount of an OfferItem.
     *
     * @param item the OfferItem to modify
     * @param amount the amount to set for the start and end amounts
     *
     * @custom:return _offerItem the modified OfferItem
     */
    function withAmount(
        OfferItem memory item,
        uint256 amount
    ) internal pure returns (OfferItem memory) {
        item.startAmount = amount;
        item.endAmount = amount;
        return item;
    }

    /**
     * @dev Converts an OfferItem to a SpentItem.
     *
     * @param item the OfferItem to convert
     *
     * @custom:return spentItem the converted SpentItem
     */
    function toSpentItem(
        OfferItem memory item
    ) internal pure returns (SpentItem memory) {
        return
            SpentItem({
                itemType: item.itemType,
                token: item.token,
                identifier: item.identifierOrCriteria,
                amount: item.startAmount
            });
    }

    /**
     * @dev Converts an OfferItem[] to a SpentItem[].
     *
     * @param items the OfferItem[] to convert
     *
     * @custom:return spentItems the converted SpentItem[]
     */
    function toSpentItemArray(
        OfferItem[] memory items
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory spentItems = new SpentItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            spentItems[i] = toSpentItem(items[i]);
        }

        return spentItems;
    }

    /**
     * @dev Converts an OfferItem to a ConsiderationItem.
     *
     * @param item the OfferItem to convert
     *
     * @custom:return considerationItem the converted ConsiderationItem
     */
    function toConsiderationItem(
        OfferItem memory item,
        address recipient
    ) internal pure returns (ConsiderationItem memory) {
        return
            ConsiderationItem({
                itemType: item.itemType,
                token: item.token,
                identifierOrCriteria: item.identifierOrCriteria,
                startAmount: item.startAmount,
                endAmount: item.endAmount,
                recipient: payable(recipient)
            });
    }
}
