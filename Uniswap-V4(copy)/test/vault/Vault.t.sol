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

import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {Vault} from "../../src/Vault.sol";
import {BalanceDelta, toBalanceDelta} from "../../src/types/BalanceDelta.sol";
import {ERC20PresetFixedSupply} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {IERC20} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../src/types/PoolId.sol";
import {IVault} from "../../src/interfaces/IVault.sol";
import {FakePoolManagerRouter} from "./FakePoolManagerRouter.sol";
import {FakePoolManager} from "./FakePoolManager.sol";

import {IHooks} from "../../src/interfaces/IHooks.sol";

/**
 * @notice Basic functionality test for Vault
 * More tests in terms of security and edge cases will be covered by VaultReentracy.t.sol & VaultInvariant.t.sol
 */
contract VaultTest is Test, GasSnapshot {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    event PoolManagerRegistered(address indexed poolManager);
    event LockAcquired();

    Vault public vault;
    IPoolManager public unRegPoolManager;
    FakePoolManager public fakePoolManager;
    FakePoolManager public fakePoolManager2;
    FakePoolManagerRouter public fakePoolManagerRouter;
    FakePoolManagerRouter public fakePoolManagerRouter2;

    Currency public currency0;
    Currency public currency1;

    PoolKey public poolKey;
    PoolKey public poolKey2;

    function setUp() public {
        vault = new Vault();
        snapSize("VaultTest#Vault", address(vault));

        unRegPoolManager = new FakePoolManager(vault);

        fakePoolManager = new FakePoolManager(vault);
        fakePoolManager2 = new FakePoolManager(vault);
        vault.registerPoolManager(address(fakePoolManager));
        vault.registerPoolManager(address(fakePoolManager2));

        currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 100 ether, address(this))));
        currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 100 ether, address(this))));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: fakePoolManager,
            fee: 0,
            parameters: 0x00
        });

        poolKey = key;
        fakePoolManagerRouter = new FakePoolManagerRouter(vault, key);

        PoolKey memory key2 = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: fakePoolManager2,
            fee: 1,
            parameters: 0x00
        });

        poolKey2 = key2;
        fakePoolManagerRouter2 = new FakePoolManagerRouter(vault, key2);
    }

    function testRegisterPoolManager() public {
        assertEq(vault.isPoolManagerRegistered(address(unRegPoolManager)), false);
        assertEq(vault.isPoolManagerRegistered(address(fakePoolManager)), true);

        vm.expectEmit();
        emit PoolManagerRegistered(address(unRegPoolManager));
        snapStart("VaultTest#registerPoolManager");
        vault.registerPoolManager(address(unRegPoolManager));
        snapEnd();

        assertEq(vault.isPoolManagerRegistered(address(unRegPoolManager)), true);
        assertEq(vault.isPoolManagerRegistered(address(fakePoolManager)), true);
    }

    function testAccountPoolBalanceDeltaFromUnregistedPoolManager() public {
        PoolKey memory key = PoolKey(currency0, currency1, IHooks(address(0)), unRegPoolManager, 0x0, 0x0);
        FakePoolManagerRouter unRegPoolManagerRouter = new FakePoolManagerRouter(vault, key);
        vm.expectRevert(IVault.PoolManagerUnregistered.selector);
        vm.prank(address(unRegPoolManagerRouter));
        vault.lock(hex"01");
    }

    function testAccountPoolBalanceDeltaFromArbitraryAddr() public {
        vm.expectRevert(IVault.NotFromPoolManager.selector);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"10");
    }

    function testAccountPoolBalanceDeltaWithoutLock() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: fakePoolManager,
            fee: uint24(3000),
            parameters: 0x00
        });
        BalanceDelta delta = toBalanceDelta(0x7, 0x8);

        vm.expectRevert(abi.encodeWithSelector(IVault.NoLocker.selector));
        vm.prank(address(fakePoolManager));
        vault.accountPoolBalanceDelta(key, delta, address(this));
    }

    function testLockNotSettled() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        vm.expectRevert(IVault.CurrencyNotSettled.selector);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"01");
    }

    function testLockNotSettled2() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);

        vm.expectRevert(IVault.CurrencyNotSettled.selector);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");
    }

    function testLockNotSettled3() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 8 ether);

        vm.expectRevert(IVault.CurrencyNotSettled.selector);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");
    }

    function testLockNotSettled4() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 12 ether);

        vm.expectRevert(IVault.CurrencyNotSettled.selector);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");
    }

    function testSettleAndMintRefund_WithMint() public {
        address alice = makeAddr("alice");

        // simulate someone transferred token to vault
        currency0.transfer(address(vault), 10 ether);
        assertEq(vault.balanceOf(alice, currency0), 0 ether);

        // settle and refund
        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#testSettleAndMintRefund_WithMint");
        vault.lock(abi.encodePacked(hex"18", alice));
        snapEnd();

        // verify excess currency minted to alice
        assertEq(vault.balanceOf(alice, currency0), 10 ether);
    }

    function testSettleAndMintRefund_WithoutMint() public {
        address alice = makeAddr("alice");

        assertEq(vault.balanceOf(alice, currency0), 0 ether);

        // settleAndRefund works even if there's no excess currency
        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#testSettleAndMintRefund_WithoutMint");
        vault.lock(abi.encodePacked(hex"18", alice));
        snapEnd();

        // verify no extra token minted
        assertEq(vault.balanceOf(alice, currency0), 0 ether);
    }

    function testSettleAndMintRefund_NegativeBalanceDelta() public {
        // pre-req: ensure vault has some value in reserveOfVault[] before
        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        // settleAndRefund should not revert even if negative balanceDelta
        currency0.transfer(address(vault), 3 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"19");
    }

    function testNotCorrectPoolManager() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        vm.expectRevert(IVault.NotFromPoolManager.selector);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"06");
    }

    function testLockSettledWhenAddLiquidity() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 0 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 0 ether);
        assertEq(vault.reservesOfVault(currency0), 0 ether);
        assertEq(vault.reservesOfVault(currency1), 0 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 0 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 0 ether);

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 10 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 10 ether);
        assertEq(vault.reservesOfVault(currency0), 0 ether);
        assertEq(vault.reservesOfVault(currency1), 0 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 0 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 0 ether);

        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#lockSettledWhenAddLiquidity");
        vault.lock(hex"02");
        snapEnd();

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 10 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 10 ether);
        assertEq(vault.reservesOfVault(currency0), 10 ether);
        assertEq(vault.reservesOfVault(currency1), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 10 ether);
    }

    function testLockSettledWhenSwap() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 10 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 10 ether);
        assertEq(vault.reservesOfVault(currency0), 10 ether);
        assertEq(vault.reservesOfVault(currency1), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 10 ether);

        currency0.transfer(address(vault), 3 ether);
        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#lockSettledWhenSwap");
        vault.lock(hex"03");
        snapEnd();

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 13 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 7 ether);
        assertEq(vault.reservesOfVault(currency0), 13 ether);
        assertEq(vault.reservesOfVault(currency1), 7 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 13 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 7 ether);

        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(fakePoolManagerRouter)), 3 ether);
    }

    function testLockWhenAlreadyLocked() public {
        // deposit enough token in
        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        vm.expectRevert(abi.encodeWithSelector(IVault.LockerAlreadySet.selector, address(fakePoolManagerRouter)));

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"07");
    }

    function testLockWhenMoreThanOnePoolManagers() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter2));
        vault.lock(hex"02");

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 20 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 20 ether);
        assertEq(vault.reservesOfVault(currency0), 20 ether);
        assertEq(vault.reservesOfVault(currency1), 20 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency1), 10 ether);

        currency0.transfer(address(vault), 3 ether);
        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#lockSettledWhenMultiHopSwap");
        vault.lock(hex"03");
        snapEnd();

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 23 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 17 ether);
        assertEq(vault.reservesOfVault(currency0), 23 ether);
        assertEq(vault.reservesOfVault(currency1), 17 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 13 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 7 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency1), 10 ether);

        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(fakePoolManagerRouter)), 3 ether);
    }

    function testVault_settleFor() public {
        // make sure router has enough tokens
        currency0.transfer(address(fakePoolManagerRouter), 10 ether);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"11");
    }

    function testVaultFuzz_settleFor_arbitraryAmt(uint256 amt) public {
        amt = bound(amt, 0, 10 ether);
        // make sure router has enough tokens
        currency0.transfer(address(fakePoolManagerRouter), amt);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"12");
    }

    function testVaultFuzz_mint(uint256 amt) public {
        amt = bound(amt, 0, 10 ether);
        // make sure router has enough tokens
        currency0.transfer(address(vault), amt);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"13");

        assertEq(vault.balanceOf(address(fakePoolManagerRouter), currency0), amt);
    }

    function testVaultFuzz_mint_toSomeoneElse(uint256 amt) public {
        amt = bound(amt, 0, 10 ether);
        // make sure router has enough tokens
        currency0.transfer(address(vault), amt);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"14");

        assertEq(vault.balanceOf(Currency.unwrap(poolKey.currency1), currency0), amt);
    }

    function testVaultFuzz_burn(uint256 amt) public {
        amt = bound(amt, 0, 10 ether);
        // make sure router has enough tokens
        currency0.transfer(address(vault), amt);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"15");

        assertEq(vault.balanceOf(address(fakePoolManagerRouter), currency0), 0);
    }

    function testVaultFuzz_burnHalf(uint256 amt) public {
        amt = bound(amt, 0, 10 ether);
        // make sure router has enough tokens
        currency0.transfer(address(vault), amt);

        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"16");

        assertEq(vault.balanceOf(address(fakePoolManagerRouter), currency0), amt - amt / 2);
    }

    function testLockInSufficientBalanceWhenMoreThanOnePoolManagers() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter2));
        vault.lock(hex"02");

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 20 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 20 ether);
        assertEq(vault.reservesOfVault(currency0), 20 ether);
        assertEq(vault.reservesOfVault(currency1), 20 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency1), 10 ether);

        assertEq(currency0.balanceOfSelf(), 80 ether);
        currency0.transfer(address(vault), 15 ether);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"04");
    }

    function testLockFlashloanCrossMoreThanOnePoolManagers() public {
        // router => vault.lock
        // vault.lock => periphery.lockAcquired
        // periphery.lockAcquired => FakePoolManager.XXX => vault.accountPoolBalanceDelta

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter2));
        vault.lock(hex"02");

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 20 ether);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 20 ether);
        assertEq(vault.reservesOfVault(currency0), 20 ether);
        assertEq(vault.reservesOfVault(currency1), 20 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency1), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey2.poolManager, currency1), 10 ether);

        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#lockSettledWhenFlashloan");
        vault.lock(hex"05");
        snapEnd();
    }

    function test_CollectFee() public {
        currency0.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"02");

        // before collectFee assert
        assertEq(vault.reservesOfVault(currency0), 10 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 10 ether);
        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(fakePoolManager)), 0 ether);

        // collectFee
        vm.prank(address(fakePoolManager));
        snapStart("VaultTest#collectFee");
        vault.collectFee(currency0, 10 ether, address(fakePoolManager));
        snapEnd();

        // after collectFee assert
        assertEq(vault.reservesOfVault(currency0), 0 ether);
        assertEq(vault.reservesOfPoolManager(poolKey.poolManager, currency0), 0 ether);
        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(fakePoolManager)), 10 ether);
    }

    function test_CollectFeeFromRandomUser() public {
        currency0.transfer(address(vault), 10 ether);

        address bob = makeAddr("bob");
        vm.startPrank(bob);

        // expected underflow as reserves are 0 currently
        vm.expectRevert(stdError.arithmeticError);
        vault.collectFee(currency0, 10 ether, bob);
    }

    function testTake_failsWithNoLiquidity() public {
        vm.expectRevert();
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"09");
    }

    function testLock_NoOpIsOk() public {
        vm.prank(address(fakePoolManagerRouter));
        snapStart("VaultTest#testLock_NoOp");
        vault.lock(hex"00");
        snapEnd();
    }

    function testLock_EmitsCorrectId() public {
        vm.expectEmit(false, false, false, true);
        emit LockAcquired();
        vm.prank(address(fakePoolManagerRouter));
        vault.lock(hex"00");
    }

    function testVault_ethSupport_transferInAndSettle() public {
        FakePoolManagerRouter router = new FakePoolManagerRouter(
            vault,
            PoolKey({
                currency0: CurrencyLibrary.NATIVE,
                currency1: currency1,
                hooks: IHooks(address(0)),
                poolManager: fakePoolManager,
                fee: 0,
                parameters: 0x00
            })
        );

        // transfer in & settle
        {
            CurrencyLibrary.NATIVE.transfer(address(vault), 10 ether);
            currency1.transfer(address(vault), 10 ether);

            vm.prank(address(router));
            vault.lock(hex"02");

            assertEq(CurrencyLibrary.NATIVE.balanceOf(address(vault)), 10 ether);
            assertEq(vault.reservesOfVault(CurrencyLibrary.NATIVE), 10 ether);
            assertEq(vault.reservesOfPoolManager(fakePoolManager, CurrencyLibrary.NATIVE), 10 ether);
        }
    }

    function testVault_ethSupport_settleAndTake() public {
        FakePoolManagerRouter router = new FakePoolManagerRouter(
            vault,
            PoolKey({
                currency0: CurrencyLibrary.NATIVE,
                currency1: currency1,
                hooks: IHooks(address(0)),
                poolManager: fakePoolManager,
                fee: 0,
                parameters: 0x00
            })
        );

        CurrencyLibrary.NATIVE.transfer(address(router), 5 ether);

        // take and settle
        {
            vm.prank(address(router));
            vault.lock(hex"17");

            assertEq(CurrencyLibrary.NATIVE.balanceOf(address(vault)), 0);
            assertEq(vault.reservesOfVault(CurrencyLibrary.NATIVE), 0);
            assertEq(vault.reservesOfPoolManager(fakePoolManager, CurrencyLibrary.NATIVE), 0);
        }
    }

    function testVault_ethSupport_flashloan() public {
        FakePoolManagerRouter router = new FakePoolManagerRouter(
            vault,
            PoolKey({
                currency0: CurrencyLibrary.NATIVE,
                currency1: currency1,
                hooks: IHooks(address(0)),
                poolManager: fakePoolManager,
                fee: 0,
                parameters: 0x00
            })
        );

        // make sure vault has enough tokens
        CurrencyLibrary.NATIVE.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(router));
        vault.lock(hex"02");

        CurrencyLibrary.NATIVE.transfer(address(vault), 10 ether);
        currency1.transfer(address(vault), 10 ether);
        vm.prank(address(router));
        vault.lock(hex"02");

        // take and settle
        {
            vm.prank(address(router));
            vault.lock(hex"05");
        }
    }
}
