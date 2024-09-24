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

import "../periphery/LyraAdapter.sol";

contract TestLyraAdapter is LyraAdapter {
  constructor() {}

  function setLyraAddressesExt(
    address _lyraRegistry,
    address _optionMarket,
    address _curveSwap,
    address _feeCounter
  ) external onlyOwner {
    setLyraAddresses(_lyraRegistry, _optionMarket, _curveSwap, _feeCounter);
  }

  function openPositionExt(TradeInputParameters memory params) external returns (TradeResult memory result) {
    result = _openPosition(params);
  }

  function closePositionExt(TradeInputParameters memory params) external returns (TradeResult memory result) {
    result = _closePosition(params);
  }

  function forceClosePositionExt(TradeInputParameters memory params) external returns (TradeResult memory result) {
    result = _forceClosePosition(params);
  }

  function closeOrForceClosePosition(TradeInputParameters memory params) external returns (TradeResult memory result) {
    result = _closeOrForceClosePosition(params);
  }

  function splitPositionExt(
    uint positionId,
    uint newAmount,
    uint newCollateral,
    address recipient
  ) external returns (uint newPositionId) {
    newPositionId = _splitPosition(positionId, newAmount, newCollateral, recipient);
  }

  function mergePositionsExt(uint[] memory positionIds) external {
    _mergePositions(positionIds);
  }

  function exchangeFromExactQuoteExt(uint amountQuote, uint minBaseReceived) external returns (uint baseReceived) {
    baseReceived = _exchangeFromExactQuote(amountQuote, minBaseReceived);
  }

  function exchangeToExactQuoteExt(uint amountQuote, uint maxBaseUsed) external returns (uint quoteReceived) {
    quoteReceived = _exchangeToExactQuote(amountQuote, maxBaseUsed);
  }

  function exchangeFromExactBaseExt(uint amountBase, uint minQuoteReceived) external returns (uint quoteReceived) {
    quoteReceived = _exchangeFromExactBase(amountBase, minQuoteReceived);
  }

  function exchangeToExactBaseExt(uint amountBase, uint maxQuoteUsed) external returns (uint baseReceived) {
    baseReceived = _exchangeToExactBase(amountBase, maxQuoteUsed);
  }

  function swapStablesExt(
    address from,
    address to,
    uint amount,
    uint expected,
    address receiver
  ) external returns (uint amountOut) {
    amountOut = _swapStables(from, to, amount, expected, receiver);
  }

  function getBoardExt(uint boardId) external view returns (Board memory board) {
    board = _getBoard(boardId);
  }

  function getStrikesExt(uint[] memory strikeIds) external view returns (Strike[] memory allStrikes) {
    allStrikes = _getStrikes(strikeIds);
  }

  function getVolsExt(uint[] memory strikeIds) external view returns (uint[] memory vols) {
    vols = _getVols(strikeIds);
  }

  function getDeltasExt(uint[] memory strikeIds) external view returns (int[] memory callDeltas) {
    callDeltas = _getDeltas(strikeIds);
  }

  function getVegasExt(uint[] memory strikeIds) external view returns (uint[] memory vegas) {
    vegas = _getVegas(strikeIds);
  }

  function getPurePremiumExt(
    uint secondsToExpiry,
    uint vol,
    uint spotPrice,
    uint strikePrice
  ) external view returns (uint call, uint put) {
    (call, put) = _getPurePremium(secondsToExpiry, vol, spotPrice, strikePrice);
  }

  function getPurePremiumForStrikeExt(uint strikeId) external view returns (uint call, uint put) {
    (call, put) = _getPurePremiumForStrike(strikeId);
  }

  function getLiquidityExt() external view returns (Liquidity memory liquidity) {
    liquidity = _getLiquidity();
  }

  function getFreeLiquidityExt() external view returns (uint freeLiquidity) {
    freeLiquidity = _getFreeLiquidity();
  }

  function getMarketParamsExt() external view returns (MarketParams memory params) {
    params = _getMarketParams();
  }

  function getExchangeParamsExt() external view returns (ExchangeRateParams memory params) {
    params = _getExchangeParams();
  }

  function getMinCollateralExt(
    OptionType optionType,
    uint strikePrice,
    uint expiry,
    uint spotPrice,
    uint amount
  ) external view returns (uint minCollateral) {
    minCollateral = _getMinCollateral(optionType, strikePrice, expiry, spotPrice, amount);
  }

  function getMinCollateralForPositionExt(uint positionId) external view returns (uint minCollateral) {
    minCollateral = _getMinCollateralForPosition(positionId);
  }

  function getMinCollateralForStrikeExt(
    OptionType optionType,
    uint strikeId,
    uint amount
  ) external view returns (uint minCollateral) {
    minCollateral = _getMinCollateralForStrike(optionType, strikeId, amount);
  }

  function getPositionsExt(uint[] memory positionIds) external view returns (OptionPosition[] memory allPositions) {
    allPositions = _getPositions(positionIds);
  }

  function getLiveBoardsExt() external view returns (uint[] memory liveBoards) {
    liveBoards = _getLiveBoards();
  }

  /// @notice the `baseIv` GWAV for a given `boardId` with GWAV interval `secondsAgo`
  function ivGWAV(uint boardId, uint secondsAgo) external view returns (uint) {
    return _ivGWAV(boardId, secondsAgo);
  }

  /// @notice the volatility `skew` GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function skewGWAV(uint strikeId, uint secondsAgo) external view returns (uint) {
    return _skewGWAV(strikeId, secondsAgo);
  }

  /// @notice the resultant volatility =`skew` * 'baseIv' for a given `strikeId` with GWAV interval `secondsAgo`
  function volGWAV(uint strikeId, uint secondsAgo) external view returns (uint) {
    return _volGWAV(strikeId, secondsAgo);
  }

  /// @notice the delta GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function deltaGWAV(uint strikeId, uint secondsAgo) external view returns (int callDelta) {
    return _deltaGWAV(strikeId, secondsAgo);
  }

  /// @notice the non-normalized vega GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function vegaGWAV(uint strikeId, uint secondsAgo) external view returns (uint) {
    return _vegaGWAV(strikeId, secondsAgo);
  }

  /// @notice the option price GWAV for a given `strikeId` with GWAV interval `secondsAgo`
  function optionPriceGWAV(uint strikeId, uint secondsAgo) external view returns (uint callPrice, uint putPrice) {
    return _optionPriceGWAV(strikeId, secondsAgo);
  }
}
