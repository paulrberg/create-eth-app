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
  
  // SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "Lyra-Finance/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// Inherited
import "../../BaseGovernanceWrapper.sol";

// Interfaces
import "../../../SNXPerpV2Adapter.sol";
import "../../../interfaces/IUniswapV3Oracle.sol";
import "../../../interfaces/perpsV2/ISystemStatus.sol";

contract SNXAdapterGovernanceWrapper is BaseGovernanceWrapper {
  struct SNXAdapterBoundsParameters {
    SNXPerpV2Adapter.MarketAdapterConfiguration minMarketPricingParams;
    SNXPerpV2Adapter.MarketAdapterConfiguration maxMarketPricingParams;
    int minRiskFreeRate;
    int maxRiskFreeRate;
  }

  SNXPerpV2Adapter public SNXAdapter;
  mapping(OptionMarket => SNXAdapterBoundsParameters) internal SNXAdapterBounds;
  bool public adapterPausingEnabled = true;

  ////////////////
  // Only Owner //
  ////////////////

  /**
   * @param _SNXAdapter the address of the SNX adapter
   */
  function setSNXAdapter(SNXPerpV2Adapter _SNXAdapter) external onlyOwner {
    if (address(SNXAdapter) != address(0)) {
      revert SNXAGW_SNXAdapterAlreadySet(SNXAdapter);
    }
    SNXAdapter = _SNXAdapter;
    SNXAdapter.acceptOwnership();
    emit SNXAGW_SNXAdapterSet(SNXAdapter);
  }

  /**
   * @param enableRiskCouncilPausing whether or not the risk council can pause the adapter
   */
  function enableRiskCouncilAdapterPausing(bool enableRiskCouncilPausing) external onlyOwner {
    adapterPausingEnabled = enableRiskCouncilPausing;
    emit SNXAGW_SNXAdapterPausingSet(enableRiskCouncilPausing);
  }

  /**
   *
   * @param _addressResolver the address of the address resolver contract
   */
  function setAddressResolver(IAddressResolver _addressResolver) external onlyOwner {
    SNXAdapter.setAddressResolver(_addressResolver);
    emit SNXAGW_AddressResolverSet(_addressResolver);
  }

  /**
   * @param _uniSwapRouter the address of the uniswap router
   */
  function setUniSwapRouter(ISwapRouter _uniSwapRouter) external onlyOwner {
    SNXAdapter.setUniswapRouter(_uniSwapRouter);
    emit SNXAGW_UniSwapRouterSet(_uniSwapRouter);
  }

  /**
   * @param _optionMarket the option market that corresponds the adapter the bounds
   * are being set for.
   * @param _SNXAdapterBounds the bounds for the SNX adapter
   */
  function setSNXAdapterBounds(
    OptionMarket _optionMarket,
    SNXAdapterBoundsParameters memory _SNXAdapterBounds
  ) external onlyOwner {
    SNXAdapterBounds[_optionMarket] = _SNXAdapterBounds;
    emit SNXAGW_SNXAdapterBoundsSet(_optionMarket, _SNXAdapterBounds);
  }

  /**
   * @param deviation the deviation for the uniswap oracle for the swap of base assets
   */
  function setUniSwapDeviation(uint deviation) external onlyOwner {
    SNXAdapter.setUniSwapDeviation(deviation);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////

  function setMarketAdapterConfiguration(
    address _optionMarket,
    SNXPerpV2Adapter.MarketAdapterConfiguration memory _marketAdapterConfiguration
  ) external onlyRiskCouncilOrOwner {
    SNXAdapter.setMarketAdapterConfiguration(
      _optionMarket,
      _marketAdapterConfiguration.staticEstimationDiscount,
      _marketAdapterConfiguration.snxPerpV2MarketAddress,
      _marketAdapterConfiguration.uniswapInfo.pool,
      _marketAdapterConfiguration.uniswapInfo.feeTier
    );
  }

  function setMarketPaused(OptionMarket optionMarket, bool isPaused) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil && !adapterPausingEnabled) {
      revert SNXAGW_RiskCouncilCannotPauseMarket(optionMarket);
    }
    SNXAdapter.setMarketPaused(address(optionMarket), isPaused);
  }

  function setRiskFreeRate(OptionMarket _optionMarket, int _rate) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      if (
        _rate > SNXAdapterBounds[_optionMarket].maxRiskFreeRate ||
        _rate < SNXAdapterBounds[_optionMarket].minRiskFreeRate
      ) {
        revert SNXAGW_RiskFreeRateBoundsInvalid(_optionMarket, _rate);
      }
    }
    SNXAdapter.setRiskFreeRate(address(_optionMarket), _rate);
    emit SNXAGW_RiskFreeRateSet(msg.sender, _optionMarket, _rate);
  }

  ///////////
  // Views //
  ///////////
  function getAdapterBounds(OptionMarket market) external view returns (SNXAdapterBoundsParameters memory bounds) {
    return SNXAdapterBounds[market];
  }

  ////////////
  // Events //
  ////////////

  event SNXAGW_SNXAdapterSet(SNXPerpV2Adapter SNXAdapter);
  event SNXAGW_SNXAdapterPausingSet(bool enableRiskCouncilPausing);
  event SNXAGW_AddressResolverSet(IAddressResolver addressResolver);
  event SNXAGW_SNXAdapterBoundsSet(OptionMarket indexed optionMarket, SNXAdapterBoundsParameters SNXAdapterBounds);
  event SNXAGW_OracleUpdate(IUniswapV3Oracle oracle);
  event SNXAGW_RiskFreeRateSet(address indexed caller, OptionMarket indexed optionMarket, int rate);
  event SNXAGW_UniSwapRouterSet(ISwapRouter uniSwapRouter);

  /////////////
  // errors ///
  /////////////

  error SNXAGW_SNXAdapterAlreadySet(SNXPerpV2Adapter SNXAdapter);

  error SNXAGW_RiskCouncilCannotPauseMarket(OptionMarket optionMarket);

  error SNXAGW_RiskCouncilCannotPauseGlobal();

  error SNXAGW_RiskFreeRateBoundsInvalid(OptionMarket optionMarket, int rate);
}
