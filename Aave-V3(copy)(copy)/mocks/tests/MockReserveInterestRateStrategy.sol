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

import {IDefaultInterestRateStrategy} from '../../interfaces/IDefaultInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {WadRayMath} from '../../protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

contract MockReserveInterestRateStrategy is IDefaultInterestRateStrategy {
  uint256 public immutable OPTIMAL_USAGE_RATIO;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
  uint256 internal immutable _baseVariableBorrowRate;
  uint256 internal immutable _variableRateSlope1;
  uint256 internal immutable _variableRateSlope2;
  uint256 internal immutable _stableRateSlope1;
  uint256 internal immutable _stableRateSlope2;

  // Not used, only defined for interface compatibility
  uint256 public constant MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = 0;
  uint256 public constant MAX_EXCESS_USAGE_RATIO = 0;
  uint256 public constant OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = 0;

  uint256 internal _liquidityRate;
  uint256 internal _stableBorrowRate;
  uint256 internal _variableBorrowRate;

  constructor(
    IPoolAddressesProvider provider,
    uint256 optimalUsageRatio,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2,
    uint256 stableRateSlope1,
    uint256 stableRateSlope2
  ) {
    OPTIMAL_USAGE_RATIO = optimalUsageRatio;
    ADDRESSES_PROVIDER = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
    _stableRateSlope1 = stableRateSlope1;
    _stableRateSlope2 = stableRateSlope2;
  }

  function setLiquidityRate(uint256 liquidityRate) public {
    _liquidityRate = liquidityRate;
  }

  function setStableBorrowRate(uint256 stableBorrowRate) public {
    _stableBorrowRate = stableBorrowRate;
  }

  function setVariableBorrowRate(uint256 variableBorrowRate) public {
    _variableBorrowRate = variableBorrowRate;
  }

  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory
  )
    external
    view
    override
    returns (uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate)
  {
    return (_liquidityRate, _stableBorrowRate, _variableBorrowRate);
  }

  function getVariableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function getVariableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function getStableRateSlope1() external view returns (uint256) {
    return _stableRateSlope1;
  }

  function getStableRateSlope2() external view returns (uint256) {
    return _stableRateSlope2;
  }

  function getBaseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }

  // Not used, only defined for interface compatibility
  function getBaseStableBorrowRate() external pure override returns (uint256) {
    return 0;
  }

  // Not used, only defined for interface compatibility
  function getStableRateExcessOffset() external pure override returns (uint256) {
    return 0;
  }
}
