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
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";
import {CurrencyTest} from "../../src/test/CurrencyTest.sol";

contract TestCurrency is Test {
    uint256 constant initialERC20Balance = 1000 ether;
    address constant otherAddress = address(1);

    Currency nativeCurrency;
    Currency erc20Currency;
    CurrencyTest currencyTest;

    function setUp() public {
        currencyTest = new CurrencyTest();
        vm.deal(address(currencyTest), 30 ether);
        nativeCurrency = Currency.wrap(address(0));
        MockERC20 token = new MockERC20("TestA", "A", 18);
        token.mint(address(currencyTest), initialERC20Balance);
        erc20Currency = Currency.wrap(address(token));
    }

    function test_fuzz_equals(address a, address b) public pure {
        assertEq(a == b, Currency.wrap(a) == Currency.wrap(b));
    }

    function test_fuzz_greaterThan(address a, address b) public pure {
        assertEq(a > b, Currency.wrap(a) > Currency.wrap(b));
    }

    function test_fuzz_lessThan(address a, address b) public pure {
        assertEq(a < b, Currency.wrap(a) < Currency.wrap(b));
    }

    function test_fuzz_greaterThanOrEqualTo(address a, address b) public pure {
        assertEq(a >= b, Currency.wrap(a) >= Currency.wrap(b));
    }

    function test_fuzz_balanceOfSelf_native(uint256 amount) public {
        uint256 balanceBefore = address(currencyTest).balance;
        amount = bound(amount, 0, balanceBefore);
        currencyTest.transfer(nativeCurrency, otherAddress, amount);
        assertEq(balanceBefore - amount, address(currencyTest).balance);
        assertEq(currencyTest.balanceOfSelf(nativeCurrency), address(currencyTest).balance);
    }

    function test_fuzz_balanceOfSelf_token(uint256 amount) public {
        amount = bound(amount, 0, initialERC20Balance);
        currencyTest.transfer(erc20Currency, otherAddress, amount);
        assertEq(currencyTest.balanceOfSelf(erc20Currency), initialERC20Balance - amount);
        assertEq(
            currencyTest.balanceOfSelf(erc20Currency),
            MockERC20(Currency.unwrap(erc20Currency)).balanceOf(address(currencyTest))
        );
    }

    function test_fuzz_balanceOf_native(uint256 amount) public {
        uint256 currencyBalanceBefore = address(currencyTest).balance;
        amount = bound(amount, 0, address(currencyTest).balance);
        currencyTest.transfer(nativeCurrency, otherAddress, amount);

        assertEq(otherAddress.balance, amount);
        assertEq(address(currencyTest).balance, currencyBalanceBefore - amount);
        assertEq(otherAddress.balance, currencyTest.balanceOf(nativeCurrency, otherAddress));
    }

    function test_fuzz_balanceOf_token(uint256 amount) public {
        amount = bound(amount, 0, initialERC20Balance);
        currencyTest.transfer(erc20Currency, otherAddress, amount);
        assertEq(currencyTest.balanceOf(erc20Currency, otherAddress), amount);
        assertEq(currencyTest.balanceOfSelf(erc20Currency), initialERC20Balance - amount);
        assertEq(
            MockERC20(Currency.unwrap(erc20Currency)).balanceOf(otherAddress),
            currencyTest.balanceOf(erc20Currency, otherAddress)
        );
    }

    function test_isNative_native_returnsTrue() public view {
        assertEq(currencyTest.isNative(nativeCurrency), true);
    }

    function test_isNative_token_returnsFalse() public view {
        assertEq(currencyTest.isNative(erc20Currency), false);
    }

    function test_fuzz_isNative(Currency currency) public view {
        assertEq(currencyTest.isNative(currency), (Currency.unwrap(currency) == address(0)));
    }

    function test_toId_nativeReturns0() public view {
        assertEq(currencyTest.toId(nativeCurrency), uint256(0));
    }

    function test_fuzz_toId_returnsCurrencyAsUint256(Currency currency) public view {
        assertEq(currencyTest.toId(currency), uint256(uint160(Currency.unwrap(currency))));
    }

    function test_fromId_0ReturnsNative() public view {
        assertEq(Currency.unwrap(currencyTest.fromId(0)), Currency.unwrap(nativeCurrency));
    }

    function test_fuzz_fromId_returnsUint256AsCurrency(uint256 id) public view {
        uint160 expectedCurrency = uint160(uint256(type(uint160).max) & id);
        assertEq(Currency.unwrap(currencyTest.fromId(id)), address(expectedCurrency));
    }

    function test_fuzz_fromId_toId_opposites(Currency currency) public view {
        assertEq(Currency.unwrap(currency), Currency.unwrap(currencyTest.fromId(currencyTest.toId(currency))));
    }

    function test_fuzz_transfer_native(uint256 amount) public {
        uint256 balanceBefore = otherAddress.balance;
        uint256 contractBalanceBefore = address(currencyTest).balance;

        if (amount <= contractBalanceBefore) {
            currencyTest.transfer(nativeCurrency, otherAddress, amount);
            assertEq(otherAddress.balance, balanceBefore + amount);
            assertEq(address(currencyTest).balance, contractBalanceBefore - amount);
        } else {
            vm.expectRevert(CurrencyLibrary.NativeTransferFailed.selector);
            currencyTest.transfer(nativeCurrency, otherAddress, amount);
            assertEq(otherAddress.balance, balanceBefore);
        }
    }

    function test_fuzz_transfer_token(uint256 amount) public {
        uint256 balanceBefore = currencyTest.balanceOf(erc20Currency, otherAddress);

        if (amount <= initialERC20Balance) {
            currencyTest.transfer(erc20Currency, otherAddress, amount);
            assertEq(currencyTest.balanceOf(erc20Currency, otherAddress), balanceBefore + amount);
            assertEq(
                MockERC20(Currency.unwrap(erc20Currency)).balanceOf(address(currencyTest)), initialERC20Balance - amount
            );
        } else {
            vm.expectRevert(CurrencyLibrary.ERC20TransferFailed.selector);
            currencyTest.transfer(erc20Currency, otherAddress, amount);
            assertEq(currencyTest.balanceOf(erc20Currency, otherAddress), balanceBefore);
        }
    }
}
