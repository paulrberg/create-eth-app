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

import "../../../SNXPerpsV2PoolHedger.sol";
import "../../BaseGovernanceWrapper.sol";

contract SNXHedgerGovernanceWrapper is BaseGovernanceWrapper {
  struct HedgerBounds {
    SNXPerpsV2PoolHedger.PoolHedgerParameters minPoolHedgerParams;
    SNXPerpsV2PoolHedger.PoolHedgerParameters maxPoolHedgerParams;
    SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters minFuturesPoolHedgerParams;
    SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters maxFuturesPoolHedgerParams;
  }

  SNXPerpsV2PoolHedger public marketHedger;
  LiquidityPool public liquidityPool;
  HedgerBounds internal hedgerBounds;

  ////////////////
  // Owner Only //
  ////////////////

  function setLiquidityPool(LiquidityPool _liquidityPool) external onlyOwner {
    if (address(liquidityPool) != address(0)) {
      revert SNXHGW_LiquidityPoolAlreadySet(liquidityPool);
    }
    liquidityPool = _liquidityPool;
    emit SNXHGW_LiquidityPoolSet(_liquidityPool);
  }

  function setSNXFuturesHedgerBounds(HedgerBounds memory _hedgerBounds) external onlyOwner {
    hedgerBounds = _hedgerBounds;
    emit SNXHGW_FuturesPoolHedgerBounds(_hedgerBounds);
  }

  function setTrackingCode(bytes32 _trackingCode) external onlyOwner {
    marketHedger.setTrackingCode(_trackingCode);
    emit SNXHGW_trackingCodeSet(_trackingCode);
  }

  ////////////////////////////
  // Risk Council and Owner //
  ////////////////////////////

  function updateMarketHedger() external onlyRiskCouncilOrOwner {
    if (address(liquidityPool) == address(0)) {
      revert SNXHGW_LiquidityPoolNotSet();
    }

    // we dont worry about currentHedger owner as we can `forceChangeOwner` if necessary
    SNXPerpsV2PoolHedger currentHedger = marketHedger;
    SNXPerpsV2PoolHedger newHedger = SNXPerpsV2PoolHedger(payable(address(liquidityPool.poolHedger())));

    if (newHedger == currentHedger) {
      revert SNXHGW_HedgerIsUnchanged();
    }
    newHedger.acceptOwnership();
    marketHedger = newHedger;
  }

  function setPoolHedgerParams(
    SNXPerpsV2PoolHedger.PoolHedgerParameters memory _poolHedgerParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      SNXPerpsV2PoolHedger.PoolHedgerParameters memory lowerBound = hedgerBounds.minPoolHedgerParams;
      SNXPerpsV2PoolHedger.PoolHedgerParameters memory upperBound = hedgerBounds.maxPoolHedgerParams;
      if (
        _poolHedgerParams.interactionDelay < lowerBound.interactionDelay ||
        _poolHedgerParams.interactionDelay > upperBound.interactionDelay ||
        _poolHedgerParams.hedgeCap < lowerBound.hedgeCap ||
        _poolHedgerParams.hedgeCap > upperBound.hedgeCap
      ) {
        revert SNXHGW_PoolHedgerParamsOutOfBounds(_poolHedgerParams);
      }
    }

    marketHedger.setPoolHedgerParams(_poolHedgerParams);
    emit SNXHGW_PoolHedgerParamsSet(msg.sender, _poolHedgerParams);
  }

  function setFuturesPoolHedgerParams(
    SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters memory _futuresPoolHedgerParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters memory lowerBound = hedgerBounds.minFuturesPoolHedgerParams;
      SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters memory upperBound = hedgerBounds.maxFuturesPoolHedgerParams;

      if (
        _futuresPoolHedgerParams.maximumFundingRate < lowerBound.maximumFundingRate ||
        _futuresPoolHedgerParams.maximumFundingRate > upperBound.maximumFundingRate ||
        _futuresPoolHedgerParams.deltaThreshold < lowerBound.deltaThreshold ||
        _futuresPoolHedgerParams.deltaThreshold > upperBound.deltaThreshold ||
        _futuresPoolHedgerParams.marketDepthBuffer < lowerBound.marketDepthBuffer ||
        _futuresPoolHedgerParams.marketDepthBuffer > upperBound.marketDepthBuffer ||
        _futuresPoolHedgerParams.targetLeverage < lowerBound.targetLeverage ||
        _futuresPoolHedgerParams.targetLeverage > upperBound.targetLeverage ||
        _futuresPoolHedgerParams.priceDeltaBuffer < lowerBound.priceDeltaBuffer ||
        _futuresPoolHedgerParams.priceDeltaBuffer > upperBound.priceDeltaBuffer ||
        _futuresPoolHedgerParams.worstStableRate < lowerBound.worstStableRate ||
        _futuresPoolHedgerParams.worstStableRate > upperBound.worstStableRate
      ) {
        revert SNXHGW_FuturesPoolHedgerParamsOutOfBounds(_futuresPoolHedgerParams);
      }
    }

    marketHedger.setFuturesPoolHedgerParams(_futuresPoolHedgerParams);
    emit SNXHGW_FuturesPoolHedgerParamsSet(msg.sender, _futuresPoolHedgerParams);
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
  event SNXHGW_FuturesPoolHedgerBounds(HedgerBounds futuresPoolHedgerBounds);
  event SNXHGW_LiquidityPoolSet(LiquidityPool liquidityPool);
  event SNXHGW_PoolHedgerParamsSet(address indexed caller, SNXPerpsV2PoolHedger.PoolHedgerParameters poolHedgerParams);
  event SNXHGW_FuturesPoolHedgerParamsSet(
    address indexed caller,
    SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters futuresPoolHedgerParams
  );
  event SNXHGW_trackingCodeSet(bytes32 trackingCode);
  ////////////
  // Error ///
  ////////////

  error SNXHGW_LiquidityPoolAlreadySet(LiquidityPool liquidityPool);

  error SNXHGW_LiquidityPoolNotSet();

  error SNXHGW_HedgerIsUnchanged();

  error SNXHGW_PoolHedgerParamsOutOfBounds(PoolHedger.PoolHedgerParameters PoolHedgerParams);

  error SNXHGW_FuturesPoolHedgerParamsOutOfBounds(
    SNXPerpsV2PoolHedger.SNXPerpsV2PoolHedgerParameters futuresPoolHedgerParams
  );
}
