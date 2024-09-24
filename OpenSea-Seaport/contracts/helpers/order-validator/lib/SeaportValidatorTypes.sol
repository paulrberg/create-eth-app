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

struct ValidationConfiguration {
    /// @notice The seaport address.
    address seaport;
    /// @notice Recipient for primary fee payments.
    address primaryFeeRecipient;
    /// @notice Bips for primary fee payments.
    uint256 primaryFeeBips;
    /// @notice Should creator fees be checked?
    bool checkCreatorFee;
    /// @notice Should strict validation be skipped?
    bool skipStrictValidation;
    /// @notice Short order duration in seconds
    uint256 shortOrderDuration;
    /// @notice Distant order expiration delta in seconds. Warning if order expires in longer than this.
    uint256 distantOrderExpiration;
}

struct ConsiderationItemConfiguration {
    address primaryFeeRecipient;
    uint256 primaryFeeBips;
    bool checkCreatorFee;
}

enum GenericIssue {
    InvalidOrderFormat // 100
}

enum ERC20Issue {
    IdentifierNonZero, // 200
    InvalidToken, // 201
    InsufficientAllowance, // 202
    InsufficientBalance // 203
}

enum ERC721Issue {
    AmountNotOne, // 300
    InvalidToken, // 301
    IdentifierDNE, // 302
    NotOwner, // 303
    NotApproved, // 304
    CriteriaNotPartialFill // 305
}

enum ERC1155Issue {
    InvalidToken, // 400
    NotApproved, // 401
    InsufficientBalance // 402
}

enum ConsiderationIssue {
    AmountZero, // 500
    NullRecipient, // 501
    ExtraItems, // 502
    PrivateSaleToSelf, // 503
    ZeroItems, // 504
    DuplicateItem, // 505
    OffererNotReceivingAtLeastOneItem, // 506
    PrivateSale, // 507
    AmountVelocityHigh, // 508
    AmountStepLarge // 509
}

enum OfferIssue {
    ZeroItems, // 600
    AmountZero, // 601
    MoreThanOneItem, // 602
    NativeItem, // 603
    DuplicateItem, // 604
    AmountVelocityHigh, // 605
    AmountStepLarge // 606
}

enum PrimaryFeeIssue {
    Missing, // 700
    ItemType, // 701
    Token, // 702
    StartAmount, // 703
    EndAmount, // 704
    Recipient // 705
}

enum StatusIssue {
    Cancelled, // 800
    FullyFilled, // 801
    ContractOrder // 802
}

enum TimeIssue {
    EndTimeBeforeStartTime, // 900
    Expired, // 901
    DistantExpiration, // 902
    NotActive, // 903
    ShortOrder // 904
}

enum ConduitIssue {
    KeyInvalid, // 1000
    MissingSeaportChannel // 1001
}

enum SignatureIssue {
    Invalid, // 1100
    ContractOrder, // 1101
    LowCounter, // 1102
    HighCounter, // 1103
    OriginalConsiderationItems // 1104
}

enum CreatorFeeIssue {
    Missing, // 1200
    ItemType, // 1201
    Token, // 1202
    StartAmount, // 1203
    EndAmount, // 1204
    Recipient // 1205
}

enum NativeIssue {
    TokenAddress, // 1300
    IdentifierNonZero, // 1301
    InsufficientBalance // 1302
}

enum ZoneIssue {
    InvalidZone, // 1400
    RejectedOrder, // 1401
    NotSet, // 1402
    EOAZone // 1403
}

enum MerkleIssue {
    SingleLeaf, // 1500
    Unsorted // 1501
}

enum ContractOffererIssue {
    InvalidContractOfferer // 1600
}

/**
 * @title IssueParser - parse issues into integers
 * @notice Implements a `parseInt` function for each issue type.
 *    offsets the enum value to place within the issue range.
 */
