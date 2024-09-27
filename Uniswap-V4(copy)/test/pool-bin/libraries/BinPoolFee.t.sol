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

import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {IFees} from "../../../src/interfaces/IFees.sol";
import {IVault} from "../../../src/interfaces/IVault.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {IPoolManager} from "../../../src/interfaces/IPoolManager.sol";
import {IProtocolFeeController} from "../../../src/interfaces/IProtocolFeeController.sol";
import {MockVault} from "../../../src/test/MockVault.sol";
import {MockProtocolFeeController} from "../../../src/test/fee/MockProtocolFeeController.sol";
import {MockFeeManagerHook} from "../../../src/test/fee/MockFeeManagerHook.sol";
import {Currency} from "../../../src/types/Currency.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BalanceDelta, toBalanceDelta} from "../../../src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";
import {BinPoolManager} from "../../../src/pool-bin/BinPoolManager.sol";
import {BinPool} from "../../../src/pool-bin/libraries/BinPool.sol";
import {PackedUint128Math} from "../../../src/pool-bin/libraries/math/PackedUint128Math.sol";
import {SafeCast} from "../../../src/pool-bin/libraries/math/SafeCast.sol";
import {LiquidityConfigurations} from "../../../src/pool-bin/libraries/math/LiquidityConfigurations.sol";
import {IBinPoolManager} from "../../../src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinPoolParametersHelper} from "../../../src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";
import {BinTestHelper} from "../helpers/BinTestHelper.sol";
import {BinFeeManagerHook} from "../helpers/BinFeeManagerHook.sol";
import {HOOKS_BEFORE_MINT_OFFSET} from "../../../src/pool-bin/interfaces/IBinHooks.sol";

/**
 * @dev tests around fee for mint(), swap() and burn()
 */
