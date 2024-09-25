/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/flagship-cookbook-nft?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// V1 Royalty test
// Accepts an arbitrary amount of ETH from the client, defined by the client. 
// Testing contract for future royalty distribution for any deploys to the creator of the contract

abstract contract Royalty {
     constructor () payable {
        (bool sent, bytes memory data) = 0x07590a393C67670463b80768fEED264832541d51.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}
