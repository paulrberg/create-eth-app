/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {CommonBase} from "Uniswap-V4/forge-std/Base.sol";

abstract contract JavascriptFfi is CommonBase {
    function runScript(string memory scriptName, string memory args) internal returns (bytes memory result) {
        string[] memory inputs = new string[](8);

        // build ffi command string
        inputs[0] = "npm";
        inputs[1] = "--silent";
        inputs[2] = "--prefix";
        inputs[3] = "./test/js-scripts";
        inputs[4] = "run";
        inputs[5] = scriptName;
        inputs[6] = "--";
        inputs[7] = args;
        result = vm.ffi(inputs);
    }
}
