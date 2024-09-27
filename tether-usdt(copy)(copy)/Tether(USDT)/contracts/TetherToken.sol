/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/tether-usdt?utm=code
  */
  
  pragma solidity ^0.8.0;

import "tether-usdt/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "tether-usdt/openzeppelin-solidity/contracts/access/Ownable.sol";
import "tether-usdt/openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract Blacklist is Ownable {
    mapping(address => bool) public BlacklistAddresses;

    function getBlacklistStatus(address _address) external view returns (bool) {
        return BlacklistAddresses[_address];
    }

    function addBlacklist(address _address) public onlyOwner {
        BlacklistAddresses[_address] = true;
        emit AddedBlacklist(_address);
    }

    function removeBlackList(address _address) public onlyOwner {
        BlacklistAddresses[_address] = false;
        emit RemovedBlacklist(_address);
    }

    function removeBlacklistFunds(address _address) public onlyOwner {
        require(BlacklistAddresses[_address]);
        _destroyFunds(_address);
    }

    function _destroyFunds(address _address) internal virtual {}

    event DestroyedBlacklistFunds(address _address, uint256 _balance);

    event AddedBlacklist(address _address);

    event RemovedBlacklist(address _address);
}

contract TetherToken is ERC20Pausable, Blacklist {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    function _destroyFunds(address _address) internal override{
        uint256 fundsToDestroy = balanceOf(_address);
        _burn(_address, fundsToDestroy);
        emit DestroyedBlacklistFunds(_address, fundsToDestroy);
    }
}