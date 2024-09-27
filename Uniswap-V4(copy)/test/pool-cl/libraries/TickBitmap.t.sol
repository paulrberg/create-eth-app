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

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {TickBitmap} from "../../../src/pool-cl/libraries/TickBitmap.sol";

contract TickBitmapTest is Test, GasSnapshot {
    using TickBitmap for mapping(int16 => uint256);

    int24 constant INITIALIZED_TICK = 70;
    int24 constant TICK_IN_UNINITIALZIED_WORD = 10000;
    int24 constant SOLO_INITIALIZED_TICK_IN_WORD = -10000;

    mapping(int16 => uint256) public bitmap;

    function setUp() public {
        // set dirty slots beforehand for certain gas tests
        int24[10] memory ticks = [SOLO_INITIALIZED_TICK_IN_WORD, -200, -55, -4, INITIALIZED_TICK, 78, 84, 139, 240, 535];
        for (uint256 i; i < ticks.length - 1; i++) {
            flipTick(ticks[i]);
        }
    }

    function test_isInitialized_isFalseAtFirst() public {
        assertEq(isInitialized(1), false);
    }

    function test_isInitialized_isFlippedByFlipTick() public {
        flipTick(1);
        assertEq(isInitialized(1), true);
    }

    function test_isInitialized_isFlippedBackByFlipTick() public {
        flipTick(1);
        flipTick(1);
        assertEq(isInitialized(1), false);
    }

    function test_isInitialized_isNotChangedByAnotherFlipToADifferentTick() public {
        flipTick(2);
        assertEq(isInitialized(1), false);
    }

    function test_isInitialized_isNotChangedByAnotherFlipToADifferentTickOnAnotherWord() public {
        flipTick(1 + 256);
        assertEq(isInitialized(257), true);
        assertEq(isInitialized(1), false);
    }

    function test_flipTick_flipsOnlyTheSpecifiedTick() public {
        flipTick(-230);
        assertEq(isInitialized(-230), true);
        assertEq(isInitialized(-231), false);
        assertEq(isInitialized(-229), false);
        assertEq(isInitialized(-230 + 256), false);
        assertEq(isInitialized(-230 - 256), false);

        flipTick(-230);
        assertEq(isInitialized(-230), false);
        assertEq(isInitialized(-231), false);
        assertEq(isInitialized(-229), false);
        assertEq(isInitialized(-230 + 256), false);
        assertEq(isInitialized(-230 - 256), false);

        assertEq(isInitialized(1), false);
    }

    function test_flipTick_revertsOnlyItself() public {
        flipTick(-230);
        flipTick(-259);
        flipTick(-229);
        flipTick(500);
        flipTick(-259);
        flipTick(-229);
        flipTick(-259);
        assertEq(isInitialized(-259), true);
        assertEq(isInitialized(-229), false);
    }

    function test_flipTick_gasCostOfFlippingFirstTickInWordToInitialized() public {
        snapStart("flipTick_gasCostOfFlippingFirstTickInWordToInitialized");
        flipTick(TICK_IN_UNINITIALZIED_WORD);
        snapEnd();
    }

    function test_flipTick_gasCostOfFlippingSecondTickInWordToInitialized() public {
        snapStart("flipTick_gasCostOfFlippingSecondTickInWordToInitialized");
        flipTick(INITIALIZED_TICK + 1);
        snapEnd();
    }

    function test_flipTick_gasCostOfFlippingATickThatResultsInDeletingAWord() public {
        snapStart("flipTick_gasCostOfFlippingATickThatResultsInDeletingAWord");
        flipTick(SOLO_INITIALIZED_TICK_IN_WORD);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTickToRightIfAtInitializedTick() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(78, 1, false);
        assertEq(next, 84);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTickToRightIfAtInitializedTick2() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(-55, 1, false);

        assertEq(next, -4);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheTickDirectlyToTheRight() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(77, 1, false);
        assertEq(next, 78);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheTickDirectlyToTheRight2() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(-56, 1, false);
        assertEq(next, -55);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheNextWordsInitializedTickIfOnTheRightBoundary()
        public
    {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(255, 1, false);
        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheNextWordsInitializedTickIfOnTheRightBoundary2()
        public
    {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(-257, 1, false);
        assertEq(next, -200);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_returnsTheNextInitializedTickFromTheNextWord() public {
        flipTick(340);

        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(328, 1, false);
        assertEq(next, 340);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_doesNotExceedBoundary() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(508, 1, false);
        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_skipsEntireWord() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(255, 1, false);
        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_skipsHalfWord() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(383, 1, false);
        assertEq(next, 511);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_gasCostOnBoundary() public {
        snapStart("nextInitializedTickWithinOneWord_lteFalse_gasCostOnBoundary");
        bitmap.nextInitializedTickWithinOneWord(255, 1, false);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_gasCostJustBelowBoundary() public {
        snapStart("nextInitializedTickWithinOneWord_lteFalse_gasCostJustBelowBoundary");
        bitmap.nextInitializedTickWithinOneWord(254, 1, false);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteFalse_gasCostForEntireWord() public {
        snapStart("nextInitializedTickWithinOneWord_lteFalse_gasCostForEntireWord");
        bitmap.nextInitializedTickWithinOneWord(768, 1, false);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_returnsSameTickIfInitialized() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(78, 1, true);
        assertEq(next, 78);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_returnsTickDirectlyToTheLeftOfInputTickIfNotInitialized()
        public
    {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(79, 1, true);
        assertEq(next, 78);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_willNotExceedTheWordBoundary() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(258, 1, true);
        assertEq(next, 256);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_atTheWordBoundary() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(256, 1, true);
        assertEq(next, 256);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_wordBoundaryLess1nextInitializedTickInNextWord() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(72, 1, true);
        assertEq(next, 70);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_wordBoundary() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(-257, 1, true);
        assertEq(next, -512);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_entireEmptyWord() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(1023, 1, true);
        assertEq(next, 768);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_halfwayThroughEmptyWord() public {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(900, 1, true);
        assertEq(next, 768);
        assertEq(initialized, false);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_boundaryIsInitialized() public {
        flipTick(329);
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(456, 1, true);
        assertEq(next, 329);
        assertEq(initialized, true);
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_gasCostOnBoundary() public {
        snapStart("nextInitializedTickWithinOneWord_lteTrue_gasCostOnBoundary");
        bitmap.nextInitializedTickWithinOneWord(256, 1, true);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_gasCostJustBelowBoundary() public {
        snapStart("nextInitializedTickWithinOneWord_lteTrue_gasCostJustBelowBoundary");
        bitmap.nextInitializedTickWithinOneWord(255, 1, true);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_lteTrue_gasCostForEntireWord() public {
        snapStart("nextInitializedTickWithinOneWord_lteTrue_gasCostForEntireWord");
        bitmap.nextInitializedTickWithinOneWord(1024, 1, true);
        snapEnd();
    }

    function test_nextInitializedTickWithinOneWord_fuzz(int24 tick, bool lte) public {
        // assume tick is at least one word inside type(int24).(max | min)
        vm.assume(lte ? tick >= -8388352 : tick < 8388351);

        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(tick, 1, lte);

        if (lte) {
            assertLe(next, tick);
            assertLe(tick - next, 256);
            // all the ticks between the input tick and the next tick should be uninitialized
            for (int24 i = tick; i > next; i--) {
                assertTrue(!isInitialized(i));
            }
            assertEq(isInitialized(next), initialized);
        } else {
            assertGt(next, tick);
            assertLe(next - tick, 256);
            // all the ticks between the input tick and the next tick should be uninitialized
            for (int24 i = tick + 1; i < next; i++) {
                assertTrue(!isInitialized(i));
            }
            assertEq(isInitialized(next), initialized);
        }
    }

    function isInitialized(int24 tick) internal view returns (bool) {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(tick, 1, true);
        return next == tick ? initialized : false;
    }

    function flipTick(int24 tick) internal {
        bitmap.flipTick(tick, 1);
    }
}
