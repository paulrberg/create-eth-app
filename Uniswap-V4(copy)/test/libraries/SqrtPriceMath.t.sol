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

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {Vm} from "Uniswap-V4/forge-std/Vm.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {SqrtPriceMath} from "../../src/libraries/SqrtPriceMath.sol";
import {Constants} from "../../test/utils/Constants.sol";

contract SqrtPriceMathTest is Test, GasSnapshot {
    function test_getNextSqrtPriceFromInput_revertsIfPriceIsZero() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        SqrtPriceMath.getNextSqrtPriceFromInput(0, 1, 0.1 ether, false);
    }

    function test_getNextSqrtPriceFromInput_revertsIfLiquidityIsZero() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        SqrtPriceMath.getNextSqrtPriceFromInput(1, 0, 0.1 ether, true);
    }

    function test_getNextSqrtPriceFromInput_revertsIfInputAmountOverflowsThePrice() public {
        uint160 price = Constants.MAX_UINT160 - 1;
        uint128 liquidity = 1024;
        uint256 amountIn = 1024;

        vm.expectRevert();
        SqrtPriceMath.getNextSqrtPriceFromInput(price, liquidity, amountIn, false);
    }

    function test_getNextSqrtPriceFromInput_anyInputAmountCannotUnderflowThePrice() public pure {
        uint160 price = 1;
        uint128 liquidity = 1;
        uint256 amountIn = 2 ** 255;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromInput(price, liquidity, amountIn, true);

        assertEq(sqrtQ, 1);
    }

    function test_getNextSqrtPriceFromInput_returnsInputPriceIfAmountInIsZeroAndZeroForOneEqualsTrue() public pure {
        uint160 price = Constants.SQRT_PRICE_1_1;
        uint128 liquidity = 1;

        assertEq(SqrtPriceMath.getNextSqrtPriceFromInput(price, liquidity, 0, true), price);
    }

    function test_getNextSqrtPriceFromInput_returnsInputPriceIfAmountInIsZeroAndZeroForOneEqualsFalse() public pure {
        uint160 price = Constants.SQRT_PRICE_1_1;
        uint128 liquidity = 1;

        assertEq(SqrtPriceMath.getNextSqrtPriceFromInput(price, liquidity, 0, false), price);
    }

    function test_getNextSqrtPriceFromInput_returnsTheMinimumPriceForMaxInputs() public pure {
        uint160 sqrtP = Constants.MAX_UINT160 - 1;
        uint128 liquidity = Constants.MAX_UINT128;
        uint256 maxAmountNoOverflow = Constants.MAX_UINT256 - Constants.MAX_UINT128 << 96 / sqrtP;

        assertEq(SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, liquidity, maxAmountNoOverflow, true), 1);
    }

    function test_getNextSqrtPriceFromInput_inputAmountOf0_1Currency1() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, uint128(1 ether), 0.1 ether, false);

        assertEq(sqrtQ, Constants.SQRT_PRICE_121_100);
    }

    function test_getNextSqrtPriceFromInput_inputAmountOf0_1Currency0() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, uint128(1 ether), 0.1 ether, true);

        assertEq(sqrtQ, 72025602285694852357767227579);
    }

    function test_getNextSqrtPriceFromInput_amountInGreaterThanType_uint96_maxAndZeroForOneEqualsTrue() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, uint128(10 ether), 2 ** 100, true);

        // perfect answer:
        // https://www.wolframalpha.com/input/?i=624999999995069620+-+%28%281e19+*+1+%2F+%281e19+%2B+2%5E100+*+1%29%29+*+2%5E96%29
        assertEq(sqrtQ, 624999999995069620);
    }

    function test_getNextSqrtPriceFromInput_canReturn1WithEnoughAmountInAndZeroForOneEqualsTrue() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, 1, Constants.MAX_UINT256 / 2, true);

        assertEq(sqrtQ, 1);
    }

    //
    function test_getNextSqrtPriceFromInput_zeroForOneEqualsTrueGas() public {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        snapStart("getNextSqrtPriceFromInput_zeroForOneEqualsTrueGas");
        SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, uint128(1 ether), 0.1 ether, true);
        snapEnd();
    }

    function test_getNextSqrtPriceFromInput_zeroForOneEqualsFalseGas() public {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        snapStart("getNextSqrtPriceFromInput_zeroForOneEqualsFalseGas");
        SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, uint128(1 ether), 0.1 ether, false);
        snapEnd();
    }

    function test_getNextSqrtPriceFromOutput_revertsIfPriceIsZero() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(0, 1, 0.1 ether, false);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfLiquidityIsZero() public {
        vm.expectRevert(SqrtPriceMath.InvalidPriceOrLiquidity.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(1, 0, 0.1 ether, true);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfOutputAmountIsExactlyTheVirtualReservesOfCurrency0() public {
        uint160 price = 20282409603651670423947251286016;
        uint128 liquidity = 1024;
        uint256 amountOut = 4;

        vm.expectRevert(SqrtPriceMath.PriceOverflow.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, false);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfOutputAmountIsGreaterThanTheVirtualReservesOfCurrency0() public {
        uint160 price = 20282409603651670423947251286016;
        uint128 liquidity = 1024;
        uint256 amountOut = 5;

        vm.expectRevert(SqrtPriceMath.PriceOverflow.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, false);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfOutputAmountIsGreaterThanTheVirtualReservesOfCurrency1() public {
        uint160 price = 20282409603651670423947251286016;
        uint128 liquidity = 1024;
        uint256 amountOut = 262145;

        vm.expectRevert(SqrtPriceMath.NotEnoughLiquidity.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, true);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfOutputAmountIsExactlyTheVirtualReservesOfCurrency1() public {
        uint160 price = 20282409603651670423947251286016;
        uint128 liquidity = 1024;
        uint256 amountOut = 262144;

        vm.expectRevert(SqrtPriceMath.NotEnoughLiquidity.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, true);
    }

    function test_getNextSqrtPriceFromOutput_succeedsIfOutputAmountIsJustLessThanTheVirtualReservesOfCurrency1()
        public
        pure
    {
        uint160 price = 20282409603651670423947251286016;
        uint128 liquidity = 1024;
        uint256 amountOut = 262143;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, true);

        assertEq(sqrtQ, 77371252455336267181195264);
    }

    function test_getNextSqrtPriceFromOutput_puzzlingEchidnaTest() public {
        uint160 price = 20282409603651670423947251286016;
        uint128 liquidity = 1024;
        uint256 amountOut = 4;

        vm.expectRevert(SqrtPriceMath.PriceOverflow.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, false);
    }

    function test_getNextSqrtPriceFromOutput_returnsInputPriceIfAmountInIsZeroAndZeroForOneEqualsTrue() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint256 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, uint128(0.1 ether), 0, true);

        assertEq(sqrtP, sqrtQ);
    }

    function test_getNextSqrtPriceFromOutput_returnsInputPriceIfAmountInIsZeroAndZeroForOneEqualsFalse() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint256 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, uint128(0.1 ether), 0, false);

        assertEq(sqrtP, sqrtQ);
    }

    function test_getNextSqrtPriceFromOutput_outputAmountOf0_1Currency1() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, uint128(1 ether), 0.1 ether, false);

        assertEq(sqrtQ, 88031291682515930659493278152);
    }

    function test_getNextSqrtPriceFromOutput_outputAmountOf0_1Currency0() public pure {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, uint128(1 ether), 0.1 ether, true);

        assertEq(sqrtQ, 71305346262837903834189555302);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfAmountOutIsImpossibleInZeroForOneDirection() public {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        vm.expectRevert();
        SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, 1, Constants.MAX_UINT256, true);
    }

    function test_getNextSqrtPriceFromOutput_revertsIfAmountOutIsImpossibleInOneForZeroDirection() public {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        vm.expectRevert(SqrtPriceMath.PriceOverflow.selector);
        SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, 1, Constants.MAX_UINT256, false);
    }

    function test_getNextSqrtPriceFromOutput_zeroForOneEqualsTrueGas() public {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        snapStart("getNextSqrtPriceFromOutput_zeroForOneEqualsTrueGas");
        SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, uint128(1 ether), 0.1 ether, true);
        snapEnd();
    }

    function test_getNextSqrtPriceFromOutput_zeroForOneEqualsFalseGas() public {
        uint160 sqrtP = Constants.SQRT_PRICE_1_1;

        snapStart("getNextSqrtPriceFromOutput_zeroForOneEqualsFalseGas");
        SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtP, uint128(1 ether), 0.1 ether, false);
        snapEnd();
    }

    function test_getAmount0Delta_returns0IfLiquidityIs0() public pure {
        uint256 amount0 = SqrtPriceMath.getAmount0Delta(Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_2_1, 0, true);

        assertEq(amount0, 0);
    }

    function test_getAmount0Delta_returns0IfPricesAreEqual() public pure {
        uint256 amount0 = SqrtPriceMath.getAmount0Delta(Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_1_1, 0, true);

        assertEq(amount0, 0);
    }

    function test_getAmount0Delta_revertsIfPriceIsZero() public {
        vm.expectRevert(SqrtPriceMath.InvalidPrice.selector);
        SqrtPriceMath.getAmount0Delta(0, 1, 1, true);
    }

    function test_getAmount0Delta_1Amount1ForPriceOf1To1_21() public pure {
        uint256 amount0 = SqrtPriceMath.getAmount0Delta(
            Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_121_100, uint128(1 ether), true
        );

        assertEq(amount0, 90909090909090910);

        uint256 amount0RoundedDown = SqrtPriceMath.getAmount0Delta(
            Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_121_100, uint128(1 ether), false
        );

        assertEq(amount0RoundedDown, amount0 - 1);
    }

    function test_getAmount0Delta_worksForPricesThatOverflow() public pure {
        // sqrtP_1 = encodeSqrtPriceX96(2^90, 1)
        uint160 sqrtP_1 = 2787593149816327892691964784081045188247552;
        // sqrtP_2 = encodeSqrtPriceX96(2^96, 1)
        uint160 sqrtP_2 = 22300745198530623141535718272648361505980416;

        uint256 amount0Up = SqrtPriceMath.getAmount0Delta(sqrtP_1, sqrtP_2, uint128(1 ether), true);

        uint256 amount0Down = SqrtPriceMath.getAmount0Delta(sqrtP_1, sqrtP_2, uint128(1 ether), false);

        assertEq(amount0Up, amount0Down + 1);
    }

    function test_getAmount0Delta_gasCostForAmount0WhereRoundUpIsTrue() public {
        snapStart("getAmount0Delta_gasCostForAmount0WhereRoundUpIsTrue");
        SqrtPriceMath.getAmount0Delta(Constants.SQRT_PRICE_121_100, Constants.SQRT_PRICE_1_1, uint128(1 ether), true);
        snapEnd();
    }

    function test_getAmount0Delta_gasCostForAmount0WhereRoundUpIsFalse() public {
        snapStart("getAmount0Delta_gasCostForAmount0WhereRoundUpIsFalse");
        SqrtPriceMath.getAmount0Delta(Constants.SQRT_PRICE_121_100, Constants.SQRT_PRICE_1_1, uint128(1 ether), false);
        snapEnd();
    }

    function test_getAmount1Delta_returns0IfLiquidityIs0() public pure {
        uint256 amount1 = SqrtPriceMath.getAmount1Delta(Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_2_1, 0, true);

        assertEq(amount1, 0);
    }

    function test_getAmount1Delta_returns0IfPricesAreEqual() public pure {
        uint256 amount1 = SqrtPriceMath.getAmount1Delta(Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_1_1, 0, true);

        assertEq(amount1, 0);
    }

    function test_getAmount1Delta_1Amount1ForPriceOf1To1_21() public pure {
        uint256 amount1 = SqrtPriceMath.getAmount1Delta(
            Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_121_100, uint128(1 ether), true
        );

        assertEq(amount1, 100000000000000000);

        uint256 amount1RoundedDown = SqrtPriceMath.getAmount1Delta(
            Constants.SQRT_PRICE_1_1, Constants.SQRT_PRICE_121_100, uint128(1 ether), false
        );

        assertEq(amount1RoundedDown, amount1 - 1);
    }

    function test_getAmount1Delta_gasCostForAmount1WhereRoundUpIsTrue() public {
        snapStart("getAmount1Delta_gasCostForAmount1WhereRoundUpIsTrue");
        SqrtPriceMath.getAmount1Delta(Constants.SQRT_PRICE_121_100, Constants.SQRT_PRICE_1_1, uint128(1 ether), true);
        snapEnd();
    }

    function test_getAmount1Delta_gasCostForAmount1WhereRoundUpIsFalse() public {
        snapStart("getAmount1Delta_gasCostForAmount1WhereRoundUpIsFalse");
        SqrtPriceMath.getAmount1Delta(Constants.SQRT_PRICE_121_100, Constants.SQRT_PRICE_1_1, uint128(1 ether), false);
        snapEnd();
    }

    function test_swapComputation_sqrtPTimessqrtQOverflows() public pure {
        // getNextSqrtPriceInvariants(1025574284609383690408304870162715216695788925244,50015962439936049619261659728067971248,406,true)
        uint160 sqrtP = 1025574284609383690408304870162715216695788925244;
        uint128 liquidity = 50015962439936049619261659728067971248;
        bool zeroForOne = true;
        uint128 amountIn = 406;

        uint160 sqrtQ = SqrtPriceMath.getNextSqrtPriceFromInput(sqrtP, liquidity, amountIn, zeroForOne);
        assertEq(sqrtQ, 1025574284609383582644711336373707553698163132913);

        uint256 amount0Delta = SqrtPriceMath.getAmount0Delta(sqrtQ, sqrtP, liquidity, true);
        assertEq(amount0Delta, 406);
    }
}
