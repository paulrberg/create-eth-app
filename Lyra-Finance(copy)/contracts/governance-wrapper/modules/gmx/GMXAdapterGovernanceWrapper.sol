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

import "../../../GMXAdapter.sol";
import "../../BaseGovernanceWrapper.sol";

contract GMXAdapterGovernanceWrapper is BaseGovernanceWrapper {
  struct GMXAdapterBounds {
    GMXAdapter.MarketPricingParams minMarketPricingParams;
    GMXAdapter.MarketPricingParams maxMarketPricingParams;
    int minRiskFreeRate;
    int maxRiskFreeRate;
  }

  GMXAdapter public gmxAdapter;
  mapping(OptionMarket => GMXAdapterBounds) internal gmxAdapterBounds;
  bool public adapterPausingEnabled = true;

  ////////////////
  // Only Owner //
  ////////////////

  function setGMXAdapter(GMXAdapter _gmxAdapter) external onlyOwner {
    if (address(gmxAdapter) != address(0)) {
      revert GMXAGW_GMXAdapterAlreadySet(gmxAdapter);
    }
    gmxAdapter = _gmxAdapter;
    gmxAdapter.acceptOwnership();
    emit GMXAGW_GMXAdapterSet(_gmxAdapter);
  }

  function enableRiskCouncilAdapterPausing(bool enableRiskCouncilPausing) external onlyOwner {
    adapterPausingEnabled = enableRiskCouncilPausing;
    emit GMXAGW_GMXAdapterPausingSet(enableRiskCouncilPausing);
  }

  function setVaultContract(IVault _vault) external onlyOwner {
    gmxAdapter.setVaultContract(_vault);
    emit GMXAGW_VaultAddressSet(_vault);
  }

  function setChainlinkFeed(address _asset, AggregatorV2V3Interface _assetPriceFeed) external onlyOwner {
    gmxAdapter.setChainlinkFeed(_asset, _assetPriceFeed);
    emit GMXAGW_ChainlinkFeedSet(_asset, _assetPriceFeed);
  }

  function setGMXAdapterBounds(
    OptionMarket _optionMarket,
    GMXAdapterBounds memory _gmxAdapterBounds
  ) external onlyOwner {
    gmxAdapterBounds[_optionMarket] = _gmxAdapterBounds;
    emit GMXAGW_GMXAdapterBoundsSet(_optionMarket, _gmxAdapterBounds);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////

  function setMarketPaused(OptionMarket optionMarket, bool isPaused) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil && !adapterPausingEnabled) {
      revert GMXAGW_RiskCouncilCannotPauseMarket(optionMarket);
    }
    gmxAdapter.setMarketPaused(address(optionMarket), isPaused);
  }

  function setGlobalPaused(bool isPaused) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil && !adapterPausingEnabled) {
      revert GMXAGW_RiskCouncilCannotPauseGlobal();
    }
    gmxAdapter.setGlobalPaused(isPaused);
  }

  function setMarketPricingParams(
    OptionMarket _optionMarket,
    GMXAdapter.MarketPricingParams memory _marketPricingParams
  ) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      GMXAdapter.MarketPricingParams memory lowerBound = gmxAdapterBounds[_optionMarket].minMarketPricingParams;
      GMXAdapter.MarketPricingParams memory upperBound = gmxAdapterBounds[_optionMarket].maxMarketPricingParams;

      if (
        lowerBound.staticSwapFeeEstimate > _marketPricingParams.staticSwapFeeEstimate ||
        upperBound.staticSwapFeeEstimate < _marketPricingParams.staticSwapFeeEstimate ||
        lowerBound.gmxUsageThreshold > _marketPricingParams.gmxUsageThreshold ||
        upperBound.gmxUsageThreshold < _marketPricingParams.gmxUsageThreshold ||
        lowerBound.priceVarianceCBPercent > _marketPricingParams.priceVarianceCBPercent ||
        upperBound.priceVarianceCBPercent < _marketPricingParams.priceVarianceCBPercent ||
        lowerBound.chainlinkStalenessCheck > _marketPricingParams.chainlinkStalenessCheck ||
        upperBound.chainlinkStalenessCheck < _marketPricingParams.chainlinkStalenessCheck
      ) {
        revert GMXAGW_MarketPricingParams(_optionMarket, _marketPricingParams);
      }
    }
    gmxAdapter.setMarketPricingParams(address(_optionMarket), _marketPricingParams);
    emit GMXAGW_MarketPricingParamsSet(msg.sender, _optionMarket, _marketPricingParams);
  }

  function setRiskFreeRate(OptionMarket _optionMarket, int _rate) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      if (
        _rate > gmxAdapterBounds[_optionMarket].maxRiskFreeRate ||
        _rate < gmxAdapterBounds[_optionMarket].minRiskFreeRate
      ) {
        revert GMXAGW_RiskFeeRateBoundsInvalid(_optionMarket, _rate);
      }
    }
    gmxAdapter.setRiskFreeRate(address(_optionMarket), _rate);
    emit GMXAGW_RiskFreeRateSet(msg.sender, _optionMarket, _rate);
  }

  ///////////
  // Views //
  ///////////
  function getAdapterBounds(OptionMarket market) external view returns (GMXAdapterBounds memory bounds) {
    return gmxAdapterBounds[market];
  }

  ////////////
  // Events //
  ////////////

  event GMXAGW_GMXAdapterSet(GMXAdapter gmxAdapter);
  event GMXAGW_GMXAdapterPausingSet(bool enableRiskCouncilPausing);
  event GMXAGW_VaultAddressSet(IVault vault);
  event GMXAGW_ChainlinkFeedSet(address indexed asset, AggregatorV2V3Interface assetPriceFeed);
  event GMXAGW_GMXAdapterBoundsSet(OptionMarket indexed optionMarket, GMXAdapterBounds gmxAdapterBounds);

  event GMXAGW_RiskFreeRateSet(address indexed caller, OptionMarket indexed optionMarket, int rate);
  event GMXAGW_MarketPricingParamsSet(
    address indexed caller,
    OptionMarket indexed optionMarket,
    GMXAdapter.MarketPricingParams marketPricingParams
  );

  /////////////
  // errors ///
  /////////////

  error GMXAGW_GMXAdapterAlreadySet(GMXAdapter gmxAdapter);

  error GMXAGW_RiskCouncilCannotPauseMarket(OptionMarket optionMarket);

  error GMXAGW_RiskCouncilCannotPauseGlobal();

  error GMXAGW_RiskFeeRateBoundsInvalid(OptionMarket optionMarket, int rate);

  error GMXAGW_MarketPricingParams(OptionMarket optionMarket, GMXAdapter.MarketPricingParams marketPricingParams);
}
