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

import "./ILiquidityPool.sol";
import "./ISynthetixAdapter.sol";
import "./IOptionMarketPricer.sol";

// For full documentation refer to @lyrafinance/protocol/contracts/OptionMarket.sol";
interface IOptionMarket {
  enum TradeDirection {
    OPEN,
    CLOSE,
    LIQUIDATE
  }

  enum OptionType {
    LONG_CALL,
    LONG_PUT,
    SHORT_CALL_BASE,
    SHORT_CALL_QUOTE,
    SHORT_PUT_QUOTE
  }

  /// @notice For returning more specific errors
  enum NonZeroValues {
    BASE_IV,
    SKEW,
    STRIKE_PRICE,
    ITERATIONS,
    STRIKE_ID
  }

  ///////////////////
  // Internal Data //
  ///////////////////

  struct Strike {
    // strike listing identifier
    uint id;
    // strike price
    uint strikePrice;
    // volatility component specific to the strike listing (boardIv * skew = vol of strike)
    uint skew;
    // total user long call exposure
    uint longCall;
    // total user short call (base collateral) exposure
    uint shortCallBase;
    // total user short call (quote collateral) exposure
    uint shortCallQuote;
    // total user long put exposure
    uint longPut;
    // total user short put (quote collateral) exposure
    uint shortPut;
    // id of board to which strike belongs
    uint boardId;
  }

  struct OptionBoard {
    // board identifier
    uint id;
    // expiry of all strikes belonging to board
    uint expiry;
    // volatility component specific to board (boardIv * skew = vol of strike)
    uint iv;
    // admin settable flag blocking all trading on this board
    bool frozen;
    // list of all strikes belonging to this board
    uint[] strikeIds;
  }

  ///////////////
  // In-memory //
  ///////////////

  struct OptionMarketParameters {
    // max allowable expiry of added boards
    uint maxBoardExpiry;
    // security module address
    address securityModule;
    // fee portion reserved for Lyra DAO
    uint feePortionReserved;
    // expected fee charged to LPs, used for pricing short_call_base settlement
    uint staticBaseSettlementFee;
  }

  struct TradeInputParameters {
    // id of strike
    uint strikeId;
    // OptionToken ERC721 id for position (set to 0 for new positions)
    uint positionId;
    // number of sub-orders to break order into (reduces slippage)
    uint iterations;
    // type of option to trade
    OptionType optionType;
    // number of contracts to trade
    uint amount;
    // final amount of collateral to leave in OptionToken position
    uint setCollateralTo;
    // revert trade if totalCost is below this value
    uint minTotalCost;
    // revert trade if totalCost is above this value
    uint maxTotalCost;
  }

  struct TradeParameters {
    bool isBuy;
    bool isForceClose;
    TradeDirection tradeDirection;
    OptionType optionType;
    uint amount;
    uint expiry;
    uint strikePrice;
    ILiquidityPool.Liquidity liquidity;
    ISynthetixAdapter.ExchangeParams exchangeParams;
  }

  struct TradeEventData {
    uint expiry;
    uint strikePrice;
    OptionType optionType;
    TradeDirection tradeDirection;
    uint amount;
    uint setCollateralTo;
    bool isForceClose;
    uint spotPrice;
    uint reservedFee;
    uint totalCost;
  }

  struct LiquidationEventData {
    address rewardBeneficiary;
    address caller;
    uint returnCollateral; // quote || base
    uint lpPremiums; // quote || base
    uint lpFee; // quote || base
    uint liquidatorFee; // quote || base
    uint smFee; // quote || base
    uint insolventAmount; // quote
  }

  struct Result {
    uint positionId;
    uint totalCost;
    uint totalFee;
  }

  ///////////////
  // Variables //
  ///////////////

  /// @notice claim all reserved option fees
  function smClaim() external;

  ///////////
  // Views //
  ///////////

  function getOptionMarketParams() external view returns (OptionMarketParameters memory);

  function getLiveBoards() external view returns (uint[] memory _liveBoards);

  function getNumLiveBoards() external view returns (uint numLiveBoards);

  function getStrikeAndExpiry(uint strikeId) external view returns (uint strikePrice, uint expiry);

  function getBoardStrikes(uint boardId) external view returns (uint[] memory strikeIds);

  function getStrike(uint strikeId) external view returns (Strike memory);

  function getOptionBoard(uint boardId) external view returns (OptionBoard memory);

  function getStrikeAndBoard(uint strikeId) external view returns (Strike memory, OptionBoard memory);

