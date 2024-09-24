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
import "./Exchanger.sol";

// Internal references
import "./MinimalProxyFactory.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IDirectIntegrationManager.sol";
import "./interfaces/IERC20.sol";

interface IVirtualSynthInternal {
    function initialize(
        IERC20 _synth,
        IAddressResolver _resolver,
        address _recipient,
        uint _amount,
        bytes32 _currencyKey
    ) external;
}

// https://docs.synthetix.io/contracts/source/contracts/exchangerwithfeereclamationalternatives
contract ExchangerWithFeeRecAlternatives is MinimalProxyFactory, Exchanger {
    bytes32 public constant CONTRACT_NAME = "ExchangerWithFeeRecAlternatives";

    using SafeMath for uint;

    struct ExchangeVolumeAtPeriod {
        uint64 time;
        uint192 volume;
    }

    ExchangeVolumeAtPeriod public lastAtomicVolume;

    constructor(address _owner, address _resolver) public MinimalProxyFactory() Exchanger(_owner, _resolver) {}

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_VIRTUALSYNTH_MASTERCOPY = "VirtualSynthMastercopy";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = Exchanger.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_VIRTUALSYNTH_MASTERCOPY;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ========== VIEWS ========== */

    function atomicMaxVolumePerBlock() external view returns (uint) {
        return getAtomicMaxVolumePerBlock();
    }

    function feeRateForAtomicExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate)
    {
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            _exchangeSettings(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            _exchangeSettings(msg.sender, destinationCurrencyKey);
        exchangeFeeRate = _feeRateForAtomicExchange(sourceSettings, destinationSettings);
    }

    function getAmountsForAtomicExchange(
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
        IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings = _exchangeSettings(msg.sender, sUSD);

        (amountReceived, fee, exchangeFeeRate, , , ) = _getAmountsForAtomicExchangeMinusFees(
            sourceAmount,
            sourceSettings,
            destinationSettings,
            usdSettings
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode,
        uint minAmount
    ) external onlySynthetixorSynth returns (uint amountReceived) {
        uint fee;
        (amountReceived, fee) = _exchangeAtomically(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress
        );

        require(amountReceived >= minAmount, "The amount received is below the minimum amount specified.");

        _processTradingRewards(fee, destinationAddress);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, destinationCurrencyKey, amountReceived, fee);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _virtualSynthMastercopy() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_VIRTUALSYNTH_MASTERCOPY);
    }

    function _createVirtualSynth(
        IERC20 synth,
        address recipient,
        uint amount,
        bytes32 currencyKey
    ) internal returns (IVirtualSynth) {
        // prevent inverse synths from being allowed due to purgeability
        require(currencyKey[0] != 0x69, "Cannot virtualize this synth");

        IVirtualSynthInternal vSynth =
            IVirtualSynthInternal(_cloneAsMinimalProxy(_virtualSynthMastercopy(), "Could not create new vSynth"));
        vSynth.initialize(synth, resolver, recipient, amount, currencyKey);
        emit VirtualSynthCreated(address(synth), recipient, address(vSynth), currencyKey, amount);

        return IVirtualSynth(address(vSynth));
    }

    function _exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) internal returns (uint amountReceived, uint fee) {
        uint sourceAmountAfterSettlement;
        uint exchangeFeeRate;
        uint systemSourceRate;
        uint systemDestinationRate;

        {
            IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
                _exchangeSettings(from, sourceCurrencyKey);
            IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
                _exchangeSettings(from, destinationCurrencyKey);

            if (!_ensureCanExchange(sourceCurrencyKey, destinationCurrencyKey, sourceAmount)) {
                return (0, 0);
            }
            require(!exchangeRates().synthTooVolatileForAtomicExchange(sourceSettings), "Src synth too volatile");
            require(!exchangeRates().synthTooVolatileForAtomicExchange(destinationSettings), "Dest synth too volatile");

            sourceAmountAfterSettlement = _settleAndCalcSourceAmountRemaining(sourceAmount, from, sourceCurrencyKey);

            // If, after settlement the user has no balance left (highly unlikely), then return to prevent
            // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
            if (sourceAmountAfterSettlement == 0) {
                return (0, 0);
            }

            // sometimes we need parameters for USD and USD has parameters which could be overridden
            IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings = _exchangeSettings(from, sUSD);

            uint systemConvertedAmount;

            // Note: also ensures the given synths are allowed to be atomically exchanged
            (
                amountReceived, // output amount with fee taken out (denominated in dest currency)
                fee, // fee amount (denominated in dest currency)
                exchangeFeeRate, // applied fee rate
                systemConvertedAmount, // current system value without fees (denominated in dest currency)
                systemSourceRate, // current system rate for src currency
                systemDestinationRate // current system rate for dest currency
            ) = _getAmountsForAtomicExchangeMinusFees(
                sourceAmountAfterSettlement,
                sourceSettings,
                destinationSettings,
                usdSettings
            );

            // Sanity check atomic output's value against current system value (checking atomic rates)
            require(
                !circuitBreaker().isDeviationAboveThreshold(systemConvertedAmount, amountReceived.add(fee)),
                "Atomic rate deviates too much"
            );

            // Determine sUSD value of exchange
            uint sourceSusdValue;
            if (sourceCurrencyKey == sUSD) {
                // Use after-settled amount as this is amount converted (not sourceAmount)
                sourceSusdValue = sourceAmountAfterSettlement;
            } else if (destinationCurrencyKey == sUSD) {
                // In this case the systemConvertedAmount would be the fee-free sUSD value of the source synth
                sourceSusdValue = systemConvertedAmount;
            } else {
                // Otherwise, convert source to sUSD value
                (uint amountReceivedInUSD, uint sUsdFee, , , , ) =
                    _getAmountsForAtomicExchangeMinusFees(
                        sourceAmountAfterSettlement,
                        sourceSettings,
                        usdSettings,
                        usdSettings
                    );
                sourceSusdValue = amountReceivedInUSD.add(sUsdFee);
            }

            // Check and update atomic volume limit
            _checkAndUpdateAtomicVolume(sourceSettings, sourceSusdValue);
        }

        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.

        _convert(
            sourceCurrencyKey,
            from,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress,
            false // no vsynths
        );

        // Remit the fee if required
        if (fee > 0) {
            // Normalize fee to sUSD
            // Note: `fee` is being reused to avoid stack too deep errors.
            fee = exchangeRates().effectiveValue(destinationCurrencyKey, fee, sUSD);

            // Remit the fee in sUSDs
            issuer().synths(sUSD).issue(feePool().FEE_ADDRESS(), fee);

            // Tell the fee pool about this
            feePool().recordFeePaid(fee);
        }

        // Note: As of this point, `fee` is denominated in sUSD.

        // Note: this update of the debt snapshot will not be accurate because the atomic exchange
        // was executed with a different rate than the system rate. To be perfect, issuance data,
        // priced in system rates, should have been adjusted on the src and dest synth.
        // The debt pool is expected to be deprecated soon, and so we don't bother with being
        // perfect here. For now, an inaccuracy will slowly accrue over time with increasing atomic
        // exchange volume.
        _updateSNXIssuedDebtOnExchange(
            [sourceCurrencyKey, destinationCurrencyKey],
            [systemSourceRate, systemDestinationRate]
        );

        // Let the DApps know there was a Synth exchange
        ISynthetixInternal(address(synthetix())).emitSynthExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // Emit separate event to track atomic exchanges
        ISynthetixInternal(address(synthetix())).emitAtomicSynthExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // No need to persist any exchange information, as no settlement is required for atomic exchanges
    }

    function _checkAndUpdateAtomicVolume(
        IDirectIntegrationManager.ParameterIntegrationSettings memory settings,
        uint sourceSusdValue
    ) internal {
        uint currentVolume =
            uint(lastAtomicVolume.time) == block.timestamp
                ? uint(lastAtomicVolume.volume).add(sourceSusdValue)
                : sourceSusdValue;
        require(currentVolume <= settings.atomicMaxVolumePerBlock, "Surpassed volume limit");
        lastAtomicVolume.time = uint64(block.timestamp);
        lastAtomicVolume.volume = uint192(currentVolume); // Protected by volume limit check above
    }

    function _feeRateForAtomicExchange(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings
    ) internal view returns (uint) {
        // Get the exchange fee rate as per source and destination currencyKey
        uint baseRate = sourceSettings.atomicExchangeFeeRate.add(destinationSettings.atomicExchangeFeeRate);
        if (baseRate == 0) {
            // If no atomic rate was set, fallback to the regular exchange rate
            baseRate = sourceSettings.exchangeFeeRate.add(destinationSettings.exchangeFeeRate);
        }

        return baseRate;
    }

    function _getAmountsForAtomicExchangeMinusFees(
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings
    )
        internal
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate,
            uint systemConvertedAmount,
            uint systemSourceRate,
            uint systemDestinationRate
        )
    {
        uint destinationAmount;
        (destinationAmount, systemConvertedAmount, systemSourceRate, systemDestinationRate) = exchangeRates()
            .effectiveAtomicValueAndRates(sourceSettings, sourceAmount, destinationSettings, usdSettings);

        exchangeFeeRate = _feeRateForAtomicExchange(sourceSettings, destinationSettings);
        amountReceived = ExchangeSettlementLib._deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }

    event VirtualSynthCreated(
        address indexed synth,
        address indexed recipient,
        address vSynth,
        bytes32 currencyKey,
        uint amount
    );
}
