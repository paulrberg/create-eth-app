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

// Interfaces
import "../LiquidityPool.sol";

/**
 * @title PoolHedger
 * @author Lyra
 * @dev Scaffold for using the delta hedging funds from the LiquidityPool to hedge option deltas, so LPs are minimally
 * exposed to movements in the underlying asset price.
 */
abstract contract PoolHedger {
  struct PoolHedgerParameters {
    uint interactionDelay;
    uint hedgeCap;
  }

  LiquidityPool internal liquidityPool;
  PoolHedgerParameters internal poolHedgerParams;
  uint public lastInteraction;

  /////////////
  // Only LP //
  /////////////
  function resetInteractionDelay() external onlyLiquidityPool {
    lastInteraction = 0;
  }

  /////////////
  // Getters //
  /////////////

  /**
   * @dev Returns the current hedged netDelta position.
   */
  function getCurrentHedgedNetDelta() external view virtual returns (int);

  /// @notice Returns pending delta hedge liquidity and used delta hedge liquidity
  /// @dev include funds that would need to be transferred to the contract to hedge optimally
  function getHedgingLiquidity(
    uint spotPrice
  ) external view virtual returns (uint pendingDeltaLiquidity, uint usedDeltaLiquidity);

  /**
   * @dev Calculates the expected delta hedge that hedger must perform and
   * adjusts the result down to the hedgeCap param if needed.
   */
  function getCappedExpectedHedge() public view virtual returns (int cappedExpectedHedge);

  //////////////
  // External //
  //////////////

  /// @param increasesPoolDelta Does the trade increase or decrease the pool's net delta position
  function canHedge(uint tradeSize, bool increasesPoolDelta, uint strikeId) external view virtual returns (bool);

  /**
   * @dev Retrieves the netDelta for the system and hedges appropriately.
   */
  function hedgeDelta() external payable virtual;

  function updateCollateral() external payable virtual;

  function getPoolHedgerParams() external view virtual returns (PoolHedgerParameters memory) {
    return poolHedgerParams;
  }

  //////////////
  // Internal //
  //////////////

  function _setPoolHedgerParams(PoolHedgerParameters memory _poolHedgerParams) internal {
    poolHedgerParams = _poolHedgerParams;
    emit PoolHedgerParametersSet(poolHedgerParams);
  }

  ///////////////
  // Modifiers //
  ///////////////

  modifier onlyLiquidityPool() {
    if (msg.sender != address(liquidityPool)) {
      revert OnlyLiquidityPool(address(this), msg.sender, address(liquidityPool));
    }
    _;
  }

  ////////////
  // Events //
  ////////////
  /**
   * @dev Emitted when pool hedger parameters are updated.
   */
  event PoolHedgerParametersSet(PoolHedgerParameters poolHedgerParams);

  ////////////
  // Errors //
  ////////////

  // Access
  error OnlyLiquidityPool(address thrower, address caller, address liquidityPool);
}
