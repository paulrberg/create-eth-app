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
// test contract that mimics limited functionality of SNX Futures Market Settings

pragma solidity 0.8.16;

import "../../synthetix/Owned.sol";
import "../../libraries/SimpleInitializable.sol";
import "../../interfaces/perpsV2/IPerpsV2MarketSettings.sol";

contract TestFuturesMarketSettings is Owned, SimpleInitializable, IPerpsV2MarketSettings {
  uint public leverage = 20e18;

  mapping(bytes32 => uint) public maxMarketValueMap;

  constructor() Owned() {}

  function init(uint _leverage) external {
    leverage = _leverage;
  }

  // will just return the same leverage for all markets
  function maxLeverage(bytes32 /* marketKey */) external view returns (uint) {
    return leverage;
  }

  function setMaxLeverage(bytes32 /* marketKey */, uint lev) external returns (uint) {
    leverage = lev;
    return leverage;
  }

  function takerFee(bytes32 _marketKey) external view override returns (uint) {}

  function makerFee(bytes32 _marketKey) external view override returns (uint) {}

  function takerFeeDelayedOrder(bytes32 _marketKey) external view override returns (uint) {}

  function makerFeeDelayedOrder(bytes32 _marketKey) external view override returns (uint) {}

  function takerFeeOffchainDelayedOrder(bytes32 _marketKey) external view override returns (uint) {}

  function makerFeeOffchainDelayedOrder(bytes32 _marketKey) external view override returns (uint) {}

  function nextPriceConfirmWindow(bytes32 _marketKey) external view override returns (uint) {}

  function delayedOrderConfirmWindow(bytes32 _marketKey) external view override returns (uint) {}

  function offchainDelayedOrderMinAge(bytes32 _marketKey) external view override returns (uint) {}

  function offchainDelayedOrderMaxAge(bytes32 _marketKey) external view override returns (uint) {}

  function maxMarketValue(bytes32 _marketKey) external view override returns (uint) {
    if (maxMarketValueMap[_marketKey] != 0) {
      return uint(maxMarketValueMap[_marketKey]);
    }
    return 100000000 * 1e18;
  }

  function setMaxMarketValue(bytes32 _marketKey, uint _maxMarketValue) external returns (uint) {
    maxMarketValueMap[_marketKey] = _maxMarketValue;
    return maxMarketValueMap[_marketKey];
  }

  function maxFundingVelocity(bytes32 _marketKey) external view override returns (uint) {}

  function skewScale(bytes32 _marketKey) external view override returns (uint) {}

  function minDelayTimeDelta(bytes32 _marketKey) external view override returns (uint) {}

  function maxDelayTimeDelta(bytes32 _marketKey) external view override returns (uint) {}

  function parameters(bytes32 _marketKey) external view override returns (Parameters memory) {}

  function offchainMarketKey(bytes32 _marketKey) external view override returns (bytes32) {}

  function offchainPriceDivergence(bytes32 _marketKey) external view override returns (uint) {}

  function liquidationPremiumMultiplier(bytes32 _marketKey) external view override returns (uint) {}

  function minKeeperFee() external view override returns (uint) {}

  function maxKeeperFee() external view override returns (uint) {}

  function liquidationFeeRatio() external view override returns (uint) {}

  function liquidationBufferRatio() external view override returns (uint) {}

  function minInitialMargin() external view override returns (uint) {
    return 50 * 1e18;
  }
}
