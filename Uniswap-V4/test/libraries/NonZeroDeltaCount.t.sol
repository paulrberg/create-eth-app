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
import {NonZeroDeltaCount} from "../../src/libraries/NonZeroDeltaCount.sol";

contract NonZeroDeltaCountTest is Test {
    function test_incrementNonzeroDeltaCount() public {
        assertEq(NonZeroDeltaCount.read(), 0);
        NonZeroDeltaCount.increment();
        assertEq(NonZeroDeltaCount.read(), 1);
    }

    function test_decrementNonzeroDeltaCount() public {
        assertEq(NonZeroDeltaCount.read(), 0);
        NonZeroDeltaCount.increment();
        assertEq(NonZeroDeltaCount.read(), 1);
        NonZeroDeltaCount.decrement();
        assertEq(NonZeroDeltaCount.read(), 0);
    }

    // Reading from right to left. Bit of 0: call increase. Bit of 1: call decrease.
    // The library allows over over/underflow so we dont check for that here
    function test_fuzz_nonZeroDeltaCount(uint256 instructions) public {
        assertEq(NonZeroDeltaCount.read(), 0);
        uint256 expectedCount;
        for (uint256 i = 0; i < 256; i++) {
            if ((instructions & (1 << i)) == 0) {
                NonZeroDeltaCount.increment();
                unchecked {
                    expectedCount++;
                }
            } else {
                NonZeroDeltaCount.decrement();
                unchecked {
                    expectedCount--;
                }
            }
            assertEq(NonZeroDeltaCount.read(), expectedCount);
        }
    }

    function test_nonZeroDeltaCountSlot() public pure {
        assertEq(uint256(keccak256("NonzeroDeltaCount")) - 1, NonZeroDeltaCount.NONZERO_DELTA_COUNT_SLOT);
    }
}
