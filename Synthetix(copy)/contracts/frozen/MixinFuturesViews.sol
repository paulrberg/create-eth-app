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
 * A mixin that implements vairous useful views that are used externally but
 * aren't used inside the core contract (so don't need to clutter the contract file)
 */
contract MixinFuturesViews is FuturesMarketBase {
    /*
     * Sizes of the long and short sides of the market (in sUSD)
     */
    function marketSizes() public view returns (uint long, uint short) {
        int size = int(marketSize);
        int skew = marketSkew;
        return (_abs(size.add(skew).div(2)), _abs(size.sub(skew).div(2)));
    }

    /*
     * The debt contributed by this market to the overall system.
     * The total market debt is equivalent to the sum of remaining margins in all open positions.
     */
    function marketDebt() external view returns (uint debt, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_marketDebt(price), isInvalid);
    }

    /*
     * The current funding rate as determined by the market skew; this is returned as a percentage per day.
     * If this is positive, shorts pay longs, if it is negative, longs pay shorts.
     */
    function currentFundingRate() external view returns (int) {
        (uint price, ) = assetPrice();
        return _currentFundingRate(price);
    }

    /*
     * The funding per base unit accrued since the funding rate was last recomputed, which has not yet
     * been persisted in the funding sequence.
     */
    function unrecordedFunding() external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_unrecordedFunding(price), isInvalid);
    }

    /*
     * The number of entries in the funding sequence.
     */
    function fundingSequenceLength() external view returns (uint) {
        return fundingSequence.length;
    }

    /*
     * The notional value of a position is its size multiplied by the current price. Margin and leverage are ignored.
     */
    function notionalValue(address account) external view returns (int value, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_notionalValue(positions[account].size, price), isInvalid);
    }

    /*
     * The PnL of a position is the change in its notional value. Funding is not taken into account.
     */
    function profitLoss(address account) external view returns (int pnl, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_profitLoss(positions[account], price), isInvalid);
    }

    /*
     * The funding accrued in a position since it was opened; this does not include PnL.
     */
    function accruedFunding(address account) external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_accruedFunding(positions[account], price), isInvalid);
    }

    /*
     * The initial margin plus profit and funding; returns zero balance if losses exceed the initial margin.
     */
    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_remainingMargin(positions[account], price), isInvalid);
    }

    /*
     * The approximate amount of margin the user may withdraw given their current position; this underestimates the
     * true value slightly.
     */
    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_accessibleMargin(positions[account], price), isInvalid);
    }

    /*
     * The price at which a position is subject to liquidation; otherwise the price at which the user's remaining
     * margin has run out. When they have just enough margin left to pay a liquidator, then they are liquidated.
     * If a position is long, then it is safe as long as the current price is above the liquidation price; if it is
     * short, then it is safe whenever the current price is below the liquidation price.
     * A position's accurate liquidation price can move around slightly due to accrued funding.
     */
    function liquidationPrice(address account) external view returns (uint price, bool invalid) {
        (uint aPrice, bool isInvalid) = assetPrice();
        uint liqPrice = _approxLiquidationPrice(positions[account], aPrice);
        return (liqPrice, isInvalid);
    }

    /**
     * The fee paid to liquidator in the event of successful liquidation of an account at current price.
     * Returns 0 if account cannot be liquidated right now.
     * @param account address of the trader's account
     * @return fee that will be paid for liquidating the account if it can be liquidated
     *  in sUSD fixed point decimal units or 0 if account is not liquidatable.
     */
    function liquidationFee(address account) external view returns (uint) {
        (uint price, bool invalid) = assetPrice();
        if (!invalid && _canLiquidate(positions[account], price)) {
            return _liquidationFee(int(positions[account].size), price);
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
        (uint price, bool invalid) = assetPrice();
        return !invalid && _canLiquidate(positions[account], price);
    }

    /*
     * Reports the fee for submitting an order of a given size. Orders that increase the skew will be more
     * expensive than ones that decrease it. Dynamic fee is added according to the recent volatility
     * according to SIP-184.
     * @param sizeDelta size of the order in baseAsset units (negative numbers for shorts / selling)
     * @return fee in sUSD decimal, and invalid boolean flag for invalid rates or dynamic fee that is
     * too high due to recent volatility.
     */
    function orderFee(int sizeDelta) external view returns (uint fee, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        (uint dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFee(marketKey),
                makerFee: _makerFee(marketKey),
                trackingCode: bytes32(0)
            });
        return (_orderFee(params, dynamicFeeRate), isInvalid || tooVolatile);
    }

    /*
     * Returns all new position details if a given order from `sender` was confirmed at the current price.
     */
    function postTradeDetails(int sizeDelta, address sender)
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
        bool invalid;
        (price, invalid) = assetPrice();
        if (invalid) {
            return (0, 0, 0, 0, 0, Status.InvalidPrice);
        }

        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFee(marketKey),
                makerFee: _makerFee(marketKey),
                trackingCode: bytes32(0)
            });
        (Position memory newPosition, uint fee_, Status status_) = _postTradeDetails(positions[sender], params);

        liqPrice = _approxLiquidationPrice(newPosition, newPosition.lastPrice);
        return (newPosition.margin, newPosition.size, newPosition.lastPrice, liqPrice, fee_, status_);
    }

    /// helper methods calculates the approximate liquidation price
    function _approxLiquidationPrice(Position memory position, uint currentPrice) internal view returns (uint) {
        int positionSize = int(position.size);

        // short circuit
        if (positionSize == 0) {
            return 0;
        }

        // price = lastPrice + (liquidationMargin - margin) / positionSize - netAccrued
        int fundingPerUnit = _netFundingPerUnit(position.lastFundingIndex, currentPrice);

        // minimum margin beyond which position can be liqudiated
        uint liqMargin = _liquidationMargin(positionSize, currentPrice);

        // A position can be liquidated whenever:
        //     remainingMargin <= liquidationMargin
        // Hence, expanding the definition of remainingMargin the exact price
        // at which a position can first be liquidated is:
        //     margin + profitLoss + funding =  liquidationMargin
        //     substitute with: profitLoss = (price - last-price) * positionSize
        //     and also with: funding = netFundingPerUnit * positionSize
        //     we get: margin + (price - last-price) * positionSize + netFundingPerUnit * positionSize =  liquidationMargin
        //     moving around: price  = lastPrice + (liquidationMargin - margin) / positionSize - netFundingPerUnit
        int result =
            int(position.lastPrice).add(int(liqMargin).sub(int(position.margin)).divideDecimal(positionSize)).sub(
                fundingPerUnit
            );

        // If the user has leverage less than 1, their liquidation price may actually be negative; return 0 instead.
        return uint(_max(0, result));
    }
}
