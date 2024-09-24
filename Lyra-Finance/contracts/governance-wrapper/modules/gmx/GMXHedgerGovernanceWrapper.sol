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

import "../../../GMXFuturesPoolHedger.sol";
import "../../BaseGovernanceWrapper.sol";

contract GMXHedgerGovernanceWrapper is BaseGovernanceWrapper {
  struct HedgerBounds {
    GMXFuturesPoolHedger.PoolHedgerParameters minPoolHedgerParams;
    GMXFuturesPoolHedger.PoolHedgerParameters maxPoolHedgerParams;
    GMXFuturesPoolHedger.FuturesPoolHedgerParameters minFuturesPoolHedgerParams;
    GMXFuturesPoolHedger.FuturesPoolHedgerParameters maxFuturesPoolHedgerParams;
  }

  GMXFuturesPoolHedger public marketHedger;
  LiquidityPool public liquidityPool;
  HedgerBounds internal hedgerBounds;

  ////////////////
  // Owner Only //
  ////////////////

  function setLiquidityPool(LiquidityPool _liquidityPool) external onlyOwner {
    if (address(liquidityPool) != address(0)) {
      revert GMXHGW_LiquidityPoolAlreadySet(liquidityPool);
    }
    liquidityPool = _liquidityPool;
    emit GMXHGW_LiquidityPoolSet(_liquidityPool);
  }

  function setHedgerBounds(HedgerBounds memory _hedgerBounds) external onlyOwner {
    hedgerBounds = _hedgerBounds;
    emit GMXHGW_FuturesPoolHedgerBounds(_hedgerBounds);
  }

  function setPositionRouter(IPositionRouter _positionRouter) external onlyOwner {
    marketHedger.setPositionRouter(_positionRouter);
    emit GMXHGW_PositionRouterSet(_positionRouter);
  }

  function recoverEth(address payable receiver) external onlyOwner {
    marketHedger.recoverEth(receiver);
    emit GMXHGW_EthRecovered(receiver);
  }

  function setReferralCode(bytes32 _referralCode) external onlyOwner {
    marketHedger.setReferralCode(_referralCode);
    emit GMXHGW_ReferralCodeSet(_referralCode);
  }

  function recoverHedgerFunds(IERC20Decimals token, address recipient) external onlyOwner {
    marketHedger.recoverFunds(token, recipient);
    emit GMXHGW_HedgerFundsRecovered(token, recipient);
  }

  ////////////////////////////
  // Risk Council and Owner //
  ////////////////////////////

  function updateMarketHedger() external onlyRiskCouncilOrOwner {
    if (address(liquidityPool) == address(0)) {
      revert GMXHGW_LiquidityPoolNotSet();
    }

    // we dont worry about currentHedger owner as we can `forceChangeOwner` if necessary
    GMXFuturesPoolHedger currentHedger = marketHedger;
    GMXFuturesPoolHedger newHedger = GMXFuturesPoolHedger(payable(address(liquidityPool.poolHedger())));

    if (newHedger == currentHedger) {
      revert GMXHGW_HedgerIsUnchanged();
    }
    newHedger.acceptOwnership();
    marketHedger = newHedger;
  }

  function setPoolHedgerParams(
    GMXFuturesPoolHedger.PoolHedgerParameters memory _poolHedgerParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      GMXFuturesPoolHedger.PoolHedgerParameters memory lowerBound = hedgerBounds.minPoolHedgerParams;
      GMXFuturesPoolHedger.PoolHedgerParameters memory upperBound = hedgerBounds.maxPoolHedgerParams;
      if (
        _poolHedgerParams.interactionDelay < lowerBound.interactionDelay ||
        _poolHedgerParams.interactionDelay > upperBound.interactionDelay ||
        _poolHedgerParams.hedgeCap < lowerBound.hedgeCap ||
        _poolHedgerParams.hedgeCap > upperBound.hedgeCap
      ) {
        revert GMXHGW_PoolHedgerParamsOutOfBounds(_poolHedgerParams);
      }
    }

    marketHedger.setPoolHedgerParams(_poolHedgerParams);
    emit GMXHGW_PoolHedgerParamsSet(msg.sender, _poolHedgerParams);
  }

  function setFuturesPoolHedgerParams(
    GMXFuturesPoolHedger.FuturesPoolHedgerParameters memory _futuresPoolHedgerParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      GMXFuturesPoolHedger.FuturesPoolHedgerParameters memory lowerBound = hedgerBounds.minFuturesPoolHedgerParams;
      GMXFuturesPoolHedger.FuturesPoolHedgerParameters memory upperBound = hedgerBounds.maxFuturesPoolHedgerParams;

      if (
        _futuresPoolHedgerParams.acceptableSpotSlippage < lowerBound.acceptableSpotSlippage ||
        _futuresPoolHedgerParams.acceptableSpotSlippage > upperBound.acceptableSpotSlippage ||
        _futuresPoolHedgerParams.deltaThreshold < lowerBound.deltaThreshold ||
        _futuresPoolHedgerParams.deltaThreshold > upperBound.deltaThreshold ||
        _futuresPoolHedgerParams.marketDepthBuffer < lowerBound.marketDepthBuffer ||
        _futuresPoolHedgerParams.marketDepthBuffer > upperBound.marketDepthBuffer ||
        _futuresPoolHedgerParams.targetLeverage < lowerBound.targetLeverage ||
        _futuresPoolHedgerParams.targetLeverage > upperBound.targetLeverage ||
        _futuresPoolHedgerParams.maxLeverage < lowerBound.maxLeverage ||
        _futuresPoolHedgerParams.maxLeverage > upperBound.maxLeverage ||
        _futuresPoolHedgerParams.minCancelDelay < lowerBound.minCancelDelay ||
        _futuresPoolHedgerParams.minCancelDelay > upperBound.minCancelDelay ||
        _futuresPoolHedgerParams.minCollateralUpdate < lowerBound.minCollateralUpdate ||
        _futuresPoolHedgerParams.minCollateralUpdate > upperBound.minCollateralUpdate ||
        // Note: can only set the boolean to either value set in the params
        // So one must be false and one true if the intention is that it is settable by risk council
        (_futuresPoolHedgerParams.vaultLiquidityCheckEnabled != lowerBound.vaultLiquidityCheckEnabled &&
          _futuresPoolHedgerParams.vaultLiquidityCheckEnabled != upperBound.vaultLiquidityCheckEnabled)
      ) {
        revert GMXHGW_FuturesPoolHedgerParamsOutOfBounds(_futuresPoolHedgerParams);
      }
    }

    marketHedger.setFuturesPoolHedgerParams(_futuresPoolHedgerParams);
    emit GMXHGW_FuturesPoolHedgerParamsSet(msg.sender, _futuresPoolHedgerParams);
  }

  ///////////
  // Views //
  ///////////
  function getHedgerBounds() external view returns (HedgerBounds memory bounds) {
    return hedgerBounds;
  }

  ////////////
  // Events //
  ////////////
  event GMXHGW_FuturesPoolHedgerBounds(HedgerBounds futuresPoolHedgerBounds);
  event GMXHGW_LiquidityPoolSet(LiquidityPool liquidityPool);
  event GMXHGW_PositionRouterSet(IPositionRouter positionRouter);
  event GMXHGW_EthRecovered(address receiver);
  event GMXHGW_ReferralCodeSet(bytes32 referralCode);
  event GMXHGW_HedgerFundsRecovered(IERC20Decimals token, address recipient);

  event GMXHGW_PoolHedgerParamsSet(address indexed caller, GMXFuturesPoolHedger.PoolHedgerParameters poolHedgerParams);
  event GMXHGW_FuturesPoolHedgerParamsSet(
    address indexed caller,
    GMXFuturesPoolHedger.FuturesPoolHedgerParameters futuresPoolHedgerParams
  );

  ////////////
  // Error ///
  ////////////

  error GMXHGW_LiquidityPoolAlreadySet(LiquidityPool liquidityPool);

  error GMXHGW_LiquidityPoolNotSet();

  error GMXHGW_HedgerIsUnchanged();

  error GMXHGW_PoolHedgerParamsOutOfBounds(PoolHedger.PoolHedgerParameters PoolHedgerParams);

  error GMXHGW_FuturesPoolHedgerParamsOutOfBounds(
    GMXFuturesPoolHedger.FuturesPoolHedgerParameters futuresPoolHedgerParams
  );
}
