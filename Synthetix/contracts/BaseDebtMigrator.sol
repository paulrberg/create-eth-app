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
import "./interfaces/IBaseSynthetixBridge.sol";

// Libraries
import "./Math.sol";
import "./SafeDecimalMath.sol";
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/token/ERC20/SafeERC20.sol";

// Internal references
import "./interfaces/ISynthetix.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/IIssuer.sol";
import "Synthetix/@eth-optimism/contracts/iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

contract BaseDebtMigrator is Owned, MixinSystemSettings {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SafeERC20 for IERC20;

    // have to define this function like this here because contract name is required for FlexibleStorage
    function CONTRACT_NAME() public pure returns (bytes32);

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_EXT_MESSENGER = "ext:Messenger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 internal constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrowV2";

    bytes32 private constant DEBT_TRANSFER_NAMESPACE = "DebtTransfer";
    bytes32 internal constant DEBT_TRANSFER_SENT = "Sent";
    bytes32 internal constant DEBT_TRANSFER_RECV = "Recv";

    bytes32 internal constant sUSD = "sUSD";
    bytes32 internal constant SDS = "SDS";

    /* ========== CONSTRUCTOR ========= */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function _issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function _messenger() internal view returns (iAbs_BaseCrossDomainMessenger) {
        return iAbs_BaseCrossDomainMessenger(requireAndGetAddress(CONTRACT_EXT_MESSENGER));
    }

    function _rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW));
    }

    function _synthetixERC20() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](4);
        newAddresses[0] = CONTRACT_EXT_MESSENGER;
        newAddresses[1] = CONTRACT_REWARDESCROW;
        newAddresses[2] = CONTRACT_ISSUER;
        newAddresses[3] = CONTRACT_SYNTHETIX;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ======== INTERNALS ======== */

    function debtTransferSent() external view returns (uint) {
        bytes32 debtSharesKey = keccak256(abi.encodePacked(DEBT_TRANSFER_NAMESPACE, DEBT_TRANSFER_SENT, SDS));
        uint currentDebtShares = flexibleStorage().getUIntValue(CONTRACT_NAME(), debtSharesKey);
        return currentDebtShares;
    }

    function debtTransferReceived() external view returns (uint) {
        bytes32 debtSharesKey = keccak256(abi.encodePacked(DEBT_TRANSFER_NAMESPACE, DEBT_TRANSFER_RECV, SDS));
        uint currentDebtShares = flexibleStorage().getUIntValue(CONTRACT_NAME(), debtSharesKey);
        return currentDebtShares;
    }

    function _incrementDebtTransferCounter(bytes32 group, uint debtShares) internal {
        bytes32 debtSharesKey = keccak256(abi.encodePacked(DEBT_TRANSFER_NAMESPACE, group, SDS));
        uint currentDebtShares = flexibleStorage().getUIntValue(CONTRACT_NAME(), debtSharesKey);
        flexibleStorage().setUIntValue(CONTRACT_NAME(), debtSharesKey, currentDebtShares.add(debtShares));
    }
}
