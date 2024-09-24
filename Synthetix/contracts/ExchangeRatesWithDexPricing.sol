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
import "./ExchangeRates.sol";
import "./interfaces/IDexPriceAggregator.sol";

// https://docs.synthetix.io/contracts/source/contracts/exchangerateswithdexpricing
contract ExchangeRatesWithDexPricing is ExchangeRates {
    bytes32 public constant CONTRACT_NAME = "ExchangeRatesWithDexPricing";

    bytes32 internal constant SETTING_DEX_PRICE_AGGREGATOR = "dexPriceAggregator";

    constructor(address _owner, address _resolver) public ExchangeRates(_owner, _resolver) {}

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_DIRECT_INTEGRATION_MANAGER = "DirectIntegrationManager";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = ExchangeRates.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_DIRECT_INTEGRATION_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ========== SETTERS ========== */

    function setDexPriceAggregator(IDexPriceAggregator _dexPriceAggregator) external onlyOwner {
        flexibleStorage().setAddressValue(
            ExchangeRates.CONTRACT_NAME,
            SETTING_DEX_PRICE_AGGREGATOR,
            address(_dexPriceAggregator)
        );
        emit DexPriceAggregatorUpdated(address(_dexPriceAggregator));
    }

    /* ========== VIEWS ========== */

    function directIntegrationManager() internal view returns (IDirectIntegrationManager) {
        return IDirectIntegrationManager(requireAndGetAddress(CONTRACT_DIRECT_INTEGRATION_MANAGER));
    }

    function dexPriceAggregator() public view returns (IDexPriceAggregator) {
        return
            IDexPriceAggregator(
                flexibleStorage().getAddressValue(ExchangeRates.CONTRACT_NAME, SETTING_DEX_PRICE_AGGREGATOR)
            );
    }

    // SIP-120 Atomic exchanges
    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint amount,
        bytes32 destinationCurrencyKey
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
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings =
            directIntegrationManager().getExchangeParameters(msg.sender, sourceCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings =
            directIntegrationManager().getExchangeParameters(msg.sender, destinationCurrencyKey);
        IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings =
            directIntegrationManager().getExchangeParameters(msg.sender, sUSD);

        return effectiveAtomicValueAndRates(sourceSettings, amount, destinationSettings, usdSettings);
    }

    // SIP-120 Atomic exchanges
    // Note that the returned systemValue, systemSourceRate, and systemDestinationRate are based on
    // the current system rate, which may not be the atomic rate derived from value / sourceAmount
    function effectiveAtomicValueAndRates(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory usdSettings
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
        (systemValue, systemSourceRate, systemDestinationRate) = _effectiveValueAndRates(
            sourceSettings.currencyKey,
            sourceAmount,
            destinationSettings.currencyKey
        );

        bool usePureChainlinkPriceForSource = getPureChainlinkPriceForAtomicSwapsEnabled(sourceSettings.currencyKey);
        bool usePureChainlinkPriceForDest = getPureChainlinkPriceForAtomicSwapsEnabled(destinationSettings.currencyKey);
        uint sourceRate;
        uint destRate;

        // Handle the different scenarios that may arise when trading currencies with or without the PureChainlinkPrice set.
        // outlined here: https://sips.synthetix.io/sips/sip-198/#computation-methodology-in-atomic-pricing
        if (usePureChainlinkPriceForSource) {
            sourceRate = systemSourceRate;
        } else {
            sourceRate = _getMinValue(
                systemSourceRate,
                _getPriceFromDexAggregator(sourceSettings, usdSettings, sourceAmount)
            );
        }

        if (usePureChainlinkPriceForDest) {
            destRate = systemDestinationRate;
        } else {
            destRate = _getMaxValue(
                systemDestinationRate,
                _getPriceFromDexAggregator(usdSettings, destinationSettings, sourceAmount)
            );
        }

        value = sourceAmount.mul(sourceRate).div(destRate);
    }

    function _getMinValue(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }

    function _getMaxValue(uint x, uint y) internal pure returns (uint) {
        return x > y ? x : y;
    }

    /// @notice Retrieve the TWAP (time-weighted average price) of an asset from its Uniswap V3-equivalent pool
    /// @dev By default, the TWAP oracle 'hops' through the wETH pool. This can be overridden. See DexPriceAggregator for more information.
    /// @dev The TWAP oracle doesn't take into account variable slippage due to trade amounts, as Uniswap's OracleLibary doesn't cross ticks based on their liquidity. See: https://docs.uniswap.org/protocol/concepts/V3-overview/oracle#deriving-price-from-a-tick
    /// @dev One of `sourceCurrencyKey` or `destCurrencyKey` should be sUSD. There are two parameters to indicate directionality. Because this function returns "price", if the source is sUSD, the result will be flipped.
    /// @param sourceSettings The settings data for the source token
    /// @param destinationSettings The settings data for the destination token
    /// @param amount The amount of the asset we're interested in
    /// @return The price of the asset
    function _getPriceFromDexAggregator(
        IDirectIntegrationManager.ParameterIntegrationSettings memory sourceSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings memory destinationSettings,
        uint amount
    ) internal view returns (uint) {
        require(amount != 0, "Amount must be greater than 0");
        require(
            sourceSettings.currencyKey == sUSD || destinationSettings.currencyKey == sUSD,
            "Atomic swaps must go through sUSD"
        );

        IERC20 sourceEquivalent = IERC20(sourceSettings.atomicEquivalentForDexPricing);
        require(address(sourceEquivalent) != address(0), "No atomic equivalent for source");

        IERC20 destEquivalent = IERC20(destinationSettings.atomicEquivalentForDexPricing);
        require(address(destEquivalent) != address(0), "No atomic equivalent for dest");

        uint result =
            _dexPriceDestinationValue(
                IDexPriceAggregator(sourceSettings.dexPriceAggregator),
                sourceEquivalent,
                destEquivalent,
                amount,
                sourceSettings
                    .atomicTwapWindow
            )
                .mul(SafeDecimalMath.unit())
                .div(amount);

        require(result != 0, "Result must be greater than 0");

        return destinationSettings.currencyKey == "sUSD" ? result : SafeDecimalMath.unit().divideDecimalRound(result);
    }

    function _dexPriceDestinationValue(
        IDexPriceAggregator dexAggregator,
        IERC20 sourceEquivalent,
        IERC20 destEquivalent,
        uint sourceAmount,
        uint twapWindow
    ) internal view returns (uint) {
        // Normalize decimals in case equivalent asset uses different decimals from internal unit
        uint sourceAmountInEquivalent =
            (sourceAmount.mul(10**uint(sourceEquivalent.decimals()))).div(SafeDecimalMath.unit());

        require(address(dexAggregator) != address(0), "dex aggregator address is 0");

        require(twapWindow != 0, "Uninitialized atomic twap window");

        uint twapValueInEquivalent =
            dexAggregator.assetToAsset(
                address(sourceEquivalent),
                sourceAmountInEquivalent,
                address(destEquivalent),
                twapWindow
            );

        require(twapValueInEquivalent > 0, "dex price returned 0");

        // Similar to source amount, normalize decimals back to internal unit for output amount
        return (twapValueInEquivalent.mul(SafeDecimalMath.unit())).div(10**uint(destEquivalent.decimals()));
    }

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) public view returns (bool) {
        IDirectIntegrationManager.ParameterIntegrationSettings memory settings =
            directIntegrationManager().getExchangeParameters(msg.sender, currencyKey);

        return synthTooVolatileForAtomicExchange(settings);
    }

    function synthTooVolatileForAtomicExchange(IDirectIntegrationManager.ParameterIntegrationSettings memory settings)
        public
        view
        returns (bool)
    {
        // sUSD is a special case and is never volatile
        if (settings.currencyKey == "sUSD") return false;

        uint considerationWindow = settings.atomicVolatilityConsiderationWindow;
        uint updateThreshold = settings.atomicVolatilityUpdateThreshold;

        if (considerationWindow == 0 || updateThreshold == 0) {
            // If either volatility setting is not set, never judge an asset to be volatile
            return false;
        }

        // Go back through the historical oracle update rounds to see if there have been more
        // updates in the consideration window than the allowed threshold.
        // If there have, consider the asset volatile--by assumption that many close-by oracle
        // updates is a good proxy for price volatility.
        uint considerationWindowStart = block.timestamp.sub(considerationWindow);
        uint roundId = _getCurrentRoundId(settings.currencyKey);
        for (updateThreshold; updateThreshold > 0; updateThreshold--) {
            (uint rate, uint time) = _getRateAndTimestampAtRound(settings.currencyKey, roundId);
            if (time != 0 && time < considerationWindowStart) {
                // Round was outside consideration window so we can stop querying further rounds
                return false;
            } else if (rate == 0 || time == 0) {
                // Either entire round or a rate inside consideration window was not available
                // Consider the asset volatile
                break;
            }

            if (roundId == 0) {
                // Not enough historical data to continue further
                // Consider the asset volatile
                break;
            }
            roundId--;
        }

        return true;
    }

    /* ========== EVENTS ========== */

    event DexPriceAggregatorUpdated(address newDexPriceAggregator);
}
