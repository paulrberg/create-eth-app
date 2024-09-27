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
import {BinPosition} from "../../../src/pool-bin/libraries/BinPosition.sol";

contract BinPositionTest is Test {
    using BinPosition for mapping(bytes32 => BinPosition.Info);
    using BinPosition for BinPosition.Info;

    struct State {
        /// @notice (user, binId) => shares of user in a binId
        mapping(bytes32 => BinPosition.Info) positions;
    }

    State private _self;

    function testFuzz_AddShare(address owner, uint24 binId, uint256 share) public {
        _self.positions.get(owner, binId).addShare(share);

        assertEq(_self.positions.get(owner, binId).share, share, "testFuzz_AddShare::1");
    }

    function testFuzz_AddShareMultiple(address owner, uint24 binId, uint256 share1, uint256 share2) public {
        share1 = bound(share1, 0, type(uint128).max);
        share2 = bound(share2, 0, type(uint128).max);
        _self.positions.get(owner, binId).addShare(share1);
        _self.positions.get(owner, binId).addShare(share2);

        assertEq(_self.positions.get(owner, binId).share, share1 + share2, "testFuzz_AddShareMultiple::1");
    }

    function testFuzz_SubShare(address owner, uint24 binId, uint256 share) public {
        _self.positions.get(owner, binId).addShare(share);
        _self.positions.get(owner, binId).subShare(share);

        assertEq(_self.positions.get(owner, binId).share, 0, "testFuzz_SubShare::1");
    }

    function testFuzz_SubShareMultiple(address owner, uint24 binId, uint256 share1, uint256 share2) public {
        share1 = bound(share1, 1, type(uint128).max);
        share2 = bound(share2, 0, share1 - 1);

        _self.positions.get(owner, binId).addShare(share1);
        _self.positions.get(owner, binId).subShare(share2);

        assertEq(_self.positions.get(owner, binId).share, share1 - share2, "testFuzz_SubShareMultiple::1");
    }

    function testFuzz_GetPosition(address owner, uint24 binId, uint256 share) public {
        // manual keccak and add share
        bytes32 key = keccak256(abi.encodePacked(owner, binId));
        _self.positions[key].addShare(share);

        // verify assembly version of keccak retrival works
        assertEq(_self.positions.get(owner, binId).share, share);
    }
}
