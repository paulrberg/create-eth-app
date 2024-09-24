/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Aave-V3?utm=code
  */
  
  // SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProviderRegistry
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool Addresses Provider Registry.
 */
interface IPoolAddressesProviderRegistry {
  /**
   * @dev Emitted when a new AddressesProvider is registered.
   * @param addressesProvider The address of the registered PoolAddressesProvider
   * @param id The id of the registered PoolAddressesProvider
   */
  event AddressesProviderRegistered(address indexed addressesProvider, uint256 indexed id);

  /**
   * @dev Emitted when an AddressesProvider is unregistered.
   * @param addressesProvider The address of the unregistered PoolAddressesProvider
   * @param id The id of the unregistered PoolAddressesProvider
   */
  event AddressesProviderUnregistered(address indexed addressesProvider, uint256 indexed id);

  /**
   * @notice Returns the list of registered addresses providers
   * @return The list of addresses providers
   */
  function getAddressesProvidersList() external view returns (address[] memory);

  /**
   * @notice Returns the id of a registered PoolAddressesProvider
   * @param addressesProvider The address of the PoolAddressesProvider
   * @return The id of the PoolAddressesProvider or 0 if is not registered
   */
  function getAddressesProviderIdByAddress(
    address addressesProvider
  ) external view returns (uint256);

  /**
   * @notice Returns the address of a registered PoolAddressesProvider
   * @param id The id of the market
   * @return The address of the PoolAddressesProvider with the given id or zero address if it is not registered
   */
  function getAddressesProviderAddressById(uint256 id) external view returns (address);

  /**
   * @notice Registers an addresses provider
   * @dev The PoolAddressesProvider must not already be registered in the registry
   * @dev The id must not be used by an already registered PoolAddressesProvider
   * @param provider The address of the new PoolAddressesProvider
   * @param id The id for the new PoolAddressesProvider, referring to the market it belongs to
   */
  function registerAddressesProvider(address provider, uint256 id) external;

  /**
   * @notice Removes an addresses provider from the list of registered addresses providers
   * @param provider The PoolAddressesProvider address
   */
  function unregisterAddressesProvider(address provider) external;
}
