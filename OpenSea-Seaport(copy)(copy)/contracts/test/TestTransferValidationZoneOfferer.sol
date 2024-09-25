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

import { ERC165 } from "OpenSea-Seaport/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {
    ReceivedItem,
    Schema,
    SpentItem,
    ZoneParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    ContractOffererInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ContractOffererInterface.sol";

import { ZoneInterface } from "OpenSea-Seaport/seaport-types/src/interfaces/ZoneInterface.sol";

/**
 * @dev This contract is used to validate transfer within the zone/offerer.  Use
 *      the HashValidationZoneOfferer to validate calldata via hashes.
 */
contract TestTransferValidationZoneOfferer is
    ContractOffererInterface,
    ZoneInterface,
    ERC165
{
    error InvalidNativeTokenBalance(
        uint256 expectedBalance,
        uint256 actualBalance,
        address checkedAddress
    );
    error InvalidERC20Balance(
        uint256 expectedBalance,
        uint256 actualBalance,
        address checkedAddress,
        address checkedToken
    );
    error InvalidERC1155Balance(
        uint256 expectedBalance,
        uint256 actualBalance,
        address checkedAddress,
        address checkedToken
    );
    // 0x38fb386a
    error InvalidOwner(
        address expectedOwner,
        address actualOwner,
        address checkedToken,
        uint256 checkedTokenId
    );
    error IncorrectSeaportBalance(
        uint256 expectedBalance,
        uint256 actualBalance
    );
    event ValidateOrderDataHash(bytes32 dataHash);

    receive() external payable {}

    address internal _expectedOfferRecipient;

    mapping(bytes32 => bytes32) public orderHashToValidateOrderDataHash;

    // Pass in the null address to expect the fulfiller.
    constructor(address expectedOfferRecipient) {
        _expectedOfferRecipient = expectedOfferRecipient;
    }

    bool public called = false;
    uint public callCount = 0;

    /**
     * @dev Validates that the parties have received the correct items.
     *
     * @param zoneParameters The zone parameters, including the SpentItem and
     *                       ReceivedItem arrays.
     *
     * @return validOrderMagicValue The magic value to indicate things are OK.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external override returns (bytes4 validOrderMagicValue) {
        // Validate the order.

        // Currently assumes that the balances of all tokens of addresses are
        // zero at the start of the transaction.  Accordingly, take care to
        // use an address in tests that is not pre-populated with tokens.

        // Get the length of msg.data
        uint256 dataLength = msg.data.length;

        // Create a variable to store msg.data in memory
        bytes memory data;

        // Copy msg.data to memory
        assembly {
            let ptr := mload(0x40)
            calldatacopy(add(ptr, 0x20), 0, dataLength)
            mstore(ptr, dataLength)
            data := ptr
        }

        // Get the hash of msg.data
        bytes32 calldataHash = keccak256(data);

        // Get the orderHash from zoneParameters
        bytes32 orderHash = zoneParameters.orderHash;

        // Store callDataHash in orderHashToValidateOrderDataHash
        orderHashToValidateOrderDataHash[orderHash] = calldataHash;

        // Emit a DataHash event with the hash of msg.data
        emit ValidateOrderDataHash(calldataHash);

        // Check if Seaport is empty. This makes sure that we've transferred
        // all native token balance out of Seaport before we do the validation.
        uint256 seaportBalance = address(msg.sender).balance;

        if (seaportBalance > 0) {
            revert IncorrectSeaportBalance(0, seaportBalance);
        }

        // Ensure that the offerer or recipient has received all consideration
        // items.
        _assertValidReceivedItems(zoneParameters.consideration);

        address expectedOfferRecipient = _expectedOfferRecipient == address(0)
            ? zoneParameters.fulfiller
            : _expectedOfferRecipient;

        // Ensure that the expected recipient has received all offer items.
        _assertValidSpentItems(expectedOfferRecipient, zoneParameters.offer);

        // Set the global called flag to true.
        called = true;
        callCount++;

        // Return the selector of validateOrder as the magic value.
        validOrderMagicValue = this.validateOrder.selector;
    }

    /**
     * @dev Generates an order with the specified minimum and maximum spent
     *      items.
     */
    function generateOrder(
        address,
        SpentItem[] calldata a,
        SpentItem[] calldata b,
        bytes calldata c
    )
        external
        virtual
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        return previewOrder(address(this), address(this), a, b, c);
    }

    /**
     * @dev View function to preview an order generated in response to a minimum
     *      set of received items, maximum set of spent items, and context
     *      (supplied as extraData).
     */
    function previewOrder(
        address,
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
        return (a, _convertSpentToReceived(b));
    }

    /**
     * @dev Ratifies that the parties have received the correct items.
     *
     * @param minimumReceived The minimum items that the caller was willing to
     *                        receive.
     * @param maximumSpent    The maximum items that the caller was willing to
     *                        spend.
     * @param context         The context of the order.
     * @ param orderHashes     The order hashes, unused here.
     * @ param contractNonce   The contract nonce, unused here.
     *
     * @return ratifyOrderMagicValue The magic value to indicate things are OK.
     */
    function ratifyOrder(
        SpentItem[] calldata minimumReceived /* offer */,
        ReceivedItem[] calldata maximumSpent /* consideration */,
        bytes calldata context /* context */,
        bytes32[] calldata /* orderHashes */,
        uint256 /* contractNonce */
    ) external override returns (bytes4 /* ratifyOrderMagicValue */) {
        // Ratify the order.
        // Check if Seaport is empty. This makes sure that we've transferred
        // all native token balance out of Seaport before we do the validation.
        uint256 seaportBalance = address(msg.sender).balance;

        if (seaportBalance > 0) {
            revert IncorrectSeaportBalance(0, seaportBalance);
        }

        // Ensure that the offerer or recipient has received all consideration
        // items.
        _assertValidReceivedItems(maximumSpent);

        // It's necessary to pass in either an expected offerer or an address
        // in the context.  If neither is provided, this ternary will revert
        // with a generic, hard-to-debug revert when it tries to slice bytes
        // from the context.
        address expectedOfferRecipient = _expectedOfferRecipient == address(0)
            ? address(bytes20(context[0:20]))
            : _expectedOfferRecipient;

        // Ensure that the expected recipient has received all offer items.
        _assertValidSpentItems(expectedOfferRecipient, minimumReceived);

        // Set the global called flag to true.
        called = true;
        callCount++;

        return this.ratifyOrder.selector;
    }

    function getSeaportMetadata()
        external
        pure
        override(ContractOffererInterface, ZoneInterface)
        returns (string memory name, Schema[] memory schemas)
    {
        // Return the metadata.
        name = "TestTransferValidationZoneOfferer";
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

    function _assertValidReceivedItems(
        ReceivedItem[] calldata receivedItems
    ) internal view {
        address recipient;
        ItemType itemType;
        ReceivedItem memory receivedItem;

        // Iterate over all received items.
        for (uint256 i = 0; i < receivedItems.length; i++) {
            // Check if the consideration item has been received.
            receivedItem = receivedItems[i];
            // Get the recipient of the consideration item.
            recipient = receivedItem.recipient;
            // Get item type.
            itemType = receivedItem.itemType;

            // Check balance/ownerOf depending on item type.
            if (itemType == ItemType.NATIVE) {
                // NATIVE Token
                _assertNativeTokenTransfer(receivedItem.amount, recipient);
            } else if (itemType == ItemType.ERC20) {
                // ERC20 Token
                _assertERC20Transfer(
                    receivedItem.amount,
                    receivedItem.token,
                    recipient
                );
            } else if (itemType == ItemType.ERC721) {
                // ERC721 Token
                _assertERC721Transfer(
                    receivedItem.identifier,
                    receivedItem.token,
                    recipient
                );
            } else if (itemType == ItemType.ERC1155) {
                // ERC1155 Token
                _assertERC1155Transfer(
                    receivedItem.amount,
                    receivedItem.identifier,
                    receivedItem.token,
                    recipient
                );
            }
        }
    }

    function _assertValidSpentItems(
        address expectedRecipient,
        SpentItem[] calldata spentItems
    ) internal view {
        SpentItem memory spentItem;
        ItemType itemType;

        // Iterate over all spent items.
        for (uint256 i = 0; i < spentItems.length; i++) {
            // Check if the offer item has been spent.
            spentItem = spentItems[i];
            // Get item type.
            itemType = spentItem.itemType;

            // Check balance/ownerOf depending on item type.
            if (itemType == ItemType.NATIVE) {
                // NATIVE Token
                _assertNativeTokenTransfer(spentItem.amount, expectedRecipient);
            } else if (itemType == ItemType.ERC20) {
                // ERC20 Token
                _assertERC20Transfer(
                    spentItem.amount,
                    spentItem.token,
                    expectedRecipient
                );
            } else if (itemType == ItemType.ERC721) {
                // ERC721 Token
                _assertERC721Transfer(
                    spentItem.identifier,
                    spentItem.token,
                    expectedRecipient
                );
            } else if (itemType == ItemType.ERC1155) {
                // ERC1155 Token
                _assertERC1155Transfer(
                    spentItem.amount,
                    spentItem.identifier,
                    spentItem.token,
                    expectedRecipient
                );
            }
        }
    }

    function _assertNativeTokenTransfer(
        uint256 expectedAmount,
        address expectedRecipient
    ) internal view {
        // If the amount we read from the spent item or received item (the
        // expected transfer value) is greater than the balance of the expected
        // recipient then revert, because that means the recipient did not
        // receive the expected amount at the time the order was ratified or
        // validated.
        if (expectedAmount > address(expectedRecipient).balance) {
            revert InvalidNativeTokenBalance(
                expectedAmount,
                address(expectedRecipient).balance,
                expectedRecipient
            );
        }
    }

    function _assertERC20Transfer(
        uint256 expectedAmount,
        address token,
        address expectedRecipient
    ) internal view {
        // If the amount we read from the spent item or received item (the
        // expected transfer value) is greater than the balance of the expected
        // recipient, revert.
        if (
            expectedAmount > ERC20Interface(token).balanceOf(expectedRecipient)
        ) {
            revert InvalidERC20Balance(
                expectedAmount,
                ERC20Interface(token).balanceOf(expectedRecipient),
                expectedRecipient,
                token
            );
        }
    }

    function _assertERC721Transfer(
        uint256 checkedTokenId,
        address token,
        address expectedRecipient
    ) internal view {
        // If the actual owner of the token is not the expected recipient,
        // revert.
        address actualOwner = ERC721Interface(token).ownerOf(checkedTokenId);
        if (expectedRecipient != actualOwner) {
            revert InvalidOwner(
                expectedRecipient,
                actualOwner,
                token,
                checkedTokenId
            );
        }
    }

    function _assertERC1155Transfer(
        uint256 expectedAmount,
        uint256 identifier,
        address token,
        address expectedRecipient
    ) internal view {
        // If the amount we read from the spent item or received item (the
        // expected transfer value) is greater than the balance of the expected
        // recipient, revert.
        if (
            expectedAmount >
            ERC1155Interface(token).balanceOf(expectedRecipient, identifier)
        ) {
            revert InvalidERC1155Balance(
                expectedAmount,
                ERC1155Interface(token).balanceOf(
                    expectedRecipient,
                    identifier
                ),
                expectedRecipient,
                token
            );
        }
    }

    function setExpectedOfferRecipient(address expectedOfferRecipient) public {
        _expectedOfferRecipient = expectedOfferRecipient;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165, ContractOffererInterface, ZoneInterface)
        returns (bool)
    {
        return
            interfaceId == type(ContractOffererInterface).interfaceId ||
            interfaceId == type(ZoneInterface).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
