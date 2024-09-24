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
import "./BaseDebtMigrator.sol";

// Internal references
import "./interfaces/IDebtMigrator.sol";
import "./interfaces/ILiquidator.sol";
import "./interfaces/ILiquidatorRewards.sol";
import "./interfaces/ISynthetixBridgeToOptimism.sol";
import "./interfaces/ISynthetixDebtShare.sol";

contract DebtMigratorOnEthereum is BaseDebtMigrator {
    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_OVM_DEBT_MIGRATOR_ON_OPTIMISM = "ovm:DebtMigratorOnOptimism";
    bytes32 private constant CONTRACT_LIQUIDATOR = "Liquidator";
    bytes32 private constant CONTRACT_LIQUIDATOR_REWARDS = "LiquidatorRewards";
    bytes32 private constant CONTRACT_SYNTHETIX_BRIDGE_TO_OPTIMISM = "SynthetixBridgeToOptimism";
    bytes32 private constant CONTRACT_SYNTHETIX_DEBT_SHARE = "SynthetixDebtShare";

    function CONTRACT_NAME() public pure returns (bytes32) {
        return "DebtMigratorOnEthereum";
    }

    bool public initiationActive;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public BaseDebtMigrator(_owner, _resolver) {}

    /* ========== VIEWS ============ */

    function _debtMigratorOnOptimism() private view returns (address) {
        return requireAndGetAddress(CONTRACT_OVM_DEBT_MIGRATOR_ON_OPTIMISM);
    }

    function _liquidator() internal view returns (ILiquidator) {
        return ILiquidator(requireAndGetAddress(CONTRACT_LIQUIDATOR));
    }

    function _liquidatorRewards() internal view returns (ILiquidatorRewards) {
        return ILiquidatorRewards(requireAndGetAddress(CONTRACT_LIQUIDATOR_REWARDS));
    }

    function _synthetixBridgeToOptimism() internal view returns (ISynthetixBridgeToOptimism) {
        return ISynthetixBridgeToOptimism(requireAndGetAddress(CONTRACT_SYNTHETIX_BRIDGE_TO_OPTIMISM));
    }

    function _synthetixDebtShare() internal view returns (ISynthetixDebtShare) {
        return ISynthetixDebtShare(requireAndGetAddress(CONTRACT_SYNTHETIX_DEBT_SHARE));
    }

    function _initiatingActive() internal view {
        require(initiationActive, "Initiation deactivated");
    }

    function _getCrossDomainGasLimit(uint32 crossDomainGasLimit) private view returns (uint32) {
        // Use specified crossDomainGasLimit if specified value is not zero.
        // otherwise use the default in SystemSettings.
        return
            crossDomainGasLimit != 0
                ? crossDomainGasLimit
                : uint32(getCrossDomainMessageGasLimit(CrossDomainMessageGasLimits.Relay));
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseDebtMigrator.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](5);
        newAddresses[0] = CONTRACT_OVM_DEBT_MIGRATOR_ON_OPTIMISM;
        newAddresses[1] = CONTRACT_LIQUIDATOR;
        newAddresses[2] = CONTRACT_LIQUIDATOR_REWARDS;
        newAddresses[3] = CONTRACT_SYNTHETIX_BRIDGE_TO_OPTIMISM;
        newAddresses[4] = CONTRACT_SYNTHETIX_DEBT_SHARE;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    /* ========== MUTATIVE ========== */

    // Ideally, the account should call vest on their escrow before invoking the debt migration to L2.
    function migrateDebt(address account) public requireInitiationActive {
        require(msg.sender == account, "Must be the account owner");
        _migrateDebt(account);
    }

    function _migrateDebt(address _account) internal {
        // Require the account to not be flagged or open for liquidation
        require(!_liquidator().isLiquidationOpen(_account, false), "Cannot migrate if open for liquidation");

        // Important: this has to happen before any updates to user's debt shares
        _liquidatorRewards().getReward(_account);

        // First, remove all debt shares on L1
        ISynthetixDebtShare sds = _synthetixDebtShare();
        uint totalDebtShares = sds.balanceOf(_account);
        require(totalDebtShares > 0, "No debt to migrate");

        // Increment the in-flight debt counter by their SDS balance
        _incrementDebtTransferCounter(DEBT_TRANSFER_SENT, totalDebtShares);
        _issuer().modifyDebtSharesForMigration(_account, totalDebtShares);

        // Deposit all of the liquid & revoked escrowed SNX to the migrator on L2
        (uint totalEscrowRevoked, uint totalLiquidBalance) =
            ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX)).migrateAccountBalances(_account);
        uint totalAmountToDeposit = totalLiquidBalance.add(totalEscrowRevoked);

        require(totalAmountToDeposit > 0, "Cannot migrate zero balances");
        require(
            resolver.getAddress(CONTRACT_OVM_DEBT_MIGRATOR_ON_OPTIMISM) != address(0),
            "Debt Migrator On Optimism not set"
        );

        _synthetixERC20().approve(address(_synthetixBridgeToOptimism()), totalAmountToDeposit);
        _synthetixBridgeToOptimism().depositTo(_debtMigratorOnOptimism(), totalAmountToDeposit);

        // Require all zeroed balances
        require(_synthetixDebtShare().balanceOf(_account) == 0, "Debt share balance is not zero");
        require(_synthetixERC20().balanceOf(_account) == 0, "SNX balance is not zero");
        require(_rewardEscrowV2().balanceOf(_account) == 0, "Escrow balanace is not zero");
        require(_liquidatorRewards().earned(_account) == 0, "Earned balance is not zero");

        // Create the data payloads to be relayed on L2
        IIssuer issuer;
        bytes memory _debtPayload =
            abi.encodeWithSelector(issuer.modifyDebtSharesForMigration.selector, _account, totalDebtShares);

        // Send a message with the debt & escrow payloads to L2 to finalize the migration
        IDebtMigrator debtMigratorOnOptimism;
        bytes memory messageData =
            abi.encodeWithSelector(
                debtMigratorOnOptimism.finalizeDebtMigration.selector,
                _account,
                totalDebtShares,
                totalEscrowRevoked,
                totalLiquidBalance,
                _debtPayload
            );
        _messenger().sendMessage(_debtMigratorOnOptimism(), messageData, _getCrossDomainGasLimit(0)); // passing zero will use the system setting default

        emit MigrationInitiated(_account, totalDebtShares, totalEscrowRevoked, totalLiquidBalance);
    }

    /* ========= RESTRICTED ========= */

    function suspendInitiation() external onlyOwner {
        require(initiationActive, "Initiation suspended");
        initiationActive = false;
        emit InitiationSuspended();
    }

    function resumeInitiation() external onlyOwner {
        require(!initiationActive, "Initiation not suspended");
        initiationActive = true;
        emit InitiationResumed();
    }

    /* ========= MODIFIERS ========= */

    modifier requireInitiationActive() {
        _initiatingActive();
        _;
    }

    /* ========== EVENTS ========== */

    event InitiationSuspended();

    event InitiationResumed();

    event MigrationInitiated(
        address indexed account,
        uint totalDebtSharesMigrated,
        uint totalEscrowMigrated,
        uint totalLiquidBalanceMigrated
    );
}
