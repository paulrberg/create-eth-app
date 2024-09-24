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
  
  //SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    ERC20Interface,
    ERC721Interface,
    ERC1155Interface
} from "OpenSea-Seaport/seaport-types/src/interfaces/AbridgedTokenInterfaces.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    ReceivedItem,
    Schema,
    SpentItem,
    ZoneParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType, Side } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    ConsiderationInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ConsiderationInterface.sol";

import {
    ContractOffererInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ContractOffererInterface.sol";
import { OffererZoneFailureReason } from "./OffererZoneFailureReason.sol";

contract HashCalldataContractOfferer is ContractOffererInterface {
    error HashCalldataContractOffererGenerateOrderReverts();
    error HashCalldataContractOffererRatifyOrderReverts();

    error NativeTokenTransferFailed();

    event GenerateOrderDataHash(bytes32 orderHash, bytes32 dataHash);
    event RatifyOrderDataHash(bytes32 orderHash, bytes32 dataHash);

    struct ItemAmountMutation {
        Side side;
        uint256 index;
        uint256 newAmount;
        bytes32 orderHash;
    }

    struct DropItemMutation {
        Side side;
        uint256 index;
        bytes32 orderHash;
    }

    struct ExtraItemMutation {
        Side side;
        ReceivedItem item;
        bytes32 orderHash;
    }

    ItemAmountMutation[] public itemAmountMutations;
    DropItemMutation[] public dropItemMutations;
    ExtraItemMutation[] public extraItemMutations;

    mapping(bytes32 => OffererZoneFailureReason) public failureReasons;

    address private _SEAPORT;
    address internal _expectedOfferRecipient;

    mapping(bytes32 => bytes32) public orderHashToGenerateOrderDataHash;
    mapping(bytes32 => bytes32) public orderHashToRatifyOrderDataHash;

    function setFailureReason(
        bytes32 orderHash,
        OffererZoneFailureReason newFailureReason
    ) external {
        failureReasons[orderHash] = newFailureReason;
    }

    function addItemAmountMutation(
        Side side,
        uint256 index,
        uint256 newAmount,
        bytes32 orderHash
    ) external {
        // TODO: add safety checks to ensure that item is in range
        // and that any failure-inducing mutations have the correct
        // failure reason appropriately set

        itemAmountMutations.push(
            ItemAmountMutation(side, index, newAmount, orderHash)
        );
    }

    function addDropItemMutation(
        Side side,
        uint256 index,
        bytes32 orderHash
    ) external {
        // TODO: add safety checks to ensure that item is in range
        // and that any failure-inducing mutations have the correct
        // failure reason appropriately set; also should consider
        // modifying existing indices in other mutations

        dropItemMutations.push(DropItemMutation(side, index, orderHash));
    }

    function addExtraItemMutation(
        Side side,
        ReceivedItem calldata item,
        bytes32 orderHash
    ) external {
        // TODO: add safety checks to ensure that a failure-inducing
        // mutation has the correct failure reason appropriately set

        extraItemMutations.push(ExtraItemMutation(side, item, orderHash));
    }

    function applyItemAmountMutation(
        SpentItem[] memory offer,
        ReceivedItem[] memory consideration,
        ItemAmountMutation memory mutation
    ) internal pure returns (SpentItem[] memory, ReceivedItem[] memory) {
        if (mutation.side == Side.OFFER && offer.length > mutation.index) {
            offer[mutation.index].amount = mutation.newAmount;
        } else if (consideration.length > mutation.index) {
            consideration[mutation.index].amount = mutation.newAmount;
        }
        return (offer, consideration);
    }

    function applyDropItemMutation(
        SpentItem[] memory offer,
        ReceivedItem[] memory consideration,
        DropItemMutation memory mutation
    )
        internal
        pure
        returns (
            SpentItem[] memory _offer,
            ReceivedItem[] memory _consideration
        )
    {
        if (mutation.side == Side.OFFER) {
            _offer = dropIndex(offer, mutation.index);
            _consideration = consideration;
        } else {
            _offer = offer;
            _consideration = _cast(
                dropIndex(_cast(consideration), mutation.index)
            );
        }
    }

    function dropIndex(
        SpentItem[] memory items,
        uint256 index
    ) internal pure returns (SpentItem[] memory newItems) {
        newItems = new SpentItem[](items.length - 1);
        uint256 newIndex = 0;
        uint256 originalLength = items.length;
        for (uint256 i = 0; i < originalLength; i++) {
            if (i != index) {
                newItems[newIndex] = items[i];
                newIndex++;
            }
        }
    }

    function _cast(
        ReceivedItem[] memory items
    ) internal pure returns (SpentItem[] memory _items) {
        assembly {
            _items := items
        }
    }

    function _cast(
        SpentItem[] memory items
    ) internal pure returns (ReceivedItem[] memory _items) {
        assembly {
            _items := items
        }
    }

    function applyExtraItemMutation(
        SpentItem[] memory offer,
        ReceivedItem[] memory consideration,
        ExtraItemMutation memory mutation
    )
        internal
        pure
        returns (
            SpentItem[] memory _offer,
            ReceivedItem[] memory _consideration
        )
    {
        if (mutation.side == Side.OFFER) {
            _offer = _cast(appendItem(_cast(offer), mutation.item));
            _consideration = consideration;
        } else {
            _offer = offer;
            _consideration = appendItem(consideration, mutation.item);
        }
    }

    function appendItem(
        ReceivedItem[] memory items,
        ReceivedItem memory item
    ) internal pure returns (ReceivedItem[] memory newItems) {
        newItems = new ReceivedItem[](items.length + 1);
        for (uint256 i = 0; i < items.length; i++) {
            newItems[i] = items[i];
        }
        newItems[items.length] = item;
    }

    receive() external payable {}

    constructor(address seaport) {
        _SEAPORT = seaport;
    }

    /**
     * @dev Generates an order with the specified minimum and maximum spent
     *      items. Validates data hash set in activate.
     */
    function generateOrder(
        address fulfiller,
        SpentItem[] calldata a,
        SpentItem[] calldata b,
        bytes calldata c
    )
        external
        virtual
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        uint256 contractOffererNonce = ConsiderationInterface(_SEAPORT)
            .getContractOffererNonce(address(this));

        bytes32 orderHash = bytes32(
            contractOffererNonce ^ (uint256(uint160(address(this))) << 96)
        );

        if (
            failureReasons[orderHash] ==
            OffererZoneFailureReason.ContractOfferer_generateReverts
        ) {
            revert HashCalldataContractOffererGenerateOrderReverts();
        } else if (
            failureReasons[orderHash] ==
            OffererZoneFailureReason
                .ContractOfferer_generateReturnsInvalidEncoding
        ) {
            assembly {
                mstore(0, 0x12345678)
                return(0, 0x20)
            }
        }

        {
            // Create a variable to store msg.data in memory
            bytes memory data = new bytes(msg.data.length);

            // Copy msg.data to memory
            assembly {
                calldatacopy(add(data, 0x20), 0, calldatasize())
            }

            bytes32 calldataHash = keccak256(data);

            // Store the hash of msg.data
            orderHashToGenerateOrderDataHash[orderHash] = calldataHash;

            emit GenerateOrderDataHash(orderHash, calldataHash);
        }

        (offer, consideration) = previewOrder(msg.sender, fulfiller, a, b, c);

        (bool success, ) = payable(_SEAPORT).call{
            value: _getOfferedNativeTokens(offer)
        }("");

        if (!success) {
            revert NativeTokenTransferFailed();
        }
    }

    /**
     * @dev View function to preview an order generated in response to a minimum
     *      set of received items, maximum set of spent items, and context
     *      (supplied as extraData).
     */
    function previewOrder(
        address caller,
        address,
        SpentItem[] calldata a,
        SpentItem[] calldata b,
        bytes calldata
    )
        public
        view
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        require(
            caller == _SEAPORT,
            "HashCalldataContractOfferer: caller not seaport"
        );

        uint256 contractOffererNonce = ConsiderationInterface(_SEAPORT)
            .getContractOffererNonce(address(this));

        bytes32 orderHash = bytes32(
            contractOffererNonce ^ (uint256(uint160(address(this))) << 96)
        );

        (offer, consideration) = (a, _convertSpentToReceived(b));

        for (uint256 i; i < itemAmountMutations.length; i++) {
            if (itemAmountMutations[i].orderHash == orderHash) {
                (offer, consideration) = applyItemAmountMutation(
                    offer,
                    consideration,
                    itemAmountMutations[i]
                );
            }
        }
        for (uint256 i; i < extraItemMutations.length; i++) {
            if (extraItemMutations[i].orderHash == orderHash) {
                (offer, consideration) = applyExtraItemMutation(
                    offer,
                    consideration,
                    extraItemMutations[i]
                );
            }
        }
        for (uint256 i; i < dropItemMutations.length; i++) {
            if (dropItemMutations[i].orderHash == orderHash) {
                (offer, consideration) = applyDropItemMutation(
                    offer,
                    consideration,
                    dropItemMutations[i]
                );
            }
        }

        return (offer, consideration);
    }

    /**
     * @dev Ratifies that the parties have received the correct items.
     *
     * @custom:param minimumReceived The minimum items that the caller was
     *                               willing to receive.
     * @custom:param maximumSpent    The maximum items that the caller was
     *                               willing to spend.
     * @custom:param context         The context of the order.
     * @custom:param orderHashes     The order hashes, unused here.
     * @custom:param contractNonce   The contract nonce, unused here.
     *
     * @return ratifyOrderMagicValue The magic value to indicate things are OK.
     */
    function ratifyOrder(
        SpentItem[] calldata /* minimumReceived */,
        ReceivedItem[] calldata /* maximumSpent */,
        bytes calldata /* context */,
        bytes32[] calldata /* orderHashes */,
        uint256 contractNonce
    ) external override returns (bytes4 /* ratifyOrderMagicValue */) {
        require(
            msg.sender == _SEAPORT,
            "HashCalldataContractOfferer: ratify caller not seaport"
        );

        bytes32 orderHash = bytes32(
            contractNonce ^ (uint256(uint160(address(this))) << 96)
        );

        if (
            failureReasons[orderHash] ==
            OffererZoneFailureReason.ContractOfferer_ratifyReverts
        ) {
            revert HashCalldataContractOffererRatifyOrderReverts();
        }

        // Ratify the order.
        {
            // Create a variable to store msg.data in memory
            bytes memory data = new bytes(msg.data.length);

            // Copy msg.data to memory
            assembly {
                calldatacopy(add(data, 0x20), 0, calldatasize())
            }

            bytes32 calldataHash = keccak256(data);

            // Store the hash of msg.data
            orderHashToRatifyOrderDataHash[orderHash] = calldataHash;

            emit RatifyOrderDataHash(orderHash, calldataHash);
        }

        if (
            failureReasons[orderHash] ==
            OffererZoneFailureReason.ContractOfferer_InvalidMagicValue
        ) {
            return bytes4(0x12345678);
        } else {
            // Return the selector of ratifyOrder as the magic value.
            return this.ratifyOrder.selector;
        }
    }

    /**
     * @dev Allows us to set Seaport address following deployment.
     *
     * @param seaportAddress The Seaport address.
     */
    function setSeaportAddress(address seaportAddress) external {
        _SEAPORT = seaportAddress;
    }

    function getSeaportMetadata()
        external
        pure
        override(ContractOffererInterface)
        returns (string memory name, Schema[] memory schemas)
    {
        // Return the metadata.
        name = "TestCalldataHashContractOfferer";
        schemas = new Schema[](1);
        schemas[0].id = 1337;
        schemas[0].metadata = new bytes(0);
    }

    function _convertSpentToReceived(
        SpentItem[] calldata spentItems
    ) internal view returns (ReceivedItem[] memory) {
        ReceivedItem[] memory receivedItems = new ReceivedItem[](
            spentItems.length
        );
        for (uint256 i = 0; i < spentItems.length; ++i) {
            receivedItems[i] = _convertSpentToReceived(spentItems[i]);
        }
        return receivedItems;
    }

    function _convertSpentToReceived(
        SpentItem calldata spentItem
    ) internal view returns (ReceivedItem memory) {
        return
            ReceivedItem({
                itemType: spentItem.itemType,
                token: spentItem.token,
                identifier: spentItem.identifier,
                amount: spentItem.amount,
                recipient: payable(address(this))
            });
    }

    function _getOfferedNativeTokens(
        SpentItem[] memory offer
    ) internal pure returns (uint256 amount) {
        for (uint256 i = 0; i < offer.length; ++i) {
            SpentItem memory item = offer[i];
            if (item.itemType == ItemType.NATIVE) {
                amount += item.amount;
            }
        }
    }

    /**
     * @dev Enable accepting ERC1155 tokens via safeTransfer.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ContractOffererInterface) returns (bool) {
        return interfaceId == type(ContractOffererInterface).interfaceId;
    }

    function setExpectedOfferRecipient(address expectedOfferRecipient) public {
        _expectedOfferRecipient = expectedOfferRecipient;
    }
}
