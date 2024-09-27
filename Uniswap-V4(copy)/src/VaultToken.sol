/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.24;

import {Currency} from "./types/Currency.sol";
import {IVaultToken} from "./interfaces/IVaultToken.sol";

/// @dev This contract is a modified version of the ERC6909 implementation:
/// 1. totalSupply is removed
/// 2. tokenId is changed to Currency to fit our use case
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC6909.sol)

/// @notice Users are allowed to store their surplus tokens i.e. unsettled balance that the pool
/// owed to user in the vault, and they will be able to withdraw them or use them to settle future
/// transactions. VaultToken is designed as a minimum implementation to achieve this goal. It keeps
/// track of users' surplus tokens and allows users to approve others to spend their tokens.
abstract contract VaultToken is IVaultToken {
    /*//////////////////////////////////////////////////////////////
                             ERC6909 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool)) public isOperator;

    mapping(address => mapping(Currency currency => uint256)) public balanceOf;

    mapping(address => mapping(address => mapping(Currency currency => uint256))) public allowance;

    /*//////////////////////////////////////////////////////////////
                              ERC6909 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address receiver, Currency currency, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender][currency] -= amount;

        balanceOf[receiver][currency] += amount;

        emit Transfer(msg.sender, msg.sender, receiver, currency, amount);

        return true;
    }

    function transferFrom(address sender, address receiver, Currency currency, uint256 amount)
        public
        virtual
        returns (bool)
    {
        if (msg.sender != sender && !isOperator[sender][msg.sender]) {
            uint256 allowed = allowance[sender][msg.sender][currency];
            if (allowed != type(uint256).max) allowance[sender][msg.sender][currency] = allowed - amount;
        }

        balanceOf[sender][currency] -= amount;

        balanceOf[receiver][currency] += amount;

        emit Transfer(msg.sender, sender, receiver, currency, amount);

        return true;
    }

    function approve(address spender, Currency currency, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender][currency] = amount;

        emit Approval(msg.sender, spender, currency, amount);

        return true;
    }

    function setOperator(address operator, bool approved) public virtual returns (bool) {
        isOperator[msg.sender][operator] = approved;

        emit OperatorSet(msg.sender, operator, approved);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0xb2e69f8a; // ERC165 Interface ID for ERC6909
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address receiver, Currency currency, uint256 amount) internal virtual {
        balanceOf[receiver][currency] += amount;

        emit Transfer(msg.sender, address(0), receiver, currency, amount);
    }

    function _burn(address sender, Currency currency, uint256 amount) internal virtual {
        balanceOf[sender][currency] -= amount;

        emit Transfer(msg.sender, sender, address(0), currency, amount);
    }
}
