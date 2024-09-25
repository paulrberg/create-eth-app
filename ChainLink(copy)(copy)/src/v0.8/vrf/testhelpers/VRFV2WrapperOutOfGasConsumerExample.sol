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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../VRFV2WrapperConsumerBase.sol";
import "../../ConfirmedOwner.sol";

contract VRFV2WrapperOutOfGasConsumerExample is VRFV2WrapperConsumerBase, ConfirmedOwner {
  constructor(
    address _link,
    address _vrfV2Wrapper
  ) ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) {}

  function makeRequest(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) external onlyOwner returns (uint256 requestId) {
    return requestRandomness(_callbackGasLimit, _requestConfirmations, _numWords);
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal view override {
    while (gasleft() > 0) {}
  }
}
