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
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICircuitBreaker.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IDelegateApprovals.sol";
import "./interfaces/ITradingRewards.sol";
import "./interfaces/IVirtualSynth.sol";

import "./ExchangeSettlementLib.sol";

import "./Proxyable.sol";

// https://docs.synthetix.io/contracts/source/contracts/exchanger
contract Exchanger is Owned, MixinSystemSettings, IExchanger {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "Exchanger";

    bytes32 internal constant sUSD = "sUSD";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGESTATE = "ExchangeState";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_TRADING_REWARDS = "TradingRewards";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_DEBTCACHE = "DebtCache";
    bytes32 private constant CONTRACT_CIRCUIT_BREAKER = "CircuitBreaker";
    bytes32 private constant CONTRACT_DIRECT_INTEGRATION_MANAGER = "DirectIntegrationManager";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](11);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_EXCHANGESTATE;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_SYNTHETIX;
        newAddresses[4] = CONTRACT_FEEPOOL;
        newAddresses[5] = CONTRACT_TRADING_REWARDS;
        newAddresses[6] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[7] = CONTRACT_ISSUER;
        newAddresses[8] = CONTRACT_DEBTCACHE;
        newAddresses[9] = CONTRACT_CIRCUIT_BREAKER;
        newAddresses[10] = CONTRACT_DIRECT_INTEGRATION_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchangeState() internal view returns (IExchangeState) {
        return IExchangeState(requireAndGetAddress(CONTRACT_EXCHANGESTATE));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function circuitBreaker() internal view returns (ICircuitBreaker) {
        return ICircuitBreaker(requireAndGetAddress(CONTRACT_CIRCUIT_BREAKER));
    }

    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function tradingRewards() internal view returns (ITradingRewards) {
        return ITradingRewards(requireAndGetAddress(CONTRACT_TRADING_REWARDS));
    }

    function delegateApprovals() internal view returns (IDelegateApprovals) {
        return IDelegateApprovals(requireAndGetAddress(CONTRACT_DELEGATEAPPROVALS));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function debtCache() internal view returns (IExchangerInternalDebtCache) {
        return IExchangerInternalDebtCache(requireAndGetAddress(CONTRACT_DEBTCACHE));
    }

    function directIntegrationManager() internal view returns (IDirectIntegrationManager) {
        return IDirectIntegrationManager(requireAndGetAddress(CONTRACT_DIRECT_INTEGRATION_MANAGER));
    }

    function resolvedAddresses() internal view returns (ExchangeSettlementLib.ResolvedAddresses memory) {
        return
            ExchangeSettlementLib.ResolvedAddresses(
                exchangeState(),
                exchangeRates(),
                circuitBreaker(),
                debtCache(),
                issuer(),
                synthetix()
            );
    }

    function waitingPeriodSecs() external view returns (uint) {
        return getWaitingPeriodSecs();
    }

    function tradingRewardsEnabled() external view returns (bool) {
        return getTradingRewardsEnabled();
    }

    function priceDeviationThresholdFactor() external view returns (uint) {
        return getPriceDeviationThresholdFactor();
    }

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint) {
        return circuitBreaker().lastValue(address(exchangeRates().aggregators(currencyKey)));
    }

    function settlementOwing(address account, bytes32 currencyKey)
        public
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        )
    {
        (reclaimAmount, rebateAmount, numEntries, ) = ExchangeSettlementLib.settlementOwing(
            resolvedAddresses(),
            account,
            currencyKey,
            getWaitingPeriodSecs()
        );
    }

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool) {
        return
            ExchangeSettlementLib.hasWaitingPeriodOrSettlementOwing(
                resolvedAddresses(),
                account,
                currencyKey,
                getWaitingPeriodSecs()
            );
    }

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) public view returns (uint) {
        return
            ExchangeSettlementLib._secsLeftInWaitingPeriodForExchange(
                exchangeState().getMaxTimestamp(account, currencyKey),
                getWaitingPeriodSecs()
            );
    }

    /* ========== SETTERS ========== */

    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) public view returns (uint amountAfterSettlement) {
        amountAfterSettlement = amount;

        // balance of a synth will show an amount after settlement
        uint balanceOfSourceAfterSettlement = IERC20(address(issuer().synths(currencyKey))).balanceOf(from);

        // when there isn't enough supply (either due to reclamation settlement or because the number is too high)
        if (amountAfterSettlement > balanceOfSourceAfterSettlement) {
            // then the amount to exchange is reduced to their remaining supply
            amountAfterSettlement = balanceOfSourceAfterSettlement;
        }

        if (refunded > 0) {
            amountAfterSettlement = amountAfterSettlement.add(refunded);
        }
    }

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool) {
        (, bool invalid) = exchangeRates().rateAndInvalid(currencyKey);
        return invalid;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualSynth,
        address rewardAddress,
        bytes32 trackingCode
    ) external onlySynthetixorSynth returns (uint amountReceived, IVirtualSynth vSynth) {
        uint fee;
        if (from != exchangeForAddress) {
            require(delegateApprovals().canExchangeFor(exchangeForAddress, from), "Not approved to act on behalf");
        }

        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(from, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(from, destinationCurrencyKey);

        (amountReceived, fee, vSynth) = _exchange(
            exchangeForAddress,
            sourceSettings,
            sourceAmount,
            destinationSettings,
            destinationAddress,
            virtualSynth
        );

        _processTradingRewards(fee, rewardAddress);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, destinationCurrencyKey, amountReceived, fee);
        }
    }

    function exchangeAtomically(
        address,
        bytes32,
        uint,
        bytes32,
        address,
        bytes32,
        uint
    ) external returns (uint) {
        _notImplemented();
    }

    function _emitTrackingEvent(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) internal {
        ISynthetixInternal(address(synthetix())).emitExchangeTracking(trackingCode, toCurrencyKey, toAmount, fee);
    }

    function _processTradingRewards(uint fee, address rewardAddress) internal {
        if (fee > 0 && rewardAddress != address(0) && getTradingRewardsEnabled()) {
            tradingRewards().recordExchangeFeeForAccount(fee, rewardAddress);
        }
    }

    function _updateSNXIssuedDebtOnExchange(bytes32[2] memory currencyKeys, uint[2] memory currencyRates) internal {
        bool includesSUSD = currencyKeys[0] == sUSD || currencyKeys[1] == sUSD;
        uint numKeys = includesSUSD ? 2 : 3;

        bytes32[] memory keys = new bytes32[](numKeys);
        keys[0] = currencyKeys[0];
        keys[1] = currencyKeys[1];

        uint[] memory rates = new uint[](numKeys);
        rates[0] = currencyRates[0];
        rates[1] = currencyRates[1];

        if (!includesSUSD) {
            keys[2] = sUSD; // And we'll also update sUSD to account for any fees if it wasn't one of the exchanged currencies
            rates[2] = SafeDecimalMath.unit();
        }

        // Note that exchanges can't invalidate the debt cache, since if a rate is invalid,
        // the exchange will have failed already.
        debtCache().updateCachedSynthDebtsWithRates(keys, rates);
    }

    function _settleAndCalcSourceAmountRemaining(
        uint sourceAmount,
        address from,
        bytes32 sourceCurrencyKey
    ) internal returns (uint sourceAmountAfterSettlement) {
        (, uint refunded, uint numEntriesSettled) =
            ExchangeSettlementLib.internalSettle(
                resolvedAddresses(),
                from,
                sourceCurrencyKey,
                false,
                getWaitingPeriodSecs()
            );

        sourceAmountAfterSettlement = sourceAmount;

        // when settlement was required
        if (numEntriesSettled > 0) {
            // ensure the sourceAmount takes this into account
            sourceAmountAfterSettlement = calculateAmountAfterSettlement(from, sourceCurrencyKey, sourceAmount, refunded);
        }
    }

    function _exchange(
        address from,
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        address destinationAddress,
        bool virtualSynth
    )
        internal
        returns (
            uint amountReceived,
            uint fee,
            IVirtualSynth vSynth
        )
    {
        if (!_ensureCanExchange(sourceSettings.currencyKey, destinationSettings.currencyKey, sourceAmount)) {
            return (0, 0, IVirtualSynth(0));
        }

        // Using struct to resolve stack too deep error
        IExchanger.ExchangeEntry memory entry;
        ExchangeSettlementLib.ResolvedAddresses memory addrs = resolvedAddresses();

        entry.roundIdForSrc = addrs.exchangeRates.getCurrentRoundId(sourceSettings.currencyKey);
        entry.roundIdForDest = addrs.exchangeRates.getCurrentRoundId(destinationSettings.currencyKey);

        entry.sourceAmountAfterSettlement = _settleAndCalcSourceAmountRemaining(
            sourceAmount,
            from,
            sourceSettings.currencyKey
        );

        // If, after settlement the user has no balance left (highly unlikely), then return to prevent
        // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
        if (entry.sourceAmountAfterSettlement == 0) {
            return (0, 0, IVirtualSynth(0));
        }

        (entry.destinationAmount, entry.sourceRate, entry.destinationRate) = addrs
            .exchangeRates
            .effectiveValueAndRatesAtRound(
            sourceSettings.currencyKey,
            entry.sourceAmountAfterSettlement,
            destinationSettings.currencyKey,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        // rates must also be good for the round we are doing
        _ensureCanExchangeAtRound(
            sourceSettings.currencyKey,
            destinationSettings.currencyKey,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        bool tooVolatile;
        (entry.exchangeFeeRate, tooVolatile) = _feeRateForExchangeAtRounds(
            sourceSettings,
            destinationSettings,
            entry.roundIdForSrc,
            entry.roundIdForDest
        );

        if (tooVolatile) {
            // do not exchange if rates are too volatile, this to prevent charging
            // dynamic fees that are over the max value
            return (0, 0, IVirtualSynth(0));
        }

        amountReceived = ExchangeSettlementLib._deductFeesFromAmount(entry.destinationAmount, entry.exchangeFeeRate);
        // Note: `fee` is denominated in the destinationCurrencyKey.
        fee = entry.destinationAmount.sub(amountReceived);

        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.
        vSynth = _convert(
            sourceSettings.currencyKey,
            from,
            entry.sourceAmountAfterSettlement,
            destinationSettings.currencyKey,
            amountReceived,
            destinationAddress,
            virtualSynth
        );

        // When using a virtual synth, it becomes the destinationAddress for event and settlement tracking
        if (vSynth != IVirtualSynth(0)) {
            destinationAddress = address(vSynth);
        }

        // Remit the fee if required
        if (fee > 0) {
            // Normalize fee to sUSD
            // Note: `fee` is being reused to avoid stack too deep errors.
            fee = addrs.exchangeRates.effectiveValue(destinationSettings.currencyKey, fee, sUSD);

            // Remit the fee in sUSDs
            issuer().synths(sUSD).issue(feePool().FEE_ADDRESS(), fee);

            // Tell the fee pool about this
            feePool().recordFeePaid(fee);
        }

        // Note: As of this point, `fee` is denominated in sUSD.

        // Nothing changes as far as issuance data goes because the total value in the system hasn't changed.
        // But we will update the debt snapshot in case exchange rates have fluctuated since the last exchange
        // in these currencies
        _updateSNXIssuedDebtOnExchange(
            [sourceSettings.currencyKey, destinationSettings.currencyKey],
            [entry.sourceRate, entry.destinationRate]
        );

        // Let the DApps know there was a Synth exchange
        ISynthetixInternal(address(synthetix())).emitSynthExchange(
            from,
            sourceSettings.currencyKey,
            entry.sourceAmountAfterSettlement,
            destinationSettings.currencyKey,
            amountReceived,
            destinationAddress
        );

        // iff the waiting period is gt 0
        if (getWaitingPeriodSecs() > 0) {
            // persist the exchange information for the dest key
            ExchangeSettlementLib.appendExchange(
                addrs,
                destinationAddress,
                sourceSettings.currencyKey,
                entry.sourceAmountAfterSettlement,
                destinationSettings.currencyKey,
                amountReceived,
                entry.exchangeFeeRate
            );
        }
    }

    function _convert(
        bytes32 sourceCurrencyKey,
        address from,
        uint sourceAmountAfterSettlement,
        bytes32 destinationCurrencyKey,
        uint amountReceived,
        address recipient,
        bool virtualSynth
    ) internal returns (IVirtualSynth vSynth) {
        // Burn the source amount
        issuer().synths(sourceCurrencyKey).burn(from, sourceAmountAfterSettlement);

        // Issue their new synths
        ISynth dest = issuer().synths(destinationCurrencyKey);

        if (virtualSynth) {
            Proxyable synth = Proxyable(address(dest));
            vSynth = _createVirtualSynth(IERC20(address(synth.proxy())), recipient, amountReceived, destinationCurrencyKey);
            dest.issue(address(vSynth), amountReceived);
        } else {
            dest.issue(recipient, amountReceived);
        }
    }

    function _createVirtualSynth(
        IERC20,
        address,
        uint,
        bytes32
    ) internal returns (IVirtualSynth) {
        _notImplemented();
    }

    // Note: this function can intentionally be called by anyone on behalf of anyone else (the caller just pays the gas)
    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntriesSettled
        )
    {
        systemStatus().requireSynthActive(currencyKey);
        return ExchangeSettlementLib.internalSettle(resolvedAddresses(), from, currencyKey, true, getWaitingPeriodSecs());
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // gets the exchange parameters for a given direct integration (returns default params if no overrides exist)
    function _exchangeSettings(address from, bytes32 currencyKey)
        internal
        view
        returns (IDirectIntegrationManager.ParameterIntegrationSettings memory settings)
    {
        settings = directIntegrationManager().getExchangeParameters(from, currencyKey);
    }

    // runs basic checks and calls `rateWithSafetyChecks` (which can trigger circuit breakers)
    // returns if there are any problems found with the rate of the given currencyKey but not reverted
    function _ensureCanExchange(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint sourceAmount
    ) internal returns (bool) {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");
        require(sourceAmount > 0, "Zero amount");

        (, bool srcBroken, bool srcStaleOrInvalid) =
            sourceCurrencyKey != sUSD ? exchangeRates().rateWithSafetyChecks(sourceCurrencyKey) : (0, false, false);
        (, bool dstBroken, bool dstStaleOrInvalid) =
            destinationCurrencyKey != sUSD
                ? exchangeRates().rateWithSafetyChecks(destinationCurrencyKey)
                : (0, false, false);

        require(!srcStaleOrInvalid, "src rate stale or flagged");
        require(!dstStaleOrInvalid, "dest rate stale or flagged");

        return !srcBroken && !dstBroken;
    }

    // runs additional checks to verify a rate is valid at a specific round`
    function _ensureCanExchangeAtRound(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    ) internal view {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");

        bytes32[] memory synthKeys = new bytes32[](2);
        synthKeys[0] = sourceCurrencyKey;
        synthKeys[1] = destinationCurrencyKey;

        uint[] memory roundIds = new uint[](2);
        roundIds[0] = roundIdForSrc;
        roundIds[1] = roundIdForDest;
        require(!exchangeRates().anyRateIsInvalidAtRound(synthKeys, roundIds), "src/dest rate stale or flagged");
    }

    /* ========== Exchange Related Fees ========== */
    /// @notice public function to get the total fee rate for a given exchange
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return The exchange fee rate, and whether the rates are too volatile
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint) {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);

        (uint feeRate, bool tooVolatile) = _feeRateForExchange(sourceSettings, destinationSettings);
        require(!tooVolatile, "too volatile");
        return feeRate;
    }

    /// @notice public function to get the dynamic fee rate for a given exchange
    /// @param sourceCurrencyKey The source currency key
    /// @param destinationCurrencyKey The destination currency key
    /// @return The exchange dynamic fee rate and if rates are too volatile
    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint feeRate, bool tooVolatile)
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);

        return _dynamicFeeRateForExchange(sourceSettings, destinationSettings);
    }

    /// @notice Calculate the exchange fee for a given source and destination currency key
    /// @param sourceSettings The source currency key
    /// @param destinationSettings The destination currency key
    /// @return The exchange fee rate
    /// @return The exchange dynamic fee rate and if rates are too volatile
    function _feeRateForExchange(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings
    ) internal view returns (uint feeRate, bool tooVolatile) {
        // Get the exchange fee rate as per the source currencyKey and destination currencyKey
        uint baseRate = sourceSettings.exchangeFeeRate.add(destinationSettings.exchangeFeeRate);
        uint dynamicFee;
        (dynamicFee, tooVolatile) = _dynamicFeeRateForExchange(sourceSettings, destinationSettings);
        return (baseRate.add(dynamicFee), tooVolatile);
    }

    /// @notice Calculate the exchange fee for a given source and destination currency key
    /// @param sourceSettings The source currency key
    /// @param destinationSettings The destination currency key
    /// @param roundIdForSrc The round id of the source currency.
    /// @param roundIdForDest The round id of the target currency.
    /// @return The exchange fee rate
    /// @return The exchange dynamic fee rate
    function _feeRateForExchangeAtRounds(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        uint roundIdForSrc,
        uint roundIdForDest
    ) internal view returns (uint feeRate, bool tooVolatile) {
        // Get the exchange fee rate as per the source currencyKey and destination currencyKey
        uint baseRate = sourceSettings.exchangeFeeRate.add(destinationSettings.exchangeFeeRate);
        uint dynamicFee;
        (dynamicFee, tooVolatile) = _dynamicFeeRateForExchangeAtRounds(
            sourceSettings,
            destinationSettings,
            roundIdForSrc,
            roundIdForDest
        );
        return (baseRate.add(dynamicFee), tooVolatile);
    }

    function _dynamicFeeRateForExchange(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings
    ) internal view returns (uint dynamicFee, bool tooVolatile) {
        (uint dynamicFeeDst, bool dstVolatile) = _dynamicFeeRateForCurrency(destinationSettings);
        (uint dynamicFeeSrc, bool srcVolatile) = _dynamicFeeRateForCurrency(sourceSettings);
        dynamicFee = dynamicFeeDst.add(dynamicFeeSrc);
        // cap to maxFee
        bool overMax = dynamicFee > sourceSettings.exchangeMaxDynamicFee;
        dynamicFee = overMax ? sourceSettings.exchangeMaxDynamicFee : dynamicFee;
        return (dynamicFee, overMax || dstVolatile || srcVolatile);
    }

    function _dynamicFeeRateForExchangeAtRounds(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        uint roundIdForSrc,
        uint roundIdForDest
    ) internal view returns (uint dynamicFee, bool tooVolatile) {
        (uint dynamicFeeDst, bool dstVolatile) = _dynamicFeeRateForCurrencyRound(destinationSettings, roundIdForDest);
        (uint dynamicFeeSrc, bool srcVolatile) = _dynamicFeeRateForCurrencyRound(sourceSettings, roundIdForSrc);
        dynamicFee = dynamicFeeDst.add(dynamicFeeSrc);
        // cap to maxFee
        bool overMax = dynamicFee > sourceSettings.exchangeMaxDynamicFee;
        dynamicFee = overMax ? sourceSettings.exchangeMaxDynamicFee : dynamicFee;
        return (dynamicFee, overMax || dstVolatile || srcVolatile);
    }

    /// @notice Get dynamic dynamicFee for a given currency key (SIP-184)
    /// @param settings The given currency key
    /// @return The dynamic fee and if it exceeds max dynamic fee set in config
    function _dynamicFeeRateForCurrency(IDirectIntegrationManager.ParameterIntegrationSettings memory settings)
        internal
        view
        returns (uint dynamicFee, bool tooVolatile)
    {
        // no dynamic dynamicFee for sUSD or too few rounds
        if (settings.currencyKey == sUSD || settings.exchangeDynamicFeeRounds <= 1) {
            return (0, false);
        }
        uint roundId = exchangeRates().getCurrentRoundId(settings.currencyKey);
        return _dynamicFeeRateForCurrencyRound(settings, roundId);
    }

    /// @notice Get dynamicFee for a given currency key (SIP-184)
    /// @param settings The given currency key
    /// @param roundId The round id
    /// @return The dynamic fee and if it exceeds max dynamic fee set in config
    function _dynamicFeeRateForCurrencyRound(
        IDirectIntegrationManager.ParameterIntegrationSettings memory settings,
        uint roundId
    ) internal view returns (uint dynamicFee, bool tooVolatile) {
        // no dynamic dynamicFee for sUSD or too few rounds
        if (settings.currencyKey == sUSD || settings.exchangeDynamicFeeRounds <= 1) {
            return (0, false);
        }
        uint[] memory prices;
        (prices, ) = exchangeRates().ratesAndUpdatedTimeForCurrencyLastNRounds(
            settings.currencyKey,
            settings.exchangeDynamicFeeRounds,
            roundId
        );
        dynamicFee = _dynamicFeeCalculation(
            prices,
            settings.exchangeDynamicFeeThreshold,
            settings.exchangeDynamicFeeWeightDecay
        );
        // cap to maxFee
        bool overMax = dynamicFee > settings.exchangeMaxDynamicFee;
        dynamicFee = overMax ? settings.exchangeMaxDynamicFee : dynamicFee;
        return (dynamicFee, overMax);
    }

    /// @notice Calculate dynamic fee according to SIP-184
    /// @param prices A list of prices from the current round to the previous rounds
    /// @param threshold A threshold to clip the price deviation ratop
    /// @param weightDecay A weight decay constant
    /// @return uint dynamic fee rate as decimal
    function _dynamicFeeCalculation(
        uint[] memory prices,
        uint threshold,
        uint weightDecay
    ) internal pure returns (uint) {
        // don't underflow
        if (prices.length == 0) {
            return 0;
        }

        uint dynamicFee = 0; // start with 0
        // go backwards in price array
        for (uint i = prices.length - 1; i > 0; i--) {
            // apply decay from previous round (will be 0 for first round)
            dynamicFee = dynamicFee.multiplyDecimal(weightDecay);
            // calculate price deviation
            uint deviation = _thresholdedAbsDeviationRatio(prices[i - 1], prices[i], threshold);
            // add to total fee
            dynamicFee = dynamicFee.add(deviation);
        }
        return dynamicFee;
    }

    /// absolute price deviation ratio used by dynamic fee calculation
    /// deviationRatio = (abs(current - previous) / previous) - threshold
    /// if negative, zero is returned
    function _thresholdedAbsDeviationRatio(
        uint price,
        uint previousPrice,
        uint threshold
    ) internal pure returns (uint) {
        if (previousPrice == 0) {
            return 0; // don't divide by zero
        }
        // abs difference between prices
        uint absDelta = price > previousPrice ? price - previousPrice : previousPrice - price;
        // relative to previous price
        uint deviationRatio = absDelta.divideDecimal(previousPrice);
        // only the positive difference from threshold
        return deviationRatio > threshold ? deviationRatio - threshold : 0;
    }

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        )
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);

        require(sourceCurrencyKey == sUSD || !exchangeRates().rateIsInvalid(sourceCurrencyKey), "src synth rate invalid");

        require(
            destinationCurrencyKey == sUSD || !exchangeRates().rateIsInvalid(destinationCurrencyKey),
            "dest synth rate invalid"
        );

        // The checks are added for consistency with the checks performed in _exchange()
        // The reverts (instead of no-op returns) are used order to prevent incorrect usage in calling contracts
        // (The no-op in _exchange() is in order to trigger system suspension if needed)

        // check synths active
        systemStatus().requireSynthActive(sourceCurrencyKey);
        systemStatus().requireSynthActive(destinationCurrencyKey);

        bool tooVolatile;
        (exchangeFeeRate, tooVolatile) = _feeRateForExchange(sourceSettings, destinationSettings);

        // check rates volatility result
        require(!tooVolatile, "exchange rates too volatile");

        (uint destinationAmount, , ) =
            exchangeRates().effectiveValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        amountReceived = ExchangeSettlementLib._deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }

    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

    // ========== MODIFIERS ==========

    modifier onlySynthetixorSynth() {
        ISynthetix _synthetix = synthetix();
        require(
            msg.sender == address(_synthetix) || _synthetix.synthsByAddress(msg.sender) != bytes32(0),
            "Exchanger: Only synthetix or a synth contract can perform this action"
        );
        _;
    }

    // ========== EVENTS ==========
    // note bot hof these events are actually emitted from `ExchangeSettlementLib`
    // but they are defined here for interface reasons
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
