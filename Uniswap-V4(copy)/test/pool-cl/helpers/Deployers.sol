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

import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {Hooks} from "../../../src/libraries/Hooks.sol";
import {Currency} from "../../../src/types/Currency.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {ICLPoolManager} from "../../../src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLPoolManager} from "../../../src/pool-cl/CLPoolManager.sol";
import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {Constants} from "./Constants.sol";
import {SortTokens} from "../../helpers/SortTokens.sol";
import {Vault} from "../../../src/Vault.sol";
import {IVault} from "../../../src/interfaces/IVault.sol";

contract Deployers {
    using FeeLibrary for uint24;
    using PoolIdLibrary for PoolKey;

    bytes constant ZERO_BYTES = new bytes(0);

    uint160 constant SQRT_RATIO_1_1 = Constants.SQRT_RATIO_1_1;
    uint160 constant SQRT_RATIO_1_2 = Constants.SQRT_RATIO_1_2;
    uint160 constant SQRT_RATIO_1_4 = Constants.SQRT_RATIO_1_4;
    uint160 constant SQRT_RATIO_4_1 = Constants.SQRT_RATIO_4_1;

    function deployCurrencies(uint256 totalSupply) internal returns (Currency currency0, Currency currency1) {
        MockERC20[] memory tokens = deployTokens(2, totalSupply);
        return SortTokens.sort(tokens[0], tokens[1]);
    }

    function deployTokens(uint8 count, uint256 totalSupply) internal returns (MockERC20[] memory tokens) {
        tokens = new MockERC20[](count);
        for (uint8 i = 0; i < count; i++) {
            tokens[i] = new MockERC20("TEST", "TEST", 18);
            tokens[i].mint(address(this), totalSupply);
        }
    }

    function createPool(ICLPoolManager manager, IHooks hooks, uint24 fee, uint160 sqrtPriceX96)
        private
        returns (PoolKey memory key, PoolId id)
    {
        (key, id) = createPool(manager, hooks, fee, sqrtPriceX96, ZERO_BYTES);
    }

    function createPool(ICLPoolManager manager, IHooks hooks, uint24 fee, uint160 sqrtPriceX96, bytes memory initData)
        private
        returns (PoolKey memory key, PoolId id)
    {
        MockERC20[] memory tokens = deployTokens(2, 2 ** 255);
        (Currency currency0, Currency currency1) = SortTokens.sort(tokens[0], tokens[1]);
        key = PoolKey(
            currency0,
            currency1,
            hooks,
            manager,
            fee,
            fee.isDynamicFee()
                ? bytes32(uint256((60 << 16) | 0x00ff))
                : bytes32(uint256(((fee / 100 * 2) << 16) | 0x00ff))
        );
        id = key.toId();
        manager.initialize(key, sqrtPriceX96, initData);
    }

    function createFreshPool(IHooks hooks, uint24 fee, uint160 sqrtPriceX96)
        internal
        returns (IVault vault, ICLPoolManager manager, PoolKey memory key, PoolId id)
    {
        (vault, manager, key, id) = createFreshPool(hooks, fee, sqrtPriceX96, ZERO_BYTES);
    }

    function createFreshPool(IHooks hooks, uint24 fee, uint160 sqrtPriceX96, bytes memory initData)
        internal
        returns (IVault vault, ICLPoolManager manager, PoolKey memory key, PoolId id)
    {
        (vault, manager) = createFreshManager();
        (key, id) = createPool(manager, hooks, fee, sqrtPriceX96, initData);
        return (vault, manager, key, id);
    }

    function createFreshManager() internal returns (Vault vault, CLPoolManager manager) {
        vault = new Vault();
        manager = new CLPoolManager(vault, 500000);
        vault.registerPoolManager(address(manager));
    }
}
