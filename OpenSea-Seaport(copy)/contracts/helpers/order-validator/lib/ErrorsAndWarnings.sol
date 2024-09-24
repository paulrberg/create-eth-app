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

import {
    ConduitIssue,
    ConsiderationIssue,
    ERC20Issue,
    ERC721Issue,
    ERC1155Issue,
    GenericIssue,
    OfferIssue,
    SignatureIssue,
    StatusIssue,
    TimeIssue,
    NativeIssue,
    IssueParser
} from "./SeaportValidatorTypes.sol";

struct ErrorsAndWarnings {
    uint16[] errors;
    uint16[] warnings;
}

library ErrorsAndWarningsLib {
    using IssueParser for ConduitIssue;
    using IssueParser for ConsiderationIssue;
    using IssueParser for ERC20Issue;
    using IssueParser for ERC721Issue;
    using IssueParser for ERC1155Issue;
    using IssueParser for GenericIssue;
    using IssueParser for OfferIssue;
    using IssueParser for SignatureIssue;
    using IssueParser for StatusIssue;
    using IssueParser for TimeIssue;
    using IssueParser for NativeIssue;

    function concat(
        ErrorsAndWarnings memory ew1,
        ErrorsAndWarnings memory ew2
    ) internal pure {
        ew1.errors = concatMemory(ew1.errors, ew2.errors);
        ew1.warnings = concatMemory(ew1.warnings, ew2.warnings);
    }

    function empty() internal pure returns (ErrorsAndWarnings memory) {
        return ErrorsAndWarnings(new uint16[](0), new uint16[](0));
    }

    function addError(
        uint16 err
    ) internal pure returns (ErrorsAndWarnings memory) {
        ErrorsAndWarnings memory ew = ErrorsAndWarnings(
            new uint16[](0),
            new uint16[](0)
        );
        ew.errors = pushMemory(ew.errors, err);
        return ew;
    }

    function addError(
        ErrorsAndWarnings memory ew,
        uint16 err
    ) internal pure returns (ErrorsAndWarnings memory) {
        ew.errors = pushMemory(ew.errors, err);
        return ew;
    }

    function addError(
        ErrorsAndWarnings memory ew,
        GenericIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        ERC20Issue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        ERC721Issue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        ERC1155Issue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        ConsiderationIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        OfferIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        SignatureIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        TimeIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        ConduitIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addError(
        ErrorsAndWarnings memory ew,
        StatusIssue err
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addError(ew, err.parseInt());
    }

    function addWarning(
        uint16 warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        ErrorsAndWarnings memory ew = ErrorsAndWarnings(
            new uint16[](0),
            new uint16[](0)
        );
        ew.warnings = pushMemory(ew.warnings, warn);
        return ew;
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        uint16 warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        ew.warnings = pushMemory(ew.warnings, warn);
        return ew;
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        GenericIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        ERC20Issue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        ERC721Issue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        ERC1155Issue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        OfferIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        ConsiderationIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        SignatureIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        TimeIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        ConduitIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        StatusIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function addWarning(
        ErrorsAndWarnings memory ew,
        NativeIssue warn
    ) internal pure returns (ErrorsAndWarnings memory) {
        return addWarning(ew, warn.parseInt());
    }

    function hasErrors(
        ErrorsAndWarnings memory ew
    ) internal pure returns (bool) {
        return ew.errors.length != 0;
    }

    function hasWarnings(
        ErrorsAndWarnings memory ew
    ) internal pure returns (bool) {
        return ew.warnings.length != 0;
    }

    // Helper Functions
    function concatMemory(
        uint16[] memory array1,
        uint16[] memory array2
    ) private pure returns (uint16[] memory) {
        if (array1.length == 0) {
            return array2;
        } else if (array2.length == 0) {
            return array1;
        }

        uint16[] memory returnValue = new uint16[](
            array1.length + array2.length
        );

        for (uint256 i = 0; i < array1.length; i++) {
            returnValue[i] = array1[i];
        }
        for (uint256 i = 0; i < array2.length; i++) {
            returnValue[i + array1.length] = array2[i];
        }

        return returnValue;
    }

    function pushMemory(
        uint16[] memory uint16Array,
        uint16 newValue
    ) internal pure returns (uint16[] memory) {
        uint16[] memory returnValue = new uint16[](uint16Array.length + 1);

        for (uint256 i = 0; i < uint16Array.length; i++) {
            returnValue[i] = uint16Array[i];
        }
        returnValue[uint16Array.length] = newValue;

        return returnValue;
    }
}