library IssueParser {
    function parseInt(GenericIssue err) internal pure returns (uint16) {
        return uint16(err) + 100;
    }

    function parseInt(ERC20Issue err) internal pure returns (uint16) {
        return uint16(err) + 200;
    }

    function parseInt(ERC721Issue err) internal pure returns (uint16) {
        return uint16(err) + 300;
    }

    function parseInt(ERC1155Issue err) internal pure returns (uint16) {
        return uint16(err) + 400;
    }

    function parseInt(ConsiderationIssue err) internal pure returns (uint16) {
        return uint16(err) + 500;
    }

    function parseInt(OfferIssue err) internal pure returns (uint16) {
        return uint16(err) + 600;
    }

    function parseInt(PrimaryFeeIssue err) internal pure returns (uint16) {
        return uint16(err) + 700;
    }

    function parseInt(StatusIssue err) internal pure returns (uint16) {
        return uint16(err) + 800;
    }

    function parseInt(TimeIssue err) internal pure returns (uint16) {
        return uint16(err) + 900;
    }

    function parseInt(ConduitIssue err) internal pure returns (uint16) {
        return uint16(err) + 1000;
    }

    function parseInt(SignatureIssue err) internal pure returns (uint16) {
        return uint16(err) + 1100;
    }

    function parseInt(CreatorFeeIssue err) internal pure returns (uint16) {
        return uint16(err) + 1200;
    }

    function parseInt(NativeIssue err) internal pure returns (uint16) {
        return uint16(err) + 1300;
    }

    function parseInt(ZoneIssue err) internal pure returns (uint16) {
        return uint16(err) + 1400;
    }

    function parseInt(MerkleIssue err) internal pure returns (uint16) {
        return uint16(err) + 1500;
    }

    function parseInt(ContractOffererIssue err) internal pure returns (uint16) {
        return uint16(err) + 1600;
    }
}

