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
    AdditionalRecipient,
    BasicOrderParameters,
    OrderParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { BasicOrderType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { StructCopier } from "./StructCopier.sol";

import { AdditionalRecipientLib } from "./AdditionalRecipientLib.sol";

/**
 * @title BasicOrderParametersLib
 * @author James Wenzel (emo.eth)
 * @notice BasicOrderParametersLib is a library for managing
 *         BasicOrderParameters structs and arrays. It allows chaining of
 *         functions to make struct creation more readable.
 */
library BasicOrderParametersLib {
    using BasicOrderParametersLib for BasicOrderParameters;
    using AdditionalRecipientLib for AdditionalRecipient[];

    bytes32 private constant BASIC_ORDER_PARAMETERS_MAP_POSITION =
        keccak256("seaport.BasicOrderParametersDefaults");
    bytes32 private constant BASIC_ORDER_PARAMETERS_ARRAY_MAP_POSITION =
        keccak256("seaport.BasicOrderParametersArrayDefaults");
    bytes32 private constant EMPTY_BASIC_ORDER_PARAMETERS =
        keccak256(
            abi.encode(
                BasicOrderParameters({
                    considerationToken: address(0),
                    considerationIdentifier: 0,
                    considerationAmount: 0,
                    offerer: payable(address(0)),
                    zone: address(0),
                    offerToken: address(0),
                    offerIdentifier: 0,
                    offerAmount: 0,
                    basicOrderType: BasicOrderType(0),
                    startTime: 0,
                    endTime: 0,
                    zoneHash: bytes32(0),
                    salt: 0,
                    offererConduitKey: bytes32(0),
                    fulfillerConduitKey: bytes32(0),
                    totalOriginalAdditionalRecipients: 0,
                    additionalRecipients: new AdditionalRecipient[](0),
                    signature: ""
                })
            )
        );

    /**
     * @dev Clears a default BasicOrderParameters from storage.
     *
     * @param basicParameters the BasicOrderParameters to clear
     */
    function clear(BasicOrderParameters storage basicParameters) internal {
        // uninitialized pointers take up no new memory (versus one word for initializing length-0)
        AdditionalRecipient[] memory additionalRecipients;

        basicParameters.considerationToken = address(0);
        basicParameters.considerationIdentifier = 0;
        basicParameters.considerationAmount = 0;
        basicParameters.offerer = payable(address(0));
        basicParameters.zone = address(0);
        basicParameters.offerToken = address(0);
        basicParameters.offerIdentifier = 0;
        basicParameters.offerAmount = 0;
        basicParameters.basicOrderType = BasicOrderType(0);
        basicParameters.startTime = 0;
        basicParameters.endTime = 0;
        basicParameters.zoneHash = bytes32(0);
        basicParameters.salt = 0;
        basicParameters.offererConduitKey = bytes32(0);
        basicParameters.fulfillerConduitKey = bytes32(0);
        basicParameters.totalOriginalAdditionalRecipients = 0;
        StructCopier.setAdditionalRecipients(
            basicParameters.additionalRecipients,
            additionalRecipients
        );
        basicParameters.signature = new bytes(0);
    }

    /**
     * @dev Clears an array of BasicOrderParameters from storage.
     *
     * @param basicParametersArray the name of the default to clear
     */
    function clear(
        BasicOrderParameters[] storage basicParametersArray
    ) internal {
        while (basicParametersArray.length > 0) {
            basicParametersArray[basicParametersArray.length - 1].clear();
            basicParametersArray.pop();
        }
    }

    /**
     * @dev Clears a default BasicOrderParameters from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => BasicOrderParameters)
            storage orderParametersMap = _orderParametersMap();
        BasicOrderParameters storage basicParameters = orderParametersMap[
            defaultName
        ];
        basicParameters.clear();
    }

    /**
     * @dev Creates an empty BasicOrderParameters.
     *
     * @return item the default BasicOrderParameters
     */
    function empty() internal pure returns (BasicOrderParameters memory item) {
        AdditionalRecipient[] memory additionalRecipients;
        item = BasicOrderParameters({
            considerationToken: address(0),
            considerationIdentifier: 0,
            considerationAmount: 0,
            offerer: payable(address(0)),
            zone: address(0),
            offerToken: address(0),
            offerIdentifier: 0,
            offerAmount: 0,
            basicOrderType: BasicOrderType(0),
            startTime: 0,
            endTime: 0,
            zoneHash: bytes32(0),
            salt: 0,
            offererConduitKey: bytes32(0),
            fulfillerConduitKey: bytes32(0),
            totalOriginalAdditionalRecipients: 0,
            additionalRecipients: additionalRecipients,
            signature: new bytes(0)
        });
    }

    /**
     * @dev Gets a default BasicOrderParameters from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the selected default BasicOrderParameters
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (BasicOrderParameters memory item) {
        mapping(string => BasicOrderParameters)
            storage orderParametersMap = _orderParametersMap();
        item = orderParametersMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_BASIC_ORDER_PARAMETERS) {
            revert("Empty BasicOrderParameters selected.");
        }
    }

    /**
     * @dev Gets a default BasicOrderParameters array from storage.
     *
     * @param defaultName the name of the default array for retrieval
     *
     * @return items the selected default BasicOrderParameters array
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (BasicOrderParameters[] memory items) {
        mapping(string => BasicOrderParameters[])
            storage orderParametersArrayMap = _orderParametersArrayMap();
        items = orderParametersArrayMap[defaultName];

        if (items.length == 0) {
            revert("Empty BasicOrderParameters array selected.");
        }
    }

    /**
     * @dev Saves a BasicOrderParameters as a named default.
     *
     * @param orderParameters the BasicOrderParameters to save as a default
     * @param defaultName     the name of the default for retrieval
     *
     * @return _orderParameters the saved BasicOrderParameters
     */
    function saveDefault(
        BasicOrderParameters memory orderParameters,
        string memory defaultName
    ) internal returns (BasicOrderParameters memory _orderParameters) {
        mapping(string => BasicOrderParameters)
            storage orderParametersMap = _orderParametersMap();
        BasicOrderParameters storage destination = orderParametersMap[
            defaultName
        ];
        StructCopier.setBasicOrderParameters(destination, orderParameters);
        return orderParameters;
    }

    /**
     * @dev Saves an BasicOrderParameters array as a named default.
     *
     * @param orderParameters the BasicOrderParameters array to save as a default
     * @param defaultName     the name of the default array for retrieval
     *
     * @return _orderParameters the saved BasicOrderParameters array
     */
    function saveDefaultMany(
        BasicOrderParameters[] memory orderParameters,
        string memory defaultName
    ) internal returns (BasicOrderParameters[] memory _orderParameters) {
        mapping(string => BasicOrderParameters[])
            storage orderParametersArrayMap = _orderParametersArrayMap();
        BasicOrderParameters[] storage destination = orderParametersArrayMap[
            defaultName
        ];
        StructCopier.setBasicOrderParameters(destination, orderParameters);
        return orderParameters;
    }

    /**
     * @dev Makes a copy of an BasicOrderParameters in-memory.
     *
     * @param item the BasicOrderParameters to make a copy of in-memory
     *
     * @return copy the copied BasicOrderParameters
     */
    function copy(
        BasicOrderParameters memory item
    ) internal pure returns (BasicOrderParameters memory) {
        return
            BasicOrderParameters({
                considerationToken: item.considerationToken,
                considerationIdentifier: item.considerationIdentifier,
                considerationAmount: item.considerationAmount,
                offerer: item.offerer,
                zone: item.zone,
                offerToken: item.offerToken,
                offerIdentifier: item.offerIdentifier,
                offerAmount: item.offerAmount,
                basicOrderType: item.basicOrderType,
                startTime: item.startTime,
                endTime: item.endTime,
                zoneHash: item.zoneHash,
                salt: item.salt,
                offererConduitKey: item.offererConduitKey,
                fulfillerConduitKey: item.fulfillerConduitKey,
                totalOriginalAdditionalRecipients: item
                    .totalOriginalAdditionalRecipients,
                additionalRecipients: item.additionalRecipients.copy(),
                signature: item.signature
            });
    }

    /**
     * @dev Gets the storage position of the default BasicOrderParameters map.
     *
     * @return orderParametersMap the storage position of the default
     *                            BasicOrderParameters map
     */
    function _orderParametersMap()
        private
        pure
        returns (
            mapping(string => BasicOrderParameters) storage orderParametersMap
        )
    {
        bytes32 position = BASIC_ORDER_PARAMETERS_MAP_POSITION;
        assembly {
            orderParametersMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default BasicOrderParameters array
     *      map.
     *
     * @return orderParametersArrayMap the storage position of the default
     *                                 BasicOrderParameters array map
     */
    function _orderParametersArrayMap()
        private
        pure
        returns (
            mapping(string => BasicOrderParameters[])
                storage orderParametersArrayMap
        )
    {
        bytes32 position = BASIC_ORDER_PARAMETERS_ARRAY_MAP_POSITION;
        assembly {
            orderParametersArrayMap.slot := position
        }
    }

    // Methods for configuring a single of each of an in-memory
    // BasicOrderParameters's fields, which modify the BasicOrderParameters
    // struct in-memory and return it.

    /**
     * @dev Sets the considerationToken field of a BasicOrderParameters
     *      in-memory.
     *
     * @param item  the BasicOrderParameters to set the considerationToken field
     *              of in-memory.
     * @param value the value to set the considerationToken field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withConsiderationToken(
        BasicOrderParameters memory item,
        address value
    ) internal pure returns (BasicOrderParameters memory) {
        item.considerationToken = value;
        return item;
    }

    /**
     * @dev Sets the considerationIdentifier field of a BasicOrderParameters
     *     in-memory.
     *
     * @param item  the BasicOrderParameters to set the considerationIdentifier
     *              field of in-memory.
     * @param value the value to set the considerationIdentifier field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withConsiderationIdentifier(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.considerationIdentifier = value;
        return item;
    }

    /**
     * @dev Sets the considerationAmount field of a BasicOrderParameters
     *      in-memory.
     *
     * @param item  the BasicOrderParameters to set the considerationAmount field
     *              of in-memory.
     * @param value the value to set the considerationAmount field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withConsiderationAmount(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.considerationAmount = value;
        return item;
    }

    /**
     * @dev Sets the offerer field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the offerer field of
     *              in-memory.
     * @param value the value to set the offerer field of the BasicOrderParameters
     *              to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withOfferer(
        BasicOrderParameters memory item,
        address value
    ) internal pure returns (BasicOrderParameters memory) {
        item.offerer = payable(value);
        return item;
    }

    /**
     * @dev Sets the zone field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the zone field of
     *              in-memory.
     * @param value the value to set the zone field of the BasicOrderParameters
     *              to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withZone(
        BasicOrderParameters memory item,
        address value
    ) internal pure returns (BasicOrderParameters memory) {
        item.zone = value;
        return item;
    }

    /**
     * @dev Sets the offerToken field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the offerToken field of
     *              in-memory.
     * @param value the value to set the offerToken field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withOfferToken(
        BasicOrderParameters memory item,
        address value
    ) internal pure returns (BasicOrderParameters memory) {
        item.offerToken = value;
        return item;
    }

    /**
     * @dev Sets the offerIdentifier field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the offerIdentifier field of
     *              in-memory.
     * @param value the value to set the offerIdentifier field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withOfferIdentifier(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.offerIdentifier = value;
        return item;
    }

    /**
     * @dev Sets the offerAmount field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the offerAmount field of
     *              in-memory.
     * @param value the value to set the offerAmount field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withOfferAmount(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.offerAmount = value;
        return item;
    }

    /**
     * @dev Sets the basicOrderType field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the basicOrderType field of
     *              in-memory.
     * @param value the value to set the basicOrderType field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withBasicOrderType(
        BasicOrderParameters memory item,
        BasicOrderType value
    ) internal pure returns (BasicOrderParameters memory) {
        item.basicOrderType = value;
        return item;
    }

    /**
     * @dev Sets the startTime field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the startTime field of
     *              in-memory.
     * @param value the value to set the startTime field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withStartTime(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.startTime = value;
        return item;
    }

    /**
     * @dev Sets the endTime field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the endTime field of
     *              in-memory.
     * @param value the value to set the endTime field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withEndTime(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.endTime = value;
        return item;
    }

    /**
     * @dev Sets the zoneHash field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the zoneHash field of
     *              in-memory.
     * @param value the value to set the zoneHash field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withZoneHash(
        BasicOrderParameters memory item,
        bytes32 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.zoneHash = value;
        return item;
    }

    /**
     * @dev Sets the salt field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the salt field of
     *              in-memory.
     * @param value the value to set the salt field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withSalt(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.salt = value;
        return item;
    }

    /**
     * @dev Sets the offererConduitKey field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the offererConduitKey field of
     *              in-memory.
     * @param value the value to set the offererConduitKey field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withOffererConduitKey(
        BasicOrderParameters memory item,
        bytes32 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.offererConduitKey = value;
        return item;
    }

    /**
     * @dev Sets the fulfillerConduitKey field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the fulfillerConduitKey field of
     *              in-memory.
     * @param value the value to set the fulfillerConduitKey field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withFulfillerConduitKey(
        BasicOrderParameters memory item,
        bytes32 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.fulfillerConduitKey = value;
        return item;
    }

    /**
     * @dev Sets the totalOriginalAdditionalRecipients field of a
     *      BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the
     *              totalOriginalAdditionalRecipients field of in-memory.
     * @param value the value to set the totalOriginalAdditionalRecipients field
     *              of the BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withTotalOriginalAdditionalRecipients(
        BasicOrderParameters memory item,
        uint256 value
    ) internal pure returns (BasicOrderParameters memory) {
        item.totalOriginalAdditionalRecipients = value;
        return item;
    }

    /**
     * @dev Sets the additionalRecipients field of a BasicOrderParameters
     *      in-memory.
     *
     * @param item  the BasicOrderParameters to set the additionalRecipients
     *              field of in-memory.
     * @param value the value to set the additionalRecipients field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withAdditionalRecipients(
        BasicOrderParameters memory item,
        AdditionalRecipient[] memory value
    ) internal pure returns (BasicOrderParameters memory) {
        item.additionalRecipients = value;
        return item;
    }

    /**
     * @dev Sets the signature field of a BasicOrderParameters in-memory.
     *
     * @param item  the BasicOrderParameters to set the signature field of
     *              in-memory.
     * @param value the value to set the signature field of the
     *              BasicOrderParameters to set in-memory.
     *
     * @custom:return item the modified BasicOrderParameters
     */
    function withSignature(
        BasicOrderParameters memory item,
        bytes memory value
    ) internal pure returns (BasicOrderParameters memory) {
        item.signature = value;
        return item;
    }
}
