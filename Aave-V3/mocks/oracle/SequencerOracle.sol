/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Aave-V3?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {ISequencerOracle} from '../../interfaces/ISequencerOracle.sol';

contract SequencerOracle is ISequencerOracle, Ownable {
  bool internal _isDown;
  uint256 internal _timestampGotUp;

  /**
   * @dev Constructor.
   * @param owner The owner address of this contract
   */
  constructor(address owner) {
    transferOwnership(owner);
  }

  /**
   * @notice Updates the health status of the sequencer.
   * @param isDown True if the sequencer is down, false otherwise
   * @param timestamp The timestamp of last time the sequencer got up
   */
  function setAnswer(bool isDown, uint256 timestamp) external onlyOwner {
    _isDown = isDown;
    _timestampGotUp = timestamp;
  }

  /// @inheritdoc ISequencerOracle
  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    int256 isDown;
    if (_isDown) {
      isDown = 1;
    }
    return (0, isDown, 0, _timestampGotUp, 0);
  }
}
