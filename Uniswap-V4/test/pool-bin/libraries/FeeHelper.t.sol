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
import {FeeHelper} from "../../../src/pool-bin/libraries/FeeHelper.sol";
import {Uint256x256Math} from "../../../src/pool-bin/libraries/math/Uint256x256Math.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";

contract FeeHelperTest is Test {
    using FeeHelper for uint128;
    using Uint256x256Math for uint256;

    function testFuzz_GetFeeAmountFrom(uint128 amountWithFee, uint24 feeBips) external {
        feeBips = uint24(bound(feeBips, 0, FeeLibrary.TEN_PERCENT_FEE));

        uint128 fee = uint128(feeBips) * 1e12;
        uint256 expectedFeeAmount = (uint256(amountWithFee) * fee + 1e18 - 1) / 1e18;
        uint128 feeAmount = amountWithFee.getFeeAmountFrom(feeBips);

        assertEq(feeAmount, expectedFeeAmount, "testFuzz_GetFeeAmountFrom::1");
    }

    function testFuzz_GetFeeAmount(uint128 amount, uint24 feeBips) external {
        feeBips = uint24(bound(feeBips, 0, FeeLibrary.TEN_PERCENT_FEE));

        uint128 fee = uint128(feeBips) * 1e12;
        uint128 denominator = 1e18 - fee;
        uint256 expectedFeeAmount = (uint256(amount) * fee + denominator - 1) / denominator;

        uint128 feeAmount = amount.getFeeAmount(feeBips);

        assertEq(feeAmount, expectedFeeAmount, "testFuzz_GetFeeAmount::1");
    }

    function testFuzz_GetCompositionFee(uint128 amountWithFee, uint24 feeBips) external {
        feeBips = uint24(bound(feeBips, 0, FeeLibrary.TEN_PERCENT_FEE));

        uint128 fee = uint128(feeBips) * 1e12;
        uint256 denominator = 1e36;
        uint256 expectedCompositionFee =
            (uint256(amountWithFee) * fee).mulDivRoundDown(uint256(fee) + 1e18, denominator);

        uint128 compositionFee = amountWithFee.getCompositionFee(feeBips);
        assertEq(compositionFee, expectedCompositionFee, "testFuzz_GetCompositionFee::1");
    }
}
