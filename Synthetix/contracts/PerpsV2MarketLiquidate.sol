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
import "./interfaces/IPerpsV2MarketLiquidate.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketLiquidate
contract PerpsV2MarketLiquidate is IPerpsV2MarketLiquidate, PerpsV2MarketProxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketProxyable(_proxy, _marketState, _owner, _resolver) {}

    /* ========== MUTATIVE FUNCTIONS ========== */
    /*
     * Flag a position to be liquidated if its remaining margin is below the liquidation fee. This succeeds if and only if
     * `canLiquidate(account)` is true, and reverts otherwise.
     * Upon flagging, the position will be flagged and the only operation enabled will be liquidatation.
     */
    function flagPosition(address account) external onlyProxy notFlagged(account) {
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);

        _revertIfError(!_canLiquidate(marketState.positions(account), price), Status.CannotLiquidate);

        _flagPosition(account, messageSender, price);
    }

    /*
     * Liquidate a position if its remaining margin is below the liquidation fee. This succeeds if and only if
     * `canLiquidate(account)` is true, and reverts otherwise.
     * Upon liquidation, the position will be closed, and the liquidation fee minted into the liquidator's account.
     */
    function liquidatePosition(address account) external onlyProxy flagged(account) {
        Position memory position = marketState.positions(account);
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);

        bytes32 marketKey = _marketKey();
        uint skewScale = _skewScale(marketKey);

        // Check price impact of liquidation
        require(
            _maxLiquidationDelta(marketKey) > _abs(position.size).divideDecimal(skewScale),
            "price impact of liquidation exceeded"
        );

        // Check Instantaneous P/D
        require(_maxPD(marketKey) > _abs(marketState.marketSkew()).divideDecimal(skewScale), "instantaneous P/D exceeded");

        // Liquidate and get remaining margin
        _liquidatePosition(position, account, messageSender, price, _keeperLiquidationFee());
    }

    function forceLiquidatePosition(address account) external onlyProxy flagged(account) {
        Position memory position = marketState.positions(account);
        uint price = _assetPriceRequireSystemChecks(false);
        _recomputeFunding(price);

        // Check if sender is endorsed
        require(_manager().isEndorsed(messageSender), "address not endorsed");

        // Liquidate and get remaining margin
        _liquidatePosition(position, account, messageSender, price, 0);
    }

    function _flagPosition(
        address account,
        address flagger,
        uint price
    ) internal {
        Position memory position = marketState.positions(account);

        // Flag position
        marketState.flag(account, flagger);

        // Cleanup any outstanding delayed order
        DelayedOrder memory order = marketState.delayedOrders(account);
        if (order.sizeDelta != 0) {
            // commitDeposit should be zero. If not it means it's a legacy order
            if (order.commitDeposit > 0) {
                // persist position changes
                marketState.updatePosition(
                    account,
                    position.id,
                    position.lastFundingIndex,
                    position.margin + order.commitDeposit,
                    position.lastPrice,
                    position.size
                );

                emitPositionModified(
                    position.id,
                    account,
                    position.margin + order.commitDeposit,
                    position.size,
                    0,
                    position.lastPrice,
                    position.lastFundingIndex,
                    0,
                    marketState.marketSkew()
                );
            }

            // take keeper fee and send to flagger
            if (order.keeperDeposit > 0) {
                _manager().issueSUSD(messageSender, order.keeperDeposit);
            }

            marketState.deleteDelayedOrder(account);
        }

        emitPositionFlagged(position.id, account, flagger, price, block.timestamp);
    }

    function _liquidatePosition(
        Position memory position,
        address account,
        address liquidator,
        uint price,
        uint liquidatorFee
    ) internal {
        int128 positionSize = position.size;
        uint positionId = position.id;

        // Get remaining margin for sending any leftover buffer to fee pool
        //
        // note: we do _not_ use `_remainingLiquidatableMargin` here as we want to send this premium to the fee pool
        // upon liquidation to give back to stakers.
        uint remainingMargin = _remainingMargin(position, price);

        // Get fees to pay to flagger, liquidator and feepooland/or feePool)
        // Pay fee to flagger
        uint flaggerFee = _liquidationFee(positionSize, price);

        uint totalFees = flaggerFee.add(liquidatorFee);

        // update remaining margin
        remainingMargin = remainingMargin > totalFees ? remainingMargin.sub(totalFees) : 0;

        // Record updates to market size and debt.
        marketState.setMarketSkew(int128(int(marketState.marketSkew()).sub(positionSize)));
        marketState.setMarketSize(uint128(uint(marketState.marketSize()).sub(_abs(positionSize))));

        uint fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), 0, uint128(price), 0),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, positionSize)
        );

        // Issue the reward to the flagger.
        _manager().issueSUSD(marketState.positionFlagger(account), flaggerFee);

        // Issue the reward to the liquidator (keeper).
        if (liquidatorFee > 0) {
            _manager().issueSUSD(liquidator, liquidatorFee);
        }

        // Pay the remaining to feePool
        if (remainingMargin > 0) {
            _manager().payFee(remainingMargin);
        }

        // Close the position itself.
        marketState.deletePosition(account);

        // Unflag position.
        marketState.unflag(account);

        emitPositionModified(positionId, account, 0, 0, 0, price, fundingIndex, 0, marketState.marketSkew());

        emitPositionLiquidated(
            position.id,
            account,
            messageSender,
            position.size,
            price,
            flaggerFee,
            liquidatorFee,
            remainingMargin
        );
    }

    /* ========== EVENTS ========== */

    event PositionFlagged(uint id, address account, address flagger, uint price, uint timestamp);
    bytes32 internal constant POSITIONFLAGGED_SIG = keccak256("PositionFlagged(uint256,address,address,uint256,uint256)");

    function emitPositionFlagged(
        uint id,
        address account,
        address flagger,
        uint price,
        uint timestamp
    ) internal {
        proxy._emit(abi.encode(id, account, flagger, price, timestamp), 1, POSITIONFLAGGED_SIG, 0, 0, 0);
    }

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
    bytes32 internal constant POSITIONLIQUIDATED_SIG =
        keccak256("PositionLiquidated(uint256,address,address,int256,uint256,uint256,uint256,uint256)");

    function emitPositionLiquidated(
        uint id,
        address account,
        address liquidator,
        int size,
        uint price,
        uint flaggerFee,
        uint liquidatorFee,
        uint stakersFee
    ) internal {
        proxy._emit(
            abi.encode(id, account, liquidator, size, price, flaggerFee, liquidatorFee, stakersFee),
            1,
            POSITIONLIQUIDATED_SIG,
            0,
            0,
            0
        );
    }
}
