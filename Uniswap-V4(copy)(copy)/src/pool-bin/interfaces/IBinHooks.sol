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

import {PoolKey} from "../../types/PoolKey.sol";
import {BalanceDelta} from "../../types/BalanceDelta.sol";
import {IBinPoolManager} from "./IBinPoolManager.sol";
import {IHooks} from "../../interfaces/IHooks.sol";

uint8 constant HOOKS_BEFORE_INITIALIZE_OFFSET = 0;
uint8 constant HOOKS_AFTER_INITIALIZE_OFFSET = 1;
uint8 constant HOOKS_BEFORE_MINT_OFFSET = 2;
uint8 constant HOOKS_AFTER_MINT_OFFSET = 3;
uint8 constant HOOKS_BEFORE_BURN_OFFSET = 4;
uint8 constant HOOKS_AFTER_BURN_OFFSET = 5;
uint8 constant HOOKS_BEFORE_SWAP_OFFSET = 6;
uint8 constant HOOKS_AFTER_SWAP_OFFSET = 7;
uint8 constant HOOKS_BEFORE_DONATE_OFFSET = 8;
uint8 constant HOOKS_AFTER_DONATE_OFFSET = 9;
uint8 constant HOOKS_NO_OP_OFFSET = 10;

/// @notice The PoolManager contract decides whether to invoke specific hook by inspecting the first 16
/// bits of bytes32 PoolKey.parameters. For example a 1 bit in the first bit will cause the beforeInitialize
/// hook to be invoked.
/// @dev Should only be callable by the PoolManager.
interface IBinHooks is IHooks {
    /// @notice The hook called before the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param activeId The binId of the pool, when the value is 2 ** 23, token price is 1:1
    /// @param hookData Arbitrary data handed into the PoolManager by the initializer to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeInitialize(address sender, PoolKey calldata key, uint24 activeId, bytes calldata hookData)
        external
        returns (bytes4);

    /// @notice The hook called after the state of a pool is initialized
    /// @param sender The initial msg.sender for the initialize call
    /// @param key The key for the pool being initialized
    /// @param activeId The binId of the pool, when the value is 2 ** 23, token price is 1:1
    /// @param hookData Arbitrary data handed into the PoolManager by the initializer to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterInitialize(address sender, PoolKey calldata key, uint24 activeId, bytes calldata hookData)
        external
        returns (bytes4);

    /// @notice The hook called before adding liquidity
    /// @param sender The initial msg.sender for the modify position call
    /// @param key The key for the pool
    /// @param params The parameters for adding liquidity
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidty provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeMint(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.MintParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after adding liquidity
    /// @param sender The initial msg.sender for the modify position call
    /// @param key The key for the pool
    /// @param params The parameters for adding liquidity
    /// @param delta The amount owed to the locker (negative) or owed to the pool (positive)
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidty provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterMint(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.MintParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called before removing liquidity
    /// @param sender The initial msg.sender for the modify position call
    /// @param key The key for the pool
    /// @param params The parameters for removing liquidity
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidty provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeBurn(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.BurnParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after removing liquidity
    /// @param sender The initial msg.sender for the modify position call
    /// @param key The key for the pool
    /// @param params The parameters for removing liquidity
    /// @param delta The amount owed to the locker (negative) or owed to the pool (positive)
    /// @param hookData Arbitrary data handed into the PoolManager by the liquidty provider to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterBurn(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.BurnParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called before a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param swapForY If true, indicate swap X for Y or if false, swap Y for X
    /// @param amountIn Amount of tokenX or tokenY in
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeSwap(address sender, PoolKey calldata key, bool swapForY, uint128 amountIn, bytes calldata hookData)
        external
        returns (bytes4);

    /// @notice The hook called after a swap
    /// @param sender The initial msg.sender for the swap call
    /// @param key The key for the pool
    /// @param swapForY If true, indicate swap X for Y or if false, swap Y for X
    /// @param amountIn Amount of tokenX or tokenY in
    /// @param delta The amount owed to the locker (negative) or owed to the pool (positive)
    /// @param hookData Arbitrary data handed into the PoolManager by the swapper to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterSwap(
        address sender,
        PoolKey calldata key,
        bool swapForY,
        uint128 amountIn,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called before donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);

    /// @notice The hook called after donate
    /// @param sender The initial msg.sender for the donate call
    /// @param key The key for the pool
    /// @param amount0 The amount of token0 being donated
    /// @param amount1 The amount of token1 being donated
    /// @param hookData Arbitrary data handed into the PoolManager by the donor to be be passed on to the hook
    /// @return bytes4 The function selector for the hook
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (bytes4);
}
