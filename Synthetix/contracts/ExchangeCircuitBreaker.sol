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
import "./interfaces/IExchangeCircuitBreaker.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/ISynth.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IExchangeRates.sol";
import "./Proxyable.sol";

/**
 * Compares current exchange rate to previous, and suspends a synth if the
 * difference is outside of deviation bounds.
 *
 * This contract's functionality has been superseded by `CircuitBreaker`, and therefore its *deprecated*.
 * ExchangeCircuitBreaker is currently used within the system only as a compatibility measure for non-upgradable
 * contracts for the time being.
 *
 * https://docs.synthetix.io/contracts/source/contracts/ExchangeCircuitBreaker
 */
contract ExchangeCircuitBreaker is Owned, MixinSystemSettings, IExchangeCircuitBreaker {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "ExchangeCircuitBreaker";

    // SIP-65: Decentralized circuit breaker
    uint public constant CIRCUIT_BREAKER_SUSPENSION_REASON = 65;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_EXRATES;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function exchangeRates() public view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    // Returns rate and its "invalid" state.
    // Rate can be invalid either due to:
    //  1. Returned as invalid from ExchangeRates - due to being stale, or flagged by oracle.
    //  2, Out of deviation dounds w.r.t. to previously stored rate or if there is no
    //  valid stored rate, w.r.t. to previous 3 oracle rates.
    function rateWithInvalid(bytes32 currencyKey) external view returns (uint rate, bool invalid) {
        (rate, invalid) = exchangeRates().rateAndInvalid(currencyKey);
    }

    /* ========== Mutating ========== */

    /**
     * COMPATIBILITY -- calls `ExchangeRates.rateWithSafetyChecks` which provides equivalent functionality for non-upgradable
     * contracts (futures)
     */
    function rateWithBreakCircuit(bytes32 currencyKey) external returns (uint lastValidRate, bool invalid) {
        bool staleOrInvalid;
        bool circuitBroken;
        (lastValidRate, circuitBroken, staleOrInvalid) = exchangeRates().rateWithSafetyChecks(currencyKey);

        invalid = circuitBroken || staleOrInvalid;
    }
}
