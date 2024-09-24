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
  
  //SPDX-License-Identifier:ISC

pragma solidity 0.8.16;

import "Lyra-Finance/openzeppelin-contracts-4.4.1/token/ERC20/IERC20.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/periphery/LyraRegistry.sol";
/// @dev inputs/returns that contain Lyra contracts replaced with addresses (as opposed to LyraRegistry.sol)
///      so that interacting contracts are not required to import Lyra contracts
interface ILyraRegistry {
  struct OptionMarketAddresses {
    address liquidityPool;
    address liquidityToken;
    address greekCache;
    address optionMarket;
    address optionMarketPricer;
    address optionToken;
    address poolHedger;
    address shortCollateral;
    address gwavOracle;
    IERC20 quoteAsset;
    IERC20 baseAsset;
  }

  function optionMarkets() external view returns (address[] memory);

  function marketAddress(address market) external view returns (OptionMarketAddresses memory);

  function globalAddresses(bytes32 name) external view returns (address);

  function getMarketAddresses(address optionMarket) external view returns (OptionMarketAddresses memory);

  function getGlobalAddress(bytes32 contractName) external view returns (address globalContract);

  event GlobalAddressUpdated(bytes32 indexed name, address addr);

  event MarketUpdated(address indexed optionMarket, OptionMarketAddresses market);

  event MarketRemoved(address indexed market);

  error RemovingInvalidMarket(address thrower, address market);

  error NonExistentMarket(address optionMarket);

  error NonExistentGlobalContract(bytes32 contractName);
}
