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

import {ConsiderationItem, OfferItem, ReceivedItem, SpentItem} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {ItemType} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {StructCopier} from "./StructCopier.sol";

/**
 * @title ConsiderationItemLib
 * @author James Wenzel (emo.eth)
 * @notice ConsiderationItemLib is a library for managing ConsiderationItem
 *         structs and arrays. It allows chaining of functions to make
 *         struct creation more readable.
 */
library ConsiderationItemLib {
    bytes32 private constant CONSIDERATION_ITEM_MAP_POSITION = keccak256("seaport.ConsiderationItemDefaults");
    bytes32 private constant CONSIDERATION_ITEMS_MAP_POSITION = keccak256("seaport.ConsiderationItemsDefaults");
    bytes32 private constant EMPTY_CONSIDERATION_ITEM = keccak256(
        abi.encode(
            ConsiderationItem({
                itemType: ItemType(0),
                token: address(0),
                identifierOrCriteria: 0,
                startAmount: 0,
                endAmount: 0,
                recipient: payable(address(0))
            })
        )
    );

    /**
     * @dev Clears a ConsiderationItem from storage.
     *
     * @param item the ConsiderationItem to clear.
     */
    function _clear(ConsiderationItem storage item) internal {
        // clear all fields
        item.itemType = ItemType.NATIVE;
        item.token = address(0);
        item.identifierOrCriteria = 0;
        item.startAmount = 0;
        item.endAmount = 0;
        item.recipient = payable(address(0));
    }

    /**
     * @dev Clears a named default ConsiderationItem from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => ConsiderationItem) storage considerationItemMap = _considerationItemMap();
        ConsiderationItem storage item = considerationItemMap[defaultName];
        _clear(item);
    }

    /**
     * @dev Clears an array of ConsiderationItems from storage.
     *
     * @param defaultsName the name of the array to clear
     */
    function clearMany(string memory defaultsName) internal {
        mapping(string => ConsiderationItem[]) storage considerationItemsMap = _considerationItemsMap();
        ConsiderationItem[] storage items = considerationItemsMap[defaultsName];
        while (items.length > 0) {
            _clear(items[items.length - 1]);
            items.pop();
        }
    }

    /**
     * @dev Gets a default ConsiderationItem from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the ConsiderationItem retrieved from storage
     */
    function fromDefault(string memory defaultName) internal view returns (ConsiderationItem memory item) {
        mapping(string => ConsiderationItem) storage considerationItemMap = _considerationItemMap();
        item = considerationItemMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_CONSIDERATION_ITEM) {
            revert("Empty ConsiderationItem selected.");
        }
    }

    /**
     * @dev Gets an array of default ConsiderationItems from storage.
     *
     * @param defaultsName the name of the array for retrieval
     *
     * @return items the array of ConsiderationItems retrieved from storage
     */
    function fromDefaultMany(string memory defaultsName) internal view returns (ConsiderationItem[] memory items) {
        mapping(string => ConsiderationItem[]) storage considerationItemsMap = _considerationItemsMap();
        items = considerationItemsMap[defaultsName];

        if (items.length == 0) {
            revert("Empty ConsiderationItem array selected.");
        }
    }

    /**
     * @dev Creates an empty ConsiderationItem.
     *
     * @custom:return considerationItemMap the storage location of the default
     *                                     ConsiderationItem map
     */
    function empty() internal pure returns (ConsiderationItem memory) {
        return ConsiderationItem({
            itemType: ItemType(0),
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: 0,
            endAmount: 0,
            recipient: payable(address(0))
        });
    }

    /**
     * @dev Saves a ConsiderationItem as a named default.
     *
     * @param considerationItem the ConsiderationItem to save as a default
     * @param defaultName       the name of the default for retrieval
     *
     * @return _considerationItem the saved ConsiderationItem
     */
    function saveDefault(ConsiderationItem memory considerationItem, string memory defaultName)
        internal
        returns (ConsiderationItem memory _considerationItem)
    {
        mapping(string => ConsiderationItem) storage considerationItemMap = _considerationItemMap();
        considerationItemMap[defaultName] = considerationItem;
        return considerationItem;
    }

    /**
     * @dev Saves an array of ConsiderationItems as a named default.
     *
     * @param considerationItems the array of ConsiderationItems to save as a
     *                           default
     * @param defaultsName       the name of the default array for retrieval
     *
     * @return _considerationItems the saved array of ConsiderationItems
     */
    function saveDefaultMany(ConsiderationItem[] memory considerationItems, string memory defaultsName)
        internal
        returns (ConsiderationItem[] memory _considerationItems)
    {
        mapping(string => ConsiderationItem[]) storage considerationItemsMap = _considerationItemsMap();
        ConsiderationItem[] storage items = considerationItemsMap[defaultsName];
        clearMany(defaultsName);
        StructCopier.setConsiderationItems(items, considerationItems);
        return considerationItems;
    }

    /**
     * @dev Makes a copy of an ConsiderationItem in-memory.
     *
     * @param item the ConsiderationItem to make a copy of in-memory
     *
     * @custom:return copy the copy of the ConsiderationItem
     */
    function copy(ConsiderationItem memory item) internal pure returns (ConsiderationItem memory) {
        return ConsiderationItem({
            itemType: item.itemType,
            token: item.token,
            identifierOrCriteria: item.identifierOrCriteria,
            startAmount: item.startAmount,
            endAmount: item.endAmount,
            recipient: item.recipient
        });
    }

    /**
     * @dev Makes a copy of an array of ConsiderationItems in-memory.
     *
     * @param items the array of ConsiderationItems to make a copy of in-memory
     *
     * @custom:return copy the copy of the array of ConsiderationItems
     */
    function copy(ConsiderationItem[] memory items) internal pure returns (ConsiderationItem[] memory) {
        ConsiderationItem[] memory copies = new ConsiderationItem[](
            items.length
        );
        for (uint256 i = 0; i < items.length; i++) {
            copies[i] = ConsiderationItem({
                itemType: items[i].itemType,
                token: items[i].token,
                identifierOrCriteria: items[i].identifierOrCriteria,
                startAmount: items[i].startAmount,
                endAmount: items[i].endAmount,
                recipient: items[i].recipient
            });
        }
        return copies;
    }

    /**
     * @dev Gets the storage position of the default ConsiderationItem map.
     *
     * @custom:return considerationItemMap the storage location of the default
     *                                     ConsiderationItem map
     */
    function _considerationItemMap()
        private
        pure
        returns (mapping(string => ConsiderationItem) storage considerationItemMap)
    {
        bytes32 position = CONSIDERATION_ITEM_MAP_POSITION;
        assembly {
            considerationItemMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default array of ConsiderationItems
     *      map.
     *
     * @custom:return considerationItemsMap the storage location of the default
     *                                      array of ConsiderationItems map
     */
    function _considerationItemsMap()
        private
        pure
        returns (mapping(string => ConsiderationItem[]) storage considerationItemsMap)
    {
        bytes32 position = CONSIDERATION_ITEMS_MAP_POSITION;
        assembly {
            considerationItemsMap.slot := position
        }
    }

    // Methods for configuring a single of each of an ConsiderationItem's
    // fields, which modify the ConsiderationItem in-place and return it.

    /**
     * @dev Sets the item type.
     *
     * @param item     the ConsiderationItem to modify
     * @param itemType the item type to set
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withItemType(ConsiderationItem memory item, ItemType itemType)
        internal
        pure
        returns (ConsiderationItem memory)
    {
        item.itemType = itemType;
        return item;
    }

    /**
     * @dev Sets the token address.
     *
     * @param item  the ConsiderationItem to modify
     * @param token the token address to set
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withToken(ConsiderationItem memory item, address token) internal pure returns (ConsiderationItem memory) {
        item.token = token;
        return item;
    }

    /**
     * @dev Sets the identifier or criteria.
     *
     * @param item the ConsiderationItem to modify
     * @param identifierOrCriteria the identifier or criteria to set
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withIdentifierOrCriteria(ConsiderationItem memory item, uint256 identifierOrCriteria)
        internal
        pure
        returns (ConsiderationItem memory)
    {
        item.identifierOrCriteria = identifierOrCriteria;
        return item;
    }

    /**
     * @dev Sets the start amount.
     *
     * @param item the ConsiderationItem to modify
     * @param startAmount the start amount to set
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withStartAmount(ConsiderationItem memory item, uint256 startAmount)
        internal
        pure
        returns (ConsiderationItem memory)
    {
        item.startAmount = startAmount;
        return item;
    }

    /**
     * @dev Sets the end amount.
     *
     * @param item the ConsiderationItem to modify
     * @param endAmount the end amount to set
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withEndAmount(ConsiderationItem memory item, uint256 endAmount)
        internal
        pure
        returns (ConsiderationItem memory)
    {
        item.endAmount = endAmount;
        return item;
    }

    /**
     * @dev Sets the startAmount and endAmount of an ConsiderationItem.
     *
     * @param item the ConsiderationItem to modify
     * @param amount the amount to set for the start and end amounts
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withAmount(ConsiderationItem memory item, uint256 amount)
        internal
        pure
        returns (ConsiderationItem memory)
    {
        item.startAmount = amount;
        item.endAmount = amount;
        return item;
    }

    /**
     * @dev Sets the recipient.
     *
     * @param item the ConsiderationItem to modify
     * @param recipient the recipient to set
     *
     * @custom:return item the modified ConsiderationItem
     */
    function withRecipient(ConsiderationItem memory item, address recipient)
        internal
        pure
        returns (ConsiderationItem memory)
    {
        item.recipient = payable(recipient);
        return item;
    }

    /**
     * @dev Converts an ConsiderationItem to a ReceivedItem.
     *
     * @param item the ConsiderationItem to convert
     *
     * @custom:return receivedItem the converted ReceivedItem
     */
    function toReceivedItem(ConsiderationItem memory item) internal pure returns (ReceivedItem memory) {
        return ReceivedItem({
            itemType: item.itemType,
            token: item.token,
            identifier: item.identifierOrCriteria,
            amount: item.startAmount,
            recipient: item.recipient
        });
    }

    function toReceivedItemArray(ConsiderationItem[] memory items) internal pure returns (ReceivedItem[] memory) {
        ReceivedItem[] memory receivedItems = new ReceivedItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            receivedItems[i] = toReceivedItem(items[i]);
        }
        return receivedItems;
    }

    function toSpentItem(ConsiderationItem memory item) internal pure returns (SpentItem memory) {
        return SpentItem({
            itemType: item.itemType,
            token: item.token,
            identifier: item.identifierOrCriteria,
            amount: item.startAmount
        });
    }

    function toSpentItemArray(ConsiderationItem[] memory items) internal pure returns (SpentItem[] memory) {
        SpentItem[] memory spentItems = new SpentItem[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            spentItems[i] = toSpentItem(items[i]);
        }
        return spentItems;
    }

    function toOfferItem(ConsiderationItem memory item) internal pure returns (OfferItem memory) {
        return OfferItem({
            itemType: item.itemType,
            token: item.token,
            identifierOrCriteria: item.identifierOrCriteria,
            startAmount: item.startAmount,
            endAmount: item.endAmount
        });
    }
}
