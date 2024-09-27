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
import {Hooks} from "../../../src/libraries/Hooks.sol";
import {IHooks} from "../../../src/interfaces/IHooks.sol";
import {IPoolManager} from "../../../src/interfaces/IPoolManager.sol";
import {Currency} from "../../../src/types/Currency.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {HooksContract} from "./HooksContract.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";

contract HooksTest is Test {
    /// @dev trick to convert poolKey to calldata
    function toCallAsCalldata(PoolKey calldata poolKey) external view {
        Hooks.validateHookConfig(poolKey);
    }

    function testFuzzValidateHookConfig(uint16 bitmap, bytes32 parameters) public {
        IHooks hooksContract = new HooksContract(bitmap);

        // 1. same bitmap
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0)),
            hooks: hooksContract,
            poolManager: IPoolManager(address(0)),
            fee: 0,
            parameters: bytes32(uint256(bitmap))
        });
        this.toCallAsCalldata(poolKey);

        // 2. bitmap mismatch
        PoolKey memory poolKey2 = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0)),
            hooks: hooksContract,
            poolManager: IPoolManager(address(0)),
            fee: 0,
            parameters: parameters
        });
        if (uint16(uint256(parameters)) != bitmap) {
            vm.expectRevert(Hooks.HookConfigValidationError.selector);
        }
        this.toCallAsCalldata(poolKey2);
    }

    function testFuzzValidateHookConfig_noHook(bytes32 parameters, uint24 fee) public {
        if (uint256(parameters) % 2 == 0) {
            parameters = bytes32(0);
        }

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0)),
            hooks: IHooks(address(0)),
            poolManager: IPoolManager(address(0)),
            fee: fee,
            parameters: parameters
        });

        uint16 bitmap;
        assembly {
            bitmap := and(parameters, 0xFFFF)
        }

        if (bitmap != 0 || FeeLibrary.isDynamicFee(fee)) {
            vm.expectRevert(Hooks.HookConfigValidationError.selector);
        }

        this.toCallAsCalldata(poolKey);
    }

    function testShouldCall() public {
        // 0b1010101010101010
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 0), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 1), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 2), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 3), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 4), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 5), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 6), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 7), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 8), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 9), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 10), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 11), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 12), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 13), true);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 14), false);
        assertEq(Hooks.shouldCall(bytes32(uint256(0xaaaa)), 15), true);
    }

    function testIsValidNoOpCall(bytes32 parameters, uint8 noOpOffset, bytes4 selector) public {
        // make sure enough true cases are covered
        noOpOffset = uint8(bound(noOpOffset, 0, 15));
        if (uint32(selector) > type(uint32).max / 2) {
            selector = Hooks.NO_OP_SELECTOR;
        }

        bool expectRet;
        assembly {
            expectRet := and(shr(noOpOffset, parameters), 1)
        }
        expectRet = expectRet && selector == Hooks.NO_OP_SELECTOR;

        bool actualRet = Hooks.isValidNoOpCall(parameters, noOpOffset, selector);
        assertEq(expectRet, actualRet);
    }
}
