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

import {BinTestHelper} from "../helpers/BinTestHelper.sol";
import {Uint128x128Math} from "../../../src/pool-bin/libraries/math/Uint128x128Math.sol";
import {Uint256x256Math} from "../../../src/pool-bin/libraries/math/Uint256x256Math.sol";
import {PackedUint128Math} from "../../../src/pool-bin/libraries/math/PackedUint128Math.sol";
import {Constants} from "../../../src/pool-bin/libraries/Constants.sol";
import {BinHelper} from "../../../src/pool-bin/libraries/BinHelper.sol";
import {BinPoolParametersHelper} from "../../../src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {PriceHelper} from "../../../src/pool-bin/libraries/PriceHelper.sol";
import {FeeHelper} from "../../../src/pool-bin/libraries/FeeHelper.sol";
import {FeeLibrary} from "../../../src/libraries/FeeLibrary.sol";

contract BinHelperTest is BinTestHelper {
    using BinHelper for bytes32;
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Uint128x128Math for uint256;
    using Uint256x256Math for uint256;
    using BinPoolParametersHelper for bytes32;

    function testFuzz_GetAmountOutOfBin(
        uint128 binReserveX,
        uint128 binReserveY,
        uint256 amountToBurn,
        uint256 totalSupply
    ) external {
        totalSupply = bound(totalSupply, 1, type(uint256).max);
        amountToBurn = bound(amountToBurn, 1, totalSupply);

        bytes32 binReserves = binReserveX.encode(binReserveY);

        bytes32 amountOut = binReserves.getAmountOutOfBin(amountToBurn, totalSupply);
        (uint128 amountOutX, uint128 amountOutY) = amountOut.decode();

        assertEq(amountOutX, amountToBurn.mulDivRoundDown(binReserveX, totalSupply), "test_GetAmountOutOfBin::1");
        assertEq(amountOutY, amountToBurn.mulDivRoundDown(binReserveY, totalSupply), "test_GetAmountOutOfBin::2");
    }

    function testFuzz_GetLiquidity(uint128 amountInX, uint128 amountInY, uint256 price) external {
        bytes32 amountsIn = amountInX.encode(amountInY);

        (uint256 px, uint256 L) = (0, 0);

        unchecked {
            px = price * uint256(amountInX);
            L = px + (uint256(amountInY) << 128);
        }

        if ((amountInX != 0 && px / amountInX != price) || L < px) {
            vm.expectRevert(BinHelper.BinHelper__LiquidityOverflow.selector);
            amountsIn.getLiquidity(price);
        } else {
            uint256 liquidity = amountsIn.getLiquidity(price);
            assertEq(liquidity, price * amountInX + (uint256(amountInY) << 128), "test_GetLiquidity::1");
        }
    }

    function testFuzz_getSharesAndEffectiveAmountsIn(
        uint128 binReserveX,
        uint128 binReserveY,
        uint128 amountInX,
        uint128 amountInY,
        uint256 price,
        uint256 totalSupply
    ) external {
        // workaround instead of vm.assume to prevent too many global reject
        bool validParameters;
        validParameters = price > 0
            && (
                binReserveX == 0
                    || (
                        price <= type(uint256).max / binReserveX
                            && price * binReserveX <= (type(uint256).max - binReserveY) << 128
                    )
            )
            && (
                amountInX == 0
                    || (price <= type(uint256).max / amountInX && price * amountInX <= (type(uint256).max - amountInY) << 128)
            );
        if (!validParameters) return;

        bytes32 binReserves = binReserveX.encode(binReserveY);
        uint256 binLiquidity = binReserves.getLiquidity(price);

        totalSupply = bound(totalSupply, 0, binLiquidity);

        bytes32 amountsIn = amountInX.encode(amountInY);

        (uint256 shares, bytes32 effectiveAmountsIn) =
            binReserves.getSharesAndEffectiveAmountsIn(amountsIn, price, totalSupply);

        assertLe(uint256(effectiveAmountsIn), uint256(amountsIn), "test_getSharesAndEffectiveAmountsIn::1");

        uint256 userLiquidity = amountsIn.getLiquidity(price);
        uint256 expectedShares = binLiquidity == 0 || totalSupply == 0
            ? userLiquidity
            : userLiquidity.mulDivRoundDown(totalSupply, binLiquidity);

        assertEq(shares, expectedShares, "test_getSharesAndEffectiveAmountsIn::2");
    }

    function testFuzz_TryExploitShares(
        uint128 amountX1,
        uint128 amountY1,
        uint128 amountX2,
        uint128 amountY2,
        uint256 price
    ) external {
        // workaround instead of vm.assume to prevent too many global reject
        bool validParameters;
        validParameters = price > 0 && amountX1 > 0 && amountY1 > 0 && amountX2 > 0 && amountY2 > 0
            && uint256(amountX1) + amountX2 <= type(uint128).max && uint256(amountY1) + amountY2 <= type(uint128).max
            && price <= type(uint256).max / (uint256(amountX1) + amountX2)
            && uint256(amountY1) + amountY2 <= type(uint128).max
            && price * (uint256(amountX1) + amountX2) <= type(uint256).max - ((uint256(amountY1) + amountY2) << 128);
        if (!validParameters) return;

        // exploiter front run the tx and mint the min amount of shares, so the total supply is 2^128
        uint256 totalSupply = 1 << 128;
        bytes32 binReserves = amountX1.encode(amountY1);
        bytes32 amountsIn = amountX2.encode(amountY2);
        (uint256 shares, bytes32 effectiveAmountsIn) =
            binReserves.getSharesAndEffectiveAmountsIn(amountsIn, price, totalSupply);
        binReserves = binReserves.add(effectiveAmountsIn);
        totalSupply += shares;
        uint256 userReceivedX = shares.mulDivRoundDown(binReserves.decodeX(), totalSupply);
        uint256 userReceivedY = shares.mulDivRoundDown(binReserves.decodeY(), totalSupply);
        uint256 receivedInY = userReceivedX.mulShiftRoundDown(price, Constants.SCALE_OFFSET) + userReceivedY;
        uint256 sentInY =
            price.mulShiftRoundDown(effectiveAmountsIn.decodeX(), Constants.SCALE_OFFSET) + effectiveAmountsIn.decodeY();

        assertApproxEqAbs(receivedInY, sentInY, ((price - 1) >> 128) + 5, "test_TryExploitShares::1");
    }

    function testFuzz_VerifyAmountsNeqIds(uint128 amountX, uint128 amountY, uint24 activeId, uint24 id) external {
        vm.assume(activeId != id);

        bytes32 amounts = amountX.encode(amountY);

        if ((id < activeId && amountX > 0) || (id > activeId && amountY > 0)) {
            vm.expectRevert(abi.encodeWithSelector(BinHelper.BinHelper__CompositionFactorFlawed.selector, id));
        }

        amounts.verifyAmounts(activeId, id);
    }

    function testFuzz_VerifyAmountsOnActiveId(uint128 amountX, uint128 amountY, uint24 activeId) external pure {
        bytes32 amounts = amountX.encode(amountY);
        amounts.verifyAmounts(activeId, activeId);
    }

    function testFuzz_GetCompositionFees(
        uint128 reserveX,
        uint128 reserveY,
        uint16 binStep,
        uint128 amountXIn,
        uint128 amountYIn,
        uint256 price,
        uint256 totalSupply,
        uint24 fee
    ) external {
        binStep = uint16(bound(binStep, 0, 200));
        amountXIn = uint128(bound(amountXIn, 1, type(uint128).max));
        amountYIn = uint128(bound(amountYIn, 1, type(uint128).max));
        price = uint256(bound(price, 1, type(uint256).max / amountXIn));
        fee = uint24(bound(fee, 0, FeeLibrary.TEN_PERCENT_FEE));

        ///@dev temp fix for "The `vm.assume` cheatcode rejected too many inputs"
        ///     dont see a clear way to rewrite this with bound
        if (
            !(
                price * amountXIn <= (type(uint256).max - uint256(amountYIn)) << 128
                    && (reserveX == 0 || price <= type(uint256).max / reserveX)
                    && price * reserveX <= (type(uint256).max - uint256(reserveY)) << 128
            )
        ) {
            vm.expectRevert();
        }
        // make sure p*x+y doesn't overflow
        vm.assume(
            price * amountXIn <= (type(uint256).max - uint256(amountYIn)) << 128
                && (reserveX == 0 || price <= type(uint256).max / reserveX)
                && price * reserveX <= (type(uint256).max - uint256(reserveY)) << 128
        );

        bytes32 binReserves = reserveX.encode(reserveY);
        uint256 binLiquidity = binReserves.getLiquidity(price);

        vm.assume(
            totalSupply <= binLiquidity
                && ((totalSupply == 0 && binReserves == 0) || (totalSupply > 0 && binReserves > 0))
        );

        (uint256 shares, bytes32 amountsIn) =
            binReserves.getSharesAndEffectiveAmountsIn(amountXIn.encode(amountYIn), price, totalSupply);

        vm.assume(
            !binReserves.gt(bytes32(type(uint256).max).sub(amountsIn)) && totalSupply <= type(uint256).max - shares
        );

        (amountXIn, amountYIn) = amountsIn.decode();

        bytes32 compositionFees = binReserves.getCompositionFees(fee, amountsIn, totalSupply, shares);

        uint256 binC = reserveX | reserveY == 0 ? 0 : (uint256(reserveY) << 128) / (uint256(reserveX) + reserveY);
        uint256 userC = amountXIn | amountYIn == 0 ? 0 : (uint256(amountYIn) << 128) / (uint256(amountXIn) + amountYIn);

        if (binC > userC) {
            assertGe(uint256(compositionFees) << 128, 0, "test_GetCompositionFees::1");
        } else {
            assertGe(uint128(uint256(compositionFees)), 0, "test_GetCompositionFees::2");
        }
    }

    function testFuzz_BinIsEmpty(uint128 binReserveX, uint128 binReserveY) external {
        bytes32 binReserves = binReserveX.encode(binReserveY);

        assertEq(binReserves.isEmpty(true), binReserveX == 0, "test_BinIsEmpty::1");
        assertEq(binReserves.isEmpty(false), binReserveY == 0, "test_BinIsEmpty::2");
    }

    function testFuzz_GetAmountsLessThanBin(
        uint128 binReserveX,
        uint128 binReserveY,
        bool swapForY,
        int16 deltaId,
        uint128 amountIn,
        uint24 fee
    ) external {
        fee = uint24(bound(fee, 0, FeeLibrary.TEN_PERCENT_FEE));

        uint24 activeId = uint24(uint256(int256(uint256(ID_ONE)) + deltaId));
        uint256 price = PriceHelper.getPriceFromId(activeId, DEFAULT_BIN_STEP);

        {
            uint256 maxAmountIn = swapForY
                ? uint256(binReserveY).shiftDivRoundUp(Constants.SCALE_OFFSET, price)
                : uint256(binReserveX).mulShiftRoundUp(price, Constants.SCALE_OFFSET);

            if (maxAmountIn > type(uint128).max) return;

            uint128 maxFee = FeeHelper.getFeeAmount(uint128(maxAmountIn), fee);

            // workaround instead of vm.assume to prevent too many global reject
            bool validParameters = maxAmountIn <= type(uint128).max - maxFee && amountIn < maxAmountIn + maxFee;
            if (!validParameters) return;
        }

        bytes32 reserves = binReserveX.encode(binReserveY);

        (bytes32 amountsInToBin, bytes32 amountsOutOfBin, bytes32 totalFees) =
            reserves.getAmounts(fee, DEFAULT_BIN_STEP, swapForY, activeId, amountIn.encode(swapForY));

        assertLe(amountsInToBin.decode(swapForY), amountIn, "test_GetAmounts::1");

        uint256 amountInWithoutFees = amountsInToBin.sub(totalFees).decode(swapForY);

        (uint256 amountOutWithNoFees, uint256 amountOut) = swapForY
            ? (price.mulShiftRoundDown(amountsInToBin.decodeX(), Constants.SCALE_OFFSET), amountsOutOfBin.decodeY())
            : (
                uint256(amountsInToBin.decodeY()).shiftDivRoundDown(Constants.SCALE_OFFSET, price),
                amountsOutOfBin.decodeX()
            );

        assertGe(amountOutWithNoFees, amountOut, "test_GetAmounts::2");

        uint256 amountOutWithFees = swapForY
            ? price.mulShiftRoundDown(amountInWithoutFees, Constants.SCALE_OFFSET)
            : amountInWithoutFees.shiftDivRoundDown(Constants.SCALE_OFFSET, price);

        assertEq(amountOut, amountOutWithFees, "test_GetAmounts::3");
    }

    function testFuzz_getAmountsFullBin(
        uint128 binReserveX,
        uint128 binReserveY,
        bool swapForY,
        int16 deltaId,
        uint128 amountIn,
        uint24 fee
    ) external {
        fee = uint24(bound(fee, 0, FeeLibrary.TEN_PERCENT_FEE));

        uint24 activeId = uint24(uint256(int256(uint256(ID_ONE)) + deltaId));
        uint256 price = PriceHelper.getPriceFromId(activeId, DEFAULT_BIN_STEP);

        {
            uint256 maxAmountIn = swapForY
                ? uint256(binReserveY).shiftDivRoundUp(Constants.SCALE_OFFSET, price)
                : uint256(binReserveX).mulShiftRoundUp(price, Constants.SCALE_OFFSET);
            if (maxAmountIn > type(uint128).max) return;

            uint128 maxFee = FeeHelper.getFeeAmount(uint128(maxAmountIn), fee);
            // workaround instead of vm.assume to prevent too many global reject
            bool validParameters = maxAmountIn <= type(uint128).max - maxFee && amountIn >= maxAmountIn + maxFee;
            if (!validParameters) return;
        }

        bytes32 reserves = binReserveX.encode(binReserveY);

        (bytes32 amountsInToBin, bytes32 amountsOutOfBin, bytes32 totalFees) =
            reserves.getAmounts(fee, DEFAULT_BIN_STEP, swapForY, activeId, amountIn.encode(swapForY));

        assertLe(amountsInToBin.decode(swapForY), amountIn, "test_GetAmounts::1");

        {
            uint256 amountInForSwap = amountsInToBin.decode(swapForY);

            (uint256 amountOutWithNoFees, uint256 amountOut) = swapForY
                ? (price.mulShiftRoundDown(amountInForSwap, Constants.SCALE_OFFSET), amountsOutOfBin.decodeY())
                : (uint256(amountInForSwap).shiftDivRoundDown(Constants.SCALE_OFFSET, price), amountsOutOfBin.decodeX());

            assertGe(amountOutWithNoFees, amountOut, "test_GetAmounts::2");
        }

        uint128 amountInToBin = amountsInToBin.sub(totalFees).decode(swapForY);

        (uint256 amountOutWithFees, uint256 amountOutWithFeesAmountInSub1) = amountInToBin == 0
            ? (0, 0)
            : swapForY
                ? (
                    price.mulShiftRoundDown(amountInToBin, Constants.SCALE_OFFSET),
                    price.mulShiftRoundDown(amountInToBin - 1, Constants.SCALE_OFFSET)
                )
                : (
                    uint256(amountInToBin).shiftDivRoundDown(Constants.SCALE_OFFSET, price),
                    uint256(amountInToBin - 1).shiftDivRoundDown(Constants.SCALE_OFFSET, price)
                );

        assertLe(amountsOutOfBin.decode(!swapForY), amountOutWithFees, "test_GetAmounts::3");
        assertGe(amountsOutOfBin.decode(!swapForY), amountOutWithFeesAmountInSub1, "test_GetAmounts::4");
    }
}
