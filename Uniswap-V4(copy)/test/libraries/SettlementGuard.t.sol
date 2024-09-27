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

import {SettlementGuard} from "../../src/libraries/SettlementGuard.sol";
import {IVault} from "../../src/interfaces/IVault.sol";
import {Currency} from "../../src/types/Currency.sol";

import "Uniswap-V4/forge-std/Test.sol";

contract SettlementGuardTest is Test {
    function testSetLocker(address newLocker, address anotherNewLocker) public {
        vm.assume(newLocker != address(0x0));
        vm.assume(anotherNewLocker != address(0x0));
        vm.assume(newLocker != anotherNewLocker);

        address locker = SettlementGuard.getLocker();
        assertEq(locker, address(0x0));

        SettlementGuard.setLocker(newLocker);

        locker = SettlementGuard.getLocker();
        assertEq(locker, newLocker);

        vm.expectRevert(abi.encodeWithSelector(IVault.LockerAlreadySet.selector, newLocker));
        SettlementGuard.setLocker(anotherNewLocker);

        SettlementGuard.setLocker(address(0));
        SettlementGuard.setLocker(anotherNewLocker);
        locker = SettlementGuard.getLocker();
        assertEq(locker, anotherNewLocker);
    }

    function testAccountDelta(address settler, Currency currency, int256 addedDelta, int256 anotherAddedDelta) public {
        assertEq(SettlementGuard.getUnsettledDeltasCount(), 0);
        assertEq(SettlementGuard.getCurrencyDelta(settler, currency), 0);

        // add delta
        SettlementGuard.accountDelta(settler, currency, addedDelta);
        if (addedDelta == 0) {
            assertEq(SettlementGuard.getUnsettledDeltasCount(), 0);
        } else {
            assertEq(SettlementGuard.getUnsettledDeltasCount(), 1);
        }
        assertEq(SettlementGuard.getCurrencyDelta(settler, currency), addedDelta);

        bool expectRevert = false;
        // overflow
        if (addedDelta > 0 && type(int256).max - addedDelta < anotherAddedDelta) {
            expectRevert = true;
        }

        // underflow
        if (addedDelta < 0 && type(int256).min - addedDelta > anotherAddedDelta) {
            expectRevert = true;
        }

        if (expectRevert) {
            vm.expectRevert();
        }

        // add another delta
        SettlementGuard.accountDelta(settler, currency, anotherAddedDelta);

        if (!expectRevert) {
            if (addedDelta + anotherAddedDelta == 0) {
                assertEq(SettlementGuard.getUnsettledDeltasCount(), 0);
            } else {
                assertEq(SettlementGuard.getUnsettledDeltasCount(), 1);
            }
            assertEq(SettlementGuard.getCurrencyDelta(settler, currency), addedDelta + anotherAddedDelta);
        }
    }
}
