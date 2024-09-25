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
  
  // SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import { ERC20, ERC20Permit } from "SuperFluid/@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title Test token contract
 * @author Superfluid
 * @dev Test ERC20 token that allows any one mint new tokens.
 */
contract TestToken is ERC20Permit {
    uint256 private immutable _mintLimit;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 initDecimals, uint256 mintLimit)
        ERC20Permit(name)
        ERC20(name, symbol)
    {
        _decimals = initDecimals;
        _mintLimit = mintLimit;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function mint(address account, uint256 amount) public returns (bool) {
        assert(amount <= _mintLimit); // no revert msg for you, bad boy
        ERC20._mint(account, amount);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