  function getBoardAndStrikeDetails(
    uint boardId
  ) external view returns (OptionBoard memory, Strike[] memory, uint[] memory, uint);

  ////////////////////
  // User functions //
  ////////////////////

  function openPosition(TradeInputParameters memory params) external returns (Result memory result);

  function closePosition(TradeInputParameters memory params) external returns (Result memory result);

  /**
   * @notice Attempts to reduce or fully close position within cost bounds while ignoring delta trading cutoffs.
   *
   * @param params The parameters for the requested trade
   */
  function forceClosePosition(TradeInputParameters memory params) external returns (Result memory result);

  function addCollateral(uint positionId, uint amountCollateral) external;

  function liquidatePosition(uint positionId, address rewardBeneficiary) external;

  /////////////////////////////////
  // Board Expiry and settlement //
  /////////////////////////////////

  function settleExpiredBoard(uint boardId) external;

  function getSettlementParameters(
    uint strikeId
  ) external view returns (uint strikePrice, uint priceAtExpiry, uint strikeToBaseReturned);

  ////////////
  // Events //
  ////////////

  /**
   * @dev Emitted when a Board is created.
   */
  event BoardCreated(uint indexed boardId, uint expiry, uint baseIv, bool frozen);

  /**
   * @dev Emitted when a Board frozen is updated.
   */
  event BoardFrozen(uint indexed boardId, bool frozen);

  /**
   * @dev Emitted when a Board new baseIv is set.
   */
  event BoardBaseIvSet(uint indexed boardId, uint baseIv);

  /**
   * @dev Emitted when a Strike new skew is set.
   */
  event StrikeSkewSet(uint indexed strikeId, uint skew);

  /**
   * @dev Emitted when a Strike is added to a board
   */
  event StrikeAdded(uint indexed boardId, uint indexed strikeId, uint strikePrice, uint skew);

  /**
   * @dev Emitted when parameters for the option market are adjusted
   */
  event OptionMarketParamsSet(OptionMarketParameters optionMarketParams);

  /**
   * @dev Emitted whenever the security module claims their portion of fees
   */
  event SMClaimed(address securityModule, uint quoteAmount, uint baseAmount);

  /**
   * @dev Emitted when a Position is opened, closed or liquidated.
   */
  event Trade(
    address indexed trader,
    uint indexed strikeId,
    uint indexed positionId,
    TradeEventData trade,
    IOptionMarketPricer.TradeResult[] tradeResults,
    LiquidationEventData liquidation,
    uint timestamp
  );

  /**
   * @dev Emitted when a Board is liquidated.
   */
  event BoardSettled(
    uint indexed boardId,
    uint spotPriceAtExpiry,
    uint totalUserLongProfitQuote,
    uint totalBoardLongCallCollateral,
    uint totalBoardLongPutCollateral,
    uint totalAMMShortCallProfitBase,
    uint totalAMMShortCallProfitQuote,
    uint totalAMMShortPutProfitQuote
  );

  ////////////
  // Errors //
  ////////////
  // General purpose
  error ExpectedNonZeroValue(address thrower, NonZeroValues valueType);

  // Admin
  error InvalidOptionMarketParams(address thrower, OptionMarketParameters optionMarketParams);

  // Board related
  error InvalidBoardId(address thrower, uint boardId);
  error InvalidExpiryTimestamp(address thrower, uint currentTime, uint expiry, uint maxBoardExpiry);
  error BoardNotFrozen(address thrower, uint boardId);
  error BoardAlreadySettled(address thrower, uint boardId);
  error BoardNotExpired(address thrower, uint boardId);

  // Strike related
  error InvalidStrikeId(address thrower, uint strikeId);
  error StrikeSkewLengthMismatch(address thrower, uint strikesLength, uint skewsLength);

  // Trade
  error TotalCostOutsideOfSpecifiedBounds(address thrower, uint totalCost, uint minCost, uint maxCost);
  error BoardIsFrozen(address thrower, uint boardId);
  error BoardExpired(address thrower, uint boardId, uint boardExpiry, uint currentTime);
  error TradeIterationsHasRemainder(
    address thrower,
    uint iterations,
    uint expectedAmount,
    uint tradeAmount,
    uint totalAmount
  );

  // Access
  error OnlySecurityModule(address thrower, address caller, address securityModule);

  // Token transfers
  error BaseTransferFailed(address thrower, address from, address to, uint amount);
  error QuoteTransferFailed(address thrower, address from, address to, uint amount);
}
