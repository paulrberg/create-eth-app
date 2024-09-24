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
  
  pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Inheritance
import "./PerpsV2MarketDelayedOrdersBase.sol";
import "./interfaces/IPerpsV2MarketOffchainOrders.sol";

// Reference
import "./interfaces/IPerpsV2ExchangeRate.sol";
import "./interfaces/IPyth.sol";

/**
 Contract that implements DelayedOrders (offchain) mechanism for the PerpsV2 market.
 The purpose of the mechanism is to allow reduced fees for trades that commit to next price instead
 of current price. Specifically, this should serve funding rate arbitrageurs, such that funding rate
 arb is profitable for smaller skews. This in turn serves the protocol by reducing the skew, and so
 the risk to the debt pool, and funding rate for traders.
 The fees can be reduced when committing to next price, because front-running (MEV and oracle delay)
 is less of a risk when committing to next price.
 The relative complexity of the mechanism is due to having to enforce the "commitment" to the trade
 without either introducing free (or cheap) optionality to cause cancellations, and without large
 sacrifices to the UX / risk of the traders (e.g. blocking all actions, or penalizing failures too much).
 */
// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketDelayedOrdersOffchain
contract PerpsV2MarketDelayedOrdersOffchain is IPerpsV2MarketOffchainOrders, PerpsV2MarketDelayedOrdersBase {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketDelayedOrdersBase(_proxy, _marketState, _owner, _resolver) {}

    function _perpsV2ExchangeRate() internal view returns (IPerpsV2ExchangeRate) {
        return IPerpsV2ExchangeRate(requireAndGetAddress(CONTRACT_PERPSV2EXCHANGERATE));
    }

    ///// Mutative methods

    /**
     * @notice submits an order to be filled some time in the future or at a price of the next oracle update.
     * Reverts if a previous order still exists (wasn't executed or cancelled).
     * Reverts if the order cannot be filled at current price to prevent withholding commitFee for
     * incorrectly submitted orders (that cannot be filled).
     *
     * The order is executable after desiredTimeDelta. However, we also allow execution if the next price update
     * occurs before the desiredTimeDelta.
     * Reverts if the desiredTimeDelta is < minimum required delay.
     *
     * @param sizeDelta size in baseAsset (notional terms) of the order, similar to `modifyPosition` interface
     * @param priceImpactDelta is a percentage tolerance on fillPrice to be check upon execution
     */
    function submitOffchainDelayedOrder(int sizeDelta, uint priceImpactDelta) external onlyProxy {
        // @dev market key is obtained here and not in internal function to prevent stack too deep there
        // bytes32 marketKey = _marketKey();

        // enforcing desiredTimeDelta to 0 to use default (not needed for offchain delayed order)
        _submitDelayedOrder(_marketKey(), sizeDelta, priceImpactDelta, 0, bytes32(0), true);
    }

    function submitOffchainDelayedOrderWithTracking(
        int sizeDelta,
        uint priceImpactDelta,
        bytes32 trackingCode
    ) external onlyProxy {
        // @dev market key is obtained here and not in internal function to prevent stack too deep there
        // bytes32 marketKey = _marketKey();

        _submitDelayedOrder(_marketKey(), sizeDelta, priceImpactDelta, 0, trackingCode, true);
    }

    /**
     * @notice Cancels an existing order for an account.
     * Anyone can call this method for any account, but only the account owner
     *  can cancel their own order during the period when it can still potentially be executed (before it becomes stale).
     *  Only after the order becomes stale, can anyone else (e.g. a keeper) cancel the order for the keeperFee.
     * Cancelling the order:
     * - Removes the stored order.
     * - commitFee (deducted during submission) is sent to the fee pool.
     * - keeperFee (deducted during submission) is refunded into margin if it's the account holder,
     *  or send to the msg.sender if it's not the account holder.
     * @param account the account for which the stored order should be cancelled
     */
    function cancelOffchainDelayedOrder(address account) external onlyProxy {
        // important!! order of the account, not the msg.sender
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(order.isOffchain, "use onchain method");

        _cancelDelayedOrder(account, order);
    }

    /**
     * @notice Tries to execute a previously submitted delayed order.
     * Reverts if:
     * - There is no order
     * - Target roundId wasn't reached yet
     * - Order is stale (target roundId is too low compared to current roundId).
     * - Order fails for accounting reason (e.g. margin was removed, leverage exceeded, etc)
     * - Time delay and target round has not yet been reached
     * If order reverts, it has to be removed by calling cancelDelayedOrder().
     * Anyone can call this method for any account.
     * If this is called by the account holder - the keeperFee is refunded into margin,
     *  otherwise it sent to the msg.sender.
     * @param account address of the account for which to try to execute a delayed order
     */
    function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable onlyProxy {
        // important!: order of the account, not the sender!
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(order.isOffchain, "use onchain method");

        // update price feed (this is payable)
        _perpsV2ExchangeRate().updatePythPrice.value(msg.value)(messageSender, priceUpdateData);

        // get latest price for asset
        uint maxAge = _offchainDelayedOrderMaxAge(_marketKey());
        uint minAge = _offchainDelayedOrderMinAge(_marketKey());

        (uint currentPrice, uint executionTimestamp) = _offchainAssetPriceRequireSystemChecks(maxAge);

        require((executionTimestamp > order.intentionTime), "price not updated");
        require((executionTimestamp - order.intentionTime > minAge), "too early");
        require((executionTimestamp - order.intentionTime < maxAge), "too late");

        _executeDelayedOrder(
            account,
            order,
            currentPrice,
            0,
            _takerFeeOffchainDelayedOrder(_marketKey()),
            _makerFeeOffchainDelayedOrder(_marketKey())
        );
    }

    // solhint-disable no-unused-vars
    function _confirmCanCancel(
        address account,
        DelayedOrder memory order,
        uint currentRoundId
    ) internal {
        require(block.timestamp - order.intentionTime > _offchainDelayedOrderMaxAge(_marketKey()) * 2, "cannot cancel yet");
    }

    ///// Internal

    /*
     * The current base price, reverting if it is invalid, or if system or synth is suspended.
     */
    function _offchainAssetPriceRequireSystemChecks(uint maxAge) internal returns (uint price, uint publishTime) {
        // Onchain oracle asset price
        uint onchainPrice = _assetPriceRequireSystemChecks(true);
        (price, publishTime) = _perpsV2ExchangeRate().resolveAndGetPrice(_baseAsset(), maxAge);

        require(onchainPrice > 0 && price > 0, "invalid, price is 0");

        uint delta =
            (onchainPrice > price)
                ? onchainPrice.divideDecimal(price).sub(SafeDecimalMath.unit())
                : price.divideDecimal(onchainPrice).sub(SafeDecimalMath.unit());
        require(_offchainPriceDivergence(_marketKey()) > delta, "price divergence too high");

        return (price, publishTime);
    }
}
