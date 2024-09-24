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
import "./interfaces/IDebtMigrator.sol";

contract DebtMigratorOnOptimism is BaseDebtMigrator, IDebtMigrator {
    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_BASE_DEBT_MIGRATOR_ON_ETHEREUM = "base:DebtMigratorOnEthereum";

    function CONTRACT_NAME() public pure returns (bytes32) {
        return "DebtMigratorOnOptimism";
    }

    /* ========== CONSTRUCTOR ============ */

    constructor(address _owner, address _resolver) public BaseDebtMigrator(_owner, _resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseDebtMigrator.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_BASE_DEBT_MIGRATOR_ON_ETHEREUM;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _debtMigratorOnEthereum() private view returns (address) {
        return requireAndGetAddress(CONTRACT_BASE_DEBT_MIGRATOR_ON_ETHEREUM);
    }

    function _counterpart() internal view returns (address) {
        return _debtMigratorOnEthereum();
    }

    /* ========== MUTATIVE ============ */

    function _finalizeDebt(bytes memory _debtPayload) private {
        address target = address(_issuer()); // target is the Issuer contract on Optimism.

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = target.call(_debtPayload);
        require(success, string(abi.encode("finalize debt call failed:", result)));
    }

    function _finalizeEscrow(address account, uint escrowMigrated) private {
        uint numEntries = 10;
        uint duration = 8 weeks;

        // Split up the full amount of migrated escrow into ten chunks.
        uint amountPerEntry = escrowMigrated.multiplyDecimal(1e17);

        // Make sure to approve the creation of the escrow entries.
        _synthetixERC20().approve(address(_rewardEscrowV2()), escrowMigrated);

        // Create ten distinct entries that vest each month for a year. First entry vests in 8 weeks.
        uint amountEscrowed = 0;
        for (uint i = 0; i < numEntries; i++) {
            if (i == numEntries - 1) {
                // Use the remaining amount of escrow for the last entry to avoid rounding issues.
                uint remaining = escrowMigrated.sub(amountEscrowed);
                _rewardEscrowV2().createEscrowEntry(account, remaining, duration);
            } else {
                _rewardEscrowV2().createEscrowEntry(account, amountPerEntry, duration);
            }

            duration += 4 weeks;
            amountEscrowed += amountPerEntry;
        }
    }

    /* ========== MODIFIERS ============ */

    function _onlyAllowFromCounterpart() internal view {
        iAbs_BaseCrossDomainMessenger messenger = _messenger();
        require(msg.sender == address(messenger), "Sender is not the messenger");
        require(messenger.xDomainMessageSender() == _counterpart(), "L1 sender is not the debt migrator");
    }

    modifier onlyCounterpart() {
        _onlyAllowFromCounterpart();
        _;
    }

    /* ========== EXTERNAL ========== */

    function finalizeDebtMigration(
        address account,
        uint debtSharesMigrated,
        uint escrowMigrated,
        uint liquidSnxMigrated,
        bytes calldata debtPayload
    ) external onlyCounterpart {
        _incrementDebtTransferCounter(DEBT_TRANSFER_RECV, debtSharesMigrated);
        _finalizeDebt(debtPayload);

        if (escrowMigrated > 0) {
            _finalizeEscrow(account, escrowMigrated);
        }

        if (liquidSnxMigrated > 0) {
            _synthetixERC20().transfer(account, liquidSnxMigrated);
        }

        emit MigrationFinalized(account, debtSharesMigrated, escrowMigrated, liquidSnxMigrated);
    }

    /* ========== EVENTS ========== */

    event MigrationFinalized(
        address indexed account,
        uint totalDebtSharesMigrated,
        uint totalEscrowMigrated,
        uint totalLiquidBalanceMigrated
    );
}
