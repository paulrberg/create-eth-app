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
import "./BaseSynthetixBridge.sol";
import "./interfaces/ISynthetixBridgeToBase.sol";
import "Synthetix/@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L2DepositedToken.sol";

// Internal references
import "Synthetix/@eth-optimism/contracts/iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";

contract SynthetixBridgeToBase is BaseSynthetixBridge, ISynthetixBridgeToBase, iOVM_L2DepositedToken {
    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_BASE_SYNTHETIXBRIDGETOOPTIMISM = "base:SynthetixBridgeToOptimism";

    function CONTRACT_NAME() public pure returns (bytes32) {
        return "SynthetixBridgeToBase";
    }

    // ========== CONSTRUCTOR ==========

    constructor(address _owner, address _resolver) public BaseSynthetixBridge(_owner, _resolver) {}

    // ========== INTERNALS ============

    function synthetixBridgeToOptimism() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_BASE_SYNTHETIXBRIDGETOOPTIMISM);
    }

    function counterpart() internal view returns (address) {
        return synthetixBridgeToOptimism();
    }

    // ========== VIEWS ==========

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseSynthetixBridge.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_BASE_SYNTHETIXBRIDGETOOPTIMISM;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    // ========== PUBLIC FUNCTIONS =========

    // invoked by user on L2
    function withdraw(uint amount) external requireInitiationActive {
        _initiateWithdraw(msg.sender, amount);
    }

    function withdrawTo(address to, uint amount) external requireInitiationActive {
        _initiateWithdraw(to, amount);
    }

    function _initiateWithdraw(address to, uint amount) private {
        require(synthetix().transferableSynthetix(msg.sender) >= amount, "Not enough transferable SNX");

        // instruct L2 Synthetix to burn this supply
        synthetix().burnSecondary(msg.sender, amount);

        // create message payload for L1
        iOVM_L1TokenGateway bridgeToOptimism;
        bytes memory messageData = abi.encodeWithSelector(bridgeToOptimism.finalizeWithdrawal.selector, to, amount);

        // relay the message to Bridge on L1 via L2 Messenger
        messenger().sendMessage(
            synthetixBridgeToOptimism(),
            messageData,
            uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Withdrawal))
        );

        emit iOVM_L2DepositedToken.WithdrawalInitiated(msg.sender, to, amount);
    }

    // ========= RESTRICTED FUNCTIONS ==============

    function finalizeEscrowMigration(
        address account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] calldata vestingEntries
    ) external onlyCounterpart {
        IRewardEscrowV2 rewardEscrow = rewardEscrowV2();
        // First, mint the escrowed SNX that are being migrated
        synthetix().mintSecondary(address(rewardEscrow), escrowedAmount);
        rewardEscrow.importVestingEntries(account, escrowedAmount, vestingEntries);

        emit ImportedVestingEntries(account, escrowedAmount, vestingEntries);
    }

    // invoked by Messenger on L2
    function finalizeDeposit(address to, uint256 amount) external onlyCounterpart {
        // now tell Synthetix to mint these tokens, deposited in L1, into the specified account for L2
        synthetix().mintSecondary(to, amount);

        emit iOVM_L2DepositedToken.DepositFinalized(to, amount);
    }

    // invoked by Messenger on L2
    function finalizeRewardDeposit(address from, uint256 amount) external onlyCounterpart {
        // now tell Synthetix to mint these tokens, deposited in L1, into reward escrow on L2
        synthetix().mintSecondaryRewards(amount);

        emit RewardDepositFinalized(from, amount);
    }

    // invoked by Messenger on L2
    function finalizeFeePeriodClose(uint256 snxBackedAmount, uint256 totalDebtShares) external onlyCounterpart {
        // now tell Synthetix to mint these tokens, deposited in L1, into reward escrow on L2
        feePool().closeSecondary(snxBackedAmount, totalDebtShares);

        emit FeePeriodCloseFinalized(snxBackedAmount, totalDebtShares);
    }

    // ========== EVENTS ==========
    event ImportedVestingEntries(
        address indexed account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] vestingEntries
    );

    event RewardDepositFinalized(address from, uint256 amount);
    event FeePeriodCloseFinalized(uint snxBackedAmount, uint totalDebtShares);
}
