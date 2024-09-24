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

import "./IVaultUtils.sol";

interface IVault {
  function PRICE_PRECISION() external view returns (uint);

  function FUNDING_RATE_PRECISION() external view returns (uint);

  function isInitialized() external view returns (bool);

  function isSwapEnabled() external view returns (bool);

  function isLeverageEnabled() external view returns (bool);

  function setError(uint256 _errorCode, string calldata _error) external;

  function router() external view returns (address);

  function usdg() external view returns (address);

  function gov() external view returns (address);

  function whitelistedTokenCount() external view returns (uint256);

  function maxLeverage() external view returns (uint256);

  function minProfitTime() external view returns (uint256);

  function hasDynamicFees() external view returns (bool);

  function fundingInterval() external view returns (uint256);

  function totalTokenWeights() external view returns (uint256);

  function inManagerMode() external view returns (bool);

  function inPrivateLiquidationMode() external view returns (bool);

  function maxGasPrice() external view returns (uint256);

  function approvedRouters(address _account, address _router) external view returns (bool);

  function isLiquidator(address _account) external view returns (bool);

  function isManager(address _account) external view returns (bool);

  function minProfitBasisPoints(address _token) external view returns (uint256);

  function tokenBalances(address _token) external view returns (uint256);

  function lastFundingTimes(address _token) external view returns (uint256);

  function setInManagerMode(bool _inManagerMode) external;

  function setManager(address _manager, bool _isManager) external;

  function setIsSwapEnabled(bool _isSwapEnabled) external;

  function setIsLeverageEnabled(bool _isLeverageEnabled) external;

  function setMaxGasPrice(uint256 _maxGasPrice) external;

  function setFees(
    uint256 _taxBasisPoints,
    uint256 _stableTaxBasisPoints,
    uint256 _mintBurnFeeBasisPoints,
    uint256 _swapFeeBasisPoints,
    uint256 _stableSwapFeeBasisPoints,
    uint256 _marginFeeBasisPoints,
    uint256 _liquidationFeeUsd,
    uint256 _minProfitTime,
    bool _hasDynamicFees
  ) external;

  function setTokenConfig(
    address _token,
    uint256 _tokenDecimals,
    uint256 _redemptionBps,
    uint256 _minProfitBps,
    uint256 _maxUsdgAmount,
    bool _isStable,
    bool _isShortable
  ) external;

  function setPriceFeed(address _priceFeed) external;

  function withdrawFees(address _token, address _receiver) external returns (uint256);

  function directPoolDeposit(address _token) external;

  function buyUSDG(address _token, address _receiver) external returns (uint256);

  function sellUSDG(address _token, address _receiver) external returns (uint256);

  function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

  function increasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;

  function decreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver
  ) external returns (uint256);

  function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

  function priceFeed() external view returns (address);

  function fundingRateFactor() external view returns (uint256);

  function stableFundingRateFactor() external view returns (uint256);

  function cumulativeFundingRates(address _token) external view returns (uint256);

  function getNextFundingRate(address _token) external view returns (uint256);

  function getFeeBasisPoints(
    address _token,
    uint256 _usdgDelta,
    uint256 _feeBasisPoints,
    uint256 _taxBasisPoints,
    bool _increment
  ) external view returns (uint256);

  function liquidationFeeUsd() external view returns (uint256);

  function taxBasisPoints() external view returns (uint256);

  function stableTaxBasisPoints() external view returns (uint256);

  function mintBurnFeeBasisPoints() external view returns (uint256);

  function swapFeeBasisPoints() external view returns (uint256);

  function stableSwapFeeBasisPoints() external view returns (uint256);

  function marginFeeBasisPoints() external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function whitelistedTokens(address _token) external view returns (bool);

  function stableTokens(address _token) external view returns (bool);

  function shortableTokens(address _token) external view returns (bool);

  function feeReserves(address _token) external view returns (uint256);

  function globalShortSizes(address _token) external view returns (uint256);

  function globalShortAveragePrices(address _token) external view returns (uint256);

  function tokenDecimals(address _token) external view returns (uint256);

  function tokenWeights(address _token) external view returns (uint256);

  function guaranteedUsd(address _token) external view returns (uint256);

  function poolAmounts(address _token) external view returns (uint256);

  function bufferAmounts(address _token) external view returns (uint256);

  function reservedAmounts(address _token) external view returns (uint256);

  function usdgAmounts(address _token) external view returns (uint256);

  function maxUsdgAmounts(address _token) external view returns (uint256);

  function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

  function getMaxPrice(address _token) external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function getDelta(
    address _indexToken,
    uint256 _size,
    uint256 _averagePrice,
    bool _isLong,
    uint256 _lastIncreasedTime
  ) external view returns (bool, uint256);

  function getPosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong
  ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

  function getFundingFee(address _token, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);

  function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

  function getPositionDelta(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong
  ) external view returns (bool, uint256);
}
