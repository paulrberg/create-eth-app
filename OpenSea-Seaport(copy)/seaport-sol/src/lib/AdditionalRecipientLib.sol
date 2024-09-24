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

import { AdditionalRecipient } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title AdditionalRecipientLib
 * @author James Wenzel (emo.eth)
 * @notice AdditionalRecipientLib is a library for managing AdditionalRecipient
 *         structs and arrays. It allows chaining of functions to make
 *         struct creation more readable.
 */
library AdditionalRecipientLib {
    bytes32 private constant ADDITIONAL_RECIPIENT_MAP_POSITION =
        keccak256("seaport.AdditionalRecipientDefaults");
    bytes32 private constant ADDITIONAL_RECIPIENTS_MAP_POSITION =
        keccak256("seaport.AdditionalRecipientsDefaults");
    bytes32 private constant EMPTY_ADDITIONAL_RECIPIENT =
        keccak256(
            abi.encode(
                AdditionalRecipient({
                    amount: 0,
                    recipient: payable(address(0))
                })
            )
        );

    /**
     * @dev Clears a default AdditionalRecipient from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => AdditionalRecipient)
            storage additionalRecipientMap = _additionalRecipientMap();
        AdditionalRecipient storage item = additionalRecipientMap[defaultName];
        clear(item);
    }

    /**
     * @dev Clears all fields on an AdditionalRecipient.
     *
     * @param item the AdditionalRecipient to clear
     */
    function clear(AdditionalRecipient storage item) internal {
        // clear all fields
        item.amount = 0;
        item.recipient = payable(address(0));
    }

    /**
     * @dev Clears an array of AdditionalRecipients from storage.
     *
     * @param items the name of the default to clear
     */
    function clear(AdditionalRecipient[] storage items) internal {
        while (items.length > 0) {
            clear(items[items.length - 1]);
            items.pop();
        }
    }

    /**
     * @dev Gets a default AdditionalRecipient from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the AdditionalRecipient retrieved from storage
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (AdditionalRecipient memory item) {
        mapping(string => AdditionalRecipient)
            storage additionalRecipientMap = _additionalRecipientMap();
        item = additionalRecipientMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_ADDITIONAL_RECIPIENT) {
            revert("Empty AdditionalRecipient selected.");
        }
    }

    /**
     * @dev Gets an array of default AdditionalRecipients from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the AdditionalRecipients retrieved from storage
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (AdditionalRecipient[] memory items) {
        mapping(string => AdditionalRecipient[])
            storage additionalRecipientsMap = _additionalRecipientsMap();
        items = additionalRecipientsMap[defaultName];

        if (items.length == 0) {
            revert("Empty AdditionalRecipient array selected.");
        }
    }

    /**
     * @dev Saves an AdditionalRecipient as a named default.
     *
     * @param additionalRecipient the AdditionalRecipient to save as a default
     * @param defaultName         the name of the new default
     *
     * @return _additionalRecipient the AdditionalRecipient saved as a default
     */
    function saveDefault(
        AdditionalRecipient memory additionalRecipient,
        string memory defaultName
    ) internal returns (AdditionalRecipient memory _additionalRecipient) {
        mapping(string => AdditionalRecipient)
            storage additionalRecipientMap = _additionalRecipientMap();
        additionalRecipientMap[defaultName] = additionalRecipient;
        return additionalRecipient;
    }

    /**
     * @dev Saves an array of AdditionalRecipients as a named default.
     *
     * @param additionalRecipients the AdditionalRecipients to save as a default
     * @param defaultName          the name of the new default
     *
     * @return _additionalRecipients the AdditionalRecipients saved as a default
     */
    function saveDefaultMany(
        AdditionalRecipient[] memory additionalRecipients,
        string memory defaultName
    ) internal returns (AdditionalRecipient[] memory _additionalRecipients) {
        mapping(string => AdditionalRecipient[])
            storage additionalRecipientsMap = _additionalRecipientsMap();
        StructCopier.setAdditionalRecipients(
            additionalRecipientsMap[defaultName],
            additionalRecipients
        );
        return additionalRecipients;
    }

    /**
     * @dev Makes a copy of an AdditionalRecipient in-memory.
     *
     * @param item the AdditionalRecipient to make a copy of in-memory
     *
     * @custom:return additionalRecipient the copy of the AdditionalRecipient
     */
    function copy(
        AdditionalRecipient memory item
    ) internal pure returns (AdditionalRecipient memory) {
        return
            AdditionalRecipient({
                amount: item.amount,
                recipient: item.recipient
            });
    }

    /**
     * @dev Makes a copy of an array of AdditionalRecipients in-memory.
     *
     * @param items the AdditionalRecipients to make a copy of in-memory
     *
     * @custom:return additionalRecipients the copy of the AdditionalRecipients
     */
    function copy(
        AdditionalRecipient[] memory items
    ) internal pure returns (AdditionalRecipient[] memory) {
        AdditionalRecipient[] memory copiedItems = new AdditionalRecipient[](
            items.length
        );
        for (uint256 i = 0; i < items.length; i++) {
            copiedItems[i] = copy(items[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Returns an empty AdditionalRecipient.
     *
     * @custom:return item the empty AdditionalRecipient
     */
    function empty() internal pure returns (AdditionalRecipient memory) {
        return
            AdditionalRecipient({ amount: 0, recipient: payable(address(0)) });
    }

    /**
     * @dev Gets the storage position of the default AdditionalRecipient map.
     *
     * @custom:return additionalRecipientMap the storage position of the default
     *                                       AdditionalRecipient map
     */
    function _additionalRecipientMap()
        private
        pure
        returns (
            mapping(string => AdditionalRecipient)
                storage additionalRecipientMap
        )
    {
        bytes32 position = ADDITIONAL_RECIPIENT_MAP_POSITION;
        assembly {
            additionalRecipientMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default AdditionalRecipients array
     *      map.
     *
     * @custom:return additionalRecipientsMap the storage position of the
     *                                        default AdditionalRecipient array
     *                                        map
     */
    function _additionalRecipientsMap()
        private
        pure
        returns (
            mapping(string => AdditionalRecipient[])
                storage additionalRecipientsMap
        )
    {
        bytes32 position = ADDITIONAL_RECIPIENTS_MAP_POSITION;
        assembly {
            additionalRecipientsMap.slot := position
        }
    }

    // Methods for configuring a single of each of an AdditionalRecipient's
    // fields, which modify the AdditionalRecipient in-place and return it.

    /**
     * @dev Sets the amount field of an AdditionalRecipient.
     *
     * @param item   the AdditionalRecipient to modify
     * @param amount the amount to set
     *
     * @custom:return _item the modified AdditionalRecipient
     */
    function withAmount(
        AdditionalRecipient memory item,
        uint256 amount
    ) internal pure returns (AdditionalRecipient memory) {
        item.amount = amount;
        return item;
    }

    /**
     * @dev Sets the recipient field of an AdditionalRecipient.
     *
     * @param item      the AdditionalRecipient to modify
     * @param recipient the recipient to set
     *
     * @custom:return _item the modified AdditionalRecipient
     */
    function withRecipient(
        AdditionalRecipient memory item,
        address recipient
    ) internal pure returns (AdditionalRecipient memory) {
        item.recipient = payable(recipient);
        return item;
    }
}
