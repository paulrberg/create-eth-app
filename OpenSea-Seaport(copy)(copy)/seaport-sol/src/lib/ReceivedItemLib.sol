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
    ReceivedItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title ReceivedItemLib
 * @author James Wenzel (emo.eth)
 * @notice ReceivedItemLib is a library for managing ReceivedItem structs and
 *         arrays. It allows chaining of functions to make struct creation more
 *         readable.
 */
library ReceivedItemLib {
    bytes32 private constant RECEIVED_ITEM_MAP_POSITION =
        keccak256("seaport.ReceivedItemDefaults");
    bytes32 private constant RECEIVED_ITEMS_MAP_POSITION =
        keccak256("seaport.ReceivedItemsDefaults");
    bytes32 private constant EMPTY_RECEIVED_ITEM =
        keccak256(
            abi.encode(
                ReceivedItem({
                    itemType: ItemType(0),
                    token: address(0),
                    identifier: 0,
                    amount: 0,
                    recipient: payable(address(0))
                })
            )
        );

    /**
     * @dev Clears a default ReceivedItem from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => ReceivedItem)
            storage receivedItemMap = _receivedItemMap();
        ReceivedItem storage item = receivedItemMap[defaultName];
        clear(item);
    }

    /**
     * @dev Clears all fields on a ReceivedItem.
     *
     * @param item the ReceivedItem to clear
     */
    function clear(ReceivedItem storage item) internal {
        // clear all fields
        item.itemType = ItemType.NATIVE;
        item.token = address(0);
        item.identifier = 0;
        item.amount = 0;
        item.recipient = payable(address(0));
    }

    /**
     * @dev Clears an array of ReceivedItems from storage.
     *
     * @param defaultsName the name of the default to clear
     */
    function clearMany(string memory defaultsName) internal {
        mapping(string => ReceivedItem[])
            storage receivedItemsMap = _receivedItemsMap();
        ReceivedItem[] storage items = receivedItemsMap[defaultsName];
        clearMany(items);
    }

    /**
     * @dev Clears an array of ReceivedItems from storage.
     *
     * @param items the ReceivedItems to clear
     */
    function clearMany(ReceivedItem[] storage items) internal {
        while (items.length > 0) {
            clear(items[items.length - 1]);
            items.pop();
        }
    }

    /**
     * @dev Creates an empty ReceivedItem.
     *
     * @return the empty ReceivedItem
     */
    function empty() internal pure returns (ReceivedItem memory) {
        return
            ReceivedItem({
                itemType: ItemType(0),
                token: address(0),
                identifier: 0,
                amount: 0,
                recipient: payable(address(0))
            });
    }

    /**
     * @dev Gets a default ReceivedItem from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the default ReceivedItem
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (ReceivedItem memory item) {
        mapping(string => ReceivedItem)
            storage receivedItemMap = _receivedItemMap();
        item = receivedItemMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_RECEIVED_ITEM) {
            revert("Empty ReceivedItem selected.");
        }
    }

    /**
     * @dev Gets a default ReceivedItem from storage.
     *
     * @param defaultsName the name of the default for retrieval
     *
     * @return items the default ReceivedItem
     */
    function fromDefaultMany(
        string memory defaultsName
    ) internal view returns (ReceivedItem[] memory items) {
        mapping(string => ReceivedItem[])
            storage receivedItemsMap = _receivedItemsMap();
        items = receivedItemsMap[defaultsName];

        if (items.length == 0) {
            revert("Empty ReceivedItem array selected.");
        }
    }

    /**
     * @dev Saves an ReceivedItem as a named default.
     *
     * @param receivedItem the ReceivedItem to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _receivedItem the saved ReceivedItem
     */
    function saveDefault(
        ReceivedItem memory receivedItem,
        string memory defaultName
    ) internal returns (ReceivedItem memory _receivedItem) {
        mapping(string => ReceivedItem)
            storage receivedItemMap = _receivedItemMap();
        receivedItemMap[defaultName] = receivedItem;
        return receivedItem;
    }

    /**
     * @dev Saves an ReceivedItem as a named default.
     *
     * @param receivedItems the ReceivedItem to save as a default
     * @param defaultsName the name of the default for retrieval
     *
     * @return _receivedItems the saved ReceivedItem
     */
    function saveDefaultMany(
        ReceivedItem[] memory receivedItems,
        string memory defaultsName
    ) internal returns (ReceivedItem[] memory _receivedItems) {
        mapping(string => ReceivedItem[])
            storage receivedItemsMap = _receivedItemsMap();
        ReceivedItem[] storage items = receivedItemsMap[defaultsName];
        setReceivedItems(items, receivedItems);
        return receivedItems;
    }

    /**
     * @dev Sets an array of in-memory ReceivedItems to an array of
     *      ReceivedItems in storage.
     *
     * @param items    the ReceivedItems array in storage to push to
     * @param newItems the ReceivedItems array in memory to push onto the items
     *                 array
     */
    function setReceivedItems(
        ReceivedItem[] storage items,
        ReceivedItem[] memory newItems
    ) internal {
        clearMany(items);
        for (uint256 i = 0; i < newItems.length; i++) {
            items.push(newItems[i]);
        }
    }

    /**
     * @dev Makes a copy of an ReceivedItem in-memory.
     *
     * @param item the ReceivedItem to make a copy of in-memory
     *
     * @custom:return copiedReceivedItem the copied ReceivedItem
     */
    function copy(
        ReceivedItem memory item
    ) internal pure returns (ReceivedItem memory) {
        return
            ReceivedItem({
                itemType: item.itemType,
                token: item.token,
                identifier: item.identifier,
                amount: item.amount,
                recipient: item.recipient
            });
    }

    /**
     * @dev Makes a copy of an array of ReceivedItems in-memory.
     *
     * @param item the ReceivedItems array to make a copy of in-memory
     *
     * @custom:return copiedReceivedItems the copied ReceivedItems
     */
    function copy(
        ReceivedItem[] memory item
    ) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory copies = new ReceivedItem[](item.length);
        for (uint256 i = 0; i < item.length; i++) {
            copies[i] = ReceivedItemLib.copy(item[i]);
        }
        return copies;
    }

    /**
     * @dev Gets the storage position of the default ReceivedItem map.
     *
     * @custom:return receivedItemMap the storage position of the default
     *                                ReceivedItem map
     */
    function _receivedItemMap()
        private
        pure
        returns (mapping(string => ReceivedItem) storage receivedItemMap)
    {
        bytes32 position = RECEIVED_ITEM_MAP_POSITION;
        assembly {
            receivedItemMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default ReceivedItem array map.
     *
     * @custom:return receivedItemsMap the storage position of the default
     *                                 ReceivedItem array map
     */
    function _receivedItemsMap()
        private
        pure
        returns (mapping(string => ReceivedItem[]) storage receivedItemsMap)
    {
        bytes32 position = RECEIVED_ITEMS_MAP_POSITION;
        assembly {
            receivedItemsMap.slot := position
        }
    }

    // Methods for configuring a single of each of a ReceivedItem's fields,
    // which modify the ReceivedItem struct in-place and return it.

    /**
     * @dev Sets the itemType field of an ReceivedItem.
     *
     * @param item     the ReceivedItem to set the itemType field of
     * @param itemType the itemType to set the itemType field to
     *
     * @custom:return item the ReceivedItem with the itemType field set
     */
    function withItemType(
        ReceivedItem memory item,
        ItemType itemType
    ) internal pure returns (ReceivedItem memory) {
        item.itemType = itemType;
        return item;
    }

    /**
     * @dev Sets the token field of an ReceivedItem.
     *
     * @param item  the ReceivedItem to set the token field of
     * @param token the token to set the token field to
     *
     * @custom:return item the ReceivedItem with the token field set
     */
    function withToken(
        ReceivedItem memory item,
        address token
    ) internal pure returns (ReceivedItem memory) {
        item.token = token;
        return item;
    }

    /**
     * @dev Sets the identifier field of an ReceivedItem.
     *
     * @param item       the ReceivedItem to set the identifier field of
     * @param identifier the identifier to set the identifier field to
     *
     * @custom:return item the ReceivedItem with the identifier field set
     */
    function withIdentifier(
        ReceivedItem memory item,
        uint256 identifier
    ) internal pure returns (ReceivedItem memory) {
        item.identifier = identifier;
        return item;
    }

    /**
     * @dev Sets the amount field of an ReceivedItem.
     *
     * @param item   the ReceivedItem to set the amount field of
     * @param amount the amount to set the amount field to
     *
     * @custom:return item the ReceivedItem with the amount field set
     */
    function withAmount(
        ReceivedItem memory item,
        uint256 amount
    ) internal pure returns (ReceivedItem memory) {
        item.amount = amount;
        return item;
    }

    /**
     * @dev Sets the recipient field of an ReceivedItem.
     *
     * @param item     the ReceivedItem to set the recipient field of
     * @param recipient the recipient to set the recipient field to
     *
     * @custom:return item the ReceivedItem with the recipient field set
     */
    function withRecipient(
        ReceivedItem memory item,
        address recipient
    ) internal pure returns (ReceivedItem memory) {
        item.recipient = payable(recipient);
        return item;
    }

    /**
     * @dev Converts an ReceivedItem to a ConsiderationItem.
     *
     * @param item the ReceivedItem to convert to a ConsiderationItem
     *
     * @custom:return considerationItem the converted ConsiderationItem
     */
    function toConsiderationItem(
        ReceivedItem memory item
    ) internal pure returns (ConsiderationItem memory) {
        return
            ConsiderationItem({
                itemType: item.itemType,
                token: item.token,
                identifierOrCriteria: item.identifier,
                startAmount: item.amount,
                endAmount: item.amount,
                recipient: item.recipient
            });
    }
}
