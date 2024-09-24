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

// Internal references
import "./interfaces/IOwnerRelayOnOptimism.sol";
import "Synthetix/@eth-optimism/contracts/iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

contract OwnerRelayOnEthereum is MixinSystemSettings, Owned {
    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_EXT_MESSENGER = "ext:Messenger";
    bytes32 private constant CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM = "ovm:OwnerRelayOnOptimism";

    // ========== CONSTRUCTOR ==========

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== INTERNALS ============ */

    function _messenger() private view returns (iAbs_BaseCrossDomainMessenger) {
        return iAbs_BaseCrossDomainMessenger(requireAndGetAddress(CONTRACT_EXT_MESSENGER));
    }

    function _ownerRelayOnOptimism() private view returns (address) {
        return requireAndGetAddress(CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM);
    }

    function _getCrossDomainGasLimit(uint32 crossDomainGasLimit) private view returns (uint32) {
        // Use specified crossDomainGasLimit if specified value is not zero.
        // otherwise use the default in SystemSettings.
        return
            crossDomainGasLimit != 0
                ? crossDomainGasLimit
                : uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Relay));
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](2);
        newAddresses[0] = CONTRACT_EXT_MESSENGER;
        newAddresses[1] = CONTRACT_OVM_OWNER_RELAY_ON_OPTIMISM;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ========== RESTRICTED ========== */

    function initiateRelay(
        address target,
        bytes calldata payload,
        uint32 crossDomainGasLimit // If zero, uses default value in SystemSettings
    ) external onlyOwner {
        IOwnerRelayOnOptimism ownerRelayOnOptimism;
        bytes memory messageData = abi.encodeWithSelector(ownerRelayOnOptimism.finalizeRelay.selector, target, payload);

        _messenger().sendMessage(_ownerRelayOnOptimism(), messageData, _getCrossDomainGasLimit(crossDomainGasLimit));

        emit RelayInitiated(target, payload);
    }

    function initiateRelayBatch(
        address[] calldata targets,
        bytes[] calldata payloads,
        uint32 crossDomainGasLimit // If zero, uses default value in SystemSettings
    ) external onlyOwner {
        // First check that the length of the arguments match
        require(targets.length == payloads.length, "Argument length mismatch");

        IOwnerRelayOnOptimism ownerRelayOnOptimism;
        bytes memory messageData =
            abi.encodeWithSelector(ownerRelayOnOptimism.finalizeRelayBatch.selector, targets, payloads);

        _messenger().sendMessage(_ownerRelayOnOptimism(), messageData, _getCrossDomainGasLimit(crossDomainGasLimit));

        emit RelayBatchInitiated(targets, payloads);
    }

    /* ========== EVENTS ========== */

    event RelayInitiated(address target, bytes payload);
    event RelayBatchInitiated(address[] targets, bytes[] payloads);
}
