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

import {PoolId} from "../types/PoolId.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {IPoolManager} from "./IPoolManager.sol";
import {Currency} from "../types/Currency.sol";

interface IVaultToken {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OperatorSet(address indexed owner, address indexed operator, bool approved);

    event Approval(address indexed owner, address indexed spender, Currency indexed currency, uint256 amount);

    event Transfer(address caller, address indexed from, address indexed to, Currency indexed currency, uint256 amount);

    /// @notice get the amount of user's surplus token in vault
    function balanceOf(address user, Currency currency) external view returns (uint256);

    /// @notice get the amount that user has authorized for spender to use
    function allowance(address user, address spender, Currency currency) external view returns (uint256);

    /// @notice approve spender for using user's token
    function approve(address spender, Currency currency, uint256 amount) external returns (bool);

    /// @notice transfer user' token to someone else
    function transfer(address to, Currency currency, uint256 amount) external returns (bool);

    /// @notice transfer user's token to someone else on behalf of user
    function transferFrom(address from, address to, Currency currency, uint256 amount) external returns (bool);
}
