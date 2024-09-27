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

import "Uniswap-V4/forge-std/Test.sol";
import {TreeMath} from "../../../../src/pool-bin/libraries/math/TreeMath.sol";

contract TreeMathTest is Test {
    struct State {
        bytes32 level0;
        mapping(bytes32 => bytes32) level1;
        mapping(bytes32 => bytes32) level2;
    }

    State private _self;

    function testFuzz_AddToTree(uint24[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            bool contains = TreeMath.contains(_self.level2, ids[i]);

            (bool result, bytes32 level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, ids[i]);
            _self.level0 = level0;

            assertEq(result, !contains, "testFuzz_AddToTree::1");
            assertEq(TreeMath.contains(_self.level2, ids[i]), true, "testFuzz_AddToTree::2");
        }
    }

    function testFuzz_RemoveFromTree(uint24[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, ids[i]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            bool contains = TreeMath.contains(_self.level2, ids[i]);

            (bool result, bytes32 level0) = TreeMath.remove(_self.level0, _self.level1, _self.level2, ids[i]);
            _self.level0 = level0;

            assertEq(result, contains, "testFuzz_RemoveFromTree::1");
            assertEq(TreeMath.contains(_self.level2, ids[i]), false, "testFuzz_RemoveFromTree::2");
        }
    }

    function testFuzz_AddAndRemove(uint24 id) external {
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id);
        assertEq(TreeMath.contains(_self.level2, id), true, "testFuzz_AddAndRemove::1");

        assertGt(uint256(_self.level0), 0, "testFuzz_AddAndRemove::2");
        assertGt(uint256(_self.level1[bytes32(uint256(id >> 16))]), 0, "testFuzz_AddAndRemove::3");
        assertGt(uint256(_self.level2[bytes32(uint256(id >> 8))]), 0, "testFuzz_AddAndRemove::4");

        (, _self.level0) = TreeMath.remove(_self.level0, _self.level1, _self.level2, id);

        assertEq(TreeMath.contains(_self.level2, id), false, "testFuzz_AddAndRemove::5");

        assertEq(uint256(_self.level0), 0, "testFuzz_AddAndRemove::6");
        assertEq(uint256(_self.level1[bytes32(uint256(id >> 16))]), 0, "testFuzz_AddAndRemove::7");
        assertEq(uint256(_self.level2[bytes32(uint256(id >> 8))]), 0, "testFuzz_AddAndRemove::8");
    }

    function testFuzz_RemoveLogicAndSearchRight() external {
        uint24 id = 4194304;

        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id);
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id - 1);
        assertEq(TreeMath.contains(_self.level2, id), true);
        assertEq(TreeMath.contains(_self.level2, id - 1), true);

        assertEq(
            TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, id),
            id - 1,
            "testFuzz_RemoveLogicAndSearchRight::1"
        );

        (, _self.level0) = TreeMath.remove(_self.level0, _self.level1, _self.level2, id - 1);
        assertEq(
            TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, id),
            type(uint24).max,
            "testFuzz_RemoveLogicAndSearchRight::2"
        );
    }

    function testFuzz_RemoveLogicAndSearchRight(uint24 id) external {
        vm.assume(id > 0);

        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id);
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id - 1);
        assertEq(
            TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, id),
            id - 1,
            "testFuzz_RemoveLogicAndSearchRight::1"
        );

        (, _self.level0) = TreeMath.remove(_self.level0, _self.level1, _self.level2, id - 1);
        assertEq(
            TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, id),
            type(uint24).max,
            "testFuzz_RemoveLogicAndSearchRight::2"
        );
    }

    function testFuzz_RemoveLogicAndSearchLeft(uint24 id) external {
        id = uint24(bound(id, 0, type(uint24).max - 1));

        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id);
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, id + 1);
        assertEq(
            TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, id),
            id + 1,
            "testFuzz_RemoveLogicAndSearchLeft::1"
        );

        (, _self.level0) = TreeMath.remove(_self.level0, _self.level1, _self.level2, id + 1);
        assertEq(
            TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, id),
            0,
            "testFuzz_RemoveLogicAndSearchLeft::2"
        );
    }

    function test_FindFirst() external {
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, 0);
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, 1);
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, 2);

        assertEq(TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, 2), 1, "testFuzz_FindFirst::1");
        assertEq(TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, 1), 0, "testFuzz_FindFirst::2");

        assertEq(TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, 0), 1, "testFuzz_FindFirst::1");
        assertEq(TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, 1), 2, "testFuzz_FindFirst::2");

        assertEq(
            TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, 0),
            type(uint24).max,
            "testFuzz_FindFirst::5"
        );
        assertEq(TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, 2), 0, "testFuzz_FindFirst::6");
    }

    function test_FindFirstFar() external {
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, 0);
        (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, type(uint24).max);

        assertEq(
            TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, type(uint24).max),
            0,
            "testFuzz_FindFirstFar::1"
        );

        assertEq(
            TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, 0),
            type(uint24).max,
            "testFuzz_FindFirstFar::2"
        );
    }

    function testFuzz_FindFirst(uint24[] calldata ids) external {
        vm.assume(ids.length > 0);

        for (uint256 i = 0; i < ids.length; i++) {
            (, _self.level0) = TreeMath.add(_self.level0, _self.level1, _self.level2, ids[i]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint24 id = ids[i];

            uint24 firstRight = TreeMath.findFirstRight(_self.level0, _self.level1, _self.level2, id);
            uint24 firstLeft = TreeMath.findFirstLeft(_self.level0, _self.level1, _self.level2, id);

            if (firstRight != type(uint24).max) {
                assertEq(TreeMath.contains(_self.level2, firstRight), true, "testFuzz_FindFirst::1");
                assertEq(firstRight < id, true, "testFuzz_FindFirst::2");
            }

            if (firstLeft != 0) {
                assertEq(TreeMath.contains(_self.level2, firstLeft), true, "testFuzz_FindFirst::3");
                assertEq(firstLeft > id, true, "testFuzz_FindFirst::4");
            }
        }
    }
}
