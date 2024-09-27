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
  
  // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "Uniswap-V4/forge-std/Test.sol";

import {IERC20} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenFixture} from "../../helpers/TokenFixture.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";
import {CLFeeManagerHook} from "../helpers/CLFeeManagerHook.sol";
import {Deployers} from "../helpers/Deployers.sol";
import {Vault} from "../../../src/Vault.sol";
import {CLPoolManager} from "../../../src/pool-cl/CLPoolManager.sol";
import {CLPoolParametersHelper} from "../../../src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {IFees} from "../../../src/interfaces/IFees.sol";
import {ICLPoolManager} from "../../../src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLPoolManagerRouter} from "../helpers/CLPoolManagerRouter.sol";
import {Currency} from "../../../src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {FixedPoint96} from "../../../src/pool-cl/libraries/FixedPoint96.sol";
import {HOOKS_BEFORE_SWAP_OFFSET} from "../../../src/pool-cl/interfaces/ICLHooks.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {Hooks} from "../../../src/libraries/Hooks.sol";

contract CLPoolSwapFeeTest is Deployers, TokenFixture, Test {
    using PoolIdLibrary for PoolKey;

    Vault vault;
    CLPoolManager poolManager;
    CLPoolManagerRouter router;

    CLFeeManagerHook hook;
    PoolKey dynamicFeeKey;
    PoolKey staticFeeKey;

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

    function setUp() public {
        initializeTokens();

        (vault, poolManager) = createFreshManager();

        router = new CLPoolManagerRouter(vault, poolManager);
        IERC20(Currency.unwrap(currency0)).approve(address(router), 10 ether);
        IERC20(Currency.unwrap(currency1)).approve(address(router), 10 ether);

        hook = new CLFeeManagerHook(poolManager);

        hook.setHooksRegistrationBitmap(uint16(1 << HOOKS_BEFORE_SWAP_OFFSET));
        dynamicFeeKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG,
            parameters: CLPoolParametersHelper.setTickSpacing(bytes32(uint256(hook.getHooksRegistrationBitmap())), 1)
        });

        staticFeeKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            // 50%
            fee: FeeLibrary.ONE_HUNDRED_PERCENT_FEE / 2,
            parameters: CLPoolParametersHelper.setTickSpacing(bytes32(uint256(hook.getHooksRegistrationBitmap())), 1)
        });
    }

    function testPoolInitializeFailsWithTooLargeFee() public {
        // cl pool swap fee is capped at 1_000_000
        hook.setFee(FeeLibrary.ONE_HUNDRED_PERCENT_FEE);

        vm.expectRevert(IFees.FeeTooLarge.selector);
        poolManager.initialize(dynamicFeeKey, SQRT_RATIO_1_1, ZERO_BYTES);

        {
            vm.expectRevert(IFees.FeeTooLarge.selector);
            staticFeeKey.fee = FeeLibrary.ONE_HUNDRED_PERCENT_FEE;
            poolManager.initialize(staticFeeKey, SQRT_RATIO_1_1, ZERO_BYTES);
        }
    }

    function testUpdateFailsWithTooLargeFee() public {
        hook.setFee(FeeLibrary.ONE_HUNDRED_PERCENT_FEE / 2);
        poolManager.initialize(dynamicFeeKey, SQRT_RATIO_1_1, ZERO_BYTES);

        hook.setFee(FeeLibrary.ONE_HUNDRED_PERCENT_FEE);
        vm.expectRevert(IFees.FeeTooLarge.selector);
        poolManager.updateDynamicSwapFee(dynamicFeeKey);
    }

    function testSwapWorks() public {
        hook.setFee(FeeLibrary.ONE_HUNDRED_PERCENT_FEE / 2);

        // starts from price = 1
        poolManager.initialize(dynamicFeeKey, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1 ether});
        router.modifyPosition(dynamicFeeKey, modifyPositionParams, ZERO_BYTES);

        vm.expectEmit(true, true, true, true);
        emit Swap(
            dynamicFeeKey.toId(),
            address(router),
            100,
            -49,
            79228162514264333632135824623,
            1000000000000000000,
            -1,
            500_000,
            0
        );

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        router.swap(dynamicFeeKey, params, testSettings, ZERO_BYTES);
    }

    function testSwapWorksWithStaticFee() public {
        // starts from price = 1
        poolManager.initialize(staticFeeKey, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1 ether});
        router.modifyPosition(staticFeeKey, modifyPositionParams, ZERO_BYTES);

        vm.expectEmit(true, true, true, true);
        emit Swap(
            staticFeeKey.toId(),
            address(router),
            100,
            -49,
            79228162514264333632135824623,
            1000000000000000000,
            -1,
            500_000,
            0
        );

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        router.swap(staticFeeKey, params, testSettings, ZERO_BYTES);
    }

    function testCacheDynamicFeeAndSwap() public {
        hook.setFee(FeeLibrary.ONE_HUNDRED_PERCENT_FEE / 2);

        // starts from price = 1
        poolManager.initialize(dynamicFeeKey, SQRT_RATIO_1_1, ZERO_BYTES);

        ICLPoolManager.ModifyLiquidityParams memory modifyPositionParams =
            ICLPoolManager.ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 1 ether});
        router.modifyPosition(dynamicFeeKey, modifyPositionParams, ZERO_BYTES);

        vm.expectEmit(true, true, true, true);
        // price does not move but tick decreased by 1 because of it hits exactly the lower bound
        emit Swap(dynamicFeeKey.toId(), address(router), 100, 0, SQRT_RATIO_1_1, 1000000000000000000, -1, 999999, 0);

        ICLPoolManager.SwapParams memory params =
            ICLPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});

        CLPoolManagerRouter.SwapTestSettings memory testSettings =
            CLPoolManagerRouter.SwapTestSettings({withdrawTokens: true, settleUsingTransfer: true});

        bytes memory data = abi.encode(true, uint24(FeeLibrary.ONE_HUNDRED_PERCENT_FEE - 1));
        router.swap(dynamicFeeKey, params, testSettings, data);
    }

    function testRevertOnInitPoolWithDynamicFee() public {
        PoolKey memory _key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: IHooks(address(0)),
            poolManager: poolManager,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG,
            parameters: CLPoolParametersHelper.setTickSpacing(bytes32(uint256(hook.getHooksRegistrationBitmap())), 1)
        });

        vm.expectRevert(Hooks.HookConfigValidationError.selector);
        poolManager.initialize(_key, SQRT_RATIO_1_1, ZERO_BYTES);
    }
}
