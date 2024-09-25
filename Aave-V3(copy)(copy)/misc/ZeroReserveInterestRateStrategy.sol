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
pragma solidity ^0.8.0;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {IDefaultInterestRateStrategy} from '../interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';

/**
 * @title ZeroReserveInterestRateStrategy contract
 * @author Aave
 * @notice Interest Rate Strategy contract, with all parameters zeroed.
 * @dev It returns zero liquidity and borrow rate.
 */
contract ZeroReserveInterestRateStrategy is IDefaultInterestRateStrategy {
  /// @inheritdoc IDefaultInterestRateStrategy
  uint256 public constant OPTIMAL_USAGE_RATIO = 0;

  /// @inheritdoc IDefaultInterestRateStrategy
  uint256 public constant OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = 0;

  /// @inheritdoc IDefaultInterestRateStrategy
  uint256 public constant MAX_EXCESS_USAGE_RATIO = 0;

  /// @inheritdoc IDefaultInterestRateStrategy
  uint256 public constant MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = 0;

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  // Base variable borrow rate when usage rate = 0. Expressed in ray
  uint256 internal constant _baseVariableBorrowRate = 0;

  // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal constant _variableRateSlope1 = 0;

  // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal constant _variableRateSlope2 = 0;

  // Slope of the stable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal constant _stableRateSlope1 = 0;

  // Slope of the stable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal constant _stableRateSlope2 = 0;

  // Premium on top of `_variableRateSlope1` for base stable borrowing rate
  uint256 internal constant _baseStableRateOffset = 0;

  // Additional premium applied to stable rate when stable debt surpass `OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO`
  uint256 internal constant _stableRateExcessOffset = 0;

  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getVariableRateSlope1() external pure returns (uint256) {
    return _variableRateSlope1;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getVariableRateSlope2() external pure returns (uint256) {
    return _variableRateSlope2;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getStableRateSlope1() external pure returns (uint256) {
    return _stableRateSlope1;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getStableRateSlope2() external pure returns (uint256) {
    return _stableRateSlope2;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getStableRateExcessOffset() external pure returns (uint256) {
    return _stableRateExcessOffset;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getBaseStableBorrowRate() public pure returns (uint256) {
    return _variableRateSlope1 + _baseStableRateOffset;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getBaseVariableBorrowRate() external pure override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  /// @inheritdoc IDefaultInterestRateStrategy
  function getMaxVariableBorrowRate() external pure override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory
  ) public pure override returns (uint256, uint256, uint256) {
    return (0, 0, 0);
  }
}
