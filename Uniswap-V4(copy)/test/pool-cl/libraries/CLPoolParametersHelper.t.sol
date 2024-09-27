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
pragma solidity ^0.8.24;

import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {CLPoolParametersHelper} from "../../../src/pool-cl/libraries/CLPoolParametersHelper.sol";

contract CLPoolParametersHelperTest is Test, GasSnapshot {
    function testGetTickSpacing() public {
        bytes32 paramsWithTickSpacing0 = bytes32(uint256(0x0));
        int24 tickSpacing0 = CLPoolParametersHelper.getTickSpacing(paramsWithTickSpacing0);
        assertEq(tickSpacing0, 0);

        bytes32 paramsWithTickSpacingNegative13 = bytes32(uint256(0xfffff30000));
        snapStart("CLPoolParametersHelperTest#getTickSpacing");
        int24 tickSpacingNegative13 = CLPoolParametersHelper.getTickSpacing(paramsWithTickSpacingNegative13);
        snapEnd();
        assertEq(tickSpacingNegative13, -13);

        bytes32 paramsWithTickSpacing5 = bytes32(uint256(0x0000050000));
        int24 tickSpacingNegative5 = CLPoolParametersHelper.getTickSpacing(paramsWithTickSpacing5);
        assertEq(tickSpacingNegative5, 5);
    }
}
