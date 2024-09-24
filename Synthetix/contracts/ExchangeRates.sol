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
import "./Owned.sol";
import "./MixinSystemSettings.sol";
import "./MixinResolver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IExchangeRates.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
// AggregatorInterface from Chainlink represents a decentralized pricing network for a single currency key
import "Synthetix/@chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol";
// FlagsInterface from Chainlink addresses SIP-76
import "Synthetix/@chainlink/contracts-0.0.10/src/v0.5/interfaces/FlagsInterface.sol";
import "./interfaces/ICircuitBreaker.sol";

// https://docs.synthetix.io/contracts/source/contracts/exchangerates
contract ExchangeRates is Owned, MixinSystemSettings, IExchangeRates {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "ExchangeRates";

    bytes32 internal constant CONTRACT_CIRCUIT_BREAKER = "CircuitBreaker";

    //slither-disable-next-line naming-convention
    bytes32 internal constant sUSD = "sUSD";

    // Decentralized oracle networks that feed into pricing aggregators
    mapping(bytes32 => AggregatorV2V3Interface) public aggregators;

    mapping(bytes32 => uint8) public currencyKeyDecimals;

    // List of aggregator keys for convenient iteration
    bytes32[] public aggregatorKeys;

    // ========== CONSTRUCTOR ==========

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external onlyOwner {
        AggregatorV2V3Interface aggregator = AggregatorV2V3Interface(aggregatorAddress);
        // This check tries to make sure that a valid aggregator is being added.
        // It checks if the aggregator is an existing smart contract that has implemented `latestTimestamp` function.

        require(aggregator.latestRound() >= 0, "Given Aggregator is invalid");
        uint8 decimals = aggregator.decimals();
        // This contract converts all external rates to 18 decimal rates, so adding external rates with
        // higher precision will result in losing precision internally. 27 decimals will result in losing 9 decimal
        // places, which should leave plenty precision for most things.
        require(decimals <= 27, "Aggregator decimals should be lower or equal to 27");
        if (address(aggregators[currencyKey]) == address(0)) {
            aggregatorKeys.push(currencyKey);
        }
        aggregators[currencyKey] = aggregator;
        currencyKeyDecimals[currencyKey] = decimals;
        emit AggregatorAdded(currencyKey, address(aggregator));
    }

    function removeAggregator(bytes32 currencyKey) external onlyOwner {
        address aggregator = address(aggregators[currencyKey]);
        require(aggregator != address(0), "No aggregator exists for key");
        delete aggregators[currencyKey];
        delete currencyKeyDecimals[currencyKey];

        bool wasRemoved = removeFromArray(currencyKey, aggregatorKeys);

        if (wasRemoved) {
            emit AggregatorRemoved(currencyKey, aggregator);
        }
    }

    function rateWithSafetyChecks(bytes32 currencyKey)
        external
        returns (
            uint rate,
            bool broken,
            bool staleOrInvalid
        )
    {
        address aggregatorAddress = address(aggregators[currencyKey]);
        require(currencyKey == sUSD || aggregatorAddress != address(0), "No aggregator for asset");

        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(currencyKey);

        if (currencyKey == sUSD) {
            return (rateAndTime.rate, false, false);
        }

        rate = rateAndTime.rate;
        broken = circuitBreaker().probeCircuitBreaker(aggregatorAddress, rateAndTime.rate);
        staleOrInvalid =
            _rateIsStaleWithTime(getRateStalePeriod(), rateAndTime.time) ||
            _rateIsFlagged(currencyKey, FlagsInterface(getAggregatorWarningFlags()));
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_CIRCUIT_BREAKER;

        return combineArrays(existingAddresses, newAddresses);
    }

    function circuitBreaker() internal view returns (ICircuitBreaker) {
        return ICircuitBreaker(requireAndGetAddress(CONTRACT_CIRCUIT_BREAKER));
    }

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory currencies) {
        uint count = 0;
        currencies = new bytes32[](aggregatorKeys.length);
        for (uint i = 0; i < aggregatorKeys.length; i++) {
            bytes32 currencyKey = aggregatorKeys[i];
            if (address(aggregators[currencyKey]) == aggregator) {
                currencies[count++] = currencyKey;
            }
        }
    }

    function rateStalePeriod() external view returns (uint) {
        return getRateStalePeriod();
    }

    function aggregatorWarningFlags() external view returns (address) {
        return getAggregatorWarningFlags();
    }

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time) {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(currencyKey);
        return (rateAndTime.rate, rateAndTime.time);
    }

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint) {
        uint roundId = startingRoundId;
        uint nextTimestamp = 0;
        while (true) {
            (, nextTimestamp) = _getRateAndTimestampAtRound(currencyKey, roundId + 1);
            // if there's no new round, then the previous roundId was the latest
            if (nextTimestamp == 0 || nextTimestamp > startingTimestamp + timediff) {
                return roundId;
            }
            roundId++;
        }
        return roundId;
    }

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint) {
        return _getCurrentRoundId(currencyKey);
    }

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        (sourceRate, ) = _getRateAndTimestampAtRound(sourceCurrencyKey, roundIdForSrc);
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) {
            destinationRate = sourceRate;
            value = sourceAmount;
        } else {
            (destinationRate, ) = _getRateAndTimestampAtRound(destinationCurrencyKey, roundIdForDest);
            // prevent divide-by 0 error (this happens if the dest is not a valid rate)
            if (destinationRate > 0) {
                // Calculate the effective value by going from source -> USD -> destination
                value = sourceAmount.multiplyDecimalRound(sourceRate).divideDecimalRound(destinationRate);
            }
        }
    }

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time) {
        return _getRateAndTimestampAtRound(currencyKey, roundId);
    }

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256) {
        return _getUpdatedTime(currencyKey);
    }

    function lastRateUpdateTimesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory) {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = _getUpdatedTime(currencyKeys[i]);
        }

        return lastUpdateTimes;
    }

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value) {
        (value, , ) = _effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        return _effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    // SIP-120 Atomic exchanges
    function effectiveAtomicValueAndRates(
        bytes32,
        uint,
        bytes32
    )
        public
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        )
    {
        _notImplemented();
    }

    function effectiveAtomicValueAndRates(
        IDirectIntegrationManager.ParameterIntegrationSettings memory,
        uint,
        IDirectIntegrationManager.ParameterIntegrationSettings memory,
        IDirectIntegrationManager.ParameterIntegrationSettings memory
    )
        public
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        )
    {
        _notImplemented();
    }

    function rateForCurrency(bytes32 currencyKey) external view returns (uint) {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    /// @notice getting N rounds of rates for a currency at a specific round
    /// @param currencyKey the currency key
    /// @param numRounds the number of rounds to get
    /// @param roundId the round id
    /// @return a list of rates and a list of times
    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times) {
        rates = new uint[](numRounds);
        times = new uint[](numRounds);

        roundId = roundId > 0 ? roundId : _getCurrentRoundId(currencyKey);
        for (uint i = 0; i < numRounds; i++) {
            // fetch the rate and treat is as current, so inverse limits if frozen will always be applied
            // regardless of current rate
            (rates[i], times[i]) = _getRateAndTimestampAtRound(currencyKey, roundId);

            if (roundId == 0) {
                // if we hit the last round, then return what we have
                return (rates, times);
            } else {
                roundId--;
            }
        }
    }

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory) {
        uint[] memory _localRates = new uint[](currencyKeys.length);

        for (uint i = 0; i < currencyKeys.length; i++) {
            _localRates[i] = _getRate(currencyKeys[i]);
        }

        return _localRates;
    }

    function rateAndInvalid(bytes32 currencyKey) public view returns (uint rate, bool isInvalid) {
        RateAndUpdatedTime memory rateAndTime = _getRateAndUpdatedTime(currencyKey);

        if (currencyKey == sUSD) {
            return (rateAndTime.rate, false);
        }
        return (
            rateAndTime.rate,
            _rateIsStaleWithTime(getRateStalePeriod(), rateAndTime.time) ||
                _rateIsFlagged(currencyKey, FlagsInterface(getAggregatorWarningFlags())) ||
                _rateIsCircuitBroken(currencyKey, rateAndTime.rate)
        );
    }

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid)
    {
        rates = new uint[](currencyKeys.length);

        uint256 _rateStalePeriod = getRateStalePeriod();

        // fetch all flags at once
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint i = 0; i < currencyKeys.length; i++) {
            // do one lookup of the rate & time to minimize gas
            RateAndUpdatedTime memory rateEntry = _getRateAndUpdatedTime(currencyKeys[i]);
            rates[i] = rateEntry.rate;
            if (!anyRateInvalid && currencyKeys[i] != sUSD) {
                anyRateInvalid =
                    flagList[i] ||
                    _rateIsStaleWithTime(_rateStalePeriod, rateEntry.time) ||
                    _rateIsCircuitBroken(currencyKeys[i], rateEntry.rate);
            }
        }
    }

    function rateIsStale(bytes32 currencyKey) external view returns (bool) {
        return _rateIsStale(currencyKey, getRateStalePeriod());
    }

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool) {
        (, bool invalid) = rateAndInvalid(currencyKey);
        return invalid;
    }

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool) {
        return _rateIsFlagged(currencyKey, FlagsInterface(getAggregatorWarningFlags()));
    }

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool) {
        // Loop through each key and check whether the data point is stale.

        uint256 _rateStalePeriod = getRateStalePeriod();
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint i = 0; i < currencyKeys.length; i++) {
            if (currencyKeys[i] == sUSD) {
                continue;
            }

            RateAndUpdatedTime memory rateEntry = _getRateAndUpdatedTime(currencyKeys[i]);
            if (
                flagList[i] ||
                _rateIsStaleWithTime(_rateStalePeriod, rateEntry.time) ||
                _rateIsCircuitBroken(currencyKeys[i], rateEntry.rate)
            ) {
                return true;
            }
        }

        return false;
    }

    /// this method checks whether any rate is:
    /// 1. flagged
    /// 2. stale with respect to current time (now)
    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds)
        external
        view
        returns (bool)
    {
        // Loop through each key and check whether the data point is stale.

        require(roundIds.length == currencyKeys.length, "roundIds must be the same length as currencyKeys");

        uint256 _rateStalePeriod = getRateStalePeriod();
        bool[] memory flagList = getFlagsForRates(currencyKeys);

        for (uint i = 0; i < currencyKeys.length; i++) {
            if (currencyKeys[i] == sUSD) {
                continue;
            }

            // NOTE: technically below `_rateIsStaleWithTime` is supposed to be called with the roundId timestamp in consideration, and `_rateIsCircuitBroken` is supposed to be
            // called with the current rate (or just not called at all)
            // but thats not how the functionality has worked prior to this change so that is why it works this way here
            // if you are adding new code taht calls this function and the rate is a long time ago, note that this function may resolve an invalid rate when its actually valid!
            (uint rate, uint time) = _getRateAndTimestampAtRound(currencyKeys[i], roundIds[i]);
            if (flagList[i] || _rateIsStaleWithTime(_rateStalePeriod, time) || _rateIsCircuitBroken(currencyKeys[i], rate)) {
                return true;
            }
        }

        return false;
    }

    function synthTooVolatileForAtomicExchange(bytes32) public view returns (bool) {
        _notImplemented();
    }

    function synthTooVolatileForAtomicExchange(IDirectIntegrationManager.ParameterIntegrationSettings memory)
        public
        view
        returns (bool)
    {
        _notImplemented();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function getFlagsForRates(bytes32[] memory currencyKeys) internal view returns (bool[] memory flagList) {
        FlagsInterface _flags = FlagsInterface(getAggregatorWarningFlags());

        // fetch all flags at once
        if (_flags != FlagsInterface(0)) {
            address[] memory _aggregators = new address[](currencyKeys.length);

            for (uint i = 0; i < currencyKeys.length; i++) {
                _aggregators[i] = address(aggregators[currencyKeys[i]]);
            }

            flagList = _flags.getFlags(_aggregators);
        } else {
            flagList = new bool[](currencyKeys.length);
        }
    }

    function removeFromArray(bytes32 entry, bytes32[] storage array) internal returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == entry) {
                delete array[i];

                // Copy the last key into the place of the one we just deleted
                // If there's only one key, this is array[0] = array[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                array[i] = array[array.length - 1];

                // Decrease the size of the array by one.
                array.length--;

                return true;
            }
        }
        return false;
    }

    function _formatAggregatorAnswer(bytes32 currencyKey, int256 rate) internal view returns (uint) {
        require(rate >= 0, "Negative rate not supported");
        uint decimals = currencyKeyDecimals[currencyKey];
        uint result = uint(rate);
        if (decimals == 0 || decimals == 18) {
            // do not convert for 0 (part of implicit interface), and not needed for 18
        } else if (decimals < 18) {
            // increase precision to 18
            uint multiplier = 10**(18 - decimals); // SafeMath not needed since decimals is small
            result = result.mul(multiplier);
        } else if (decimals > 18) {
            // decrease precision to 18
            uint divisor = 10**(decimals - 18); // SafeMath not needed since decimals is small
            result = result.div(divisor);
        }
        return result;
    }

    function _getRateAndUpdatedTime(bytes32 currencyKey) internal view returns (RateAndUpdatedTime memory) {
        // sUSD rate is 1.0
        if (currencyKey == sUSD) {
            return RateAndUpdatedTime({rate: uint216(SafeDecimalMath.unit()), time: 0});
        } else {
            AggregatorV2V3Interface aggregator = aggregators[currencyKey];
            if (aggregator != AggregatorV2V3Interface(0)) {
                // this view from the aggregator is the most gas efficient but it can throw when there's no data,
                // so let's call it low-level to suppress any reverts
                bytes memory payload = abi.encodeWithSignature("latestRoundData()");
                // solhint-disable avoid-low-level-calls
                // slither-disable-next-line low-level-calls
                (bool success, bytes memory returnData) = address(aggregator).staticcall(payload);

                if (success) {
                    (, int256 answer, , uint256 updatedAt, ) =
                        abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));
                    return
                        RateAndUpdatedTime({
                            rate: uint216(_formatAggregatorAnswer(currencyKey, answer)),
                            time: uint40(updatedAt)
                        });
                } // else return defaults, to avoid reverting in views
            } // else return defaults, to avoid reverting in views
        }
    }

    function _getCurrentRoundId(bytes32 currencyKey) internal view returns (uint) {
        if (currencyKey == sUSD) {
            return 0;
        }
        AggregatorV2V3Interface aggregator = aggregators[currencyKey];
        if (aggregator != AggregatorV2V3Interface(0)) {
            return aggregator.latestRound();
        } // else return defaults, to avoid reverting in views
    }

    function _getRateAndTimestampAtRound(bytes32 currencyKey, uint roundId) internal view returns (uint rate, uint time) {
        // short circuit sUSD
        if (currencyKey == sUSD) {
            // sUSD has no rounds, and 0 time is preferrable for "volatility" heuristics
            // which are used in atomic swaps and fee reclamation
            return (SafeDecimalMath.unit(), 0);
        } else {
            AggregatorV2V3Interface aggregator = aggregators[currencyKey];
            if (aggregator != AggregatorV2V3Interface(0)) {
                // this view from the aggregator is the most gas efficient but it can throw when there's no data,
                // so let's call it low-level to suppress any reverts
                bytes memory payload = abi.encodeWithSignature("getRoundData(uint80)", roundId);
                // solhint-disable avoid-low-level-calls
                (bool success, bytes memory returnData) = address(aggregator).staticcall(payload);

                if (success) {
                    (, int256 answer, , uint256 updatedAt, ) =
                        abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));
                    return (_formatAggregatorAnswer(currencyKey, answer), updatedAt);
                } // else return defaults, to avoid reverting in views
            } // else return defaults, to avoid reverting in views
        }
    }

    function _getRate(bytes32 currencyKey) internal view returns (uint256) {
        return _getRateAndUpdatedTime(currencyKey).rate;
    }

    function _getUpdatedTime(bytes32 currencyKey) internal view returns (uint256) {
        return _getRateAndUpdatedTime(currencyKey).time;
    }

    function _effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        internal
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        )
    {
        sourceRate = _getRate(sourceCurrencyKey);
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) {
            destinationRate = sourceRate;
            value = sourceAmount;
        } else {
            // Calculate the effective value by going from source -> USD -> destination
            destinationRate = _getRate(destinationCurrencyKey);
            // prevent divide-by 0 error (this happens if the dest is not a valid rate)
            if (destinationRate > 0) {
                value = sourceAmount.multiplyDecimalRound(sourceRate).divideDecimalRound(destinationRate);
            }
        }
    }

    function _rateIsStale(bytes32 currencyKey, uint _rateStalePeriod) internal view returns (bool) {
        // sUSD is a special case and is never stale (check before an SLOAD of getRateAndUpdatedTime)
        if (currencyKey == sUSD) {
            return false;
        }
        return _rateIsStaleWithTime(_rateStalePeriod, _getUpdatedTime(currencyKey));
    }

    function _rateIsStaleWithTime(uint _rateStalePeriod, uint _time) internal view returns (bool) {
        return _time.add(_rateStalePeriod) < now;
    }

    function _rateIsFlagged(bytes32 currencyKey, FlagsInterface flags) internal view returns (bool) {
        // sUSD is a special case and is never invalid
        if (currencyKey == sUSD) {
            return false;
        }
        address aggregator = address(aggregators[currencyKey]);
        // when no aggregator or when the flags haven't been setup
        if (aggregator == address(0) || flags == FlagsInterface(0)) {
            return false;
        }
        return flags.getFlag(aggregator);
    }

    function _rateIsCircuitBroken(bytes32 currencyKey, uint curRate) internal view returns (bool) {
        return circuitBreaker().isInvalid(address(aggregators[currencyKey]), curRate);
    }

    function _notImplemented() internal pure {
        // slither-disable-next-line dead-code
        revert("Cannot be run on this layer");
    }

    /* ========== EVENTS ========== */

    event AggregatorAdded(bytes32 currencyKey, address aggregator);
    event AggregatorRemoved(bytes32 currencyKey, address aggregator);
}
