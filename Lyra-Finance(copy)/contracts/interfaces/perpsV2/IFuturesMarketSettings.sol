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
  
  pragma solidity 0.8.16;

interface IFuturesMarketSettings {
  struct Parameters {
    uint takerFee;
    uint makerFee;
    uint takerFeeNextPrice;
    uint makerFeeNextPrice;
    uint nextPriceConfirmWindow;
    uint maxLeverage;
    uint maxMarketValueUSD;
    uint maxFundingRate;
    uint skewScaleUSD;
  }

  function takerFee(bytes32 _marketKey) external view returns (uint);

  function makerFee(bytes32 _marketKey) external view returns (uint);

  function takerFeeNextPrice(bytes32 _marketKey) external view returns (uint);

  function makerFeeNextPrice(bytes32 _marketKey) external view returns (uint);

  function nextPriceConfirmWindow(bytes32 _marketKey) external view returns (uint);

  function maxLeverage(bytes32 _marketKey) external view returns (uint);

  function maxMarketValueUSD(bytes32 _marketKey) external view returns (uint);

  function maxFundingRate(bytes32 _marketKey) external view returns (uint);

  function skewScaleUSD(bytes32 _marketKey) external view returns (uint);

  function parameters(
    bytes32 _marketKey
  )
    external
    view
    returns (
      uint _takerFee,
      uint _makerFee,
      uint _takerFeeNextPrice,
      uint _makerFeeNextPrice,
      uint _nextPriceConfirmWindow,
      uint _maxLeverage,
      uint _maxMarketValueUSD,
      uint _maxFundingRate,
      uint _skewScaleUSD
    );

  function minKeeperFee() external view returns (uint);

  function liquidationFeeRatio() external view returns (uint);

  function liquidationBufferRatio() external view returns (uint);

  function minInitialMargin() external view returns (uint);
}
