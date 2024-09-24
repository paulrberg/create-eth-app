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

import { ItemType } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";
import {
    Order,
    OrderParameters,
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem,
    Schema,
    ZoneParameters
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";
import { ConsiderationTypeHashes } from "./lib/ConsiderationTypeHashes.sol";
import {
    ConsiderationInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ConsiderationInterface.sol";
import {
    ConduitControllerInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ConduitControllerInterface.sol";
import {
    ContractOffererInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ContractOffererInterface.sol";
import { ZoneInterface } from "OpenSea-Seaport/seaport-types/src/interfaces/ZoneInterface.sol";
import {
    GettersAndDerivers
} from "OpenSea-Seaport/seaport-core/src/lib/GettersAndDerivers.sol";
import { SeaportValidatorInterface } from "./lib/SeaportValidatorInterface.sol";
import { ZoneInterface } from "OpenSea-Seaport/seaport-types/src/interfaces/ZoneInterface.sol";
import {
    ERC20Interface,
    ERC721Interface,
    ERC1155Interface
} from "OpenSea-Seaport/seaport-types/src/interfaces/AbridgedTokenInterfaces.sol";
import { IERC165 } from "OpenSea-Seaport/@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC2981 } from "OpenSea-Seaport/@openzeppelin/contracts/interfaces/IERC2981.sol";
import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./lib/ErrorsAndWarnings.sol";
import { SafeStaticCall } from "./lib/SafeStaticCall.sol";
import {
    IssueParser,
    ValidationConfiguration,
    TimeIssue,
    StatusIssue,
    OfferIssue,
    ContractOffererIssue,
    ConsiderationIssue,
    PrimaryFeeIssue,
    ERC721Issue,
    ERC1155Issue,
    ERC20Issue,
    NativeIssue,
    ZoneIssue,
    ConduitIssue,
    CreatorFeeIssue,
    SignatureIssue,
    GenericIssue,
    ConsiderationItemConfiguration
} from "./lib/SeaportValidatorTypes.sol";
import { Verifiers } from "OpenSea-Seaport/seaport-core/src/lib/Verifiers.sol";
import { ReadOnlyOrderValidator } from "./lib/ReadOnlyOrderValidator.sol";
import { SeaportValidatorHelper } from "./lib/SeaportValidatorHelper.sol";

/**
 * @title SeaportValidator
 * @author OpenSea Protocol Team
 * @notice SeaportValidator provides advanced validation to seaport orders.
 */
contract SeaportValidator is
    SeaportValidatorInterface,
    ConsiderationTypeHashes
{
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using SafeStaticCall for address;
    using IssueParser for *;

    /// @notice Cross-chain conduit controller Address
    ConduitControllerInterface private immutable _conduitController;

    SeaportValidatorHelper private immutable _helper;

    ReadOnlyOrderValidator private immutable _readOnlyOrderValidator;

    bytes4 public constant ERC20_INTERFACE_ID = 0x36372b07;

    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;

    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    bytes4 public constant CONTRACT_OFFERER_INTERFACE_ID = 0x1be900b1;

    bytes4 public constant ZONE_INTERFACE_ID = 0x3839be19;

    constructor(
        address readOnlyOrderValidatorAddress,
        address seaportValidatorHelperAddress,
        address conduitControllerAddress
    ) {
        _readOnlyOrderValidator = ReadOnlyOrderValidator(
            readOnlyOrderValidatorAddress
        );
        _helper = SeaportValidatorHelper(seaportValidatorHelperAddress);
        _conduitController = ConduitControllerInterface(
            conduitControllerAddress
        );
    }

    /**
     * @notice Conduct a comprehensive validation of the given order.
     *    `isValidOrder` validates simple orders that adhere to a set of rules defined below:
     *    - The order is either a listing or an offer order (one NFT to buy or one NFT to sell).
     *    - The first consideration is the primary consideration.
     *    - The order pays up to two fees in the fungible token currency. First fee is primary fee, second is creator fee.
     *    - In private orders, the last consideration specifies a recipient for the offer item.
     *    - Offer items must be owned and properly approved by the offerer.
     *    - There must be one offer item
     *    - Consideration items must exist.
     *    - The signature must be valid, or the order must be already validated on chain
     * @param order The order to validate.
     * @return errorsAndWarnings The errors and warnings found in the order.
     */
    function isValidOrder(
        Order calldata order,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        return
            isValidOrderWithConfiguration(
                ValidationConfiguration(
                    seaportAddress,
                    address(0),
                    0,
                    false,
                    false,
                    30 minutes,
                    26 weeks
                ),
                order
            );
    }

    /**
     * @notice Same as `isValidOrder` but allows for more configuration related to fee validation.
     *    If `skipStrictValidation` is set order logic validation is not carried out: fees are not
     *       checked and there may be more than one offer item as well as any number of consideration items.
     */
    function isValidOrderWithConfiguration(
        ValidationConfiguration memory validationConfiguration,
        Order memory order
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Concatenates errorsAndWarnings with the returned errorsAndWarnings
        errorsAndWarnings.concat(
            validateTime(
                order.parameters,
                validationConfiguration.shortOrderDuration,
                validationConfiguration.distantOrderExpiration
            )
        );
        errorsAndWarnings.concat(
            validateOrderStatus(
                order.parameters,
                validationConfiguration.seaport
            )
        );
        errorsAndWarnings.concat(
            validateOfferItems(
                order.parameters,
                validationConfiguration.seaport
            )
        );
        errorsAndWarnings.concat(
            validateConsiderationItems(
                order.parameters,
                validationConfiguration.seaport
            )
        );
        errorsAndWarnings.concat(isValidZone(order.parameters));
        errorsAndWarnings.concat(
            validateSignature(order, validationConfiguration.seaport)
        );

        // Skip strict validation if requested
        if (!validationConfiguration.skipStrictValidation) {
            errorsAndWarnings.concat(
                validateStrictLogic(
                    order.parameters,
                    validationConfiguration.primaryFeeRecipient,
                    validationConfiguration.primaryFeeBips,
                    validationConfiguration.checkCreatorFee
                )
            );
        }
    }

    /**
     * @notice Strict validation operates under tight assumptions. It validates primary
     *    fee, creator fee, private sale consideration, and overall order format.
     * @dev Only checks first fee recipient provided by CreatorFeeEngine.
     *    Order of consideration items must be as follows:
     *    1. Primary consideration
     *    2. Primary fee
     *    3. Creator fee
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
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        return
            _helper.validateStrictLogic(
                orderParameters,
                primaryFeeRecipient,
                primaryFeeBips,
                checkCreatorFee
            );
    }

    /**
     * @notice Checks if a conduit key is valid.
     * @param conduitKey The conduit key to check.
     * @return errorsAndWarnings The errors and warnings
     */
    function isValidConduit(
        bytes32 conduitKey,
        address seaportAddress
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        (, errorsAndWarnings) = getApprovalAddress(conduitKey, seaportAddress);
    }

    /**
     * @notice Checks if the zone of an order is set and implements the EIP165
     *         zone interface
     * @dev To validate the zone call for an order, see validateOrderWithZone
     * @param orderParameters The order parameters to check.
     * @return errorsAndWarnings The errors and warnings
     */
    function isValidZone(
        OrderParameters memory orderParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // If not restricted, zone isn't checked
        if (
            uint8(orderParameters.orderType) < 2 ||
            uint8(orderParameters.orderType) == 4
        ) {
            return errorsAndWarnings;
        }

        if (orderParameters.zone == address(0)) {
            // Zone is not set
            errorsAndWarnings.addError(ZoneIssue.NotSet.parseInt());
            return errorsAndWarnings;
        }

        // Warn if zone is an EOA
        if (address(orderParameters.zone).code.length == 0) {
            errorsAndWarnings.addWarning(ZoneIssue.EOAZone.parseInt());
            return errorsAndWarnings;
        }

        // Check the EIP165 zone interface
        if (!checkInterface(orderParameters.zone, ZONE_INTERFACE_ID)) {
            errorsAndWarnings.addWarning(ZoneIssue.InvalidZone.parseInt());
            return errorsAndWarnings;
        }

        // Check if the zone implements SIP-5
        try ZoneInterface(orderParameters.zone).getSeaportMetadata() {} catch {
            errorsAndWarnings.addWarning(ZoneIssue.InvalidZone.parseInt());
        }
    }

    /**
     * @notice Gets the approval address for the given conduit key
     * @param conduitKey Conduit key to get approval address for
     * @param seaportAddress The Seaport address
     * @return approvalAddress The address to use for approvals
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function getApprovalAddress(
        bytes32 conduitKey,
        address seaportAddress
    )
        public
        view
        returns (address, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Zero conduit key corresponds to seaport
        if (conduitKey == 0) return (seaportAddress, errorsAndWarnings);

        // Pull conduit info from conduitController
        (address conduitAddress, bool exists) = _conduitController.getConduit(
            conduitKey
        );

        // Conduit does not exist
        if (!exists) {
            errorsAndWarnings.addError(ConduitIssue.KeyInvalid.parseInt());
            conduitAddress = address(0); // Don't return invalid conduit
        }

        // Approval address does not have Seaport added as a channel
        if (
            exists &&
            !_conduitController.getChannelStatus(conduitAddress, seaportAddress)
        ) {
            errorsAndWarnings.addError(
                ConduitIssue.MissingSeaportChannel.parseInt()
            );
        }

        return (conduitAddress, errorsAndWarnings);
    }

    /**
     * @notice Validates the signature for the order using the offerer's current counter
     * @dev Will also check if order is validated on chain.
     */
    function validateSignature(
        Order memory order,
        address seaportAddress
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // Pull current counter from seaport
        uint256 currentCounter = ConsiderationInterface(seaportAddress)
            .getCounter(order.parameters.offerer);

        return
            validateSignatureWithCounter(order, currentCounter, seaportAddress);
    }

    /**
     * @notice Validates the signature for the order using the given counter
     * @dev Will also check if order is validated on chain.
     */
    function validateSignatureWithCounter(
        Order memory order,
        uint256 counter,
        address seaportAddress
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Typecast Seaport address to ConsiderationInterface
        ConsiderationInterface seaport = ConsiderationInterface(seaportAddress);

        // Contract orders do not have signatures
        if (uint8(order.parameters.orderType) == 4) {
            errorsAndWarnings.addWarning(
                SignatureIssue.ContractOrder.parseInt()
            );
        }

        // Get current counter for context
        uint256 currentCounter = seaport.getCounter(order.parameters.offerer);

        if (currentCounter > counter) {
            // Counter strictly increases
            errorsAndWarnings.addError(SignatureIssue.LowCounter.parseInt());
            return errorsAndWarnings;
        } else if (currentCounter < counter) {
            // Counter is incremented by random large number
            errorsAndWarnings.addError(SignatureIssue.HighCounter.parseInt());
            return errorsAndWarnings;
        }

        bytes32 orderHash = _deriveOrderHash(order.parameters, counter);

        // Check if order is validated on chain
        (bool isValid, , , ) = seaport.getOrderStatus(orderHash);

        if (isValid) {
            // Shortcut success, valid on chain
            return errorsAndWarnings;
        }

        // Create memory array to pass into validate
        Order[] memory orderArray = new Order[](1);

        // Store order in array
        orderArray[0] = order;

        try
            // Call validate on Seaport
            _readOnlyOrderValidator.canValidate(seaportAddress, orderArray)
        returns (bool success) {
            if (!success) {
                // Call was unsuccessful, so signature is invalid
                errorsAndWarnings.addError(SignatureIssue.Invalid.parseInt());
            }
        } catch {
            if (
                order.parameters.consideration.length !=
                order.parameters.totalOriginalConsiderationItems
            ) {
                // May help diagnose signature issues
                errorsAndWarnings.addWarning(
                    SignatureIssue.OriginalConsiderationItems.parseInt()
                );
            }
            // Call reverted, so signature is invalid
            errorsAndWarnings.addError(SignatureIssue.Invalid.parseInt());
        }
    }

    /**
     * @notice Check that a contract offerer implements the EIP165
     *         contract offerer interface
     * @param contractOfferer The address of the contract offerer
     * @return errorsAndWarnings The errors and warnings
     */
    function validateContractOfferer(
        address contractOfferer
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Check the EIP165 contract offerer interface
        if (!checkInterface(contractOfferer, CONTRACT_OFFERER_INTERFACE_ID)) {
            errorsAndWarnings.addWarning(
                ContractOffererIssue.InvalidContractOfferer.parseInt()
            );
        }

        // Check if the contract offerer implements SIP-5
        try
            ContractOffererInterface(contractOfferer).getSeaportMetadata()
        {} catch {
            errorsAndWarnings.addWarning(
                ContractOffererIssue.InvalidContractOfferer.parseInt()
            );
        }

        return errorsAndWarnings;
    }

    /**
     * @notice Check the time validity of an order
     * @param orderParameters The parameters for the order to validate
     * @param shortOrderDuration The duration of which an order is considered short
     * @param distantOrderExpiration Distant order expiration delta in seconds.
     * @return errorsAndWarnings The errors and warnings
     */
    function validateTime(
        OrderParameters memory orderParameters,
        uint256 shortOrderDuration,
        uint256 distantOrderExpiration
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (orderParameters.endTime <= orderParameters.startTime) {
            // Order duration is zero
            errorsAndWarnings.addError(
                TimeIssue.EndTimeBeforeStartTime.parseInt()
            );
            return errorsAndWarnings;
        }

        if (orderParameters.endTime < block.timestamp) {
            // Order is expired
            errorsAndWarnings.addError(TimeIssue.Expired.parseInt());
            return errorsAndWarnings;
        } else if (
            orderParameters.endTime > block.timestamp + distantOrderExpiration
        ) {
            // Order expires in a long time
            errorsAndWarnings.addWarning(
                TimeIssue.DistantExpiration.parseInt()
            );
        }

        if (orderParameters.startTime > block.timestamp) {
            // Order is not active
            errorsAndWarnings.addWarning(TimeIssue.NotActive.parseInt());
        }

        if (
            orderParameters.endTime -
                (
                    orderParameters.startTime > block.timestamp
                        ? orderParameters.startTime
                        : block.timestamp
                ) <
            shortOrderDuration
        ) {
            // Order has a short duration
            errorsAndWarnings.addWarning(TimeIssue.ShortOrder.parseInt());
        }
    }

    /**
     * @notice Validate the status of an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOrderStatus(
        OrderParameters memory orderParameters,
        address seaportAddress
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Typecast Seaport address to ConsiderationInterface
        ConsiderationInterface seaport = ConsiderationInterface(seaportAddress);

        // Cannot validate status of contract order
        if (uint8(orderParameters.orderType) == 4) {
            errorsAndWarnings.addWarning(StatusIssue.ContractOrder.parseInt());
        }

        // Pull current counter from seaport
        uint256 currentOffererCounter = seaport.getCounter(
            orderParameters.offerer
        );
        // Derive order hash using orderParameters and currentOffererCounter
        bytes32 orderHash = _deriveOrderHash(
            orderParameters,
            currentOffererCounter
        );
        // Get order status from seaport
        (, bool isCancelled, uint256 totalFilled, uint256 totalSize) = seaport
            .getOrderStatus(orderHash);

        if (isCancelled) {
            // Order is cancelled
            errorsAndWarnings.addError(StatusIssue.Cancelled.parseInt());
        }

        if (totalSize > 0 && totalFilled == totalSize) {
            // Order is fully filled
            errorsAndWarnings.addError(StatusIssue.FullyFilled.parseInt());
        }
    }

    /**
     * @notice Validate all offer items for an order. Ensures that
     *         offerer has sufficient balance and approval for each item.
     * @dev Amounts are not summed and verified, just the individual amounts.
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOfferItems(
        OrderParameters memory orderParameters,
        address seaportAddress
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Iterate over each offer item and validate it
        for (uint256 i = 0; i < orderParameters.offer.length; i++) {
            errorsAndWarnings.concat(
                validateOfferItem(orderParameters, i, seaportAddress)
            );

            // Check for duplicate offer item
            OfferItem memory offerItem1 = orderParameters.offer[i];

            for (uint256 j = i + 1; j < orderParameters.offer.length; j++) {
                // Iterate over each remaining offer item
                // (previous items already check with this item)
                OfferItem memory offerItem2 = orderParameters.offer[j];

                // Check if token and id are the same
                if (
                    offerItem1.token == offerItem2.token &&
                    offerItem1.identifierOrCriteria ==
                    offerItem2.identifierOrCriteria
                ) {
                    errorsAndWarnings.addError(
                        OfferIssue.DuplicateItem.parseInt()
                    );
                }
            }
        }

        // You must have an offer item
        if (orderParameters.offer.length == 0) {
            errorsAndWarnings.addWarning(OfferIssue.ZeroItems.parseInt());
        }

        // Warning if there is more than one offer item
        if (orderParameters.offer.length > 1) {
            errorsAndWarnings.addWarning(OfferIssue.MoreThanOneItem.parseInt());
        }
    }

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
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // First validate the parameters (correct amount, contract, etc)
        errorsAndWarnings = validateOfferItemParameters(
            orderParameters,
            offerItemIndex,
            seaportAddress
        );
        if (errorsAndWarnings.hasErrors()) {
            // Only validate approvals and balances if parameters are valid
            return errorsAndWarnings;
        }

        // Validate approvals and balances for the offer item
        errorsAndWarnings.concat(
            validateOfferItemApprovalAndBalance(
                orderParameters,
                offerItemIndex,
                seaportAddress
            )
        );
    }

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
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Get the offer item at offerItemIndex
        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        // Check if start amount and end amount are zero
        if (offerItem.startAmount == 0 && offerItem.endAmount == 0) {
            errorsAndWarnings.addError(OfferIssue.AmountZero.parseInt());
            return errorsAndWarnings;
        }

        // Check that amount velocity is not too high.
        if (
            offerItem.startAmount != offerItem.endAmount &&
            orderParameters.endTime > orderParameters.startTime
        ) {
            // Assign larger and smaller amount values
            (uint256 maxAmount, uint256 minAmount) = offerItem.startAmount >
                offerItem.endAmount
                ? (offerItem.startAmount, offerItem.endAmount)
                : (offerItem.endAmount, offerItem.startAmount);

            uint256 amountDelta = maxAmount - minAmount;
            // delta of time that order exists for
            uint256 timeDelta = orderParameters.endTime -
                orderParameters.startTime;

            // Velocity scaled by 1e10 for precision
            uint256 velocity = (amountDelta * 1e10) / timeDelta;
            // gives velocity percentage in hundredth of a basis points per second in terms of larger value
            uint256 velocityPercentage = velocity / (maxAmount * 1e4);

            // 278 * 60 * 30 ~= 500,000
            if (velocityPercentage > 278) {
                // Over 50% change per 30 min
                errorsAndWarnings.addError(
                    OfferIssue.AmountVelocityHigh.parseInt()
                );
            }
            // Over 50% change per 30 min
            else if (velocityPercentage > 28) {
                // Over 5% change per 30 min
                errorsAndWarnings.addWarning(
                    OfferIssue.AmountVelocityHigh.parseInt()
                );
            }

            // Check for large amount steps
            if (minAmount <= 1e15) {
                errorsAndWarnings.addWarning(
                    OfferIssue.AmountStepLarge.parseInt()
                );
            }
        }

        if (offerItem.itemType == ItemType.ERC721) {
            // ERC721 type requires amounts to be 1
            if (offerItem.startAmount != 1 || offerItem.endAmount != 1) {
                errorsAndWarnings.addError(ERC721Issue.AmountNotOne.parseInt());
            }

            // Check the EIP165 token interface
            if (!checkInterface(offerItem.token, ERC721_INTERFACE_ID)) {
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
            }
        } else if (offerItem.itemType == ItemType.ERC721_WITH_CRITERIA) {
            // Check the EIP165 token interface
            if (!checkInterface(offerItem.token, ERC721_INTERFACE_ID)) {
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
            }

            if (offerItem.startAmount > 1 || offerItem.endAmount > 1) {
                // Require partial fill enabled. Even orderTypes are full
                if (uint8(orderParameters.orderType) % 2 == 0) {
                    errorsAndWarnings.addError(
                        ERC721Issue.CriteriaNotPartialFill.parseInt()
                    );
                }
            }
        } else if (
            offerItem.itemType == ItemType.ERC1155 ||
            offerItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            // Check the EIP165 token interface
            if (!checkInterface(offerItem.token, ERC1155_INTERFACE_ID)) {
                errorsAndWarnings.addError(
                    ERC1155Issue.InvalidToken.parseInt()
                );
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            // ERC20 must have `identifierOrCriteria` be zero
            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ERC20Issue.IdentifierNonZero.parseInt()
                );
            }

            // Validate contract, should return an uint256 if its an ERC20
            if (
                !offerItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.allowance.selector,
                        seaportAddress,
                        seaportAddress
                    ),
                    0
                )
            ) {
                errorsAndWarnings.addError(ERC20Issue.InvalidToken.parseInt());
            }
        } else {
            // Must be native
            // NATIVE must have `token` be zero address
            if (offerItem.token != address(0)) {
                errorsAndWarnings.addError(NativeIssue.TokenAddress.parseInt());
            }

            // NATIVE must have `identifierOrCriteria` be zero
            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    NativeIssue.IdentifierNonZero.parseInt()
                );
            }
        }
    }

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
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // Note: If multiple items are of the same token, token amounts are not summed for validation

        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Get the approval address for the given conduit key
        (
            address approvalAddress,
            ErrorsAndWarnings memory ew
        ) = getApprovalAddress(orderParameters.conduitKey, seaportAddress);
        errorsAndWarnings.concat(ew);

        if (ew.hasErrors()) {
            // Approval address is invalid
            return errorsAndWarnings;
        }

        // Get the offer item at offerItemIndex
        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        if (offerItem.itemType == ItemType.ERC721) {
            ERC721Interface token = ERC721Interface(offerItem.token);

            // Check that offerer owns token
            if (
                !address(token).safeStaticCallAddress(
                    abi.encodeWithSelector(
                        ERC721Interface.ownerOf.selector,
                        offerItem.identifierOrCriteria
                    ),
                    orderParameters.offerer
                )
            ) {
                errorsAndWarnings.addError(ERC721Issue.NotOwner.parseInt());
            }

            // Check for approval via `getApproved`
            if (
                !address(token).safeStaticCallAddress(
                    abi.encodeWithSelector(
                        ERC721Interface.getApproved.selector,
                        offerItem.identifierOrCriteria
                    ),
                    approvalAddress
                )
            ) {
                // Fallback to `isApprovalForAll`
                if (
                    !address(token).safeStaticCallBool(
                        abi.encodeWithSelector(
                            ERC721Interface.isApprovedForAll.selector,
                            orderParameters.offerer,
                            approvalAddress
                        ),
                        true
                    )
                ) {
                    // Not approved
                    errorsAndWarnings.addError(
                        ERC721Issue.NotApproved.parseInt()
                    );
                }
            }
        } else if (offerItem.itemType == ItemType.ERC721_WITH_CRITERIA) {
            ERC721Interface token = ERC721Interface(offerItem.token);

            // Check for approval
            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        ERC721Interface.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                // Not approved
                errorsAndWarnings.addError(ERC721Issue.NotApproved.parseInt());
            }
        } else if (offerItem.itemType == ItemType.ERC1155) {
            ERC1155Interface token = ERC1155Interface(offerItem.token);

            // Check for approval
            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        ERC1155Interface.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                errorsAndWarnings.addError(ERC1155Issue.NotApproved.parseInt());
            }

            // Get min required balance (max(startAmount, endAmount))
            uint256 minBalance = offerItem.startAmount < offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            // Check for sufficient balance
            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC1155Interface.balanceOf.selector,
                        orderParameters.offerer,
                        offerItem.identifierOrCriteria
                    ),
                    minBalance
                )
            ) {
                // Insufficient balance
                errorsAndWarnings.addError(
                    ERC1155Issue.InsufficientBalance.parseInt()
                );
            }
        } else if (offerItem.itemType == ItemType.ERC1155_WITH_CRITERIA) {
            ERC1155Interface token = ERC1155Interface(offerItem.token);

            // Check for approval
            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        ERC1155Interface.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                errorsAndWarnings.addError(ERC1155Issue.NotApproved.parseInt());
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            ERC20Interface token = ERC20Interface(offerItem.token);

            // Get min required balance and approval (max(startAmount, endAmount))
            uint256 minBalanceAndAllowance = offerItem.startAmount <
                offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            // Check allowance
            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.allowance.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    minBalanceAndAllowance
                )
            ) {
                errorsAndWarnings.addError(
                    ERC20Issue.InsufficientAllowance.parseInt()
                );
            }

            // Check balance
            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.balanceOf.selector,
                        orderParameters.offerer
                    ),
                    minBalanceAndAllowance
                )
            ) {
                errorsAndWarnings.addError(
                    ERC20Issue.InsufficientBalance.parseInt()
                );
            }
        } else {
            // Must be native
            // Get min required balance (max(startAmount, endAmount))
            uint256 minBalance = offerItem.startAmount < offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            // Check for sufficient balance
            if (orderParameters.offerer.balance < minBalance) {
                errorsAndWarnings.addError(
                    NativeIssue.InsufficientBalance.parseInt()
                );
            }

            // Native items can not be pulled so warn
            errorsAndWarnings.addWarning(OfferIssue.NativeItem.parseInt());
        }
    }

    /**
     * @notice Validate all consideration items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItems(
        OrderParameters memory orderParameters,
        address seaportAddress
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        return
            _helper.validateConsiderationItems(orderParameters, seaportAddress);
    }

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
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        return
            _helper.validateConsiderationItem(
                orderParameters,
                considerationItemIndex,
                seaportAddress
            );
    }

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
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        return
            _helper.validateConsiderationItemParameters(
                orderParameters,
                considerationItemIndex,
                seaportAddress
            );
    }

    /**
     * @notice Validates the zone call for an order
     * @param orderParameters The order parameters for the order to validate
     * @param zoneParameters The zone parameters for the order to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOrderWithZone(
        OrderParameters memory orderParameters,
        ZoneParameters memory zoneParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Call isValidZone to check if zone is set and implements EIP165
        errorsAndWarnings.concat(isValidZone(orderParameters));

        // Call zone function `validateOrder` with the supplied ZoneParameters
        if (
            !orderParameters.zone.safeStaticCallBytes4(
                abi.encodeWithSelector(
                    ZoneInterface.validateOrder.selector,
                    zoneParameters
                ),
                ZoneInterface.validateOrder.selector
            )
        ) {
            // Call to validateOrder reverted or returned invalid magic value
            errorsAndWarnings.addWarning(ZoneIssue.RejectedOrder.parseInt());
        }
    }

    /**
     * @notice Safely check that a contract implements an interface
     * @param token The token address to check
     * @param interfaceHash The interface hash to check
     */
    function checkInterface(
        address token,
        bytes4 interfaceHash
    ) public view returns (bool) {
        return
            token.safeStaticCallBool(
                abi.encodeWithSelector(
                    IERC165.supportsInterface.selector,
                    interfaceHash
                ),
                true
            );
    }

    function isPaymentToken(ItemType itemType) public pure returns (bool) {
        return itemType == ItemType.NATIVE || itemType == ItemType.ERC20;
    }

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
    ) public view returns (uint256[] memory sortedTokens) {
        // Sort token ids by the keccak256 hash of the id
        return _helper.sortMerkleTokens(includedTokens);
    }

    /**
     * @notice Creates a merkle root for includedTokens.
     * @dev `includedTokens` must be sorting in strictly ascending order according to the keccak256 hash of the value.
     * @return merkleRoot The merkle root
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleRoot(
        uint256[] memory includedTokens
    )
        public
        view
        returns (bytes32 merkleRoot, ErrorsAndWarnings memory errorsAndWarnings)
    {
        return _helper.getMerkleRoot(includedTokens);
    }

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
        public
        view
        returns (
            bytes32[] memory merkleProof,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        return _helper.getMerkleProof(includedTokens, targetIndex);
    }

    /**
     * @notice Verifies a merkle proof for the value to prove and given root and proof.
     * @dev The `valueToProve` is hashed prior to executing the proof verification.
     * @param merkleRoot The root of the merkle tree
     * @param merkleProof The merkle proof
     * @param valueToProve The value to prove
     * @return whether proof is valid
     */
    function verifyMerkleProof(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        uint256 valueToProve
    ) public view returns (bool) {
        return _helper.verifyMerkleProof(merkleRoot, merkleProof, valueToProve);
    }
}
