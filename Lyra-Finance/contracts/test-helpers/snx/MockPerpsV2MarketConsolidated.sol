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
  
  pragma solidity ^0.8.0;

import "../../interfaces/perpsV2/IPerpsV2MarketConsolidated.sol";

contract MockPerpsV2MarketConsolidated is IPerpsV2MarketConsolidated {
  uint private _price;
  bool private _invalid;

  function setAssetPrice(uint price, bool invalid) external {
    _price = price;
    _invalid = invalid;
  }

  function assetPrice() external view virtual override returns (uint, bool) {
    return (_price, _invalid);
  }

  function marketKey() external view virtual override returns (bytes32) {}

  function baseAsset() external view virtual override returns (bytes32) {}

  function marketSize() external view virtual override returns (uint128) {}

  function marketSkew() external view virtual override returns (int128) {}

  function fundingLastRecomputed() external view virtual override returns (uint32) {}

  function fundingSequence(uint /*index*/) external view virtual override returns (int128) {}

  function positions(address /*account*/) external view virtual override returns (Position memory) {}

  function delayedOrders(address /*account*/) external view virtual override returns (DelayedOrder memory) {}

  function marketSizes() external view virtual override returns (uint, uint) {}

  function marketDebt() external view virtual override returns (uint, bool) {}

  function currentFundingRate() external view virtual override returns (int) {}

  function currentFundingVelocity() external view virtual override returns (int) {}

  function unrecordedFunding() external view virtual override returns (int, bool) {}

  function fundingSequenceLength() external view virtual override returns (uint) {}

  function notionalValue(address /*account*/) external view virtual override returns (int, bool) {}

  function profitLoss(address /*account*/) external view virtual override returns (int, bool) {}

  function accruedFunding(address /*account*/) external view virtual override returns (int, bool) {}

  function remainingMargin(address /*account*/) external view virtual override returns (uint, bool) {}

  function accessibleMargin(address /*account*/) external view virtual override returns (uint, bool) {}

  function liquidationPrice(address /*account*/) external view virtual override returns (uint, bool) {}

  function liquidationFee(address /*account*/) external view virtual override returns (uint) {}

  function canLiquidate(address /*account*/) external view virtual override returns (bool) {}

  function orderFee(
    int /*sizeDelta*/,
    IPerpsV2MarketConsolidated.OrderType /*orderType*/
  ) external view virtual override returns (uint, bool) {}

  function postTradeDetails(
    int /*sizeDelta*/,
    uint /*tradePrice*/,
    IPerpsV2MarketConsolidated.OrderType /*orderType*/,
    address /*sender*/
  ) external view virtual override returns (uint, int, uint, uint, uint, Status) {}

  function recomputeFunding() external virtual override returns (uint) {}

  function transferMargin(int /*marginDelta*/) external virtual override {}

  function withdrawAllMargin() external virtual override {}

  function modifyPosition(int /*sizeDelta*/, uint /*priceImpactDelta*/) external virtual override {}

  function modifyPositionWithTracking(
    int /*sizeDelta*/,
    uint /*priceImpactDelta*/,
    bytes32 /*trackingCode*/
  ) external virtual override {}

  function closePosition(uint /*priceImpactDelta*/) external virtual override {}

  function closePositionWithTracking(uint /*priceImpactDelta*/, bytes32 /*trackingCode*/) external virtual override {}

  function liquidatePosition(address /*account*/) external virtual override {}

  function submitDelayedOrder(
    int /*sizeDelta*/,
    uint /*priceImpactDelta*/,
    uint /*desiredTimeDelta*/
  ) external virtual override {}

  function submitDelayedOrderWithTracking(
    int /*sizeDelta*/,
    uint /*priceImpactDelta*/,
    uint /*desiredTimeDelta*/,
    bytes32 /*trackingCode*/
  ) external virtual override {}

  function cancelDelayedOrder(address /*account*/) external virtual override {}

  function executeDelayedOrder(address /*account*/) external virtual override {}

  function submitOffchainDelayedOrder(int /*sizeDelta*/, uint /*priceImpactDelta*/) external virtual override {}

  function submitOffchainDelayedOrderWithTracking(
    int /*sizeDelta*/,
    uint /*priceImpactDelta*/,
    bytes32 /*trackingCode*/
  ) external virtual override {}

  function cancelOffchainDelayedOrder(address /*account*/) external virtual override {}

  function executeOffchainDelayedOrder(
    address /*account*/,
    bytes[] calldata /*priceUpdateData*/
  ) external payable virtual override {}
}
