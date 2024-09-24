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
pragma solidity 0.6.6;

import "../interfaces/AggregatorValidatorInterface.sol";

contract AggregatorValidatorMock is AggregatorValidatorInterface {
  uint256 public previousRoundId;
  int256 public previousAnswer;
  uint256 public currentRoundId;
  int256 public currentAnswer;

  event Validated(
    uint256 _previousRoundId,
    int256 indexed _previousAnswer,
    uint256 _currentRoundId,
    int256 indexed _currentAnswer
  );

  function validate(
    uint256 _previousRoundId,
    int256 _previousAnswer,
    uint256 _currentRoundId,
    int256 _currentAnswer
  )
    external
    override
    returns (bool)
  {
    emit Validated(
      _previousRoundId,
      _previousAnswer,
      _currentRoundId,
      _currentAnswer
    );
    return true;
  }

}
