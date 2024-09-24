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

// Libraries
import "../../synthetix/DecimalMath.sol";

// Inherited
import "../../synthetix/Owned.sol";

// Interfaces
import "../../OptionMarket.sol";
import "../../OptionToken.sol";
import "../../LiquidityPool.sol";
import "../../LiquidityToken.sol";
import "../../interfaces/ICurve.sol";
import "../../interfaces/IFeeCounter.sol";
import "../../interfaces/IERC20Decimals.sol";
import "../../interfaces/IWETH.sol";

/**
 * @title OptionMarketWrapper
 * @author Lyra
 * @dev Allows users to open/close positions in any market with multiple stablecoins
 */
contract OptionMarketWrapperWithSwaps is Owned {
  using DecimalMath for uint;

  ///////////////////
  // Internal Data //
  ///////////////////

  struct OptionMarketContracts {
    IERC20Decimals quoteAsset;
    IERC20Decimals baseAsset;
    OptionToken optionToken;
    LiquidityPool liquidityPool;
    LiquidityToken liquidityToken;
  }

  struct OptionPositionParams {
    OptionMarket optionMarket;
    uint strikeId; // The id of the relevant OptionListing
    uint positionId;
    uint iterations;
    uint setCollateralTo;
    uint currentCollateral;
    OptionMarket.OptionType optionType; // Is the trade a long/short & call/put?
    uint amount; // The amount the user has requested to close
    uint minCost; // Min amount for the cost of the trade
    uint maxCost; // Max amount for the cost of the trade
    uint inputAmount; // Amount of stable coins the user can use
    IERC20Decimals inputAsset; // Address of coin user wants to open with
  }

  struct ReturnDetails {
    address market;
    uint positionId;
    address owner;
    uint amount;
    uint totalCost;
    uint totalFee;
    int swapFee;
    address token;
  }

  struct StableAssetView {
    uint8 id;
    address token;
    uint8 decimals;
    string symbol;
    uint balance;
    uint allowance;
  }

  struct MarketAssetView {
    uint8 id;
    OptionMarket market;
    address token;
    uint8 decimals;
    string symbol;
    uint balance;
    uint allowance;
    bool isApprovedForAll;
  }

  struct LiquidityBalanceAndAllowance {
    address token;
    uint balance;
    uint allowance;
  }

  ///////////////
  // Variables //
  ///////////////
  IWETH public weth;
  ICurve public curveSwap;
  IFeeCounter public tradingRewards;
  uint public minReturnPercent = 9.8e17;
  uint8[] public ercIds;
  mapping(uint8 => IERC20Decimals) public idToERC;
  uint8[] public marketIds;
  mapping(uint8 => OptionMarket) public idToMarket;
  mapping(OptionMarket => OptionMarketContracts) public marketContracts;

  // Assume these can't change, so if cached, assume value is correct
  mapping(IERC20Decimals => uint8) internal cachedDecimals;
  mapping(IERC20Decimals => string) internal cachedSymbol;

  constructor() Owned() {}

  /**
   * @dev Initialises the contract
   *
   * @param _curveSwap The Curve contract address
   */
  function updateContractParams(
    IWETH _weth,
    ICurve _curveSwap,
    IFeeCounter _tradingRewards,
    uint _minReturnPercent
  ) external onlyOwner {
    weth = _weth;
    curveSwap = _curveSwap;
    tradingRewards = _tradingRewards;
    minReturnPercent = _minReturnPercent;
    emit WrapperParamsUpdated(_curveSwap, _tradingRewards, _minReturnPercent);
  }

  /////////////////////
  // Admin functions //
  /////////////////////

  /**
   * @dev Adds stablecoin with desired index reflected in the curve contract
   *
   * @param token Address of the stablecoin
   * @param id Desired id to set the stablecoin
   */
  function addCurveStable(IERC20Decimals token, uint8 id) external onlyOwner {
    _approveAsset(token, address(curveSwap));
    for (uint i = 0; i < ercIds.length; ++i) {
      if (idToERC[ercIds[i]] == token || ercIds[i] == id) {
        revert DuplicateEntry(address(this), id, address(token));
      }
    }
    ercIds.push(id);
    idToERC[id] = token;

    cachedDecimals[token] = token.decimals();
    cachedSymbol[token] = token.symbol();
  }

  function removeCurveStable(uint8 id) external onlyOwner {
    uint index = 0;
    bool found = false;
    for (uint i = 0; i < ercIds.length; ++i) {
      if (ercIds[i] == id) {
        index = i;
        found = true;
        break;
      }
    }
    if (!found) {
      revert RemovingInvalidId(address(this), id);
    }
    ercIds[index] = ercIds[ercIds.length - 1];
    ercIds.pop();
    delete idToERC[id];
  }

  function addMarket(
    OptionMarket optionMarket,
    uint8 id,
    OptionMarketContracts memory _marketContracts
  ) external onlyOwner {
    marketContracts[optionMarket] = _marketContracts;

    _approveAsset(marketContracts[optionMarket].quoteAsset, address(optionMarket));
    _approveAsset(marketContracts[optionMarket].baseAsset, address(optionMarket));

    for (uint i = 0; i < marketIds.length; ++i) {
      if (idToMarket[marketIds[i]] == optionMarket || marketIds[i] == id) {
        revert DuplicateEntry(address(this), id, address(optionMarket));
      }
    }

    cachedDecimals[_marketContracts.baseAsset] = _marketContracts.baseAsset.decimals();
    cachedSymbol[_marketContracts.baseAsset] = _marketContracts.baseAsset.symbol();

    marketIds.push(id);
    idToMarket[id] = optionMarket;
  }

  function removeMarket(uint8 id) external onlyOwner {
    uint index = 0;
    bool found = false;
    for (uint i = 0; i < marketIds.length; ++i) {
      if (marketIds[i] == id) {
        index = i;
        found = true;
        break;
      }
    }
    if (!found) {
      revert RemovingInvalidId(address(this), id);
    }
    marketIds[index] = marketIds[marketIds.length - 1];
    marketIds.pop();
    delete marketContracts[idToMarket[id]];
    delete idToMarket[id];
  }

  function returnEth(address _to) external onlyOwner {
    uint balance = address(this).balance;
    if (balance == 0) revert InsufficientEth(address(this), 0, 0);
    payable(_to).transfer(balance);
  }

  ////////////////////
  // User functions //
  ////////////////////

  function openPosition(
    OptionPositionParams memory params
  ) external payable returns (ReturnDetails memory returnDetails) {
    return _openPosition(params);
  }

  function closePosition(
    OptionPositionParams memory params
  ) external payable returns (ReturnDetails memory returnDetails) {
    return _closePosition(params, false);
  }

  function forceClosePosition(
    OptionPositionParams memory params
  ) external payable returns (ReturnDetails memory returnDetails) {
    return _closePosition(params, true);
  }

  function addEthCollateral(OptionMarket optionMarket, uint positionId) external payable {
    _wrapETH(msg.value);
    marketContracts[optionMarket].baseAsset.approve(address(optionMarket), msg.value);
    optionMarket.addCollateral(positionId, msg.value);
  }

  //////////////
  // Internal //
  //////////////

  /**
   * @dev Attempts to open positions within bounds, reverts if the returned amount is outside of the accepted bounds.
   *
   * @param params The params required to open a position
   */
  function _openPosition(OptionPositionParams memory params) internal returns (ReturnDetails memory returnDetails) {
    OptionMarketContracts memory c = marketContracts[params.optionMarket];
    bool useOtherStable = params.inputAsset != c.quoteAsset;
    int swapFee = 0;

    if (params.positionId != 0) {
      c.optionToken.transferFrom(msg.sender, address(this), params.positionId);
    }

    _transferBaseCollateral(params.optionType, params.currentCollateral, params.setCollateralTo, c.baseAsset);

    if (params.optionType != OptionMarket.OptionType.SHORT_CALL_BASE) {
      // You want to take outstanding collateral - minCost from user (should be inputAmount)
      _transferAsset(params.inputAsset, msg.sender, address(this), params.inputAmount);

      if (useOtherStable && params.inputAmount != 0) {
        uint expected;
        if (!_isLong(params.optionType)) {
          uint collateralBalanceAfterTrade = params.currentCollateral + params.minCost;
          if (params.setCollateralTo > collateralBalanceAfterTrade) {
            expected = params.setCollateralTo - collateralBalanceAfterTrade;
          }
        } else {
          expected = params.maxCost;
        }
        if (expected > 0) {
          (, swapFee) = _swapWithCurve(params.inputAsset, c.quoteAsset, params.inputAmount, expected, address(this));
        }
      }
    }

    // open position
    OptionMarket.TradeInputParameters memory tradeParameters = _composeTradeParams(params);
    OptionMarket.Result memory result = params.optionMarket.openPosition(tradeParameters);

    // Increments trading rewards contract
    _incrementTradingRewards(
      address(params.optionMarket),
      msg.sender,
      tradeParameters.amount,
      result.totalCost,
      result.totalFee
    );

    int addSwapFee = 0;
    (, addSwapFee) = _returnQuote(c.quoteAsset, params.inputAsset);
    swapFee += addSwapFee;

    _returnBase(c.baseAsset, c.optionToken, result.positionId);

    returnDetails = _getReturnDetails(params, result, swapFee);
    _emitEvent(returnDetails, true, _isLong(params.optionType));
  }

  /**
   * @dev Attempts to close some amount of an open position within bounds, reverts if the returned amount is outside of
   * the accepted bounds.
   *
   * @param params The params required to open a position
   */
  function _closePosition(
    OptionPositionParams memory params,
    bool forceClose
  ) internal returns (ReturnDetails memory returnDetails) {
    OptionMarketContracts memory c = marketContracts[params.optionMarket];
    bool useOtherStable = address(params.inputAsset) != address(c.quoteAsset);
    int swapFee = 0;

    c.optionToken.transferFrom(msg.sender, address(this), params.positionId);

    _transferBaseCollateral(params.optionType, params.currentCollateral, params.setCollateralTo, c.baseAsset);

    if (!_isLong(params.optionType)) {
      _transferAsset(params.inputAsset, msg.sender, address(this), params.inputAmount);
      if (useOtherStable) {
        uint expected = params.maxCost;
        if (params.optionType != OptionMarket.OptionType.SHORT_CALL_BASE) {
          uint collateralBalanceAfterTrade = params.maxCost > params.currentCollateral
            ? 0
            : params.currentCollateral - params.maxCost;
          if (params.setCollateralTo > collateralBalanceAfterTrade) {
            expected = params.setCollateralTo - collateralBalanceAfterTrade;
          } else if (!_isLong(params.optionType)) {
            expected = 0;
          }
        }
        if (expected > 0) {
          (, swapFee) = _swapWithCurve(params.inputAsset, c.quoteAsset, params.inputAmount, expected, address(this));
        }
      }
    }

    OptionMarket.TradeInputParameters memory tradeParameters = _composeTradeParams(params);
    OptionMarket.Result memory result;
    if (forceClose) {
      result = params.optionMarket.forceClosePosition(tradeParameters);
    } else {
      result = params.optionMarket.closePosition(tradeParameters);
    }

    // increments the fee counter for the user.
    _incrementTradingRewards(
      address(params.optionMarket),
      msg.sender,
      tradeParameters.amount,
      result.totalCost,
      result.totalFee
    );

    int addSwapFee;
    (, addSwapFee) = _returnQuote(c.quoteAsset, params.inputAsset);
    swapFee += addSwapFee;

    _returnBase(c.baseAsset, c.optionToken, result.positionId);

    returnDetails = _getReturnDetails(params, result, swapFee);
    _emitEvent(returnDetails, false, _isLong(params.optionType));
  }

  function _getReturnDetails(
    OptionPositionParams memory params,
    OptionMarket.Result memory result,
    int swapFee
  ) internal view returns (ReturnDetails memory) {
    return
      ReturnDetails({
        market: address(params.optionMarket),
        positionId: result.positionId,
        owner: msg.sender,
        amount: params.amount,
        totalCost: result.totalCost,
        totalFee: result.totalFee,
        swapFee: swapFee,
        token: address(params.inputAsset)
      });
  }

  //////////
  // Misc //
  //////////

  function getMarketAndErcIds() public view returns (uint8[] memory, uint8[] memory) {
    return (marketIds, ercIds);
  }

  /**
   * @dev Returns addresses, balances and allowances of all supported tokens for a list of markets
   *
   * @param owner Owner of tokens
   */
  function getBalancesAndAllowances(
    address owner
  ) external view returns (StableAssetView[] memory, MarketAssetView[] memory, LiquidityBalanceAndAllowance[] memory) {
    uint ercIdsLength = ercIds.length;
    StableAssetView[] memory stableBalances = new StableAssetView[](ercIdsLength);
    for (uint i = 0; i < ercIdsLength; ++i) {
      IERC20Decimals token = idToERC[ercIds[i]];
      stableBalances[i] = StableAssetView({
        id: ercIds[i],
        decimals: cachedDecimals[token],
        symbol: cachedSymbol[token],
        token: address(token),
        balance: token.balanceOf(owner),
        allowance: token.allowance(owner, address(this))
      });
    }
    uint marketIdsLength = marketIds.length;
    MarketAssetView[] memory marketBalances = new MarketAssetView[](marketIdsLength);
    LiquidityBalanceAndAllowance[] memory liquidityTokenBalances = new LiquidityBalanceAndAllowance[](marketIdsLength);
    for (uint i = 0; i < marketIdsLength; ++i) {
      OptionMarket market = idToMarket[marketIds[i]];
      OptionMarketContracts memory c = marketContracts[market];
      marketBalances[i] = MarketAssetView({
        id: marketIds[i],
        market: market,
        token: address(c.baseAsset),
        decimals: cachedDecimals[c.baseAsset],
        symbol: cachedSymbol[c.baseAsset],
        balance: c.baseAsset.balanceOf(owner),
        allowance: c.baseAsset.allowance(owner, address(this)),
        isApprovedForAll: c.optionToken.isApprovedForAll(owner, address(this))
      });
      liquidityTokenBalances[i].balance = c.liquidityToken.balanceOf(owner);
      liquidityTokenBalances[i].allowance = c.quoteAsset.allowance(owner, address(c.liquidityPool));
      liquidityTokenBalances[i].token = address(c.liquidityPool);
    }
    return (stableBalances, marketBalances, liquidityTokenBalances);
  }

  /**
   * @dev Returns quote back in the desired stablecoin
   *
   * @param inputAsset Stablecoin to be returned
   */
  function _returnQuote(
    IERC20Decimals quoteAsset,
    IERC20Decimals inputAsset
  ) internal returns (uint quoteBalance, int swapFee) {
    quoteBalance = quoteAsset.balanceOf(address(this));

    if (quoteBalance > 0) {
      if (inputAsset != quoteAsset) {
        uint min = (minReturnPercent * 10 ** cachedDecimals[inputAsset]) / 10 ** cachedDecimals[quoteAsset];
        (, swapFee) = _swapWithCurve(
          quoteAsset,
          inputAsset,
          quoteBalance,
          quoteBalance.multiplyDecimal(min),
          address(this)
        );
        quoteBalance = inputAsset.balanceOf(address(this));
      }
      _transferAsset(inputAsset, address(this), msg.sender, quoteBalance);
    }
  }

  /**
   * @dev Returns excess baseAsset back to user
   *
   * @param baseAsset Base asset to be returned
   * @param token OptionToken to check if active
   * @param positionId Is the positionId
   */
  function _returnBase(IERC20Decimals baseAsset, OptionToken token, uint positionId) internal {
    uint baseBalance = baseAsset.balanceOf(address(this));
    if (baseBalance > 0) {
      _transferAsset(baseAsset, address(this), msg.sender, baseBalance);
    }

    if (token.getPositionState(positionId) == OptionToken.PositionState.ACTIVE) {
      token.transferFrom(address(this), msg.sender, positionId);
    }
  }

  function _isLong(OptionMarket.OptionType optionType) internal pure returns (bool) {
    return (optionType < OptionMarket.OptionType.SHORT_CALL_BASE);
  }

  /**
   * @dev Attempts to swap the input token with the desired stablecoin.
   *
   * @param from The token being swapped
   * @param to The token being received
   * @param amount Quantity of from being exchanged
   * @param expected Minimum quantity of to received in order for the transaction to succeed
   * @param receiver The receiving address of the tokens
   */
  function _swapWithCurve(
    IERC20Decimals from,
    IERC20Decimals to,
    uint amount,
    uint expected,
    address receiver
  ) internal returns (uint amountOut, int swapFee) {
    _checkValidStable(address(from));
    _checkValidStable(address(to));

    uint8 toDec = cachedDecimals[to];
    uint8 fromDec = cachedDecimals[from];
    uint balStart = from.balanceOf(address(this));

    expected = ConvertDecimals.convertFrom18(expected, IERC20Decimals(to).decimals());
    amountOut = curveSwap.exchange_with_best_rate(address(from), address(to), amount, expected, receiver);

    uint convertedAmtOut = amountOut;
    if (fromDec < toDec) {
      balStart = balStart * 10 ** (toDec - fromDec);
    } else if (fromDec > toDec) {
      convertedAmtOut = amountOut * 10 ** (fromDec - toDec);
    }

    swapFee = SafeCast.toInt256(balStart) - SafeCast.toInt256(convertedAmtOut);
  }

  /// @dev checks if the token is in the stablecoin mapping
  function _checkValidStable(address token) internal view returns (bool) {
    for (uint i = 0; i < ercIds.length; ++i) {
      if (address(idToERC[ercIds[i]]) == token) {
        return true;
      }
    }
    revert UnsupportedToken(token);
  }

  /// @dev returns amount of toToken after a swap
  /// @param amountIn the amount of input tokens for the swap
  /// @return pool the address of the swap pool
  /// @return amountOut the amount of output tokens for the swap
  function quoteCurveSwap(
    address fromToken,
    address toToken,
    uint amountIn
  ) external view returns (address pool, uint amountOut) {
    _checkValidStable(fromToken);
    _checkValidStable(toToken);

    (pool, amountOut) = curveSwap.get_best_rate(fromToken, toToken, amountIn);
  }

  function _transferBaseCollateral(
    OptionMarket.OptionType optionType,
    uint currentCollateral,
    uint setCollateralTo,
    IERC20Decimals baseAsset
  ) internal {
    if (optionType == OptionMarket.OptionType.SHORT_CALL_BASE && setCollateralTo > currentCollateral) {
      uint amount = setCollateralTo - currentCollateral;

      // If user wants to use ETH, wrap it first
      if (address(weth) == address(baseAsset) && msg.value > 0) {
        if (msg.value <= amount) {
          _wrapETH(msg.value);
          if (msg.value < amount) {
            _transferAsset(baseAsset, msg.sender, address(this), amount - msg.value);
          }
        } else if (msg.value > amount) {
          _wrapETH(amount);
          payable(msg.sender).transfer(msg.value - amount);
        } else {
          revert InsufficientEth(address(this), msg.value, amount);
        }
      } else {
        _transferAsset(baseAsset, msg.sender, address(this), amount);
      }
    }
  }

  function _transferAsset(IERC20Decimals asset, address from, address to, uint amount) internal {
    bool success = false;

    if (from == address(this)) {
      success = asset.transfer(to, amount);
    } else {
      success = asset.transferFrom(from, to, amount);
    }

    if (!success) {
      revert AssetTransferFailed(address(this), asset, from, to, amount);
    }
  }

  function _approveAsset(IERC20Decimals asset, address approving) internal {
    // Some contracts require resetting approval to 0 first
    if (!asset.approve(approving, 0)) {
      revert ApprovalFailure(address(this), asset, approving, 0);
    }
    if (!asset.approve(approving, type(uint).max)) {
      revert ApprovalFailure(address(this), asset, approving, type(uint).max);
    }
  }

  function _composeTradeParams(
    OptionPositionParams memory params
  ) internal pure returns (OptionMarket.TradeInputParameters memory tradeParameters) {
    return
      OptionMarket.TradeInputParameters({
        strikeId: params.strikeId,
        positionId: params.positionId,
        iterations: params.iterations,
        optionType: params.optionType,
        amount: params.amount,
        setCollateralTo: params.setCollateralTo,
        minTotalCost: params.minCost,
        maxTotalCost: params.maxCost,
        referrer: address(0)
      });
  }

  function _emitEvent(ReturnDetails memory returnDetails, bool isOpen, bool isLong) internal {
    emit PositionTraded(
      isOpen,
      isLong,
      returnDetails.market,
      returnDetails.positionId,
      returnDetails.owner,
      returnDetails.amount,
      returnDetails.totalCost,
      returnDetails.totalFee,
      returnDetails.swapFee,
      returnDetails.token
    );
  }

  // @dev function increments the trading rewards contract.
  // makes a call to the trading rewards contract
  function _incrementTradingRewards(
    address market,
    address trader,
    uint amount,
    uint totalCost,
    uint totalFee
  ) internal {
    if (address(tradingRewards) != address(0)) {
      tradingRewards.trackFee(market, trader, amount, totalCost, totalFee);
    }
  }

  function _wrapETH(uint amount) internal {
    weth.deposit{value: amount}();
    emit WETHDeposit(msg.sender, amount);
  }

  ////////////
  // Events //
  ////////////

  /**
   * @dev Emitted when a position is traded
   */
  event PositionTraded(
    bool isOpen,
    bool isLong,
    address indexed market,
    uint indexed positionId,
    address indexed owner,
    uint amount,
    uint totalCost,
    uint totalFee,
    int swapFee,
    address token
  );

  /**
   * @dev Emitted when the contract parameters are updated
   */
  event WrapperParamsUpdated(ICurve curveSwap, IFeeCounter tradingRewards, uint minReturnPercent);

  /**
   * @dev Emitted collateral is changed for a position
   */
  event SetCollateralTo(uint newCollateral);

  /**
   * @dev Emitted when ETH is wrapped
   */
  event WETHDeposit(address sender, uint amount);

  ////////////
  // Errors //
  ////////////

  error AssetTransferFailed(address thrower, IERC20Decimals asset, address sender, address receiver, uint amount);
  error ApprovalFailure(address thrower, IERC20Decimals asset, address approving, uint approvalAmount);
  error DuplicateEntry(address thrower, uint8 id, address addr);
  error RemovingInvalidId(address thrower, uint8 id);
  error UnsupportedToken(address asset);
  error InsufficientEth(address thrower, uint sentAmount, uint requiredAmount);
}
