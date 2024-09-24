/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./IPerpsV2MarketBaseTypes.sol";

// Helper Interface - used in tests and to provide a consolidated PerpsV2 interface for users/integrators.

interface IPerpsV2MarketConsolidated {
    /* ========== TYPES ========== */

    enum OrderType {Atomic, Delayed, Offchain}

    enum Status {
        Ok,
        InvalidPrice,
        InvalidOrderType,
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
        PriceImpactToleranceExceeded,
        PositionFlagged,
        PositionNotFlagged
    }

    /* @dev: See IPerpsV2MarketBaseTypes */
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    /* @dev: See IPerpsV2MarketBaseTypes */
    struct DelayedOrder {
        bool isOffchain;
        int128 sizeDelta;
        uint128 desiredFillPrice;
        uint128 targetRoundId;
        uint128 commitDeposit;
        uint128 keeperDeposit;
        uint256 executableAtTime;
        uint256 intentionTime;
        bytes32 trackingCode;
    }

    /* ========== Views ========== */

    /* ---------- Market Details ---------- */

    function marketKey() external view returns (bytes32 key);

    function baseAsset() external view returns (bytes32 key);

    function marketSize() external view returns (uint128 size);

    function marketSkew() external view returns (int128 skew);

    function fundingLastRecomputed() external view returns (uint32 timestamp);

    function fundingRateLastRecomputed() external view returns (int128 fundingRate);

    function fundingSequence(uint index) external view returns (int128 netFunding);

    function positions(address account) external view returns (Position memory);

    function delayedOrders(address account) external view returns (DelayedOrder memory);

    function assetPrice() external view returns (uint price, bool invalid);

    function fillPrice(int sizeDelta) external view returns (uint price, bool invalid);

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

    function isFlagged(address account) external view returns (bool);

    function canLiquidate(address account) external view returns (bool);

    function orderFee(int sizeDelta, IPerpsV2MarketBaseTypes.OrderType orderType)
        external
        view
        returns (uint fee, bool invalid);

    function postTradeDetails(
        int sizeDelta,
        uint tradePrice,
        IPerpsV2MarketBaseTypes.OrderType orderType,
        address sender
    )
        external
        view
        returns (
            uint margin,
            int size,
            uint price,
            uint liqPrice,
            uint fee,
            Status status
        );

    /* ========== Market ========== */
    function recomputeFunding() external returns (uint lastIndex);

    function transferMargin(int marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPosition(int sizeDelta, uint desiredFillPrice) external;

    function modifyPositionWithTracking(
        int sizeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function closePosition(uint desiredFillPrice) external;

    function closePositionWithTracking(uint desiredFillPrice, bytes32 trackingCode) external;

    /* ========== Liquidate    ========== */

    function flagPosition(address account) external;

    function liquidatePosition(address account) external;

    function forceLiquidatePosition(address account) external;

    /* ========== Delayed Intent ========== */
    function submitCloseOffchainDelayedOrderWithTracking(uint desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseDelayedOrderWithTracking(
        uint desiredTimeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitDelayedOrder(
        int sizeDelta,
        uint desiredTimeDelta,
        uint desiredFillPrice
    ) external;

    function submitDelayedOrderWithTracking(
        int sizeDelta,
        uint desiredTimeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitOffchainDelayedOrder(int sizeDelta, uint desiredFillPrice) external;

    function submitOffchainDelayedOrderWithTracking(
        int sizeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    /* ========== Delayed Execution ========== */

    function executeDelayedOrder(address account) external;

    function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable;

    function cancelDelayedOrder(address account) external;

    function cancelOffchainDelayedOrder(address account) external;

    /* ========== Events ========== */

    event PositionModified(
        uint indexed id,
        address indexed account,
        uint margin,
        int size,
        int tradeSize,
        uint lastPrice,
        uint fundingIndex,
        uint fee,
        int skew
    );

    event MarginTransferred(address indexed account, int marginDelta);

    event PositionFlagged(uint id, address account, address flagger, uint price, uint timestamp);

    event PositionLiquidated(
        uint id,
        address account,
        address liquidator,
        int size,
        uint price,
        uint flaggerFee,
        uint liquidatorFee,
        uint stakersFee
    );

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
