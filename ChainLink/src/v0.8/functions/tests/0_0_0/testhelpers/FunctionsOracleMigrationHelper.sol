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

import {FunctionsOracleMigration} from "./mocks/FunctionsOracleMigration.sol";

contract FunctionsOracleMigrationHelper is FunctionsOracleMigration {
  function callValidateReport(bytes calldata report) external pure returns (bool isValid) {
    bytes32 configDigest;
    uint40 epochAndRound;
    isValid = _validateReport(configDigest, epochAndRound, report);
  }

  function callReport(bytes calldata report) external {
    address[maxNumOracles] memory signers;
    signers[0] = msg.sender;
    _report(gasleft(), msg.sender, 1, signers, report);
  }

  function callReportMultipleSigners(bytes calldata report, address secondSigner) external {
    address[maxNumOracles] memory signers;
    signers[0] = msg.sender;
    signers[1] = secondSigner;
    _report(gasleft(), msg.sender, 2, signers, report);
  }
}
