/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/voting-token?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "voting-token/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "voting-token/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "voting-token/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title Voting Token
 * @author Breakthrough Labs Inc.
 * @notice Token, ERC20, Voting, Fixed
 * @custom:version 1.0.8
 * @custom:address 7
 * @custom:default-precision 18
 * @custom:simple-description Fixed supply token that allows for
 * voting on connected DAO proposals.
 * @dev ERC20 token with the following features:
 *
 *  - Token owners can vote on Governance/DAO proposals.
 *  - Premint your total supply.
 *  - No minting function. This allows users to comfortably know the future supply of the token.
 *
 * Used with Governance/DAO contracts for voting.
 *
 */

contract VotingToken is ERC20, ERC20Permit, ERC20Votes {
    /**
     * @param name Token Name
     * @param symbol Token Symbol
     * @param totalSupply Initial Supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, totalSupply);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}

