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
import {IVault} from "../../src/interfaces/IVault.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {MockVault} from "../../src/test/MockVault.sol";
import {MockBinHooks} from "../../src/test/pool-bin/MockBinHooks.sol";
import {Vault} from "../../src/Vault.sol";
import {Currency} from "../../src/types/Currency.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../src/types/PoolId.sol";
import {BinPoolManager} from "../../src/pool-bin/BinPoolManager.sol";
import {BinPool} from "../../src/pool-bin/libraries/BinPool.sol";
import {BinPoolParametersHelper} from "../../src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";
import {Hooks} from "../../src/libraries/Hooks.sol";
import {BinTestHelper} from "./helpers/BinTestHelper.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";

contract BinHookTest is BinTestHelper, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using BinPoolParametersHelper for bytes32;

    error PoolAlreadyInitialized();

    bytes constant ZERO_BYTES = new bytes(0);
    uint24 binId = ID_ONE; // where token price are the same

    uint16 hookBitMapWithAllHooks;
    MockVault public vault;
    BinPoolManager public poolManager;
    MockBinHooks mockHooks;
    PoolKey key;
    address bob = makeAddr("bob");

    function setUp() public {
        vault = new MockVault();
        poolManager = new BinPoolManager(IVault(address(vault)), 500000);
        mockHooks = new MockBinHooks();
    }

    function testBeforeInitializeInvalidReturn() public {
        // 0000 0000 0000 0001
        uint16 bitMap = 0x0001;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.beforeInitialize.selector, bytes4(0xdeadbeef));
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.initialize(key, binId, ZERO_BYTES);
    }

    function testAfterInitializeInvalidReturn() public {
        // 0000 0000 0000 0010
        uint16 bitMap = 0x0002;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.afterInitialize.selector, bytes4(0xdeadbeef));
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.initialize(key, binId, ZERO_BYTES);
    }

    function testInitializeSucceedsWithHook() public {
        // 0000 0000 0000 0011
        uint16 bitMap = 0x0003;
        _createPoolWithBitMap(bitMap);

        snapStart("BinHookTest#testInitializeSucceedsWithHook");
        poolManager.initialize(key, binId, new bytes(123));
        snapEnd();
        assertEq(mockHooks.beforeInitializeData(), new bytes(123));
        assertEq(mockHooks.afterInitializeData(), new bytes(123));
    }

    function testMintInvalidReturn() public {
        // 0000 0000 0000 0100
        uint16 bitMap = 0x0004;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.beforeMint.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, "");
    }

    function testAfterMintInvalidReturn() public {
        // 0000 0000 0000 1000
        uint16 bitMap = 0x0008;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.afterMint.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, "");
    }

    function testMintSucceedsWithHook() public {
        // 0000 0000 0000 1100
        uint16 bitMap = 0x000c;
        _createPoolWithBitMap(bitMap);

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");

        snapStart("BinHookTest#testMintSucceedsWithHook");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));
        snapEnd();

        assertEq(mockHooks.beforeMintData(), new bytes(123));
        assertEq(mockHooks.afterMintData(), new bytes(123));
    }

    function testBurnSucceedsWithHook() public {
        // 0000 0000 0011 0000
        uint16 bitMap = 0x0030;
        _createPoolWithBitMap(bitMap);

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        uint256 bobBal = poolManager.getPosition(key.toId(), bob, binId).share;

        snapStart("BinHookTest#testBurnSucceedsWithHook");
        removeLiquidityFromBin(key, poolManager, bob, binId, bobBal, new bytes(456));
        snapEnd();

        assertEq(mockHooks.beforeBurnData(), new bytes(456));
        assertEq(mockHooks.afterBurnData(), new bytes(456));
    }

    function testBurnInvalidReturn() public {
        // 0000 0000 0001 0000
        uint16 bitMap = 0x0010;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.beforeBurn.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, "");

        uint256 bobBal = poolManager.getPosition(key.toId(), bob, binId).share;
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        removeLiquidityFromBin(key, poolManager, bob, binId, bobBal, "");
    }

    function testAfterBurnInvalidReturn() public {
        // 0000 0000 0010 0000
        uint16 bitMap = 0x0020;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.afterBurn.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, "");

        uint256 bobBal = poolManager.getPosition(key.toId(), bob, binId).share;
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        removeLiquidityFromBin(key, poolManager, bob, binId, bobBal, "");
    }

    function testSwapSucceedsWithHook() public {
        // 0000 0000 1100 0000
        uint16 bitMap = 0x00c0;
        _createPoolWithBitMap(bitMap);

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        snapStart("BinHookTest#testSwapSucceedsWithHook");
        poolManager.swap(key, true, 1e18, new bytes(456));
        snapEnd();

        assertEq(mockHooks.beforeSwapData(), new bytes(456));
        assertEq(mockHooks.afterSwapData(), new bytes(456));
    }

    function testSwapInvalidReturn() public {
        // 0000 0000 0100 0000
        uint16 bitMap = 0x0040;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.swap(key, true, 1e18, new bytes(456));
    }

    function testAfterSwapInvalidReturn() public {
        // 0000 0000 1000 0000
        uint16 bitMap = 0x0080;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.afterSwap.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.swap(key, true, 1e18, new bytes(456));
    }

    function testDonateSucceedsWithHook() public {
        // 0000 0011 0000 0000
        uint16 bitMap = 0x0300;
        _createPoolWithBitMap(bitMap);

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        snapStart("BinHookTest#testDonateSucceedsWithHook");
        poolManager.donate(key, 1e18, 1e18, new bytes(456));
        snapEnd();

        assertEq(mockHooks.beforeDonateData(), new bytes(456));
        assertEq(mockHooks.afterDonateData(), new bytes(456));
    }

    function testBeforeDonateInvalidReturn() public {
        // 0000 0001 0000 0000
        uint16 bitMap = 0x0100;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.donate(key, 1e18, 1e18, new bytes(456));
    }

    function testAfterDonateInvalidReturn() public {
        // 0000 0010 0000 0000
        uint16 bitMap = 0x0200;
        _createPoolWithBitMap(bitMap);

        mockHooks.setReturnValue(mockHooks.afterDonate.selector, bytes4(0xdeadbeef));

        // initialize and add 1e18 token0, 1e18 token1 into a single binId
        poolManager.initialize(key, binId, "");
        addLiquidityToBin(key, poolManager, bob, binId, 1e18, 1e18, 1e18, 1e18, new bytes(123));

        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.donate(key, 1e18, 1e18, new bytes(456));
    }

    function _createPoolWithBitMap(uint16 _bitMap) internal {
        mockHooks.setHooksRegistrationBitmap(_bitMap);
        key = PoolKey({
            currency0: Currency.wrap(makeAddr("token0")),
            currency1: Currency.wrap(makeAddr("token1")),
            hooks: IHooks(address(mockHooks)),
            poolManager: IPoolManager(address(poolManager)),
            fee: uint24(3000),
            parameters: bytes32(uint256(_bitMap)).setBinStep(1)
        });
    }
}
