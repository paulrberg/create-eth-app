/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/simple-token?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "simple-token/@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Simple Token
 * @author Breakthrough Labs Inc.
 * @notice Token, ERC20, Fixed Supply
 * @custom:version 1.0.7
 * @custom:address 4
 * @custom:default-precision 18
 * @custom:simple-description Simple Token. A fixed supply is minted on deployment, and
 * new tokens can never be created.
 * @dev ERC20 token with the following features:
 *
 *  - Premint your total supply.
 *  - No minting function. This allows users to comfortably know the future supply of the token.
 *
 */

contract FixedToken is ERC20 {
    /**
     * @param name Token Name
     * @param symbol Token Symbol
     * @param totalSupply Token Supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }
}

