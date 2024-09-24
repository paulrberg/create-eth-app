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

import "./TestERC20.sol";

contract TestERC20Fail is TestERC20 {
  bool public forceFail = false;
  bool public returnFalseOnNotEnoughBalance = false;
  bool public maxApproveFail = false;

  constructor(string memory name_, string memory symbol_) TestERC20(name_, symbol_) {}

  function setForceFail(bool _forceFail) external {
    forceFail = _forceFail;
  }

  function setReturnFalseOnNotEnoughBalance(bool _returnFalse) external {
    returnFalseOnNotEnoughBalance = _returnFalse;
  }

  function setMaxApprovalFail(bool _maxApproveFail) external {
    maxApproveFail = _maxApproveFail;
  }

  // This isn't ideal, it hits the coverage cases, but should only return false if the transfer fails. Would
  //  require a new contract that doesn't revert on failures.
  function transfer(address receiver, uint amount) public override(IERC20, ERC20) returns (bool) {
    if (forceFail) {
      return false;
    }

    if (returnFalseOnNotEnoughBalance) {
      if (balanceOf(msg.sender) < amount) {
        return false;
      }
    }

    return super.transfer(receiver, amount);
  }

  function transferFrom(address sender, address receiver, uint amount) public override(IERC20, ERC20) returns (bool) {
    if (forceFail) {
      return false;
    }
    return super.transferFrom(sender, receiver, amount);
  }

  function approve(address spender, uint amount) public override(IERC20, ERC20) returns (bool) {
    if (forceFail) {
      return false;
    }

    if (maxApproveFail && amount == type(uint).max) {
      return false;
    }
    return super.approve(spender, amount);
  }
}
