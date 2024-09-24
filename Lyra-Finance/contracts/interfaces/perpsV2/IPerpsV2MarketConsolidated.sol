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
  
  //SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

/**
 * @author Synthetix
 * @dev copied from https://github.com/Synthetixio/synthetix/blob/develop/contracts/interfaces/IPerpsV2MarketConsolidated.sol
 *      and updated the version to 0.8
 */
interface IPerpsV2MarketConsolidated {
  /* ========== TYPES ========== */
  enum OrderType {
    Atomic,
    Delayed,
    Offchain
  }

  enum Status {
    Ok,
    InvalidPrice,
    InvalidOrderPrice,
    PriceOutOfBounds,
    CanLiquidate,
    CannotLiquidate,
    MaxMarketSizeExceeded,
    MaxLeverageExceeded,
    InsufficientMargin,
    NotPermitted,
    NilOrder,
    NoPositionOpen,
    PriceTooVolatile,
    PriceImpactToleranceExceeded
  }

  // If margin/size are positive, the position is long; if negative then it is short.
  struct Position {
    uint64 id;
    uint64 lastFundingIndex;
    uint128 margin;
    uint128 lastPrice;
    int128 size;
  }

  // Delayed order storage
  struct DelayedOrder {
    bool isOffchain; // flag indicating the delayed order is offchain
    int128 sizeDelta; // difference in position to pass to modifyPosition
    uint128 priceImpactDelta; // price impact tolerance as a percentage used on fillPrice at execution
    uint128 targetRoundId; // price oracle roundId using which price this order needs to executed
    uint128 commitDeposit; // the commitDeposit paid upon submitting that needs to be refunded if order succeeds
    uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
    uint256 executableAtTime; // The timestamp at which this order is executable at
    uint256 intentionTime; // The block timestamp of submission
    bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
  }

  /* ========== Views ========== */
  /* ---------- Market Details ---------- */

  function marketKey() external view returns (bytes32 key);

  function baseAsset() external view returns (bytes32 key);

  function marketSize() external view returns (uint128 size);

  function marketSkew() external view returns (int128 skew);

  function fundingLastRecomputed() external view returns (uint32 timestamp);

  function fundingSequence(uint index) external view returns (int128 netFunding);

  function positions(address account) external view returns (Position memory);

  function delayedOrders(address account) external view returns (DelayedOrder memory);

  function assetPrice() external view returns (uint price, bool invalid);

  function marketSizes() external view returns (uint long, uint short);

  function marketDebt() external view returns (uint debt, bool isInvalid);

  function currentFundingRate() external view returns (int fundingRate);

  function currentFundingVelocity() external view returns (int fundingVelocity);

  function unrecordedFunding() external view returns (int funding, bool invalid);

  function fundingSequenceLength() external view returns (uint length);

  /* ---------- Position Details ---------- */

  function notionalValue(address account) external view returns (int value, bool invalid);

  function profitLoss(address account) external view returns (int pnl, bool invalid);

  function accruedFunding(address account) external view returns (int funding, bool invalid);

  function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid);

  function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid);

  function liquidationPrice(address account) external view returns (uint price, bool invalid);

  function liquidationFee(address account) external view returns (uint);

  function canLiquidate(address account) external view returns (bool);

  function orderFee(int sizeDelta, OrderType orderType) external view returns (uint fee, bool invalid);

  function postTradeDetails(
    int sizeDelta,
    uint tradePrice,
    OrderType orderType,
    address sender
  ) external view returns (uint margin, int size, uint price, uint liqPrice, uint fee, Status status);

  /* ========== Market ========== */
  function recomputeFunding() external returns (uint lastIndex);

  function transferMargin(int marginDelta) external;

  function withdrawAllMargin() external;

  function modifyPosition(int sizeDelta, uint priceImpactDelta) external;

  function modifyPositionWithTracking(int sizeDelta, uint priceImpactDelta, bytes32 trackingCode) external;

  function closePosition(uint priceImpactDelta) external;

  function closePositionWithTracking(uint priceImpactDelta, bytes32 trackingCode) external;

  function liquidatePosition(address account) external;

  /* ========== DelayedOrder ========== */
  function submitDelayedOrder(int sizeDelta, uint priceImpactDelta, uint desiredTimeDelta) external;

  function submitDelayedOrderWithTracking(
    int sizeDelta,
    uint priceImpactDelta,
    uint desiredTimeDelta,
    bytes32 trackingCode
  ) external;

  function cancelDelayedOrder(address account) external;

  function executeDelayedOrder(address account) external;

  /* ========== OffchainDelayedOrder ========== */
  function submitOffchainDelayedOrder(int sizeDelta, uint priceImpactDelta) external;

  function submitOffchainDelayedOrderWithTracking(int sizeDelta, uint priceImpactDelta, bytes32 trackingCode) external;

  function cancelOffchainDelayedOrder(address account) external;

  function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable;

  /* ========== Events ========== */

  event PositionModified(
    uint indexed id,
    address indexed account,
    uint margin,
    int size,
    int tradeSize,
    uint lastPrice,
    uint fundingIndex,
    uint fee
  );

  event MarginTransferred(address indexed account, int marginDelta);

  event PositionLiquidated(uint id, address account, address liquidator, int size, uint price, uint fee);

  event FundingRecomputed(int funding, int fundingRate, uint index, uint timestamp);

  event PerpsTracking(bytes32 indexed trackingCode, bytes32 baseAsset, bytes32 marketKey, int sizeDelta, uint fee);

  event DelayedOrderRemoved(
    address indexed account,
    bool isOffchain,
    uint currentRoundId,
    int sizeDelta,
    uint targetRoundId,
    uint commitDeposit,
    uint keeperDeposit,
    bytes32 trackingCode
  );

  event DelayedOrderSubmitted(
    address indexed account,
    bool isOffchain,
    int sizeDelta,
    uint targetRoundId,
    uint intentionTime,
    uint executableAtTime,
    uint commitDeposit,
    uint keeperDeposit,
    bytes32 trackingCode
  );
}
