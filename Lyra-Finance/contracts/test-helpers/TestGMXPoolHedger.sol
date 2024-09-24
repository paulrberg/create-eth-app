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

import "../GMXFuturesPoolHedger.sol";

/**
 * @notice only used in tests
 * @dev expose testIncreasePosition to let us create state which we have 2 positions opened at the same time
 */
contract TestGMXFuturesPoolHedger is GMXFuturesPoolHedger {
  function testIncreasePosition(
    PositionDetails memory pos,
    bool isLong,
    uint sizeDelta,
    uint collateralDelta
  ) external payable {
    uint spot = _getSpotPrice();
    _increasePosition(pos, isLong, sizeDelta, collateralDelta, spot);
  }

  function testDecreasePosition(
    PositionDetails memory pos,
    bool isLong,
    uint sizeDelta,
    uint collateralDelta,
    bool isClose
  ) external payable {
    uint spot = _getSpotPrice();
    _decreasePosition(pos, isLong, sizeDelta, collateralDelta, spot, isClose);
  }
}
