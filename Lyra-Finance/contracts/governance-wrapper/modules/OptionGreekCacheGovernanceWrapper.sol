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

import "../../OptionGreekCache.sol";

contract OptionGreekCacheGovernanceWrapper is BaseGovernanceWrapper {
  struct GreekCacheBounds {
    OptionGreekCache.GreekCacheParameters minGreekCacheParams;
    OptionGreekCache.GreekCacheParameters maxGreekCacheParams;
    OptionGreekCache.ForceCloseParameters minForceCloseParams;
    OptionGreekCache.ForceCloseParameters maxForceCloseParams;
    OptionGreekCache.MinCollateralParameters minMinCollateralParams;
    OptionGreekCache.MinCollateralParameters maxMinCollateralParams;
  }

  OptionGreekCache public optionGreekCache;
  GreekCacheBounds internal greekCacheBounds;

  ////////////////
  // Only Owner //
  ////////////////

  function setOptionGreekCache(OptionGreekCache _optionGreekCache) external onlyOwner {
    if (address(optionGreekCache) != address(0)) {
      revert OGCGW_OptionGreekCacheAlreadySet(optionGreekCache);
    }
    _optionGreekCache.acceptOwnership();
    optionGreekCache = _optionGreekCache;
    emit OGCGW_OptionGreekCacheSet(_optionGreekCache);
  }

  function setGreekCacheBounds(GreekCacheBounds memory _greekCacheBounds) external onlyOwner {
    greekCacheBounds = _greekCacheBounds;
    emit OGCGW_GreekCacheBoundsSet(_greekCacheBounds);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////

  /**
   * @notice Function can be called by the riskCouncil or owner to change the greek cache parameters
   * @param _greekCacheParams parameters to set the greek cache to
   */
  function setGreekCacheParameters(
    OptionGreekCache.GreekCacheParameters memory _greekCacheParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionGreekCache.GreekCacheParameters memory lowerBound = greekCacheBounds.minGreekCacheParams;
      OptionGreekCache.GreekCacheParameters memory upperBound = greekCacheBounds.maxGreekCacheParams;

      if (
        _greekCacheParams.maxStrikesPerBoard < lowerBound.maxStrikesPerBoard ||
        _greekCacheParams.maxStrikesPerBoard > upperBound.maxStrikesPerBoard ||
        _greekCacheParams.acceptableSpotPricePercentMove < lowerBound.acceptableSpotPricePercentMove ||
        _greekCacheParams.acceptableSpotPricePercentMove > upperBound.acceptableSpotPricePercentMove ||
        _greekCacheParams.staleUpdateDuration < lowerBound.staleUpdateDuration ||
        _greekCacheParams.staleUpdateDuration > upperBound.staleUpdateDuration ||
        _greekCacheParams.varianceIvGWAVPeriod < lowerBound.varianceIvGWAVPeriod ||
        _greekCacheParams.varianceIvGWAVPeriod > upperBound.varianceIvGWAVPeriod ||
        _greekCacheParams.varianceSkewGWAVPeriod < lowerBound.varianceSkewGWAVPeriod ||
        _greekCacheParams.varianceSkewGWAVPeriod > upperBound.varianceSkewGWAVPeriod ||
        _greekCacheParams.optionValueIvGWAVPeriod < lowerBound.optionValueIvGWAVPeriod ||
        _greekCacheParams.optionValueIvGWAVPeriod > upperBound.optionValueIvGWAVPeriod ||
        _greekCacheParams.optionValueSkewGWAVPeriod < lowerBound.optionValueSkewGWAVPeriod ||
        _greekCacheParams.optionValueSkewGWAVPeriod > upperBound.optionValueSkewGWAVPeriod ||
        _greekCacheParams.gwavSkewFloor < lowerBound.gwavSkewFloor ||
        _greekCacheParams.gwavSkewFloor > upperBound.gwavSkewFloor ||
        _greekCacheParams.gwavSkewCap < lowerBound.gwavSkewCap ||
        _greekCacheParams.gwavSkewCap > upperBound.gwavSkewCap
      ) {
        revert OGCGW_GreekCacheParametersOutOfBounds(_greekCacheParams);
      }
    }

    optionGreekCache.setGreekCacheParameters(_greekCacheParams);
    emit OGCGW_GreekCacheParametersSet(msg.sender, _greekCacheParams);
  }

  /**
   * @notice Function can be called by the riskCouncil or owner to change the greek cache parameters
   * @param _forceCloseParams parameters to set the greek cache to
   */
  function setForceCloseParameters(
    OptionGreekCache.ForceCloseParameters memory _forceCloseParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionGreekCache.ForceCloseParameters memory lowerBound = greekCacheBounds.minForceCloseParams;
      OptionGreekCache.ForceCloseParameters memory upperBound = greekCacheBounds.maxForceCloseParams;
      if (
        _forceCloseParams.ivGWAVPeriod < lowerBound.ivGWAVPeriod ||
        _forceCloseParams.ivGWAVPeriod > upperBound.ivGWAVPeriod ||
        _forceCloseParams.skewGWAVPeriod < lowerBound.skewGWAVPeriod ||
        _forceCloseParams.skewGWAVPeriod > upperBound.skewGWAVPeriod ||
        _forceCloseParams.shortVolShock < lowerBound.shortVolShock ||
        _forceCloseParams.shortVolShock > upperBound.shortVolShock ||
        _forceCloseParams.shortPostCutoffVolShock < lowerBound.shortPostCutoffVolShock ||
        _forceCloseParams.shortPostCutoffVolShock > upperBound.shortPostCutoffVolShock ||
        _forceCloseParams.longVolShock < lowerBound.longVolShock ||
        _forceCloseParams.longVolShock > upperBound.longVolShock ||
        _forceCloseParams.longPostCutoffVolShock < lowerBound.longPostCutoffVolShock ||
        _forceCloseParams.longPostCutoffVolShock > upperBound.longPostCutoffVolShock ||
        _forceCloseParams.liquidateVolShock < lowerBound.liquidateVolShock ||
        _forceCloseParams.liquidateVolShock > upperBound.liquidateVolShock ||
        _forceCloseParams.liquidatePostCutoffVolShock < lowerBound.liquidatePostCutoffVolShock ||
        _forceCloseParams.liquidatePostCutoffVolShock > upperBound.liquidatePostCutoffVolShock ||
        _forceCloseParams.shortSpotMin < lowerBound.shortSpotMin ||
        _forceCloseParams.shortSpotMin > upperBound.shortSpotMin ||
        _forceCloseParams.liquidateSpotMin < lowerBound.liquidateSpotMin ||
        _forceCloseParams.liquidateSpotMin > upperBound.liquidateSpotMin
      ) {
        revert OGCGW_ForceCloseParametersOutOfBounds(_forceCloseParams);
      }
    }

    optionGreekCache.setForceCloseParameters(_forceCloseParams);
    emit OGCGW_ForceCloseParametersSet(msg.sender, _forceCloseParams);
  }

  /**
   * @notice Function can be called by the riskCouncil or owner to change the greek cache parameters
   * @param _minCollatParams parameters to set the greek cache to
   */
  function setMinCollateralParameters(
    OptionGreekCache.MinCollateralParameters memory _minCollatParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionGreekCache.MinCollateralParameters memory lowerBound = greekCacheBounds.minMinCollateralParams;
      OptionGreekCache.MinCollateralParameters memory upperBound = greekCacheBounds.maxMinCollateralParams;

      if (
        _minCollatParams.minStaticQuoteCollateral < lowerBound.minStaticQuoteCollateral ||
        _minCollatParams.minStaticQuoteCollateral > upperBound.minStaticQuoteCollateral ||
        _minCollatParams.minStaticBaseCollateral < lowerBound.minStaticBaseCollateral ||
        _minCollatParams.minStaticBaseCollateral > upperBound.minStaticBaseCollateral ||
        _minCollatParams.shockVolA < lowerBound.shockVolA ||
        _minCollatParams.shockVolA > upperBound.shockVolA ||
        _minCollatParams.shockVolPointA < lowerBound.shockVolPointA ||
        _minCollatParams.shockVolPointA > upperBound.shockVolPointA ||
        _minCollatParams.shockVolB < lowerBound.shockVolB ||
        _minCollatParams.shockVolB > upperBound.shockVolB ||
        _minCollatParams.shockVolPointB < lowerBound.shockVolPointB ||
        _minCollatParams.shockVolPointB > upperBound.shockVolPointB ||
        _minCollatParams.callSpotPriceShock < lowerBound.callSpotPriceShock ||
        _minCollatParams.callSpotPriceShock > upperBound.callSpotPriceShock ||
        _minCollatParams.putSpotPriceShock < lowerBound.putSpotPriceShock ||
        _minCollatParams.putSpotPriceShock > upperBound.putSpotPriceShock
      ) {
        revert OGCGW_MinCollateralParametersOutOfBounds(_minCollatParams);
      }
    }

    optionGreekCache.setMinCollateralParameters(_minCollatParams);
    emit OGCGW_MinCollateralParamsSet(msg.sender, _minCollatParams);
  }

  ///////////
  // Views //
  ///////////
  function getGreekCacheBounds() external view returns (GreekCacheBounds memory bounds) {
    return greekCacheBounds;
  }

  ////////////
  // Events //
  ////////////
  event OGCGW_OptionGreekCacheSet(OptionGreekCache optionGreekCache);

  event OGCGW_GreekCacheBoundsSet(GreekCacheBounds greekCacheBounds);

  event OGCGW_MinCollateralParamsSet(
    address indexed caller,
    OptionGreekCache.MinCollateralParameters minCollateralParams
  );

  event OGCGW_GreekCacheParametersSet(address indexed caller, OptionGreekCache.GreekCacheParameters greekCacheParams);

  event OGCGW_ForceCloseParametersSet(address indexed caller, OptionGreekCache.ForceCloseParameters forceCloseParams);

  ////////////
  // Errors //
  ////////////

  error OGCGW_OptionGreekCacheAlreadySet(OptionGreekCache optionGreekCache);

  error OGCGW_GreekCacheParametersOutOfBounds(OptionGreekCache.GreekCacheParameters greekCacheParams);

  error OGCGW_ForceCloseParametersOutOfBounds(OptionGreekCache.ForceCloseParameters forceCloseParams);

  error OGCGW_MinCollateralParametersOutOfBounds(OptionGreekCache.MinCollateralParameters minCollateralParams);
}
