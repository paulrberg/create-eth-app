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

// Inheritance
import "./PerpsV2MarketProxyable.sol";
import "./interfaces/IPerpsV2MarketDelayedExecution.sol";

// Reference
import "./interfaces/IPerpsV2MarketBaseTypes.sol";
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
// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketDelayedExecution
contract PerpsV2MarketDelayedExecution is IPerpsV2MarketDelayedExecution, PerpsV2MarketProxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketProxyable(_proxy, _marketState, _owner, _resolver) {}

    function _perpsV2ExchangeRate() internal view returns (IPerpsV2ExchangeRate) {
        return IPerpsV2ExchangeRate(requireAndGetAddress(CONTRACT_PERPSV2EXCHANGERATE));
    }

    ///// Mutative methods

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
    function executeDelayedOrder(address account) external onlyProxy {
        // important!: order of the account, not the sender!
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(!order.isOffchain, "use offchain method");

        uint currentRoundId = _exchangeRates().getCurrentRoundId(_baseAsset());
        require(
            block.timestamp >= order.executableAtTime || order.targetRoundId <= currentRoundId,
            "executability not reached"
        );

        // check order is not too old to execute
        // we cannot allow executing old orders because otherwise future knowledge
        // can be used to trigger failures of orders that are more profitable
        // then the commitFee that was charged, or can be used to confirm
        // orders that are more profitable than known then (which makes this into a "cheap option").
        require(
            !_confirmationWindowOver(order.executableAtTime, currentRoundId, order.targetRoundId),
            "order too old, use cancel"
        );

        // price depends on whether the delay or price update has reached/occurred first
        _executeDelayedOrder(
            account,
            order,
            _assetPriceRequireSystemChecks(false),
            currentRoundId,
            _takerFeeDelayedOrder(_marketKey()),
            _makerFeeDelayedOrder(_marketKey())
        );
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
        require((executionTimestamp - order.intentionTime > minAge), "executability not reached");
        require((block.timestamp - order.intentionTime < maxAge), "order too old, use cancel");

        _executeDelayedOrder(
            account,
            order,
            currentPrice,
            0,
            _takerFeeOffchainDelayedOrder(_marketKey()),
            _makerFeeOffchainDelayedOrder(_marketKey())
        );
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
    function cancelDelayedOrder(address account) external onlyProxy {
        // important!! order of the account, not the msg.sender
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(!order.isOffchain, "use offchain method");

        _cancelDelayedOrder(account, order);
    }

    /**
     * @notice Cancels an existing order for an account.
     * Anyone can call this method for any account after the order becomes stale for the keeperFee.
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

    function _confirmCanCancel(DelayedOrder memory order, uint currentRoundId) internal {
        if (order.isOffchain) {
            require(block.timestamp - order.intentionTime > _offchainDelayedOrderMaxAge(_marketKey()), "cannot cancel yet");
        } else {
            require(
                _confirmationWindowOver(order.executableAtTime, currentRoundId, order.targetRoundId),
                "cannot be cancelled by keeper yet"
            );
        }
    }

    ///// Internal

    /// confirmation window is over when:
    ///  1. current roundId is more than nextPriceConfirmWindow rounds after target roundId
    ///  2. or executableAtTime - block.timestamp is more than delayedOrderConfirmWindow
    ///
    /// if either conditions are met, an order is considered to have exceeded the window.
    function _confirmationWindowOver(
        uint executableAtTime,
        uint currentRoundId,
        uint targetRoundId
    ) internal view returns (bool) {
        bytes32 marketKey = _marketKey();
        return
            (block.timestamp > executableAtTime &&
                (block.timestamp - executableAtTime) > _delayedOrderConfirmWindow(marketKey)) ||
            ((currentRoundId > targetRoundId) && (currentRoundId - targetRoundId > _nextPriceConfirmWindow(marketKey))); // don't underflow
    }

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

    function _cancelDelayedOrder(address account, DelayedOrder memory order) internal {
        uint currentRoundId = _exchangeRates().getCurrentRoundId(_baseAsset());

        _confirmCanCancel(order, currentRoundId);

        if (account == messageSender) {
            // this is account owner - refund keeper fee to margin
            Position memory position = marketState.positions(account);

            // cancelling an order does not induce a fillPrice as no skew has moved.
            uint price = _assetPriceRequireSystemChecks(false);
            uint fundingIndex = _recomputeFunding(price);
            _updatePositionMargin(account, position, order.sizeDelta, price, int(order.keeperDeposit));

            // emit event for modifying the position (add the fee to margin)
            emitPositionModified(
                position.id,
                account,
                position.margin,
                position.size,
                0,
                price,
                fundingIndex,
                0,
                marketState.marketSkew()
            );
        } else {
            // send keeper fee to keeper
            _manager().issueSUSD(messageSender, order.keeperDeposit);
        }

        // note: pay debt pool in the event there is any commitFee
        //
        // this should never occur but may during release as there may be lingering orders to be cancelled
        // which was submitted with a commitFee either before or during the upgrade.
        if (order.commitDeposit > 0) {
            _manager().payFee(order.commitDeposit);
        }

        // important!! position of the account, not the msg.sender
        marketState.deleteDelayedOrder(account);
        emitDelayedOrderRemoved(account, currentRoundId, order);
    }

    function _executeDelayedOrder(
        address account,
        DelayedOrder memory order,
        uint currentPrice,
        uint currentRoundId,
        uint takerFee,
        uint makerFee
    ) internal {
        // handle the fees and refunds according to the mechanism rules
        //
        // note: commitDeposit will always be 0 as we no longer charge a commitDeposit on submit. however,
        // during upgrade there may be pending orders for execution with a commitDeposit.
        uint toRefund = order.commitDeposit; // refund the commitment deposit

        // refund keeperFee to margin if it's the account holder
        if (messageSender == account) {
            toRefund += order.keeperDeposit;
        } else {
            _manager().issueSUSD(messageSender, order.keeperDeposit);
        }

        Position memory position = marketState.positions(account);

        uint fundingIndex = _recomputeFunding(currentPrice);

        // we need to grab the fillPrice for events and margin updates.
        uint fillPrice = _fillPrice(order.sizeDelta, currentPrice);

        // refund the commitFee (and possibly the keeperFee) to the margin before executing the order
        // if the order later fails this is reverted of course
        if (toRefund > 0) {
            _updatePositionMargin(account, position, order.sizeDelta, fillPrice, int(toRefund));
            // emit event for modifying the position (refunding fee/s)
            emitPositionModified(
                position.id,
                account,
                position.margin,
                position.size,
                0,
                fillPrice,
                fundingIndex,
                0,
                marketState.marketSkew()
            );
        }

        // execute or revert
        _trade(
            account,
            TradeParams({
                sizeDelta: order.sizeDelta, // using the pastPrice from the target roundId
                oraclePrice: currentPrice, // the funding is applied only from order confirmation time
                fillPrice: fillPrice,
                takerFee: takerFee, //_takerFeeDelayedOrder(_marketKey()),
                makerFee: makerFee, //_makerFeeDelayedOrder(_marketKey()),
                desiredFillPrice: order.desiredFillPrice,
                trackingCode: order.trackingCode
            })
        );

        // remove stored order
        marketState.deleteDelayedOrder(account);
        // emit event
        emitDelayedOrderRemoved(account, currentRoundId, order);
    }

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
    bytes32 internal constant DELAYEDORDERREMOVED_SIG =
        keccak256("DelayedOrderRemoved(address,bool,uint256,int256,uint256,uint256,uint256,bytes32)");

    function emitDelayedOrderRemoved(
        address account,
        uint currentRoundId,
        DelayedOrder memory order
    ) internal {
        proxy._emit(
            abi.encode(
                order.isOffchain,
                currentRoundId,
                order.sizeDelta,
                order.targetRoundId,
                order.commitDeposit,
                order.keeperDeposit,
                order.trackingCode
            ),
            2,
            DELAYEDORDERREMOVED_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}
