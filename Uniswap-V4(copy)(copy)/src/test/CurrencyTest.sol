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

import {Currency, CurrencyLibrary} from "../types/Currency.sol";

contract CurrencyTest {
    function transfer(Currency currency, address to, uint256 amount) external {
        CurrencyLibrary.transfer(currency, to, amount);
    }

    function balanceOfSelf(Currency currency) external view returns (uint256) {
        return CurrencyLibrary.balanceOfSelf(currency);
    }

    function balanceOf(Currency currency, address owner) external view returns (uint256) {
        return CurrencyLibrary.balanceOf(currency, owner);
    }

    function isNative(Currency currency) external pure returns (bool) {
        return CurrencyLibrary.isNative(currency);
    }

    function toId(Currency currency) external pure returns (uint256) {
        return CurrencyLibrary.toId(currency);
    }

    function fromId(uint256 id) external pure returns (Currency) {
        return CurrencyLibrary.fromId(id);
    }
}
