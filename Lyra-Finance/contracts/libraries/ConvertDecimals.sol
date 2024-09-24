/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Libraries
import "./Math.sol";

/**
 * @title ConvertDecimals
 * @author Lyra
 * @dev Contract to convert amounts to and from erc20 tokens to 18 dp.
 */
library ConvertDecimals {
  /// @dev Converts amount from token native dp to 18 dp. This cuts off precision for decimals > 18.
  function convertTo18(uint amount, uint8 decimals) internal pure returns (uint) {
    return (amount * 1e18) / (10 ** decimals);
  }

  /// @dev Converts amount from 18dp to token.decimals(). This cuts off precision for decimals < 18.
  function convertFrom18(uint amount, uint8 decimals) internal pure returns (uint) {
    return (amount * (10 ** decimals)) / 1e18;
  }

  /// @dev Converts amount from a given precisionFactor to 18 dp. This cuts off precision for decimals > 18.
  function normaliseTo18(uint amount, uint precisionFactor) internal pure returns (uint) {
    return (amount * 1e18) / precisionFactor;
  }

  // Loses precision
  /// @dev Converts amount from 18dp to the given precisionFactor. This cuts off precision for decimals < 18.
  function normaliseFrom18(uint amount, uint precisionFactor) internal pure returns (uint) {
    return (amount * precisionFactor) / 1e18;
  }

  /// @dev Ensure a value converted from 18dp is rounded up, to ensure the value requested is covered fully.
  function convertFrom18AndRoundUp(uint amount, uint8 assetDecimals) internal pure returns (uint amountConverted) {
    // If we lost precision due to conversion we ensure the lost value is rounded up to the lowest precision of the asset
    if (assetDecimals < 18) {
      // Taking the ceil of 10^(18-decimals) will ensure the first n (asset decimals) have precision when converting
      amount = Math.ceil(amount, 10 ** (18 - assetDecimals));
    }
    amountConverted = ConvertDecimals.convertFrom18(amount, assetDecimals);
  }
}
