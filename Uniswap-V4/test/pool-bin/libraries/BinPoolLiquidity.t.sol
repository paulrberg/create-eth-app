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

import {stdError} from "Uniswap-V4/forge-std/StdError.sol";
import {IVault} from "../../../src/interfaces/IVault.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {IPoolManager} from "../../../src/interfaces/IPoolManager.sol";
import {MockVault} from "../../../src/test/MockVault.sol";
import {Currency} from "../../../src/types/Currency.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BalanceDelta, toBalanceDelta} from "../../../src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {BinPoolManager} from "../../../src/pool-bin/BinPoolManager.sol";
import {BinPool} from "../../../src/pool-bin/libraries/BinPool.sol";
import {Constants} from "../../../src/pool-bin/libraries/Constants.sol";
import {PackedUint128Math} from "../../../src/pool-bin/libraries/math/PackedUint128Math.sol";
import {SafeCast} from "../../../src/pool-bin/libraries/math/SafeCast.sol";
import {LiquidityConfigurations} from "../../../src/pool-bin/libraries/math/LiquidityConfigurations.sol";
import {IBinPoolManager} from "../../../src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinPoolParametersHelper} from "../../../src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {BinTestHelper} from "../helpers/BinTestHelper.sol";

contract BinPoolLiquidityTest is BinTestHelper {
    using PoolIdLibrary for PoolKey;
    using PackedUint128Math for bytes32;
    using BinPoolParametersHelper for bytes32;
    using SafeCast for uint256;

    MockVault public vault;
    BinPoolManager public poolManager;

    uint24 immutable activeId = ID_ONE - 24647; // id where 1 NATIVE = 20 USDC

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

    function test_SimpleMintX() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256 amountX = 120 * 10 ** 18;
        uint256 amountY = 2_400 * 10 ** 6;
        uint8 nbBinX = 6;
        uint8 nbBinY = 6;

        BinPool.MintArrays memory array;
        (, array) = addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, nbBinY);

        {
            // verify X and Y amount
            uint256 amtXBalanceDelta = uint256(int256(vault.balanceDeltaOfPool(poolId).amount0()));
            uint256 amountXLeft = amountX - ((amountX * (Constants.PRECISION / nbBinX)) / 1e18) * nbBinX;
            assertEq(amountX, amtXBalanceDelta + amountXLeft, "test_SimpleMint::1");

            uint256 amtYBalanceDelta = uint256(int256(vault.balanceDeltaOfPool(poolId).amount1()));
            uint256 amountYLeft = amountY - ((amountY * (Constants.PRECISION / nbBinY)) / 1e18) * nbBinY;
            assertEq(amountY, amtYBalanceDelta + amountYLeft, "test_SimpleMint::1");
        }
        {
            // verify each binId has the right reserve
            uint256 total = getTotalBins(nbBinX, nbBinY);
            for (uint256 i; i < total; ++i) {
                uint24 id = getId(activeId, i, nbBinY);

                (uint128 binReserveX, uint128 binReserveY) = poolManager.getBin(poolId, id);

                if (id < activeId) {
                    assertEq(binReserveX, 0, "test_SimpleMint::3");
                    assertEq(binReserveY, (amountY * (Constants.PRECISION / nbBinY)) / 1e18, "test_SimpleMint::4");
                } else if (id == activeId) {
                    assertApproxEqRel(
                        binReserveX, (amountX * (Constants.PRECISION / nbBinX)) / 1e18, 1e15, "test_SimpleMint::5"
                    );
                    assertApproxEqRel(
                        binReserveY, (amountY * (Constants.PRECISION / nbBinY)) / 1e18, 1e15, "test_SimpleMint::6"
                    );
                } else {
                    assertEq(binReserveX, (amountX * (Constants.PRECISION / nbBinX)) / 1e18, "test_SimpleMint::7");
                    assertEq(binReserveY, 0, "test_SimpleMint::8");
                }

                assertGt(poolManager.getPosition(poolId, bob, id).share, 0, "test_SimpleMint::9");
            }
        }
        {
            uint256 total = getTotalBins(nbBinX, nbBinY);
            for (uint256 i; i < total; ++i) {
                uint24 id = getId(activeId, i, nbBinY);

                // verify id
                assertEq(id, array.ids[i]);

                // verify amount
                (uint128 x, uint128 y) = array.amounts[i].decode();
                if (id < activeId) {
                    assertEq(x, 0);
                    assertApproxEqRel(y, amountY / 6, 1e15); // approx amount within 0.1%,
                } else if (id == activeId) {
                    assertApproxEqRel(y, amountY / 6, 1e15); // approx amount within 0.1%
                    assertApproxEqRel(x, amountX / 6, 1e15); // approx amount within 0.1%
                } else {
                    assertApproxEqRel(x, amountX / 6, 1e15); // approx amount within 0.1%
                    assertEq(y, 0);
                }

                // verify liquidity minted
                assertEq(poolManager.getPosition(poolId, bob, id).share, array.liquidityMinted[i]);
            }
        }
    }

    function test_MintTwice() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256 amountX = 100 * 10 ** 18;
        uint256 amountY = 2_000 * 10 ** 6;
        uint8 nbBinX = 6;
        uint8 nbBinY = 6;

        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, nbBinY);

        uint256 total = getTotalBins(nbBinX, nbBinY);
        uint256[] memory balances = new uint256[](total);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);
            balances[i] = poolManager.getPosition(poolId, bob, id).share;
        }

        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, nbBinY);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);

            // (uint128 binReserveX, uint128 binReserveY) = pairWnative.getBin(id);
            (uint128 binReserveX, uint128 binReserveY) = poolManager.getBin(poolId, id);

            if (id < activeId) {
                assertEq(binReserveX, 0, "test_SimpleMint::1");
                assertEq(binReserveY, 2 * ((amountY * (Constants.PRECISION / nbBinY)) / 1e18), "test_SimpleMint::2");
            } else if (id == activeId) {
                assertApproxEqRel(
                    binReserveX, 2 * ((amountX * (Constants.PRECISION / nbBinX)) / 1e18), 1e15, "test_SimpleMint::3"
                );
                assertApproxEqRel(
                    binReserveY, 2 * ((amountY * (Constants.PRECISION / nbBinY)) / 1e18), 1e15, "test_SimpleMint::4"
                );
            } else {
                assertEq(binReserveX, 2 * ((amountX * (Constants.PRECISION / nbBinX)) / 1e18), "test_SimpleMint::5");
                assertEq(binReserveY, 0, "test_SimpleMint::6");
            }

            assertEq(poolManager.getPosition(poolId, bob, id).share, 2 * balances[i], "test_DoubleMint:7");
        }
    }

    function test_MintWithDifferentBins() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256 amountX = 100 * 10 ** 18;
        uint256 amountY = 2_000 * 10 ** 6;
        uint8 nbBinX = 6;
        uint8 nbBinY = 6;

        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, nbBinY);

        uint256 total = getTotalBins(nbBinX, nbBinY);
        uint256[] memory balances = new uint256[](total);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);
            balances[i] = poolManager.getPosition(poolId, bob, id).share;
        }

        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, 0);
        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, 0, nbBinY);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);

            if (id == activeId) {
                assertApproxEqRel(
                    poolManager.getPosition(poolId, bob, id).share,
                    2 * balances[i],
                    1e15,
                    "test_MintWithDifferentBins::1"
                ); // composition fee
            } else {
                assertEq(
                    poolManager.getPosition(poolId, bob, id).share, 2 * balances[i], "test_MintWithDifferentBins::2"
                );
            }
        }
    }

    function test_revert_MintEmptyConfig() public {
        poolManager.initialize(key, activeId, new bytes(0));

        IBinPoolManager.MintParams memory params =
            IBinPoolManager.MintParams({liquidityConfigs: new bytes32[](0), amountIn: PackedUint128Math.encode(0, 0)});

        vm.expectRevert(BinPool.BinPool__EmptyLiquidityConfigs.selector);
        poolManager.mint(key, params, "0x00");
    }

    function test_revert_MintZeroShares() external {
        poolManager.initialize(key, activeId, new bytes(0));

        bytes32[] memory data = new bytes32[](1);
        data[0] = LiquidityConfigurations.encodeParams(1e18, 1e18, activeId);

        IBinPoolManager.MintParams memory params =
            IBinPoolManager.MintParams({liquidityConfigs: data, amountIn: PackedUint128Math.encode(0, 0)});

        vm.expectRevert(abi.encodeWithSelector(BinPool.BinPool__ZeroShares.selector, activeId));
        poolManager.mint(key, params, "0x00");
    }

    function test_revert_MintMoreThanAmountSent() external {
        poolManager.initialize(key, activeId, new bytes(0));

        bytes32[] memory data = new bytes32[](2);
        data[0] = LiquidityConfigurations.encodeParams(0, 0.5e18, activeId - 1);
        data[1] = LiquidityConfigurations.encodeParams(0, 0.5e18 + 1, activeId);
        vm.expectRevert(PackedUint128Math.PackedUint128Math__SubUnderflow.selector);

        IBinPoolManager.MintParams memory params =
            IBinPoolManager.MintParams({liquidityConfigs: data, amountIn: PackedUint128Math.encode(1e18, 1e18)});
        poolManager.mint(key, params, "0x00");

        data[1] = LiquidityConfigurations.encodeParams(0.5e18, 0, activeId);
        data[0] = LiquidityConfigurations.encodeParams(0.5e18 + 1, 0, activeId + 1);
        vm.expectRevert(PackedUint128Math.PackedUint128Math__SubUnderflow.selector);
        params = IBinPoolManager.MintParams({liquidityConfigs: data, amountIn: PackedUint128Math.encode(1e18, 1e18)});
        poolManager.mint(key, params, "0x00");
    }

    function test_SimpleBurn() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256 amountX = 100 * 10 ** 18;
        uint256 amountY = 100 * 10 ** 18;
        uint8 nbBinX = 6;
        uint8 nbBinY = 6;

        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, nbBinY);
        uint256 total = getTotalBins(nbBinX, nbBinY);

        uint256[] memory balances = new uint256[](total);
        uint256[] memory ids = new uint256[](total);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);
            ids[i] = id;
            balances[i] = poolManager.getPosition(poolId, bob, id).share;
        }

        uint256 reserveX = vault.reservesOfPoolManager(key.poolManager, key.currency0);
        uint256 reserveY = vault.reservesOfPoolManager(key.poolManager, key.currency1);

        removeLiquidity(key, poolManager, bob, ids, balances);

        {
            // balanceDelta negative (so user need to call take/mint)
            uint256 balanceDelta0 = uint128(-vault.balanceDeltaOfPool(poolId).amount0());
            assertEq(uint256(balanceDelta0), reserveX, "test_SimpleBurn::1");
            uint256 balanceDelta1 = uint128(-vault.balanceDeltaOfPool(poolId).amount1());
            assertEq(uint256(balanceDelta1), reserveY, "test_SimpleBurn::1");
        }

        reserveX = vault.reservesOfPoolManager(key.poolManager, key.currency0);
        reserveY = vault.reservesOfPoolManager(key.poolManager, key.currency1);
        assertEq(reserveX, 0, "test_BurnPartial::3");
        assertEq(reserveY, 0, "test_BurnPartial::4");
    }

    function test_BurnHalfTwice() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256 amountX = 100 * 10 ** 18;
        uint256 amountY = 100 * 10 ** 18;
        uint8 nbBinX = 6;
        uint8 nbBinY = 6;

        addLiquidity(key, poolManager, bob, activeId, amountX, amountY, nbBinX, nbBinY);

        uint256 total = getTotalBins(nbBinX, nbBinY);

        uint256[] memory halfbalances = new uint256[](total);
        uint256[] memory balances = new uint256[](total);
        uint256[] memory ids = new uint256[](total);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);

            ids[i] = id;
            uint256 balance = poolManager.getPosition(poolId, bob, id).share;

            halfbalances[i] = balance / 2;
            balances[i] = balance - balance / 2;
        }

        uint256 reserveX = vault.reservesOfPoolManager(key.poolManager, key.currency0); // vault.reservesOfPool(poolId, 0);
        uint256 reserveY = vault.reservesOfPoolManager(key.poolManager, key.currency1); // vault.reservesOfPool(poolId, 1);

        removeLiquidity(key, poolManager, bob, ids, halfbalances);

        {
            // balanceDelta negative (so user need to call take/mint)
            uint256 balanceDelta0 = uint128(-vault.balanceDeltaOfPool(poolId).amount0());
            assertApproxEqRel(uint256(balanceDelta0), reserveX / 2, 1e10, "test_BurnPartial::1");
            uint256 balanceDelta1 = uint128(-vault.balanceDeltaOfPool(poolId).amount1());
            assertApproxEqRel(uint256(balanceDelta1), reserveY / 2, 1e10, "test_BurnPartial::2");
        }

        removeLiquidity(key, poolManager, bob, ids, halfbalances);

        reserveX = vault.reservesOfPoolManager(key.poolManager, key.currency0); // vault.reservesOfPool(poolId, 0);
        reserveY = vault.reservesOfPoolManager(key.poolManager, key.currency1); // vault.reservesOfPool(poolId, 1);
        assertEq(reserveX, 0, "test_BurnPartial::5");
        assertEq(reserveY, 0, "test_BurnPartial::6");
    }

    function test_revert_BurnEmptyArraysOrDifferent() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256[] memory ids = new uint256[](0);
        uint256[] memory balances = new uint256[](1);

        vm.expectRevert(BinPool.BinPool__InvalidBurnInput.selector);
        removeLiquidity(key, poolManager, bob, ids, balances);

        ids = new uint256[](1);
        balances = new uint256[](0);

        vm.expectRevert(BinPool.BinPool__InvalidBurnInput.selector);
        removeLiquidity(key, poolManager, bob, ids, balances);

        ids = new uint256[](0);
        balances = new uint256[](0);

        vm.expectRevert(BinPool.BinPool__InvalidBurnInput.selector);
        removeLiquidity(key, poolManager, bob, ids, balances);

        ids = new uint256[](1);
        balances = new uint256[](2);

        vm.expectRevert(BinPool.BinPool__InvalidBurnInput.selector);
        removeLiquidity(key, poolManager, bob, ids, balances);
    }

    function test_revert_BurnMoreThanBalance() external {
        poolManager.initialize(key, activeId, new bytes(0));

        addLiquidity(key, poolManager, alice, activeId, 1e18, 1e18, 1, 0);
        addLiquidity(key, poolManager, bob, activeId, 1e18, 1e18, 1, 0);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory balances = new uint256[](1);

        ids[0] = activeId;
        balances[0] = poolManager.getPosition(poolId, bob, activeId).share + 1;

        vm.expectRevert(stdError.arithmeticError);
        removeLiquidity(key, poolManager, bob, ids, balances);
    }

    function test_revert_BurnZeroShares() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256[] memory ids = new uint256[](1);
        uint256[] memory balances = new uint256[](1);

        ids[0] = activeId;
        balances[0] = 0;

        vm.expectRevert(abi.encodeWithSelector(BinPool.BinPool__BurnZeroAmount.selector, activeId));
        removeLiquidity(key, poolManager, alice, ids, balances);
    }

    function test_revert_BurnForZeroAmounts() external {
        poolManager.initialize(key, activeId, new bytes(0));

        uint256[] memory ids = new uint256[](1);
        uint256[] memory balances = new uint256[](1);

        ids[0] = activeId;
        balances[0] = 1;

        addLiquidity(key, poolManager, bob, activeId, 1e18, 1e18, 1, 1);

        vm.expectRevert(abi.encodeWithSelector(BinPool.BinPool__ZeroAmountsOut.selector, activeId));
        removeLiquidity(key, poolManager, bob, ids, balances);
    }
}
