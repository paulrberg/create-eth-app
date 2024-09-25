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

import "../interfaces/IPerpsV2MarketConsolidated.sol";

// Helper Contract, only used in tests and to provide a consolidated interface to PerpsV2 users/integrators

contract TestablePerpsV2MarketEmpty is IPerpsV2MarketConsolidated {
    function marketKey() external view returns (bytes32 key) {
        return "";
    }

    function baseAsset() external view returns (bytes32 key) {
        return "";
    }

    function marketSize() external view returns (uint128 size) {
        return 0;
    }

    function marketSkew() external view returns (int128 skew) {
        return 0;
    }

    function fundingLastRecomputed() external view returns (uint32 timestamp) {
        return 0;
    }

    function fundingSequence(uint index) external view returns (int128 netFunding) {
        index;
        return 0;
    }

    function positions(address account) external view returns (Position memory) {
        account;
        return Position(0, 0, 0, 0, 0);
    }

    function delayedOrders(address account) external view returns (DelayedOrder memory) {
        account;
        return DelayedOrder(false, 0, 0, 0, 0, 0, 0, 0, "");
    }

    function assetPrice() external view returns (uint price, bool invalid) {
        return (0, false);
    }

    function marketSizes() external view returns (uint long, uint short) {
        return (0, 0);
    }

    function marketDebt() external view returns (uint debt, bool isInvalid) {
        return (0, false);
    }

    function currentFundingRate() external view returns (int fundingRate) {
        return 0;
    }

    function currentFundingVelocity() external view returns (int fundingVelocity) {
        return 0;
    }

    function unrecordedFunding() external view returns (int funding, bool invalid) {
        return (0, false);
    }

    function fundingSequenceLength() external view returns (uint length) {
        return 0;
    }

    /* ---------- Position Details ---------- */

    function notionalValue(address account) external view returns (int value, bool invalid) {
        account;
        return (0, false);
    }

    function profitLoss(address account) external view returns (int pnl, bool invalid) {
        account;
        return (0, false);
    }

    function accruedFunding(address account) external view returns (int funding, bool invalid) {
        account;
        return (0, false);
    }

    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid) {
        account;
        return (0, false);
    }

    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid) {
        account;
        return (0, false);
    }

    function liquidationPrice(address account) external view returns (uint price, bool invalid) {
        account;
        return (0, false);
    }

    function liquidationFee(address account) external view returns (uint) {
        account;
        return 0;
    }

    function canLiquidate(address account) external view returns (bool) {
        account;
        return false;
    }

    function orderFee(int sizeDelta, IPerpsV2MarketBaseTypes.OrderType orderType)
        external
        view
        returns (uint fee, bool invalid)
    {
        sizeDelta;
        orderType;
        return (0, false);
    }

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
        )
    {
        sizeDelta;
        tradePrice;
        orderType;
        sender;
        return (0, 0, 0, 0, 0, Status.Ok);
    }

    /* ========== Market ========== */
    function recomputeFunding() external returns (uint lastIndex) {
        return 0;
    }

    function transferMargin(int marginDelta) external {
        marginDelta;
    }

    function withdrawAllMargin() external {}

    function modifyPosition(int sizeDelta, uint desiredFillPrice) external {
        sizeDelta;
        desiredFillPrice;
    }

    function modifyPositionWithTracking(
        int sizeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external {
        sizeDelta;
        desiredFillPrice;
        trackingCode;
    }

    function closePosition(uint desiredFillPrice) external {
        desiredFillPrice;
    }

    function closePositionWithTracking(uint desiredFillPrice, bytes32 trackingCode) external {
        desiredFillPrice;
        trackingCode;
    }

    function flagPosition(address account) external {}

    function liquidatePosition(address account) external {}

    function forceLiquidatePosition(address account) external {}

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
    ) external {
        sizeDelta;
        desiredTimeDelta;
        desiredFillPrice;
    }

    function submitDelayedOrderWithTracking(
        int sizeDelta,
        uint desiredTimeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external {
        sizeDelta;
        desiredTimeDelta;
        desiredFillPrice;
        trackingCode;
    }

    function submitOffchainDelayedOrder(int sizeDelta, uint desiredFillPrice) external {
        sizeDelta;
        desiredFillPrice;
    }

    function submitOffchainDelayedOrderWithTracking(
        int sizeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external {
        sizeDelta;
        desiredFillPrice;
        trackingCode;
    }

    /* ========== Delayed Execution ========== */
    function executeOrder(address account, bytes[] calldata priceUpdateData) external payable {
        account;
        priceUpdateData;
    }

    function cancelOrder(address account) external {
        account;
    }

    function executeDelayedOrder(address account) external {
        account;
    }

    function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable {
        account;
        priceUpdateData;
    }

    function cancelDelayedOrder(address account) external {
        account;
    }

    function cancelOffchainDelayedOrder(address account) external {
        account;
    }
}
