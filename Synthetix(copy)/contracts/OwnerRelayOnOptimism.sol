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
import "./MixinResolver.sol";
import "./TemporarilyOwned.sol";
import "./interfaces/IOwnerRelayOnOptimism.sol";

// Internal references
import "Synthetix/@eth-optimism/contracts/iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

contract OwnerRelayOnOptimism is MixinResolver, TemporarilyOwned, IOwnerRelayOnOptimism {
    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_EXT_MESSENGER = "ext:Messenger";
    bytes32 private constant CONTRACT_BASE_OWNER_RELAY_ON_ETHEREUM = "base:OwnerRelayOnEthereum";

    /* ========== CONSTRUCTOR ============ */

    constructor(
        address _resolver,
        address _temporaryOwner,
        uint _ownershipDuration
    ) public MixinResolver(_resolver) TemporarilyOwned(_temporaryOwner, _ownershipDuration) {}

    /* ========== INTERNALS ============ */

    function _messenger() private view returns (iAbs_BaseCrossDomainMessenger) {
        return iAbs_BaseCrossDomainMessenger(requireAndGetAddress(CONTRACT_EXT_MESSENGER));
    }

    function _ownerRelayOnEthereum() private view returns (address) {
        return requireAndGetAddress(CONTRACT_BASE_OWNER_RELAY_ON_ETHEREUM);
    }

    function _relayCall(address target, bytes memory payload) private {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = target.call(payload);

        require(success, string(abi.encode("xChain call failed:", result)));
    }

    function _onlyAllowMessengerAndL1Relayer() internal view {
        iAbs_BaseCrossDomainMessenger messenger = _messenger();

        require(msg.sender == address(messenger), "Sender is not the messenger");
        require(messenger.xDomainMessageSender() == _ownerRelayOnEthereum(), "L1 sender is not the owner relay");
    }

    modifier onlyMessengerAndL1Relayer() {
        _onlyAllowMessengerAndL1Relayer();
        _;
    }

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](2);
        addresses[0] = CONTRACT_EXT_MESSENGER;
        addresses[1] = CONTRACT_BASE_OWNER_RELAY_ON_ETHEREUM;
    }

    /* ========== EXTERNAL ========== */

    function directRelay(address target, bytes calldata payload) external onlyTemporaryOwner {
        _relayCall(target, payload);

        emit DirectRelay(target, payload);
    }

    function finalizeRelay(address target, bytes calldata payload) external onlyMessengerAndL1Relayer {
        _relayCall(target, payload);

        emit RelayFinalized(target, payload);
    }

    function finalizeRelayBatch(address[] calldata targets, bytes[] calldata payloads) external onlyMessengerAndL1Relayer {
        for (uint256 i = 0; i < targets.length; i++) {
            _relayCall(targets[i], payloads[i]);
        }

        emit RelayBatchFinalized(targets, payloads);
    }

    /* ========== EVENTS ========== */

    event DirectRelay(address target, bytes payload);
    event RelayFinalized(address target, bytes payload);
    event RelayBatchFinalized(address[] targets, bytes[] payloads);
}
