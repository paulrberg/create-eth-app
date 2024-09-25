/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

import "Synthetix/openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20.sol";
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20Detailed.sol";

// IWETH
contract MockWETH is ERC20, ERC20Detailed {
    constructor() public ERC20Detailed("Wrapped Ether", "WETH", 18) {
        _mint(msg.sender, 1000000 * (10**18));
    }

    function deposit() external {
        revert("Unimplemented for OVM");
    }

    function withdraw(uint amount) external {
        amount;
        revert("Unimplemented for OVM");
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
