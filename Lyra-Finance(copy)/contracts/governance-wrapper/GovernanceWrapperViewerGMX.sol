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

// Inherited
import "../synthetix/Owned.sol";
import "./modules/gmx/GMXAdapterGovernanceWrapper.sol";
import "./modules/gmx/GMXHedgerGovernanceWrapper.sol";
import "./modules/LiquidityPoolGovernanceWrapper.sol";
import "./modules/OptionGreekCacheGovernanceWrapper.sol";
import "./modules/OptionMarketGovernanceWrapper.sol";
import "./modules/OptionMarketPricerGovernanceWrapper.sol";
import "./modules/OptionTokenGovernanceWrapper.sol";

/**
 * @title BaseGovernanceWrapper
 * @author Lyra
 * @dev Base contract for managing access to exchange functions.
 */
contract GovernanceWrapperViewerGMX is Owned {
  struct GMXGovernanceWrappers {
    GMXAdapterGovernanceWrapper gmxAdapterGovernanceWrapper;
    GMXHedgerGovernanceWrapper gmxHedgerGovernanceWrapper;
    LiquidityPoolGovernanceWrapper liquidityPoolGovernanceWrapper;
    OptionGreekCacheGovernanceWrapper optionGreekCacheGovernanceWrapper;
    OptionMarketGovernanceWrapper optionMarketGovernanceWrapper;
    OptionMarketPricerGovernanceWrapper optionMarketPricerGovernanceWrapper;
    OptionTokenGovernanceWrapper optionTokenGovernanceWrapper;
  }

  mapping(address => GMXGovernanceWrappers) public marketWrappers;

  constructor() Owned() {}

  function addGMXGovernanceWrappers(address optionMarket, GMXGovernanceWrappers memory govWrappers) external onlyOwner {
    marketWrappers[optionMarket] = govWrappers;
  }

  function getAllBounds(
    address optionMarket
  )
    external
    view
    returns (
      GMXGovernanceWrappers memory wrapperAddresses,
      GMXAdapterGovernanceWrapper.GMXAdapterBounds memory adapterBounds,
      GMXHedgerGovernanceWrapper.HedgerBounds memory hedgerBounds,
      LiquidityPoolGovernanceWrapper.LiquidityPoolBounds memory liquidityPoolBounds,
      OptionGreekCacheGovernanceWrapper.GreekCacheBounds memory greekCacheBounds,
      OptionMarketGovernanceWrapper.OptionMarketBounds memory optionMarketBounds,
      OptionMarketPricerGovernanceWrapper.OptionMarketPricerBounds memory optionMarketPricerBounds,
      OptionTokenGovernanceWrapper.OptionTokenBounds memory optionTokenBounds,
      address boardManager,
      address optionMarketRiskCouncil
    )
  {
    GMXGovernanceWrappers memory wrappers = marketWrappers[optionMarket];
    return (
      wrappers,
      wrappers.gmxAdapterGovernanceWrapper.getAdapterBounds(OptionMarket(optionMarket)),
      wrappers.gmxHedgerGovernanceWrapper.getHedgerBounds(),
      wrappers.liquidityPoolGovernanceWrapper.getLiquidityPoolBounds(),
      wrappers.optionGreekCacheGovernanceWrapper.getGreekCacheBounds(),
      wrappers.optionMarketGovernanceWrapper.getOptionMarketBounds(),
      wrappers.optionMarketPricerGovernanceWrapper.getOptionMarketPricerBounds(),
      wrappers.optionTokenGovernanceWrapper.getOptionTokenBounds(),
      wrappers.optionMarketGovernanceWrapper.boardManager(),
      wrappers.optionMarketGovernanceWrapper.riskCouncil()
    );
  }
}
