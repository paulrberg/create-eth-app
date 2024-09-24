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

// Libraries
import "../libraries/BlackScholes.sol";
import "../synthetix/DecimalMath.sol";

// Inherited
import "../synthetix/Owned.sol";

// Interfaces
import "../OptionMarket.sol";
import "../OptionToken.sol";
import "../LiquidityPool.sol";
import "../OptionGreekCache.sol";
import "../OptionMarketPricer.sol";
import "./OptionMarketViewer.sol";
import "./GWAVOracle.sol";
import "./Wrapper/OptionMarketWrapper.sol";

/**
 * @title OptionMarketViewer
 * @author Lyra
 * @dev Provides helpful functions to allow the dapp to operate more smoothly; logic in getPremiumForTrade is vital to
 * ensuring accurate prices are provided to the user.
 */
contract LyraRegistry is Owned {
  struct OptionMarketAddresses {
    LiquidityPool liquidityPool;
    LiquidityToken liquidityToken;
    OptionGreekCache greekCache;
    OptionMarket optionMarket;
    OptionMarketPricer optionMarketPricer;
    OptionToken optionToken;
    PoolHedger poolHedger;
    ShortCollateral shortCollateral;
    GWAVOracle gwavOracle;
    IERC20 quoteAsset;
    IERC20 baseAsset;
  }

  OptionMarket[] public optionMarkets;
  mapping(OptionMarket => OptionMarketAddresses) public marketAddresses;
  mapping(bytes32 => address) public globalAddresses;

  constructor() Owned() {}

  function getMarketAddresses(OptionMarket optionMarket) external view returns (OptionMarketAddresses memory) {
    OptionMarketAddresses memory addresses = marketAddresses[optionMarket];
    if (address(addresses.optionMarket) != address(0)) {
      return addresses;
    } else {
      revert NonExistentMarket(address(optionMarket));
    }
  }

  function getGlobalAddress(bytes32 contractName) external view returns (address globalContract) {
    globalContract = globalAddresses[contractName];
    if (globalContract != address(0)) {
      return globalContract;
    } else {
      revert NonExistentGlobalContract(contractName);
    }
  }

  function updateGlobalAddresses(bytes32[] memory names, address[] memory addresses) external onlyOwner {
    uint namesLength = names.length;
    require(namesLength == addresses.length, "length mismatch");
    for (uint i = 0; i < namesLength; ++i) {
      globalAddresses[names[i]] = addresses[i];
      emit GlobalAddressUpdated(names[i], addresses[i]);
    }
  }

  function addMarket(OptionMarketAddresses memory newMarketAddresses) external onlyOwner {
    if (address(marketAddresses[newMarketAddresses.optionMarket].optionMarket) == address(0)) {
      optionMarkets.push(newMarketAddresses.optionMarket);
    }
    marketAddresses[newMarketAddresses.optionMarket] = newMarketAddresses;
    emit MarketUpdated(newMarketAddresses.optionMarket, newMarketAddresses);
  }

  function removeMarket(OptionMarket market) external onlyOwner {
    _removeMarket(market);
  }

  function _removeMarket(OptionMarket market) internal {
    uint optionMarketsLength = optionMarkets.length;
    uint index = 0;
    bool found = false;
    for (uint i = 0; i < optionMarketsLength; ++i) {
      if (optionMarkets[i] == market) {
        index = i;
        found = true;
        break;
      }
    }
    if (!found) {
      revert RemovingInvalidMarket(address(this), address(market));
    }
    optionMarkets[index] = optionMarkets[optionMarketsLength - 1];
    optionMarkets.pop();

    emit MarketRemoved(market);
    delete marketAddresses[market];
  }

  /**
   * @dev Emitted when a global contract is added
   */
  event GlobalAddressUpdated(bytes32 indexed name, address addr);

  /**
   * @dev Emitted when an optionMarket is updated
   */
  event MarketUpdated(OptionMarket indexed optionMarket, OptionMarketAddresses market);

  /**
   * @dev Emitted when an optionMarket is removed
   */
  event MarketRemoved(OptionMarket indexed market);

  ////////////
  // Errors //
  ////////////

  error RemovingInvalidMarket(address thrower, address market);

  error NonExistentMarket(address optionMarket);

  error NonExistentGlobalContract(bytes32 contractName);
}
