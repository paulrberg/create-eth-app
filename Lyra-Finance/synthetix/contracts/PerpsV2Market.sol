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
import "./PerpsV2MarketProxyable.sol";
import "./interfaces/IPerpsV2Market.sol";

/*
 * Synthetic PerpsV2
 * =================
 *
 * PerpsV2 markets allow users leveraged exposure to an asset, long or short.
 * A user must post some margin in order to open a perpsV2 account, and profits/losses are
 * continually tallied against this margin. If a user's margin runs out, then their position is closed
 * by a liquidation keeper, which is rewarded with a flat fee extracted from the margin.
 *
 * The Synthetix debt pool is effectively the counterparty to each trade, so if a particular position
 * is in profit, then the debt pool pays by issuing sUSD into their margin account,
 * while if the position makes a loss then the debt pool burns sUSD from the margin, reducing the
 * debt load in the system.
 *
 * As the debt pool underwrites all positions, the debt-inflation risk to the system is proportional to the
 * long-short skew in the market. It is therefore in the interest of the system to reduce the skew.
 * To encourage the minimisation of the skew, each position is charged a funding rate, which increases with
 * the size of the skew. The funding rate is charged continuously, and positions on the heavier side of the
 * market are charged the current funding rate times the notional value of their position, while positions
 * on the lighter side are paid at the same rate to keep their positions open.
 * As the funding rate is the same (but negated) on both sides of the market, there is an excess quantity of
 * funding being charged, which is collected by the debt pool, and serves to reduce the system debt.
 *
 * The contract architecture is as follows:
 *
 *     - FuturesMarketManager.sol:  the manager keeps track of which markets exist, and is the main window between
 *                                  futures and perpsV2 markets and the rest of the system. It accumulates the total debt
 *                                  over all markets, and issues and burns sUSD on each market's behalf.
 *
 *     - PerpsV2MarketSettings.sol: Holds the settings for each market in the global FlexibleStorage instance used
 *                                  by SystemSettings, and provides an interface to modify these values. Other than
 *                                  the base asset, these settings determine the behaviour of each market.
 *                                  See that contract for descriptions of the meanings of each setting.
 *
 * Each market is composed of the following pieces, one of each of this exists per asset:
 *
 *     - ProxyPerpsV2.sol:          The Proxy is the main entry point and visible, permanent address of the market.
 *                                  It acts as a combination of Proxy and Router sending the messages to the
 *                                  appropriate implementation (or fragment) of the Market.
 *                                  Margin is maintained isolated per market. each market is composed of several
 *                                  contracts (or fragments) accessed by this proxy:
 *                                  `base` contains all the common logic and is inherited by other fragments.
 *                                  It's treated as abstract and not deployed alone;
 *                                  `proxyable` is an extension of `base` that implements the proxyable interface
 *                                  and is used as base for fragments that require the messageSender.
 *                                  `mutations` contains the basic market behaviour
 *                                  `views` contains functions to provide visibility to different parameters and
 *                                  is used by external or manager contracts.
 *                                  `delayedOrders` contains the logic to implement the delayed order flows.
 *                                  `offchainDelayedOrders` contains the logic to implement the delayed order
 *                                  with off-chain pricing flows.
 *
 *     - PerpsV2State.sol:          The State contracts holds all the state for the market and is consumed/updated
 *                                  by the fragments.
 *                                  It provides access to the positions in case a migration is needed in the future.
 *
 *     - PerpsV2Market.sol:         Contains the core logic to implement the market and position flows.
 *
 *     - PerpsV2MarketViews.sol:    Contains the logic to access market and positions parameters by external or
 *                                  manager contracts
 *
 *     - PerpsV2MarketDelayedOrdersOffchain.sol: Contains the logic to implement delayed order with off-chain pricing flows
 *
 *
 * Technical note: internal functions within the PerpsV2Market contract assume the following:
 *
 *     - prices passed into them are valid;
 *     - funding has already been recomputed up to the current time (hence unrecorded funding is nil);
 *     - the account being managed was not liquidated in the same transaction;
 */

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2Market
contract PerpsV2Market is IPerpsV2Market, PerpsV2MarketProxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketProxyable(_proxy, _marketState, _owner, _resolver) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Pushes a new entry to the funding sequence at the current price and funding rate.
     * @dev Admin only method accessible to PerpsV2MarketSettings. This is admin only because:
     * - When system parameters change, funding should be recomputed, but system may be paused
     *   during that time for any reason, so this method needs to work even if system is paused.
     *   But in that case, it shouldn't be accessible to external accounts.
     */
    function recomputeFunding() external returns (uint lastIndex) {
        // only PerpsV2MarketSettings is allowed to use this method (calling it directly, not via proxy)
        _revertIfError(messageSender != _settings(), Status.NotPermitted);
        // This method is the only mutative method that uses the view _assetPrice()
        // and not the mutative _assetPriceRequireSystemChecks() that reverts on system flags.
        // This is because this method is used by system settings when changing funding related
        // parameters, so needs to function even when system / market is paused. E.g. to facilitate
        // market migration.
        (uint price, bool invalid) = _assetPrice();
        // A check for a valid price is still in place, to ensure that a system settings action
        // doesn't take place when the price is invalid (e.g. some oracle issue).
        require(!invalid, "Invalid price");
        return _recomputeFunding(price);
    }

    function _transferMargin(
        int marginDelta,
        uint price,
        address sender
    ) internal {
        // Transfer no tokens if marginDelta is 0
        uint absDelta = _abs(marginDelta);
        if (marginDelta > 0) {
            // A positive margin delta corresponds to a deposit, which will be burnt from their
            // sUSD balance and credited to their margin account.

            // Ensure we handle reclamation when burning tokens.
            uint postReclamationAmount = _manager().burnSUSD(sender, absDelta);
            if (postReclamationAmount != absDelta) {
                // If balance was insufficient, the actual delta will be smaller
                marginDelta = int(postReclamationAmount);
            }
        } else if (marginDelta < 0) {
            // A negative margin delta corresponds to a withdrawal, which will be minted into
            // their sUSD balance, and debited from their margin account.
            _manager().issueSUSD(sender, absDelta);
        } else {
            // Zero delta is a no-op
            return;
        }

        Position memory position = marketState.positions(sender);

        _updatePositionMargin(sender, position, price, marginDelta);

        emitMarginTransferred(sender, marginDelta);

        emitPositionModified(position.id, sender, position.margin, position.size, 0, price, _latestFundingIndex(), 0);
    }

    /*
     * Alter the amount of margin in a position. A positive input triggers a deposit; a negative one, a
     * withdrawal. The margin will be burnt or issued directly into/out of the caller's sUSD wallet.
     * Reverts on deposit if the caller lacks a sufficient sUSD balance.
     * Reverts on withdrawal if the amount to be withdrawn would expose an open position to liquidation.
     */
    function transferMargin(int marginDelta) external onlyProxy {
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);
        _transferMargin(marginDelta, price, messageSender);
    }

    /*
     * Withdraws all accessible margin in a position. This will leave some remaining margin
     * in the account if the caller has a position open. Equivalent to `transferMargin(-accessibleMargin(sender))`.
     */
    function withdrawAllMargin() external onlyProxy {
        address sender = messageSender;
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);
        int marginDelta = -int(_accessibleMargin(marketState.positions(sender), price));
        _transferMargin(marginDelta, price, sender);
    }

    /*
     * Adjust the sender's position size.
     * Reverts if the resulting position is too large, outside the max leverage, or is liquidating.
     */
    function modifyPosition(int sizeDelta, uint priceImpactDelta) external {
        _modifyPosition(sizeDelta, priceImpactDelta, bytes32(0));
    }

    /*
     * Same as modifyPosition, but emits an event with the passed tracking code to
     * allow off-chain calculations for fee sharing with originating integrations
     */
    function modifyPositionWithTracking(
        int sizeDelta,
        uint priceImpactDelta,
        bytes32 trackingCode
    ) external {
        _modifyPosition(sizeDelta, priceImpactDelta, trackingCode);
    }

    function _modifyPosition(
        int sizeDelta,
        uint priceImpactDelta,
        bytes32 trackingCode
    ) internal onlyProxy {
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);
        _trade(
            messageSender,
            TradeParams({
                sizeDelta: sizeDelta,
                oraclePrice: price,
                fillPrice: _fillPrice(sizeDelta, price),
                takerFee: _takerFee(_marketKey()),
                makerFee: _makerFee(_marketKey()),
                priceImpactDelta: priceImpactDelta,
                trackingCode: trackingCode
            })
        );
    }

    /*
     * Submit an order to close a position.
     */
    function closePosition(uint priceImpactDelta) external {
        _closePosition(priceImpactDelta, bytes32(0));
    }

    /// Same as closePosition, but emits an even with the trackingCode for volume source fee sharing
    function closePositionWithTracking(uint priceImpactDelta, bytes32 trackingCode) external {
        _closePosition(priceImpactDelta, trackingCode);
    }

    function _closePosition(uint priceImpactDelta, bytes32 trackingCode) internal onlyProxy {
        int size = marketState.positions(messageSender).size;
        _revertIfError(size == 0, Status.NoPositionOpen);
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);
        _trade(
            messageSender,
            // note: the -size here is needed to completely close the position.
            TradeParams({
                sizeDelta: -size,
                oraclePrice: price,
                fillPrice: _fillPrice(-size, price),
                takerFee: _takerFee(_marketKey()),
                makerFee: _makerFee(_marketKey()),
                priceImpactDelta: priceImpactDelta,
                trackingCode: trackingCode
            })
        );
    }

    function _liquidatePosition(
        address account,
        address liquidator,
        uint price
    ) internal {
        Position memory position = marketState.positions(account);

        // Get remaining margin for sending any leftover buffer to fee pool
        //
        // note: we do _not_ use `_remainingLiquidatableMargin` here as we want to send this premium to the fee pool
        // upon liquidation to give back to stakers.
        uint remMargin = _remainingMargin(position, price);

        // Record updates to market size and debt.
        int positionSize = position.size;
        uint positionId = position.id;
        marketState.setMarketSkew(int128(int(marketState.marketSkew()).sub(positionSize)));
        marketState.setMarketSize(uint128(uint(marketState.marketSize()).sub(_abs(positionSize))));

        uint fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), 0, uint128(price), 0),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(positionSize))
        );

        // Close the position itself.
        marketState.deletePosition(account);

        // Issue the reward to the liquidator.
        uint liqFee = _liquidationFee(positionSize, price);
        _manager().issueSUSD(liquidator, liqFee);

        emitPositionModified(positionId, account, 0, 0, 0, price, fundingIndex, 0);
        emitPositionLiquidated(positionId, account, liquidator, positionSize, price, liqFee);

        // Send any positive margin buffer to the fee pool
        if (remMargin > liqFee) {
            _manager().payFee(remMargin.sub(liqFee));
        }
    }

    /*
     * Liquidate a position if its remaining margin is below the liquidation fee. This succeeds if and only if
     * `canLiquidate(account)` is true, and reverts otherwise.
     * Upon liquidation, the position will be closed, and the liquidation fee minted into the liquidator's account.
     */
    function liquidatePosition(address account) external onlyProxy {
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);

        _revertIfError(!_canLiquidate(marketState.positions(account), price), Status.CannotLiquidate);

        _liquidatePosition(account, messageSender, price);
    }
}
