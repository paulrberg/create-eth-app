/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ChainLink?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/UniswapAnchoredView.sol";

contract MockCompoundOracle is UniswapAnchoredView {
  struct OracleDetails {
    uint256 price;
    uint256 decimals;
  }

  mapping(string => OracleDetails) s_oracleDetails;

  function price(string memory symbol) external view override returns (uint256) {
    return s_oracleDetails[symbol].price;
  }

  function setPrice(
    string memory symbol,
    uint256 newPrice,
    uint256 newDecimals
  ) public {
    OracleDetails memory details = s_oracleDetails[symbol];
    details.price = newPrice;
    details.decimals = newDecimals;
    s_oracleDetails[symbol] = details;
  }
}
