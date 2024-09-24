/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ChainLink?utm=code
  */
  
  pragma solidity ^0.8.0;

contract LogEmitter {
  event Log1(uint256);
  event Log2(uint256 indexed);
  event Log3(string);

  function EmitLog1(uint256[] memory v) public {
    for (uint256 i = 0; i < v.length; i++) {
      emit Log1(v[i]);
    }
  }

  function EmitLog2(uint256[] memory v) public {
    for (uint256 i = 0; i < v.length; i++) {
      emit Log2(v[i]);
    }
  }

  function EmitLog3(string[] memory v) public {
    for (uint256 i = 0; i < v.length; i++) {
      emit Log3(v[i]);
    }
  }
}
