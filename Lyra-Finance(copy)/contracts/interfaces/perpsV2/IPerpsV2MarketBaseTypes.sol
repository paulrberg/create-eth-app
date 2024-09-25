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
  
  pragma solidity ^0.8.0;

/**
 * @author Synthetix
 * @dev copied from https://github.com/Synthetixio/synthetix/blob/develop/contracts/interfaces/IPerpsV2MarketBaseTypes.sol
 *      and updated the version to 0.8
 */
interface IPerpsV2MarketBaseTypes {
  /* ========== TYPES ========== */

  enum OrderType {
    Atomic,
    Delayed,
    Offchain
  }

  enum Status {
    Ok,
    InvalidPrice,
    InvalidOrderType,
    PriceOutOfBounds,
    CanLiquidate,
    CannotLiquidate,
    MaxMarketSizeExceeded,
    MaxLeverageExceeded,
    InsufficientMargin,
    NotPermitted,
    NilOrder,
    NoPositionOpen,
    PriceTooVolatile,
    PriceImpactToleranceExceeded
  }

  // If margin/size are positive, the position is long; if negative then it is short.
  struct Position {
    uint64 id;
    uint64 lastFundingIndex;
    uint128 margin;
    uint128 lastPrice;
    int128 size;
  }

  // Delayed order storage
  struct DelayedOrder {
    bool isOffchain; // flag indicating the delayed order is offchain
    int128 sizeDelta; // difference in position to pass to modifyPosition
    uint128 priceImpactDelta; // price impact tolerance as a percentage used on fillPrice at execution
    uint128 targetRoundId; // price oracle roundId using which price this order needs to executed
    uint128 commitDeposit; // the commitDeposit paid upon submitting that needs to be refunded if order succeeds
    uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
    uint256 executableAtTime; // The timestamp at which this order is executable at
    uint256 intentionTime; // The block timestamp of submission
    bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
  }
}
