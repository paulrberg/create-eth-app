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
  
  //SPDX-License-Identifier:ISC
pragma solidity 0.8.16;

// Inherited
import "../synthetix/Owned.sol";
// Interfaces
import "../OptionMarket.sol";
import "../OptionToken.sol";
import "../LiquidityPool.sol";
import "../OptionGreekCache.sol";
import "../OptionMarketPricer.sol";
import "../BaseExchangeAdapter.sol";

/**
 * @title OptionMarketViewer
 * @author Lyra
 * @dev Provides helpful functions for user interfaces
 */
contract OptionMarketViewer is Owned {
  struct MarketsView {
    bool isPaused;
    MarketView[] markets;
  }

  struct MarketView {
    bool isPaused;
    uint spotPrice;
    string quoteSymbol;
    uint quoteDecimals;
    string baseSymbol;
    uint baseDecimals;
    LiquidityPool.Liquidity liquidity;
    OptionMarketAddresses marketAddresses;
    MarketParameters marketParameters;
    OptionGreekCache.NetGreeks globalNetGreeks;
    BoardView[] liveBoards;
  }

  struct MarketParameters {
    OptionMarket.OptionMarketParameters optionMarketParams;
    LiquidityPool.LiquidityPoolParameters lpParams;
    LiquidityPool.CircuitBreakerParameters cbParams;
    OptionGreekCache.GreekCacheParameters greekCacheParams;
    OptionGreekCache.ForceCloseParameters forceCloseParams;
    OptionGreekCache.MinCollateralParameters minCollatParams;
    OptionMarketPricer.PricingParameters pricingParams;
    OptionMarketPricer.TradeLimitParameters tradeLimitParams;
    OptionMarketPricer.VarianceFeeParameters varianceFeeParams;
    OptionToken.PartialCollateralParameters partialCollatParams;
  }

  struct StrikeView {
    uint strikeId;
    uint boardId;
    uint strikePrice;
    uint skew;
    uint forceCloseSkew;
    OptionGreekCache.StrikeGreeks cachedGreeks;
    uint baseReturnedRatio;
    uint longCallOpenInterest;
    uint longPutOpenInterest;
    uint shortCallBaseOpenInterest;
    uint shortCallQuoteOpenInterest;
    uint shortPutOpenInterest;
  }

  struct BoardView {
    address market;
    uint boardId;
    uint expiry;
    uint baseIv;
    uint priceAtExpiry;
    bool isPaused;
    uint varianceGwavIv;
    uint forceCloseGwavIv;
    uint longScaleFactor;
    OptionGreekCache.NetGreeks netGreeks;
    StrikeView[] strikes;
  }

  struct MarketOptionPositions {
    address market;
    OptionToken.OptionPosition[] positions;
  }

  struct OptionMarketAddresses {
    LiquidityPool liquidityPool;
    LiquidityToken liquidityToken;
    OptionGreekCache greekCache;
    OptionMarket optionMarket;
    OptionMarketPricer optionMarketPricer;
    OptionToken optionToken;
    ShortCollateral shortCollateral;
    PoolHedger poolHedger;
    IERC20Decimals quoteAsset;
    IERC20Decimals baseAsset;
  }

  struct LiquidityBalance {
    IERC20Decimals quoteAsset;
    uint quoteBalance;
    string quoteSymbol;
    uint quoteDepositAllowance;
    LiquidityToken liquidityToken;
    uint liquidityBalance;
  }

  BaseExchangeAdapter public exchangeAdapter;
  bool public initialized = false;
  OptionMarket[] public optionMarkets;
  mapping(OptionMarket => OptionMarketAddresses) public marketAddresses;

  constructor() Owned() {}

  /**
   * @dev Initializes the contract
   * @param _exchangeAdapter BaseExchangeAdapter contract address
   */
  function init(BaseExchangeAdapter _exchangeAdapter) external {
    require(!initialized, "already initialized");
    exchangeAdapter = _exchangeAdapter;
    initialized = true;
  }

  function addMarket(OptionMarketAddresses memory newMarketAddresses) external onlyOwner {
    optionMarkets.push(newMarketAddresses.optionMarket);
    marketAddresses[newMarketAddresses.optionMarket] = newMarketAddresses;
    emit MarketAdded(newMarketAddresses);
  }

  function removeMarket(OptionMarket market) external onlyOwner {
    uint index = 0;
    bool found = false;

    uint marketsLength = optionMarkets.length;
    for (uint i = 0; i < marketsLength; ++i) {
      if (optionMarkets[i] == market) {
        index = i;
        found = true;
        break;
      }
    }
    if (!found) {
      revert RemovingInvalidMarket(address(this), address(market));
    }
    optionMarkets[index] = optionMarkets[optionMarkets.length - 1];
    optionMarkets.pop();

    emit MarketRemoved(market);
    delete marketAddresses[market];
  }

  function getMarketAddresses() external view returns (OptionMarketAddresses[] memory) {
    uint marketsLen = optionMarkets.length;
    OptionMarketAddresses[] memory allMarketAddresses = new OptionMarketAddresses[](marketsLen);
    for (uint i = 0; i < marketsLen; ++i) {
      allMarketAddresses[i] = marketAddresses[optionMarkets[i]];
    }
    return allMarketAddresses;
  }

  function getMarkets(OptionMarket[] memory markets) external view returns (MarketsView memory marketsView) {
    uint marketsLen = markets.length;
    MarketView[] memory marketViews = new MarketView[](marketsLen);
    bool isGlobalPaused = exchangeAdapter.isGlobalPaused();
    for (uint i = 0; i < marketsLen; ++i) {
      OptionMarketAddresses memory marketC = marketAddresses[markets[i]];
      marketViews[i] = _getMarketView(marketC, isGlobalPaused);
    }
    return MarketsView({isPaused: isGlobalPaused, markets: marketViews});
  }

  function getMarketForBase(string memory baseSymbol) public view returns (MarketView memory marketView) {
    for (uint i = 0; i < optionMarkets.length; ++i) {
      OptionMarketAddresses memory marketC = marketAddresses[optionMarkets[i]];
      string memory marketBaseSymbol = marketC.baseAsset.symbol();
      if (keccak256(bytes(baseSymbol)) == keccak256(bytes(marketBaseSymbol))) {
        marketView = getMarket(marketC.optionMarket);
        break;
      }
    }
    require(address(marketView.marketAddresses.optionMarket) != address(0), "No market for base key");
    return marketView;
  }

  function getMarket(OptionMarket market) public view returns (MarketView memory marketView) {
    OptionMarketAddresses memory marketC = marketAddresses[market];
    bool isGlobalPaused = exchangeAdapter.isGlobalPaused();
    marketView = _getMarketView(marketC, isGlobalPaused);
    return marketView;
  }

  function _getMarketView(
    OptionMarketAddresses memory marketC,
    bool isGlobalPaused
  ) internal view returns (MarketView memory) {
    OptionGreekCache.GlobalCache memory globalCache = marketC.greekCache.getGlobalCache();
    MarketParameters memory marketParameters = _getMarketParams(marketC);
    bool isMarketPaused = exchangeAdapter.isMarketPaused(address(marketC.optionMarket));
    uint spotPrice = 0;
    LiquidityPool.Liquidity memory liquidity = LiquidityPool.Liquidity({
      freeLiquidity: 0,
      burnableLiquidity: 0,
      reservedCollatLiquidity: 0,
      pendingDeltaLiquidity: 0,
      usedDeltaLiquidity: 0,
      NAV: 0,
      longScaleFactor: 0
    });
    if (!isGlobalPaused && !isMarketPaused) {
      spotPrice = exchangeAdapter.getSpotPriceForMarket(
        address(marketC.optionMarket),
        BaseExchangeAdapter.PriceType.REFERENCE
      );
      liquidity = marketC.liquidityPool.getLiquidity();
    }
    string memory quoteSymbol = marketC.quoteAsset.symbol();
    uint quoteDecimals = marketC.quoteAsset.decimals();
    string memory baseSymbol = marketC.baseAsset.symbol();
    uint baseDecimals = marketC.baseAsset.decimals();
    return
      MarketView({
        isPaused: isMarketPaused || isGlobalPaused,
        spotPrice: spotPrice,
        quoteSymbol: quoteSymbol,
        quoteDecimals: quoteDecimals,
        baseSymbol: baseSymbol,
        baseDecimals: baseDecimals,
        liquidity: liquidity,
        marketAddresses: marketC,
        marketParameters: marketParameters,
        globalNetGreeks: globalCache.netGreeks,
        liveBoards: getLiveBoards(marketC.optionMarket)
      });
  }

  function _getMarketParams(
    OptionMarketAddresses memory marketC
  ) internal view returns (MarketParameters memory params) {
    return
      MarketParameters({
        optionMarketParams: marketC.optionMarket.getOptionMarketParams(),
        lpParams: marketC.liquidityPool.getLpParams(),
        cbParams: marketC.liquidityPool.getCBParams(),
        greekCacheParams: marketC.greekCache.getGreekCacheParams(),
        forceCloseParams: marketC.greekCache.getForceCloseParams(),
        minCollatParams: marketC.greekCache.getMinCollatParams(),
        pricingParams: marketC.optionMarketPricer.getPricingParams(),
        tradeLimitParams: marketC.optionMarketPricer.getTradeLimitParams(),
        varianceFeeParams: marketC.optionMarketPricer.getVarianceFeeParams(),
        partialCollatParams: marketC.optionToken.getPartialCollatParams()
      });
  }

  function getOwnerPositions(address account) external view returns (MarketOptionPositions[] memory) {
    uint optionMarketLen = optionMarkets.length;
    MarketOptionPositions[] memory positions = new MarketOptionPositions[](optionMarketLen);
    for (uint i = 0; i < optionMarketLen; ++i) {
      OptionMarketAddresses memory marketC = marketAddresses[optionMarkets[i]];
      positions[i].market = address(marketC.optionMarket);
      positions[i].positions = marketC.optionToken.getOwnerPositions(account);
    }
    return positions;
  }

  // Get live boards for the chosen market
  function getLiveBoards(OptionMarket market) public view returns (BoardView[] memory marketBoards) {
    OptionMarketAddresses memory marketC = marketAddresses[market];
    uint[] memory liveBoards = marketC.optionMarket.getLiveBoards();
    uint liveBoardsLen = liveBoards.length;
    marketBoards = new BoardView[](liveBoardsLen);
    for (uint i = 0; i < liveBoardsLen; ++i) {
      marketBoards[i] = _getBoard(marketC, liveBoards[i]);
    }
  }

  // Get single board for market based on boardId
  function getBoard(OptionMarket market, uint boardId) external view returns (BoardView memory) {
    OptionMarketAddresses memory marketC = marketAddresses[market];
    return _getBoard(marketC, boardId);
  }

  function getBoardForBase(string memory baseSymbol, uint boardId) external view returns (BoardView memory) {
    MarketView memory marketView = getMarketForBase(baseSymbol);
    return _getBoard(marketView.marketAddresses, boardId);
  }

  function getBoardForStrikeId(OptionMarket market, uint strikeId) external view returns (BoardView memory) {
    OptionMarketAddresses memory marketC = marketAddresses[market];
    OptionMarket.Strike memory strike = marketC.optionMarket.getStrike(strikeId);
    return _getBoard(marketC, strike.boardId);
  }

  function _getBoard(OptionMarketAddresses memory marketC, uint boardId) internal view returns (BoardView memory) {
    (
      OptionMarket.OptionBoard memory board,
      OptionMarket.Strike[] memory strikes,
      uint[] memory strikeToBaseReturnedRatios,
      uint priceAtExpiry,
      uint longScaleFactor
    ) = marketC.optionMarket.getBoardAndStrikeDetails(boardId);
    OptionGreekCache.BoardGreeksView memory boardGreeksView;
    uint varianceGwavIv = 0;
    if (priceAtExpiry == 0) {
      boardGreeksView = marketC.greekCache.getBoardGreeksView(boardId);
      OptionGreekCache.GreekCacheParameters memory greekCacheParams = marketC.greekCache.getGreekCacheParams();
      varianceGwavIv = marketC.greekCache.getIvGWAV(boardId, greekCacheParams.varianceIvGWAVPeriod);
    }
    return
      BoardView({
        boardId: board.id,
        market: address(marketC.optionMarket),
        expiry: board.expiry,
        baseIv: board.iv,
        priceAtExpiry: priceAtExpiry,
        isPaused: board.frozen,
        varianceGwavIv: varianceGwavIv,
        forceCloseGwavIv: boardGreeksView.ivGWAV,
        longScaleFactor: longScaleFactor,
        strikes: _getStrikeViews(strikes, boardGreeksView, strikeToBaseReturnedRatios, priceAtExpiry),
        netGreeks: boardGreeksView.boardGreeks
      });
  }

  function _getStrikeViews(
    OptionMarket.Strike[] memory strikes,
    OptionGreekCache.BoardGreeksView memory boardGreeksView,
    uint[] memory strikeToBaseReturnedRatios,
    uint priceAtExpiry
  ) internal pure returns (StrikeView[] memory strikeViews) {
    uint strikesLen = strikes.length;

    strikeViews = new StrikeView[](strikesLen);
    for (uint i = 0; i < strikesLen; ++i) {
      strikeViews[i] = StrikeView({
        strikePrice: strikes[i].strikePrice,
        skew: strikes[i].skew,
        forceCloseSkew: priceAtExpiry == 0 ? boardGreeksView.skewGWAVs[i] : 0,
        cachedGreeks: priceAtExpiry == 0
          ? boardGreeksView.strikeGreeks[i]
          : OptionGreekCache.StrikeGreeks(0, 0, 0, 0, 0),
        strikeId: strikes[i].id,
        boardId: strikes[i].boardId,
        longCallOpenInterest: strikes[i].longCall,
        longPutOpenInterest: strikes[i].longPut,
        shortCallBaseOpenInterest: strikes[i].shortCallBase,
        shortCallQuoteOpenInterest: strikes[i].shortCallQuote,
        shortPutOpenInterest: strikes[i].shortPut,
        baseReturnedRatio: strikeToBaseReturnedRatios[i]
      });
    }
  }

  function getLiquidityBalances(address account) external view returns (LiquidityBalance[] memory) {
    uint marketsLength = optionMarkets.length;
    LiquidityBalance[] memory balances = new LiquidityBalance[](marketsLength);
    for (uint i = 0; i < marketsLength; ++i) {
      OptionMarketAddresses memory marketC = marketAddresses[optionMarkets[i]];
      balances[i].quoteAsset = marketC.quoteAsset;
      balances[i].quoteSymbol = marketC.quoteAsset.symbol();
      balances[i].quoteBalance = marketC.quoteAsset.balanceOf(account);
      balances[i].quoteDepositAllowance = marketC.quoteAsset.allowance(account, address(marketC.liquidityPool));
      balances[i].liquidityToken = marketC.liquidityToken;
      balances[i].liquidityBalance = marketC.liquidityToken.balanceOf(account);
    }
    return balances;
  }

  /**
   * @dev Emitted when an optionMarket is added
   */
  event MarketAdded(OptionMarketAddresses market);

  /**
   * @dev Emitted when an optionMarket is removed
   */
  event MarketRemoved(OptionMarket market);

  ////////////
  // Errors //
  ////////////
  error RemovingInvalidMarket(address thrower, address market);
}
