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
import { ConsiderationTypeHashes } from "./ConsiderationTypeHashes.sol";
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
import { GettersAndDerivers } from "OpenSea-Seaport/seaport-core/src/lib/GettersAndDerivers.sol";
import {
    SeaportValidatorInterface
} from "../lib/SeaportValidatorInterface.sol";
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
} from "../lib/ErrorsAndWarnings.sol";
import { SafeStaticCall } from "../lib/SafeStaticCall.sol";
import { Murky } from "../lib/Murky.sol";
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
} from "./SeaportValidatorTypes.sol";
import { Verifiers } from "OpenSea-Seaport/seaport-core/src/lib/Verifiers.sol";

/**
 * @title SeaportValidator
 * @author OpenSea Protocol Team
 * @notice SeaportValidatorHelper assists in advanced validation to seaport orders.
 */
contract SeaportValidatorHelper is Murky {
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using SafeStaticCall for address;
    using IssueParser for *;

    /// @notice Ethereum creator fee engine address
    CreatorFeeEngineInterface public immutable creatorFeeEngine;

    bytes4 public constant ERC20_INTERFACE_ID = 0x36372b07;

    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;

    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    constructor() {
        address creatorFeeEngineAddress;
        if (block.chainid == 1 || block.chainid == 31337) {
            creatorFeeEngineAddress = 0x0385603ab55642cb4Dd5De3aE9e306809991804f;
        } else if (block.chainid == 3) {
            // Ropsten
            creatorFeeEngineAddress = 0xFf5A6F7f36764aAD301B7C9E85A5277614Df5E26;
        } else if (block.chainid == 4) {
            // Rinkeby
            creatorFeeEngineAddress = 0x8d17687ea9a6bb6efA24ec11DcFab01661b2ddcd;
        } else if (block.chainid == 5) {
            // Goerli
            creatorFeeEngineAddress = 0xe7c9Cb6D966f76f3B5142167088927Bf34966a1f;
        } else if (block.chainid == 42) {
            // Kovan
            creatorFeeEngineAddress = 0x54D88324cBedfFe1e62c9A59eBb310A11C295198;
        } else if (block.chainid == 137) {
            // Polygon
            creatorFeeEngineAddress = 0x28EdFcF0Be7E86b07493466e7631a213bDe8eEF2;
        } else if (block.chainid == 80001) {
            // Mumbai
            creatorFeeEngineAddress = 0x0a01E11887f727D1b1Cd81251eeEE9BEE4262D07;
        } else {
            // No creator fee engine for this chain
            creatorFeeEngineAddress = address(0);
        }

        creatorFeeEngine = CreatorFeeEngineInterface(creatorFeeEngineAddress);
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
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Check that order matches the required format (listing or offer)
        {
            bool canCheckFee = true;
            // Single offer item and at least one consideration
            if (
                orderParameters.offer.length != 1 ||
                orderParameters.consideration.length == 0
            ) {
                // Not listing or offer, can't check fees
                canCheckFee = false;
            } else if (
                // Can't have both items be fungible
                isPaymentToken(orderParameters.offer[0].itemType) &&
                isPaymentToken(orderParameters.consideration[0].itemType)
            ) {
                // Not listing or offer, can't check fees
                canCheckFee = false;
            } else if (
                // Can't have both items be non-fungible
                !isPaymentToken(orderParameters.offer[0].itemType) &&
                !isPaymentToken(orderParameters.consideration[0].itemType)
            ) {
                // Not listing or offer, can't check fees
                canCheckFee = false;
            }
            if (!canCheckFee) {
                // Does not match required format
                errorsAndWarnings.addError(
                    GenericIssue.InvalidOrderFormat.parseInt()
                );
                return errorsAndWarnings;
            }
        }

        // Validate secondary consideration items (fees)
        (
            uint256 tertiaryConsiderationIndex,
            ErrorsAndWarnings memory errorsAndWarningsLocal
        ) = _validateSecondaryConsiderationItems(
                orderParameters,
                ConsiderationItemConfiguration({
                    primaryFeeRecipient: primaryFeeRecipient,
                    primaryFeeBips: primaryFeeBips,
                    checkCreatorFee: checkCreatorFee
                })
            );

        errorsAndWarnings.concat(errorsAndWarningsLocal);

        // Validate tertiary consideration items if not 0 (0 indicates error).
        // Only if no prior errors
        if (tertiaryConsiderationIndex != 0) {
            errorsAndWarnings.concat(
                _validateTertiaryConsiderationItems(
                    orderParameters,
                    tertiaryConsiderationIndex
                )
            );
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
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // You must have a consideration item
        if (orderParameters.consideration.length == 0) {
            errorsAndWarnings.addWarning(
                ConsiderationIssue.ZeroItems.parseInt()
            );
            return errorsAndWarnings;
        }

        // Declare a boolean to check if offerer is receiving at least
        // one consideration item
        bool offererReceivingAtLeastOneItem = false;

        // Iterate over each consideration item
        for (uint256 i = 0; i < orderParameters.consideration.length; i++) {
            // Validate consideration item
            errorsAndWarnings.concat(
                validateConsiderationItem(orderParameters, i, seaportAddress)
            );

            ConsiderationItem memory considerationItem1 = orderParameters
                .consideration[i];

            // Check if the offerer is the recipient
            if (!offererReceivingAtLeastOneItem) {
                if (considerationItem1.recipient == orderParameters.offerer) {
                    offererReceivingAtLeastOneItem = true;
                }
            }

            // Check for duplicate consideration items
            for (
                uint256 j = i + 1;
                j < orderParameters.consideration.length;
                j++
            ) {
                // Iterate over each remaining consideration item
                // (previous items already check with this item)
                ConsiderationItem memory considerationItem2 = orderParameters
                    .consideration[j];

                // Check if itemType, token, id, and recipient are the same
                if (
                    considerationItem2.itemType ==
                    considerationItem1.itemType &&
                    considerationItem2.token == considerationItem1.token &&
                    considerationItem2.identifierOrCriteria ==
                    considerationItem1.identifierOrCriteria &&
                    considerationItem2.recipient == considerationItem1.recipient
                ) {
                    errorsAndWarnings.addWarning(
                        // Duplicate consideration item, warning
                        ConsiderationIssue.DuplicateItem.parseInt()
                    );
                }
            }
        }

        if (!offererReceivingAtLeastOneItem) {
            // Offerer is not receiving at least one consideration item
            errorsAndWarnings.addWarning(
                ConsiderationIssue.OffererNotReceivingAtLeastOneItem.parseInt()
            );
        }
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
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Validate the consideration item at considerationItemIndex
        errorsAndWarnings.concat(
            validateConsiderationItemParameters(
                orderParameters,
                considerationItemIndex,
                seaportAddress
            )
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
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        ConsiderationItem memory considerationItem = orderParameters
            .consideration[considerationItemIndex];

        // Check if startAmount and endAmount are zero
        if (
            considerationItem.startAmount == 0 &&
            considerationItem.endAmount == 0
        ) {
            errorsAndWarnings.addError(
                ConsiderationIssue.AmountZero.parseInt()
            );
            return errorsAndWarnings;
        }

        // Check if the recipient is the null address
        if (considerationItem.recipient == address(0)) {
            errorsAndWarnings.addError(
                ConsiderationIssue.NullRecipient.parseInt()
            );
        }

        if (
            considerationItem.startAmount != considerationItem.endAmount &&
            orderParameters.endTime > orderParameters.startTime
        ) {
            // Check that amount velocity is not too high.
            // Assign larger and smaller amount values
            (uint256 maxAmount, uint256 minAmount) = considerationItem
                .startAmount > considerationItem.endAmount
                ? (considerationItem.startAmount, considerationItem.endAmount)
                : (considerationItem.endAmount, considerationItem.startAmount);

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
                    ConsiderationIssue.AmountVelocityHigh.parseInt()
                );
            }
            // 28 * 60 * 30 ~= 50,000
            else if (velocityPercentage > 28) {
                // Over 5% change per 30 min
                errorsAndWarnings.addWarning(
                    ConsiderationIssue.AmountVelocityHigh.parseInt()
                );
            }

            // Check for large amount steps
            if (minAmount <= 1e15) {
                errorsAndWarnings.addWarning(
                    ConsiderationIssue.AmountStepLarge.parseInt()
                );
            }
        }

        if (considerationItem.itemType == ItemType.ERC721) {
            // ERC721 type requires amounts to be 1
            if (
                considerationItem.startAmount != 1 ||
                considerationItem.endAmount != 1
            ) {
                errorsAndWarnings.addError(ERC721Issue.AmountNotOne.parseInt());
            }

            // Check EIP165 interface
            if (!checkInterface(considerationItem.token, ERC721_INTERFACE_ID)) {
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
                return errorsAndWarnings;
            }

            // Check that token exists
            if (
                !considerationItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC721Interface.ownerOf.selector,
                        considerationItem.identifierOrCriteria
                    ),
                    1
                )
            ) {
                // Token does not exist
                errorsAndWarnings.addError(
                    ERC721Issue.IdentifierDNE.parseInt()
                );
            }
        } else if (
            considerationItem.itemType == ItemType.ERC721_WITH_CRITERIA
        ) {
            // Check EIP165 interface
            if (!checkInterface(considerationItem.token, ERC721_INTERFACE_ID)) {
                // Does not implement required interface
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
            }
        } else if (
            considerationItem.itemType == ItemType.ERC1155 ||
            considerationItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            // Check EIP165 interface
            if (
                !checkInterface(considerationItem.token, ERC1155_INTERFACE_ID)
            ) {
                // Does not implement required interface
                errorsAndWarnings.addError(
                    ERC1155Issue.InvalidToken.parseInt()
                );
            }
        } else if (considerationItem.itemType == ItemType.ERC20) {
            // ERC20 must have `identifierOrCriteria` be zero
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ERC20Issue.IdentifierNonZero.parseInt()
                );
            }

            // Check that it is an ERC20 token. ERC20 will return a uint256
            if (
                !considerationItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.allowance.selector,
                        seaportAddress,
                        seaportAddress
                    ),
                    0
                )
            ) {
                // Not an ERC20 token
                errorsAndWarnings.addError(ERC20Issue.InvalidToken.parseInt());
            }
        } else {
            // Must be native
            // NATIVE must have `token` be zero address
            if (considerationItem.token != address(0)) {
                errorsAndWarnings.addError(NativeIssue.TokenAddress.parseInt());
            }
            // NATIVE must have `identifierOrCriteria` be zero
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    NativeIssue.IdentifierNonZero.parseInt()
                );
            }
        }
    }

    function _validateSecondaryConsiderationItems(
        OrderParameters memory orderParameters,
        ConsiderationItemConfiguration memory config
    )
        internal
        view
        returns (
            uint256 /* tertiaryConsiderationIndex */,
            ErrorsAndWarnings memory /* errorsAndWarnings */
        )
    {
        ErrorsAndWarnings memory errorsAndWarnings = ErrorsAndWarnings(
            new uint16[](0),
            new uint16[](0)
        );

        // Consideration item to hold expected creator fee info
        ConsiderationItem memory creatorFeeConsideration;

        bool primaryFeePresent;

        {
            // non-fungible item address
            address itemAddress;
            // non-fungible item identifier
            uint256 itemIdentifier;
            // fungible item start amount
            uint256 transactionAmountStart;
            // fungible item end amount
            uint256 transactionAmountEnd;

            if (isPaymentToken(orderParameters.offer[0].itemType)) {
                // Offer is an offer. Offer item is fungible and used for fees
                creatorFeeConsideration.itemType = orderParameters
                    .offer[0]
                    .itemType;
                creatorFeeConsideration.token = orderParameters.offer[0].token;
                transactionAmountStart = orderParameters.offer[0].startAmount;
                transactionAmountEnd = orderParameters.offer[0].endAmount;

                // Set non-fungible information for calculating creator fee
                itemAddress = orderParameters.consideration[0].token;
                itemIdentifier = orderParameters
                    .consideration[0]
                    .identifierOrCriteria;
            } else {
                // Offer is an offer. Consideration item is fungible and used for fees
                creatorFeeConsideration.itemType = orderParameters
                    .consideration[0]
                    .itemType;
                creatorFeeConsideration.token = orderParameters
                    .consideration[0]
                    .token;
                transactionAmountStart = orderParameters
                    .consideration[0]
                    .startAmount;
                transactionAmountEnd = orderParameters
                    .consideration[0]
                    .endAmount;

                // Set non-fungible information for calculating creator fees
                itemAddress = orderParameters.offer[0].token;
                itemIdentifier = orderParameters.offer[0].identifierOrCriteria;
            }

            // Store flag if primary fee is present
            primaryFeePresent = false;
            {
                // Calculate primary fee start and end amounts
                uint256 primaryFeeStartAmount = (transactionAmountStart *
                    config.primaryFeeBips) / 10000;
                uint256 primaryFeeEndAmount = (transactionAmountEnd *
                    config.primaryFeeBips) / 10000;

                // Check if primary fee check is desired. Skip if calculated amount is zero.
                if (
                    config.primaryFeeRecipient != address(0) &&
                    (primaryFeeStartAmount > 0 || primaryFeeEndAmount > 0)
                ) {
                    // Ensure primary fee is present
                    if (orderParameters.consideration.length < 2) {
                        errorsAndWarnings.addError(
                            PrimaryFeeIssue.Missing.parseInt()
                        );
                        return (0, errorsAndWarnings);
                    }
                    primaryFeePresent = true;

                    ConsiderationItem memory primaryFeeItem = orderParameters
                        .consideration[1];

                    // Check item type
                    if (
                        primaryFeeItem.itemType !=
                        creatorFeeConsideration.itemType
                    ) {
                        errorsAndWarnings.addError(
                            PrimaryFeeIssue.ItemType.parseInt()
                        );
                        return (0, errorsAndWarnings);
                    }
                    // Check token
                    if (primaryFeeItem.token != creatorFeeConsideration.token) {
                        errorsAndWarnings.addError(
                            PrimaryFeeIssue.Token.parseInt()
                        );
                    }
                    // Check start amount
                    if (primaryFeeItem.startAmount < primaryFeeStartAmount) {
                        errorsAndWarnings.addError(
                            PrimaryFeeIssue.StartAmount.parseInt()
                        );
                    }
                    // Check end amount
                    if (primaryFeeItem.endAmount < primaryFeeEndAmount) {
                        errorsAndWarnings.addError(
                            PrimaryFeeIssue.EndAmount.parseInt()
                        );
                    }
                    // Check recipient
                    if (
                        primaryFeeItem.recipient != config.primaryFeeRecipient
                    ) {
                        errorsAndWarnings.addError(
                            PrimaryFeeIssue.Recipient.parseInt()
                        );
                    }
                }
            }

            // Check creator fee
            (
                creatorFeeConsideration.recipient,
                creatorFeeConsideration.startAmount,
                creatorFeeConsideration.endAmount
            ) = getCreatorFeeInfo(
                itemAddress,
                itemIdentifier,
                transactionAmountStart,
                transactionAmountEnd
            );
        }

        // Flag indicating if creator fee is present in considerations
        bool creatorFeePresent = false;

        // Determine if should check for creator fee
        if (
            creatorFeeConsideration.recipient != address(0) &&
            config.checkCreatorFee &&
            (creatorFeeConsideration.startAmount > 0 ||
                creatorFeeConsideration.endAmount > 0)
        ) {
            // Calculate index of creator fee consideration item
            uint16 creatorFeeConsiderationIndex = primaryFeePresent ? 2 : 1; // 2 if primary fee, ow 1

            // Check that creator fee consideration item exists
            if (
                orderParameters.consideration.length - 1 <
                creatorFeeConsiderationIndex
            ) {
                errorsAndWarnings.addError(CreatorFeeIssue.Missing.parseInt());
                return (0, errorsAndWarnings);
            }

            ConsiderationItem memory creatorFeeItem = orderParameters
                .consideration[creatorFeeConsiderationIndex];

            creatorFeePresent = true;

            // Check type
            if (creatorFeeItem.itemType != creatorFeeConsideration.itemType) {
                errorsAndWarnings.addError(CreatorFeeIssue.ItemType.parseInt());
                return (0, errorsAndWarnings);
            }
            // Check token
            if (creatorFeeItem.token != creatorFeeConsideration.token) {
                errorsAndWarnings.addError(CreatorFeeIssue.Token.parseInt());
            }
            // Check start amount
            if (
                creatorFeeItem.startAmount < creatorFeeConsideration.startAmount
            ) {
                errorsAndWarnings.addError(
                    CreatorFeeIssue.StartAmount.parseInt()
                );
            }
            // Check end amount
            if (creatorFeeItem.endAmount < creatorFeeConsideration.endAmount) {
                errorsAndWarnings.addError(
                    CreatorFeeIssue.EndAmount.parseInt()
                );
            }
            // Check recipient
            if (creatorFeeItem.recipient != creatorFeeConsideration.recipient) {
                errorsAndWarnings.addError(
                    CreatorFeeIssue.Recipient.parseInt()
                );
            }
        }

        // Calculate index of first tertiary consideration item
        uint256 tertiaryConsiderationIndex = 1 +
            (primaryFeePresent ? 1 : 0) +
            (creatorFeePresent ? 1 : 0);

        return (tertiaryConsiderationIndex, errorsAndWarnings);
    }

    /**
     * @notice Internal function for validating all consideration items after the fee items.
     *    Only additional acceptable consideration is private sale.
     */
    function _validateTertiaryConsiderationItems(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) internal pure returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (orderParameters.consideration.length <= considerationItemIndex) {
            // No more consideration items
            return errorsAndWarnings;
        }

        ConsiderationItem memory privateSaleConsideration = orderParameters
            .consideration[considerationItemIndex];

        // Check if offer is payment token. Private sale not possible if so.
        if (isPaymentToken(orderParameters.offer[0].itemType)) {
            errorsAndWarnings.addError(
                ConsiderationIssue.ExtraItems.parseInt()
            );
            return errorsAndWarnings;
        }

        // Check if private sale to self
        if (privateSaleConsideration.recipient == orderParameters.offerer) {
            errorsAndWarnings.addError(
                ConsiderationIssue.PrivateSaleToSelf.parseInt()
            );
            return errorsAndWarnings;
        }

        // Ensure that private sale parameters match offer item.
        if (
            privateSaleConsideration.itemType !=
            orderParameters.offer[0].itemType ||
            privateSaleConsideration.token != orderParameters.offer[0].token ||
            orderParameters.offer[0].startAmount !=
            privateSaleConsideration.startAmount ||
            orderParameters.offer[0].endAmount !=
            privateSaleConsideration.endAmount ||
            orderParameters.offer[0].identifierOrCriteria !=
            privateSaleConsideration.identifierOrCriteria
        ) {
            // Invalid private sale, say extra consideration item
            errorsAndWarnings.addError(
                ConsiderationIssue.ExtraItems.parseInt()
            );
            return errorsAndWarnings;
        }

        errorsAndWarnings.addWarning(ConsiderationIssue.PrivateSale.parseInt());

        // Should not be any additional consideration items
        if (orderParameters.consideration.length - 1 > considerationItemIndex) {
            // Extra consideration items
            errorsAndWarnings.addError(
                ConsiderationIssue.ExtraItems.parseInt()
            );
            return errorsAndWarnings;
        }
    }

    /**
     * @notice Fetches the on chain creator fees.
     * @dev Uses the creatorFeeEngine when available, otherwise fallback to `IERC2981`.
     * @param token The token address
     * @param tokenId The token identifier
     * @param transactionAmountStart The transaction start amount
     * @param transactionAmountEnd The transaction end amount
     * @return recipient creator fee recipient
     * @return creatorFeeAmountStart creator fee start amount
     * @return creatorFeeAmountEnd creator fee end amount
     */
    function getCreatorFeeInfo(
        address token,
        uint256 tokenId,
        uint256 transactionAmountStart,
        uint256 transactionAmountEnd
    )
        public
        view
        returns (
            address payable recipient,
            uint256 creatorFeeAmountStart,
            uint256 creatorFeeAmountEnd
        )
    {
        // Check if creator fee engine is on this chain
        if (address(creatorFeeEngine) != address(0)) {
            // Creator fee engine may revert if no creator fees are present.
            try
                creatorFeeEngine.getRoyaltyView(
                    token,
                    tokenId,
                    transactionAmountStart
                )
            returns (
                address payable[] memory creatorFeeRecipients,
                uint256[] memory creatorFeeAmountsStart
            ) {
                if (creatorFeeRecipients.length != 0) {
                    // Use first recipient and amount
                    recipient = creatorFeeRecipients[0];
                    creatorFeeAmountStart = creatorFeeAmountsStart[0];
                }
            } catch {
                // Creator fee not found
            }

            // If fees found for start amount, check end amount
            if (recipient != address(0)) {
                // Creator fee engine may revert if no creator fees are present.
                try
                    creatorFeeEngine.getRoyaltyView(
                        token,
                        tokenId,
                        transactionAmountEnd
                    )
                returns (
                    address payable[] memory,
                    uint256[] memory creatorFeeAmountsEnd
                ) {
                    creatorFeeAmountEnd = creatorFeeAmountsEnd[0];
                } catch {}
            }
        } else {
            // Fallback to ERC2981
            {
                // Static call to token using ERC2981
                (bool success, bytes memory res) = token.staticcall(
                    abi.encodeWithSelector(
                        IERC2981.royaltyInfo.selector,
                        tokenId,
                        transactionAmountStart
                    )
                );
                // Check if call succeeded
                if (success) {
                    // Ensure 64 bytes returned
                    if (res.length == 64) {
                        // Decode result and assign recipient and start amount
                        (recipient, creatorFeeAmountStart) = abi.decode(
                            res,
                            (address, uint256)
                        );
                    }
                }
            }

            // Only check end amount if start amount found
            if (recipient != address(0)) {
                // Static call to token using ERC2981
                (bool success, bytes memory res) = token.staticcall(
                    abi.encodeWithSelector(
                        IERC2981.royaltyInfo.selector,
                        tokenId,
                        transactionAmountEnd
                    )
                );
                // Check if call succeeded
                if (success) {
                    // Ensure 64 bytes returned
                    if (res.length == 64) {
                        // Decode result and assign end amount
                        (, creatorFeeAmountEnd) = abi.decode(
                            res,
                            (address, uint256)
                        );
                    }
                }
            }
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
    ) public pure returns (uint256[] memory sortedTokens) {
        // Sort token ids by the keccak256 hash of the id
        return _sortUint256ByHash(includedTokens);
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
        pure
        returns (bytes32 merkleRoot, ErrorsAndWarnings memory errorsAndWarnings)
    {
        (merkleRoot, errorsAndWarnings) = _getRoot(includedTokens);
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
        pure
        returns (
            bytes32[] memory merkleProof,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        (merkleProof, errorsAndWarnings) = _getProof(
            includedTokens,
            targetIndex
        );
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
    ) public pure returns (bool) {
        bytes32 hashedValue = keccak256(abi.encode(valueToProve));

        return _verifyProof(merkleRoot, merkleProof, hashedValue);
    }

    function isPaymentToken(ItemType itemType) public pure returns (bool) {
        return itemType == ItemType.NATIVE || itemType == ItemType.ERC20;
    }
}

interface CreatorFeeEngineInterface {
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}
