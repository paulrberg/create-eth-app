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
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";

import {Deployers} from "./utils/Deployers.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "../src/types/Currency.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "../src/test/PoolSwapTest.sol";
import {IUnlockCallback} from "../src/interfaces/callback/IUnlockCallback.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {ActionsRouter, Actions} from "../src/test/ActionsRouter.sol";
import {SafeCast} from "../src/libraries/SafeCast.sol";
import {Reserves} from "../src/libraries/Reserves.sol";
import {StateLibrary} from "../src/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "../src/libraries/TransientStateLibrary.sol";

contract SyncTest is Test, Deployers, GasSnapshot {
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    // PoolManager has no balance of currency2.
    Currency currency2;
    ActionsRouter router;

    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));
        currency2 = deployMintAndApproveCurrency();
        router = new ActionsRouter(manager);
    }

    function test_sync_balanceIsZero() public noIsolate {
        assertEq(currency2.balanceOf(address(manager)), uint256(0));
        uint256 balance = manager.sync(currency2);

        assertEq(uint256(balance), 0);
        assertEq(manager.getReserves(currency2), type(uint256).max);
    }

    function test_sync_balanceIsNonZero() public noIsolate {
        uint256 currency0Balance = currency0.balanceOf(address(manager));
        assertGt(currency0Balance, uint256(0));

        // Without calling sync, getReserves should return 0.
        assertEq(manager.getReserves(currency0), 0);

        uint256 balance = manager.sync(currency0);
        assertEq(balance, currency0Balance, "balance not equal");
        assertEq(manager.getReserves(currency0), balance);
    }

    function test_settle_withStartingBalance() public noIsolate {
        assertGt(currency0.balanceOf(address(manager)), uint256(0));

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        // Sync has not been called.
        assertEq(manager.getReserves(currency0), 0);

        swapRouter.swap(key, SWAP_PARAMS, testSettings, new bytes(0));
        (uint256 balanceCurrency0) = currency0.balanceOf(address(manager));
        assertEq(manager.getReserves(currency0), balanceCurrency0); // Reserves are up to date since settle was called.
    }

    function test_settle_withNoStartingBalance() public noIsolate {
        assertEq(currency2.balanceOf(address(manager)), uint256(0));

        (Currency cur0, Currency cur1) = currency0 < currency2 ? (currency0, currency2) : (currency2, currency0);
        PoolKey memory key2 =
            PoolKey({currency0: cur0, currency1: cur1, fee: 3000, tickSpacing: 60, hooks: IHooks(address(0))});

        manager.initialize(key2, SQRT_PRICE_1_1, new bytes(0));

        // Sync has not been called.
        assertEq(manager.getReserves(currency2), 0);
        modifyLiquidityRouter.modifyLiquidity(key2, IPoolManager.ModifyLiquidityParams(-60, 60, 100, 0), new bytes(0));
        (uint256 balanceCurrency2) = currency2.balanceOf(address(manager));
        assertEq(manager.getReserves(currency2), balanceCurrency2);
    }

    function test_settle_revertsIfSyncNotCalled() public noIsolate {
        Actions[] memory actions = new Actions[](1);
        bytes[] memory params = new bytes[](1);

        actions[0] = Actions.SETTLE;
        params[0] = abi.encode(currency0);

        vm.expectRevert(Reserves.ReservesMustBeSynced.selector);
        router.executeActions(actions, params);
    }

    /// @notice When there is no balance and reserves are set to type(uint256).max, no delta should be applied.
    function test_settle_noBalanceInPool_shouldNotApplyDelta() public noIsolate {
        assertEq(currency2.balanceOf(address(manager)), uint256(0));

        // Sync has not been called.
        assertEq(manager.getReserves(currency2), 0);

        manager.sync(currency2);
        assertEq(manager.getReserves(currency2), type(uint256).max);

        Actions[] memory actions = new Actions[](2);
        bytes[] memory params = new bytes[](2);

        actions[0] = Actions.SETTLE;
        params[0] = abi.encode(currency2);

        actions[1] = Actions.ASSERT_DELTA_EQUALS;
        params[1] = abi.encode(currency2, address(router), 0);

        router.executeActions(actions, params);
    }

    /// @notice When there is a balance, no delta should be applied.
    function test_settle_balanceInPool_shouldNotApplyDelta() public noIsolate {
        uint256 currency0Balance = currency0.balanceOf(address(manager));

        // Sync has not been called.
        assertEq(manager.getReserves(currency0), 0);

        manager.sync(currency0);
        assertEq(manager.getReserves(currency0), currency0Balance);

        Actions[] memory actions = new Actions[](2);
        bytes[] memory params = new bytes[](2);

        actions[0] = Actions.SETTLE;
        params[0] = abi.encode(currency0);

        actions[1] = Actions.ASSERT_DELTA_EQUALS;
        params[1] = abi.encode(currency0, address(router), 0);

        router.executeActions(actions, params);
    }

    /// @notice When there is no actual balance in the pool, the ZERO_BALANCE stored in transient reserves should never actually used in calculating the amount paid in settle.
    /// This tests check that the reservesNow value is set to 0 not ZERO_BALANCE, by checking that an underflow happens when
    /// a) the contract balance is 0 and b) the reservesBefore value is out of date (sync isn't called again before settle).
    /// ie because paid = reservesNow - reservesBefore, and because reservesNow < reservesBefore an underflow should happen.
    function test_settle_afterTake_doesNotApplyDelta() public noIsolate {
        Currency currency3 = deployMintAndApproveCurrency();

        // Approve the router for a transfer.
        MockERC20(Currency.unwrap(currency3)).approve(address(router), type(uint256).max);

        // Sync has not been called on currency3.
        assertEq(manager.getReserves(currency3), 0);

        manager.sync(currency3);
        // Sync has been called.
        assertEq(manager.getReserves(currency3), type(uint256).max);

        uint256 maxBalanceCurrency3 = uint256(int256(type(int128).max));

        Actions[] memory actions = new Actions[](10);
        bytes[] memory params = new bytes[](10);

        // 1. First supply a large amount of currency3 to the pool, by minting and transfering.
        // Encode a MINT.
        actions[0] = Actions.MINT;
        params[0] = abi.encode(address(this), currency3, maxBalanceCurrency3);

        // Encode a TRANSFER.
        actions[1] = Actions.TRANSFER_FROM;
        params[1] = abi.encode(currency3, address(this), address(manager), maxBalanceCurrency3);

        // Encode a SETTLE.
        actions[2] = Actions.SETTLE;
        params[2] = abi.encode(currency3);

        // 2. Second check that the balances (token balances, reserves balance, and delta balance) are as expected.
        // The token balance of the pool should be the full balance.
        // The reserves balance should have been updated to the full balance in settle.
        // And the delta balance should be 0, because it has been fully settled.

        // Assert that the manager balance is the full balance.
        actions[3] = Actions.ASSERT_BALANCE_EQUALS;
        params[3] = abi.encode(currency3, address(manager), maxBalanceCurrency3);

        // Assert that the reserves balance is the full balance.
        actions[4] = Actions.ASSERT_RESERVES_EQUALS;
        params[4] = abi.encode(currency3, maxBalanceCurrency3);

        // Assert that the delta is settled.
        actions[5] = Actions.ASSERT_DELTA_EQUALS;
        params[5] = abi.encode(currency3, address(router), 0);

        // 3. Take the full balance from the pool, but do not call sync.
        // Thus reservesBefore stays > 0. And the next reserves call will be 0 causing a revert.

        // Encode a TAKE.
        actions[6] = Actions.TAKE;
        params[6] = abi.encode(currency3, address(this), maxBalanceCurrency3);

        // Assert that the actual balance of the pool is 0.
        actions[7] = Actions.ASSERT_BALANCE_EQUALS;
        params[7] = abi.encode(currency3, address(manager), 0);

        // Assert that the reserves balance is the old pool balance because sync has not been called.
        actions[8] = Actions.ASSERT_RESERVES_EQUALS;
        params[8] = abi.encode(currency3, maxBalanceCurrency3);

        // Encode a SETTLE.
        actions[9] = Actions.SETTLE;
        params[9] = abi.encode(currency3);

        // Expect an underflow/overflow because reservesBefore > reservesNow since sync() had not been called before settle.
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));

        router.executeActions(actions, params);
    }

    // @notice This tests expected behavior if you DO NOT call sync. (ie. Do not interact with the pool manager properly. You can lose funds.)
    function test_settle_withoutSync_doesNotRevert_takesUserBalance() public noIsolate {
        MockERC20(Currency.unwrap(currency0)).approve(address(router), type(uint256).max);
        uint256 managerCurrency0BalanceBefore = currency0.balanceOf(address(manager));
        uint256 userCurrency0BalanceBefore = currency0.balanceOf(address(this));

        Actions[] memory actions = new Actions[](8);
        bytes[] memory params = new bytes[](8);

        manager.sync(currency0);
        snapStart("getReserves");
        uint256 reserves = manager.getReserves(currency0);
        snapEnd();
        assertEq(reserves, managerCurrency0BalanceBefore); // reserves are 100.

        actions[0] = Actions.TAKE;
        params[0] = abi.encode(currency0, address(this), 10);

        // Assert that the delta open on the router is -10. (The user owes 10 to the pool).
        actions[1] = Actions.ASSERT_DELTA_EQUALS;
        params[1] = abi.encode(currency0, address(router), -10);

        actions[2] = Actions.TRANSFER_FROM;
        params[2] = abi.encode(currency0, address(this), manager, 10);

        actions[3] = Actions.SETTLE;
        params[3] = abi.encode(currency0); // Since reserves now == reserves, paid = 0 and the delta owed by the user will still be -10 after settle.

        actions[4] = Actions.ASSERT_DELTA_EQUALS;
        params[4] = abi.encode(currency0, address(router), -10);

        // To now settle the delta, the user owes 10 to the pool.
        // Because sync is called in settle we can transfer + settle.
        actions[5] = Actions.TRANSFER_FROM;
        params[5] = abi.encode(currency0, address(this), manager, 10);

        actions[6] = Actions.SETTLE;
        params[6] = abi.encode(currency0);

        actions[7] = Actions.ASSERT_DELTA_EQUALS;
        params[7] = abi.encode(currency0, address(router), 0);

        router.executeActions(actions, params);

        // The manager gained 10 currency0.
        assertEq(currency0.balanceOf(address(manager)), managerCurrency0BalanceBefore + 10);
        // The user lost 10 currency0, and can never claim it back.
        assertEq(currency0.balanceOf(address(this)), userCurrency0BalanceBefore - 10);
    }
}
