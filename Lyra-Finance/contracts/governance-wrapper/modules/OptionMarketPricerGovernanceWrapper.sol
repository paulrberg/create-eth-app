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

import "../../OptionMarketPricer.sol";

contract OptionMarketPricerGovernanceWrapper is BaseGovernanceWrapper {
  struct OptionMarketPricerBounds {
    OptionMarketPricer.PricingParameters minPricingParams;
    OptionMarketPricer.PricingParameters maxPricingParams;
    OptionMarketPricer.TradeLimitParameters minTradeLimitParams;
    OptionMarketPricer.TradeLimitParameters maxTradeLimitParams;
    OptionMarketPricer.VarianceFeeParameters minVarianceFeeParams;
    OptionMarketPricer.VarianceFeeParameters maxVarianceFeeParams;
  }

  OptionMarketPricer public optionMarketPricer;
  OptionMarketPricerBounds internal optionMarketPricerBounds;

  ////////////////
  // Only Owner //
  ////////////////

  function setOptionMarketPricer(OptionMarketPricer _optionMarketPricer) external onlyOwner {
    if (address(optionMarketPricer) != address(0)) {
      revert OMPGW_OptionMarketPricerAlreadySet(optionMarketPricer);
    }
    _optionMarketPricer.acceptOwnership();
    optionMarketPricer = _optionMarketPricer;
    emit OMPGW_OptionMarketPricerSet(_optionMarketPricer);
  }

  function setOptionMarketPricerBounds(OptionMarketPricerBounds memory _optionMarketPricerBounds) external onlyOwner {
    optionMarketPricerBounds = _optionMarketPricerBounds;
    emit OMPGW_OptionMarketPricerBoundsSet(optionMarketPricerBounds);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////

  function setPricingParams(OptionMarketPricer.PricingParameters memory _pricingParams) public onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionMarketPricer.PricingParameters memory lowerBound = optionMarketPricerBounds.minPricingParams;
      OptionMarketPricer.PricingParameters memory upperBound = optionMarketPricerBounds.maxPricingParams;

      if (
        _pricingParams.optionPriceFeeCoefficient < lowerBound.optionPriceFeeCoefficient ||
        _pricingParams.optionPriceFeeCoefficient > upperBound.optionPriceFeeCoefficient ||
        _pricingParams.optionPriceFee1xPoint < lowerBound.optionPriceFee1xPoint ||
        _pricingParams.optionPriceFee1xPoint > upperBound.optionPriceFee1xPoint ||
        _pricingParams.optionPriceFee2xPoint < lowerBound.optionPriceFee2xPoint ||
        _pricingParams.optionPriceFee2xPoint > upperBound.optionPriceFee2xPoint ||
        _pricingParams.spotPriceFeeCoefficient < lowerBound.spotPriceFeeCoefficient ||
        _pricingParams.spotPriceFeeCoefficient > upperBound.spotPriceFeeCoefficient ||
        _pricingParams.spotPriceFee1xPoint < lowerBound.spotPriceFee1xPoint ||
        _pricingParams.spotPriceFee1xPoint > upperBound.spotPriceFee1xPoint ||
        _pricingParams.spotPriceFee2xPoint < lowerBound.spotPriceFee2xPoint ||
        _pricingParams.spotPriceFee2xPoint > upperBound.spotPriceFee2xPoint ||
        _pricingParams.vegaFeeCoefficient < lowerBound.vegaFeeCoefficient ||
        _pricingParams.vegaFeeCoefficient > upperBound.vegaFeeCoefficient ||
        _pricingParams.standardSize < lowerBound.standardSize ||
        _pricingParams.standardSize > upperBound.standardSize ||
        _pricingParams.skewAdjustmentFactor < lowerBound.skewAdjustmentFactor ||
        _pricingParams.skewAdjustmentFactor > upperBound.skewAdjustmentFactor
      ) {
        revert OMPGW_PricingParamsOutOfBounds(_pricingParams);
      }
    }

    optionMarketPricer.setPricingParams(_pricingParams);
    emit OMPGW_PricingParamsSet(msg.sender, _pricingParams);
  }

  function setTradeLimitParams(
    OptionMarketPricer.TradeLimitParameters memory _tradeLimitParams
  ) public onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionMarketPricer.TradeLimitParameters storage lowerBound = optionMarketPricerBounds.minTradeLimitParams;
      OptionMarketPricer.TradeLimitParameters storage upperBound = optionMarketPricerBounds.maxTradeLimitParams;

      if (
        _tradeLimitParams.minDelta < lowerBound.minDelta ||
        _tradeLimitParams.minDelta > upperBound.minDelta ||
        _tradeLimitParams.minForceCloseDelta < lowerBound.minForceCloseDelta ||
        _tradeLimitParams.minForceCloseDelta > upperBound.minForceCloseDelta ||
        _tradeLimitParams.tradingCutoff < lowerBound.tradingCutoff ||
        _tradeLimitParams.tradingCutoff > upperBound.tradingCutoff ||
        _tradeLimitParams.minBaseIV < lowerBound.minBaseIV ||
        _tradeLimitParams.minBaseIV > upperBound.minBaseIV ||
        _tradeLimitParams.maxBaseIV < lowerBound.maxBaseIV ||
        _tradeLimitParams.maxBaseIV > upperBound.maxBaseIV ||
        _tradeLimitParams.minSkew < lowerBound.minSkew ||
        _tradeLimitParams.minSkew > upperBound.minSkew ||
        _tradeLimitParams.maxSkew < lowerBound.maxSkew ||
        _tradeLimitParams.maxSkew > upperBound.maxSkew ||
        _tradeLimitParams.minVol < lowerBound.minVol ||
        _tradeLimitParams.minVol > upperBound.minVol ||
        _tradeLimitParams.maxVol < lowerBound.maxVol ||
        _tradeLimitParams.maxVol > upperBound.maxVol ||
        _tradeLimitParams.absMinSkew < lowerBound.absMinSkew ||
        _tradeLimitParams.absMinSkew > upperBound.absMinSkew ||
        _tradeLimitParams.absMaxSkew < lowerBound.absMaxSkew ||
        _tradeLimitParams.absMaxSkew > upperBound.absMaxSkew ||
        // Note: can only set the boolean to either value set in the params
        // So one must be false and one true if the intention is that it is settable by risk council
        (_tradeLimitParams.capSkewsToAbs != lowerBound.capSkewsToAbs &&
          _tradeLimitParams.capSkewsToAbs != upperBound.capSkewsToAbs)
      ) {
        revert OMPGW_TradeLimitParamsOutOfBounds(_tradeLimitParams);
      }
    }

    optionMarketPricer.setTradeLimitParams(_tradeLimitParams);
    emit OMPGW_TradeLimitParamsSet(msg.sender, _tradeLimitParams);
  }

  function setVarianceFeeParams(
    OptionMarketPricer.VarianceFeeParameters memory _varianceFeeParams
  ) public onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      OptionMarketPricer.VarianceFeeParameters storage lowerBound = optionMarketPricerBounds.minVarianceFeeParams;
      OptionMarketPricer.VarianceFeeParameters storage upperBound = optionMarketPricerBounds.maxVarianceFeeParams;

      if (
        _varianceFeeParams.defaultVarianceFeeCoefficient < lowerBound.defaultVarianceFeeCoefficient ||
        _varianceFeeParams.defaultVarianceFeeCoefficient > upperBound.defaultVarianceFeeCoefficient ||
        _varianceFeeParams.forceCloseVarianceFeeCoefficient < lowerBound.forceCloseVarianceFeeCoefficient ||
        _varianceFeeParams.forceCloseVarianceFeeCoefficient > upperBound.forceCloseVarianceFeeCoefficient ||
        _varianceFeeParams.skewAdjustmentCoefficient < lowerBound.skewAdjustmentCoefficient ||
        _varianceFeeParams.skewAdjustmentCoefficient > upperBound.skewAdjustmentCoefficient ||
        _varianceFeeParams.referenceSkew < lowerBound.referenceSkew ||
        _varianceFeeParams.referenceSkew > upperBound.referenceSkew ||
        _varianceFeeParams.minimumStaticSkewAdjustment < lowerBound.minimumStaticSkewAdjustment ||
        _varianceFeeParams.minimumStaticSkewAdjustment > upperBound.minimumStaticSkewAdjustment ||
        _varianceFeeParams.vegaCoefficient < lowerBound.vegaCoefficient ||
        _varianceFeeParams.vegaCoefficient > upperBound.vegaCoefficient ||
        _varianceFeeParams.minimumStaticVega < lowerBound.minimumStaticVega ||
        _varianceFeeParams.minimumStaticVega > upperBound.minimumStaticVega ||
        _varianceFeeParams.ivVarianceCoefficient < lowerBound.ivVarianceCoefficient ||
        _varianceFeeParams.ivVarianceCoefficient > upperBound.ivVarianceCoefficient ||
        _varianceFeeParams.minimumStaticIvVariance < lowerBound.minimumStaticIvVariance ||
        _varianceFeeParams.minimumStaticIvVariance > upperBound.minimumStaticIvVariance
      ) {
        revert OMPGW_VarianceFeeParamsOutOfBounds(_varianceFeeParams);
      }
    }

    optionMarketPricer.setVarianceFeeParams(_varianceFeeParams);

    emit OMPGW_VarianceFeeParamsSet(msg.sender, _varianceFeeParams);
  }

  ///////////
  // Views //
  ///////////
  function getOptionMarketPricerBounds() external view returns (OptionMarketPricerBounds memory bounds) {
    return optionMarketPricerBounds;
  }

  ////////////
  // Events //
  ////////////
  event OMPGW_OptionMarketPricerBoundsSet(OptionMarketPricerBounds optionMarketPricerBounds);

  event OMPGW_TradeLimitParamsSet(address indexed caller, OptionMarketPricer.TradeLimitParameters tradeLimitParams);

  event OMPGW_VarianceFeeParamsSet(address indexed caller, OptionMarketPricer.VarianceFeeParameters varianceFeeParams);

  event OMPGW_PricingParamsSet(address indexed caller, OptionMarketPricer.PricingParameters pricingParams);
  event OMPGW_OptionMarketPricerSet(OptionMarketPricer optionMarketPricer);

  ////////////
  // Errors //
  ////////////
  error OMPGW_OptionMarketPricerAlreadySet(OptionMarketPricer optionMarketPricer);

  error OMPGW_VarianceFeeParamsOutOfBounds(OptionMarketPricer.VarianceFeeParameters _varianceFeeParams);

  error OMPGW_TradeLimitParamsOutOfBounds(OptionMarketPricer.TradeLimitParameters _tradeLimitParams);

  error OMPGW_PricingParamsOutOfBounds(OptionMarketPricer.PricingParameters _pricingParams);
}
