/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ImmutableCreate2FactoryInterface
 * @author 0age
 * @notice This contract provides a safeCreate2 function that takes a salt value
 *         and a block of initialization code as arguments and passes them into
 *         inline assembly. The contract prevents redeploys by maintaining a
 *         mapping of all contracts that have already been deployed, and
 *         prevents frontrunning or other collisions by requiring that the first
 *         20 bytes of the salt are equal to the address of the caller (this can
 *         be bypassed by setting the first 20 bytes to the null address). There
 *         is also a view function that computes the address of the contract
 *         that will be created when submitting a given salt or nonce along with
 *         a given block of initialization code.
 */
interface ImmutableCreate2FactoryInterface {
    /**
     * @dev Create a contract using CREATE2 by submitting a given salt or nonce
     *      along with the initialization code for the contract. Note that the
     *      first 20 bytes of the salt must match those of the calling address,
     *      which prevents contract creation events from being submitted by
     *      unintended parties.
     *
     * @param salt               The nonce that will be passed into the CREATE2
     *                           call.
     * @param initializationCode The initialization code that will be passed
     *                           into the CREATE2 call.
     *
     * @return deploymentAddress Address of the contract that will be created.
     */
    function safeCreate2(
        bytes32 salt,
        bytes calldata initializationCode
    ) external payable returns (address deploymentAddress);

    /**
     * @dev Compute the address of the contract that will be created when
     *      submitting a given salt or nonce to the contract along with the
     *      contract's initialization code. The CREATE2 address is computed in
     *      accordance with EIP-1014, and adheres to the formula therein of
     *      `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]`
     *      when performing the computation. The computed address is then
     *      checked for any existing contract code - if so, the null address
     *      will be returned instead.
     *
     * @param salt     The nonce passed into the CREATE2 address calculation.
     * @param initCode The contract initialization code to be used that will be
     *                 passed into the CREATE2 address calculation.
     *
     * @return deploymentAddress Address of the contract that will be created,
     *                           or the null address if a contract already
     *                           exists at that address.
     */
    function findCreate2Address(
        bytes32 salt,
        bytes calldata initCode
    ) external view returns (address deploymentAddress);

    /**
     * @dev Compute the address of the contract that will be created when
     *      submitting a given salt or nonce to the contract along with the
     *      keccak256 hash of the contract's initialization code. The CREATE2
     *      address is computed in accordance with EIP-1014, and adheres to the
     *      `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]`
     *      formula when performing the computation. The computed address is
     *      then checked for any existing contract code - if so, the null
     *      address will be returned instead.
     *
     * @param salt         The nonce passed into the CREATE2 address
     *                     calculation.
     * @param initCodeHash The keccak256 hash of the initialization code that
     *                     will be passed into the CREATE2 address calculation.
     *
     * @return deploymentAddress Address of the contract that will be created,
     *                           or the null address if a contract already
     *                           exists at that address.
     */
    function findCreate2AddressViaHash(
        bytes32 salt,
        bytes32 initCodeHash
    ) external view returns (address deploymentAddress);

    /**
     * @dev Determine if a contract has already been deployed by the factory to
     *      a given address.
     *
     * @param deploymentAddress The contract address to check.
     *
     * @return True if the contract has been deployed, false otherwise.
     */
    function hasBeenDeployed(
        address deploymentAddress
    ) external view returns (bool);
}