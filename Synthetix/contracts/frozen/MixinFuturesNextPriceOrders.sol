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

// Inheritance
import "./FuturesMarketBase.sol";

/**
 Mixin that implements NextPrice orders mechanism for the futures market.
 The purpose of the mechanism is to allow reduced fees for trades that commit to next price instead
 of current price. Specifically, this should serve funding rate arbitrageurs, such that funding rate
 arb is profitable for smaller skews. This in turn serves the protocol by reducing the skew, and so
 the risk to the debt pool, and funding rate for traders. 
 The fees can be reduced when comitting to next price, because front-running (MEV and oracle delay)
 is less of a risk when committing to next price.
 The relative complexity of the mechanism is due to having to enforce the "commitment" to the trade
 without either introducing free (or cheap) optionality to cause cancellations, and without large
 sacrifices to the UX / risk of the traders (e.g. blocking all actions, or penalizing failures too much).
 */
contract MixinFuturesNextPriceOrders is FuturesMarketBase {
    /// @dev Holds a mapping of accounts to orders. Only one order per account is supported
    mapping(address => NextPriceOrder) public nextPriceOrders;

    ///// Mutative methods

    /**
     * @notice submits an order to be filled at a price of the next oracle update.
     * Reverts if a previous order still exists (wasn't executed or cancelled).
     * Reverts if the order cannot be filled at current price to prevent witholding commitFee for
     * incorrectly submitted orders (that cannot be filled).
     * @param sizeDelta size in baseAsset (notional terms) of the order, similar to `modifyPosition` interface
     */
    function submitNextPriceOrder(int sizeDelta) external {
        _submitNextPriceOrder(sizeDelta, bytes32(0));
    }

    /// same as submitNextPriceOrder but emits an event with the tracking code
    /// to allow volume source fee sharing for integrations
    function submitNextPriceOrderWithTracking(int sizeDelta, bytes32 trackingCode) external {
        _submitNextPriceOrder(sizeDelta, trackingCode);
    }

    function _submitNextPriceOrder(int sizeDelta, bytes32 trackingCode) internal {
        // check that a previous order doesn't exist
        require(nextPriceOrders[msg.sender].sizeDelta == 0, "previous order exists");

        // storage position as it's going to be modified to deduct commitFee and keeperFee
        Position storage position = positions[msg.sender];

        // to prevent submitting bad orders in good faith and being charged commitDeposit for them
        // simulate the order with current price and market and check that the order doesn't revert
        uint price = _assetPriceRequireSystemChecks();
        uint fundingIndex = _recomputeFunding(price);
        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFeeNextPrice(marketKey),
                makerFee: _makerFeeNextPrice(marketKey),
                trackingCode: trackingCode
            });
        (, , Status status) = _postTradeDetails(position, params);
        _revertIfError(status);

        // deduct fees from margin
        uint commitDeposit = _nextPriceCommitDeposit(params);
        uint keeperDeposit = _minKeeperFee();
        _updatePositionMargin(position, price, -int(commitDeposit + keeperDeposit));
        // emit event for modifying the position (subtracting the fees from margin)
        emit PositionModified(position.id, msg.sender, position.margin, position.size, 0, price, fundingIndex, 0);

        // create order
        uint targetRoundId = _exchangeRates().getCurrentRoundId(baseAsset) + 1; // next round
        NextPriceOrder memory order =
            NextPriceOrder({
                sizeDelta: int128(sizeDelta),
                targetRoundId: uint128(targetRoundId),
                commitDeposit: uint128(commitDeposit),
                keeperDeposit: uint128(keeperDeposit),
                trackingCode: trackingCode
            });
        // emit event
        emit NextPriceOrderSubmitted(
            msg.sender,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
        // store order
        nextPriceOrders[msg.sender] = order;
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
    function cancelNextPriceOrder(address account) external {
        // important!! order of the account, not the msg.sender
        NextPriceOrder memory order = nextPriceOrders[account];
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        uint currentRoundId = _exchangeRates().getCurrentRoundId(baseAsset);

        if (account == msg.sender) {
            // this is account owner
            // refund keeper fee to margin
            Position storage position = positions[account];
            uint price = _assetPriceRequireSystemChecks();
            uint fundingIndex = _recomputeFunding(price);
            _updatePositionMargin(position, price, int(order.keeperDeposit));

            // emit event for modifying the position (add the fee to margin)
            emit PositionModified(position.id, account, position.margin, position.size, 0, price, fundingIndex, 0);
        } else {
            // this is someone else (like a keeper)
            // cancellation by third party is only possible when execution cannot be attempted any longer
            // otherwise someone might try to grief an account by cancelling for the keeper fee
            require(_confirmationWindowOver(currentRoundId, order.targetRoundId), "cannot be cancelled by keeper yet");

            // send keeper fee to keeper
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
        }

        // pay the commitDeposit as fee to the FeePool
        _manager().payFee(order.commitDeposit);

        // remove stored order
        // important!! position of the account, not the msg.sender
        delete nextPriceOrders[account];
        // emit event
        emit NextPriceOrderRemoved(
            account,
            currentRoundId,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
    }

    /**
     * @notice Tries to execute a previously submitted next-price order.
     * Reverts if:
     * - There is no order
     * - Target roundId wasn't reached yet
     * - Order is stale (target roundId is too low compared to current roundId).
     * - Order fails for accounting reason (e.g. margin was removed, leverage exceeded, etc)
     * If order reverts, it has to be removed by calling cancelNextPriceOrder().
     * Anyone can call this method for any account.
     * If this is called by the account holder - the keeperFee is refunded into margin,
     *  otherwise it sent to the msg.sender.
     * @param account address of the account for which to try to execute a next-price order
     */
    function executeNextPriceOrder(address account) external {
        // important!: order  of the account, not the sender!
        NextPriceOrder memory order = nextPriceOrders[account];
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        // check round-Id
        uint currentRoundId = _exchangeRates().getCurrentRoundId(baseAsset);
        require(order.targetRoundId <= currentRoundId, "target roundId not reached");

        // check order is not too old to execute
        // we cannot allow executing old orders because otherwise future knowledge
        // can be used to trigger failures of orders that are more profitable
        // then the commitFee that was charged, or can be used to confirm
        // orders that are more profitable than known then (which makes this into a "cheap option").
        require(!_confirmationWindowOver(currentRoundId, order.targetRoundId), "order too old, use cancel");

        // handle the fees and refunds according to the mechanism rules
        uint toRefund = order.commitDeposit; // refund the commitment deposit

        // refund keeperFee to margin if it's the account holder
        if (msg.sender == account) {
            toRefund += order.keeperDeposit;
        } else {
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
        }

        Position storage position = positions[account];
        uint currentPrice = _assetPriceRequireSystemChecks();
        uint fundingIndex = _recomputeFunding(currentPrice);
        // refund the commitFee (and possibly the keeperFee) to the margin before executing the order
        // if the order later fails this is reverted of course
        _updatePositionMargin(position, currentPrice, int(toRefund));
        // emit event for modifying the position (refunding fee/s)
        emit PositionModified(position.id, account, position.margin, position.size, 0, currentPrice, fundingIndex, 0);

        // the correct price for the past round
        (uint pastPrice, ) = _exchangeRates().rateAndTimestampAtRound(baseAsset, order.targetRoundId);
        // execute or revert
        _trade(
            account,
            TradeParams({
                sizeDelta: order.sizeDelta, // using the pastPrice from the target roundId
                price: pastPrice, // the funding is applied only from order confirmation time
                takerFee: _takerFeeNextPrice(marketKey),
                makerFee: _makerFeeNextPrice(marketKey),
                trackingCode: order.trackingCode
            })
        );

        // remove stored order
        delete nextPriceOrders[account];
        // emit event
        emit NextPriceOrderRemoved(
            account,
            currentRoundId,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
    }

    ///// Internal views

    // confirmation window is over when current roundId is more than nextPriceConfirmWindow
    // rounds after target roundId
    function _confirmationWindowOver(uint currentRoundId, uint targetRoundId) internal view returns (bool) {
        return (currentRoundId > targetRoundId) && (currentRoundId - targetRoundId > _nextPriceConfirmWindow(marketKey)); // don't underflow
    }

    // convenience view to access exchangeRates contract for methods that are not exposed
    // via _exchangeCircuitBreaker() contract
    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(_exchangeCircuitBreaker().exchangeRates());
    }

    // calculate the commitFee, which is the fee that would be charged on the order if it was spot
    function _nextPriceCommitDeposit(TradeParams memory params) internal view returns (uint) {
        // modify params to spot fee
        params.takerFee = _takerFee(marketKey);
        params.makerFee = _makerFee(marketKey);
        // Commit fee is equal to the spot fee that would be paid.
        // This is to prevent free cancellation manipulations (by e.g. withdrawing the margin).
        // The dynamic fee rate is passed as 0 since for the purposes of the commitment deposit
        // it is not important since at the time of order execution it will be refunded and the correct
        // dynamic fee will be charged.
        return _orderFee(params, 0);
    }

    ///// Events
    event NextPriceOrderSubmitted(
        address indexed account,
        int sizeDelta,
        uint targetRoundId,
        uint commitDeposit,
        uint keeperDeposit,
        bytes32 trackingCode
    );

    event NextPriceOrderRemoved(
        address indexed account,
        uint currentRoundId,
        int sizeDelta,
        uint targetRoundId,
        uint commitDeposit,
        uint keeperDeposit,
        bytes32 trackingCode
    );
}
