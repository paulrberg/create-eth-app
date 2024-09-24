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
import "./Proxyable.sol";
import "./PerpsV2MarketBase.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketProxyable
contract PerpsV2MarketProxyable is PerpsV2MarketBase, Proxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketBase(_marketState, _owner, _resolver) Proxyable(_proxy) {}

    /* ---------- Market Operations ---------- */

    /*
     * Alter the debt correction to account for the net result of altering a position.
     */
    function _applyDebtCorrection(Position memory newPosition, Position memory oldPosition) internal {
        int newCorrection = _positionDebtCorrection(newPosition);
        int oldCorrection = _positionDebtCorrection(oldPosition);
        marketState.setEntryDebtCorrection(
            int128(int(marketState.entryDebtCorrection()).add(newCorrection).sub(oldCorrection))
        );
    }

    /*
     * The impact of a given position on the debt correction.
     */
    function _positionDebtCorrection(Position memory position) internal view returns (int) {
        /**
        This method only returns the correction term for the debt calculation of the position, and not it's 
        debt. This is needed for keeping track of the marketDebt() in an efficient manner to allow O(1) marketDebt
        calculation in marketDebt().

        Explanation of the full market debt calculation from the SIP https://sips.synthetix.io/sips/sip-80/:

        The overall market debt is the sum of the remaining margin in all positions. The intuition is that
        the debt of a single position is the value withdrawn upon closing that position.

        single position remaining margin = initial-margin + profit-loss + accrued-funding =
            = initial-margin + q * (price - last-price) + q * funding-accrued-per-unit
            = initial-margin + q * price - q * last-price + q * (funding - initial-funding)

        Total debt = sum ( position remaining margins )
            = sum ( initial-margin + q * price - q * last-price + q * (funding - initial-funding) )
            = sum( q * price ) + sum( q * funding ) + sum( initial-margin - q * last-price - q * initial-funding )
            = skew * price + skew * funding + sum( initial-margin - q * ( last-price + initial-funding ) )
            = skew (price + funding) + sum( initial-margin - q * ( last-price + initial-funding ) )

        The last term: sum( initial-margin - q * ( last-price + initial-funding ) ) being the position debt correction
            that is tracked with each position change using this method. 
        
        The first term and the full debt calculation using current skew, price, and funding is calculated globally in marketDebt().
         */
        return
            int(position.margin).sub(
                int(position.size).multiplyDecimal(
                    int(position.lastPrice).add(marketState.fundingSequence(position.lastFundingIndex))
                )
            );
    }

    /*
     * The current base price, reverting if it is invalid, or if system or synth is suspended.
     * This is mutative because the circuit breaker stores the last price on every invocation.
     */
    function _assetPriceRequireSystemChecks(bool checkOffchainMarket) internal returns (uint) {
        // check that futures market isn't suspended, revert with appropriate message
        _systemStatus().requireFuturesMarketActive(_marketKey()); // asset and market may be different
        // check that synth is active, and wasn't suspended, revert with appropriate message
        _systemStatus().requireSynthActive(_baseAsset());

        if (checkOffchainMarket) {
            // offchain PerpsV2 virtual market
            _systemStatus().requireFuturesMarketActive(_offchainMarketKey(_marketKey()));
        }
        // check if circuit breaker if price is within deviation tolerance and system & synth is active
        // note: rateWithBreakCircuit (mutative) is used here instead of rateWithInvalid (view). This is
        //  despite reverting immediately after if circuit is broken, which may seem silly.
        //  This is in order to persist last-rate in exchangeCircuitBreaker in the happy case
        //  because last-rate is what used for measuring the deviation for subsequent trades.
        (uint price, bool circuitBroken, bool staleOrInvalid) = _exchangeRates().rateWithSafetyChecks(_baseAsset());
        // revert if price is invalid or circuit was broken
        // note: we revert here, which means that circuit is not really broken (is not persisted), this is
        //  because the futures methods and interface are designed for reverts, and do not support no-op
        //  return values.
        _revertIfError(circuitBroken || staleOrInvalid, Status.InvalidPrice);
        return price;
    }

    /*
     * @dev Checks if the fillPrice does not exceed priceImpactDelta tolerance.
     *
     * This will vary depending on the side you're taking. The intuition is if you're short, a discount is negatively
     * impactful to your order but a premium is not. As such, the priceImpactDelta is asserted differently depending
     * on which side of the trade you take.
     */
    function _assertPriceImpact(
        uint price,
        uint fillPrice,
        uint priceImpactDelta,
        int sizeDelta
    ) internal view returns (uint) {
        uint priceImpactLimit = _priceImpactLimit(price, priceImpactDelta, sizeDelta);
        _revertIfError(
            sizeDelta > 0 ? fillPrice > priceImpactLimit : fillPrice < priceImpactLimit,
            Status.PriceImpactToleranceExceeded
        );
        return priceImpactLimit;
    }

    function _recomputeFunding(uint price) internal returns (uint lastIndex) {
        uint sequenceLengthBefore = marketState.fundingSequenceLength();

        int fundingRate = _currentFundingRate();
        int funding = _nextFundingEntry(price);
        marketState.pushFundingSequence(int128(funding));
        marketState.setFundingLastRecomputed(uint32(block.timestamp));
        marketState.setFundingRateLastRecomputed(int128(fundingRate));

        emitFundingRecomputed(funding, fundingRate, sequenceLengthBefore, marketState.fundingLastRecomputed());

        return sequenceLengthBefore;
    }

    // updates the stored position margin in place (on the stored position)
    function _updatePositionMargin(
        address account,
        Position memory position,
        uint price,
        int marginDelta
    ) internal {
        Position memory oldPosition = position;
        // Determine new margin, ensuring that the result is positive.
        (uint margin, Status status) = _recomputeMarginWithDelta(oldPosition, price, marginDelta);
        _revertIfError(status);

        // Update the debt correction.
        int positionSize = position.size;
        uint fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), uint128(margin), uint128(price), int128(positionSize)),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(positionSize))
        );

        // Update the account's position with the realised margin.
        position.margin = uint128(margin);
        // We only need to update their funding/PnL details if they actually have a position open
        if (positionSize != 0) {
            position.lastPrice = uint128(price);
            position.lastFundingIndex = uint64(fundingIndex);

            // The user can always decrease their margin if they have no position, or as long as:
            //   * they have sufficient margin to do so
            //   * the resulting margin would not be lower than the liquidation margin or min initial margin
            //     * liqMargin accounting for the liqPremium
            //   * the resulting leverage is lower than the maximum leverage
            if (marginDelta < 0) {
                // note: We .add `liqPremium` to increase the req margin to avoid entering into liquidation
                uint liqPremium = _liquidationPremium(position.size, price);
                uint liqMargin = _liquidationMargin(position.size, price).add(liqPremium);
                _revertIfError(
                    (margin < _minInitialMargin()) ||
                        (margin <= liqMargin) ||
                        (_maxLeverage(_marketKey()) < _abs(_currentLeverage(position, price, margin))),
                    Status.InsufficientMargin
                );
            }
        }

        // persist position changes
        marketState.updatePosition(
            account,
            position.id,
            position.lastFundingIndex,
            position.margin,
            position.lastPrice,
            position.size
        );
    }

    function _trade(address sender, TradeParams memory params) internal {
        Position memory position = marketState.positions(sender);
        Position memory oldPosition =
            Position({
                id: position.id,
                lastFundingIndex: position.lastFundingIndex,
                margin: position.margin,
                lastPrice: position.lastPrice,
                size: position.size
            });

        // Compute the new position after performing the trade
        (Position memory newPosition, uint fee, Status status) = _postTradeDetails(oldPosition, params);
        _revertIfError(status);

        _assertPriceImpact(params.oraclePrice, params.fillPrice, params.priceImpactDelta, params.sizeDelta);

        // Update the aggregated market size and skew with the new order size
        marketState.setMarketSkew(int128(int(marketState.marketSkew()).add(newPosition.size).sub(oldPosition.size)));
        marketState.setMarketSize(
            uint128(uint(marketState.marketSize()).add(_abs(newPosition.size)).sub(_abs(oldPosition.size)))
        );

        // Send the fee to the fee pool
        if (0 < fee) {
            _manager().payFee(fee);
            // emit tracking code event
            if (params.trackingCode != bytes32(0)) {
                emitPerpsTracking(params.trackingCode, _baseAsset(), _marketKey(), params.sizeDelta, fee);
            }
        }

        // Update the margin, and apply the resulting debt correction
        position.margin = newPosition.margin;
        _applyDebtCorrection(newPosition, oldPosition);

        // Record the trade
        uint64 id = oldPosition.id;
        uint fundingIndex = _latestFundingIndex();
        if (newPosition.size == 0) {
            // If the position is being closed, we no longer need to track these details.
            delete position.id;
            delete position.size;
            delete position.lastPrice;
            delete position.lastFundingIndex;
        } else {
            if (oldPosition.size == 0) {
                // New positions get new ids.
                id = marketState.nextPositionId();
                marketState.setNextPositionId(id + 1);
            }
            position.id = id;
            position.size = newPosition.size;
            position.lastPrice = uint128(params.fillPrice);
            position.lastFundingIndex = uint64(fundingIndex);
        }

        // persist position changes
        marketState.updatePosition(
            sender,
            position.id,
            position.lastFundingIndex,
            position.margin,
            position.lastPrice,
            position.size
        );

        // emit the modification event
        emitPositionModified(
            id,
            sender,
            newPosition.margin,
            newPosition.size,
            params.sizeDelta,
            params.fillPrice,
            fundingIndex,
            fee
        );
    }

    /* ========== EVENTS ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

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
    bytes32 internal constant POSITIONMODIFIED_SIG =
        keccak256("PositionModified(uint256,address,uint256,int256,int256,uint256,uint256,uint256)");

    function emitPositionModified(
        uint id,
        address account,
        uint margin,
        int size,
        int tradeSize,
        uint lastPrice,
        uint fundingIndex,
        uint fee
    ) internal {
        proxy._emit(
            abi.encode(margin, size, tradeSize, lastPrice, fundingIndex, fee),
            3,
            POSITIONMODIFIED_SIG,
            bytes32(id),
            addressToBytes32(account),
            0
        );
    }

    event MarginTransferred(address indexed account, int marginDelta);
    bytes32 internal constant MARGINTRANSFERRED_SIG = keccak256("MarginTransferred(address,int256)");

    function emitMarginTransferred(address account, int marginDelta) internal {
        proxy._emit(abi.encode(marginDelta), 2, MARGINTRANSFERRED_SIG, addressToBytes32(account), 0, 0);
    }

    event PositionLiquidated(uint id, address account, address liquidator, int size, uint price, uint fee);
    bytes32 internal constant POSITIONLIQUIDATED_SIG =
        keccak256("PositionLiquidated(uint256,address,address,int256,uint256,uint256)");

    function emitPositionLiquidated(
        uint id,
        address account,
        address liquidator,
        int size,
        uint price,
        uint fee
    ) internal {
        proxy._emit(abi.encode(id, account, liquidator, size, price, fee), 1, POSITIONLIQUIDATED_SIG, 0, 0, 0);
    }

    event FundingRecomputed(int funding, int fundingRate, uint index, uint timestamp);
    bytes32 internal constant FUNDINGRECOMPUTED_SIG = keccak256("FundingRecomputed(int256,int256,uint256,uint256)");

    function emitFundingRecomputed(
        int funding,
        int fundingRate,
        uint index,
        uint timestamp
    ) internal {
        proxy._emit(abi.encode(funding, fundingRate, index, timestamp), 1, FUNDINGRECOMPUTED_SIG, 0, 0, 0);
    }

    event PerpsTracking(bytes32 indexed trackingCode, bytes32 baseAsset, bytes32 marketKey, int sizeDelta, uint fee);
    bytes32 internal constant PERPSTRACKING_SIG = keccak256("PerpsTracking(bytes32,bytes32,bytes32,int256,uint256)");

    function emitPerpsTracking(
        bytes32 trackingCode,
        bytes32 baseAsset,
        bytes32 marketKey,
        int sizeDelta,
        uint fee
    ) internal {
        proxy._emit(abi.encode(baseAsset, marketKey, sizeDelta, fee), 2, PERPSTRACKING_SIG, trackingCode, 0, 0);
    }
}
