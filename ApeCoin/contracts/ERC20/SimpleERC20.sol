/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ApeCoin?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "ApeCoin/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "ApeCoin/@openzeppelin/contracts/access/Ownable.sol";

contract SimpleERC20 is ERC20, Ownable {

    uint256 limitMintPublic = 11000 ether;
    uint256 maxTotalSupply = 1000000000 ether;

    constructor(string memory name, string memory symbol) ERC20(name, symbol){
    }

    function mintOwner(address to, uint256 amount) external onlyOwner {
        require(totalSupply() <= maxTotalSupply, "Can't exceed max total supply");
        _mint(to, amount);
    }

    function mintPublic(address to, uint256 amount) public {
        require(amount <= limitMintPublic, "Can't mint more than 11K $APE per tx");
        require(totalSupply() <= maxTotalSupply, "Can't exceed max total supply");
        _mint(to, amount);
    }
}
