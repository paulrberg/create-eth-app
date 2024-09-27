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

import {IERC20} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../../../src/interfaces/IVault.sol";
import {HOOKS_NO_OP_OFFSET} from "../../../src/pool-bin/interfaces/IBinHooks.sol";
import {IBinPoolManager} from "../../../src/pool-bin/interfaces/IBinPoolManager.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../../../src/types/BalanceDelta.sol";
import {CurrencyLibrary, Currency} from "../../../src/types/Currency.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {Hooks} from "../../../src/libraries/Hooks.sol";

contract BinLiquidityHelper {
    using CurrencyLibrary for Currency;
    using Hooks for bytes32;

    error HookMissingNoOpPermission();

    IBinPoolManager public immutable binManager;
    IVault public immutable vault;
    ActionType public actionType;

    enum ActionType {
        Mint,
        Burn
    }

    constructor(IBinPoolManager _binManager, IVault _vault) {
        binManager = _binManager;
        vault = _vault;
    }

    struct BurnCallbackData {
        address sender;
        PoolKey key;
        IBinPoolManager.BurnParams params;
        bytes hookData;
    }

    struct MintCallbackData {
        address sender;
        PoolKey key;
        IBinPoolManager.MintParams params;
        bytes hookData;
    }

    function burn(PoolKey memory key, IBinPoolManager.BurnParams memory params, bytes memory hookData)
        external
        payable
        returns (BalanceDelta delta)
    {
        BurnCallbackData memory data = BurnCallbackData(msg.sender, key, params, hookData);
        actionType = ActionType.Burn;

        delta = abi.decode(vault.lock(abi.encode(data)), (BalanceDelta));
    }

    function mint(PoolKey memory key, IBinPoolManager.MintParams memory params, bytes memory hookData)
        external
        payable
        returns (BalanceDelta delta)
    {
        MintCallbackData memory data = MintCallbackData(msg.sender, key, params, hookData);
        actionType = ActionType.Mint;

        delta = abi.decode(vault.lock(abi.encode(data)), (BalanceDelta));
    }

    function lockAcquired(bytes calldata callbackData) external returns (bytes memory) {
        require(msg.sender == address(vault));
        BalanceDelta delta;
        PoolKey memory key;
        address sender;

        if (actionType == ActionType.Burn) {
            BurnCallbackData memory data = abi.decode(callbackData, (BurnCallbackData));

            key = data.key;
            sender = data.sender;
            delta = binManager.burn(data.key, data.params, data.hookData);
        } else if (actionType == ActionType.Mint) {
            MintCallbackData memory data = abi.decode(callbackData, (MintCallbackData));

            key = data.key;
            sender = data.sender;
            (delta,) = binManager.mint(data.key, data.params, data.hookData);
        }

        if (delta == BalanceDeltaLibrary.MAXIMUM_DELTA) {
            // check if the hook has permission to no-op, if true, return early
            if (!key.parameters.shouldCall(HOOKS_NO_OP_OFFSET)) {
                revert HookMissingNoOpPermission();
            }
            return abi.encode(delta);
        }

        if (delta.amount0() > 0) {
            if (key.currency0.isNative()) {
                vault.settle{value: uint128(delta.amount0())}(key.currency0);
            } else {
                IERC20(Currency.unwrap(key.currency0)).transferFrom(sender, address(vault), uint128(delta.amount0()));
                vault.settle(key.currency0);
            }
        }

        if (delta.amount1() > 0) {
            if (key.currency1.isNative()) {
                vault.settle{value: uint128(delta.amount1())}(key.currency1);
            } else {
                IERC20(Currency.unwrap(key.currency1)).transferFrom(sender, address(vault), uint128(delta.amount1()));
                vault.settle(key.currency1);
            }
        }

        if (delta.amount0() < 0) {
            vault.take(key.currency0, sender, uint128(-delta.amount0()));
        }
        if (delta.amount1() < 0) {
            vault.take(key.currency1, sender, uint128(-delta.amount1()));
        }

        return abi.encode(delta);
    }
}
