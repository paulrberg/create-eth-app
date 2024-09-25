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
import "Uniswap-V4/solmate/test/utils/mocks/MockERC20.sol";
import "../src/test/MockFeePoolManager.sol";
import "../src/test/fee/MockFeeManagerHook.sol";
import {
    MockProtocolFeeController,
    RevertingMockProtocolFeeController,
    OutOfBoundsMockProtocolFeeController,
    OverflowMockProtocolFeeController,
    InvalidReturnSizeMockProtocolFeeController
} from "../src/test/fee/MockProtocolFeeController.sol";
import "../src/test/MockVault.sol";
import "../src/Fees.sol";
import "../src/interfaces/IFees.sol";
import "../src/interfaces/IVault.sol";
import "../src/interfaces/IPoolManager.sol";
import "../src/interfaces/IHooks.sol";
import "../src/libraries/FeeLibrary.sol";

contract FeesTest is Test {
    MockFeePoolManager poolManager;
    MockProtocolFeeController feeController;
    RevertingMockProtocolFeeController revertingFeeController;
    OutOfBoundsMockProtocolFeeController outOfBoundsFeeController;
    OverflowMockProtocolFeeController overflowFeeController;
    InvalidReturnSizeMockProtocolFeeController invalidReturnSizeFeeController;
    MockFeeManagerHook mockFeeManagerHook;

    MockVault vault;
    PoolKey key;

    address alice = makeAddr("alice");
    MockERC20 token0;
    MockERC20 token1;

    event ProtocolFeeControllerUpdated(address protocolFeeController);

    function setUp() public {
        vault = new MockVault();
        poolManager = new MockFeePoolManager(IVault(address(vault)), 500_000);
        feeController = new MockProtocolFeeController();
        revertingFeeController = new RevertingMockProtocolFeeController();
        outOfBoundsFeeController = new OutOfBoundsMockProtocolFeeController();
        overflowFeeController = new OverflowMockProtocolFeeController();
        invalidReturnSizeFeeController = new InvalidReturnSizeMockProtocolFeeController();
        mockFeeManagerHook = new MockFeeManagerHook();

        token0 = new MockERC20("TestA", "A", 18);
        token1 = new MockERC20("TestB", "B", 18);

        key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            hooks: IHooks(address(0)),
            poolManager: IPoolManager(address(poolManager)),
            fee: uint24(0), // fee not used in the setup
            parameters: 0x00
        });
    }

    function testSetProtocolFeeController() public {
        vm.expectEmit();
        emit ProtocolFeeControllerUpdated(address(feeController));

        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        assertEq(address(poolManager.protocolFeeController()), address(feeController));
    }

    function testSwap_NoProtocolFee() public {
        poolManager.initialize(key, new bytes(0));

        (uint256 protocolFee0, uint256 protocolFee1) = poolManager.swap(key, 1e18, 1e18);
        assertEq(protocolFee0, 0);
        assertEq(protocolFee1, 0);
    }

    function testInit_WhenFeeController_ProtocolFeeCannotBeFetched() public {
        MockFeePoolManager poolManagerWithLowControllerGasLimit =
            new MockFeePoolManager(IVault(address(vault)), 5000_000);
        PoolKey memory _key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            hooks: IHooks(address(0)),
            poolManager: IPoolManager(address(poolManagerWithLowControllerGasLimit)),
            fee: uint24(0), // fee not used in the setup
            parameters: 0x00
        });
        poolManagerWithLowControllerGasLimit.setProtocolFeeController(feeController);

        vm.expectRevert(IFees.ProtocolFeeCannotBeFetched.selector);
        poolManagerWithLowControllerGasLimit.initialize{gas: 2000_000}(_key, new bytes(0));
    }

    function testInit_WhenFeeControllerRevert() public {
        poolManager.setProtocolFeeController(revertingFeeController);
        poolManager.initialize(key, new bytes(0));

        assertEq(poolManager.getProtocolFee(key), 0);
    }

    function testInit_WhenFeeControllerOutOfBound() public {
        poolManager.setProtocolFeeController(outOfBoundsFeeController);
        assertEq(address(poolManager.protocolFeeController()), address(outOfBoundsFeeController));
        poolManager.initialize(key, new bytes(0));

        assertEq(poolManager.getProtocolFee(key), 0);
    }

    function testInit_WhenFeeControllerOverflow() public {
        poolManager.setProtocolFeeController(overflowFeeController);
        assertEq(address(poolManager.protocolFeeController()), address(overflowFeeController));
        poolManager.initialize(key, new bytes(0));

        assertEq(poolManager.getProtocolFee(key), 0);
    }

    function testInit_WhenFeeControllerInvalidReturnSize() public {
        poolManager.setProtocolFeeController(invalidReturnSizeFeeController);
        assertEq(address(poolManager.protocolFeeController()), address(invalidReturnSizeFeeController));
        poolManager.initialize(key, new bytes(0));

        assertEq(poolManager.getProtocolFee(key), 0);
    }

    function testInitFuzz(uint16 fee) public {
        poolManager.setProtocolFeeController(feeController);

        vm.mockCall(
            address(feeController),
            abi.encodeWithSelector(IProtocolFeeController.protocolFeeForPool.selector, key),
            abi.encode(fee)
        );

        poolManager.initialize(key, new bytes(0));

        if (fee != 0) {
            uint16 fee0 = fee % 256;
            uint16 fee1 = fee >> 8;

            if (
                (fee0 != 0 && fee0 < poolManager.MIN_PROTOCOL_FEE_DENOMINATOR())
                    || (fee1 != 0 && fee1 < poolManager.MIN_PROTOCOL_FEE_DENOMINATOR())
            ) {
                // invalid fee, fallback to 0
                assertEq(poolManager.getProtocolFee(key), 0);
            } else {
                assertEq(poolManager.getProtocolFee(key), fee);
            }
        }
    }

    function testSwap_OnlyProtocolFee() public {
        // set protocolFee as 10% of fee
        uint16 protocolFee = _buildSwapFee(10, 10); // 10%
        feeController.setProtocolFeeForPool(key, protocolFee);
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));

        poolManager.initialize(key, new bytes(0));
        (uint256 protocolFee0, uint256 protocolFee1) = poolManager.swap(key, 1e18, 1e18);
        assertEq(protocolFee0, 1e17);
        assertEq(protocolFee1, 1e17);
    }

    function test_CheckProtocolFee_SwapFee() public {
        uint16 protocolFee = _buildSwapFee(3, 3); // 25% is the limit, 3 = amt/3 = 33%
        feeController.setProtocolFeeForPool(key, protocolFee);
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));

        // wont revert but set protocolFee as 0
        poolManager.initialize(key, new bytes(0));
        assertEq(poolManager.getProtocolFee(key), 0);
    }

    function test_CollectProtocolFee_OnlyOwnerOrFeeController() public {
        vm.expectRevert(IFees.InvalidProtocolFeeCollector.selector);

        vm.prank(address(alice));
        poolManager.collectProtocolFees(alice, Currency.wrap(address(token0)), 1e18);
    }

    function test_CollectProtocolFee() public {
        // set protocolFee as 10% of fee
        feeController.setProtocolFeeForPool(key, _buildSwapFee(10, 10));
        poolManager.setProtocolFeeController(IProtocolFeeController(address(feeController)));
        poolManager.initialize(key, new bytes(0));
        (uint256 protocolFee0, uint256 protocolFee1) = poolManager.swap(key, 1e18, 1e18);
        assertEq(protocolFee0, 1e17);
        assertEq(protocolFee1, 1e17);

        // send some token to vault as poolManager.swap doesn't have tokens
        token0.mint(address(vault), 1e17);
        token1.mint(address(vault), 1e17);

        // before collect
        assertEq(token0.balanceOf(alice), 0);
        assertEq(token1.balanceOf(alice), 0);
        assertEq(token0.balanceOf(address(vault)), 1e17);
        assertEq(token1.balanceOf(address(vault)), 1e17);

        // collect
        vm.prank(address(feeController));
        poolManager.collectProtocolFees(alice, Currency.wrap(address(token0)), 1e17);
        poolManager.collectProtocolFees(alice, Currency.wrap(address(token1)), 1e17);

        // after collect
        assertEq(token0.balanceOf(alice), 1e17);
        assertEq(token1.balanceOf(alice), 1e17);
        assertEq(token0.balanceOf(address(vault)), 0);
        assertEq(token1.balanceOf(address(vault)), 0);
    }

    function _buildSwapFee(uint16 fee0, uint16 fee1) public pure returns (uint16) {
        return fee0 + (fee1 << 8);
    }
}
