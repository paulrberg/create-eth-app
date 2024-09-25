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
import {ICLPoolManager} from "./ICLPoolManager.sol";

/// @notice The dynamic fee manager determines fees for pools
/// @dev note that this pool is only called if the PoolKey fee value is equal to the DYNAMIC_FEE magic value
interface ICLDynamicFeeManager {
    /// @notice Called to look up swap fee for pool when PoolManager#updateDynamicSwapFee is called
    /// @return swapFee 10_000 represent 1%, 3_000 represent 0.3%
    function getFee(address sender, PoolKey calldata key) external view returns (uint24);
}
