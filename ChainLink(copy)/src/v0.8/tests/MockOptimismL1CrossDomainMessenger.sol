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
pragma solidity ^0.8.9;

/* Interface Imports */
import {IL1CrossDomainMessenger} from "ChainLink/@eth-optimism/contracts/L1/messaging/IL1CrossDomainMessenger.sol";

contract MockOptimismL1CrossDomainMessenger is IL1CrossDomainMessenger {
  uint256 private s_nonce;

  // slither-disable-next-line external-function
  function xDomainMessageSender() public view returns (address) {
    return address(0);
  }

  function sendMessage(address _target, bytes memory _message, uint32 _gasLimit) public {
    emit SentMessage(_target, msg.sender, _message, s_nonce, _gasLimit);
    s_nonce++;
  }

  /**
   * Relays a cross domain message to a contract.
   * @inheritdoc IL1CrossDomainMessenger
   */
  // slither-disable-next-line external-function
  function relayMessage(
    address _target,
    address _sender,
    bytes memory _message,
    uint256 _messageNonce,
    L2MessageInclusionProof memory _proof
  ) public {}

  function replayMessage(
    address _target,
    address _sender,
    bytes memory _message,
    uint256 _queueIndex,
    uint32 _oldGasLimit,
    uint32 _newGasLimit
  ) public {}
}
