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

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IStableDebtToken} from '../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../interfaces/IVariableDebtToken.sol';
import {IPool} from '../interfaces/IPool.sol';
import {IPoolDataProvider} from '../interfaces/IPoolDataProvider.sol';

/**
 * @title AaveProtocolDataProvider
 * @author Aave
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract AaveProtocolDataProvider is IPoolDataProvider {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using WadRayMath for uint256;

  address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @inheritdoc IPoolDataProvider
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  /**
   * @notice Constructor
   * @param addressesProvider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider addressesProvider) {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  /// @inheritdoc IPoolDataProvider
  function getAllReservesTokens() external view override returns (TokenData[] memory) {
    IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory reservesTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      if (reserves[i] == MKR) {
        reservesTokens[i] = TokenData({symbol: 'MKR', tokenAddress: reserves[i]});
        continue;
      }
      if (reserves[i] == ETH) {
        reservesTokens[i] = TokenData({symbol: 'ETH', tokenAddress: reserves[i]});
        continue;
      }
      reservesTokens[i] = TokenData({
        symbol: IERC20Detailed(reserves[i]).symbol(),
        tokenAddress: reserves[i]
      });
    }
    return reservesTokens;
  }

  /// @inheritdoc IPoolDataProvider
  function getAllATokens() external view override returns (TokenData[] memory) {
    IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory aTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
      aTokens[i] = TokenData({
        symbol: IERC20Detailed(reserveData.aTokenAddress).symbol(),
        tokenAddress: reserveData.aTokenAddress
      });
    }
    return aTokens;
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveConfigurationData(
    address asset
  )
    external
    view
    override
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration = IPool(ADDRESSES_PROVIDER.getPool())
      .getConfiguration(asset);

    (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor, ) = configuration
      .getParams();

    (isActive, isFrozen, borrowingEnabled, stableBorrowRateEnabled, ) = configuration.getFlags();

    usageAsCollateralEnabled = liquidationThreshold != 0;
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveEModeCategory(address asset) external view override returns (uint256) {
    DataTypes.ReserveConfigurationMap memory configuration = IPool(ADDRESSES_PROVIDER.getPool())
      .getConfiguration(asset);
    return configuration.getEModeCategory();
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveCaps(
    address asset
  ) external view override returns (uint256 borrowCap, uint256 supplyCap) {
    (borrowCap, supplyCap) = IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getCaps();
  }

  /// @inheritdoc IPoolDataProvider
  function getPaused(address asset) external view override returns (bool isPaused) {
    (, , , , isPaused) = IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getFlags();
  }

  /// @inheritdoc IPoolDataProvider
  function getSiloedBorrowing(address asset) external view override returns (bool) {
    return IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getSiloedBorrowing();
  }

  /// @inheritdoc IPoolDataProvider
  function getLiquidationProtocolFee(address asset) external view override returns (uint256) {
    return IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getLiquidationProtocolFee();
  }

  /// @inheritdoc IPoolDataProvider
  function getUnbackedMintCap(address asset) external view override returns (uint256) {
    return IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getUnbackedMintCap();
  }

  /// @inheritdoc IPoolDataProvider
  function getDebtCeiling(address asset) external view override returns (uint256) {
    return IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getDebtCeiling();
  }

  /// @inheritdoc IPoolDataProvider
  function getDebtCeilingDecimals() external pure override returns (uint256) {
    return ReserveConfiguration.DEBT_CEILING_DECIMALS;
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveData(
    address asset
  )
    external
    view
    override
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    return (
      reserve.unbacked,
      reserve.accruedToTreasury,
      IERC20Detailed(reserve.aTokenAddress).totalSupply(),
      IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply(),
      IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply(),
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      reserve.currentStableBorrowRate,
      IStableDebtToken(reserve.stableDebtTokenAddress).getAverageStableRate(),
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  /// @inheritdoc IPoolDataProvider
  function getATokenTotalSupply(address asset) external view override returns (uint256) {
    DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );
    return IERC20Detailed(reserve.aTokenAddress).totalSupply();
  }

  /// @inheritdoc IPoolDataProvider
  function getTotalDebt(address asset) external view override returns (uint256) {
    DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );
    return
      IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply() +
      IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply();
  }

  /// @inheritdoc IPoolDataProvider
  function getUserReserveData(
    address asset,
    address user
  )
    external
    view
    override
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    )
  {
    DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    DataTypes.UserConfigurationMap memory userConfig = IPool(ADDRESSES_PROVIDER.getPool())
      .getUserConfiguration(user);

    currentATokenBalance = IERC20Detailed(reserve.aTokenAddress).balanceOf(user);
    currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress).balanceOf(user);
    currentStableDebt = IERC20Detailed(reserve.stableDebtTokenAddress).balanceOf(user);
    principalStableDebt = IStableDebtToken(reserve.stableDebtTokenAddress).principalBalanceOf(user);
    scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
    stableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress).getUserStableRate(user);
    stableRateLastUpdated = IStableDebtToken(reserve.stableDebtTokenAddress).getUserLastUpdated(
      user
    );
    usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
  }

  /// @inheritdoc IPoolDataProvider
  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    override
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    )
  {
    DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    return (
      reserve.aTokenAddress,
      reserve.stableDebtTokenAddress,
      reserve.variableDebtTokenAddress
    );
  }

  /// @inheritdoc IPoolDataProvider
  function getInterestRateStrategyAddress(
    address asset
  ) external view override returns (address irStrategyAddress) {
    DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    return (reserve.interestRateStrategyAddress);
  }

  /// @inheritdoc IPoolDataProvider
  function getFlashLoanEnabled(address asset) external view override returns (bool) {
    DataTypes.ReserveConfigurationMap memory configuration = IPool(ADDRESSES_PROVIDER.getPool())
      .getConfiguration(asset);

    return configuration.getFlashLoanEnabled();
  }
}
