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

import "Lyra-Finance/openzeppelin-contracts-4.4.1/token/ERC20/ERC20.sol";

import "./ITestERC20.sol";

// This test may need to be depricated as decimals are overridden hardcoded in decimals() now
contract TestERC20SetDecimalsFail is ITestERC20, ERC20 {
  bool public forceFail = false;
  bool public transferRevert = false;
  bool public maxApproveFail = false;
  bool public returnFalseOnNotEnoughBalance = false;
  mapping(address => bool) public permitted;
  uint8 private _decimals;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
    permitted[msg.sender] = true;
    _setupDecimals(decimals_);
  }

  function setForceFail(bool _forceFail) external {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    forceFail = _forceFail;
  }

  function setTransferRevert(bool _transferRevert) external {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    transferRevert = _transferRevert;
  }

  function setMaxApprovalFail(bool _maxApproveFail) external {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    maxApproveFail = _maxApproveFail;
  }

  function setReturnFalseOnNotEnoughBalance(bool _returnFalse) external {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    returnFalseOnNotEnoughBalance = _returnFalse;
  }

  // Default setup of decimals in OpenZepellin v4 is done via decimals() override
  // For testing purposes, manually implementing v3 style ERC20 storage and _setDecimals
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function setDecimals(uint8 newDecimals) external {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    _decimals = newDecimals;
  }

  function permitMint(address user, bool permit) external {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    permitted[user] = permit;
  }

  function mint(address account, uint amount) external override {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    ERC20._mint(account, amount);
  }

  function burn(address account, uint amount) external override {
    require(permitted[msg.sender], "TestERC20SetDecimals: only permitted");
    ERC20._burn(account, amount);
  }

  // This isn't ideal, it hits the coverage cases, but should only return false if the transfer fails. Would
  //  require a new contract that doesn't revert on failures.
  function transfer(address receiver, uint amount) public override(ERC20, IERC20) returns (bool) {
    if (forceFail) {
      return false;
    }
    if (transferRevert) {
      revert TransferFailure();
    }

    if (returnFalseOnNotEnoughBalance) {
      if (balanceOf(msg.sender) < amount) {
        return false;
      }
    }
    return super.transfer(receiver, amount);
  }

  function transferFrom(address sender, address receiver, uint amount) public override(ERC20, IERC20) returns (bool) {
    if (forceFail) {
      return false;
    }
    if (transferRevert) {
      revert TransferFailure();
    }
    return super.transferFrom(sender, receiver, amount);
  }

  function approve(address spender, uint amount) public override(ERC20, IERC20) returns (bool) {
    if (forceFail) {
      return false;
    }

    if (maxApproveFail && amount == type(uint).max) {
      return false;
    }
    return super.approve(spender, amount);
  }

  error TransferFailure();
}
