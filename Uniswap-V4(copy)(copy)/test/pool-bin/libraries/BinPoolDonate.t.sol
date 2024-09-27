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

import {IVault} from "../../../src/interfaces/IVault.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {IPoolManager} from "../../../src/interfaces/IPoolManager.sol";
import {MockVault} from "../../../src/test/MockVault.sol";
import {Currency} from "../../../src/types/Currency.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BinHelper} from "../../../src/pool-bin/libraries/BinHelper.sol";
import {BalanceDelta, toBalanceDelta} from "../../../src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {BinPoolManager} from "../../../src/pool-bin/BinPoolManager.sol";
import {BinPool} from "../../../src/pool-bin/libraries/BinPool.sol";
import {PackedUint128Math} from "../../../src/pool-bin/libraries/math/PackedUint128Math.sol";
import {SafeCast} from "../../../src/pool-bin/libraries/math/SafeCast.sol";
import {BinPoolParametersHelper} from "../../../src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {BinTestHelper} from "../helpers/BinTestHelper.sol";

contract BinPoolDonateTest is BinTestHelper {
    using PoolIdLibrary for PoolKey;
    using PackedUint128Math for bytes32;
    using BinPoolParametersHelper for bytes32;
    using SafeCast for uint256;

    MockVault public vault;
    BinPoolManager public poolManager;

    uint24 immutable activeId = ID_ONE;

    PoolKey key;
    PoolId poolId;
    bytes32 poolParam;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vault = new MockVault();
        poolManager = new BinPoolManager(IVault(address(vault)), 500000);

        poolParam = poolParam.setBinStep(10);
        key = PoolKey({
            currency0: Currency.wrap(makeAddr("token0")),
            currency1: Currency.wrap(makeAddr("token1")),
            hooks: IHooks(address(0)),
            poolManager: IPoolManager(address(poolManager)),
            fee: uint24(3000),
            parameters: poolParam // binStep
        });
        poolId = key.toId();
    }

    function testDonatePoolNotInitialized() public {
        vm.expectRevert(BinPool.PoolNotInitialized.selector);
        poolManager.donate(key, 1e18, 1e18, "");
    }

    function testDonateNoLiquidity() public {
        poolManager.initialize(key, activeId, new bytes(0));

        vm.expectRevert(BinPool.BinPool__NoLiquidityToReceiveFees.selector);
        poolManager.donate(key, 1e18, 1e18, "");
    }

    function testDonate() public {
        // Initialize. Alice/Bob both add 1e18 token0, token1 to the active bin
        poolManager.initialize(key, activeId, new bytes(0));
        addLiquidityToBin(key, poolManager, alice, activeId, 1e18, 1e18, 1e18, 1e18, "");
        uint256 aliceShare = poolManager.getPosition(poolId, alice, activeId).share;
        addLiquidityToBin(key, poolManager, bob, activeId, 1e18, 1e18, 1e18, 1e18, "");
        uint256 bobShare = poolManager.getPosition(poolId, bob, activeId).share;

        // Verify reserve before donate
        uint128 reserveX;
        uint128 reserveY;
        (reserveX, reserveY) = poolManager.getBin(poolId, activeId);
        assertEq(reserveX, 2e18);
        assertEq(reserveY, 2e18);

        // Donate
        poolManager.donate(key, 2e18, 2e18, "");

        // Verify reserve after donate
        (reserveX, reserveY) = poolManager.getBin(poolId, activeId);
        assertEq(reserveX, 4e18);
        assertEq(reserveY, 4e18);

        // Verify bob remove liquidity and get the donated reserve
        BalanceDelta removeDelta1 = removeLiquidityFromBin(key, poolManager, bob, activeId, bobShare, "");
        assertEq(removeDelta1.amount0(), -2e18);
        assertEq(removeDelta1.amount1(), -2e18);

        BalanceDelta removeDelta2 = removeLiquidityFromBin(key, poolManager, alice, activeId, aliceShare, "");
        assertEq(removeDelta2.amount0(), -2e18);
        assertEq(removeDelta2.amount1(), -2e18);

        // Verify no reserve remaining
        (reserveX, reserveY) = poolManager.getBin(poolId, activeId);
        assertEq(reserveX, 0);
        assertEq(reserveY, 0);

        vm.expectRevert(BinPool.BinPool__NoLiquidityToReceiveFees.selector);
        poolManager.donate(key, 1e18, 1e18, "");
    }

    function testFuzzDonate(uint128 amt0, uint128 amt1) public {
        vm.assume(amt0 < uint128(type(int128).max) && amt1 < uint128(type(int128).max));

        // Initialize and add 1e18 token0, token1 to the active bin. price of bin: 2**128, 3.4e38
        poolManager.initialize(key, activeId, new bytes(0));
        addLiquidityToBin(key, poolManager, bob, activeId, 1e18, 1e18, 1e18, 1e18, "");
        poolManager.getPosition(poolId, bob, activeId).share;

        poolManager.donate(key, amt0, amt1, "");

        // Verify reserve after donate
        (uint128 reserveX, uint128 reserveY) = poolManager.getBin(poolId, activeId);
        assertEq(reserveX, 1e18 + amt0);
        assertEq(reserveY, 1e18 + amt1);
    }

    function testDonateOverflow_BinReserve() public {
        // Initialize and add 1e18 token0, token1 to the active bin
        poolManager.initialize(key, activeId, new bytes(0));
        addLiquidityToBin(key, poolManager, bob, activeId, 1e18, 1e18, 1e18, 1e18, "");

        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        poolManager.donate(key, type(uint128).max, type(uint128).max, "");

        // Should still overflow as active bin has 1e18 already
        vm.expectRevert(PackedUint128Math.PackedUint128Math__AddOverflow.selector);
        poolManager.donate(key, type(uint128).max - 1e18 + 1, type(uint128).max - 1e18 + 1, "");
    }

    function testDonateOverflow_LiquidityOverflow() public {
        // liquidity can overflow when  price * x > type(uint256).max
        uint24 binId = activeId + 60_000; // price: 3.7e64

        // Initialize and add 1e18 token0, token1 to the active bin.
        poolManager.initialize(key, binId, new bytes(0));
        addLiquidityToBin(key, poolManager, bob, binId, 1, 1, 1e18, 1e18, "");

        // scenario 1: L = 3.7e64 * 3.4e38 will be greater than 2**256
        vm.expectRevert(BinHelper.BinHelper__LiquidityOverflow.selector);
        poolManager.donate(key, type(uint128).max - 1e18, 0, "");
    }
}
