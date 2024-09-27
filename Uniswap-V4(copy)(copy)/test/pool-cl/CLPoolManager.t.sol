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
import {IVault} from "../../src/interfaces/IVault.sol";
import {ERC20PresetFixedSupply} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {Vault} from "../../src/Vault.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {ICLPoolManager} from "../../src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLPoolManager} from "../../src/pool-cl/CLPoolManager.sol";
import {CLPool} from "../../src/pool-cl/libraries/CLPool.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "../../src/types/PoolId.sol";
import {IHooks} from "../../src/interfaces/IHooks.sol";
import {TickMath} from "../../src/pool-cl/libraries/TickMath.sol";
import {IFees} from "../../src/interfaces/IFees.sol";
import {ICLHooks} from "../../src/pool-cl/interfaces/ICLHooks.sol";
import {Hooks} from "../../src/libraries/Hooks.sol";
import {CLPoolManagerRouter} from "./helpers/CLPoolManagerRouter.sol";
import {FixedPoint96} from "../../src/pool-cl/libraries/FixedPoint96.sol";
import {IERC20} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CLPosition} from "../../src/pool-cl/libraries/CLPosition.sol";
import {Deployers} from "./helpers/Deployers.sol";
import {TokenFixture, MockERC20} from "../helpers/TokenFixture.sol";
import {MockHooks} from "./helpers/MockHooks.sol";
import {FeeLibrary} from "../../src/libraries/FeeLibrary.sol";
import {CLPoolParametersHelper} from "../../src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {ParametersHelper} from "../../src/libraries/math/ParametersHelper.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../../src/types/BalanceDelta.sol";
import {NonStandardERC20} from "./helpers/NonStandardERC20.sol";
import {ProtocolFeeControllerTest} from "./helpers/ProtocolFeeControllerTest.sol";
import {IProtocolFeeController} from "../../src/interfaces/IProtocolFeeController.sol";
import {CLFeeManagerHook} from "./helpers/CLFeeManagerHook.sol";
import {CLNoOpTestHook} from "./helpers/CLNoOpTestHook.sol";
import {ICLLmPool} from "../../src/pool-cl/interfaces/ICLLmPool.sol";
import {CLLmPool} from "./helpers/CLLmPool.sol";

