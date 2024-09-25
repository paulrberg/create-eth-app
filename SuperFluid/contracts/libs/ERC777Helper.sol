/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { IERC1820Registry } from "SuperFluid/@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/**
 * @title ERC777 helper library
 * @author Superfluid
 */
library ERC777Helper {

    IERC1820Registry constant internal _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 constant internal _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 constant internal _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");


    /// @dev ERC777 operators support self structure
    struct Operators {
        address[] defaultOperatorsArray;
        mapping(address => bool) defaultOperators;
        mapping(address => mapping(address => bool)) operators;
        mapping(address => mapping(address => bool)) revokedDefaultOperators;
    }

    function register(address token) internal {
        _ERC1820_REGISTRY.setInterfaceImplementer(token, keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(token, keccak256("ERC20Token"), address(this));
    }

    function isOperatorFor(Operators storage self, address operator, address tokenHolder) internal view returns (bool) {
        return operator == tokenHolder ||
            (
                self.defaultOperators[operator] &&
                !self.revokedDefaultOperators[tokenHolder][operator]
            ) ||
            self.operators[tokenHolder][operator];
    }

    function authorizeOperator(Operators storage self, address holder, address operator) internal {
        require(holder != operator, "ERC777Operators: authorizing self as operator");

        if (self.defaultOperators[operator]) {
            delete self.revokedDefaultOperators[holder][operator];
        } else {
            self.operators[holder][operator] = true;
        }
    }

    function revokeOperator(Operators storage self, address holder, address operator) internal {
        require(operator != msg.sender, "ERC777Operators: revoking self as operator");
        if (self.defaultOperators[operator]) {
            self.revokedDefaultOperators[holder][operator] = true;
        } else {
            delete self.operators[holder][operator];
        }
    }

    function defaultOperators(Operators storage self) internal view returns (address[] memory) {
        return self.defaultOperatorsArray;
    }

    function setupDefaultOperators(Operators storage self, address[] memory operators) internal {
        // According to 777 spec: default operators should only be setup once
        assert(self.defaultOperatorsArray.length == 0);
        self.defaultOperatorsArray = operators;
        for (uint i = 0; i < operators.length; ++i) {
            self.defaultOperators[operators[i]] = true;
        }
    }

}
