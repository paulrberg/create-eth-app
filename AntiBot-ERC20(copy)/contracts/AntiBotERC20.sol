/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/AntiBot-ERC20?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "AntiBot-ERC20/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "AntiBot-ERC20/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "AntiBot-ERC20/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "AntiBot-ERC20/@openzeppelin/contracts/access/Ownable.sol";

contract AntiBotERC20 is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    mapping(address => uint256) private _buyBlock;
    bool public checkBot = true;

    constructor() ERC20("TokenName", "SYMBOL") ERC20Permit("TokenName") {
        _mint(msg.sender, 1000 * 10 ** 18);
    }

    function setCheckBot(bool _status) public onlyOwner {
        checkBot = _status;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override isBot(from, to) {
        _buyBlock[to] = block.number;
    }

    modifier isBot(address from, address to) {
        if (checkBot) require(_buyBlock[from] != block.number, "Bad bot!");
        _;
    }
}
