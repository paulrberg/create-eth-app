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
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {PoolConfigurator} from '../protocol/pool/PoolConfigurator.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title ReservesSetupHelper
 * @author Aave
 * @notice Deployment helper to setup the assets risk parameters at PoolConfigurator in batch.
 * @dev The ReservesSetupHelper is an Ownable contract, so only the deployer or future owners can call this contract.
 */
contract ReservesSetupHelper is Ownable {
  struct ConfigureReserveInput {
    address asset;
    uint256 baseLTV;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 reserveFactor;
    uint256 borrowCap;
    uint256 supplyCap;
    bool stableBorrowingEnabled;
    bool borrowingEnabled;
    bool flashLoanEnabled;
  }

  /**
   * @notice External function called by the owner account to setup the assets risk parameters in batch.
   * @dev The Pool or Risk admin must transfer the ownership to ReservesSetupHelper before calling this function
   * @param configurator The address of PoolConfigurator contract
   * @param inputParams An array of ConfigureReserveInput struct that contains the assets and their risk parameters
   */
  function configureReserves(
    PoolConfigurator configurator,
    ConfigureReserveInput[] calldata inputParams
  ) external onlyOwner {
    for (uint256 i = 0; i < inputParams.length; i++) {
      configurator.configureReserveAsCollateral(
        inputParams[i].asset,
        inputParams[i].baseLTV,
        inputParams[i].liquidationThreshold,
        inputParams[i].liquidationBonus
      );

      if (inputParams[i].borrowingEnabled) {
        configurator.setReserveBorrowing(inputParams[i].asset, true);

        configurator.setBorrowCap(inputParams[i].asset, inputParams[i].borrowCap);
        configurator.setReserveStableRateBorrowing(
          inputParams[i].asset,
          inputParams[i].stableBorrowingEnabled
        );
      }
      configurator.setReserveFlashLoaning(inputParams[i].asset, inputParams[i].flashLoanEnabled);
      configurator.setSupplyCap(inputParams[i].asset, inputParams[i].supplyCap);
      configurator.setReserveFactor(inputParams[i].asset, inputParams[i].reserveFactor);
    }
  }
}
