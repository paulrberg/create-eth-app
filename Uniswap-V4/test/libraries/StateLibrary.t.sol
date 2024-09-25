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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "Uniswap-V4/forge-std/Test.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";
import {Hooks} from "../../src/libraries/Hooks.sol";
import {TickMath} from "../../src/libraries/TickMath.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {BalanceDelta} from "../../src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "../../src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "../../src/types/Currency.sol";
import {Deployers} from "../utils/Deployers.sol";
import {FixedPointMathLib} from "Uniswap-V4/solmate/utils/FixedPointMathLib.sol";
import {Pool} from "../../src/libraries/Pool.sol";
import {TickBitmap} from "../../src/libraries/TickBitmap.sol";
import {FixedPoint128} from "../../src/libraries/FixedPoint128.sol";

import {StateLibrary} from "../../src/libraries/StateLibrary.sol";
import {Fuzzers} from "../../src/test/Fuzzers.sol";

contract StateLibraryTest is Test, Deployers, Fuzzers, GasSnapshot {
    using FixedPointMathLib for uint256;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    PoolId poolId;

    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        Deployers.deployFreshManagerAndRouters();
        (currency0, currency1) = Deployers.deployMintAndApprove2Currencies();

        // Create the pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(0x0)));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
    }

    function test_getSlot0() public {
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, 10_000 ether, 0), ZERO_BYTES
        );

        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-600, 600, 10_000 ether, 0), ZERO_BYTES
        );

        // swap to create fees, crossing a tick
        uint256 swapAmount = 100 ether;
        swap(key, true, -int256(swapAmount), ZERO_BYTES);
        (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 swapFee) = StateLibrary.getSlot0(manager, poolId);
        snapLastCall("extsload getSlot0");
        assertEq(tick, -139);

        // magic number verified against a native getter
        assertEq(sqrtPriceX96, 78680104762184586858280382455);
        assertEq(tick, -139);
        assertEq(protocolFee, 0); // tested in protocol fee tests
        assertEq(swapFee, 3000);
    }

    function test_getTickLiquidity() public {
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether, 0), ZERO_BYTES);

        (uint128 liquidityGrossLower, int128 liquidityNetLower) = StateLibrary.getTickLiquidity(manager, poolId, -60);
        snapLastCall("extsload getTickLiquidity");
        assertEq(liquidityGrossLower, 10 ether);
        assertEq(liquidityNetLower, 10 ether);

        (uint128 liquidityGrossUpper, int128 liquidityNetUpper) = StateLibrary.getTickLiquidity(manager, poolId, 60);
        assertEq(liquidityGrossUpper, 10 ether);
        assertEq(liquidityNetUpper, -10 ether);
    }

    function test_fuzz_getTickLiquidity(IPoolManager.ModifyLiquidityParams memory params) public {
        (IPoolManager.ModifyLiquidityParams memory _params,) =
            Fuzzers.createFuzzyLiquidity(modifyLiquidityRouter, key, params, SQRT_PRICE_1_1, ZERO_BYTES);
        uint128 liquidityDelta = uint128(uint256(_params.liquidityDelta));

        (uint128 liquidityGrossLower, int128 liquidityNetLower) =
            StateLibrary.getTickLiquidity(manager, poolId, _params.tickLower);
        assertEq(liquidityGrossLower, liquidityDelta);
        assertEq(liquidityNetLower, int128(_params.liquidityDelta));

        (uint128 liquidityGrossUpper, int128 liquidityNetUpper) =
            StateLibrary.getTickLiquidity(manager, poolId, _params.tickUpper);
        assertEq(liquidityGrossUpper, liquidityDelta);
        assertEq(liquidityNetUpper, -int128(_params.liquidityDelta));

        // confirm agreement with getTickInfo()
        (uint128 _liquidityGrossLower, int128 _liquidityNetLower,,) =
            StateLibrary.getTickInfo(manager, poolId, _params.tickLower);
        assertEq(_liquidityGrossLower, liquidityGrossLower);
        assertEq(_liquidityNetLower, liquidityNetLower);

        (uint128 _liquidityGrossUpper, int128 _liquidityNetUpper,,) =
            StateLibrary.getTickInfo(manager, poolId, _params.tickUpper);
        assertEq(_liquidityGrossUpper, liquidityGrossUpper);
        assertEq(_liquidityNetUpper, liquidityNetUpper);
    }

    function test_fuzz_getTickLiquidity_two_positions(
        IPoolManager.ModifyLiquidityParams memory paramsA,
        IPoolManager.ModifyLiquidityParams memory paramsB
    ) public {
        (IPoolManager.ModifyLiquidityParams memory _paramsA,) =
            Fuzzers.createFuzzyLiquidityWithTightBound(modifyLiquidityRouter, key, paramsA, SQRT_PRICE_1_1, ZERO_BYTES);
        (IPoolManager.ModifyLiquidityParams memory _paramsB,) =
            Fuzzers.createFuzzyLiquidityWithTightBound(modifyLiquidityRouter, key, paramsB, SQRT_PRICE_1_1, ZERO_BYTES);

        uint128 liquidityDeltaA = uint128(uint256(_paramsA.liquidityDelta));
        uint128 liquidityDeltaB = uint128(uint256(_paramsB.liquidityDelta));

        (uint128 liquidityGrossLowerA, int128 liquidityNetLowerA) =
            StateLibrary.getTickLiquidity(manager, poolId, _paramsA.tickLower);
        (uint128 liquidityGrossLowerB, int128 liquidityNetLowerB) =
            StateLibrary.getTickLiquidity(manager, poolId, _paramsB.tickLower);
        (uint256 liquidityGrossUpperA, int256 liquidityNetUpperA) =
            StateLibrary.getTickLiquidity(manager, poolId, _paramsA.tickUpper);
        (uint256 liquidityGrossUpperB, int256 liquidityNetUpperB) =
            StateLibrary.getTickLiquidity(manager, poolId, _paramsB.tickUpper);

        // when tick lower is shared between two positions, the gross liquidity is the sum
        if (_paramsA.tickLower == _paramsB.tickLower || _paramsA.tickLower == _paramsB.tickUpper) {
            assertEq(liquidityGrossLowerA, liquidityDeltaA + liquidityDeltaB);

            // when tick lower is shared with an upper tick, the net liquidity is the difference
            (_paramsA.tickLower == _paramsB.tickLower)
                ? assertEq(liquidityNetLowerA, int128(liquidityDeltaA + liquidityDeltaB))
                : assertApproxEqAbs(liquidityNetLowerA, int128(liquidityDeltaA) - int128(liquidityDeltaB), 1 wei);
        } else {
            assertEq(liquidityGrossLowerA, liquidityDeltaA);
            assertEq(liquidityNetLowerA, int128(liquidityDeltaA));
        }

        if (_paramsA.tickUpper == _paramsB.tickLower || _paramsA.tickUpper == _paramsB.tickUpper) {
            assertEq(liquidityGrossUpperA, liquidityDeltaA + liquidityDeltaB);
            (_paramsA.tickUpper == _paramsB.tickUpper)
                ? assertEq(liquidityNetUpperA, -int128(liquidityDeltaA + liquidityDeltaB))
                : assertApproxEqAbs(liquidityNetUpperA, int128(liquidityDeltaB) - int128(liquidityDeltaA), 2 wei);
        } else {
            assertEq(liquidityGrossUpperA, liquidityDeltaA);
            assertEq(liquidityNetUpperA, -int128(liquidityDeltaA));
        }

        if (_paramsB.tickLower == _paramsA.tickLower || _paramsB.tickLower == _paramsA.tickUpper) {
            assertEq(liquidityGrossLowerB, liquidityDeltaA + liquidityDeltaB);
            (_paramsB.tickLower == _paramsA.tickLower)
                ? assertEq(liquidityNetLowerB, int128(liquidityDeltaA + liquidityDeltaB))
                : assertApproxEqAbs(liquidityNetLowerB, int128(liquidityDeltaB) - int128(liquidityDeltaA), 1 wei);
        } else {
            assertEq(liquidityGrossLowerB, liquidityDeltaB);
            assertEq(liquidityNetLowerB, int128(liquidityDeltaB));
        }

        if (_paramsB.tickUpper == _paramsA.tickLower || _paramsB.tickUpper == _paramsA.tickUpper) {
            assertEq(liquidityGrossUpperB, liquidityDeltaA + liquidityDeltaB);
            (_paramsB.tickUpper == _paramsA.tickUpper)
                ? assertEq(liquidityNetUpperB, -int128(liquidityDeltaA + liquidityDeltaB))
                : assertApproxEqAbs(liquidityNetUpperB, int128(liquidityDeltaA) - int128(liquidityDeltaB), 2 wei);
        } else {
            assertEq(liquidityGrossUpperB, liquidityDeltaB);
            assertEq(liquidityNetUpperB, -int128(liquidityDeltaB));
        }
    }

    function test_getFeeGrowthGlobals0() public {
        // create liquidity
        uint256 liquidity = 10_000 ether;
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, int256(liquidity), 0), ZERO_BYTES
        );

        (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) = StateLibrary.getFeeGrowthGlobals(manager, poolId);
        assertEq(feeGrowthGlobal0, 0);
        assertEq(feeGrowthGlobal1, 0);

        // swap to create fees on the input token (currency0)
        uint256 swapAmount = 10 ether;
        swap(key, true, -int256(swapAmount), ZERO_BYTES);

        (feeGrowthGlobal0, feeGrowthGlobal1) = StateLibrary.getFeeGrowthGlobals(manager, poolId);
        snapLastCall("extsload getFeeGrowthGlobals");

        uint256 feeGrowthGlobalCalc = swapAmount.mulWadDown(0.003e18).mulDivDown(FixedPoint128.Q128, liquidity);
        assertEq(feeGrowthGlobal0, feeGrowthGlobalCalc);
        assertEq(feeGrowthGlobal1, 0);
    }

    function test_getFeeGrowthGlobals1() public {
        // create liquidity
        uint256 liquidity = 10_000 ether;
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, int256(liquidity), 0), ZERO_BYTES
        );

        (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) = StateLibrary.getFeeGrowthGlobals(manager, poolId);
        assertEq(feeGrowthGlobal0, 0);
        assertEq(feeGrowthGlobal1, 0);

        // swap to create fees on the input token (currency1)
        uint256 swapAmount = 10 ether;
        swap(key, false, -int256(swapAmount), ZERO_BYTES);

        (feeGrowthGlobal0, feeGrowthGlobal1) = StateLibrary.getFeeGrowthGlobals(manager, poolId);

        assertEq(feeGrowthGlobal0, 0);
        uint256 feeGrowthGlobalCalc = swapAmount.mulWadDown(0.003e18).mulDivDown(FixedPoint128.Q128, liquidity);
        assertEq(feeGrowthGlobal1, feeGrowthGlobalCalc);
    }

    function test_getLiquidity() public {
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether, 0), ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-120, 120, 10 ether, 0), ZERO_BYTES
        );

        uint128 liquidity = StateLibrary.getLiquidity(manager, poolId);
        snapLastCall("extsload getLiquidity");
        assertEq(liquidity, 20 ether);
    }

    function test_fuzz_getLiquidity(IPoolManager.ModifyLiquidityParams memory params) public {
        (IPoolManager.ModifyLiquidityParams memory _params,) =
            Fuzzers.createFuzzyLiquidity(modifyLiquidityRouter, key, params, SQRT_PRICE_1_1, ZERO_BYTES);
        (, int24 tick,,) = StateLibrary.getSlot0(manager, poolId);
        uint128 liquidity = StateLibrary.getLiquidity(manager, poolId);

        // out of range liquidity is not added to Pool.State.liquidity
        if (tick < _params.tickLower || tick >= _params.tickUpper) {
            assertEq(liquidity, 0);
        } else {
            assertEq(liquidity, uint128(uint256(_params.liquidityDelta)));
        }
    }

    function test_getTickBitmap() public {
        int24 tickLower = -300;
        int24 tickUpper = 300;
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(tickLower, tickUpper, 10_000 ether, 0), ZERO_BYTES
        );

        (int16 wordPos, uint8 bitPos) = TickBitmap.position(tickLower / key.tickSpacing);
        uint256 tickBitmap = StateLibrary.getTickBitmap(manager, poolId, wordPos);
        snapLastCall("extsload getTickBitmap");
        assertNotEq(tickBitmap, 0);
        assertEq(tickBitmap, 1 << bitPos);

        (wordPos, bitPos) = TickBitmap.position(tickUpper / key.tickSpacing);
        tickBitmap = StateLibrary.getTickBitmap(manager, poolId, wordPos);
        assertNotEq(tickBitmap, 0);
        assertEq(tickBitmap, 1 << bitPos);
    }

    function test_fuzz_getTickBitmap(IPoolManager.ModifyLiquidityParams memory params) public {
        (IPoolManager.ModifyLiquidityParams memory _params,) =
            Fuzzers.createFuzzyLiquidity(modifyLiquidityRouter, key, params, SQRT_PRICE_1_1, ZERO_BYTES);

        (int16 wordPos, uint8 bitPos) = TickBitmap.position(_params.tickLower / key.tickSpacing);
        (int16 wordPosUpper, uint8 bitPosUpper) = TickBitmap.position(_params.tickUpper / key.tickSpacing);

        uint256 tickBitmap = StateLibrary.getTickBitmap(manager, poolId, wordPos);
        assertNotEq(tickBitmap, 0);

        // in fuzz tests, the tickLower and tickUpper might exist on the same word
        if (wordPos == wordPosUpper) {
            assertEq(tickBitmap, (1 << bitPos) | (1 << bitPosUpper));
        } else {
            assertEq(tickBitmap, 1 << bitPos);
        }
    }

    function test_getPositionInfo() public {
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, 10_000 ether, 0), ZERO_BYTES
        );

        // swap to create fees, crossing a tick
        uint256 swapAmount = 10 ether;
        swap(key, true, -int256(swapAmount), ZERO_BYTES);
        (, int24 currentTick,,) = StateLibrary.getSlot0(manager, poolId);
        assertNotEq(currentTick, -139);

        // poke the LP so that fees are updated
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 0, 0), ZERO_BYTES);

        bytes32 positionId =
            keccak256(abi.encodePacked(address(modifyLiquidityRouter), int24(-60), int24(60), bytes32(0)));

        (uint128 liquidity, uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            StateLibrary.getPositionInfo(manager, poolId, positionId);
        snapLastCall("extsload getPositionInfo");

        assertEq(liquidity, 10_000 ether);

        assertNotEq(feeGrowthInside0X128, 0);
        assertEq(feeGrowthInside1X128, 0);
    }

    function test_fuzz_getPositionInfo(
        IPoolManager.ModifyLiquidityParams memory params,
        uint256 swapAmount,
        bool zeroForOne
    ) public {
        (IPoolManager.ModifyLiquidityParams memory _params, BalanceDelta delta) =
            createFuzzyLiquidity(modifyLiquidityRouter, key, params, SQRT_PRICE_1_1, ZERO_BYTES);

        uint256 delta0 = uint256(int256(-delta.amount0()));
        uint256 delta1 = uint256(int256(-delta.amount1()));
        // if one of the deltas is zero, ensure to swap in the right direction
        if (delta0 == 0) {
            zeroForOne = true;
        } else if (delta1 == 0) {
            zeroForOne = false;
        }
        swapAmount = bound(swapAmount, 1, uint256(int256(type(int128).max)));
        swap(key, zeroForOne, -int256(swapAmount), ZERO_BYTES);

        // poke the LP so that fees are updated
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(_params.tickLower, _params.tickUpper, 0, 0), ZERO_BYTES
        );

        bytes32 positionId = keccak256(
            abi.encodePacked(address(modifyLiquidityRouter), _params.tickLower, _params.tickUpper, bytes32(0))
        );

        (uint128 liquidity, uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            StateLibrary.getPositionInfo(manager, poolId, positionId);

        assertEq(liquidity, uint128(uint256(_params.liquidityDelta)));
        if (zeroForOne) {
            assertNotEq(feeGrowthInside0X128, 0);
            assertEq(feeGrowthInside1X128, 0);
        } else {
            assertEq(feeGrowthInside0X128, 0);
            assertNotEq(feeGrowthInside1X128, 0);
        }
    }

    function test_getTickFeeGrowthOutside() public {
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, 10_000 ether, 0), ZERO_BYTES
        );

        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-600, 600, 10_000 ether, 0), ZERO_BYTES
        );

        // swap to create fees, crossing a tick
        uint256 swapAmount = 100 ether;
        swap(key, true, -int256(swapAmount), ZERO_BYTES);
        (, int24 currentTick,,) = StateLibrary.getSlot0(manager, poolId);
        assertEq(currentTick, -139);

        int24 tick = -60;
        (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128) =
            StateLibrary.getTickFeeGrowthOutside(manager, poolId, tick);
        snapLastCall("extsload getTickFeeGrowthOutside");

        // magic number verified against a native getter on PoolManager
        assertEq(feeGrowthOutside0X128, 3076214778951936192155253373200636);
        assertEq(feeGrowthOutside1X128, 0);

        tick = 60;
        (feeGrowthOutside0X128, feeGrowthOutside1X128) = StateLibrary.getTickFeeGrowthOutside(manager, poolId, tick);
        assertEq(feeGrowthOutside0X128, 0);
        assertEq(feeGrowthOutside1X128, 0);
    }

    // also hard to fuzz because of feeGrowthOutside
    function test_getTickInfo() public {
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, 10_000 ether, 0), ZERO_BYTES
        );

        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-600, 600, 10_000 ether, 0), ZERO_BYTES
        );

        // swap to create fees, crossing a tick
        uint256 swapAmount = 100 ether;
        swap(key, true, -int256(swapAmount), ZERO_BYTES);
        (, int24 currentTick,,) = StateLibrary.getSlot0(manager, poolId);
        assertEq(currentTick, -139);

        int24 tick = -60;
        (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128) =
            StateLibrary.getTickInfo(manager, poolId, tick);
        snapLastCall("extsload getTickInfo");

        (uint128 liquidityGross_, int128 liquidityNet_) = StateLibrary.getTickLiquidity(manager, poolId, tick);
        (uint256 feeGrowthOutside0X128_, uint256 feeGrowthOutside1X128_) =
            StateLibrary.getTickFeeGrowthOutside(manager, poolId, tick);

        assertEq(liquidityGross, 10_000 ether);
        assertEq(liquidityGross, liquidityGross_);
        assertEq(liquidityNet, liquidityNet_);

        assertNotEq(feeGrowthOutside0X128, 0);
        assertEq(feeGrowthOutside1X128, 0);
        assertEq(feeGrowthOutside0X128, feeGrowthOutside0X128_);
        assertEq(feeGrowthOutside1X128, feeGrowthOutside1X128_);
    }

    function test_getFeeGrowthInside() public {
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, 10_000 ether, 0), ZERO_BYTES
        );

        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-600, 600, 10_000 ether, 0), ZERO_BYTES
        );

        // swap to create fees, crossing a tick
        uint256 swapAmount = 100 ether;
        swap(key, true, -int256(swapAmount), ZERO_BYTES);
        (, int24 currentTick,,) = StateLibrary.getSlot0(manager, poolId);
        assertEq(currentTick, -139);

        // calculated live
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            StateLibrary.getFeeGrowthInside(manager, poolId, -60, 60);
        snapLastCall("extsload getFeeGrowthInside");

        // poke the LP so that fees are updated
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 0, 0), ZERO_BYTES);

        bytes32 positionId =
            keccak256(abi.encodePacked(address(modifyLiquidityRouter), int24(-60), int24(60), bytes32(0)));

        (, uint256 feeGrowthInside0X128_, uint256 feeGrowthInside1X128_) =
            StateLibrary.getPositionInfo(manager, poolId, positionId);

        assertNotEq(feeGrowthInside0X128, 0);
        assertEq(feeGrowthInside0X128, feeGrowthInside0X128_);
        assertEq(feeGrowthInside1X128, feeGrowthInside1X128_);
    }

    function test_fuzz_getFeeGrowthInside(IPoolManager.ModifyLiquidityParams memory params, bool zeroForOne) public {
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(
                TickMath.minUsableTick(key.tickSpacing), TickMath.maxUsableTick(key.tickSpacing), 10_000 ether, 0
            ),
            ZERO_BYTES
        );

        (IPoolManager.ModifyLiquidityParams memory _params,) =
            createFuzzyLiquidity(modifyLiquidityRouter, key, params, SQRT_PRICE_1_1, ZERO_BYTES);

        swap(key, zeroForOne, -int256(100e18), ZERO_BYTES);

        // calculated live
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            StateLibrary.getFeeGrowthInside(manager, poolId, _params.tickLower, _params.tickUpper);

        // poke the LP so that fees are updated
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(_params.tickLower, _params.tickUpper, 0, 0), ZERO_BYTES
        );
        bytes32 positionId = keccak256(
            abi.encodePacked(address(modifyLiquidityRouter), _params.tickLower, _params.tickUpper, bytes32(0))
        );

        (, uint256 feeGrowthInside0X128_, uint256 feeGrowthInside1X128_) =
            StateLibrary.getPositionInfo(manager, poolId, positionId);

        assertEq(feeGrowthInside0X128, feeGrowthInside0X128_);
        assertEq(feeGrowthInside1X128, feeGrowthInside1X128_);
    }

    function test_getPositionLiquidity() public {
        // create liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key, IPoolManager.ModifyLiquidityParams(-60, 60, 10_000 ether, 0), ZERO_BYTES
        );

        bytes32 positionId =
            keccak256(abi.encodePacked(address(modifyLiquidityRouter), int24(-60), int24(60), bytes32(0)));

        uint128 liquidity = StateLibrary.getPositionLiquidity(manager, poolId, positionId);
        snapLastCall("extsload getPositionLiquidity");

        assertEq(liquidity, 10_000 ether);
    }

    function test_fuzz_getPositionLiquidity(
        IPoolManager.ModifyLiquidityParams memory paramsA,
        IPoolManager.ModifyLiquidityParams memory paramsB
    ) public {
        (IPoolManager.ModifyLiquidityParams memory _paramsA) =
            Fuzzers.createFuzzyLiquidityParams(key, paramsA, SQRT_PRICE_1_1);

        (IPoolManager.ModifyLiquidityParams memory _paramsB) =
            Fuzzers.createFuzzyLiquidityParams(key, paramsB, SQRT_PRICE_1_1);

        // Assume there are no overlapping positions
        vm.assume(
            _paramsA.tickLower != _paramsB.tickLower && _paramsA.tickLower != _paramsB.tickUpper
                && _paramsB.tickLower != _paramsA.tickUpper && _paramsA.tickUpper != _paramsB.tickUpper
        );

        modifyLiquidityRouter.modifyLiquidity(key, _paramsA, ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key, _paramsB, ZERO_BYTES);

        bytes32 positionIdA = keccak256(
            abi.encodePacked(address(modifyLiquidityRouter), _paramsA.tickLower, _paramsA.tickUpper, bytes32(0))
        );
        uint128 liquidityA = StateLibrary.getPositionLiquidity(manager, poolId, positionIdA);
        assertEq(liquidityA, uint128(uint256(_paramsA.liquidityDelta)));

        bytes32 positionIdB = keccak256(
            abi.encodePacked(address(modifyLiquidityRouter), _paramsB.tickLower, _paramsB.tickUpper, bytes32(0))
        );
        uint128 liquidityB = StateLibrary.getPositionLiquidity(manager, poolId, positionIdB);
        assertEq(liquidityB, uint128(uint256(_paramsB.liquidityDelta)));
    }
}
