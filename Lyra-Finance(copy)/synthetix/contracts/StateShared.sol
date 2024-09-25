/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";

// Libraries
import "./AddressSetLib.sol";

/**
 * Based on `State.sol`. This contract adds the capability to have multiple associated contracts
 * enabled to access a state contract.
 *
 * Note: it changed the interface to manage the associated contracts from `setAssociatedContract`
 * to `addAssociatedContracts` or `removeAssociatedContracts` and the modifier is now plural
 */
// https://docs.synthetix.io/contracts/source/contracts/StateShared
contract StateShared is Owned {
    using AddressSetLib for AddressSetLib.AddressSet;

    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    AddressSetLib.AddressSet internal _associatedContracts;

    constructor(address[] memory associatedContracts) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        _addAssociatedContracts(associatedContracts);
    }

    /* ========== SETTERS ========== */

    function _addAssociatedContracts(address[] memory associatedContracts) internal {
        for (uint i = 0; i < associatedContracts.length; i++) {
            if (!_associatedContracts.contains(associatedContracts[i])) {
                _associatedContracts.add(associatedContracts[i]);
                emit AssociatedContractAdded(associatedContracts[i]);
            }
        }
    }

    // Add associated contracts
    function addAssociatedContracts(address[] calldata associatedContracts) external onlyOwner {
        _addAssociatedContracts(associatedContracts);
    }

    // Remove associated contracts
    function removeAssociatedContracts(address[] calldata associatedContracts) external onlyOwner {
        for (uint i = 0; i < associatedContracts.length; i++) {
            if (_associatedContracts.contains(associatedContracts[i])) {
                _associatedContracts.remove(associatedContracts[i]);
                emit AssociatedContractRemoved(associatedContracts[i]);
            }
        }
    }

    function associatedContracts() external view returns (address[] memory) {
        return _associatedContracts.getPage(0, _associatedContracts.elements.length);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContracts {
        require(_associatedContracts.contains(msg.sender), "Only an associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractAdded(address associatedContract);
    event AssociatedContractRemoved(address associatedContract);
}
