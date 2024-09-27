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

import {IHooks} from "../interfaces/IHooks.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {BeforeSwapDelta} from "../types/BeforeSwapDelta.sol";

contract EmptyRevertHook is IHooks {
    function beforeInitialize(
        address, /* sender **/
        PoolKey calldata, /* key **/
        uint160, /* sqrtPriceX96 **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4) {
        revert();
    }

    function afterInitialize(
        address, /* sender **/
        PoolKey calldata, /* key **/
        uint160, /* sqrtPriceX96 **/
        int24, /* tick **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4) {
        revert();
    }

    function beforeAddLiquidity(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4) {
        revert();
    }

    function afterAddLiquidity(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        BalanceDelta, /* delta **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4, BalanceDelta) {
        revert();
    }

    function beforeRemoveLiquidity(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4) {
        revert();
    }

    function afterRemoveLiquidity(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        BalanceDelta, /* delta **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4, BalanceDelta) {
        revert();
    }

    function beforeSwap(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.SwapParams calldata, /* params **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4, BeforeSwapDelta, uint24) {
        revert();
    }

    function afterSwap(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.SwapParams calldata, /* params **/
        BalanceDelta, /* delta **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4, int128) {
        revert();
    }

    function beforeDonate(
        address, /* sender **/
        PoolKey calldata, /* key **/
        uint256, /* amount0 **/
        uint256, /* amount1 **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4) {
        revert();
    }

    function afterDonate(
        address, /* sender **/
        PoolKey calldata, /* key **/
        uint256, /* amount0 **/
        uint256, /* amount1 **/
        bytes calldata /* hookData **/
    ) external virtual returns (bytes4) {
        revert();
    }
}
