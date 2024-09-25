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

import {IVault} from "../../../src/interfaces/IVault.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "../../../src/types/Currency.sol";
import {IPoolManager} from "../../../src/interfaces/IPoolManager.sol";
import {ICLPoolManager} from "../../../src/pool-cl/interfaces/ICLPoolManager.sol";
import {console2} from "Uniswap-V4/forge-std/console2.sol";
import {IERC20} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../../../src/types/BalanceDelta.sol";
import {HOOKS_NO_OP_OFFSET} from "../../../src/pool-cl/interfaces/ICLHooks.sol";
import {Hooks} from "../../../src/libraries/Hooks.sol";

contract CLPoolManagerRouter {
    error InvalidAction();
    error HookMissingNoOpPermission();

    using CurrencyLibrary for Currency;
    using Hooks for bytes32;

    IVault public immutable vault;
    ICLPoolManager public immutable poolManager;

    constructor(IVault _vault, ICLPoolManager _poolManager) {
        vault = _vault;
        poolManager = _poolManager;
    }

    struct CallbackData {
        bytes action;
        bytes rawCallbackData;
    }

    struct ModifyPositionCallbackData {
        address sender;
        PoolKey key;
        ICLPoolManager.ModifyLiquidityParams params;
        bytes hookData;
    }

    function modifyPosition(
        PoolKey memory key,
        ICLPoolManager.ModifyLiquidityParams memory params,
        bytes memory hookData
    ) external payable returns (BalanceDelta delta) {
        delta = abi.decode(
            vault.lock(
                abi.encode("modifyPosition", abi.encode(ModifyPositionCallbackData(msg.sender, key, params, hookData)))
            ),
            (BalanceDelta)
        );

        // if any ethers left
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);
        }
    }

    function modifyPositionCallback(bytes memory rawData) private returns (bytes memory) {
        ModifyPositionCallbackData memory data = abi.decode(rawData, (ModifyPositionCallbackData));

        BalanceDelta delta = poolManager.modifyLiquidity(data.key, data.params, data.hookData);

        if (delta == BalanceDeltaLibrary.MAXIMUM_DELTA) {
            // check if the hook has permission to no-op, if true, return early
            if (!data.key.parameters.shouldCall(HOOKS_NO_OP_OFFSET)) {
                revert HookMissingNoOpPermission();
            }
            return abi.encode(delta);
        }

        if (delta.amount0() > 0) {
            if (data.key.currency0.isNative()) {
                vault.settle{value: uint128(delta.amount0())}(data.key.currency0);
            } else {
                IERC20(Currency.unwrap(data.key.currency0)).transferFrom(
                    data.sender, address(vault), uint128(delta.amount0())
                );
                vault.settle(data.key.currency0);
            }
        }
        if (delta.amount1() > 0) {
            if (data.key.currency1.isNative()) {
                vault.settle{value: uint128(delta.amount1())}(data.key.currency1);
            } else {
                IERC20(Currency.unwrap(data.key.currency1)).transferFrom(
                    data.sender, address(vault), uint128(delta.amount1())
                );
                vault.settle(data.key.currency1);
            }
        }

        if (delta.amount0() < 0) {
            vault.take(data.key.currency0, data.sender, uint128(-delta.amount0()));
        }
        if (delta.amount1() < 0) {
            vault.take(data.key.currency1, data.sender, uint128(-delta.amount1()));
        }

        return abi.encode(delta);
    }

    struct SwapTestSettings {
        bool withdrawTokens;
        bool settleUsingTransfer;
    }

    struct SwapCallbackData {
        address sender;
        SwapTestSettings testSettings;
        PoolKey key;
        ICLPoolManager.SwapParams params;
        bytes hookData;
    }

    function swap(
        PoolKey memory key,
        ICLPoolManager.SwapParams memory params,
        SwapTestSettings memory testSettings,
        bytes memory hookData
    ) external payable returns (BalanceDelta delta) {
        delta = abi.decode(
            vault.lock(
                abi.encode("swap", abi.encode(SwapCallbackData(msg.sender, testSettings, key, params, hookData)))
            ),
            (BalanceDelta)
        );

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);
    }

    function swapCallback(bytes memory rawData) private returns (bytes memory) {
        SwapCallbackData memory data = abi.decode(rawData, (SwapCallbackData));

        BalanceDelta delta = poolManager.swap(data.key, data.params, data.hookData);

        if (delta == BalanceDeltaLibrary.MAXIMUM_DELTA) {
            // check if the hook has permission to no-op, if true, return early
            if (!data.key.parameters.shouldCall(HOOKS_NO_OP_OFFSET)) {
                revert HookMissingNoOpPermission();
            }
            return abi.encode(delta);
        }

        if (data.params.zeroForOne) {
            if (delta.amount0() > 0) {
                if (data.testSettings.settleUsingTransfer) {
                    if (data.key.currency0.isNative()) {
                        vault.settle{value: uint128(delta.amount0())}(data.key.currency0);
                    } else {
                        IERC20(Currency.unwrap(data.key.currency0)).transferFrom(
                            data.sender, address(vault), uint128(delta.amount0())
                        );
                        vault.settle(data.key.currency0);
                    }
                } else {
                    // the received hook on this transfer will burn the tokens
                    vault.transferFrom(data.sender, address(this), data.key.currency0, uint128(delta.amount0()));
                    vault.burn(data.key.currency0, uint128(delta.amount0()));
                }
            }
            if (delta.amount1() < 0) {
                if (data.testSettings.withdrawTokens) {
                    vault.take(data.key.currency1, data.sender, uint128(-delta.amount1()));
                } else {
                    vault.mint(data.key.currency1, data.sender, uint128(-delta.amount1()));
                }
            }
        } else {
            if (delta.amount1() > 0) {
                if (data.testSettings.settleUsingTransfer) {
                    if (data.key.currency1.isNative()) {
                        vault.settle{value: uint128(delta.amount1())}(data.key.currency1);
                    } else {
                        IERC20(Currency.unwrap(data.key.currency1)).transferFrom(
                            data.sender, address(vault), uint128(delta.amount1())
                        );
                        vault.settle(data.key.currency1);
                    }
                } else {
                    // the received hook on this transfer will burn the tokens
                    vault.transferFrom(data.sender, address(this), data.key.currency1, uint128(delta.amount1()));
                    vault.burn(data.key.currency1, uint128(delta.amount1()));
                }
            }
            if (delta.amount0() < 0) {
                if (data.testSettings.withdrawTokens) {
                    vault.take(data.key.currency0, data.sender, uint128(-delta.amount0()));
                } else {
                    vault.mint(data.key.currency0, data.sender, uint128(-delta.amount0()));
                }
            }
        }

        return abi.encode(delta);
    }

    struct DonateCallbackData {
        address sender;
        PoolKey key;
        uint256 amount0;
        uint256 amount1;
        bytes hookData;
    }

    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes memory hookData)
        external
        payable
        returns (BalanceDelta delta)
    {
        delta = abi.decode(
            vault.lock(
                abi.encode("donate", abi.encode(DonateCallbackData(msg.sender, key, amount0, amount1, hookData)))
            ),
            (BalanceDelta)
        );

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);
        }
    }

    function donateCallback(bytes memory rawData) private returns (bytes memory) {
        DonateCallbackData memory data = abi.decode(rawData, (DonateCallbackData));

        BalanceDelta delta = poolManager.donate(data.key, data.amount0, data.amount1, data.hookData);

        if (delta == BalanceDeltaLibrary.MAXIMUM_DELTA) {
            // check if the hook has permission to no-op, if true, return early
            if (!data.key.parameters.shouldCall(HOOKS_NO_OP_OFFSET)) {
                revert HookMissingNoOpPermission();
            }
            return abi.encode(delta);
        }

        if (delta.amount0() > 0) {
            if (data.key.currency0.isNative()) {
                vault.settle{value: uint128(delta.amount0())}(data.key.currency0);
            } else {
                IERC20(Currency.unwrap(data.key.currency0)).transferFrom(
                    data.sender, address(vault), uint128(delta.amount0())
                );
                vault.settle(data.key.currency0);
            }
        }
        if (delta.amount1() > 0) {
            if (data.key.currency1.isNative()) {
                vault.settle{value: uint128(delta.amount1())}(data.key.currency1);
            } else {
                IERC20(Currency.unwrap(data.key.currency1)).transferFrom(
                    data.sender, address(vault), uint128(delta.amount1())
                );
                vault.settle(data.key.currency1);
            }
        }

        return abi.encode(delta);
    }

    struct TakeCallbackData {
        address sender;
        PoolKey key;
        uint256 amount0;
        uint256 amount1;
    }

    function take(PoolKey memory key, uint256 amount0, uint256 amount1) external payable {
        vault.lock(abi.encode("take", abi.encode(TakeCallbackData(msg.sender, key, amount0, amount1))));
    }

    function takeCallback(bytes memory rawData) private returns (bytes memory) {
        TakeCallbackData memory data = abi.decode(rawData, (TakeCallbackData));

        if (data.amount0 > 0) {
            uint256 balBefore = data.key.currency0.balanceOf(data.sender);
            vault.take(data.key.currency0, data.sender, data.amount0);
            uint256 balAfter = data.key.currency0.balanceOf(data.sender);
            require(balAfter - balBefore == data.amount0);

            if (data.key.currency0.isNative()) {
                vault.settle{value: uint256(data.amount0)}(data.key.currency0);
            } else {
                IERC20(Currency.unwrap(data.key.currency0)).transferFrom(
                    data.sender, address(vault), uint256(data.amount0)
                );
                vault.settle(data.key.currency0);
            }
        }

        if (data.amount1 > 0) {
            uint256 balBefore = data.key.currency1.balanceOf(data.sender);
            vault.take(data.key.currency1, data.sender, data.amount1);
            uint256 balAfter = data.key.currency1.balanceOf(data.sender);
            require(balAfter - balBefore == data.amount1);

            if (data.key.currency1.isNative()) {
                vault.settle{value: uint256(data.amount1)}(data.key.currency1);
            } else {
                IERC20(Currency.unwrap(data.key.currency1)).transferFrom(
                    data.sender, address(vault), uint256(data.amount1)
                );
                vault.settle(data.key.currency1);
            }
        }

        return abi.encode(0);
    }

    function lockAcquired(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(vault));

        (bytes memory action, bytes memory rawCallbackData) = abi.decode(data, (bytes, bytes));
        if (keccak256(action) == keccak256("modifyPosition")) {
            return modifyPositionCallback(rawCallbackData);
        } else if (keccak256(action) == keccak256("swap")) {
            return swapCallback(rawCallbackData);
        } else if (keccak256(action) == keccak256("donate")) {
            return donateCallback(rawCallbackData);
        } else if (keccak256(action) == keccak256("take")) {
            return takeCallback(rawCallbackData);
        } else {
            revert InvalidAction();
        }
    }
}
