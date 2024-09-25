/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Gnosis-Safe?utm=code
  */
  
  // SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../../common/Enum.sol";
import "../../base/GuardManager.sol";
import "../../Safe.sol";

/**
 * @title ReentrancyTransactionGuard - Prevents reentrancy into the transaction execution function.
 * @author Richard Meissner - @rmeissner
 */
contract ReentrancyTransactionGuard is BaseGuard {
    bytes32 internal constant GUARD_STORAGE_SLOT = keccak256("reentrancy_guard.guard.struct");

    struct GuardValue {
        bool active;
    }

    // solhint-disable-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    /**
     * @notice Returns the guard value for the current context.
     * @dev The guard value is stored in a slot that is unique to the contract instance and the function in which it is called.
     * @return guard The guard value.
     */
    function getGuard() internal pure returns (GuardValue storage guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard.slot := slot
        }
    }

    /**
     * @notice Called by the Safe contract before a transaction is executed.
     * @dev Reverts if reentrancy is detected.
     */
    function checkTransaction(
        address,
        uint256,
        bytes memory,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        // solhint-disable-next-line no-unused-vars
        address payable,
        bytes memory,
        address
    ) external override {
        GuardValue storage guard = getGuard();
        require(!guard.active, "Reentrancy detected");
        guard.active = true;
    }

    /**
     * @notice Called by the Safe contract after a transaction is executed.
     * @dev Resets the guard value.
     */
    function checkAfterExecution(bytes32, bool) external override {
        getGuard().active = false;
    }
}
