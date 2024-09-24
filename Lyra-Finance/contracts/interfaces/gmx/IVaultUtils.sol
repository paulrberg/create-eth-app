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

interface IVaultUtils {
  function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);

  function validateIncreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint _sizeDelta,
    bool _isLong
  ) external view;

  function validateDecreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint _collateralDelta,
    uint _sizeDelta,
    bool _isLong,
    address _receiver
  ) external view;

  function validateLiquidation(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong,
    bool _raise
  ) external view returns (uint, uint);

  function getEntryFundingRate(
    address _collateralToken,
    address _indexToken,
    bool _isLong
  ) external view returns (uint);

  function getPositionFee(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong,
    uint _sizeDelta
  ) external view returns (uint);

  function getFundingFee(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong,
    uint _size,
    uint _entryFundingRate
  ) external view returns (uint);

  function getBuyUsdgFeeBasisPoints(address _token, uint _usdgAmount) external view returns (uint);

  function getSellUsdgFeeBasisPoints(address _token, uint _usdgAmount) external view returns (uint);

  function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint _usdgAmount) external view returns (uint);

  function getFeeBasisPoints(
    address _token,
    uint _usdgDelta,
    uint _feeBasisPoints,
    uint _taxBasisPoints,
    bool _increment
  ) external view returns (uint);
}
