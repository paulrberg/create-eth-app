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
import {SafeCast} from "../libraries/SafeCast.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {CurrencySettleTake} from "../libraries/CurrencySettleTake.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta, toBalanceDelta} from "../types/BalanceDelta.sol";
import {Currency} from "../types/Currency.sol";
import {BaseTestHooks} from "./BaseTestHooks.sol";
import {IERC20Minimal} from "../interfaces/external/IERC20Minimal.sol";
import {CurrencyLibrary, Currency} from "../types/Currency.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "../types/BeforeSwapDelta.sol";

contract DeltaReturningHook is BaseTestHooks {
    using Hooks for IHooks;
    using CurrencyLibrary for Currency;
    using CurrencySettleTake for Currency;

    IPoolManager immutable manager;

    int128 deltaSpecified;
    int128 deltaUnspecifiedBeforeSwap;
    int128 deltaUnspecifiedAfterSwap;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(manager));
        _;
    }

    function setDeltaSpecified(int128 delta) external {
        deltaSpecified = delta;
    }

    function setDeltaUnspecifiedBeforeSwap(int128 delta) external {
        deltaUnspecifiedBeforeSwap = delta;
    }

    function setDeltaUnspecifiedAfterSwap(int128 delta) external {
        deltaUnspecifiedAfterSwap = delta;
    }

    function beforeSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        (Currency specifiedCurrency, Currency unspecifiedCurrency) = _sortCurrencies(key, params);

        if (deltaSpecified != 0) _settleOrTake(specifiedCurrency, deltaSpecified);
        if (deltaUnspecifiedBeforeSwap != 0) _settleOrTake(unspecifiedCurrency, deltaUnspecifiedBeforeSwap);

        BeforeSwapDelta beforeSwapDelta = toBeforeSwapDelta(deltaSpecified, deltaUnspecifiedBeforeSwap);

        return (IHooks.beforeSwap.selector, beforeSwapDelta, 0);
    }

    function afterSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta, /* delta **/
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, int128) {
        (, Currency unspecifiedCurrency) = _sortCurrencies(key, params);
        _settleOrTake(unspecifiedCurrency, deltaUnspecifiedAfterSwap);

        return (IHooks.afterSwap.selector, deltaUnspecifiedAfterSwap);
    }

    function _sortCurrencies(PoolKey calldata key, IPoolManager.SwapParams calldata params)
        internal
        pure
        returns (Currency specified, Currency unspecified)
    {
        (specified, unspecified) = (params.zeroForOne == (params.amountSpecified < 0))
            ? (key.currency0, key.currency1)
            : (key.currency1, key.currency0);
    }

    function _settleOrTake(Currency currency, int128 delta) internal {
        // positive amount means positive delta for the hook, so it can take
        // negative it should settle
        if (delta > 0) {
            currency.take(manager, address(this), uint128(delta), false);
        } else {
            uint256 amount = uint256(-int256(delta));
            if (currency.isNative()) {
                manager.settle{value: amount}(currency);
            } else {
                currency.settle(manager, address(this), amount, false);
            }
        }
    }
}