contract BinPoolFeeTest is BinTestHelper {
    using PoolIdLibrary for PoolKey;
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using BinPoolParametersHelper for bytes32;
    using SafeCast for uint256;

    event Mint(
        PoolId indexed id,
        address indexed sender,
        uint256[] ids,
        bytes32[] amounts,
        bytes32 compositionFee,
        bytes32 pFee
    );
    event Burn(PoolId indexed id, address indexed sender, uint256[] ids, bytes32[] amounts);
    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint24 activeId,
        uint24 fee,
        bytes32 pFees
    );

    MockVault public vault;
    BinPoolManager public poolManager;
    MockProtocolFeeController feeController;
    MockFeeManagerHook mockFeeManagerHook;
    BinFeeManagerHook binFeeManagerHook;

    PoolKey key;
    PoolId poolId;
    bytes32 poolParam;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    MockERC20 token0;
    MockERC20 token1;
    Currency currency0;
    Currency currency1;

    function setUp() public {
        vault = new MockVault();
        poolManager = new BinPoolManager(IVault(address(vault)), 500000);
        binFeeManagerHook = new BinFeeManagerHook(poolManager);

        token0 = new MockERC20("TestA", "A", 18);
        token1 = new MockERC20("TestB", "B", 18);
        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));

        (currency0, currency1) = currency0 < currency1 ? (currency0, currency1) : (currency1, currency0);

        poolParam = poolParam.setBinStep(10);
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: IPoolManager(address(poolManager)),
            fee: uint24(3000), // 3000 = 0.3%
            parameters: poolParam // binStep
        });
        poolId = key.toId();

        feeController = new MockProtocolFeeController();
        mockFeeManagerHook = new MockFeeManagerHook();
    }

    function test_MintCompositionFee_NoProtocolFee() external {
        uint24 binId = ID_ONE; // where token price are the same
        uint256 amountX = 1_000 * 1e18;
        uint256 amountY = 1_000 * 1e18;
        poolManager.initialize(key, binId, new bytes(0));

        // first mint: 5:5 ratio, will never incur composition fee for first mint
        addLiquidityToBin(key, poolManager, bob, binId, amountX, amountY, 1e18, 1e18, "");

        // second mint:
        // 1. amt into bin [400e18, 500e18]
        // 2. user share: [434482758620689655172, 465517241379310344827]
        // 3. since user get more X, an internal swap from Y to X happened. thus fee on Y.
        //      -> fee: (500e18 - 465517241379310344827) * 0.3% ~ 0.1e18
        bytes32 expectedFee = uint128(0).encode(uint128(103758620689655172));
        bytes32 protocolFee = uint128(0).encode(uint128(0));
        bytes32 expectedAmtInBin = uint128(400e18).encode(uint128(500e18));
        uint256[] memory ids = new uint256[](1);
        bytes32[] memory amounts = new bytes32[](1);
        ids[0] = binId;
        amounts[0] = expectedAmtInBin;
        vm.expectEmit();
        emit Mint(key.toId(), bob, ids, amounts, expectedFee, protocolFee);
        addLiquidityToBin(key, poolManager, bob, binId, amountX, amountY, 4e17, 5e17, "");
    }

    function testFuzz_Mint_WithDynamicFeeTooLarge(uint24 swapFee) external {
        swapFee = uint24(bound(swapFee, FeeLibrary.TEN_PERCENT_FEE + 1, type(uint24).max));

        // 0000 0000 0000 0100, beforeMint
        uint16 bitMap = 0x0004;
        binFeeManagerHook.setHooksRegistrationBitmap(bitMap);

        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(binFeeManagerHook)),
            poolManager: IPoolManager(address(poolManager)),
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(10_000), // 10_000 = 1%
            parameters: bytes32(uint256(bitMap)).setBinStep(10)
        });

        uint24 activeId = ID_ONE; // where token price are the same
        poolManager.initialize(key, activeId, new bytes(0));

        vm.expectRevert(IFees.FeeTooLarge.selector);
        bytes memory data = abi.encode(true, uint24(swapFee));
        addLiquidityToBin(key, poolManager, bob, activeId, 10_000 ether, 10_000 ether, 1e18, 1e18, data);
    }

    function test_MintCompositionFee_DynamicFee() external {
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(mockFeeManagerHook)),
            poolManager: IPoolManager(address(poolManager)),
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(3000), // 3000 = 0.3%
            parameters: poolParam // binStep
        });
        mockFeeManagerHook.setSwapFee(6_000); // overwrite to 0.6% fee

        uint24 binId = ID_ONE; // where token price are the same
        uint256 amountX = 1_000 * 1e18;
        uint256 amountY = 1_000 * 1e18;
        poolManager.initialize(key, binId, new bytes(0));

        // first mint: 5:5 ratio, will never incur composition fee for first mint
        addLiquidityToBin(key, poolManager, bob, binId, amountX, amountY, 1e18, 1e18, "");

        // second mint:
        // 1. amt into bin [400e18, 500e18]
        // 2. user share: [434482758620689655172, 465517241379310344827]
        // 3. since user get more X, an internal swap from Y to X happened. thus fee on Y.
        //      -> fee: (500e18 - 465517241379310344827) * 0.6% ~ 0.2e18
        bytes32 expectedFee = uint128(0).encode(uint128(208137931034482758));
        bytes32 protocolFee = uint128(0).encode(uint128(0));
        bytes32 expectedAmtInBin = uint128(400e18).encode(uint128(500e18));
        uint256[] memory ids = new uint256[](1);
        bytes32[] memory amounts = new bytes32[](1);
        ids[0] = binId;
        amounts[0] = expectedAmtInBin;
        vm.expectEmit();
        emit Mint(key.toId(), bob, ids, amounts, expectedFee, protocolFee);
        addLiquidityToBin(key, poolManager, bob, binId, amountX, amountY, 4e17, 5e17, "");
    }

    function test_MintCompositionFee_WithProtocolFee() external {
        // set protocolFee as 10% of fee
        uint16 pFee = _getSwapFee(10, 10); // 10%
        feeController.setProtocolFeeForPool(key, pFee);
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));

        uint24 binId = ID_ONE; // where token price are the same
        uint256 amountX = 1_000 * 1e18;
        uint256 amountY = 1_000 * 1e18;
        poolManager.initialize(key, binId, new bytes(0));

        // first mint: 5:5 ratio, will never incur composition fee for first mint
        addLiquidityToBin(key, poolManager, bob, binId, amountX, amountY, 1e18, 1e18, "");

        // lpFee is 90% while protocolFee = 10%
        bytes32 lpFee = uint128(0).encode(uint128(93382758620689655));
        bytes32 protocolFee = uint128(0).encode(uint128(10375862068965517));
        bytes32 expectedFee = lpFee.add(protocolFee);
        bytes32 expectedAmtInBin = uint128(400e18).encode(uint128(500e18)).sub(protocolFee);
        uint256[] memory ids = new uint256[](1);
        bytes32[] memory amounts = new bytes32[](1);
        ids[0] = binId;
        amounts[0] = expectedAmtInBin;
        vm.expectEmit();
        emit Mint(key.toId(), bob, ids, amounts, expectedFee, protocolFee);

        addLiquidityToBin(key, poolManager, bob, binId, amountX, amountY, 4e17, 5e17, "");

        assertEq(poolManager.protocolFeesAccrued(key.currency1), uint256(protocolFee.decodeY()));
    }

    function _addLiquidityForBurnTest(uint24 activeId, PoolKey memory _key) internal {
        uint256 amountX = 1000 ether;
        uint256 amountY = 1000 ether;
        poolManager.initialize(_key, activeId, new bytes(0));

        // mint 5:5 ratio
        addLiquidityToBin(_key, poolManager, bob, activeId, amountX, amountY, 1e18, 1e18, "");
    }

    function test_Burn_NoFee() external {
        // add liqudiity
        uint24 activeId = ID_ONE; // where token price are the same
        _addLiquidityForBurnTest(activeId, key);

        // then remove liquidity
        uint256[] memory balances = new uint256[](1);
        uint256[] memory ids = new uint256[](1);
        balances[0] = poolManager.getPosition(poolId, bob, activeId).share;
        ids[0] = activeId;
        removeLiquidity(key, poolManager, bob, ids, balances);

        // check fee. no hook for pool, so can skip check
        assertEq(poolManager.protocolFeesAccrued(currency0), 0, "test_Burn_NoFee::1");
        assertEq(poolManager.protocolFeesAccrued(currency1), 0, "test_Burn_NoFee::1");
    }

    function test_Swap_NoFee() external {
        uint24 activeId = ID_ONE; // where token price are the same
        poolManager.initialize(key, activeId, new bytes(0));

        // addLiquidity: 10_000 token0 and token1 on active bin
        addLiquidityToBin(key, poolManager, bob, activeId, 10_000e18, 10_000e18, 1e18, 1e18, "");

        // Call getSwapIn and getSwapOut
        (, uint128 getSwapOutAmtOut,) = poolManager.getSwapOut(key, true, 1e18);
        (uint128 getSwapInAmtIn,,) = poolManager.getSwapIn(key, true, getSwapOutAmtOut);
        assertEq(getSwapInAmtIn, 1e18);

        vm.startPrank(bob);
        vm.expectEmit();
        bytes32 pFee = uint128(0).encode(uint128(0));
        emit Swap(key.toId(), bob, 1e18, -((1e18 * 997) / 1000), activeId, 3000, pFee);

        // swap: 1e18 X for Y. pool is 0.3% fee
        BalanceDelta delta = poolManager.swap(key, true, 1e18, "0x");
        assertEq(delta.amount0(), 1e18, "test_Swap_NoFee::1");
        assertEq(delta.amount1(), -((1e18 * 997) / 1000), "test_Swap_NoFee::2");

        // Verify swap result is similar to getSwapOut
        assertEq(getSwapOutAmtOut, uint128(-delta.amount1()));

        // check fee. no hook for pool, so can skip check
        assertEq(poolManager.protocolFeesAccrued(currency0), 0, "test_Swap_NoFee::3");
        assertEq(poolManager.protocolFeesAccrued(currency1), 0, "test_Swap_NoFee::4");
    }

    function test_Swap_WithDynamicFee(uint24 poolFee) external {
        poolFee = uint24(bound(poolFee, 0, FeeLibrary.TEN_PERCENT_FEE - 1));

        // 0000 0000 0100 0000, beforeSwap
        uint16 bitMap = 0x0040;
        binFeeManagerHook.setHooksRegistrationBitmap(bitMap);

        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(binFeeManagerHook)),
            poolManager: IPoolManager(address(poolManager)),
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + poolFee,
            // parameters: poolParam // binStep
            parameters: bytes32(uint256(bitMap)).setBinStep(10)
        });

        // addLiquidity: 10_000 token0 and token1 on active bin
        uint24 activeId = ID_ONE; // where token price are the same
        poolManager.initialize(key, activeId, new bytes(0));
        addLiquidityToBin(key, poolManager, bob, activeId, 10_000 ether, 10_000 ether, 1e18, 1e18, "");

        // overwrite fee to 2%
        binFeeManagerHook.setFee(20_000);
        poolManager.updateDynamicSwapFee(key);

        // Call getSwapIn and getSwapOut
        (, uint128 getSwapOutAmtOut,) = poolManager.getSwapOut(key, true, 1e18);
        (uint128 getSwapInAmtIn,,) = poolManager.getSwapIn(key, true, getSwapOutAmtOut);
        assertEq(getSwapInAmtIn, 1e18);

        // verify 2% fee instead of whatever fee set on the pool
        BalanceDelta delta = poolManager.swap(key, true, 1e18, "");
        assertEq(delta.amount0(), 1e18, "test_Swap_WithDynamicFee::1");
        assertEq(delta.amount1(), -((1e18 * 98) / 100), "test_Swap_WithDynamicFee::2");

        // Verify swap result is similar to getSwapOut
        assertEq(getSwapOutAmtOut, uint128(-delta.amount1()));
    }

    function testFuzz_Swap_WithDynamicFeeTooLarge(uint24 swapFee) external {
        swapFee = uint24(bound(swapFee, FeeLibrary.TEN_PERCENT_FEE + 1, type(uint24).max));

        // 0000 0000 0100 0000, beforeSwap
        uint16 bitMap = 0x0040;
        binFeeManagerHook.setHooksRegistrationBitmap(bitMap);

        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(binFeeManagerHook)),
            poolManager: IPoolManager(address(poolManager)),
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(10_000), // 10_000 = 1%
            parameters: bytes32(uint256(bitMap)).setBinStep(10)
        });

        // addLiquidity: 10_000 token0 and token1 on active bin
        uint24 activeId = ID_ONE; // where token price are the same
        poolManager.initialize(key, activeId, new bytes(0));
        addLiquidityToBin(key, poolManager, bob, activeId, 10_000e18, 10_000e18, 1e18, 1e18, "");

        vm.expectRevert(IFees.FeeTooLarge.selector);
        bytes memory data = abi.encode(true, uint24(swapFee));
        poolManager.swap(key, true, 1e18, data);
    }

    function _getSwapFee(uint16 fee0, uint16 fee1) internal pure returns (uint16) {
        return fee0 + (fee1 << 8);
    }

    /**
     * @dev given amountIn and fee (pool, protocol and hook level), calculate amount to lp and the feeAmt
     * @param feePercentage pool fee %, 10 imply 10%
     * @param protocolFeePercentage 10 imply 10%
     */
    function _getProtocolFeeForSwap(uint128 amtIn, uint128 feePercentage, uint128 protocolFeePercentage)
        internal
        pure
        returns (uint128 amtToLp, uint128 protocolFee)
    {
        uint128 totalFeeAmt = (amtIn * feePercentage) / 100;
        protocolFee = (totalFeeAmt * protocolFeePercentage) / 100;
        amtToLp = amtIn - protocolFee;
    }
}
