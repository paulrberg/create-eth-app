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

import "./interfaces/IExchanger.sol";
import "./interfaces/ICircuitBreaker.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IExchangeState.sol";
import "./interfaces/IDebtCache.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/ISynthetix.sol";

import "./SafeDecimalMath.sol";

library ExchangeSettlementLib {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    struct ResolvedAddresses {
        IExchangeState exchangeState;
        IExchangeRates exchangeRates;
        ICircuitBreaker circuitBreaker;
        IExchangerInternalDebtCache debtCache;
        IIssuer issuer;
        ISynthetix synthetix;
    }

    bytes32 internal constant sUSD = "sUSD";

    function internalSettle(
        ResolvedAddresses calldata resolvedAddresses,
        address from,
        bytes32 currencyKey,
        bool updateCache,
        uint waitingPeriod
    )
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntriesSettled
        )
    {
        require(
            maxSecsLeftInWaitingPeriod(resolvedAddresses.exchangeState, from, currencyKey, waitingPeriod) == 0,
            "Cannot settle during waiting period"
        );

        (uint reclaimAmount, uint rebateAmount, uint entries, IExchanger.ExchangeEntrySettlement[] memory settlements) =
            _settlementOwing(resolvedAddresses, from, currencyKey, waitingPeriod);

        if (reclaimAmount > rebateAmount) {
            reclaimed = reclaimAmount.sub(rebateAmount);
            _reclaim(resolvedAddresses, from, currencyKey, reclaimed);
        } else if (rebateAmount > reclaimAmount) {
            refunded = rebateAmount.sub(reclaimAmount);
            _refund(resolvedAddresses, from, currencyKey, refunded);
        }

        // by checking a reclaim or refund we also check that the currency key is still a valid synth,
        // as the deviation check will return 0 if the synth has been removed.
        if (updateCache && (reclaimed > 0 || refunded > 0)) {
            bytes32[] memory key = new bytes32[](1);
            key[0] = currencyKey;
            resolvedAddresses.debtCache.updateCachedSynthDebts(key);
        }

        // emit settlement event for each settled exchange entry
        for (uint i = 0; i < settlements.length; i++) {
            emit ExchangeEntrySettled(
                from,
                settlements[i].src,
                settlements[i].amount,
                settlements[i].dest,
                settlements[i].reclaim,
                settlements[i].rebate,
                settlements[i].srcRoundIdAtPeriodEnd,
                settlements[i].destRoundIdAtPeriodEnd,
                settlements[i].timestamp
            );
        }

        numEntriesSettled = entries;

        // Now remove all entries, even if no reclaim and no rebate
        resolvedAddresses.exchangeState.removeEntries(from, currencyKey);
    }

    function maxSecsLeftInWaitingPeriod(
        IExchangeState exchangeState,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    ) public view returns (uint) {
        return _secsLeftInWaitingPeriodForExchange(exchangeState.getMaxTimestamp(account, currencyKey), waitingPeriod);
    }

    function _secsLeftInWaitingPeriodForExchange(uint timestamp, uint waitingPeriod) internal view returns (uint) {
        if (timestamp == 0 || now >= timestamp.add(waitingPeriod)) {
            return 0;
        }

        return timestamp.add(waitingPeriod).sub(now);
    }

    function _reclaim(
        ResolvedAddresses memory resolvedAddresses,
        address from,
        bytes32 currencyKey,
        uint amount
    ) internal {
        // burn amount from user
        resolvedAddresses.issuer.synths(currencyKey).burn(from, amount);
        ISynthetixInternal(address(resolvedAddresses.synthetix)).emitExchangeReclaim(from, currencyKey, amount);
    }

    function _refund(
        ResolvedAddresses memory resolvedAddresses,
        address from,
        bytes32 currencyKey,
        uint amount
    ) internal {
        // issue amount to user
        resolvedAddresses.issuer.synths(currencyKey).issue(from, amount);
        ISynthetixInternal(address(resolvedAddresses.synthetix)).emitExchangeRebate(from, currencyKey, amount);
    }

    function hasWaitingPeriodOrSettlementOwing(
        ResolvedAddresses calldata resolvedAddresses,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    ) external view returns (bool) {
        if (maxSecsLeftInWaitingPeriod(resolvedAddresses.exchangeState, account, currencyKey, waitingPeriod) != 0) {
            return true;
        }

        (uint reclaimAmount, , , ) = _settlementOwing(resolvedAddresses, account, currencyKey, waitingPeriod);

        return reclaimAmount > 0;
    }

    function settlementOwing(
        ResolvedAddresses calldata resolvedAddresses,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    )
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries,
            IExchanger.ExchangeEntrySettlement[] memory
        )
    {
        return _settlementOwing(resolvedAddresses, account, currencyKey, waitingPeriod);
    }

    // Internal function to aggregate each individual rebate and reclaim entry for a synth
    function _settlementOwing(
        ResolvedAddresses memory resolvedAddresses,
        address account,
        bytes32 currencyKey,
        uint waitingPeriod
    )
        internal
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries,
            IExchanger.ExchangeEntrySettlement[] memory
        )
    {
        // Need to sum up all reclaim and rebate amounts for the user and the currency key
        numEntries = resolvedAddresses.exchangeState.getLengthOfEntries(account, currencyKey);

        // For each unsettled exchange
        IExchanger.ExchangeEntrySettlement[] memory settlements = new IExchanger.ExchangeEntrySettlement[](numEntries);
        for (uint i = 0; i < numEntries; i++) {
            // fetch the entry from storage
            IExchangeState.ExchangeEntry memory exchangeEntry =
                _getExchangeEntry(resolvedAddresses.exchangeState, account, currencyKey, i);

            // determine the last round ids for src and dest pairs when period ended or latest if not over
            (uint srcRoundIdAtPeriodEnd, uint destRoundIdAtPeriodEnd) =
                _getRoundIdsAtPeriodEnd(resolvedAddresses.exchangeRates, exchangeEntry, waitingPeriod);

            // given these round ids, determine what effective value they should have received
            uint amountShouldHaveReceived;
            {
                (uint destinationAmount, , ) =
                    resolvedAddresses.exchangeRates.effectiveValueAndRatesAtRound(
                        exchangeEntry.src,
                        exchangeEntry.amount,
                        exchangeEntry.dest,
                        srcRoundIdAtPeriodEnd,
                        destRoundIdAtPeriodEnd
                    );

                // and deduct the fee from this amount using the exchangeFeeRate from storage
                amountShouldHaveReceived = _deductFeesFromAmount(destinationAmount, exchangeEntry.exchangeFeeRate);
            }

            // SIP-65 settlements where the amount at end of waiting period is beyond the threshold, then
            // settle with no reclaim or rebate
            bool sip65condition =
                resolvedAddresses.circuitBreaker.isDeviationAboveThreshold(
                    exchangeEntry.amountReceived,
                    amountShouldHaveReceived
                );

            uint reclaim;
            uint rebate;

            if (!sip65condition) {
                if (exchangeEntry.amountReceived > amountShouldHaveReceived) {
                    // if they received more than they should have, add to the reclaim tally
                    reclaim = exchangeEntry.amountReceived.sub(amountShouldHaveReceived);
                    reclaimAmount = reclaimAmount.add(reclaim);
                } else if (amountShouldHaveReceived > exchangeEntry.amountReceived) {
                    // if less, add to the rebate tally
                    rebate = amountShouldHaveReceived.sub(exchangeEntry.amountReceived);
                    rebateAmount = rebateAmount.add(rebate);
                }
            }

            settlements[i] = IExchanger.ExchangeEntrySettlement({
                src: exchangeEntry.src,
                amount: exchangeEntry.amount,
                dest: exchangeEntry.dest,
                reclaim: reclaim,
                rebate: rebate,
                srcRoundIdAtPeriodEnd: srcRoundIdAtPeriodEnd,
                destRoundIdAtPeriodEnd: destRoundIdAtPeriodEnd,
                timestamp: exchangeEntry.timestamp
            });
        }

        return (reclaimAmount, rebateAmount, numEntries, settlements);
    }

    function _getExchangeEntry(
        IExchangeState exchangeState,
        address account,
        bytes32 currencyKey,
        uint index
    ) internal view returns (IExchangeState.ExchangeEntry memory) {
        (
            bytes32 src,
            uint amount,
            bytes32 dest,
            uint amountReceived,
            uint exchangeFeeRate,
            uint timestamp,
            uint roundIdForSrc,
            uint roundIdForDest
        ) = exchangeState.getEntryAt(account, currencyKey, index);

        return
            IExchangeState.ExchangeEntry({
                src: src,
                amount: amount,
                dest: dest,
                amountReceived: amountReceived,
                exchangeFeeRate: exchangeFeeRate,
                timestamp: timestamp,
                roundIdForSrc: roundIdForSrc,
                roundIdForDest: roundIdForDest
            });
    }

    function _getRoundIdsAtPeriodEnd(
        IExchangeRates exRates,
        IExchangeState.ExchangeEntry memory exchangeEntry,
        uint waitingPeriod
    ) internal view returns (uint srcRoundIdAtPeriodEnd, uint destRoundIdAtPeriodEnd) {
        srcRoundIdAtPeriodEnd = exRates.getLastRoundIdBeforeElapsedSecs(
            exchangeEntry.src,
            exchangeEntry.roundIdForSrc,
            exchangeEntry.timestamp,
            waitingPeriod
        );
        destRoundIdAtPeriodEnd = exRates.getLastRoundIdBeforeElapsedSecs(
            exchangeEntry.dest,
            exchangeEntry.roundIdForDest,
            exchangeEntry.timestamp,
            waitingPeriod
        );
    }

    function _deductFeesFromAmount(uint destinationAmount, uint exchangeFeeRate)
        internal
        pure
        returns (uint amountReceived)
    {
        amountReceived = destinationAmount.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }

    function appendExchange(
        ResolvedAddresses calldata resolvedAddresses,
        address account,
        bytes32 src,
        uint amount,
        bytes32 dest,
        uint amountReceived,
        uint exchangeFeeRate
    ) external {
        uint roundIdForSrc = resolvedAddresses.exchangeRates.getCurrentRoundId(src);
        uint roundIdForDest = resolvedAddresses.exchangeRates.getCurrentRoundId(dest);
        resolvedAddresses.exchangeState.appendExchangeEntry(
            account,
            src,
            amount,
            dest,
            amountReceived,
            exchangeFeeRate,
            now,
            roundIdForSrc,
            roundIdForDest
        );

        emit ExchangeEntryAppended(
            account,
            src,
            amount,
            dest,
            amountReceived,
            exchangeFeeRate,
            roundIdForSrc,
            roundIdForDest
        );
    }

    // ========== EVENTS ==========
    event ExchangeEntryAppended(
        address indexed account,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 amountReceived,
        uint256 exchangeFeeRate,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    );

    event ExchangeEntrySettled(
        address indexed from,
        bytes32 src,
        uint256 amount,
        bytes32 dest,
        uint256 reclaim,
        uint256 rebate,
        uint256 srcRoundIdAtPeriodEnd,
        uint256 destRoundIdAtPeriodEnd,
        uint256 exchangeTimestamp
    );
}
