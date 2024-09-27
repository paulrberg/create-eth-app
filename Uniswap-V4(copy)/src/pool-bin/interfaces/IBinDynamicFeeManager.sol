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
import {IBinPoolManager} from "./IBinPoolManager.sol";

/// @notice The dynamic fee manager determines fees for pools
/// @dev note that this pool is only called if the PoolKey fee value is equal to the DYNAMIC_FEE magic value
interface IBinDynamicFeeManager {
    /// @notice Called to look up swap fee for pool when PoolManager#updateDynamicSwapFee is called
    /// @return swapFee 10_000 represent 1%, 3_000 represent 0.3%
    function getFee(address sender, PoolKey calldata key) external view returns (uint24);

    /// @notice Called whenever BinPoolManager getSwapIn or getSwapOut is called
    /// @dev getSwapIn or getSwapOut was added to allow on-chain quotes for integrators. For hook dev, this is similar to getFee, with extra swap parameter (swapForY and amount).
    ///      Hooks should ensure that this returns the same value as if the user was to perform an actual swap.
    /// @param amountIn either amountIn or amountOut will be non-zero, if amountIn non-zero, imply a swap with amountIn
    /// @param amountOut either amountIn or amountOut will be non-zero, if amountOut non-zero, imply a swap with amountOut
    /// @return swapFee 10_000 represent 1%, 3_000 represent 0.3%
    function getFeeForSwapInSwapOut(
        address sender,
        PoolKey calldata key,
        bool swapForY,
        uint128 amountIn,
        uint128 amountOut
    ) external view returns (uint24);
}
