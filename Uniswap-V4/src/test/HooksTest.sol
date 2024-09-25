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
pragma solidity ^0.8.20;

import {Hooks} from "../libraries/Hooks.sol";
import {IHooks} from "../interfaces/IHooks.sol";

contract HooksTest {
    using Hooks for IHooks;

    function validateHookPermissions(address hookAddress, Hooks.Permissions calldata params) external pure {
        IHooks(hookAddress).validateHookPermissions(params);
    }

    function isValidHookAddress(address hookAddress, uint24 fee) external pure returns (bool) {
        return IHooks(hookAddress).isValidHookAddress(fee);
    }

    function shouldCallBeforeInitialize(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.BEFORE_INITIALIZE_FLAG);
    }

    function shouldCallAfterInitialize(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.AFTER_INITIALIZE_FLAG);
    }

    function shouldCallBeforeSwap(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.BEFORE_SWAP_FLAG);
    }

    function shouldCallAfterSwap(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.AFTER_SWAP_FLAG);
    }

    function shouldCallBeforeAddLiquidity(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.BEFORE_ADD_LIQUIDITY_FLAG);
    }

    function shouldCallAfterAddLiquidity(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.AFTER_ADD_LIQUIDITY_FLAG);
    }

    function shouldCallBeforeRemoveLiquidity(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG);
    }

    function shouldCallAfterRemoveLiquidity(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.AFTER_REMOVE_LIQUIDITY_FLAG);
    }

    function shouldCallBeforeDonate(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.BEFORE_DONATE_FLAG);
    }

    function shouldCallAfterDonate(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).hasPermission(Hooks.AFTER_DONATE_FLAG);
    }

    function getGasCostOfShouldCall(address hookAddress) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        IHooks(hookAddress).hasPermission(Hooks.BEFORE_SWAP_FLAG);
        return gasBefore - gasleft();
    }

    function getGasCostOfValidateHookAddress(address hookAddress, Hooks.Permissions calldata params)
        external
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        IHooks(hookAddress).validateHookPermissions(params);
        return gasBefore - gasleft();
    }
}