contract CLPoolManagerTest is Test, Deployers, TokenFixture, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using CLPoolParametersHelper for bytes32;
    using ParametersHelper for bytes32;
    using FeeLibrary for uint24;

    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        ICLHooks hooks
    );
    event ModifyLiquidity(
        PoolId indexed poolId, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta
    );
    event Swap(
        PoolId indexed poolId,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee,
        uint256 protocolFee
    );
    event Transfer(address caller, address indexed from, address indexed to, Currency indexed currency, uint256 amount);

    event ProtocolFeeUpdated(PoolId indexed id, uint16 protocolFees);
    event DynamicSwapFeeUpdated(PoolId indexed id, uint24 dynamicSwapFee);
    event Donate(PoolId indexed id, address indexed sender, uint256 amount0, uint256 amount1, int24 tick);
    event SetMasterChef(address masterChef);
    event SetLmPool(PoolId indexed id, address lmPool);

    IVault public vault;
    CLPoolManager public poolManager;
    CLPoolManagerRouter public router;
    ProtocolFeeControllerTest public protocolFeeController;
    ProtocolFeeControllerTest public feeController;
    CLFeeManagerHook public clFeeManagerHook;

    function setUp() public {
        initializeTokens();
        (vault, poolManager) = createFreshManager();
        router = new CLPoolManagerRouter(vault, poolManager);
        protocolFeeController = new ProtocolFeeControllerTest();
        feeController = new ProtocolFeeControllerTest();
        clFeeManagerHook = new CLFeeManagerHook(poolManager);

        IERC20(Currency.unwrap(currency0)).approve(address(router), 10 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 10 ether);
    }

    // **************              *************** //
    // **************  initialize  *************** //
    // **************              *************** //
    function testInitialize_feeRange() external {
        // 3000 i.e. 0.3%
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(3000),
                parameters: bytes32(uint256(0xa0000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // 0
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(0),
                parameters: bytes32(uint256(0xa0000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // 300000 i.e. 30%
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(300000),
                parameters: bytes32(uint256(0xa0000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // 999999 i.e. 99.9999% overflow
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(999999),
                parameters: bytes32(uint256(0xa0000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // 1000000 i.e. 100% overflow
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(1000000),
                parameters: bytes32(uint256(0xa0000))
            });

            vm.expectRevert(IFees.FeeTooLarge.selector);
            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }
    }

    function testInitialize_tickSpacing() external {
        // tickSpacing 0
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(3000),
                parameters: bytes32(uint256(0x0000))
            });

            vm.expectRevert(ICLPoolManager.TickSpacingTooSmall.selector);
            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // tickSpacing 1
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(3000),
                parameters: bytes32(uint256(0x10000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // tickSpacing 10
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(3000),
                parameters: bytes32(uint256(0xa0000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // tickSpacing max
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(3000),
                parameters: bytes32(uint256(0x7fff0000))
            });

            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }

        // tickSpacing overflow
        {
            PoolKey memory key = PoolKey({
                currency0: Currency.wrap(makeAddr("token0")),
                currency1: Currency.wrap(makeAddr("token1")),
                hooks: IHooks(address(0)),
                poolManager: poolManager,
                fee: uint24(3000),
                parameters: bytes32(uint256(0x80000000))
            });

            vm.expectRevert(ICLPoolManager.TickSpacingTooLarge.selector);
            poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        }
    }

    function testInitialize_stateCheck() external {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(makeAddr("token0")),
            currency1: Currency.wrap(makeAddr("token1")),
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 10
            parameters: bytes32(uint256(0xa0000))
        });

        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));

        (CLPool.Slot0 memory slot0, uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128, uint128 liquidity,) =
            poolManager.pools(key.toId());

        assertEq(slot0.sqrtPriceX96, TickMath.MIN_SQRT_RATIO);
        assertEq(slot0.tick, TickMath.MIN_TICK);
        assertEq(slot0.protocolFee, 0);
        assertEq(feeGrowthGlobal0X128, 0);
        assertEq(feeGrowthGlobal1X128, 0);
        assertEq(liquidity, 0);
    }

    function testInitialize_gasCheck_withoutHooks() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 100 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 100 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 10
            parameters: bytes32(uint256(0xa0000))
        });

        snapStart("CLPoolManagerTest#initializeWithoutHooks");
        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        snapEnd();
    }

    function test_initialize_fuzz(PoolKey memory key, uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        // tested in Hooks.t.sol
        key.hooks = IHooks(address(0));
        key.poolManager = poolManager;

        if (key.fee & FeeLibrary.STATIC_FEE_MASK >= FeeLibrary.ONE_HUNDRED_PERCENT_FEE) {
            vm.expectRevert(abi.encodeWithSelector(IFees.FeeTooLarge.selector));
            poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        } else if (key.parameters.getTickSpacing() > poolManager.MAX_TICK_SPACING()) {
            vm.expectRevert(abi.encodeWithSelector(ICLPoolManager.TickSpacingTooLarge.selector));
            poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        } else if (key.parameters.getTickSpacing() < poolManager.MIN_TICK_SPACING()) {
            vm.expectRevert(abi.encodeWithSelector(ICLPoolManager.TickSpacingTooSmall.selector));
            poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        } else if (key.currency0 > key.currency1 || key.currency0 == key.currency1) {
            vm.expectRevert(abi.encodeWithSelector(IPoolManager.CurrenciesInitializedOutOfOrder.selector));
            poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        } else if (!_validateHookConfig(key)) {
            vm.expectRevert(abi.encodeWithSelector(Hooks.HookConfigValidationError.selector));
            poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        } else {
            vm.expectEmit(true, true, true, true);
            emit Initialize(
                key.toId(),
                key.currency0,
                key.currency1,
                key.fee,
                key.parameters.getTickSpacing(),
                ICLHooks(address(key.hooks))
            );
            poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);

            (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
            assertEq(slot0.sqrtPriceX96, sqrtPriceX96);
            assertEq(slot0.protocolFee, 0);
        }
    }

    function test_initialize_forNativeTokens(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60 << 16))
        });

        vm.expectEmit(true, true, true, true);
        emit Initialize(
            key.toId(),
            key.currency0,
            key.currency1,
            key.fee,
            key.parameters.getTickSpacing(),
            ICLHooks(address(key.hooks))
        );
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);

        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.sqrtPriceX96, sqrtPriceX96);
        assertEq(slot0.protocolFee, 0);
        assertEq(slot0.tick, TickMath.getTickAtSqrtRatio(sqrtPriceX96));
    }

    function test_initialize_succeedsWithHooks(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        MockHooks hookAddr = new MockHooks();
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(hookAddr),
            poolManager: poolManager,
            parameters: bytes32(uint256((60 << 16) | hookAddr.getHooksRegistrationBitmap()))
        });

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        bytes memory beforePayload =
            abi.encodeWithSelector(MockHooks.beforeInitialize.selector, address(this), key, sqrtPriceX96, ZERO_BYTES);

        bytes memory afterPayload = abi.encodeWithSelector(
            MockHooks.afterInitialize.selector, address(this), key, sqrtPriceX96, tick, ZERO_BYTES
        );

        vm.expectCall(address(hookAddr), 0, beforePayload, 1);
        vm.expectCall(address(hookAddr), 0, afterPayload, 1);

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.sqrtPriceX96, sqrtPriceX96);
    }

    function test_initialize_succeedsWithMaxTickSpacing(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(int256(poolManager.MAX_TICK_SPACING()) << 16))
        });

        vm.expectEmit(true, true, true, true);
        emit Initialize(
            key.toId(),
            key.currency0,
            key.currency1,
            key.fee,
            key.parameters.getTickSpacing(),
            ICLHooks(address(key.hooks))
        );

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_succeedsWithEmptyHooks(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        MockHooks hookEmptyAddr = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: hookEmptyAddr,
            poolManager: poolManager,
            parameters: bytes32(uint256((60 << 16) | hookEmptyAddr.getHooksRegistrationBitmap()))
        });

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.sqrtPriceX96, sqrtPriceX96);
    }

    function test_initialize_revertsWithIdenticalTokens(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        // Both currencies are currency0
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency0,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60 << 16))
        });

        vm.expectRevert(IPoolManager.CurrenciesInitializedOutOfOrder.selector);
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_revertsWithSameTokenCombo(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60 << 16))
        });

        PoolKey memory keyInvertedCurrency = PoolKey({
            currency0: currency1,
            currency1: currency0,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60 << 16))
        });

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        vm.expectRevert(IPoolManager.CurrenciesInitializedOutOfOrder.selector);
        poolManager.initialize(keyInvertedCurrency, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_revertsWhenPoolAlreadyInitialized(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60 << 16))
        });

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        vm.expectRevert(CLPool.PoolAlreadyInitialized.selector);
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_failsWithIncorrectSelectors() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        mockHooks.setReturnValue(mockHooks.beforeInitialize.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterInitialize.selector, bytes4(0xdeadbeef));

        // Fails at beforeInitialize hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        // Fail at afterInitialize hook.
        mockHooks.setReturnValue(mockHooks.beforeInitialize.selector, mockHooks.beforeInitialize.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
    }

    function test_initialize_succeedsWithCorrectSelectors() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        mockHooks.setReturnValue(mockHooks.beforeInitialize.selector, mockHooks.beforeInitialize.selector);
        mockHooks.setReturnValue(mockHooks.afterInitialize.selector, mockHooks.afterInitialize.selector);

        vm.expectEmit(true, true, true, true);
        emit Initialize(
            key.toId(),
            key.currency0,
            key.currency1,
            key.fee,
            key.parameters.getTickSpacing(),
            ICLHooks(address(key.hooks))
        );

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
    }

    function test_initialize_failsIfTickSpaceTooLarge(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256((int256((poolManager.MAX_TICK_SPACING())) + 1) << 16))
        });

        vm.expectRevert(abi.encodeWithSelector(ICLPoolManager.TickSpacingTooLarge.selector));
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_failsIfTickSpaceZero(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(0))
        });

        vm.expectRevert(abi.encodeWithSelector(ICLPoolManager.TickSpacingTooSmall.selector));
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_failsIfTickSpaceNeg(uint160 sqrtPriceX96) public {
        // Assumptions tested in Pool.t.sol
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            // tickSpacing = -1
            parameters: bytes32(uint256(0xffffff) << 16)
        });

        vm.expectRevert(abi.encodeWithSelector(ICLPoolManager.TickSpacingTooSmall.selector));
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
    }

    function test_initialize_failsIDynamicFeeTooLarge(uint24 dynamicSwapFee) public {
        dynamicSwapFee = uint24(bound(dynamicSwapFee, FeeLibrary.ONE_HUNDRED_PERCENT_FEE + 1, type(uint24).max));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(3000), // 3000 = 0.3%
            hooks: IHooks(address(clFeeManagerHook)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });

        clFeeManagerHook.setFee(dynamicSwapFee);

        vm.expectRevert(IFees.FeeTooLarge.selector);
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
    }

    function test_initialize_failsNoOpMissingBeforeCall() public {
        uint16 bitMap = 0x0400; // 0000 0100 0000 0000 (only noOp)

        CLNoOpTestHook noOpHook = new CLNoOpTestHook();
        noOpHook.setHooksRegistrationBitmap(bitMap);
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(noOpHook),
            poolManager: poolManager,
            parameters: bytes32(uint256((60 << 16) | noOpHook.getHooksRegistrationBitmap()))
        });

        vm.expectRevert(Hooks.NoOpHookMissingBeforeCall.selector);
        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
    }

    // **************                  *************** //
    // **************  modifyPosition  *************** //
    // **************                  *************** //

    function testModifyPosition_addLiquidity() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e10 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e10 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e10 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e10 ether);

        snapStart("CLPoolManagerTest#addLiquidity_fromEmpty");
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                liquidityDelta: 1e24
            }),
            ""
        );
        snapEnd();

        {
            uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
            uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

            // consume both X and Y, python:
            // >>> X = ((1.0001 ** tick0) ** -0.5 - (1.0001 ** tick1) ** -0.5) * 1e24
            // >>> Y = ((1.0001 ** tick1) ** 0.5 - (1.0001 ** tick0) ** 0.5) * 1e24
            assertEq(1e10 ether - token0Left, 99999999999999999945788);
            assertEq(1e10 ether - token1Left, 9999999999999999999945788);

            assertEq(poolManager.getLiquidity(key.toId()), 1e24);
            assertEq(poolManager.getLiquidity(key.toId(), address(router), TickMath.MIN_TICK, TickMath.MAX_TICK), 1e24);

            assertEq(
                poolManager.getPosition(key.toId(), address(router), TickMath.MIN_TICK, TickMath.MAX_TICK)
                    .feeGrowthInside0LastX128,
                0
            );
            assertEq(
                poolManager.getPosition(key.toId(), address(router), TickMath.MIN_TICK, TickMath.MAX_TICK)
                    .feeGrowthInside1LastX128,
                0
            );
        }

        snapStart("CLPoolManagerTest#addLiquidity_fromNonEmpty");
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({
                tickLower: TickMath.MIN_TICK,
                tickUpper: TickMath.MAX_TICK,
                liquidityDelta: 1e4
            }),
            ""
        );
        snapEnd();

        {
            uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
            uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

            // consume both X and Y, python:
            // >>> X = ((1.0001 ** tick0) ** -0.5 - (1.0001 ** tick1) ** -0.5) * 1e24
            // >>> Y = ((1.0001 ** tick1) ** 0.5 - (1.0001 ** tick0) ** 0.5) * 1e24
            assertEq(1e10 ether - token0Left, 99999999999999999946788);
            assertEq(1e10 ether - token1Left, 10000000000000000000045788);

            assertEq(poolManager.getLiquidity(key.toId()), 1e24 + 1e4);
            assertEq(
                poolManager.getLiquidity(key.toId(), address(router), TickMath.MIN_TICK, TickMath.MAX_TICK), 1e24 + 1e4
            );

            assertEq(
                poolManager.getPosition(key.toId(), address(router), TickMath.MIN_TICK, TickMath.MAX_TICK)
                    .feeGrowthInside0LastX128,
                0
            );
            assertEq(
                poolManager.getPosition(key.toId(), address(router), TickMath.MIN_TICK, TickMath.MAX_TICK)
                    .feeGrowthInside1LastX128,
                0
            );
        }
    }

    function testModifyPosition_Liquidity_aboveCurrentTick() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e30 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e30 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 46055, tickUpper: 46060, liquidityDelta: 1e9}), ""
        );

        uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
        uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

        // consume X only, python:
        // >>> ((1.0001 ** tick0) ** -0.5 - (1.0001 ** tick1) ** -0.5) * 1e9
        // 24994.381475337836
        assertEq(1e30 ether - token0Left, 24995);
        assertEq(1e30 ether - token1Left, 0);

        // no active liquidity
        assertEq(poolManager.getLiquidity(key.toId()), 0);
        assertEq(poolManager.getLiquidity(key.toId(), address(router), 46055, 46060), 1e9);

        assertEq(poolManager.getPosition(key.toId(), address(this), 46055, 46060).feeGrowthInside0LastX128, 0);
        assertEq(poolManager.getPosition(key.toId(), address(this), 46055, 46060).feeGrowthInside1LastX128, 0);
    }

    function testModifyPosition_addLiquidity_belowCurrentTick() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e30 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e30 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 46000, tickUpper: 46050, liquidityDelta: 1e9}), ""
        );

        uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
        uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

        // consume Y only, python:
        //>>> ((1.0001 ** tick1) ** 0.5 - (1.0001 ** tick0) ** 0.5) * 1e9
        // 24962530.97288914
        assertEq(1e30 ether - token0Left, 0);
        assertEq(1e30 ether - token1Left, 24962531);

        // no active liquidity
        assertEq(poolManager.getLiquidity(key.toId()), 0);
        assertEq(poolManager.getLiquidity(key.toId(), address(router), 46000, 46050), 1e9);

        assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside0LastX128, 0);
        assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside1LastX128, 0);
    }

    function testModifyPosition_removeLiquidity_fromEmpty() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e36 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e36 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        vm.expectRevert(stdError.arithmeticError);
        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 46000, tickUpper: 46050, liquidityDelta: -1}), ""
        );
    }

    function testModifyPosition_removeLiquidity_updateEmptyPosition() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e36 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e36 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        vm.expectRevert(CLPosition.CannotUpdateEmptyPosition.selector);
        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 46000, tickUpper: 46050, liquidityDelta: 0}), ""
        );
    }

    function testModifyPosition_removeLiquidity_empty() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e36 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e36 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 1 i.e. tick 0
        poolManager.initialize(key, uint160(1 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: -1, tickUpper: 1, liquidityDelta: 100 ether}), ""
        );

        assertEq(poolManager.getLiquidity(key.toId()), 100 ether, "total liquidity should be 1000");
        assertEq(
            poolManager.getLiquidity(key.toId(), address(router), -1, 1), 100 ether, "router's liquidity should be 1000"
        );

        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 4999625031247266);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 4999625031247266);

        assertEq(poolManager.getPosition(key.toId(), address(router), -1, 1).feeGrowthInside0LastX128, 0);
        assertEq(poolManager.getPosition(key.toId(), address(router), -1, 1).feeGrowthInside1LastX128, 0);

        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: -1, tickUpper: 1, liquidityDelta: -100 ether}), ""
        );

        assertEq(poolManager.getLiquidity(key.toId()), 0);
        assertEq(poolManager.getLiquidity(key.toId(), address(router), -1, 1), 0);

        // expected to receive 0, but got 1 because of precision loss
        assertEq(IERC20(Currency.unwrap(currency0)).balanceOf(address(vault)), 1);
        assertEq(IERC20(Currency.unwrap(currency1)).balanceOf(address(vault)), 1);

        assertEq(poolManager.getPosition(key.toId(), address(router), -1, 1).feeGrowthInside0LastX128, 0);
        assertEq(poolManager.getPosition(key.toId(), address(router), -1, 1).feeGrowthInside1LastX128, 0);
    }

    function testModifyPosition_removeLiquidity_halfAndThenAll() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e30 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e30 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 46000, tickUpper: 46050, liquidityDelta: 1e9}), ""
        );

        {
            uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
            uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

            // consume Y only, python:
            //>>> ((1.0001 ** tick1) ** 0.5 - (1.0001 ** tick0) ** 0.5) * 1e9
            // 24962530.97288914
            assertEq(1e30 ether - token0Left, 0);
            assertEq(1e30 ether - token1Left, 24962531);

            // no active liquidity
            assertEq(poolManager.getLiquidity(key.toId()), 0);
            assertEq(poolManager.getLiquidity(key.toId(), address(router), 46000, 46050), 1e9);

            assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside0LastX128, 0);
            assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside1LastX128, 0);
        }

        // remove half
        snapStart("CLPoolManagerTest#removeLiquidity_toNonEmpty");
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: 46000, tickUpper: 46050, liquidityDelta: -5 * 1e8}),
            ""
        );
        snapEnd();

        {
            uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
            uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

            // half of 24962531
            assertEq(1e30 ether - token0Left, 0);
            assertEq(1e30 ether - token1Left, 12481266);

            // no active liquidity
            assertEq(poolManager.getLiquidity(key.toId()), 0);
            assertEq(poolManager.getLiquidity(key.toId(), address(router), 46000, 46050), 5 * 1e8);

            assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside0LastX128, 0);
            assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside1LastX128, 0);
        }

        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: 46000, tickUpper: 46050, liquidityDelta: -5 * 1e8}),
            ""
        );

        {
            uint256 token0Left = IERC20(Currency.unwrap(currency0)).balanceOf(address(this));
            uint256 token1Left = IERC20(Currency.unwrap(currency1)).balanceOf(address(this));

            // back to 0
            assertEq(1e30 ether - token0Left, 0);

            // expected to receive 0, but got 1 because of precision loss
            assertEq(1e30 ether - token1Left, 1);

            // no active liquidity
            assertEq(poolManager.getLiquidity(key.toId()), 0);
            assertEq(poolManager.getLiquidity(key.toId(), address(router), 46000, 46050), 0);

            assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside0LastX128, 0);
            assertEq(poolManager.getPosition(key.toId(), address(router), 46000, 46050).feeGrowthInside1LastX128, 0);
        }
    }

    function testModifyPosition_failsIfNotInitialized() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });
        vm.expectRevert();
        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100}), ZERO_BYTES
        );
    }

    function testModifyPosition_succeedsIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(key.toId(), address(router), 0, 60, 100);

        router.modifyPosition(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100}), ZERO_BYTES
        );
    }

    function testModifyPosition_succeedsForNativeTokensIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(key.toId(), address(router), 0, 60, 100);

        router.modifyPosition{value: 100}(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100}), ZERO_BYTES
        );
    }

    function testModifyPosition_succeedsWithHooksIfInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        MockHooks mockAddr = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(mockAddr),
            poolManager: poolManager,
            parameters: bytes32((uint256(60) << 16) | mockAddr.getHooksRegistrationBitmap())
        });

        ICLPoolManager.ModifyLiquidityParams memory params =
            ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100});

        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);

        BalanceDelta balanceDelta;
        // create a new context to swallow up the revert
        try CLPoolManagerTest(payable(this)).tryExecute(
            address(router),
            abi.encodeWithSelector(CLPoolManagerRouter.modifyPosition.selector, key, params, ZERO_BYTES)
        ) {
            revert("must revert");
        } catch (bytes memory result) {
            balanceDelta = abi.decode(result, (BalanceDelta));
        }

        bytes memory beforePayload =
            abi.encodeWithSelector(MockHooks.beforeAddLiquidity.selector, address(router), key, params, ZERO_BYTES);

        bytes memory afterPayload = abi.encodeWithSelector(
            MockHooks.afterAddLiquidity.selector, address(router), key, params, balanceDelta, ZERO_BYTES
        );

        vm.expectCall(address(mockAddr), 0, beforePayload, 1);
        vm.expectCall(address(mockAddr), 0, afterPayload, 1);
        router.modifyPosition(key, params, ZERO_BYTES);
    }

    function testModifyPosition_failsWithIncorrectSelectors() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32((uint256(10) << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        ICLPoolManager.ModifyLiquidityParams memory params =
            ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeAddLiquidity.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterAddLiquidity.selector, bytes4(0xdeadbeef));

        // Fails at beforeAddLiquidity hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        router.modifyPosition(key, params, ZERO_BYTES);

        // Fail at afterAddLiquidity hook.
        mockHooks.setReturnValue(mockHooks.beforeAddLiquidity.selector, mockHooks.beforeAddLiquidity.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        router.modifyPosition(key, params, ZERO_BYTES);
    }

    function testModifyPosition_succeedsWithCorrectSelectors() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32((uint256(10) << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        ICLPoolManager.ModifyLiquidityParams memory params =
            ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeAddLiquidity.selector, mockHooks.beforeAddLiquidity.selector);
        mockHooks.setReturnValue(mockHooks.afterAddLiquidity.selector, mockHooks.afterAddLiquidity.selector);

        vm.expectEmit(true, true, true, true);
        emit ModifyLiquidity(key.toId(), address(router), 0, 60, 100);

        router.modifyPosition(key, params, ZERO_BYTES);
    }

    function testModifyPosition_withNative_gas() public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        snapStart("CLPoolManagerTest#addLiquidity_nativeToken");
        router.modifyPosition{value: 100}(
            key, ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100}), ZERO_BYTES
        );
        snapEnd();
    }

    // **************        *************** //
    // **************  swap  *************** //
    // **************        *************** //

    function testSwap_runOutOfLiquidity() external {
        Currency currency0 = Currency.wrap(address(new ERC20PresetFixedSupply("C0", "C0", 1e30 ether, address(this))));
        Currency currency1 = Currency.wrap(address(new ERC20PresetFixedSupply("C1", "C1", 1e30 ether, address(this))));

        if (currency0 > currency1) {
            (currency0, currency1) = (currency1, currency0);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            // 0 ~ 15  hookRegistrationMap = nil
            // 16 ~ 24 tickSpacing = 1
            parameters: bytes32(uint256(0x10000))
        });

        // price = 100 tick roughly 46054
        poolManager.initialize(key, uint160(10 * FixedPoint96.Q96), new bytes(0));

        IERC20(Currency.unwrap(currency0)).approve(address(router), 1e30 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 1e30 ether);

        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: 46053, tickUpper: 46055, liquidityDelta: 1000000 ether}),
            ""
        );

        // token0: roughly 5 ether
        assertEq(vault.reservesOfVault(currency0), 4977594234867895338);
        // token1: roughly 502 ether
        assertEq(vault.reservesOfVault(currency1), 502165582277283491084);

        // swap 10 ether token0 for token1
        snapStart("CLPoolManagerTest#swap_runOutOfLiquidity");
        router.swap(
            key,
            ICLPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: 10 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
            }),
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true}),
            ""
        );
        snapEnd();

        //        console2.log("token0 balance: ", int256(vault.reservesOfVault(currency0)));
        //        console2.log("token1 balance: ", int256(vault.reservesOfVault(currency1)));
    }

    function testSwap_failsIfNotInitialized(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: sqrtPriceX96});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        vm.expectRevert();
        router.swap(key, params, testSettings, ZERO_BYTES);
    }

    function testSwap_succeedsIfInitialized() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        address masterChef = makeAddr("masterChef");
        ICLLmPool lmPool = new CLLmPool();
        poolManager.setMasterChef(masterChef);
        vm.prank(masterChef);
        poolManager.setLmPool(key, address(lmPool));

        vm.mockCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.accumulateReward.selector), "");
        vm.mockCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.crossLmTick.selector), "");

        // vm.expectCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.crossLmTick.selector, int24(0), true));

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1 ether});

        router.modifyPosition(key, modifyPositionParams, ZERO_BYTES);

        vm.expectEmit(true, true, true, true);
        emit Swap(
            key.toId(), address(router), 100, -98, 79228162514264329749955861424, 1000000000000000000, -1, 3000, 0
        );

        // sell base token(x) for quote token(y), pricea(y / x) decreases
        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        router.swap(key, params, testSettings, ZERO_BYTES);
    }

    function testSwap_crossLmTickUncalled() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -6000, tickUpper: 6000, liquidityDelta: 1 ether});

        router.modifyPosition(key, modifyPositionParams, ZERO_BYTES);

        // sell base token(x) for quote token(y), pricea(y / x) decreases
        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 0.1 ether, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        router.swap(key, params, testSettings, ZERO_BYTES);
    }

    function testSwap_crossLmTickCalled() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        address masterChef = makeAddr("masterChef");
        ICLLmPool lmPool = new CLLmPool();
        poolManager.setMasterChef(masterChef);
        vm.prank(masterChef);
        poolManager.setLmPool(key, address(lmPool));

        vm.mockCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.accumulateReward.selector), "");
        vm.mockCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.crossLmTick.selector), "");

        vm.expectCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.crossLmTick.selector, int24(-60), true));
        vm.expectCall(address(lmPool), abi.encodeWithSelector(ICLLmPool.crossLmTick.selector, int24(0), true), 0);

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1 ether});

        router.modifyPosition(key, modifyPositionParams, ZERO_BYTES);

        // vm.expectEmit(true, true, true, true);
        // emit Swap(
        //     key.toId(),
        //     address(router),
        //     3013394245478362,
        //     -2995354955910780,
        //     56022770974786139918731938227,
        //     0,
        //     -6932,
        //     3000,
        //     0
        // );

        // sell base token(x) for quote token(y), pricea(y / x) decreases
        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 0.1 ether, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        router.swap(key, params, testSettings, ZERO_BYTES);
    }

    function testSwap_succeedsIfInitialized_WithDynamicFee() public {
        uint16 bitMap = 0x0040; // 0000 0000 0100 0000 (before swap call)
        clFeeManagerHook.setHooksRegistrationBitmap(bitMap);

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(3000), // 0.3%
            hooks: IHooks(address(clFeeManagerHook)),
            poolManager: poolManager,
            parameters: bytes32(uint256((60 << 16) | clFeeManagerHook.getHooksRegistrationBitmap()))
        });

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1 ether});

        router.modifyPosition(key, modifyPositionParams, ZERO_BYTES);

        // similar result to testSwap_succeedsIfInitialized above, except swapFee is twice due to dynamic fee
        vm.expectEmit(true, true, true, true);
        emit Swap(
            key.toId(), address(router), 100, -97, 79228162514264329829184023939, 1000000000000000000, -1, 12000, 0
        );

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        bytes memory data = abi.encode(true, uint24(12000)); // dynamic fee at 1.2% (four times of static fee)
        router.swap(key, params, testSettings, data);
    }

    function testSwap_succeedsWithNativeTokensIfInitialized() public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: false});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        vm.expectEmit(true, true, true, true);
        emit Swap(key.toId(), address(router), 0, 0, SQRT_RATIO_1_2, 0, -6932, 3000, 0);

        router.swap(key, params, testSettings, ZERO_BYTES);
    }

    function testSwap_succeedsWithHooksIfInitialized() public {
        MockHooks mockAddr = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(mockAddr),
            poolManager: poolManager,
            parameters: bytes32((uint256(60) << 16) | mockAddr.getHooksRegistrationBitmap())
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: false});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        BalanceDelta balanceDelta;
        // create a new context to swallow up the revert
        try CLPoolManagerTest(payable(this)).tryExecute(
            address(router),
            abi.encodeWithSelector(CLPoolManagerRouter.swap.selector, key, params, testSettings, ZERO_BYTES)
        ) {
            revert("must revert");
        } catch (bytes memory result) {
            balanceDelta = abi.decode(result, (BalanceDelta));
        }

        bytes memory beforePayload =
            abi.encodeWithSelector(MockHooks.beforeSwap.selector, address(router), key, params, ZERO_BYTES);

        bytes memory afterPayload =
            abi.encodeWithSelector(MockHooks.afterSwap.selector, address(router), key, params, balanceDelta, ZERO_BYTES);

        vm.expectCall(address(mockAddr), 0, beforePayload, 1);
        vm.expectCall(address(mockAddr), 0, afterPayload, 1);
        router.swap(key, params, testSettings, ZERO_BYTES);
    }

    function testSwap_failsWithIncorrectSelectors() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32((uint256(10) << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        ICLPoolManager.ModifyLiquidityParams memory params =
            ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100});

        ICLPoolManager.SwapParams memory swapParams =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 10, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: false});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(key, params, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterSwap.selector, bytes4(0xdeadbeef));

        // Fails at beforeAddLiquidity hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        router.swap(key, swapParams, testSettings, ZERO_BYTES);

        // Fail at afterAddLiquidity hook.
        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, mockHooks.beforeSwap.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        router.swap(key, swapParams, testSettings, ZERO_BYTES);
    }

    function testSwap_succeedsWithCorrectSelectors() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32((uint256(10) << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        ICLPoolManager.ModifyLiquidityParams memory params =
            ICLPoolManager.ModifyLiquidityParams({tickLower: 0, tickUpper: 60, liquidityDelta: 100});

        ICLPoolManager.SwapParams memory swapParams =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 10, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: false});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(key, params, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeSwap.selector, mockHooks.beforeSwap.selector);
        mockHooks.setReturnValue(mockHooks.afterSwap.selector, mockHooks.afterSwap.selector);

        vm.expectEmit(true, true, true, true);
        emit Swap(key.toId(), address(router), 0, 0, SQRT_RATIO_1_2, 0, -6932, 100, 0);

        router.swap(key, swapParams, testSettings, ZERO_BYTES);
    }

    function testSwap_leaveSurplusTokenInVault() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1000000000000000000}),
            ZERO_BYTES
        );

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(router), address(0), address(this), currency1, 98);
        router.swap(key, params, testSettings, ZERO_BYTES);

        uint256 surplusTokenAmount = vault.balanceOf(address(this), currency1);
        assertEq(surplusTokenAmount, 98);
    }

    function testSwap_useSurplusTokenAsInput() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1000000000000000000}),
            ZERO_BYTES
        );
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(router), address(0), address(this), currency1, 98);
        router.swap(key, params, testSettings, ZERO_BYTES);

        uint256 surplusTokenAmount = vault.balanceOf(address(this), currency1);
        assertEq(surplusTokenAmount, 98);

        // give permission for router to burn the surplus tokens
        vault.approve(address(router), currency0, type(uint256).max);
        vault.approve(address(router), currency1, type(uint256).max);

        // swap from currency1 to currency0 again, using surplus tokne as input
        params = ICLPoolManager.SwapParams({zeroForOne: false, amountSpecified: -25, sqrtPriceLimitX96: SQRT_RATIO_4_1});

        testSettings = CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: false});

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(router), address(router), address(0), currency1, 27);
        router.swap(key, params, testSettings, ZERO_BYTES);

        surplusTokenAmount = vault.balanceOf(address(this), currency1);
        assertEq(surplusTokenAmount, 71);
    }

    function testSwap_gas() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.swap(key, params, testSettings, ZERO_BYTES);

        params = ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_4});
        testSettings = CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: false});

        snapStart("CLPoolManagerTest#swap_simple");
        router.swap(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    function testSwap_withNative_gas() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.swap(key, params, testSettings, ZERO_BYTES);

        params = ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_4});
        testSettings = CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: false});

        snapStart("CLPoolManagerTest#swap_withNative");
        router.swap(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    function testSwap_withHooks_gas() public {
        MockHooks mockHooks = new MockHooks();

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32((uint256(60) << 16) | mockHooks.getHooksRegistrationBitmap())
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.swap(key, params, testSettings, ZERO_BYTES);

        params = ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_4});
        testSettings = CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        snapStart("CLPoolManagerTest#swap_withHooks");
        router.swap(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    function testSwap_leaveSurplusTokenInVault_gas() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1000000000000000000}),
            ZERO_BYTES
        );

        snapStart("CLPoolManagerTest#swap_leaveSurplusTokenInVault");
        router.swap(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    function testSwap_useSurplusTokenAsInput_gas() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: false, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1000000000000000000}),
            ZERO_BYTES
        );
        router.swap(key, params, testSettings, ZERO_BYTES);

        uint256 surplusTokenAmount = vault.balanceOf(address(this), currency1);
        assertEq(surplusTokenAmount, 98);

        // give permission for router to burn the surplus tokens
        vault.approve(address(router), currency0, type(uint256).max);
        vault.approve(address(router), currency1, type(uint256).max);

        // swap from currency1 to currency0 again, using surplus tokne as input
        params = ICLPoolManager.SwapParams({zeroForOne: false, amountSpecified: -25, sqrtPriceLimitX96: SQRT_RATIO_4_1});

        testSettings = CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: false});

        snapStart("CLPoolManagerTest#swap_useSurplusTokenAsInput");
        router.swap(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    function testSwap_againstLiq_gas() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1000000000000000000}),
            ZERO_BYTES
        );

        router.swap(key, params, testSettings, ZERO_BYTES);

        params = ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_4});

        snapStart("CLPoolManagerTest#swap_againstLiquidity");
        router.swap(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    function testSwap_againstLiqWithNative_gas() public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        router.modifyPosition{value: 1 ether}(
            key,
            ICLPoolManager.ModifyLiquidityParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1 ether}),
            ZERO_BYTES
        );

        router.swap{value: 1 ether}(key, params, testSettings, ZERO_BYTES);

        params = ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_4});

        snapStart("CLPoolManagerTest#swap_againstLiquidity");
        router.swap{value: 1 ether}(key, params, testSettings, ZERO_BYTES);
        snapEnd();
    }

    // **************        *************** //
    // **************  donate  *************** //
    // **************        *************** //

    function testDonateFailsIfNotInitialized() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16))
        });
        vm.expectRevert(abi.encodeWithSelector(CLPool.PoolNotInitialized.selector));
        router.donate(key, 100, 100, ZERO_BYTES);
    }

    function testDonateFailsIfNoLiquidity(uint160 sqrtPriceX96) public {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16))
        });
        poolManager.initialize(key, sqrtPriceX96, ZERO_BYTES);
        vm.expectRevert(abi.encodeWithSelector(CLPool.NoLiquidityToReceiveFees.selector));
        router.donate(key, 100, 100, ZERO_BYTES);
    }

    // test successful donation if pool has liquidity
    function testDonateSucceedsWhenPoolHasLiquidity() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16))
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition(key, params, ZERO_BYTES);
        snapStart("CLPoolManagerTest#donateBothTokens");
        router.donate(key, 100, 200, ZERO_BYTES);
        snapEnd();

        (, uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128,,) = poolManager.pools(key.toId());
        assertEq(feeGrowthGlobal0X128, 340282366920938463463374607431768211456);
        assertEq(feeGrowthGlobal1X128, 680564733841876926926749214863536422912);
    }

    function testDonateSucceedsForNativeTokensWhenPoolHasLiquidity() public {
        vm.deal(address(this), 1 ether);

        PoolKey memory key = PoolKey({
            currency0: CurrencyLibrary.NATIVE,
            currency1: currency1,
            fee: 100,
            poolManager: poolManager,
            hooks: IHooks(address(0)),
            parameters: bytes32(uint256(10 << 16))
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition{value: 1}(key, params, ZERO_BYTES);
        router.donate{value: 100}(key, 100, 200, ZERO_BYTES);

        (, uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128,,) = poolManager.pools(key.toId());
        assertEq(feeGrowthGlobal0X128, 340282366920938463463374607431768211456);
        assertEq(feeGrowthGlobal1X128, 680564733841876926926749214863536422912);
    }

    function testDonateFailsWithIncorrectSelectors() public {
        address hookAddr = makeAddr("hook");

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16) | impl.getHooksRegistrationBitmap())
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition(key, params, ZERO_BYTES);
        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, bytes4(0xdeadbeef));
        mockHooks.setReturnValue(mockHooks.afterDonate.selector, bytes4(0xdeadbeef));

        // Fails at beforeDonate hook.
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        router.donate(key, 100, 200, ZERO_BYTES);

        // Fail at afterDonate hook.
        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, mockHooks.beforeDonate.selector);
        vm.expectRevert(Hooks.InvalidHookResponse.selector);
        router.donate(key, 100, 200, ZERO_BYTES);
    }

    function testDonateSucceedsWithCorrectSelectors() public {
        address hookAddr = makeAddr("hook");

        MockHooks impl = new MockHooks();
        vm.etch(hookAddr, address(impl).code);
        MockHooks mockHooks = MockHooks(hookAddr);

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: mockHooks,
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16) | impl.getHooksRegistrationBitmap())
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition(key, params, ZERO_BYTES);

        mockHooks.setReturnValue(mockHooks.beforeDonate.selector, mockHooks.beforeDonate.selector);
        mockHooks.setReturnValue(mockHooks.afterDonate.selector, mockHooks.afterDonate.selector);

        router.donate(key, 100, 200, ZERO_BYTES);
    }

    function testDonateSuccessWithEventEmitted() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16))
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition(key, params, ZERO_BYTES);

        (, int24 tick,,) = poolManager.getSlot0(key.toId());

        vm.expectEmit();
        emit Donate(key.toId(), address(router), 100, 0, tick);

        router.donate(key, 100, 0, ZERO_BYTES);
    }

    function testGasDonateOneToken() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10 << 16))
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition(key, params, ZERO_BYTES);

        snapStart("CLPoolManagerTest#gasDonateOneToken");
        router.donate(key, 100, 0, ZERO_BYTES);
        snapEnd();
    }

    function testTake_failsWithInvalidTokensThatDoNotReturnTrueOnTransfer() public {
        NonStandardERC20 invalidToken = new NonStandardERC20(2 ** 255);
        Currency invalidCurrency = Currency.wrap(address(invalidToken));
        bool currency0Invalid = invalidCurrency < currency0;
        PoolKey memory key = PoolKey({
            currency0: currency0Invalid ? invalidCurrency : currency0,
            currency1: currency0Invalid ? currency0 : invalidCurrency,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(60) << 16)
        });

        invalidToken.approve(address(router), type(uint256).max);
        invalidToken.approve(address(router), type(uint256).max);
        MockERC20(Currency.unwrap(currency0)).approve(address(router), type(uint256).max);

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 1000);
        router.modifyPosition(key, params, ZERO_BYTES);

        (uint256 amount0, uint256 amount1) = currency0Invalid ? (1, 0) : (0, 1);
        vm.expectRevert();
        router.take(key, amount0, amount1);

        // should not revert when non zero amount passed in for valid currency
        // assertions inside router because it takes then settles
        (amount0, amount1) = currency0Invalid ? (0, 1) : (1, 0);
        router.take(key, amount0, amount1);
    }

    function testTake_succeedsWithPoolWithLiquidity() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition(key, params, ZERO_BYTES);
        router.take(key, 1, 1); // assertions inside router because it takes then settles
    }

    function testTake_succeedsWithPoolWithLiquidityWithNativeToken() public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-60, 60, 100);
        router.modifyPosition{value: 100}(key, params, ZERO_BYTES);
        router.take{value: 1}(key, 1, 1); // assertions inside router because it takes then settles
    }

    function testSetProtocolFee_updatesProtocolFeeForInitializedPool() public {
        uint16 protocolFee = 4;

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.protocolFee, 0);
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        feeController.setSwapFeeForPool(key.toId(), uint16(protocolFee));

        vm.expectEmit(false, false, false, true);
        emit ProtocolFeeUpdated(key.toId(), protocolFee);
        poolManager.setProtocolFee(key);
    }

    function testCollectProtocolFees_initializesWithProtocolFeeIfCalled() public {
        uint16 protocolFee = 1028; // 00000100 00000100 i.e. 25%
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 100,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        feeController.setSwapFeeForPool(key.toId(), uint16(protocolFee));

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.protocolFee, protocolFee);
    }

    function testCollectProtocolFees_ERC20_allowsOwnerToAccumulateFees() public {
        uint16 protocolFee = 1028; // 00000100 00000100 i.e. 25%
        // swap fee i.e. 0.3% * protocol fee i.e. 25% * input amount i.e. 10000 = 0.075%
        uint256 expectedFees = uint256(10000) * 3000 / 1000000 * 25 / 100;

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        feeController.setSwapFeeForPool(key.toId(), uint16(protocolFee));

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.protocolFee, protocolFee);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-120, 120, 10 ether);
        router.modifyPosition(key, params, ZERO_BYTES);
        router.swap(
            key,
            ICLPoolManager.SwapParams(true, 10000, SQRT_RATIO_1_2),
            CLPoolManagerRouter.SwapTestSettings(true, true),
            ZERO_BYTES
        );

        assertEq(poolManager.protocolFeesAccrued(currency0), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(currency1), 0);
        assertEq(currency0.balanceOf(address(1)), 0);
        poolManager.collectProtocolFees(address(1), currency0, expectedFees);
        assertEq(currency0.balanceOf(address(1)), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(currency0), 0);
    }

    function testCollectProtocolFees_ERC20_returnsAllFeesIf0IsProvidedAsParameter() public {
        uint16 protocolFee = 1028; // 00000100 00000100 i.e. 25%
        // swap fee i.e. 0.3% * protocol fee i.e. 25% * input amount i.e. 10000 = 0.075%
        uint256 expectedFees = uint256(10000) * 3000 / 1000000 * 25 / 100;

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        feeController.setSwapFeeForPool(key.toId(), uint16(protocolFee));

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.protocolFee, protocolFee);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-120, 120, 10 ether);
        router.modifyPosition(key, params, ZERO_BYTES);
        router.swap(
            key,
            ICLPoolManager.SwapParams(true, 10000, SQRT_RATIO_1_2),
            CLPoolManagerRouter.SwapTestSettings(true, true),
            ZERO_BYTES
        );

        assertEq(poolManager.protocolFeesAccrued(currency0), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(currency1), 0);
        assertEq(currency0.balanceOf(address(1)), 0);
        poolManager.collectProtocolFees(address(1), currency0, 0);
        assertEq(currency0.balanceOf(address(1)), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(currency0), 0);
    }

    function testCollectProtocolFees_nativeToken_allowsOwnerToAccumulateFees() public {
        uint16 protocolFee = 1028; // 00000100 00000100 i.e. 25%
        // swap fee i.e. 0.3% * protocol fee i.e. 25% * input amount i.e. 10000 = 0.075%
        uint256 expectedFees = uint256(10000) * 3000 / 1000000 * 25 / 100;
        Currency nativeCurrency = Currency.wrap(address(0));

        PoolKey memory key = PoolKey({
            currency0: nativeCurrency,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        feeController.setSwapFeeForPool(key.toId(), uint16(protocolFee));

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.protocolFee, protocolFee);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-120, 120, 10 ether);
        router.modifyPosition{value: 10 ether}(key, params, ZERO_BYTES);
        router.swap{value: 10000}(
            key,
            ICLPoolManager.SwapParams(true, 10000, SQRT_RATIO_1_2),
            CLPoolManagerRouter.SwapTestSettings(true, true),
            ZERO_BYTES
        );

        assertEq(poolManager.protocolFeesAccrued(nativeCurrency), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(currency1), 0);
        assertEq(nativeCurrency.balanceOf(address(1)), 0);
        poolManager.collectProtocolFees(address(1), nativeCurrency, expectedFees);
        assertEq(nativeCurrency.balanceOf(address(1)), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(nativeCurrency), 0);
    }

    function testCollectProtocolFees_nativeToken_returnsAllFeesIf0IsProvidedAsParameter() public {
        uint16 protocolFee = 1028; // 00000100 00000100 i.e. 25%
        // swap fee i.e. 0.3% * protocol fee i.e. 25% * input amount i.e. 10000 = 0.075%
        uint256 expectedFees = uint256(10000) * 3000 / 1000000 * 25 / 100;
        Currency nativeCurrency = Currency.wrap(address(0));

        PoolKey memory key = PoolKey({
            currency0: nativeCurrency,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        feeController.setSwapFeeForPool(key.toId(), uint16(protocolFee));

        poolManager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);
        (CLPool.Slot0 memory slot0,,,,) = poolManager.pools(key.toId());
        assertEq(slot0.protocolFee, protocolFee);

        ICLPoolManager.ModifyLiquidityParams memory params = ICLPoolManager.ModifyLiquidityParams(-120, 120, 10 ether);
        router.modifyPosition{value: 10 ether}(key, params, ZERO_BYTES);
        router.swap{value: 10000}(
            key,
            ICLPoolManager.SwapParams(true, 10000, SQRT_RATIO_1_2),
            CLPoolManagerRouter.SwapTestSettings(true, true),
            ZERO_BYTES
        );

        assertEq(poolManager.protocolFeesAccrued(nativeCurrency), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(currency1), 0);
        assertEq(nativeCurrency.balanceOf(address(1)), 0);
        poolManager.collectProtocolFees(address(1), nativeCurrency, 0);
        assertEq(nativeCurrency.balanceOf(address(1)), expectedFees);
        assertEq(poolManager.protocolFeesAccrued(nativeCurrency), 0);
    }

    function testUpdateDynamicSwapFee_FeeTooLarge() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(3000), // 3000 = 0.3%
            hooks: IHooks(address(clFeeManagerHook)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });

        clFeeManagerHook.setFee(FeeLibrary.ONE_HUNDRED_PERCENT_FEE);

        vm.expectRevert(IFees.FeeTooLarge.selector);
        poolManager.updateDynamicSwapFee(key);
    }

    function testUpdateDynamicSwapFee_FeeNotDynamic() public {
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: uint24(3000), // 3000 = 0.3%
            hooks: IHooks(address(clFeeManagerHook)),
            poolManager: poolManager,
            parameters: bytes32(uint256(10) << 16)
        });

        vm.expectRevert(IFees.FeeNotDynamic.selector);
        poolManager.updateDynamicSwapFee(key);
    }

    function testFuzzUpdateDynamicSwapFee(uint24 _swapFee) public {
        vm.assume(_swapFee < FeeLibrary.ONE_HUNDRED_PERCENT_FEE);

        uint16 bitMap = 0x0010; // 0000 0000 0001 0000 (before swap call)
        clFeeManagerHook.setHooksRegistrationBitmap(bitMap);

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG + uint24(3000), // 3000 = 0.3%
            hooks: IHooks(address(clFeeManagerHook)),
            poolManager: poolManager,
            parameters: bytes32(uint256((10 << 16) | clFeeManagerHook.getHooksRegistrationBitmap()))
        });

        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));

        clFeeManagerHook.setFee(_swapFee);

        vm.expectEmit();
        emit DynamicSwapFeeUpdated(key.toId(), _swapFee);

        snapStart("CLPoolManagerTest#testFuzzUpdateDynamicSwapFee");
        poolManager.updateDynamicSwapFee(key);
        snapEnd();

        (,,, uint24 swapFee) = poolManager.getSlot0(key.toId());
        assertEq(swapFee, _swapFee);
    }

    function testNoOp_gas() public {
        uint16 bitMap = 0x0550; // 0000 0101 0101 0000 (only noOp, beforeRemoveLiquidity, beforeSwap, beforeDonate)

        // pre-req create pool
        CLNoOpTestHook noOpHook = new CLNoOpTestHook();
        noOpHook.setHooksRegistrationBitmap(bitMap);
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            hooks: IHooks(noOpHook),
            poolManager: poolManager,
            parameters: bytes32(uint256((60 << 16) | noOpHook.getHooksRegistrationBitmap()))
        });

        snapStart("CLPoolManagerTest#testNoOp_gas_Initialize");
        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        snapEnd();

        BalanceDelta delta;

        // Action 1: modify
        ICLPoolManager.ModifyLiquidityParams memory params;
        snapStart("CLPoolManagerTest#testNoOp_gas_ModifyPosition");
        delta = router.modifyPosition(key, params, ZERO_BYTES);
        snapEnd();
        assertTrue(delta == BalanceDeltaLibrary.MAXIMUM_DELTA);

        // Action 2: swap
        snapStart("CLPoolManagerTest#testNoOp_gas_Swap");
        delta = router.swap(
            key,
            ICLPoolManager.SwapParams(true, 10000, SQRT_RATIO_1_2),
            CLPoolManagerRouter.SwapTestSettings(true, true),
            ZERO_BYTES
        );
        snapEnd();
        assertTrue(delta == BalanceDeltaLibrary.MAXIMUM_DELTA);

        // Action 3: donate
        snapStart("CLPoolManagerTest#testNoOp_gas_Donate");
        delta = router.donate(key, 100, 100, ZERO_BYTES);
        snapEnd();
        assertTrue(delta == BalanceDeltaLibrary.MAXIMUM_DELTA);
    }

    function testSetMasterChef(address masterChef) public {
        assertEq(poolManager.masterChef(), address(0));

        vm.expectEmit();
        emit SetMasterChef(masterChef);
        poolManager.setMasterChef(masterChef);

        assertEq(poolManager.masterChef(), masterChef);
    }

    function testSetMasterChef_gas() public {
        snapStart("CLPoolManagerTest#setMasterChef");
        poolManager.setMasterChef(address(0x01));
        snapEnd();
    }

    function testSetMasterChef_NotOwner() public {
        vm.prank(makeAddr("fakeOwner"));
        vm.expectRevert("Ownable: caller is not the owner");
        poolManager.setMasterChef(makeAddr("masterChef"));
    }

    function testSetLmPool() public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(makeAddr("token0")),
            currency1: Currency.wrap(makeAddr("token1")),
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            parameters: bytes32(uint256(0xa0000))
        });

        address lmPool = makeAddr("lmPool");
        address masterChef = makeAddr("masterChef");

        // error when not initialized
        vm.expectRevert(CLPool.PoolNotInitialized.selector);
        poolManager.getLmPool(key.toId());

        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));
        assertEq(poolManager.getLmPool(key.toId()), address(0));

        // error when setting from neither masterChef or owner
        vm.expectRevert(ICLPoolManager.UnauthorizedCaller.selector);
        vm.prank(makeAddr("someone"));
        poolManager.setLmPool(key, address(lmPool));

        // success when caller is masterchef
        poolManager.setMasterChef(masterChef);
        vm.startPrank(masterChef);
        vm.expectEmit();
        emit SetLmPool(key.toId(), address(lmPool));
        poolManager.setLmPool(key, address(lmPool));

        assertEq(poolManager.getLmPool(key.toId()), address(lmPool));

        // success when caller is owner
        vm.expectEmit();
        emit SetLmPool(key.toId(), address(0));
        poolManager.setLmPool(key, address(0));
        assertEq(poolManager.getLmPool(key.toId()), address(0));
    }

    function testSetLmPool_gas() public {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(makeAddr("token0")),
            currency1: Currency.wrap(makeAddr("token1")),
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: uint24(3000),
            parameters: bytes32(uint256(0xa0000))
        });

        address lmPool = makeAddr("lmPool");
        address masterChef = makeAddr("masterChef");

        poolManager.initialize(key, TickMath.MIN_SQRT_RATIO, new bytes(0));

        poolManager.setMasterChef(masterChef);
        vm.startPrank(masterChef);

        snapStart("CLPoolManagerTest#setLmPool");
        poolManager.setLmPool(key, address(lmPool));
        snapEnd();
    }

    function _validateHookConfig(PoolKey memory poolKey) internal view returns (bool) {
        uint16 bitmapInParameters = poolKey.parameters.getHooksRegistrationBitmap();
        if (address(poolKey.hooks) == address(0)) {
            if (bitmapInParameters == 0 && !poolKey.fee.isDynamicFee()) {
                return true;
            }
            return false;
        }

        if (poolKey.hooks.getHooksRegistrationBitmap() != bitmapInParameters) {
            return false;
        }

        return true;
    }

    function tryExecute(address target, bytes memory msgData) external {
        (bool success, bytes memory result) = target.call(msgData);
        if (!success) {
            return;
        }

        assembly {
            revert(add(result, 0x20), mload(result))
        }
    }

    fallback() external payable {}

    receive() external payable {}
}
