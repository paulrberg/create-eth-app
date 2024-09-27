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

import "Uniswap-V4/forge-std/Test.sol";
import {FakePoolManager} from "./FakePoolManager.sol";
import {IVault} from "../../src/interfaces/IVault.sol";
import {PoolKey} from "../../src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "../../src/types/Currency.sol";
import {IPoolManager} from "../../src/interfaces/IPoolManager.sol";
import {toBalanceDelta} from "../../src/types/BalanceDelta.sol";

contract FakePoolManagerRouter {
    using CurrencyLibrary for Currency;

    event LockAcquired();

    IVault vault;
    PoolKey poolKey;
    FakePoolManager poolManager;
    Forwarder forwarder;

    constructor(IVault _vault, PoolKey memory _poolKey) {
        vault = _vault;
        poolKey = _poolKey;
        poolManager = FakePoolManager(address(_poolKey.poolManager));
        forwarder = new Forwarder();
    }

    function lockAcquired(bytes calldata data) external returns (bytes memory) {
        emit LockAcquired();

        if (data[0] == 0x01) {
            poolManager.mockAccounting(poolKey, 10 ether, 10 ether);
        } else if (data[0] == 0x02) {
            poolManager.mockAccounting(poolKey, 10 ether, 10 ether);
            vault.settle(poolKey.currency0);
            vault.settle(poolKey.currency1);
        } else if (data[0] == 0x03) {
            poolManager.mockAccounting(poolKey, 3 ether, -3 ether);
            vault.settle(poolKey.currency0);
            vault.take(poolKey.currency1, address(this), 3 ether);
        } else if (data[0] == 0x04) {
            poolManager.mockAccounting(poolKey, 15 ether, -15 ether);
            vault.settle(poolKey.currency0);
            vault.take(poolKey.currency1, address(this), 15 ether);
        } else if (data[0] == 0x05) {
            vault.take(poolKey.currency0, address(this), 20 ether);
            vault.take(poolKey.currency1, address(this), 20 ether);

            // ... flashloan logic

            poolKey.currency0.transfer(address(vault), 20 ether);
            poolKey.currency1.transfer(address(vault), 20 ether);
            vault.settle(poolKey.currency0);
            vault.settle(poolKey.currency1);
        } else if (data[0] == 0x06) {
            // poolKey.poolManager was hacked hence not equal to msg.sender
            PoolKey memory maliciousPoolKey = poolKey;
            maliciousPoolKey.poolManager = IPoolManager(address(0));
            poolManager.mockAccounting(maliciousPoolKey, 3 ether, -3 ether);
        } else if (data[0] == 0x07) {
            // generate nested lock call
            vault.take(poolKey.currency0, address(this), 5 ether);
            vault.take(poolKey.currency1, address(this), 5 ether);

            forwarder.forward(vault);
        } else if (data[0] == 0x08) {
            // settle generated balance delta by 0x07
            poolKey.currency0.transfer(address(vault), 5 ether);
            poolKey.currency1.transfer(address(vault), 5 ether);
            vault.settle(poolKey.currency0);
            vault.settle(poolKey.currency1);
        } else if (data[0] == 0x09) {
            vault.take(poolKey.currency1, address(this), 5 ether);
        } else if (data[0] == 0x10) {
            // call accountPoolBalanceDelta from arbitrary addr
            vault.accountPoolBalanceDelta(poolKey, toBalanceDelta(int128(1), int128(0)), address(0));
        } else if (data[0] == 0x11) {
            // settleFor
            Payer payer = new Payer();
            payer.settleFor(vault, poolKey, 5 ether);

            poolKey.currency0.transfer(address(vault), 5 ether);
            payer.settle(vault, poolKey);

            vault.take(poolKey.currency0, address(this), 5 ether);
        } else if (data[0] == 0x12) {
            // settleFor(, , 0)
            Payer payer = new Payer();

            uint256 amt = poolKey.currency0.balanceOfSelf();
            poolKey.currency0.transfer(address(vault), amt);
            payer.settle(vault, poolKey);

            vault.take(poolKey.currency0, address(this), amt);

            payer.settleFor(vault, poolKey, 0);
        } else if (data[0] == 0x13) {
            // mint
            uint256 amt = poolKey.currency0.balanceOf(address(vault));
            vault.settle(poolKey.currency0);
            vault.mint(poolKey.currency0, address(this), amt);
        } else if (data[0] == 0x14) {
            // mint to someone else, poolKey.currency1 for example
            uint256 amt = poolKey.currency0.balanceOf(address(vault));
            vault.settle(poolKey.currency0);
            vault.mint(poolKey.currency0, Currency.unwrap(poolKey.currency1), amt);
        } else if (data[0] == 0x15) {
            // burn

            uint256 amt = poolKey.currency0.balanceOf(address(vault));
            vault.settle(poolKey.currency0);
            vault.mint(poolKey.currency0, address(this), amt);

            vault.burn(poolKey.currency0, amt);
            vault.take(poolKey.currency0, address(this), amt);
        } else if (data[0] == 0x16) {
            // burn half if possible

            uint256 amt = poolKey.currency0.balanceOf(address(vault));
            vault.settle(poolKey.currency0);

            vault.mint(poolKey.currency0, address(this), amt);

            vault.burn(poolKey.currency0, amt / 2);
            vault.take(poolKey.currency0, address(this), amt / 2);
        } else if (data[0] == 0x17) {
            // settle ETH
            vault.settle{value: 5 ether}(CurrencyLibrary.NATIVE);
            vault.take(CurrencyLibrary.NATIVE, address(this), 5 ether);
        } else if (data[0] == 0x18) {
            // call this method via vault.lock(abi.encodePacked(hex"18", alice));
            address to = address(uint160(uint256(bytes32(data[1:0x15]) >> 96)));
            vault.settleAndMintRefund(poolKey.currency0, to);
            vault.settleAndMintRefund(poolKey.currency1, to);
        } else if (data[0] == 0x19) {
            poolManager.mockAccounting(poolKey, 3 ether, -3 ether);
            vault.settle(poolKey.currency0);

            /// try to call settleAndMintRefund should not revert
            vault.settleAndMintRefund(poolKey.currency1, address(this));
            vault.take(poolKey.currency1, address(this), 3 ether);
        }

        return "";
    }

    function callback() external {
        vault.lock(hex"08");
    }

    receive() external payable {}
}

contract Forwarder {
    function forward(IVault vault) external {
        vault.lock(abi.encode(msg.sender));
    }

    function lockAcquired(bytes calldata data) external returns (bytes memory) {
        address lastLocker = abi.decode(data, (address));
        FakePoolManagerRouter(payable(lastLocker)).callback();
        return "";
    }
}

contract Payer {
    function settleFor(IVault vault, PoolKey calldata poolKey, uint256 amt) public {
        vault.settleFor(poolKey.currency0, msg.sender, amt);
    }

    function settle(IVault vault, PoolKey calldata poolKey) public {
        vault.settle(poolKey.currency0);
    }
}
