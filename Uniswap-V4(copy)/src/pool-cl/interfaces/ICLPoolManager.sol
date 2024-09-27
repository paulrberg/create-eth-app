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
  
  //SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "../../types/Currency.sol";
import {PoolKey} from "../../types/PoolKey.sol";
import {CLPool} from "../libraries/CLPool.sol";
import {ICLHooks} from "./ICLHooks.sol";
import {IFees} from "../../interfaces/IFees.sol";
import {BalanceDelta} from "../../types/BalanceDelta.sol";
import {PoolId} from "../../types/PoolId.sol";
import {CLPosition} from "../libraries/CLPosition.sol";
import {IPoolManager} from "../../interfaces/IPoolManager.sol";
import {IExtsload} from "../../interfaces/IExtsload.sol";

interface ICLPoolManager is IFees, IPoolManager, IExtsload {
    /// @notice PoolManagerMismatch is thrown when pool manager specified in the pool key does not match current contract
    error PoolManagerMismatch();
    /// @notice Pools are limited to type(int16).max tickSpacing in #initialize, to prevent overflow
    error TickSpacingTooLarge();
    /// @notice Pools must have a positive non-zero tickSpacing passed to #initialize
    error TickSpacingTooSmall();
    /// @notice Error thrown when Unauthorized caller
    error UnauthorizedCaller();

    /// @notice Emitted when a new pool is initialized
    /// @param id The abi encoded hash of the pool key struct for the new pool
    /// @param currency0 The first currency of the pool by address sort order
    /// @param currency1 The second currency of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param hooks The hooks contract address for the pool, or address(0) if none
    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        int24 tickSpacing,
        ICLHooks hooks
    );

    /// @notice Emitted when a liquidity position is modified
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidityDelta The amount of liquidity that was added or removed
    event ModifyLiquidity(
        PoolId indexed id, address indexed sender, int24 tickLower, int24 tickUpper, int256 liquidityDelta
    );

    /// @notice Emitted for swaps between currency0 and currency1
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param amount0 The delta of the currency0 balance of the pool
    /// @param amount1 The delta of the currency1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of the price of the pool after the swap
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param protocolFee Protocol fee from the swap, and it is only on the input currency
    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee,
        uint256 protocolFee
    );

    /// @notice Emitted when donate happen
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param amount0 The delta of the currency0 balance of the pool
    /// @param amount1 The delta of the currency1 balance of the pool
    /// @param tick The donated tick
    event Donate(PoolId indexed id, address indexed sender, uint256 amount0, uint256 amount1, int24 tick);

    /// @notice Emitted when masterChef is updated
    event SetMasterChef(address masterChef);

    /// @notice Emitted when LMPool is set for a pool
    event SetLmPool(PoolId indexed id, address lmPool);

    /// @notice Returns the constant representing the maximum tickSpacing for an initialized pool key
    function MAX_TICK_SPACING() external view returns (int24);

    /// @notice Returns the constant representing the minimum tickSpacing for an initialized pool key
    function MIN_TICK_SPACING() external view returns (int24);

    /// @notice Get the current value in slot0 of the given pool
    function getSlot0(PoolId id)
        external
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint16 protocolFee, uint24 swapFee);

    /// @notice Get the current value of liquidity of the given pool
    function getLiquidity(PoolId id) external view returns (uint128 liquidity);

    /// @notice Get the current value of liquidity for the specified pool and position
    function getLiquidity(PoolId id, address owner, int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint128 liquidity);

    /// @notice Get the position struct for a specified pool and position
    function getPosition(PoolId id, address owner, int24 tickLower, int24 tickUpper)
        external
        view
        returns (CLPosition.Info memory position);

    /// @notice Initialize the state for a given pool ID
    function initialize(PoolKey memory key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        returns (int24 tick);

    struct ModifyLiquidityParams {
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // how to modify the liquidity
        int256 liquidityDelta;
    }

    /// @notice Modify the position for the given pool
    function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta);

    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swap against the given pool
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta);

    /// @notice Donate the given currency amounts to the pool with the given pool key
    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta);

    /// @notice Set masterChef address, in case when farming incentive for a pool begin.
    /// @dev If farming is migrated to off-chain in the future, masterChef can be reverted to address(0)
    function setMasterChef(address masterChef) external;

    /// @notice Return the masterChef address set
    function masterChef() external returns (address);

    /// @notice Set liquidity mining pool for a poolId. if a pool has farmining incentive, masterChef
    ///         will deploy and assign an LM Pool to a pool.
    /// @dev During swap, pool will call LMPool to accumulate reward or notify when current tick is crossed.
    ///      The only reason why owner call is when we no longer rely on lmPool for farming incentives or
    ///      there is an issue with the existing lmPool and we need to change it.
    function setLmPool(PoolKey memory key, address lmPool) external;

    /// @notice Return the lmPool for a poolId, address(0) if not set
    function getLmPool(PoolId id) external view returns (address);
}
