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
pragma solidity ^0.8.24;

import {Currency} from "../../src/types/Currency.sol";
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {SortTokens} from "./SortTokens.sol";

contract TokenFixture {
    Currency internal currency0;
    Currency internal currency1;

    function initializeTokens() internal {
        MockERC20 tokenA = new MockERC20("TestA", "A", 18);
        MockERC20 tokenB = new MockERC20("TestB", "B", 18);

        tokenA.mint(address(this), 1000 ether);
        tokenB.mint(address(this), 1000 ether);

        (currency0, currency1) = SortTokens.sort(tokenA, tokenB);
    }

    function mint(uint256 amount) internal {
        MockERC20 tokenA = MockERC20(Currency.unwrap(currency0));
        MockERC20 tokenB = MockERC20(Currency.unwrap(currency1));

        tokenA.mint(address(this), amount);
        tokenB.mint(address(this), amount);
    }
}
