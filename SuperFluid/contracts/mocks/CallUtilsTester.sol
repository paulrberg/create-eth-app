/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { CallUtils } from "../libs/CallUtils.sol";

contract CallUtilsTester {
    function testIsValidAbiEncodedBytes() external pure {
        require(!CallUtils.isValidAbiEncodedBytes(abi.encode(1, 2, 3)), "bad data");
        require(CallUtils.isValidAbiEncodedBytes(abi.encode(new bytes(0))), "0");
        require(CallUtils.isValidAbiEncodedBytes(abi.encode(new bytes(1))), "1");
        require(CallUtils.isValidAbiEncodedBytes(abi.encode(new bytes(32))), "32");
        require(CallUtils.isValidAbiEncodedBytes(abi.encode(new bytes(33))), "33");
    }
}
