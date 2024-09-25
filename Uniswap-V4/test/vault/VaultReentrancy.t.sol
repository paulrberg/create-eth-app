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
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {ILockCallback} from "../../src/interfaces/ILockCallback.sol";
import {SettlementGuard} from "../../src/libraries/SettlementGuard.sol";
import {Vault} from "../../src/Vault.sol";
import {IVault} from "../../src/interfaces/IVault.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";
import {toBalanceDelta} from "../../src/types/BalanceDelta.sol";
import {SafeCast} from "../../src/libraries/SafeCast.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {TokenFixture} from "../helpers/TokenFixture.sol";

contract TokenLocker is ILockCallback {
    address public tester;
    IVault public vault;

    constructor(IVault _vault) {
        tester = msg.sender;
        vault = _vault;
    }

    function exec(bytes calldata payload) external {
        vault.lock(abi.encode(payload));
    }

    function lockAcquired(bytes calldata data) external returns (bytes memory) {
        bytes memory payload = abi.decode(data, (bytes));
        (bool success, bytes memory ret) = tester.call(payload);
        if (!success) {
            // revert original error
            assembly {
                let ptr := add(ret, 0x20)
                let size := mload(ret)
                revert(ptr, size)
            }
        }
        return "";
    }
}

contract VaultReentrancyTest is Test, TokenFixture {
    using CurrencyLibrary for Currency;
    using SafeCast for *;

    Vault vault;
    TokenLocker locker;

    function setUp() public {
        initializeTokens();
        vault = new Vault();
        locker = new TokenLocker(vault);
    }

    function testVault_functioningAsExpected() public {
        locker.exec(abi.encodeWithSignature("_testVault_functioningAsExpected()"));
    }

    function _testVault_functioningAsExpected() public {
        uint256 nonzeroDeltaCount = vault.getUnsettledDeltasCount();
        assertEq(nonzeroDeltaCount, 0);

        int256 delta = vault.currencyDelta(address(this), currency0);
        assertEq(delta, 0);

        // deposit some tokens
        currency0.transfer(address(vault), 1);
        vault.settle(currency0);
        nonzeroDeltaCount = vault.getUnsettledDeltasCount();

        assertEq(nonzeroDeltaCount, 1);
        delta = vault.currencyDelta(address(this), currency0);
        assertEq(delta, -1);

        // take to offset
        vault.take(currency0, address(this), uint256(-delta));

        nonzeroDeltaCount = vault.getUnsettledDeltasCount();
        assertEq(nonzeroDeltaCount, 0);
        delta = vault.currencyDelta(address(this), currency0);
        assertEq(delta, 0);

        // lock again
        vm.expectRevert(abi.encodeWithSelector(IVault.LockerAlreadySet.selector, locker));
        vault.lock("");
    }

    function testVault_withArbitraryAmountOfCallers() public {
        locker.exec(abi.encodeWithSignature("_testFuzz_vault_withArbitraryAmountOfCallers(uint256)", 10));
    }

    function _testFuzz_vault_withArbitraryAmountOfCallers(uint256 count) public {
        for (uint256 i = 0; i < count; i++) {
            uint256 nonzeroDeltaCount = vault.getUnsettledDeltasCount();
            // when paidAmount = 0, 0 is transferred to the vault, so the delta remains unchanged
            if (i == 0) {
                assertEq(nonzeroDeltaCount, 0);
            } else {
                assertEq(nonzeroDeltaCount, i - 1);
            }

            uint256 paidAmount = i;
            // amount starts from 0 to callerAmount - 1
            currency0.transfer(address(vault), paidAmount);

            address callerAddr = makeAddr(string(abi.encode(i)));
            vm.prank(callerAddr);
            vault.settle(currency0);

            nonzeroDeltaCount = vault.getUnsettledDeltasCount();
            assertEq(nonzeroDeltaCount, i);

            int256 delta = vault.currencyDelta(callerAddr, currency0);
            assertEq(delta, -int256(paidAmount), "after settle & delta is effectively updated");
        }

        for (uint256 i = count; i > 0; i--) {
            uint256 nonzeroDeltaCount = vault.getUnsettledDeltasCount();
            assertEq(nonzeroDeltaCount, i - 1, "before take");

            uint256 paidAmount = i - 1;

            // amount from callerAmount - 1 to 0
            address callerAddr = makeAddr(string(abi.encode(i - 1)));
            vm.prank(callerAddr);
            vault.take(currency0, callerAddr, paidAmount);

            nonzeroDeltaCount = vault.getUnsettledDeltasCount();
            if (paidAmount == 0) {
                assertEq(nonzeroDeltaCount, i - 1, "after take & paidAmt = 0, delta remains unchanged");
            } else {
                assertEq(nonzeroDeltaCount, i - 2, "after take & paidAmt = 0, delta effectively offset");
            }

            int256 delta = vault.currencyDelta(callerAddr, currency0);
            assertEq(delta, 0, "after take & delta is effectively offset");
        }
    }

    function testVault_withArbitraryAmountOfOperations() public {
        locker.exec(abi.encodeWithSignature("_testFuzz_vault_withArbitraryAmountOfOperations(uint256)", 15));
    }

    function _testFuzz_vault_withArbitraryAmountOfOperations(uint256 count) public {
        uint256 SETTLERS_AMOUNT = 3;
        int256[] memory currencyDelta = new int256[](SETTLERS_AMOUNT);
        uint256[] memory vaultTokenBalance = new uint256[](SETTLERS_AMOUNT);

        // deposit enough liquidity for the vault
        for (uint256 i = 0; i < SETTLERS_AMOUNT; i++) {
            currency0.transfer(address(vault), 1 ether);

            address callerAddr = makeAddr(string(abi.encode(i % SETTLERS_AMOUNT)));
            vm.prank(callerAddr);
            vault.settle(currency0);
            vm.prank(callerAddr);
            vault.mint(currency0, address(callerAddr), 1 ether);

            vaultTokenBalance[i] = vault.balanceOf(callerAddr, currency0);
        }
        uint256 nonzeroDeltaCount = vault.getUnsettledDeltasCount();
        assertLe(nonzeroDeltaCount, 0);

        vault.registerPoolManager(makeAddr("poolManager"));

        for (uint256 i = 0; i < count; i++) {
            // alternately:
            // 1. take
            // 2. settle
            // 3. mint
            // 4. burn
            // 5. settleFor
            // 6. accountPoolBalanceDelta

            address callerAddr = makeAddr(string(abi.encode(i % SETTLERS_AMOUNT)));
            uint256 paidAmount = i * 10;
            if (i % 6 == 0) {
                // take
                vm.prank(callerAddr);
                vault.take(currency0, callerAddr, paidAmount);

                currencyDelta[i % SETTLERS_AMOUNT] += int256(paidAmount);
            } else if (i % 6 == 1) {
                // settle
                currency0.transfer(address(vault), paidAmount);
                vm.prank(callerAddr);
                vault.settle(currency0);

                currencyDelta[i % SETTLERS_AMOUNT] -= int256(paidAmount);
            } else if (i % 6 == 2) {
                // mint
                vm.prank(callerAddr);
                vault.mint(currency0, callerAddr, paidAmount);

                currencyDelta[i % SETTLERS_AMOUNT] += int256(paidAmount);
                vaultTokenBalance[i % SETTLERS_AMOUNT] += paidAmount;
            } else if (i % 6 == 3) {
                // burn
                vm.prank(callerAddr);
                vault.burn(currency0, paidAmount);

                currencyDelta[i % SETTLERS_AMOUNT] -= int256(paidAmount);
                vaultTokenBalance[i % SETTLERS_AMOUNT] -= paidAmount;
            } else if (i % 6 == 4) {
                // settleFor
                currency0.transfer(address(vault), paidAmount);
                vm.prank(callerAddr);
                vault.settle(currency0);

                address target = makeAddr(string(abi.encode((i + 1) % SETTLERS_AMOUNT)));
                vm.prank(callerAddr);
                vault.settleFor(currency0, target, paidAmount);

                currencyDelta[(i + 1) % SETTLERS_AMOUNT] -= int256(paidAmount);
            } else if (i % 6 == 5) {
                // accountPoolBalanceDelta
                vm.prank(makeAddr("poolManager"));
                vault.accountPoolBalanceDelta(
                    PoolKey({
                        currency0: currency0,
                        currency1: currency1,
                        hooks: IHooks(address(0)),
                        poolManager: IPoolManager(makeAddr("poolManager")),
                        fee: 0,
                        parameters: bytes32(0)
                    }),
                    toBalanceDelta(paidAmount.toInt128(), int128(0)),
                    callerAddr
                );

                currencyDelta[i % SETTLERS_AMOUNT] += int256(paidAmount);
            }

            // must always hold
            nonzeroDeltaCount = vault.getUnsettledDeltasCount();
            assertLe(nonzeroDeltaCount, SETTLERS_AMOUNT);

            for (uint256 j = 0; j < SETTLERS_AMOUNT; ++j) {
                address _callerAddr = makeAddr(string(abi.encode(j)));
                int256 delta = vault.currencyDelta(_callerAddr, currency0);
                assertEq(delta, currencyDelta[j], "after settle & delta is effectively updated after each loop");

                uint256 balance = vault.balanceOf(_callerAddr, currency0);
                assertEq(balance, vaultTokenBalance[j], "vaultTokenBalance is correctly updated after each loop");
            }
        }

        for (uint256 i = 0; i < SETTLERS_AMOUNT; ++i) {
            address callerAddr = makeAddr(string(abi.encode(i)));
            int256 delta = vault.currencyDelta(callerAddr, currency0);
            if (delta > 0) {
                // user owes token to the vault
                currency0.transfer(address(vault), uint256(delta));
                vm.prank(callerAddr);
                vault.settle(currency0);
            } else if (delta < 0) {
                // vault owes token to the user
                vm.prank(callerAddr);
                vault.take(currency0, callerAddr, uint256(-delta));
            }
            delta = vault.currencyDelta(callerAddr, currency0);
        }
    }
}