library IssueStringHelpers {
    function toString(GenericIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == GenericIssue.InvalidOrderFormat) {
            code = "InvalidOrderFormat";
        }
        return string.concat("GenericIssue: ", code);
    }

    function toString(ERC20Issue id) internal pure returns (string memory) {
        string memory code;
        if (id == ERC20Issue.IdentifierNonZero) {
            code = "IdentifierNonZero";
        } else if (id == ERC20Issue.InvalidToken) {
            code = "InvalidToken";
        } else if (id == ERC20Issue.InsufficientAllowance) {
            code = "InsufficientAllowance";
        } else if (id == ERC20Issue.InsufficientBalance) {
            code = "InsufficientBalance";
        }
        return string.concat("ERC20Issue: ", code);
    }

    function toString(ERC721Issue id) internal pure returns (string memory) {
        string memory code;
        if (id == ERC721Issue.AmountNotOne) {
            code = "AmountNotOne";
        } else if (id == ERC721Issue.InvalidToken) {
            code = "InvalidToken";
        } else if (id == ERC721Issue.IdentifierDNE) {
            code = "IdentifierDNE";
        } else if (id == ERC721Issue.NotOwner) {
            code = "NotOwner";
        } else if (id == ERC721Issue.NotApproved) {
            code = "NotApproved";
        } else if (id == ERC721Issue.CriteriaNotPartialFill) {
            code = "CriteriaNotPartialFill";
        }
        return string.concat("ERC721Issue: ", code);
    }

    function toString(ERC1155Issue id) internal pure returns (string memory) {
        string memory code;
        if (id == ERC1155Issue.InvalidToken) {
            code = "InvalidToken";
        } else if (id == ERC1155Issue.NotApproved) {
            code = "NotApproved";
        } else if (id == ERC1155Issue.InsufficientBalance) {
            code = "InsufficientBalance";
        }
        return string.concat("ERC1155Issue: ", code);
    }

    function toString(
        ConsiderationIssue id
    ) internal pure returns (string memory) {
        string memory code;
        if (id == ConsiderationIssue.AmountZero) {
            code = "AmountZero";
        } else if (id == ConsiderationIssue.NullRecipient) {
            code = "NullRecipient";
        } else if (id == ConsiderationIssue.ExtraItems) {
            code = "ExtraItems";
        } else if (id == ConsiderationIssue.PrivateSaleToSelf) {
            code = "PrivateSaleToSelf";
        } else if (id == ConsiderationIssue.ZeroItems) {
            code = "ZeroItems";
        } else if (id == ConsiderationIssue.DuplicateItem) {
            code = "DuplicateItem";
        } else if (id == ConsiderationIssue.OffererNotReceivingAtLeastOneItem) {
            code = "OffererNotReceivingAtLeastOneItem";
        } else if (id == ConsiderationIssue.PrivateSale) {
            code = "PrivateSale";
        } else if (id == ConsiderationIssue.AmountVelocityHigh) {
            code = "AmountVelocityHigh";
        } else if (id == ConsiderationIssue.AmountStepLarge) {
            code = "AmountStepLarge";
        }
        return string.concat("ConsiderationIssue: ", code);
    }

    function toString(OfferIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == OfferIssue.ZeroItems) {
            code = "ZeroItems";
        } else if (id == OfferIssue.AmountZero) {
            code = "AmountZero";
        } else if (id == OfferIssue.MoreThanOneItem) {
            code = "MoreThanOneItem";
        } else if (id == OfferIssue.NativeItem) {
            code = "NativeItem";
        } else if (id == OfferIssue.DuplicateItem) {
            code = "DuplicateItem";
        } else if (id == OfferIssue.AmountVelocityHigh) {
            code = "AmountVelocityHigh";
        } else if (id == OfferIssue.AmountStepLarge) {
            code = "AmountStepLarge";
        }
        return string.concat("OfferIssue: ", code);
    }

    function toString(
        PrimaryFeeIssue id
    ) internal pure returns (string memory) {
        string memory code;
        if (id == PrimaryFeeIssue.Missing) {
            code = "Missing";
        } else if (id == PrimaryFeeIssue.ItemType) {
            code = "ItemType";
        } else if (id == PrimaryFeeIssue.Token) {
            code = "Token";
        } else if (id == PrimaryFeeIssue.StartAmount) {
            code = "StartAmount";
        } else if (id == PrimaryFeeIssue.EndAmount) {
            code = "EndAmount";
        } else if (id == PrimaryFeeIssue.Recipient) {
            code = "Recipient";
        }
        return string.concat("PrimaryFeeIssue: ", code);
    }

    function toString(StatusIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == StatusIssue.Cancelled) {
            code = "Cancelled";
        } else if (id == StatusIssue.FullyFilled) {
            code = "FullyFilled";
        } else if (id == StatusIssue.ContractOrder) {
            code = "ContractOrder";
        }
        return string.concat("StatusIssue: ", code);
    }

    function toString(TimeIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == TimeIssue.EndTimeBeforeStartTime) {
            code = "EndTimeBeforeStartTime";
        } else if (id == TimeIssue.Expired) {
            code = "Expired";
        } else if (id == TimeIssue.DistantExpiration) {
            code = "DistantExpiration";
        } else if (id == TimeIssue.NotActive) {
            code = "NotActive";
        } else if (id == TimeIssue.ShortOrder) {
            code = "ShortOrder";
        }
        return string.concat("TimeIssue: ", code);
    }

    function toString(ConduitIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == ConduitIssue.KeyInvalid) {
            code = "KeyInvalid";
        } else if (id == ConduitIssue.MissingSeaportChannel) {
            code = "MissingSeaportChannel";
        }
        return string.concat("ConduitIssue: ", code);
    }

    function toString(SignatureIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == SignatureIssue.Invalid) {
            code = "Invalid";
        } else if (id == SignatureIssue.ContractOrder) {
            code = "ContractOrder";
        } else if (id == SignatureIssue.LowCounter) {
            code = "LowCounter";
        } else if (id == SignatureIssue.HighCounter) {
            code = "HighCounter";
        } else if (id == SignatureIssue.OriginalConsiderationItems) {
            code = "OriginalConsiderationItems";
        }
        return string.concat("SignatureIssue: ", code);
    }

    function toString(
        CreatorFeeIssue id
    ) internal pure returns (string memory) {
        string memory code;
        if (id == CreatorFeeIssue.Missing) {
            code = "Missing";
        } else if (id == CreatorFeeIssue.ItemType) {
            code = "ItemType";
        } else if (id == CreatorFeeIssue.Token) {
            code = "Token";
        } else if (id == CreatorFeeIssue.StartAmount) {
            code = "StartAmount";
        } else if (id == CreatorFeeIssue.EndAmount) {
            code = "EndAmount";
        } else if (id == CreatorFeeIssue.Recipient) {
            code = "Recipient";
        }
        return string.concat("CreatorFeeIssue: ", code);
    }

    function toString(NativeIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == NativeIssue.TokenAddress) {
            code = "TokenAddress";
        } else if (id == NativeIssue.IdentifierNonZero) {
            code = "IdentifierNonZero";
        } else if (id == NativeIssue.InsufficientBalance) {
            code = "InsufficientBalance";
        }
        return string.concat("NativeIssue: ", code);
    }

    function toString(ZoneIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == ZoneIssue.InvalidZone) {
            code = "InvalidZone";
        } else if (id == ZoneIssue.RejectedOrder) {
            code = "RejectedOrder";
        } else if (id == ZoneIssue.NotSet) {
            code = "NotSet";
        } else if (id == ZoneIssue.EOAZone) {
            code = "EOAZone";
        }
        return string.concat("ZoneIssue: ", code);
    }

    function toString(MerkleIssue id) internal pure returns (string memory) {
        string memory code;
        if (id == MerkleIssue.SingleLeaf) {
            code = "SingleLeaf";
        } else if (id == MerkleIssue.Unsorted) {
            code = "Unsorted";
        }
        return string.concat("MerkleIssue: ", code);
    }

    function toString(
        ContractOffererIssue id
    ) internal pure returns (string memory) {
        string memory code;
        if (id == ContractOffererIssue.InvalidContractOfferer) {
            code = "InvalidContractOfferer";
        }
        return string.concat("ContractOffererIssue: ", code);
    }

    function toIssueString(
        uint16 issueCode
    ) internal pure returns (string memory issueString) {
        uint16 issue = (issueCode / 100) * 100;
        uint8 id = uint8(issueCode % 100);
        if (issue == 100) {
            return toString(GenericIssue(id));
        } else if (issue == 200) {
            return toString(ERC20Issue(id));
        } else if (issue == 300) {
            return toString(ERC721Issue(id));
        } else if (issue == 400) {
            return toString(ERC1155Issue(id));
        } else if (issue == 500) {
            return toString(ConsiderationIssue(id));
        } else if (issue == 600) {
            return toString(OfferIssue(id));
        } else if (issue == 700) {
            return toString(PrimaryFeeIssue(id));
        } else if (issue == 800) {
            return toString(StatusIssue(id));
        } else if (issue == 900) {
            return toString(TimeIssue(id));
        } else if (issue == 1000) {
            return toString(ConduitIssue(id));
        } else if (issue == 1100) {
            return toString(SignatureIssue(id));
        } else if (issue == 1200) {
            return toString(CreatorFeeIssue(id));
        } else if (issue == 1300) {
            return toString(NativeIssue(id));
        } else if (issue == 1400) {
            return toString(ZoneIssue(id));
        } else if (issue == 1500) {
            return toString(MerkleIssue(id));
        } else if (issue == 1600) {
            return toString(ContractOffererIssue(id));
        } else {
            revert("IssueStringHelpers: Unknown issue code");
        }
    }

    function toIssueString(
        uint16[] memory issueCodes
    ) internal pure returns (string memory issueString) {
        for (uint256 i; i < issueCodes.length; i++) {
            issueString = string.concat(
                issueString,
                "\n    ",
                toIssueString(issueCodes[i])
            );
        }
    }
}
