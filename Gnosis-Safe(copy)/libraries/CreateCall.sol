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

/**
 * @title Create Call - Allows to use the different create opcodes to deploy a contract.
 * @author Richard Meissner - @rmeissner
 * @notice This contract provides functions for deploying a new contract using the create and create2 opcodes.
 */
contract CreateCall {
    /// @notice Emitted when a new contract is created
    event ContractCreation(address indexed newContract);

    /**
     * @notice Deploys a new contract using the create2 opcode.
     * @param value The value in wei to be sent with the contract creation.
     * @param deploymentData The initialisation code of the contract to be created.
     * @param salt The salt value to use for the contract creation.
     * @return newContract The address of the newly created contract.
     */
    function performCreate2(uint256 value, bytes memory deploymentData, bytes32 salt) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }

    /**
     * @notice Deploys a new contract using the create opcode.
     * @param value The value in wei to be sent with the contract creation.
     * @param deploymentData The initialisation code of the contract to be created.
     * @return newContract The address of the newly created contract.
     */
    function performCreate(uint256 value, bytes memory deploymentData) public returns (address newContract) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        require(newContract != address(0), "Could not deploy contract");
        emit ContractCreation(newContract);
    }
}
