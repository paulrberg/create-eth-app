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

/**
 * @title CalldataLogic library
 * @author Aave
 * @notice Library to decode calldata, used to optimize calldata size in L2Pool for transaction cost reduction
 */
library CalldataLogic {
  /**
   * @notice Decodes compressed supply params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed supply params
   * @return The address of the underlying reserve
   * @return The amount to supply
   * @return The referralCode
   */
  function decodeSupplyParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256, uint16) {
    uint16 assetId;
    uint256 amount;
    uint16 referralCode;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      referralCode := and(shr(144, args), 0xFFFF)
    }
    return (reservesList[assetId], amount, referralCode);
  }

  /**
   * @notice Decodes compressed supply params to standard params along with permit params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed supply with permit params
   * @return The address of the underlying reserve
   * @return The amount to supply
   * @return The referralCode
   * @return The deadline of the permit
   * @return The V value of the permit signature
   */
  function decodeSupplyWithPermitParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256, uint16, uint256, uint8) {
    uint256 deadline;
    uint8 permitV;

    assembly {
      deadline := and(shr(160, args), 0xFFFFFFFF)
      permitV := and(shr(192, args), 0xFF)
    }
    (address asset, uint256 amount, uint16 referralCode) = decodeSupplyParams(reservesList, args);

    return (asset, amount, referralCode, deadline, permitV);
  }

  /**
   * @notice Decodes compressed withdraw params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed withdraw params
   * @return The address of the underlying reserve
   * @return The amount to withdraw
   */
  function decodeWithdrawParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256) {
    uint16 assetId;
    uint256 amount;
    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    if (amount == type(uint128).max) {
      amount = type(uint256).max;
    }
    return (reservesList[assetId], amount);
  }

  /**
   * @notice Decodes compressed borrow params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed borrow params
   * @return The address of the underlying reserve
   * @return The amount to borrow
   * @return The interestRateMode, 1 for stable or 2 for variable debt
   * @return The referralCode
   */
  function decodeBorrowParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256, uint256, uint16) {
    uint16 assetId;
    uint256 amount;
    uint256 interestRateMode;
    uint16 referralCode;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      interestRateMode := and(shr(144, args), 0xFF)
      referralCode := and(shr(152, args), 0xFFFF)
    }

    return (reservesList[assetId], amount, interestRateMode, referralCode);
  }

  /**
   * @notice Decodes compressed repay params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed repay params
   * @return The address of the underlying reserve
   * @return The amount to repay
   * @return The interestRateMode, 1 for stable or 2 for variable debt
   */
  function decodeRepayParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256, uint256) {
    uint16 assetId;
    uint256 amount;
    uint256 interestRateMode;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      interestRateMode := and(shr(144, args), 0xFF)
    }

    if (amount == type(uint128).max) {
      amount = type(uint256).max;
    }

    return (reservesList[assetId], amount, interestRateMode);
  }

  /**
   * @notice Decodes compressed repay params to standard params along with permit params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed repay with permit params
   * @return The address of the underlying reserve
   * @return The amount to repay
   * @return The interestRateMode, 1 for stable or 2 for variable debt
   * @return The deadline of the permit
   * @return The V value of the permit signature
   */
  function decodeRepayWithPermitParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256, uint256, uint256, uint8) {
    uint256 deadline;
    uint8 permitV;

    (address asset, uint256 amount, uint256 interestRateMode) = decodeRepayParams(
      reservesList,
      args
    );

    assembly {
      deadline := and(shr(152, args), 0xFFFFFFFF)
      permitV := and(shr(184, args), 0xFF)
    }

    return (asset, amount, interestRateMode, deadline, permitV);
  }

  /**
   * @notice Decodes compressed swap borrow rate mode params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed swap borrow rate mode params
   * @return The address of the underlying reserve
   * @return The interest rate mode, 1 for stable 2 for variable debt
   */
  function decodeSwapBorrowRateModeParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256) {
    uint16 assetId;
    uint256 interestRateMode;

    assembly {
      assetId := and(args, 0xFFFF)
      interestRateMode := and(shr(16, args), 0xFF)
    }

    return (reservesList[assetId], interestRateMode);
  }

  /**
   * @notice Decodes compressed rebalance stable borrow rate params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed rabalance stable borrow rate params
   * @return The address of the underlying reserve
   * @return The address of the user to rebalance
   */
  function decodeRebalanceStableBorrowRateParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, address) {
    uint16 assetId;
    address user;
    assembly {
      assetId := and(args, 0xFFFF)
      user := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    return (reservesList[assetId], user);
  }

  /**
   * @notice Decodes compressed set user use reserve as collateral params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed set user use reserve as collateral params
   * @return The address of the underlying reserve
   * @return True if to set using as collateral, false otherwise
   */
  function decodeSetUserUseReserveAsCollateralParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, bool) {
    uint16 assetId;
    bool useAsCollateral;
    assembly {
      assetId := and(args, 0xFFFF)
      useAsCollateral := and(shr(16, args), 0x1)
    }
    return (reservesList[assetId], useAsCollateral);
  }

  /**
   * @notice Decodes compressed liquidation call params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args1 The first half of packed liquidation call params
   * @param args2 The second half of the packed liquidation call params
   * @return The address of the underlying collateral asset
   * @return The address of the underlying debt asset
   * @return The address of the user to liquidate
   * @return The amount of debt to cover
   * @return True if receiving aTokens, false otherwise
   */
  function decodeLiquidationCallParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args1,
    bytes32 args2
  ) internal view returns (address, address, address, uint256, bool) {
    uint16 collateralAssetId;
    uint16 debtAssetId;
    address user;
    uint256 debtToCover;
    bool receiveAToken;

    assembly {
      collateralAssetId := and(args1, 0xFFFF)
      debtAssetId := and(shr(16, args1), 0xFFFF)
      user := and(shr(32, args1), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

      debtToCover := and(args2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      receiveAToken := and(shr(128, args2), 0x1)
    }

    if (debtToCover == type(uint128).max) {
      debtToCover = type(uint256).max;
    }

    return (
      reservesList[collateralAssetId],
      reservesList[debtAssetId],
      user,
      debtToCover,
      receiveAToken
    );
  }
}
