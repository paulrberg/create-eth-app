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
import "./Owned.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/ICircuitBreaker.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/ISynth.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IExchangeRates.sol";
import "./Proxyable.sol";

// Chainlink
import "Synthetix/@chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol";

/**
 * Compares current exchange rate to previous, and suspends a synth if the
 * difference is outside of deviation bounds.
 * Stores last "good" rate for each synth on each invocation.
 * Inteded use is to use in combination with ExchangeRates on mutative exchange-like
 * methods.
 * Suspend functionality is public, resume functionality is controlled by owner.
 *
 * https://docs.synthetix.io/contracts/source/contracts/CircuitBreaker
 */
contract CircuitBreaker is Owned, MixinSystemSettings, ICircuitBreaker {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "CircuitBreaker";

    // is internal to have lastValue getter in interface in solidity v0.5
    // TODO: after upgrading solidity, switch to just public lastValue instead
    //  of maintaining this internal one
    mapping(address => uint) internal _lastValue;
    mapping(address => bool) internal _circuitBroken;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](3);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_ISSUER;
        newAddresses[2] = CONTRACT_EXRATES;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    // Returns whether or not a rate would be come invalid
    // ignores systemStatus check
    function isInvalid(address oracleAddress, uint value) external view returns (bool) {
        return _circuitBroken[oracleAddress] || _isRateOutOfBounds(oracleAddress, value) || value == 0;
    }

    function isDeviationAboveThreshold(uint base, uint comparison) external view returns (bool) {
        return _isDeviationAboveThreshold(base, comparison);
    }

    function priceDeviationThresholdFactor() external view returns (uint) {
        return getPriceDeviationThresholdFactor();
    }

    function lastValue(address oracleAddress) external view returns (uint) {
        return _lastValue[oracleAddress];
    }

    function circuitBroken(address oracleAddress) external view returns (bool) {
        return _circuitBroken[oracleAddress];
    }

    /* ========== Internal views ========== */

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    /* ========== Mutating ========== */

    /**
     * Checks rate deviation from previous and its "invalid" oracle state (stale rate, of flagged by oracle).
     * If its valid, set the `circuitBoken` flag and return false. Continue storing price updates as normal.
     * Also, checks that system is not suspended currently, if it is - doesn't perform any checks, and
     * returns last rate and the current broken state, to prevent synths suspensions during maintenance.
     */
    function probeCircuitBreaker(address oracleAddress, uint value) external onlyProbers returns (bool circuitBroken) {
        require(oracleAddress != address(0), "Oracle address is 0");

        // these conditional statements are ordered for short circuit (heh) efficiency to reduce gas usage
        // in the usual case of no circuit broken.
        if (
            // cases where the new price should be triggering a circuit break
            (value == 0 || _isRateOutOfBounds(oracleAddress, value)) &&
            // other necessary states in order to break
            !_circuitBroken[oracleAddress] &&
            !systemStatus().systemSuspended()
        ) {
            _circuitBroken[oracleAddress] = true;
            emit CircuitBroken(oracleAddress, _lastValue[oracleAddress], value);
        }

        _lastValue[oracleAddress] = value;

        return _circuitBroken[oracleAddress];
    }

    /**
     * SIP-139
     * resets the stored value for _lastValue for multiple currencies to the latest rate
     * can be used to enable synths after a broken circuit happenned
     * doesn't check deviations here, so believes that owner knows better
     * emits LastRateOverridden
     */
    function resetLastValue(address[] calldata oracleAddresses, uint[] calldata values) external onlyOwner {
        for (uint i = 0; i < oracleAddresses.length; i++) {
            require(oracleAddresses[i] != address(0), "Oracle address is 0");
            emit LastValueOverridden(oracleAddresses[i], _lastValue[oracleAddresses[i]], values[i]);
            _lastValue[oracleAddresses[i]] = values[i];
            _circuitBroken[oracleAddresses[i]] = false;
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _isDeviationAboveThreshold(uint base, uint comparison) internal view returns (bool) {
        if (base == 0 || comparison == 0) {
            return true;
        }

        uint factor;
        if (comparison > base) {
            factor = comparison.divideDecimal(base);
        } else {
            factor = base.divideDecimal(comparison);
        }

        return factor >= getPriceDeviationThresholdFactor();
    }

    /**
     * Rate is invalid if it is outside of deviation bounds relative to previous non-zero rate
     */
    function _isRateOutOfBounds(address oracleAddress, uint current) internal view returns (bool) {
        uint last = _lastValue[oracleAddress];

        // `last == 0` indicates unset/unpopulated oracle. If we dont have any data on the previous oracle price,
        // we should skip the deviation check and allow it to be populated.
        if (last > 0) {
            return _isDeviationAboveThreshold(last, current);
        }

        return false;
    }

    // ========== MODIFIERS =======

    modifier onlyProbers() {
        require(
            msg.sender == requireAndGetAddress(CONTRACT_ISSUER) || msg.sender == requireAndGetAddress(CONTRACT_EXRATES),
            "Only internal contracts can call this function"
        );

        _;
    }

    // ========== EVENTS ==========

    // @notice signals that a the "last value" was overridden by one of the admin methods
    //   with a value that didn't come directly from the ExchangeRates.getRates methods
    event LastValueOverridden(address indexed oracleAddress, uint256 previousValue, uint256 newValue);

    // @notice signals that the circuit was broken
    event CircuitBroken(address indexed oracleAddress, uint256 previousValue, uint256 newValue);
}
