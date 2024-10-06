/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/FlashloanAttacker?utm=code
  */
  
  // SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPool} from '../../interfaces/IPool.sol';

/**
 * @title IFlashLoanSimpleReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 */
interface IFlashLoanSimpleReceiver {
  /**
   * @notice Executes an operation after receiving the flash-borrowed asset
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param asset The address of the flash-borrowed asset
   * @param amount The amount of the flash-borrowed asset
   * @param premium The fee of the flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  function POOL() external view returns (IPool);
}
