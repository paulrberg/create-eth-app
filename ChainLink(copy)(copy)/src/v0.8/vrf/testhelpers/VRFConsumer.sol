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
pragma solidity ^0.8.0;

import "../../interfaces/LinkTokenInterface.sol";
import "../VRFConsumerBase.sol";

contract VRFConsumer is VRFConsumerBase {
  uint256 public randomnessOutput;
  bytes32 public requestId;

  constructor(
    address vrfCoordinator,
    address link
  )
    // solhint-disable-next-line no-empty-blocks
    VRFConsumerBase(vrfCoordinator, link)
  {
    /* empty */
  }

  function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
    randomnessOutput = randomness;
    requestId = requestId;
  }

  function doRequestRandomness(bytes32 keyHash, uint256 fee) external returns (bytes32) {
    return requestRandomness(keyHash, fee);
  }
}
