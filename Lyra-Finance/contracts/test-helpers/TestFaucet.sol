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

contract TestFaucet {
  mapping(uint => uint) dripAmounts;
  TestERC20[] public addresses;

  mapping(address => bool) public permitted;
  mapping(address => bool) public received;

  constructor() {
    permitted[msg.sender] = true;
  }

  function permitModify(address user, bool permit) external {
    require(permitted[msg.sender], "only permitted");
    permitted[user] = permit;
  }

  function setDripAmount(TestERC20 token, uint amount) external {
    require(permitted[msg.sender], "only permitted");
    uint index;
    bool found = false;
    for (index = 0; index < addresses.length; ++index) {
      if (addresses[index] == token) {
        found = true;
        break;
      }
    }
    if (!found) {
      // index will be addresses.length here
      addresses.push(token);
    }
    dripAmounts[index] = amount;
  }

  function drip() external {
    require(!received[msg.sender], "already received");

    for (uint i = 0; i < addresses.length; ++i) {
      addresses[i].mint(msg.sender, dripAmounts[i]);
      emit Dripped(addresses[i], dripAmounts[i]);
    }
    received[msg.sender] = true;
  }

  event Dripped(TestERC20 token, uint amount);
}
