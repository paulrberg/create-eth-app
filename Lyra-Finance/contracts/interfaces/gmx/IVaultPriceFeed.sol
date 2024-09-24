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

interface IVaultPriceFeed {
  function PRICE_PRECISION() external view returns (uint);

  function adjustmentBasisPoints(address _token) external view returns (uint);

  function isAdjustmentAdditive(address _token) external view returns (bool);

  function setAdjustment(address _token, bool _isAdditive, uint _adjustmentBps) external;

  function setUseV2Pricing(bool _useV2Pricing) external;

  function setIsAmmEnabled(bool _isEnabled) external;

  function setIsSecondaryPriceEnabled(bool _isEnabled) external;

  function setSpreadBasisPoints(address _token, uint _spreadBasisPoints) external;

  function setSpreadThresholdBasisPoints(uint _spreadThresholdBasisPoints) external;

  function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

  function setPriceSampleSpace(uint _priceSampleSpace) external;

  function setMaxStrictPriceDeviation(uint _maxStrictPriceDeviation) external;

  function getPrice(
    address _token,
    bool _maximise,
    bool _includeAmmPrice,
    bool _useSwapPricing
  ) external view returns (uint);

  function getAmmPrice(address _token) external view returns (uint);

  function getLatestPrimaryPrice(address _token) external view returns (uint);

  function getPrimaryPrice(address _token, bool _maximise) external view returns (uint);

  function setTokenConfig(address _token, address _priceFeed, uint _priceDecimals, bool _isStrictStable) external;
}
