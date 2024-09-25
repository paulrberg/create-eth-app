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

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Slot0, Slot0Library} from "../../src/types/Slot0.sol";

contract TestSlot0 is Test {
    function test_slot0_constants_masks() public pure {
        assertEq(Slot0Library.MASK_160_BITS, type(uint160).max);
        assertEq(Slot0Library.MASK_24_BITS, type(uint24).max);
    }

    function test_fuzz_slot0_pack_unpack(uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee)
        public
        pure
    {
        // pack starting from "lowest" field
        Slot0 _slot0 = Slot0.wrap(bytes32(0)).setSqrtPriceX96(sqrtPriceX96).setTick(tick).setProtocolFee(protocolFee)
            .setLpFee(lpFee);

        assertEq(_slot0.sqrtPriceX96(), sqrtPriceX96);
        assertEq(_slot0.tick(), tick);
        assertEq(_slot0.protocolFee(), protocolFee);
        assertEq(_slot0.lpFee(), lpFee);

        // pack starting from "highest" field
        _slot0 = Slot0.wrap(bytes32(0)).setLpFee(lpFee).setProtocolFee(protocolFee).setTick(tick).setSqrtPriceX96(
            sqrtPriceX96
        );

        assertEq(_slot0.sqrtPriceX96(), sqrtPriceX96);
        assertEq(_slot0.tick(), tick);
        assertEq(_slot0.protocolFee(), protocolFee);
        assertEq(_slot0.lpFee(), lpFee);
    }
}
