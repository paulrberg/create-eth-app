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

import "./Owned.sol";

// Inheritance
import "./MixinPerpsV2MarketSettings.sol";
import "./interfaces/IPerpsV2MarketBaseTypes.sol";

// Libraries
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SignedSafeDecimalMath.sol";
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IFuturesMarketManager.sol";

// Internal references
import "./interfaces/IPerpsV2MarketState.sol";

// Use internal interface (external functions not present in IFuturesMarketManager)
interface IFuturesMarketManagerInternal {
    function issueSUSD(address account, uint amount) external;

    function burnSUSD(address account, uint amount) external returns (uint postReclamationAmount);

    function payFee(uint amount) external;

    function isEndorsed(address account) external view returns (bool);
}

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketBase
contract PerpsV2MarketBase is Owned, MixinPerpsV2MarketSettings, IPerpsV2MarketBaseTypes {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SignedSafeMath for int;
    using SignedSafeDecimalMath for int;

    /* ========== CONSTANTS ========== */

    // This is the same unit as used inside `SignedSafeDecimalMath`.
    int private constant _UNIT = int(10**uint(18));

    //slither-disable-next-line naming-convention
    bytes32 internal constant sUSD = "sUSD";

    /* ========== STATE VARIABLES ========== */

    IPerpsV2MarketState public marketState;

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 internal constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";
    bytes32 internal constant CONTRACT_PERPSV2MARKETSETTINGS = "PerpsV2MarketSettings";
    bytes32 internal constant CONTRACT_PERPSV2EXCHANGERATE = "PerpsV2ExchangeRate";
    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    // Holds the revert message for each type of error.
    mapping(uint8 => string) internal _errorMessages;

    // convenience struct for passing params between position modification helper functions
    struct TradeParams {
        int sizeDelta;
        uint oraclePrice;
        uint fillPrice;
        uint desiredFillPrice;
        uint takerFee;
        uint makerFee;
        bytes32 trackingCode; // optional tracking code for volume source fee sharing
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _marketState,
        address _owner,
        address _resolver
    ) public MixinPerpsV2MarketSettings(_resolver) Owned(_owner) {
        marketState = IPerpsV2MarketState(_marketState);

        // Set up the mapping between error codes and their revert messages.
        _errorMessages[uint8(Status.InvalidPrice)] = "Invalid price";
        _errorMessages[uint8(Status.InvalidOrderType)] = "Invalid order type";
        _errorMessages[uint8(Status.PriceOutOfBounds)] = "Price out of acceptable range";
        _errorMessages[uint8(Status.CanLiquidate)] = "Position can be liquidated";
        _errorMessages[uint8(Status.CannotLiquidate)] = "Position cannot be liquidated";
        _errorMessages[uint8(Status.MaxMarketSizeExceeded)] = "Max market size exceeded";
        _errorMessages[uint8(Status.MaxLeverageExceeded)] = "Max leverage exceeded";
        _errorMessages[uint8(Status.InsufficientMargin)] = "Insufficient margin";
        _errorMessages[uint8(Status.NotPermitted)] = "Not permitted by this address";
        _errorMessages[uint8(Status.NilOrder)] = "Cannot submit empty order";
        _errorMessages[uint8(Status.NoPositionOpen)] = "No position open";
        _errorMessages[uint8(Status.PriceTooVolatile)] = "Price too volatile";
        _errorMessages[uint8(Status.PriceImpactToleranceExceeded)] = "Price impact exceeded";
        _errorMessages[uint8(Status.PositionFlagged)] = "Position flagged";
        _errorMessages[uint8(Status.PositionNotFlagged)] = "Position not flagged";
    }

    /* ---------- External Contracts ---------- */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinPerpsV2MarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](7);
        newAddresses[0] = CONTRACT_EXCHANGER;
        newAddresses[1] = CONTRACT_EXRATES;
        newAddresses[2] = CONTRACT_SYSTEMSTATUS;
        newAddresses[3] = CONTRACT_FUTURESMARKETMANAGER;
        newAddresses[4] = CONTRACT_PERPSV2MARKETSETTINGS;
        newAddresses[5] = CONTRACT_PERPSV2EXCHANGERATE;
        newAddresses[6] = CONTRACT_FLEXIBLESTORAGE;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function _systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function _manager() internal view returns (IFuturesMarketManagerInternal) {
        return IFuturesMarketManagerInternal(requireAndGetAddress(CONTRACT_FUTURESMARKETMANAGER));
    }

    function _settings() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_PERPSV2MARKETSETTINGS);
    }

    /* ---------- Market Details ---------- */
    function _baseAsset() internal view returns (bytes32) {
        return marketState.baseAsset();
    }

    function _marketKey() internal view returns (bytes32) {
        return marketState.marketKey();
    }

    /*
     * Returns the pSkew = skew / skewScale capping the pSkew between [-1, 1].
     */
    function _proportionalSkew() internal view returns (int) {
        int pSkew = int(marketState.marketSkew()).divideDecimal(int(_skewScale(_marketKey())));

        // Ensures the proportionalSkew is between -1 and 1.
        return _min(_max(-_UNIT, pSkew), _UNIT);
    }

    function _proportionalElapsed() internal view returns (int) {
        return int(block.timestamp.sub(marketState.fundingLastRecomputed())).divideDecimal(1 days);
    }

    function _currentFundingVelocity() internal view returns (int) {
        int maxFundingVelocity = int(_maxFundingVelocity(_marketKey()));
        return _proportionalSkew().multiplyDecimal(maxFundingVelocity);
    }

    /*
     * @dev Retrieves the _current_ funding rate given the current market conditions.
     *
     * This is used during funding computation _before_ the market is modified (e.g. closing or
     * opening a position). However, called via the `currentFundingRate` view, will return the
     * 'instantaneous' funding rate. It's similar but subtle in that velocity now includes the most
     * recent skew modification.
     *
     * There is no variance in computation but will be affected based on outside modifications to
     * the market skew, max funding velocity, price, and time delta.
     */
    function _currentFundingRate() internal view returns (int) {
        // calculations:
        //  - velocity          = proportional_skew * max_funding_velocity
        //  - proportional_skew = skew / skew_scale
        //
        // example:
        //  - prev_funding_rate     = 0
        //  - prev_velocity         = 0.0025
        //  - time_delta            = 29,000s
        //  - max_funding_velocity  = 0.025 (2.5%)
        //  - skew                  = 300
        //  - skew_scale            = 10,000
        //
        // note: prev_velocity just refs to the velocity _before_ modifying the market skew.
        //
        // funding_rate = prev_funding_rate + prev_velocity * (time_delta / seconds_in_day)
        // funding_rate = 0 + 0.0025 * (29,000 / 86,400)
        //              = 0 + 0.0025 * 0.33564815
        //              = 0.00083912
        return
            int(marketState.fundingRateLastRecomputed()).add(
                _currentFundingVelocity().multiplyDecimal(_proportionalElapsed())
            );
    }

    function _unrecordedFunding(uint price) internal view returns (int) {
        int nextFundingRate = _currentFundingRate();
        // note the minus sign: funding flows in the opposite direction to the skew.
        int avgFundingRate = -(int(marketState.fundingRateLastRecomputed()).add(nextFundingRate)).divideDecimal(_UNIT * 2);
        return avgFundingRate.multiplyDecimal(_proportionalElapsed()).multiplyDecimal(int(price));
    }

    /*
     * The new entry in the funding sequence, appended when funding is recomputed. It is the sum of the
     * last entry and the unrecorded funding, so the sequence accumulates running total over the market's lifetime.
     */
    function _nextFundingEntry(uint price) internal view returns (int) {
        return int(marketState.fundingSequence(_latestFundingIndex())).add(_unrecordedFunding(price));
    }

    function _netFundingPerUnit(uint startIndex, uint price) internal view returns (int) {
        // Compute the net difference between start and end indices.
        return _nextFundingEntry(price).sub(marketState.fundingSequence(startIndex));
    }

    /* ---------- Position Details ---------- */

    /*
     * Determines whether a change in a position's size would violate the max market value constraint.
     */
    function _orderSizeTooLarge(
        uint maxSize,
        int oldSize,
        int newSize
    ) internal view returns (bool) {
        // Allow users to reduce an order no matter the market conditions.
        if (_sameSide(oldSize, newSize) && _abs(newSize) <= _abs(oldSize)) {
            return false;
        }

        // Either the user is flipping sides, or they are increasing an order on the same side they're already on;
        // we check that the side of the market their order is on would not break the limit.
        int newSkew = int(marketState.marketSkew()).sub(oldSize).add(newSize);
        int newMarketSize = int(marketState.marketSize()).sub(_signedAbs(oldSize)).add(_signedAbs(newSize));

        int newSideSize;
        if (0 < newSize) {
            // long case: marketSize + skew
            //            = (|longSize| + |shortSize|) + (longSize + shortSize)
            //            = 2 * longSize
            newSideSize = newMarketSize.add(newSkew);
        } else {
            // short case: marketSize - skew
            //            = (|longSize| + |shortSize|) - (longSize + shortSize)
            //            = 2 * -shortSize
            newSideSize = newMarketSize.sub(newSkew);
        }

        // newSideSize still includes an extra factor of 2 here, so we will divide by 2 in the actual condition
        if (maxSize < _abs(newSideSize.div(2))) {
            return true;
        }

        return false;
    }

    function _notionalValue(int positionSize, uint price) internal pure returns (int value) {
        return positionSize.multiplyDecimal(int(price));
    }

    function _profitLoss(Position memory position, uint price) internal pure returns (int pnl) {
        int priceShift = int(price).sub(int(position.lastPrice));
        return int(position.size).multiplyDecimal(priceShift);
    }

    function _accruedFunding(Position memory position, uint price) internal view returns (int funding) {
        uint lastModifiedIndex = position.lastFundingIndex;
        if (lastModifiedIndex == 0) {
            return 0; // The position does not exist -- no funding.
        }
        int net = _netFundingPerUnit(lastModifiedIndex, price);
        return int(position.size).multiplyDecimal(net);
    }

    /*
     * The initial margin of a position, plus any PnL and funding it has accrued. The resulting value may be negative.
     */
    function _marginPlusProfitFunding(Position memory position, uint price) internal view returns (int) {
        int funding = _accruedFunding(position, price);
        return int(position.margin).add(_profitLoss(position, price)).add(funding);
    }

    /*
     * The value in a position's margin after a deposit or withdrawal, accounting for funding and profit.
     * If the resulting margin would be negative or below the liquidation threshold, an appropriate error is returned.
     * If the result is not an error, callers of this function that use it to update a position's margin
     * must ensure that this is accompanied by a corresponding debt correction update, as per `_applyDebtCorrection`.
     */
    function _recomputeMarginWithDelta(
        Position memory position,
        uint price,
        int marginDelta
    ) internal view returns (uint margin, Status statusCode) {
        int newMargin = _marginPlusProfitFunding(position, price).add(marginDelta);
        if (newMargin < 0) {
            return (0, Status.InsufficientMargin);
        }

        uint uMargin = uint(newMargin);
        int positionSize = int(position.size);
        // minimum margin beyond which position can be liquidated
        uint lMargin = _liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            return (uMargin, Status.CanLiquidate);
        }

        return (uMargin, Status.Ok);
    }

    function _remainingMargin(Position memory position, uint price) internal view returns (uint) {
        int remaining = _marginPlusProfitFunding(position, price);

        // If the margin went past zero, the position should have been liquidated - return zero remaining margin.
        return uint(_max(0, remaining));
    }

    /*
     * @dev Similar to _remainingMargin except it accounts for the premium and fees to be paid upon liquidation.
     */
    function _remainingLiquidatableMargin(Position memory position, uint price) internal view returns (uint) {
        int remaining = _marginPlusProfitFunding(position, price).sub(int(_liquidationPremium(position.size, price)));
        return uint(_max(0, remaining));
    }

    function _accessibleMargin(Position memory position, uint price) internal view returns (uint) {
        // Ugly solution to rounding safety: leave up to an extra tenth of a cent in the account/leverage
        // This should guarantee that the value returned here can always be withdrawn, but there may be
        // a little extra actually-accessible value left over, depending on the position size and margin.
        uint milli = uint(_UNIT / 1000);
        int maxLeverage = int(_maxLeverage(_marketKey()).sub(milli));
        uint inaccessible = _abs(_notionalValue(position.size, price).divideDecimal(maxLeverage));

        // If the user has a position open, we'll enforce a min initial margin requirement.
        if (0 < inaccessible) {
            uint minInitialMargin = _minInitialMargin();
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible.add(milli);
        }

        uint remaining = _remainingMargin(position, price);
        if (remaining <= inaccessible) {
            return 0;
        }

        return remaining.sub(inaccessible);
    }

    /**
     * The fee charged from the margin during liquidation. Fee is proportional to position size
     * but is between _minKeeperFee() and _maxKeeperFee() expressed in sUSD to prevent underincentivising
     * liquidations of small positions, or overpaying.
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lFee liquidation fee to be paid to liquidator in sUSD fixed point decimal units
     */
    function _liquidationFee(int positionSize, uint price) internal view returns (uint lFee) {
        // size * price * fee-ratio
        uint proportionalFee = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationFeeRatio());
        uint maxFee = _maxKeeperFee();
        uint cappedProportionalFee = proportionalFee > maxFee ? maxFee : proportionalFee;
        uint minFee = _minKeeperFee();

        // max(proportionalFee, minFee) - to prevent not incentivising liquidations enough
        return cappedProportionalFee > minFee ? cappedProportionalFee : minFee; // not using _max() helper because it's for signed ints
    }

    /**
     * The minimal margin at which liquidation can happen.
     * Is the sum of liquidationBuffer, liquidationFee (for flagger) and keeperLiquidationFee (for liquidator)
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lMargin liquidation margin to maintain in sUSD fixed point decimal units
     * @dev The liquidation margin contains a buffer that is proportional to the position
     * size. The buffer should prevent liquidation happening at negative margin (due to next price being worse)
     * so that stakers would not leak value to liquidators through minting rewards that are not from the
     * account's margin.
     */
    function _liquidationMargin(int positionSize, uint price) internal view returns (uint lMargin) {
        uint liquidationBuffer =
            _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationBufferRatio(_marketKey()));
        return liquidationBuffer.add(_liquidationFee(positionSize, price)).add(_keeperLiquidationFee());
    }

    /**
     * @dev This is the additional premium we charge upon liquidation.
     *
     * Similar to fillPrice, but we disregard the skew (by assuming it's zero). Which is basically the calculation
     * when we compute as if taking the position from 0 to x. In practice, the premium component of the
     * liquidation will just be (size / skewScale) * (size * price).
     *
     * It adds a configurable multiplier that can be used to increase the margin that goes to feePool.
     *
     * For instance, if size of the liquidation position is 100, oracle price is 1200 and skewScale is 1M then,
     *
     *  size    = abs(-100)
     *          = 100
     *  premium = 100 / 1000000 * (100 * 1200) * multiplier
     *          = 12 * multiplier
     *  if multiplier is set to 1
     *          = 12 * 1 = 12
     *
     * @param positionSize Size of the position we want to liquidate
     * @param currentPrice The current oracle price (not fillPrice)
     * @return The premium to be paid upon liquidation in sUSD
     */
    function _liquidationPremium(int positionSize, uint currentPrice) internal view returns (uint) {
        if (positionSize == 0) {
            return 0;
        }

        // note: this is the same as fillPrice() where the skew is 0.
        uint notional = _abs(_notionalValue(positionSize, currentPrice));

        return
            _abs(positionSize).divideDecimal(_skewScale(_marketKey())).multiplyDecimal(notional).multiplyDecimal(
                _liquidationPremiumMultiplier(_marketKey())
            );
    }

    function _canLiquidate(Position memory position, uint price) internal view returns (bool) {
        // No liquidating empty positions.
        if (position.size == 0) {
            return false;
        }

        return _remainingLiquidatableMargin(position, price) <= _liquidationMargin(int(position.size), price);
    }

    function _currentLeverage(
        Position memory position,
        uint price,
        uint remainingMargin_
    ) internal pure returns (int leverage) {
        // No position is open, or it is ready to be liquidated; leverage goes to nil
        if (remainingMargin_ == 0) {
            return 0;
        }

        return _notionalValue(position.size, price).divideDecimal(int(remainingMargin_));
    }

    function _orderFee(TradeParams memory params, uint dynamicFeeRate) internal view returns (uint fee) {
        // usd value of the difference in position (using the p/d-adjusted price).
        int marketSkew = marketState.marketSkew();
        int notionalDiff = params.sizeDelta.multiplyDecimal(int(params.fillPrice));

        // minimum fee to pay regardless (due to dynamic fees).
        uint baseFee = _abs(notionalDiff).multiplyDecimal(dynamicFeeRate);

        // does this trade keep the skew on one side?
        if (_sameSide(marketSkew + params.sizeDelta, marketSkew)) {
            // use a flat maker/taker fee for the entire size depending on whether the skew is increased or reduced.
            //
            // if the order is submitted on the same side as the skew (increasing it) - the taker fee is charged.
            // otherwise if the order is opposite to the skew, the maker fee is charged.
            uint staticRate = _sameSide(notionalDiff, marketState.marketSkew()) ? params.takerFee : params.makerFee;
            return baseFee + _abs(notionalDiff.multiplyDecimal(int(staticRate)));
        }

        // this trade flips the skew.
        //
        // the proportion of size that moves in the direction after the flip should not be considered
        // as a maker (reducing skew) as it's now taking (increasing skew) in the opposite direction. hence,
        // a different fee is applied on the proportion increasing the skew.

        // proportion of size that's on the other direction
        uint takerSize = _abs((marketSkew + params.sizeDelta).divideDecimal(params.sizeDelta));
        uint makerSize = uint(_UNIT) - takerSize;
        uint takerFee = _abs(notionalDiff).multiplyDecimal(takerSize).multiplyDecimal(params.takerFee);
        uint makerFee = _abs(notionalDiff).multiplyDecimal(makerSize).multiplyDecimal(params.makerFee);

        return baseFee + takerFee + makerFee;
    }

    /// Uses the exchanger to get the dynamic fee (SIP-184) for trading from sUSD to baseAsset
    /// this assumes dynamic fee is symmetric in direction of trade.
    /// @dev this is a pretty expensive action in terms of execution gas as it queries a lot
    ///   of past rates from oracle. Shouldn't be much of an issue on a rollup though.
    function _dynamicFeeRate() internal view returns (uint feeRate, bool tooVolatile) {
        return _exchanger().dynamicFeeRateForExchange(sUSD, _baseAsset());
    }

    function _latestFundingIndex() internal view returns (uint) {
        return marketState.fundingSequenceLength().sub(1); // at least one element is pushed in constructor
    }

    function _postTradeDetails(Position memory oldPos, TradeParams memory params)
        internal
        view
        returns (
            Position memory newPosition,
            uint fee,
            Status tradeStatus
        )
    {
        // Reverts if the user is trying to submit a size-zero order.
        if (params.sizeDelta == 0) {
            return (oldPos, 0, Status.NilOrder);
        }

        // The order is not submitted if the user's existing position needs to be liquidated.
        if (_canLiquidate(oldPos, params.oraclePrice)) {
            return (oldPos, 0, Status.CanLiquidate);
        }

        // get the dynamic fee rate SIP-184
        (uint dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        if (tooVolatile) {
            return (oldPos, 0, Status.PriceTooVolatile);
        }

        // calculate the total fee for exchange
        fee = _orderFee(params, dynamicFeeRate);

        // Deduct the fee.
        // It is an error if the realised margin minus the fee is negative or subject to liquidation.
        (uint newMargin, Status status) = _recomputeMarginWithDelta(oldPos, params.fillPrice, -int(fee));
        if (_isError(status)) {
            return (oldPos, 0, status);
        }

        // construct new position
        Position memory newPos =
            Position({
                id: oldPos.id,
                lastFundingIndex: uint64(_latestFundingIndex()),
                margin: uint128(newMargin),
                lastPrice: uint128(params.fillPrice),
                size: int128(int(oldPos.size).add(params.sizeDelta))
            });

        // always allow to decrease a position, otherwise a margin of minInitialMargin can never
        // decrease a position as the price goes against them.
        // we also add the paid out fee for the minInitialMargin because otherwise minInitialMargin
        // is never the actual minMargin, because the first trade will always deduct
        // a fee (so the margin that otherwise would need to be transferred would have to include the future
        // fee as well, making the UX and definition of min-margin confusing).
        bool positionDecreasing = _sameSide(oldPos.size, newPos.size) && _abs(newPos.size) < _abs(oldPos.size);
        if (!positionDecreasing) {
            // minMargin + fee <= margin is equivalent to minMargin <= margin - fee
            // except that we get a nicer error message if fee > margin, rather than arithmetic overflow.
            if (uint(newPos.margin).add(fee) < _minInitialMargin()) {
                return (oldPos, 0, Status.InsufficientMargin);
            }
        }

        // check that new position margin is above liquidation margin
        // (above, in _recomputeMarginWithDelta() we checked the old position, here we check the new one)
        //
        // Liquidation margin is considered without a fee (but including premium), because it wouldn't make sense to allow
        // a trade that will make the position liquidatable.
        //
        // note: we use `oraclePrice` here as `liquidationPremium` calcs premium based not current skew.
        uint liqPremium = _liquidationPremium(newPos.size, params.oraclePrice);
        uint liqMargin = _liquidationMargin(newPos.size, params.oraclePrice).add(liqPremium);
        if (newMargin <= liqMargin) {
            return (newPos, 0, Status.CanLiquidate);
        }

        // Check that the maximum leverage is not exceeded when considering new margin including the paid fee.
        // The paid fee is considered for the benefit of UX of allowed max leverage, otherwise, the actual
        // max leverage is always below the max leverage parameter since the fee paid for a trade reduces the margin.
        // We'll allow a little extra headroom for rounding errors.
        {
            // stack too deep
            int leverage = int(newPos.size).multiplyDecimal(int(params.fillPrice)).divideDecimal(int(newMargin.add(fee)));
            if (_maxLeverage(_marketKey()).add(uint(_UNIT) / 100) < _abs(leverage)) {
                return (oldPos, 0, Status.MaxLeverageExceeded);
            }
        }

        // Check that the order isn't too large for the markets.
        if (_orderSizeTooLarge(_maxMarketValue(_marketKey()), oldPos.size, newPos.size)) {
            return (oldPos, 0, Status.MaxMarketSizeExceeded);
        }

        return (newPos, fee, Status.Ok);
    }

    /* ---------- Utilities ---------- */

    /*
     * The current base price from the oracle, and whether that price was invalid. Zero prices count as invalid.
     * Public because used both externally and internally
     */
    function _assetPrice() internal view returns (uint price, bool invalid) {
        (price, invalid) = _exchangeRates().rateAndInvalid(_baseAsset());
        // Ensure we catch uninitialised rates or suspended state / synth
        invalid = invalid || price == 0 || _systemStatus().synthSuspended(_baseAsset());
        return (price, invalid);
    }

    /*
     * @dev SIP-279 fillPrice price at which a trade is executed against accounting for how this position's
     * size impacts the skew. If the size contracts the skew (reduces) then a discount is applied on the price
     * whereas expanding the skew incurs an additional premium.
     */
    function _fillPrice(int size, uint price) internal view returns (uint) {
        int skew = marketState.marketSkew();
        int skewScale = int(_skewScale(_marketKey()));

        int pdBefore = skew.divideDecimal(skewScale);
        int pdAfter = skew.add(size).divideDecimal(skewScale);
        int priceBefore = int(price).add(int(price).multiplyDecimal(pdBefore));
        int priceAfter = int(price).add(int(price).multiplyDecimal(pdAfter));

        // How is the p/d-adjusted price calculated using an example:
        //
        // price      = $1200 USD (oracle)
        // size       = 100
        // skew       = 0
        // skew_scale = 1,000,000 (1M)
        //
        // Then,
        //
        // pd_before = 0 / 1,000,000
        //           = 0
        // pd_after  = (0 + 100) / 1,000,000
        //           = 100 / 1,000,000
        //           = 0.0001
        //
        // price_before = 1200 * (1 + pd_before)
        //              = 1200 * (1 + 0)
        //              = 1200
        // price_after  = 1200 * (1 + pd_after)
        //              = 1200 * (1 + 0.0001)
        //              = 1200 * (1.0001)
        //              = 1200.12
        // Finally,
        //
        // fill_price = (price_before + price_after) / 2
        //            = (1200 + 1200.12) / 2
        //            = 1200.06
        return uint(priceBefore.add(priceAfter).divideDecimal(_UNIT * 2));
    }

    /*
     * Absolute value of the input, returned as a signed number.
     */
    function _signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function _abs(int x) internal pure returns (uint) {
        return uint(_signedAbs(x));
    }

    function _max(int x, int y) internal pure returns (int) {
        return x < y ? y : x;
    }

    function _min(int x, int y) internal pure returns (int) {
        return x < y ? x : y;
    }

    /*
     * True if and only if two positions a and b are on the same side of the market; that is, if they have the same
     * sign, or either of them is zero.
     */
    function _sameSide(int a, int b) internal pure returns (bool) {
        return (a == 0) || (b == 0) || (a > 0) == (b > 0);
    }

    /*
     * True if and only if the given status indicates an error.
     */
    function _isError(Status status) internal pure returns (bool) {
        return status != Status.Ok;
    }

    /*
     * Revert with an appropriate message if the first argument is true.
     */
    function _revertIfError(bool isError, Status status) internal view {
        if (isError) {
            revert(_errorMessages[uint8(status)]);
        }
    }

    /*
     * Revert with an appropriate message if the input is an error.
     */
    function _revertIfError(Status status) internal view {
        if (_isError(status)) {
            revert(_errorMessages[uint8(status)]);
        }
    }
}
