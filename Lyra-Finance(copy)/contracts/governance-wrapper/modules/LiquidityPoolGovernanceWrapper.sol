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
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "../BaseGovernanceWrapper.sol";
import "../../LiquidityPool.sol";

contract LiquidityPoolGovernanceWrapper is BaseGovernanceWrapper {
  struct LiquidityPoolBounds {
    LiquidityPool.LiquidityPoolParameters minLiquidityPoolParams;
    LiquidityPool.LiquidityPoolParameters maxLiquidityPoolParams;
    LiquidityPool.CircuitBreakerParameters minCircuitBreakerParams;
    LiquidityPool.CircuitBreakerParameters maxCircuitBreakerParams;
    address defaultGuardianMultisig;
    bool recoverFundsBlocked;
    bool updateHedgerBlocked;
  }

  LiquidityPool public liquidityPool;
  LiquidityPoolBounds internal liquidityPoolBounds;

  ////////////////
  // Only Owner //
  ////////////////

  function setLiquidityPool(LiquidityPool _liquidityPool) external onlyOwner {
    if (address(liquidityPool) != address(0)) {
      revert LPGW_LiquidityPoolAlreadySet(liquidityPool);
    }
    _liquidityPool.acceptOwnership();
    liquidityPool = _liquidityPool;
    emit LPGW_LiquidityPoolSet(_liquidityPool);
  }

  function setLiquidityPoolBounds(LiquidityPoolBounds memory _liquidityPoolBounds) external onlyOwner {
    liquidityPoolBounds = _liquidityPoolBounds;
    emit LPGW_LiquidityPoolBoundsSet(_liquidityPoolBounds);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////

  /**
   * @notice Function can be called by the riskCouncil or owner to change the liquidity pool parameters
   * @param _lpParams parameters of the liquidityPoolParameters
   */
  function setLiquidityPoolParameters(
    LiquidityPool.LiquidityPoolParameters memory _lpParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      LiquidityPool.LiquidityPoolParameters memory lowerBound = liquidityPoolBounds.minLiquidityPoolParams;
      LiquidityPool.LiquidityPoolParameters memory upperBound = liquidityPoolBounds.maxLiquidityPoolParams;
      if (
        _lpParams.minDepositWithdraw < lowerBound.minDepositWithdraw ||
        _lpParams.minDepositWithdraw > upperBound.minDepositWithdraw ||
        _lpParams.depositDelay < lowerBound.depositDelay ||
        _lpParams.depositDelay > upperBound.depositDelay ||
        _lpParams.withdrawalDelay < lowerBound.withdrawalDelay ||
        _lpParams.withdrawalDelay > upperBound.withdrawalDelay ||
        _lpParams.withdrawalFee < lowerBound.withdrawalFee ||
        _lpParams.withdrawalFee > upperBound.withdrawalFee ||
        _lpParams.guardianDelay < lowerBound.guardianDelay ||
        _lpParams.guardianDelay > upperBound.guardianDelay ||
        _lpParams.adjustmentNetScalingFactor < lowerBound.adjustmentNetScalingFactor ||
        _lpParams.adjustmentNetScalingFactor > upperBound.adjustmentNetScalingFactor ||
        _lpParams.callCollatScalingFactor < lowerBound.callCollatScalingFactor ||
        _lpParams.callCollatScalingFactor > upperBound.callCollatScalingFactor ||
        _lpParams.putCollatScalingFactor < lowerBound.putCollatScalingFactor ||
        _lpParams.putCollatScalingFactor > upperBound.putCollatScalingFactor
      ) {
        revert LPGW_LiquidityPoolParamsOutOfBounds(_lpParams);
      }
      // If a guardian is specified by the owner, always use that value - otherwise risk council can set the guardian
      if (liquidityPoolBounds.defaultGuardianMultisig != address(0)) {
        _lpParams.guardianMultisig = liquidityPoolBounds.defaultGuardianMultisig;
      }
    }

    liquidityPool.setLiquidityPoolParameters(_lpParams);
    emit LPGW_LiquidityPoolParametersSet(msg.sender, _lpParams);
  }

  /**
   * @notice Function can be called by the riskCouncil or owner to change the circuit breaker parameters
   * @param _cbParams parameters of the circuitBreakerParameters
   */
  function setCircuitBreakerParameters(
    LiquidityPool.CircuitBreakerParameters memory _cbParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      LiquidityPool.CircuitBreakerParameters memory lowerBound = liquidityPoolBounds.minCircuitBreakerParams;
      LiquidityPool.CircuitBreakerParameters memory upperBound = liquidityPoolBounds.maxCircuitBreakerParams;
      if (
        _cbParams.liquidityCBThreshold < lowerBound.liquidityCBThreshold ||
        _cbParams.liquidityCBThreshold > upperBound.liquidityCBThreshold ||
        _cbParams.liquidityCBTimeout < lowerBound.liquidityCBTimeout ||
        _cbParams.liquidityCBTimeout > upperBound.liquidityCBTimeout ||
        _cbParams.ivVarianceCBThreshold < lowerBound.ivVarianceCBThreshold ||
        _cbParams.ivVarianceCBThreshold > upperBound.ivVarianceCBThreshold ||
        _cbParams.skewVarianceCBThreshold < lowerBound.skewVarianceCBThreshold ||
        _cbParams.skewVarianceCBThreshold > upperBound.skewVarianceCBThreshold ||
        _cbParams.ivVarianceCBTimeout < lowerBound.ivVarianceCBTimeout ||
        _cbParams.ivVarianceCBTimeout > upperBound.ivVarianceCBTimeout ||
        _cbParams.skewVarianceCBTimeout < lowerBound.skewVarianceCBTimeout ||
        _cbParams.skewVarianceCBTimeout > upperBound.skewVarianceCBTimeout ||
        _cbParams.boardSettlementCBTimeout < lowerBound.boardSettlementCBTimeout ||
        _cbParams.boardSettlementCBTimeout > upperBound.boardSettlementCBTimeout ||
        _cbParams.contractAdjustmentCBTimeout < lowerBound.contractAdjustmentCBTimeout ||
        _cbParams.contractAdjustmentCBTimeout > upperBound.contractAdjustmentCBTimeout
      ) {
        revert LPGW_CircuitBreakerParamsOutOfBounds(_cbParams);
      }
    }

    liquidityPool.setCircuitBreakerParameters(_cbParams);
    emit LPGW_CircuitBreakerParametersSet(msg.sender, _cbParams);
  }

  function recoverLPFunds(IERC20Decimals token, address recipient) external onlyRiskCouncilOrOwner {
    if (recipient == address(0)) {
      revert LPGW_InvalidRecipient();
    }

    if (msg.sender == riskCouncil && liquidityPoolBounds.recoverFundsBlocked) {
      revert LPGW_RecoverFundsBlocked();
    }

    liquidityPool.recoverFunds(token, recipient);

    emit LPGW_RecoverFundsCalled(msg.sender, token, recipient);
  }

  function setPoolHedger(PoolHedger newPoolHedger) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil && liquidityPoolBounds.updateHedgerBlocked) {
      revert LPGW_CannotUpdateHedge();
    }
    liquidityPool.setPoolHedger(newPoolHedger);

    emit LPGW_PoolHedgerSet(msg.sender, newPoolHedger);
  }

  ///////////
  // Views //
  ///////////
  function getLiquidityPoolBounds() external view returns (LiquidityPoolBounds memory bounds) {
    return liquidityPoolBounds;
  }

  ////////////
  // Events //
  ////////////
  event LPGW_LiquidityPoolSet(LiquidityPool liquidityPool);

  event LPGW_LiquidityPoolBoundsSet(LiquidityPoolBounds lpBounds);

  event LPGW_CircuitBreakerParametersSet(
    address indexed caller,
    LiquidityPool.CircuitBreakerParameters circuitBreakerParameters
  );

  event LPGW_LiquidityPoolParametersSet(
    address indexed caller,
    LiquidityPool.LiquidityPoolParameters liquidityPoolParameters
  );

  event LPGW_PoolHedgerSet(address indexed caller, PoolHedger indexed newPoolHedger);

  event LPGW_RecoverFundsCalled(address indexed caller, IERC20Decimals indexed token, address recipient);

  ////////////
  // Errors //
  ////////////
  error LPGW_LiquidityPoolAlreadySet(LiquidityPool liquidityPool);

  error LPGW_LiquidityPoolParamsOutOfBounds(LiquidityPool.LiquidityPoolParameters _lpParams);

  error LPGW_CircuitBreakerParamsOutOfBounds(LiquidityPool.CircuitBreakerParameters _cbParams);

  error LPGW_InvalidRecipient();

  error LPGW_RecoverFundsBlocked();

  error LPGW_CannotUpdateHedge();
}
