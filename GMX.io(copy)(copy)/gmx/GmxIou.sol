/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/GMX.io?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "./interfaces/IGmxIou.sol";

contract GmxIou is IERC20, IGmxIou {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    uint256 public override totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    address public minter;

    constructor (address _minter, string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        minter = _minter;
        decimals = 18;
    }

    function mint(address account, uint256 amount) public override returns (bool) {
        require(msg.sender == minter, "GmxIou: forbidden");
        _mint(account, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // empty implementation, GmxIou tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("GmxIou: non-transferrable");
    }

    // empty implementation, GmxIou tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, GmxIou tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("GmxIou: non-transferrable");
    }

    // empty implementation, GmxIou tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("GmxIou: non-transferrable");
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "GmxIou: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}
