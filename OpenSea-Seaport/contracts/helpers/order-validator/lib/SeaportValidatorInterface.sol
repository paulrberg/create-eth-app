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
pragma solidity ^0.8.10;

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";
import {
    Order,
    OrderParameters,
    ZoneParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";
import { ErrorsAndWarnings } from "./ErrorsAndWarnings.sol";
import { ValidationConfiguration } from "./SeaportValidatorTypes.sol";

/**
 * @title SeaportValidator
 * @notice SeaportValidator validates simple orders that adhere to a set of rules defined below:
 *    - The order is either a listing or an offer order (one NFT to buy or one NFT to sell).
 *    - The first consideration is the primary consideration.
 *    - The order pays up to two fees in the fungible token currency. First fee is primary fee, second is creator fee.
 *    - In private orders, the last consideration specifies a recipient for the offer item.
 *    - Offer items must be owned and properly approved by the offerer.
 *    - Consideration items must exist.
 */
interface SeaportValidatorInterface {
    /**
     * @notice Conduct a comprehensive validation of the given order.
     * @param order The order to validate.
     * @return errorsAndWarnings The errors and warnings found in the order.
     */
    function isValidOrder(
        Order calldata order,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Same as `isValidOrder` but allows for more configuration related to fee validation.
     */
    function isValidOrderWithConfiguration(
        ValidationConfiguration memory validationConfiguration,
        Order memory order
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Checks if a conduit key is valid.
     * @param conduitKey The conduit key to check.
     * @return errorsAndWarnings The errors and warnings
     */
    function isValidConduit(
        bytes32 conduitKey,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    // TODO: Need to add support for order with extra data
    /**
     * @notice Checks that the zone of an order implements the required interface
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function isValidZone(
        OrderParameters memory orderParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    function validateSignature(
        Order memory order,
        address seaportAddress
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings);

    function validateSignatureWithCounter(
        Order memory order,
        uint256 counter,
        address seaportAddress
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Check the time validity of an order
     * @param orderParameters The parameters for the order to validate
     * @param shortOrderDuration The duration of which an order is considered short
     * @param distantOrderExpiration Distant order expiration delta in seconds.
     * @return errorsAndWarnings The Issues and warnings
     */
    function validateTime(
        OrderParameters memory orderParameters,
        uint256 shortOrderDuration,
        uint256 distantOrderExpiration
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate the status of an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOrderStatus(
        OrderParameters memory orderParameters,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate all offer items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOfferItems(
        OrderParameters memory orderParameters,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate all consideration items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItems(
        OrderParameters memory orderParameters,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Strict validation operates under tight assumptions. It validates primary
     *    fee, creator fee, private sale consideration, and overall order format.
     * @dev Only checks first fee recipient provided by CreatorFeeRegistry.
     *    Order of consideration items must be as follows:
     *    1. Primary consideration
     *    2. Primary fee
     *    3. Creator Fee
     *    4. Private sale consideration
     * @param orderParameters The parameters for the order to validate.
     * @param primaryFeeRecipient The primary fee recipient. Set to null address for no primary fee.
     * @param primaryFeeBips The primary fee in BIPs.
     * @param checkCreatorFee Should check for creator fee. If true, creator fee must be present as
     *    according to creator fee engine. If false, must not have creator fee.
     * @return errorsAndWarnings The errors and warnings.
     */
    function validateStrictLogic(
        OrderParameters memory orderParameters,
        address primaryFeeRecipient,
        uint256 primaryFeeBips,
        bool checkCreatorFee
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate a consideration item
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItem(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates the parameters of a consideration item including contract validation
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItemParameters(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates an offer item
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItem(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates the OfferItem parameters. This includes token contract validation
     * @dev OfferItems with criteria are currently not allowed
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemParameters(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates the OfferItem approvals and balances
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemApprovalAndBalance(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Calls validateOrder on the order's zone with the given zoneParameters
     * @param orderParameters The parameters for the order to validate
     * @param zoneParameters The parameters for the zone to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOrderWithZone(
        OrderParameters memory orderParameters,
        ZoneParameters memory zoneParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Gets the approval address for the given conduit key
     * @param conduitKey Conduit key to get approval address for
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function getApprovalAddress(
        bytes32 conduitKey,
        address seaportAddress
    )
        external
        view
        returns (address, ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Safely check that a contract implements an interface
     * @param token The token address to check
     * @param interfaceHash The interface hash to check
     */
    function checkInterface(
        address token,
        bytes4 interfaceHash
    ) external view returns (bool);

    function isPaymentToken(ItemType itemType) external pure returns (bool);

    /*//////////////////////////////////////////////////////////////
                        Merkle Helpers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sorts an array of token ids by the keccak256 hash of the id. Required ordering of ids
     *    for other merkle operations.
     * @param includedTokens An array of included token ids.
     * @return sortedTokens The sorted `includedTokens` array.
     */
    function sortMerkleTokens(
        uint256[] memory includedTokens
    ) external view returns (uint256[] memory sortedTokens);

    /**
     * @notice Creates a merkle root for includedTokens.
     * @dev `includedTokens` must be sorting in strictly ascending order according to the keccak256 hash of the value.
     * @return merkleRoot The merkle root
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleRoot(
        uint256[] memory includedTokens
    )
        external
        view
        returns (
            bytes32 merkleRoot,
            ErrorsAndWarnings memory errorsAndWarnings
        );

    /**
     * @notice Creates a merkle proof for the the targetIndex contained in includedTokens.
     * @dev `targetIndex` is referring to the index of an element in `includedTokens`.
     *    `includedTokens` must be sorting in ascending order according to the keccak256 hash of the value.
     * @return merkleProof The merkle proof
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleProof(
        uint256[] memory includedTokens,
        uint256 targetIndex
    )
        external
        view
        returns (
            bytes32[] memory merkleProof,
            ErrorsAndWarnings memory errorsAndWarnings
        );

    function verifyMerkleProof(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        uint256 valueToProve
    ) external view returns (bool);
}
