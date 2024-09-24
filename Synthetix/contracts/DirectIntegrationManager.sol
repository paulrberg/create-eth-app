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
import "./interfaces/IDirectIntegrationManager.sol";

/*
 * SIP-267: Direct Integration
 * https://sips.synthetix.io/sips/sip-267/
 *
 * Used by the Spartan Council to approve an external contract, (i.e. one which is not owned or managed by the Synthetix protocol),
 * to interact with Synthetix's core exchange functionalities with overridden parameters.
 * If no parameter overrides are specified, then the prevailing parameter configuration will be automatically used.
 */
contract DirectIntegrationManager is Owned, MixinSystemSettings, IDirectIntegrationManager {
    /* ========== CONSTANTS ========== */
    bytes32 private constant CONTRACT_NAME = "DirectIntegration";

    bytes32 private constant CONTRACT_NAME_EXCHANGE_RATES = "ExchangeRates";

    bytes32 internal constant SETTING_DEX_PRICE_AGGREGATOR = "dexPriceAggregator";

    uint internal constant DI_VERSION = 1;

    /* ---------- Internal Variables ---------- */

    // Stores a mapping of all overridden parameters for a given direct integration.
    mapping(address => mapping(bytes32 => ParameterIntegrationSettings)) internal _settings;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    /* ---------- Getters ---------- */

    /**
     * Used to read the configured overridden values for a given integration.
     * @param integration the address of the external integrator's contract
     */
    function getExchangeParameters(address integration, bytes32 currencyKey)
        external
        view
        returns (ParameterIntegrationSettings memory overrides)
    {
        ParameterIntegrationSettings memory storedOverrides = _settings[integration][currencyKey];

        return
            ParameterIntegrationSettings({
                currencyKey: currencyKey,
                dexPriceAggregator: storedOverrides.dexPriceAggregator != address(0)
                    ? storedOverrides.dexPriceAggregator
                    : flexibleStorage().getAddressValue(CONTRACT_NAME_EXCHANGE_RATES, SETTING_DEX_PRICE_AGGREGATOR),
                atomicEquivalentForDexPricing: storedOverrides.atomicEquivalentForDexPricing != address(0)
                    ? storedOverrides.atomicEquivalentForDexPricing
                    : getAtomicEquivalentForDexPricing(currencyKey),
                atomicExchangeFeeRate: storedOverrides.atomicExchangeFeeRate > 0
                    ? storedOverrides.atomicExchangeFeeRate
                    : getAtomicExchangeFeeRate(currencyKey),
                atomicTwapWindow: storedOverrides.atomicTwapWindow > 0
                    ? storedOverrides.atomicTwapWindow
                    : getAtomicTwapWindow(),
                atomicMaxVolumePerBlock: storedOverrides.atomicMaxVolumePerBlock > 0
                    ? storedOverrides.atomicMaxVolumePerBlock
                    : getAtomicMaxVolumePerBlock(),
                atomicVolatilityConsiderationWindow: storedOverrides.atomicVolatilityConsiderationWindow > 0
                    ? storedOverrides.atomicVolatilityConsiderationWindow
                    : getAtomicVolatilityConsiderationWindow(currencyKey),
                atomicVolatilityUpdateThreshold: storedOverrides.atomicVolatilityUpdateThreshold > 0
                    ? storedOverrides.atomicVolatilityUpdateThreshold
                    : getAtomicVolatilityUpdateThreshold(currencyKey),
                exchangeFeeRate: storedOverrides.exchangeFeeRate > 0
                    ? storedOverrides.exchangeFeeRate
                    : getExchangeFeeRate(currencyKey),
                exchangeMaxDynamicFee: storedOverrides.exchangeMaxDynamicFee > 0
                    ? storedOverrides.exchangeMaxDynamicFee
                    : getExchangeMaxDynamicFee(),
                exchangeDynamicFeeRounds: storedOverrides.exchangeDynamicFeeRounds > 0
                    ? storedOverrides.exchangeDynamicFeeRounds
                    : getExchangeDynamicFeeRounds(),
                exchangeDynamicFeeThreshold: storedOverrides.exchangeDynamicFeeThreshold > 0
                    ? storedOverrides.exchangeDynamicFeeThreshold
                    : getExchangeDynamicFeeThreshold(),
                exchangeDynamicFeeWeightDecay: storedOverrides.exchangeDynamicFeeWeightDecay > 0
                    ? storedOverrides.exchangeDynamicFeeWeightDecay
                    : getExchangeDynamicFeeWeightDecay()
            });
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /**
     * Sets an override to be used for a given direct integration that supersedes the default Synthetix parameter value.
     * @param integration the address of the external integrator's contract
     * @param settings a collection of parameters to be overridden
     * @dev Invoking this function will overwrite whatever overrides were previously set. Set overrides to zero to "remove" them.
     * @notice This will require a SIP and a presentation, given the importance of clearly presenting
     * external interactions with Synthetix contracts and the parameter overrides that would be implemented.
     */
    function setExchangeParameters(
        address integration,
        bytes32[] calldata currencyKeys,
        ParameterIntegrationSettings calldata settings
    ) external onlyOwner {
        for (uint i = 0; i < currencyKeys.length; i++) {
            _setExchangeParameters(integration, currencyKeys[i], settings);
        }
    }

    /* ---------- Internal Functions ---------- */

    function _setExchangeParameters(
        address integration,
        bytes32 currencyKey,
        ParameterIntegrationSettings memory settings
    ) internal {
        require(address(integration) != address(0), "Address cannot be 0");

        _settings[integration][currencyKey] = settings; // overwrites the parameters for a given direct integration
        emit IntegrationParametersSet(integration, currencyKey, settings);
    }

    /* ========== EVENTS ========== */

    event IntegrationParametersSet(
        address indexed integration,
        bytes32 indexed currencyKey,
        ParameterIntegrationSettings overrides
    );
}
