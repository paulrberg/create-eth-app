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
import "./PerpsV2MarketBase.sol";
import "./interfaces/IPerpsV2MarketViews.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketViews
contract PerpsV2MarketViews is PerpsV2MarketBase, IPerpsV2MarketViews {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketBase(_marketState, _owner, _resolver) {}

    /* ---------- Market Details ---------- */

    // The market identifier in the perpsV2 system (manager + settings). Multiple markets can co-exist
    // for the same asset in order to allow migrations.
    function marketKey() external view returns (bytes32 key) {
        return _marketKey();
    }

    // The asset being traded in this market. This should be a valid key into the ExchangeRates contract.
    function baseAsset() external view returns (bytes32 key) {
        return _baseAsset();
    }

    /*
     * Sizes of the long and short sides of the market.
     */
    function marketSize() external view returns (uint128) {
        return marketState.marketSize();
    }

    /*
     * Sizes of the long and short sides of the market.
     */
    function marketSkew() external view returns (int128) {
        return marketState.marketSkew();
    }

    /*
     * The current base price from the oracle, and whether that price was invalid. Zero prices count as invalid.
     */
    function assetPrice() external view returns (uint price, bool invalid) {
        return _assetPrice();
    }

    function fillPrice(int sizeDelta) external view returns (uint price, bool invalid) {
        (uint price, bool invalid) = _assetPrice();
        return (_fillPrice(sizeDelta, price), invalid);
    }

    /*
     * The number of entries in the funding sequence.
     */
    function fundingLastRecomputed() external view returns (uint32) {
        return marketState.fundingLastRecomputed();
    }

    /*
     * The number of entries in the funding sequence.
     */
    function fundingSequence(uint index) external view returns (int128) {
        return marketState.fundingSequence(index);
    }

    /*
     * Positions details
     */
    function positions(address account) external view returns (Position memory) {
        return marketState.positions(account);
    }

    /*
     * Sizes of the long and short sides of the market (in sUSD)
     */
    function marketSizes() external view returns (uint long, uint short) {
        int size = int(marketState.marketSize());
        int skew = marketState.marketSkew();
        return (_abs(size.add(skew).div(2)), _abs(size.sub(skew).div(2)));
    }

    /*
     * The debt contributed by this market to the overall system.
     * The total market debt is equivalent to the sum of remaining margins in all open positions.
     */
    function marketDebt() external view returns (uint debt, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_marketDebt(price), isInvalid);
    }

    /*
     * The current funding rate as determined by the market skew; this is returned as a percentage per day.
     * If this is positive, shorts pay longs, if it is negative, longs pay shorts.
     */
    function currentFundingRate() external view returns (int) {
        return _currentFundingRate();
    }

    /*
     * Velocity is a measure of how quickly the funding rate increases or decreases. A positive velocity means
     * funding rate is increasing positively (long skew). A negative velocity means the skew is on shorts.
     */
    function currentFundingVelocity() external view returns (int) {
        return _currentFundingVelocity();
    }

    /*
     * The funding per base unit accrued since the funding rate was last recomputed, which has not yet
     * been persisted in the funding sequence.
     */
    function unrecordedFunding() external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_unrecordedFunding(price), isInvalid);
    }

    /*
     * The number of entries in the funding sequence.
     */
    function fundingSequenceLength() external view returns (uint) {
        return marketState.fundingSequenceLength();
    }

    /* ---------- Position Details ---------- */

    /*
     * The notional value of a position is its size multiplied by the current price. Margin and leverage are ignored.
     */
    function notionalValue(address account) external view returns (int value, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_notionalValue(marketState.positions(account).size, price), isInvalid);
    }

    /*
     * The PnL of a position is the change in its notional value. Funding is not taken into account.
     */
    function profitLoss(address account) external view returns (int pnl, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_profitLoss(marketState.positions(account), price), isInvalid);
    }

    /*
     * The funding accrued in a position since it was opened; this does not include PnL.
     */
    function accruedFunding(address account) external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_accruedFunding(marketState.positions(account), price), isInvalid);
    }

    /*
     * The initial margin plus profit and funding; returns zero balance if losses exceed the initial margin.
     */
    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_remainingMargin(marketState.positions(account), price), isInvalid);
    }

    /*
     * The approximate amount of margin the user may withdraw given their current position; this underestimates the
     * true value slightly.
     */
    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_accessibleMargin(marketState.positions(account), price), isInvalid);
    }

    /*
     * The price at which a position is subject to liquidation; otherwise the price at which the user's remaining
     * margin has run out. When they have just enough margin left to pay a liquidator, then they are liquidated.
     * If a position is long, then it is safe as long as the current price is above the liquidation price; if it is
     * short, then it is safe whenever the current price is below the liquidation price.
     * A position's accurate liquidation price can move around slightly due to accrued funding.
     */
    function liquidationPrice(address account) external view returns (uint price, bool invalid) {
        (uint aPrice, bool isInvalid) = _assetPrice();
        return (_approxLiquidationPrice(marketState.positions(account), aPrice), isInvalid);
    }

    /**
     * The fee paid to liquidator in the event of successful liquidation of an account at current price.
     * Returns 0 if account cannot be liquidated right now.
     * @param account address of the trader's account
     * @return fee that will be paid for liquidating the account if it can be liquidated
     *  in sUSD fixed point decimal units or 0 if account is not liquidatable.
     */
    function liquidationFee(address account) external view returns (uint) {
        (uint price, bool invalid) = _assetPrice();
        if (!invalid && _canLiquidate(marketState.positions(account), price)) {
            return _liquidationFee(int(marketState.positions(account).size), price);
        } else {
            // theoretically we can calculate a value, but this value is always incorrect because
            // it's for a price at which liquidation cannot happen - so is misleading, because
            // it won't be paid, and what will be paid is a different fee (for a different price)
            return 0;
        }
    }

    /*
     * True if and only if a position is ready to be liquidated.
     */
    function canLiquidate(address account) external view returns (bool) {
        (uint price, bool invalid) = _assetPrice();
        return !invalid && _canLiquidate(marketState.positions(account), price);
    }

    /*
     * Reports the fee for submitting an order of a given size. Orders that increase the skew will be more
     * expensive than ones that decrease it. Dynamic fee is added according to the recent volatility
     * according to SIP-184.
     *
     * @param sizeDelta size of the order in baseAsset units (negative numbers for shorts / selling)
     * @param orderType the type of order to calc fees against (e.g. Delayed, Offchain, Atomic).
     * @return fee in sUSD decimal, and invalid boolean flag for invalid rates or dynamic fee that is
     * too high due to recent volatility.
     */
    function orderFee(int sizeDelta, IPerpsV2MarketBaseTypes.OrderType orderType)
        external
        view
        returns (uint fee, bool invalid)
    {
        (uint price, bool isInvalid) = _assetPrice();
        (uint dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();

        (uint makerFee, uint takerFee, bool invalid) = _makerTakeFeeByOrderType(orderType);
        if (invalid) {
            return (0, true);
        }

        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                oraclePrice: price,
                fillPrice: _fillPrice(sizeDelta, price),
                makerFee: makerFee,
                takerFee: takerFee,
                priceImpactDelta: 0, // price impact is not needed to calculate order fees.
                trackingCode: bytes32(0)
            });
        return (_orderFee(params, dynamicFeeRate), isInvalid || tooVolatile);
    }

    /*
     * @notice Returns all new position details if a given order from `sender` was confirmed at the current price.
     *
     * note: We do not check for price impact during this trade simulation.
     *
     * @param sizeDelta The size of the next trade
     * @param tradePrice An arbitrary price to simulate on. When price is 0 then the current price will be used
     * @param orderType OrderType enum to simulate fees against (e.g. Atomic, Delayed, Offchain)
     * @param sender The user holding the position we would like to simulate
     */
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
        uint makerFee;
        uint takerFee;

        // stack too deep
        {
            bool invalid;
            (makerFee, takerFee, invalid) = _makerTakeFeeByOrderType(orderType);
            if (invalid) {
                return (0, 0, 0, 0, 0, Status.InvalidOrderType);
            }

            (tradePrice, invalid) = _simulationTradePrice(tradePrice);
            if (invalid) {
                return (0, 0, 0, 0, 0, Status.InvalidPrice);
            }
        }

        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                oraclePrice: tradePrice,
                fillPrice: _fillPrice(sizeDelta, tradePrice),
                makerFee: makerFee,
                takerFee: takerFee,
                priceImpactDelta: 0,
                trackingCode: bytes32(0)
            });
        (Position memory newPosition, uint fee_, Status status_) = _postTradeDetails(marketState.positions(sender), params);

        liqPrice = _approxLiquidationPrice(newPosition, newPosition.lastPrice);
        return (newPosition.margin, newPosition.size, newPosition.lastPrice, liqPrice, fee_, status_);
    }

    function _simulationTradePrice(uint tradePrice) internal view returns (uint, bool) {
        if (tradePrice != 0) {
            return (tradePrice, false);
        }
        return _assetPrice();
    }

    /// helper to fetch the orderFee (maker/taker) bps by order type (Atomic, Delayed, Offchain).
    function _makerTakeFeeByOrderType(IPerpsV2MarketBaseTypes.OrderType orderType)
        internal
        view
        returns (
            uint makerFee,
            uint takerFee,
            bool invalid
        )
    {
        bytes32 marketKey = _marketKey();
        invalid = false;

        // Infer the maker/taker fee based on orderType. In the event an unsupported orderType is
        // provided then orderFee of 0 is returned with an invalid price bool.
        if (orderType == IPerpsV2MarketBaseTypes.OrderType.Atomic) {
            makerFee = _makerFee(marketKey);
            takerFee = _takerFee(marketKey);
        } else if (orderType == IPerpsV2MarketBaseTypes.OrderType.Delayed) {
            makerFee = _makerFeeDelayedOrder(marketKey);
            takerFee = _takerFeeDelayedOrder(marketKey);
        } else if (orderType == IPerpsV2MarketBaseTypes.OrderType.Offchain) {
            makerFee = _makerFeeOffchainDelayedOrder(marketKey);
            takerFee = _takerFeeOffchainDelayedOrder(marketKey);
        } else {
            makerFee = 0;
            takerFee = 0;
            invalid = true;
        }

        return (makerFee, takerFee, invalid);
    }

    /// helper methods calculates the approximate liquidation price
    ///
    /// note: currentPrice is oracle price and not fill price.
    function _approxLiquidationPrice(Position memory position, uint currentPrice) internal view returns (uint) {
        if (position.size == 0) {
            return 0;
        }

        // fundingPerUnit
        //  price = lastPrice + (liquidationMargin - margin) / positionSize - netAccrued
        //
        // A position can be liquidated whenever:
        //  remainingMargin <= liquidationMargin
        //
        // Hence, expanding the definition of remainingMargin the exact price at which a position can be liquidated is:
        //
        //  margin + profitLoss + funding = liquidationMargin
        //  substitute with: profitLoss = (price - last-price) * positionSize
        //  and also with: funding = netFundingPerUnit * positionSize
        //  we get: margin + (price - last-price) * positionSize + netFundingPerUnit * positionSize = liquidationMargin
        //  moving around: price = lastPrice + (liquidationMargin - margin - liqPremium) / positionSize - netFundingPerUnit
        int result =
            int(position.lastPrice)
                .add(
                int(_liquidationMargin(position.size, currentPrice))
                    .sub(int(position.margin).sub(int(_liquidationPremium(position.size, currentPrice))))
                    .divideDecimal(position.size)
            )
                .sub(_netFundingPerUnit(position.lastFundingIndex, currentPrice));

        // If the user has leverage less than 1, their liquidation price may actually be negative; return 0 instead.
        return uint(_max(0, result));
    }

    function _marketDebt(uint price) internal view returns (uint) {
        // short circuit and also convenient during setup
        if (marketState.marketSkew() == 0 && marketState.entryDebtCorrection() == 0) {
            // if these are 0, the resulting calculation is necessarily zero as well
            return 0;
        }
        // see comment explaining this calculation in _positionDebtCorrection()
        int priceWithFunding = int(price).add(_nextFundingEntry(price));
        int totalDebt =
            int(marketState.marketSkew()).multiplyDecimal(priceWithFunding).add(marketState.entryDebtCorrection());
        return uint(_max(totalDebt, 0));
    }
}
