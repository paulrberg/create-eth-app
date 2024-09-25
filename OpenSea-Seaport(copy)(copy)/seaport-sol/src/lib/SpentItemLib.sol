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

import { OfferItem, SpentItem } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

/**
 * @title SpentItemLib
 * @author James Wenzel (emo.eth)
 * @notice SpentItemLib is a library for managing SpentItem structs and arrays.
 *         It allows chaining of functions to make struct creation more
 *         readable.
 */
library SpentItemLib {
    bytes32 private constant SPENT_ITEM_MAP_POSITION =
        keccak256("seaport.SpentItemDefaults");
    bytes32 private constant SPENT_ITEMS_MAP_POSITION =
        keccak256("seaport.SpentItemsDefaults");
    bytes32 private constant EMPTY_SPENT_ITEM =
        keccak256(
            abi.encode(
                SpentItem({
                    itemType: ItemType(0),
                    token: address(0),
                    identifier: 0,
                    amount: 0
                })
            )
        );

    /**
     * @dev Creates an empty SpentItem.
     *
     * @return the empty SpentItem
     */
    function empty() internal pure returns (SpentItem memory) {
        return SpentItem(ItemType(0), address(0), 0, 0);
    }

    /**
     * @dev Clears an SpentItem from storage.
     *
     * @param item the item to clear
     */
    function clear(SpentItem storage item) internal {
        // clear all fields
        item.itemType = ItemType(0);
        item.token = address(0);
        item.identifier = 0;
        item.amount = 0;
    }

    /**
     * @dev Clears an array of SpentItems from storage.
     *
     * @param items the items to clear
     */
    function clearMany(SpentItem[] storage items) internal {
        while (items.length > 0) {
            clear(items[items.length - 1]);
            items.pop();
        }
    }

    /**
     * @dev Clears a default SpentItem from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => SpentItem) storage spentItemMap = _spentItemMap();
        SpentItem storage item = spentItemMap[defaultName];
        clear(item);
    }

    /**
     * @dev Clears an array of default SpentItems from storage.
     *
     * @param defaultsName the name of the default to clear
     */
    function clearMany(string memory defaultsName) internal {
        mapping(string => SpentItem[]) storage spentItemsMap = _spentItemsMap();
        SpentItem[] storage items = spentItemsMap[defaultsName];
        clearMany(items);
    }

    /**
     * @dev Gets a default SpentItem from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the SpentItem
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (SpentItem memory item) {
        mapping(string => SpentItem) storage spentItemMap = _spentItemMap();
        item = spentItemMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_SPENT_ITEM) {
            revert("Empty SpentItem selected.");
        }
    }

    /**
     * @dev Gets an array of default SpentItems from storage.
     *
     * @param defaultsName the name of the default for retrieval
     *
     * @return items the SpentItems
     */
    function fromDefaultMany(
        string memory defaultsName
    ) internal view returns (SpentItem[] memory items) {
        mapping(string => SpentItem[]) storage spentItemsMap = _spentItemsMap();
        items = spentItemsMap[defaultsName];

        if (items.length == 0) {
            revert("Empty SpentItem array selected.");
        }
    }

    /**
     * @dev Saves an SpentItem as a named default.
     *
     * @param spentItem the SpentItem to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _spentItem the saved SpentItem
     */
    function saveDefault(
        SpentItem memory spentItem,
        string memory defaultName
    ) internal returns (SpentItem memory _spentItem) {
        mapping(string => SpentItem) storage spentItemMap = _spentItemMap();
        spentItemMap[defaultName] = spentItem;
        return spentItem;
    }

    /**
     * @dev Saves an array of SpentItems as a named default.
     *
     * @param spentItems the SpentItems to save as a default
     * @param defaultsName the name of the default for retrieval
     *
     * @return _spentItems the saved SpentItems
     */
    function saveDefaultMany(
        SpentItem[] memory spentItems,
        string memory defaultsName
    ) internal returns (SpentItem[] memory _spentItems) {
        mapping(string => SpentItem[]) storage spentItemsMap = _spentItemsMap();
        SpentItem[] storage items = spentItemsMap[defaultsName];
        setSpentItems(items, spentItems);
        return spentItems;
    }

    /**
     * @dev Sets an array of in-memory SpentItems to an array of SpentItems in
     *      storage.
     *
     * @param items    the SpentItem array in storage to push to
     * @param newItems the SpentItem array in memory to push onto the items
     *                 array
     */
    function setSpentItems(
        SpentItem[] storage items,
        SpentItem[] memory newItems
    ) internal {
        clearMany(items);
        for (uint256 i = 0; i < newItems.length; i++) {
            items.push(newItems[i]);
        }
    }

    /**
     * @dev Makes a copy of an SpentItem in-memory.
     *
     * @param item the SpentItem to make a copy of in-memory
     *
     * @custom:return copiedItem the copied SpentItem
     */
    function copy(
        SpentItem memory item
    ) internal pure returns (SpentItem memory) {
        return
            SpentItem({
                itemType: item.itemType,
                token: item.token,
                identifier: item.identifier,
                amount: item.amount
            });
    }

    /**
     * @dev Makes a copy of an array of SpentItems in-memory.
     *
     * @param items the SpentItems to make a copy of in-memory
     *
     * @custom:return copiedItems the copied SpentItems
     */
    function copy(
        SpentItem[] memory items
    ) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory copiedItems = new SpentItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            copiedItems[i] = copy(items[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Gets the storage position of the default SpentItem map.
     *
     * @custom:return position the storage position of the default SpentItem map
     */
    function _spentItemMap()
        private
        pure
        returns (mapping(string => SpentItem) storage spentItemMap)
    {
        bytes32 position = SPENT_ITEM_MAP_POSITION;
        assembly {
            spentItemMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default SpentItem array map.
     *
     * @custom:return position the storage position of the default SpentItem
     *                         array map
     */
    function _spentItemsMap()
        private
        pure
        returns (mapping(string => SpentItem[]) storage spentItemsMap)
    {
        bytes32 position = SPENT_ITEMS_MAP_POSITION;
        assembly {
            spentItemsMap.slot := position
        }
    }

    // Methods for configuring a single of each of a SpentItem's fields, which
    // modify the SpentItem struct in-place and return it.

    /**
     * @dev Sets the itemType field of a SpentItem.
     *
     * @param item     the SpentItem to set the itemType field of
     * @param itemType the itemType to set the itemType field to
     *
     * @custom:return item the SpentItem with the itemType field set
     */
    function withItemType(
        SpentItem memory item,
        ItemType itemType
    ) internal pure returns (SpentItem memory) {
        item.itemType = itemType;
        return item;
    }

    /**
     * @dev Sets the token field of a SpentItem.
     *
     * @param item  the SpentItem to set the token field of
     * @param token the token to set the token field to
     *
     * @custom:return item the SpentItem with the token field set
     */
    function withToken(
        SpentItem memory item,
        address token
    ) internal pure returns (SpentItem memory) {
        item.token = token;
        return item;
    }

    /**
     * @dev Sets the identifier field of a SpentItem.
     *
     * @param item       the SpentItem to set the identifier field of
     * @param identifier the identifier to set the identifier field to
     *
     * @custom:return item the SpentItem with the identifier field set
     */
    function withIdentifier(
        SpentItem memory item,
        uint256 identifier
    ) internal pure returns (SpentItem memory) {
        item.identifier = identifier;
        return item;
    }

    /**
     * @dev Sets the amount field of a SpentItem.
     *
     * @param item   the SpentItem to set the amount field of
     * @param amount the amount to set the amount field to
     *
     * @custom:return item the SpentItem with the amount field set
     */
    function withAmount(
        SpentItem memory item,
        uint256 amount
    ) internal pure returns (SpentItem memory) {
        item.amount = amount;
        return item;
    }

    /**
     * @dev Converts a SpentItem to an OfferItem.
     *
     * @param item the SpentItem to convert to an OfferItem
     *
     * @custom:return offerItem the converted OfferItem
     */
    function toOfferItem(
        SpentItem memory item
    ) internal pure returns (OfferItem memory) {
        return
            OfferItem({
                itemType: item.itemType,
                token: item.token,
                identifierOrCriteria: item.identifier,
                startAmount: item.amount,
                endAmount: item.amount
            });
    }
}
