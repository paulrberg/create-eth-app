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
pragma solidity ^0.8.13;

import {
    ERC721Interface
} from "OpenSea-Seaport/seaport-types/src/interfaces/AbridgedTokenInterfaces.sol";

import {
    ContractOffererInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ContractOffererInterface.sol";

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    ReceivedItem,
    Schema,
    SpentItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

contract TestBadContractOfferer is ContractOffererInterface {
    error IntentionalRevert();

    address private immutable seaport;
    ERC721Interface token;

    constructor(address _seaport, ERC721Interface _token) {
        seaport = _seaport;
        token = _token;
        ERC721Interface(token).setApprovalForAll(seaport, true);
    }

    receive() external payable {}

    /**
     * @dev Generates an order with the specified minimum and maximum spent items,
     * and the optional extra data.
     *
     * @param a               Fulfiller, unused here.
     * @param b               The minimum items that the caller is willing to
     *                        receive.
     * @param c               maximumSent, unused here.
     * @param d               context, unused here.
     *
     * @return offer         A tuple containing the offer items.
     * @return consideration A tuple containing the consideration items.
     */
    function generateOrder(
        address a,
        SpentItem[] calldata b,
        SpentItem[] calldata c,
        bytes calldata d
    )
        external
        virtual
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        return previewOrder(a, a, b, c, d);
    }

    /**
     * @dev View function to preview an order generated in response to a minimum
     *      set of received items, maximum set of spent items, and context
     *      (supplied as extraData).
     *
     * @param -               caller, unused here.
     * @param -               fulfiller, unused here.
     * @param minimumReceived The minimum received set.
     * @param -               maximumSpent, unused here.
     * @param -               context, unused here.
     *
     * @return offer         The offer for the order.
     * @return consideration The consideration for the order.
     */
    function previewOrder(
        address,
        address,
        SpentItem[] calldata minimumReceived,
        SpentItem[] calldata maximumSpent,
        bytes calldata
    )
        public
        view
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {
        if (minimumReceived[0].identifier == 1) {
            offer = minimumReceived;
            consideration = new ReceivedItem[](1);
            consideration[0] = ReceivedItem({
                itemType: ItemType.NATIVE,
                token: address(0),
                identifier: 0,
                amount: 100,
                recipient: payable(address(this))
            });
            return (offer, consideration);
        } else if (minimumReceived[0].identifier == 2) {
            // return nothing
            assembly {
                return(0, 0)
            }
        } else if (minimumReceived[0].identifier == 3) {
            revert IntentionalRevert();
        } else {
            // return garbage
            bytes32 h1 = keccak256(abi.encode(minimumReceived));
            bytes32 h2 = keccak256(abi.encode(maximumSpent));
            assembly {
                mstore(0x00, h1)
                mstore(0x20, h2)
                return(0, 0x100)
            }
        }
    }

    function ratifyOrder(
        SpentItem[] calldata /* offer */,
        ReceivedItem[] calldata /* consideration */,
        bytes calldata /* context */,
        bytes32[] calldata /* orderHashes */,
        uint256 /* contractNonce */
    ) external pure override returns (bytes4 /* ratifyOrderMagicValue */) {
        return TestBadContractOfferer.ratifyOrder.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ContractOffererInterface) returns (bool) {
        return interfaceId == type(ContractOffererInterface).interfaceId;
    }

    /**
     * @dev Returns the metadata for this contract offerer.
     */
    function getSeaportMetadata()
        external
        pure
        override
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        )
    {
        schemas = new Schema[](1);
        schemas[0].id = 1337;
        schemas[0].metadata = new bytes(0);

        return ("TestBadContractOfferer", schemas);
    }
}
