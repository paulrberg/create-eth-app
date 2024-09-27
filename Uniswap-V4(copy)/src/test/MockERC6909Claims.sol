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
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {ERC6909Claims} from "../ERC6909Claims.sol";
import {CurrencyLibrary, Currency} from "../types/Currency.sol";

/// @notice Mock contract for testing ERC6909Claims
contract MockERC6909Claims is ERC6909Claims {
    using CurrencyLibrary for Currency;

    /// @notice mocked mint logic
    function mint(address to, uint256 id, uint256 amount) public {
        _mint(to, id, amount);
    }

    /// @notice mocked burn logic
    function burn(uint256 id, uint256 amount) public {
        _burn(msg.sender, id, amount);
    }

    /// @notice mocked burn logic without checking sender allowance
    function burnFrom(address from, uint256 id, uint256 amount) public {
        _burnFrom(from, id, amount);
    }
}
