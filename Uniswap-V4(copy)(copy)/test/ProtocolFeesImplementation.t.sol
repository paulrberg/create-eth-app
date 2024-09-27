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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {MockERC20} from "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import {CurrencyLibrary, Currency} from "../src/types/Currency.sol";
import {ProtocolFeesImplementation} from "../src/test/ProtocolFeesImplementation.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {IProtocolFees} from "../src/interfaces/IProtocolFees.sol";
import {ProtocolFeeLibrary} from "../src/libraries/ProtocolFeeLibrary.sol";
import {PoolKey} from "../src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "../src/types/Currency.sol";
import {Deployers} from "../test/utils/Deployers.sol";
import {PoolId, PoolIdLibrary} from "../src/types/PoolId.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";
import {Constants} from "../test/utils/Constants.sol";
import {
    ProtocolFeeControllerTest,
    OutOfBoundsProtocolFeeControllerTest,
    RevertingProtocolFeeControllerTest,
    OverflowProtocolFeeControllerTest,
    InvalidReturnSizeProtocolFeeControllerTest
} from "../src/test/ProtocolFeeControllerTest.sol";

contract ProtocolFeesTest is Test, GasSnapshot, Deployers {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;
    using ProtocolFeeLibrary for uint24;

    event ProtocolFeeControllerUpdated(address feeController);
    event ProtocolFeeUpdated(PoolId indexed id, uint24 protocolFee);

    uint24 constant MAX_PROTOCOL_FEE_BOTH_TOKENS = (1000 << 12) | 1000; // 1000 1000

    ProtocolFeesImplementation protocolFees;

    function setUp() public {
        protocolFees = new ProtocolFeesImplementation(5000);
        feeController = new ProtocolFeeControllerTest();
        (currency0, currency1) = deployAndMint2Currencies();
        MockERC20(Currency.unwrap(currency0)).transfer(address(protocolFees), 2 ** 255);
    }

    function test_setProtocolFeeController_succeedsNoRevert() public {
        assertEq(address(protocolFees.protocolFeeController()), address(0));
        vm.expectEmit(false, false, false, true, address(protocolFees));
        emit ProtocolFeeControllerUpdated(address(feeController));
        protocolFees.setProtocolFeeController(feeController);
        assertEq(address(protocolFees.protocolFeeController()), address(feeController));
    }

    function test_setProtocolFeeController_revertsWithNotAuthorized() public {
        assertEq(address(protocolFees.protocolFeeController()), address(0));

        vm.prank(address(1)); // not the owner address
        vm.expectRevert("UNAUTHORIZED");
        protocolFees.setProtocolFeeController(feeController);
        assertEq(address(protocolFees.protocolFeeController()), address(0));
    }

    function test_setProtocolFee_succeeds_gas() public {
        PoolKey memory key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(0)));
        protocolFees.setProtocolFeeController(feeController);
        // Set price to pretend that the pool is initialized
        protocolFees.setPrice(key, Constants.SQRT_PRICE_1_1);
        vm.prank(address(feeController));
        vm.expectEmit(true, false, false, true, address(protocolFees));
        emit ProtocolFeeUpdated(key.toId(), MAX_PROTOCOL_FEE_BOTH_TOKENS);
        protocolFees.setProtocolFee(key, MAX_PROTOCOL_FEE_BOTH_TOKENS);
        snapLastCall("set protocol fee");
    }

    function test_setProtocolFee_revertsWithInvalidCaller() public {
        protocolFees.setProtocolFeeController(feeController);
        vm.expectRevert(IProtocolFees.InvalidCaller.selector);
        protocolFees.setProtocolFee(key, 1);
    }

    function test_setProtocolFee_revertsWithInvalidFee() public {
        protocolFees.setProtocolFeeController(feeController);
        vm.prank(address(feeController));
        vm.expectRevert(IProtocolFees.InvalidProtocolFee.selector);
        protocolFees.setProtocolFee(key, MAX_PROTOCOL_FEE_BOTH_TOKENS + 1);

        vm.prank(address(feeController));
        vm.expectRevert(IProtocolFees.InvalidProtocolFee.selector);
        protocolFees.setProtocolFee(key, MAX_PROTOCOL_FEE_BOTH_TOKENS + (1 << 12));
    }

    function test_fuzz_setProtocolFee(PoolKey memory key, uint24 protocolFee) public {
        protocolFees.setProtocolFeeController(feeController);
        // Set price to pretend that the pool is initialized
        protocolFees.setPrice(key, Constants.SQRT_PRICE_1_1);
        uint16 fee0 = protocolFee.getZeroForOneFee();
        uint16 fee1 = protocolFee.getOneForZeroFee();
        vm.prank(address(feeController));
        if ((fee0 > 1000) || (fee1 > 1000)) {
            vm.expectRevert(IProtocolFees.InvalidProtocolFee.selector);
            protocolFees.setProtocolFee(key, protocolFee);
        } else {
            vm.expectEmit(true, false, false, true, address(protocolFees));
            emit IProtocolFees.ProtocolFeeUpdated(key.toId(), protocolFee);
            protocolFees.setProtocolFee(key, protocolFee);
        }
    }

    function test_collectProtocolFees_revertsWithInvalidCaller() public {
        vm.expectRevert(IProtocolFees.InvalidCaller.selector);
        protocolFees.collectProtocolFees(address(1), currency0, 0);
    }

    function test_collectProtocolFees_succeeds() public {
        // set a balance of protocol fees that can be collected
        protocolFees.updateProtocolFees(currency0, 100);
        assertEq(protocolFees.protocolFeesAccrued(currency0), 100);

        protocolFees.setProtocolFeeController(feeController);
        vm.prank(address(feeController));
        protocolFees.collectProtocolFees(address(this), currency0, 100);
        assertEq(protocolFees.protocolFeesAccrued(currency0), 0);
        assertEq(currency0.balanceOf(address(this)), 100);
    }

    function test_fuzz_collectProtocolFees(address recipient, uint256 amount, uint256 feesAccrued) public {
        vm.assume(feesAccrued <= currency0.balanceOf(address(protocolFees)));
        vm.assume(amount <= feesAccrued);
        vm.assume(recipient != address(protocolFees));

        uint256 recipientBalanceBefore = currency0.balanceOf(recipient);
        uint256 senderBalanceBefore = currency0.balanceOf(address(protocolFees));

        // set a balance of protocol fees that can be collected
        protocolFees.updateProtocolFees(currency0, feesAccrued);
        assertEq(protocolFees.protocolFeesAccrued(currency0), feesAccrued);
        if (amount == 0) {
            amount = protocolFees.protocolFeesAccrued(currency0);
        }

        protocolFees.setProtocolFeeController(feeController);
        vm.prank(address(feeController));
        uint256 amountCollected = protocolFees.collectProtocolFees(recipient, currency0, amount);

        assertEq(protocolFees.protocolFeesAccrued(currency0), feesAccrued - amount);
        assertEq(currency0.balanceOf(recipient), recipientBalanceBefore + amount);
        assertEq(currency0.balanceOf(address(protocolFees)), senderBalanceBefore - amount);
        assertEq(amountCollected, amount);
    }

    function test_updateProtocolFees_succeeds() public {
        // set a starting balance of protocol fees
        protocolFees.updateProtocolFees(currency0, 100);
        assertEq(protocolFees.protocolFeesAccrued(currency0), 100);

        protocolFees.updateProtocolFees(currency0, 200);
        assertEq(protocolFees.protocolFeesAccrued(currency0), 300);
    }

    function test_fuzz_updateProtocolFees(uint256 amount, uint256 startingAmount) public {
        // set a starting balance of protocol fees
        protocolFees.updateProtocolFees(currency0, startingAmount);
        assertEq(protocolFees.protocolFeesAccrued(currency0), startingAmount);

        uint256 newAmount;
        unchecked {
            newAmount = startingAmount + amount;
        }

        protocolFees.updateProtocolFees(currency0, amount);
        assertEq(protocolFees.protocolFeesAccrued(currency0), newAmount);
    }

    function test_fetchProtocolFee_succeeds() public {
        protocolFees.setProtocolFeeController(feeController);
        vm.prank(address(feeController));
        (bool success, uint24 protocolFee) = protocolFees.fetchProtocolFee(key);
        assertTrue(success);
        assertEq(protocolFee, 0);
    }

    function test_fetchProtocolFee_outOfBounds() public {
        outOfBoundsFeeController = new OutOfBoundsProtocolFeeControllerTest();
        protocolFees.setProtocolFeeController(outOfBoundsFeeController);
        vm.prank(address(outOfBoundsFeeController));
        (bool success, uint24 protocolFee) = protocolFees.fetchProtocolFee(key);
        assertFalse(success);
        assertEq(protocolFee, 0);
    }

    function test_fetchProtocolFee_overflowFee() public {
        overflowFeeController = new OverflowProtocolFeeControllerTest();
        protocolFees.setProtocolFeeController(overflowFeeController);
        vm.prank(address(overflowFeeController));
        (bool success, uint24 protocolFee) = protocolFees.fetchProtocolFee(key);
        assertFalse(success);
        assertEq(protocolFee, 0);
    }

    function test_fetchProtocolFee_invalidReturnSize() public {
        invalidReturnSizeFeeController = new InvalidReturnSizeProtocolFeeControllerTest();
        protocolFees.setProtocolFeeController(invalidReturnSizeFeeController);
        vm.prank(address(invalidReturnSizeFeeController));
        (bool success, uint24 protocolFee) = protocolFees.fetchProtocolFee(key);
        assertFalse(success);
        assertEq(protocolFee, 0);
    }

    function test_fetchProtocolFee_revert() public {
        revertingFeeController = new RevertingProtocolFeeControllerTest();
        protocolFees.setProtocolFeeController(revertingFeeController);
        vm.prank(address(revertingFeeController));
        (bool success, uint24 protocolFee) = protocolFees.fetchProtocolFee(key);
        assertFalse(success);
        assertEq(protocolFee, 0);
    }
}
