/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Olympus-DAO?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ERC20} from "Olympus-DAO/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "Olympus-DAO/hardhat/console.sol";

/**
 * A mock version of sOHM, with an over-simplified rebase mechanism, for testing purposes only
 */
contract MockSOHM is ERC20 {
    uint256 public immutable DECIMALS;
    uint256 public _index; // 9 decimals
    uint256 public _rebasePct; // 9 decimals
    uint256 public _totalAgnosticSupply;

    mapping(address => uint256) public _agnosticBalance;
    mapping(address => mapping(address => uint256)) public _allowedValue;

    constructor(uint256 initialIndex_, uint256 rebasePct_) ERC20("Mock sOHM", "sOHM") {
        require(initialIndex_ > 0, "initial index must be greater than 0");
        require(rebasePct_ > 0, "rebase percentage must be greater than 0");

        DECIMALS = 10**decimals();
        _index = initialIndex_;
        _rebasePct = rebasePct_;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function approve(address spender_, uint256 value_) public override returns (bool) {
        _approve(msg.sender, spender_, value_);
        return true;
    }

    function mint(address to_, uint256 amount_) public returns (uint256) {
        uint256 amount = (amount_ * DECIMALS) / _index;

        _agnosticBalance[to_] += amount;
        _mint(to_, amount);
        _totalAgnosticSupply += amount;
        return amount;
    }

    function transfer(address to_, uint256 value_) public override returns (bool) {
        require(to_ != address(0), "ERC20: transfer to the zero address");

        _transfer(msg.sender, to_, value_);
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 value_
    ) public override returns (bool) {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");

        _allowedValue[from_][to_] -= value_;
        _transfer(from_, to_, value_);
        return true;
    }

    function _transfer(
        address from_,
        address to_,
        uint256 value_
    ) internal override {
        uint256 amount = (value_ * DECIMALS) / _index;

        _agnosticBalance[from_] -= amount;
        _agnosticBalance[to_] += amount;

        emit Transfer(from_, to_, amount);
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        return (_agnosticBalance[owner_] * _index) / DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return (_totalAgnosticSupply * _index) / DECIMALS;
    }

    // Rebase all balances by rebase percentage
    function rebase() external {
        _index += (_index * _rebasePct) / DECIMALS;
    }

    // Set rebase percentage to new amount. Percentage has 9 decimal places.
    function setRebasePct(uint256 newRebasePct_) external {
        require(newRebasePct_ > 0, "rebase percentage must be greater than 0");
        _rebasePct = newRebasePct_;
    }

    function index() public view returns (uint256) {
        return _index;
    }

    // Set index. Index has 9 decimal places.
    function setIndex(uint256 newIndex_) external {
        require(newIndex_ > 0, "new index must be greater than 0");
        _index = newIndex_;
    }

    // Drip 100 sOHM to caller
    function drip() external {
        mint(msg.sender, 100000000000);
    }

    function _approve(
        address owner_,
        address spender_,
        uint256 value_
    ) internal override {
        _allowedValue[owner_][spender_] = value_;
        emit Approval(owner_, spender_, value_);
    }
}
