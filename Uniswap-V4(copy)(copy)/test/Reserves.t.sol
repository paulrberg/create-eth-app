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

import {Reserves} from "../src/libraries/Reserves.sol";
import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Currency} from "../src/types/Currency.sol";

contract ReservesTest is Test {
    using Reserves for Currency;

    Currency currency0;

    function setUp() public {
        currency0 = Currency.wrap(address(0xbeef));
    }

    function test_getReserves_reverts_withoutSet() public {
        vm.expectRevert(Reserves.ReservesMustBeSynced.selector);
        currency0.getReserves();
    }

    function test_getReserves_returns0AfterSet() public {
        currency0.setReserves(0);
        uint256 value = currency0.getReserves();
        assertEq(value, 0);
    }

    function test_getReserves_returns_set() public {
        currency0.setReserves(100);
        uint256 value = currency0.getReserves();
        assertEq(value, 100);
    }

    function test_set_twice_returns_correct_value() public {
        currency0.setReserves(100);
        currency0.setReserves(200);
        uint256 value = currency0.getReserves();
        assertEq(value, 200);
    }

    function test_reservesOfSlot() public pure {
        assertEq(uint256(keccak256("ReservesOf")) - 1, Reserves.RESERVES_OF_SLOT);
    }

    function test_fuzz_get_set(Currency currency, uint256 value) public {
        vm.assume(value != type(uint256).max);
        currency.setReserves(value);
        assertEq(currency.getReserves(), value);
    }
}
