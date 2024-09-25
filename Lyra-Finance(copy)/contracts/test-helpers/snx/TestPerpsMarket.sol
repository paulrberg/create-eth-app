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

// libraries
import "../../synthetix/DecimalMath.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/utils/math/SafeCast.sol";

// Inherited
import "../../synthetix/Owned.sol";
import "../../libraries/SimpleInitializable.sol";
import "../../interfaces/perpsV2/IPerpsV2MarketConsolidated.sol";
import "./../SynthetixAdapter.sol"; // TODO: this will need to be updated to use the new adapter

import "./MockPerpsV2MarketConsolidated.sol";
import "../TestERC20SetDecimals.sol";

/**
 * @title TestPerpsMarket
 * @notice This contract is used to test the hedger contract
 * @dev This contract is used to test the hedger contract
 */
contract TestPerpsMarket is MockPerpsV2MarketConsolidated, Owned, SimpleInitializable {
  using DecimalMath for uint;

  bytes32 public override marketKey;
  SynthetixAdapter public adapter;
  TestERC20SetDecimals public quoteAsset;

  mapping(address => Position) public userPositions;
  mapping(address => Position) public pendingPosition;
  mapping(bytes32 => OptionMarket) public keyToOptionMarket;

  int public fundingRate = 0.01 * 1e18; 
  mapping(bytes32 => uint) public maxMarketValueMap;

  constructor() Owned() {}

  function init(
    bytes32 _marketKey,
    SynthetixAdapter _synthetixAdapter,
    TestERC20SetDecimals _quoteAsset
  ) external onlyOwner initializer {
    marketKey = _marketKey;
    adapter = _synthetixAdapter;
    quoteAsset = _quoteAsset;
  }

  function addMarket(bytes32 _marketKey, OptionMarket _optionMarket) external {
    keyToOptionMarket[_marketKey] = _optionMarket;
  }

  function _getSpot() internal view returns (uint) {
    return
      adapter.getSpotPriceForMarket(address(keyToOptionMarket[marketKey]), BaseExchangeAdapter.PriceType.REFERENCE);
  }

  function setPosition(Position memory pos) external {
    userPositions[msg.sender] = pos;
  }

  function positions() external view returns (Position memory) {
    return userPositions[msg.sender];
  }

  function marketSize() external view override returns (uint128) {
    return 10000000 * 1e18;
  }

  function submitOffchainDelayedOrder(int sizeDelta, uint priceImpactDelta) external override {
    pendingPosition[msg.sender] = Position({
      size: userPositions[msg.sender].size + int128(sizeDelta),
      lastPrice: 1300,
      margin: userPositions[msg.sender].margin,
      id: userPositions[msg.sender].id + 1,
      lastFundingIndex: 0
    });
  }

  function submitOffchainDelayedOrderWithTracking(
    int sizeDelta,
    uint priceImpactDelta,
    bytes32 trackingCode
  ) external override {
    pendingPosition[msg.sender] = Position({
      size: userPositions[msg.sender].size + int128(sizeDelta),
      lastPrice: 1300,
      margin: userPositions[msg.sender].margin,
      id: userPositions[msg.sender].id + 1,
      lastFundingIndex: 0
    });
  }

  function cancelOffchainDelayedOrder(address account) external override {
    pendingPosition[account] = Position({size: 0, lastPrice: 0, margin: 0, id: 0, lastFundingIndex: 0});
  }

  function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable override {
    userPositions[account] = Position({
      size: pendingPosition[account].size,
      lastPrice: pendingPosition[account].lastPrice,
      margin: pendingPosition[account].margin,
      id: pendingPosition[account].id,
      lastFundingIndex: pendingPosition[account].lastFundingIndex
    });

    pendingPosition[account] = Position({size: 0, lastPrice: 0, margin: 0, id: 0, lastFundingIndex: 0});
  }

  // TODO: flesh out thse margin functions so that proper testing can be done
  function transferMargin(int amount) external override {
    if (amount < 50 * 1e18 && userPositions[msg.sender].margin < 50 * 1e18) {
      revert("below minimum margin");
    }
    if (amount < 0) {
      // transfer user back margin
      userPositions[msg.sender].margin -= uint128(Math.abs(amount));
      quoteAsset.mint(msg.sender, Math.abs(amount));
      return;
    }

    // transfer user margin
    quoteAsset.burn(msg.sender, Math.abs(amount));
    userPositions[msg.sender].margin += uint128(Math.abs(amount));

    if (userPositions[msg.sender].margin < 50 * 1e18 && userPositions[msg.sender].margin != 0) {
      revert("below minimum margin after transfer");
    }
  }

  function positions(address account) external view override returns (Position memory) {
    return userPositions[account];
  }

  function remainingMargin(address account) external view override returns (uint marginRemaining, bool invalid) {
    // might need to be able to get spot price or set spot price to test this
    return (userPositions[account].margin, false);
  }

  function marketSkew() external view override returns (int128 skew) {
    return 0;
  }

  function currentFundingRate() external view override returns (int) {
    return fundingRate;
  }
  
  function setFundingRate(int _fundingRate) external returns (int) {
    fundingRate = _fundingRate;
    return fundingRate;
  }

  function orderFee(int sizeDelta, OrderType orderType) external view override returns (uint fee, bool invalid) {
    return (1 * 1e16, false);
  }
}
