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

import "./ShortPoolHedger.sol";

contract TestShortPoolHedger is ShortPoolHedger {
  bool public canPoolHedge = true;

  function setCanHedge(bool _canHedge) public {
    canPoolHedge = _canHedge;
  }

  function canHedge(uint, bool, uint) external view override returns (bool) {
    return canPoolHedge;
  }

  function hedgeDeltaExt(int expectedHedge) external {
    _hedgeDelta(expectedHedge);
  }

  function increaseLongExt(SynthetixAdapter.ExchangeParams memory exchangeParams, uint amount) external {
    // Last field is optional, only for event
    _increaseLong(exchangeParams, amount, 0);
  }

  function decreaseLongExt(uint amount) external {
    // Last field is optional, only for event
    _decreaseLong(amount, 0);
  }

  function callTransferQuoteToHedge(uint amount) external {
    liquidityPool.transferQuoteToHedge(amount);
  }

  function setShortToExt(uint spotPrice, uint desiredShort, uint currentShort, uint currentCollateral) external {
    _setShortTo(spotPrice, desiredShort, currentShort, currentCollateral);
  }

  function _sendAllQuoteToLPExt() external {
    _sendAllQuoteToLP();
  }
}
