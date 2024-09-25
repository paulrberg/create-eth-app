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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Extsload} from "../src/Extsload.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";

contract Loadable is Extsload {}

/// @author philogy <https://github.com/philogy>
contract ExtsloadTest is Test, GasSnapshot {
    Loadable loadable = new Loadable();

    function test_load10_sparse() public {
        bytes32[] memory keys = new bytes32[](10);
        for (uint256 i = 0; i < keys.length; i++) {
            keys[i] = keccak256(abi.encode(i));
            vm.store(address(loadable), keys[i], bytes32(i));
        }

        bytes32[] memory values = loadable.extsload(keys);
        snapLastCall("sparse external sload");
        assertEq(values.length, keys.length);
        for (uint256 i = 0; i < values.length; i++) {
            assertEq(values[i], bytes32(i));
        }
    }
}
