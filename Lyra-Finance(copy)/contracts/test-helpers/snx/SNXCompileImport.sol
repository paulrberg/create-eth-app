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
pragma solidity 0.5.16;

import "Lyra-Finance/synthetix/contracts/MixinPerpsV2MarketSettings.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2ExchangeRate.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2Market.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketBase.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketData.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketDelayedOrders.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketDelayedOrdersBase.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketDelayedOrdersOffchain.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketProxyable.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketSettings.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketState.sol";
import "Lyra-Finance/synthetix/contracts/PerpsV2MarketViews.sol";
import "Lyra-Finance/synthetix/contracts/ProxyPerpsV2.sol";
import "Lyra-Finance/synthetix/contracts/FuturesMarketManager.sol";
import "Lyra-Finance/synthetix/contracts/FuturesMarketSettings.sol";
import "Lyra-Finance/synthetix/contracts/SafeDecimalMath.sol";
import "Lyra-Finance/openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "Lyra-Finance/synthetix/contracts/SignedSafeMath.sol";
import "Lyra-Finance/synthetix/contracts/SignedSafeDecimalMath.sol";
import "Lyra-Finance/synthetix/contracts/SafeDecimalMath.sol";

/**
 * @dev Contract is used to import all the contracts that are needed for integration testing the GMX contracts.
 */
contract SNXCompileImports {
  constructor() public {
    // this is empty
  }
}
