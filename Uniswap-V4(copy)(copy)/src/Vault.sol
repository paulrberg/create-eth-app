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
  
  // SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.24;

import {Ownable} from "Uniswap-V4/@openzeppelin/contracts/access/Ownable.sol";
import {IVault, IVaultToken} from "./interfaces/IVault.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {PoolId, PoolIdLibrary} from "./types/PoolId.sol";
import {PoolKey} from "./types/PoolKey.sol";
import {SettlementGuard} from "./libraries/SettlementGuard.sol";
import {Currency, CurrencyLibrary} from "./types/Currency.sol";
import {BalanceDelta} from "./types/BalanceDelta.sol";
import {ILockCallback} from "./interfaces/ILockCallback.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {VaultToken} from "./VaultToken.sol";

contract Vault is IVault, VaultToken, Ownable {
    using SafeCast for *;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    mapping(address => bool) public override isPoolManagerRegistered;

    /// @dev keep track of the reserves of the whole vault
    mapping(Currency currency => uint256) public override reservesOfVault;

    /// @dev keep track of each pool manager's reserves
    mapping(IPoolManager poolManager => mapping(Currency currency => uint256 reserve)) public reservesOfPoolManager;

    /// @notice only poolManager is allowed to call swap or modifyLiquidity, donate
    /// @param poolManager The address specified in PoolKey
    modifier onlyPoolManager(address poolManager) {
        /// @dev Make sure:
        /// 1. the pool manager specified in PoolKey is the caller
        /// 2. the pool manager has been registered
        if (poolManager != msg.sender) revert NotFromPoolManager();

        if (!isPoolManagerRegistered[msg.sender]) revert PoolManagerUnregistered();

        _;
    }

    /// @notice revert if no locker is set
    modifier isLocked() {
        if (SettlementGuard.getLocker() == address(0)) revert NoLocker();
        _;
    }

    /// @notice receive native tokens for native pools
    receive() external payable {}

    /// @inheritdoc IVault
    function registerPoolManager(address poolManager) external override onlyOwner {
        isPoolManagerRegistered[poolManager] = true;

        emit PoolManagerRegistered(poolManager);
    }

    /// @inheritdoc IVault
    function getLocker() external view override returns (address) {
        return SettlementGuard.getLocker();
    }

    /// @inheritdoc IVault
    function getUnsettledDeltasCount() external view override returns (uint256) {
        return SettlementGuard.getUnsettledDeltasCount();
    }

    /// @inheritdoc IVault
    function currencyDelta(address settler, Currency currency) external view override returns (int256) {
        return SettlementGuard.getCurrencyDelta(settler, currency);
    }

    /// @dev interaction must start from lock
    /// @inheritdoc IVault
    function lock(bytes calldata data) external override returns (bytes memory result) {
        /// @dev only one locker at a time
        SettlementGuard.setLocker(msg.sender);

        result = ILockCallback(msg.sender).lockAcquired(data);
        /// @notice the caller can do anything in this callback as long as all deltas are offset after this
        if (SettlementGuard.getUnsettledDeltasCount() != 0) revert CurrencyNotSettled();

        /// @dev release the lock
        SettlementGuard.setLocker(address(0));
    }

    /// @inheritdoc IVault
    function accountPoolBalanceDelta(PoolKey memory key, BalanceDelta delta, address settler)
        external
        override
        isLocked
        onlyPoolManager(address(key.poolManager))
    {
        int128 delta0 = delta.amount0();
        int128 delta1 = delta.amount1();

        // keep track on each pool manager
        _accountDeltaOfPoolManager(key.poolManager, key.currency0, delta0);
        _accountDeltaOfPoolManager(key.poolManager, key.currency1, delta1);

        // keep track of the balance for the whole vault
        SettlementGuard.accountDelta(settler, key.currency0, delta0);
        SettlementGuard.accountDelta(settler, key.currency1, delta1);
    }

    /// @inheritdoc IVault
    function take(Currency currency, address to, uint256 amount) external override isLocked {
        SettlementGuard.accountDelta(msg.sender, currency, amount.toInt128());
        reservesOfVault[currency] -= amount;
        currency.transfer(to, amount);
    }

    /// @inheritdoc IVault
    function mint(Currency currency, address to, uint256 amount) external override isLocked {
        SettlementGuard.accountDelta(msg.sender, currency, amount.toInt128());
        _mint(to, currency, amount);
    }

    /// @inheritdoc IVault
    function settle(Currency currency) external payable override isLocked returns (uint256 paid) {
        uint256 reservesBefore = reservesOfVault[currency];
        reservesOfVault[currency] = currency.balanceOfSelf();
        paid = reservesOfVault[currency] - reservesBefore;
        // subtraction must be safe
        SettlementGuard.accountDelta(msg.sender, currency, -(paid.toInt128()));
    }

    function settleAndMintRefund(Currency currency, address to)
        external
        payable
        override
        isLocked
        returns (uint256 paid, uint256 refund)
    {
        uint256 reservesBefore = reservesOfVault[currency];
        reservesOfVault[currency] = currency.balanceOfSelf();
        paid = reservesOfVault[currency] - reservesBefore;

        int256 currentDelta = SettlementGuard.getCurrencyDelta(msg.sender, currency);
        if (currentDelta >= 0) {
            uint256 currentDeltaUint256 = currentDelta.toUint256();
            if (paid > currentDeltaUint256) {
                // msg.sender owes vault but paid more than than whats owed
                refund = paid - currentDeltaUint256;
                paid = currentDeltaUint256;
            }
        }

        SettlementGuard.accountDelta(msg.sender, currency, -(paid.toInt128()));
        if (refund > 0) _mint(to, currency, refund);
    }

    /// @inheritdoc IVault
    function settleFor(Currency currency, address target, uint256 amount) external isLocked {
        /// @notice settle all outstanding debt if amount is 0
        /// It will revert if target has negative delta
        if (amount == 0) amount = SettlementGuard.getCurrencyDelta(target, currency).toUint256();
        SettlementGuard.accountDelta(msg.sender, currency, amount.toInt128());
        SettlementGuard.accountDelta(target, currency, -(amount.toInt128()));
    }

    /// @inheritdoc IVault
    function burn(Currency currency, uint256 amount) external override isLocked {
        SettlementGuard.accountDelta(msg.sender, currency, -(amount.toInt128()));
        _burn(msg.sender, currency, amount);
    }

    /// @inheritdoc IVault
    function collectFee(Currency currency, uint256 amount, address recipient) external {
        reservesOfPoolManager[IPoolManager(msg.sender)][currency] -= amount;
        reservesOfVault[currency] -= amount;

        currency.transfer(recipient, amount);
    }

    function _accountDeltaOfPoolManager(IPoolManager poolManager, Currency currency, int128 delta) internal {
        if (delta == 0) return;

        if (delta >= 0) {
            reservesOfPoolManager[poolManager][currency] += uint128(delta);
        } else {
            /// @dev arithmetic underflow is possible in following two cases:
            /// 1. delta == type(int128).min
            /// This occurs when withdrawing amount is too large
            /// 2. reservesOfPoolManager[poolManager][currency] < delta0
            /// This occurs when insufficient balance in pool
            reservesOfPoolManager[poolManager][currency] -= uint128(-delta);
        }
    }
}
