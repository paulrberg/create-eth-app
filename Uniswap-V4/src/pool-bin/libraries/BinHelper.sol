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

import {IERC20} from "Uniswap-V4/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {PackedUint128Math} from "./math/PackedUint128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";
import {BinPoolParametersHelper} from "./BinPoolParametersHelper.sol";
import {FeeHelper} from "./FeeHelper.sol";
import {PriceHelper} from "./PriceHelper.sol";

/// @notice This library contains functions to help interaction with bins.
library BinHelper {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Uint256x256Math for uint256;
    using PriceHelper for uint24;
    using SafeCast for uint256;
    using BinPoolParametersHelper for bytes32;
    using FeeHelper for uint128;

    error BinHelper__CompositionFactorFlawed(uint24 id);
    error BinHelper__LiquidityOverflow();

    /// @dev Returns the amount of tokens that will be received when burning the given amount of liquidity
    /// @param binReserves The reserves of the bin
    /// @param amountToBurn The amount of liquidity to burn
    /// @param totalSupply The total supply of the liquidity book
    /// @return amountsOut The encoded amount of tokens that will be received
    function getAmountOutOfBin(bytes32 binReserves, uint256 amountToBurn, uint256 totalSupply)
        internal
        pure
        returns (bytes32 amountsOut)
    {
        (uint128 binReserveX, uint128 binReserveY) = binReserves.decode();

        uint128 amountXOutFromBin;
        uint128 amountYOutFromBin;

        if (binReserveX > 0) {
            amountXOutFromBin = (amountToBurn.mulDivRoundDown(binReserveX, totalSupply)).safe128();
        }

        if (binReserveY > 0) {
            amountYOutFromBin = (amountToBurn.mulDivRoundDown(binReserveY, totalSupply)).safe128();
        }

        amountsOut = amountXOutFromBin.encode(amountYOutFromBin);
    }

    /// @dev Returns the share and the effective amounts in when adding liquidity
    /// @param binReserves The reserves of the bin
    /// @param amountsIn The amounts of tokens to add
    /// @param price The price of the bin
    /// @param totalSupply The total supply of the liquidity book
    /// @return shares The share of the liquidity book that the user will receive
    /// @return effectiveAmountsIn The encoded effective amounts of tokens that the user will add.
    /// This is the amount of tokens that the user will actually add to the liquidity book,
    /// and will always be less than or equal to the amountsIn.
    function getSharesAndEffectiveAmountsIn(bytes32 binReserves, bytes32 amountsIn, uint256 price, uint256 totalSupply)
        internal
        pure
        returns (uint256 shares, bytes32 effectiveAmountsIn)
    {
        (uint256 x, uint256 y) = amountsIn.decode();

        uint256 userLiquidity = getLiquidity(x, y, price);
        if (totalSupply == 0 || userLiquidity == 0) return (userLiquidity, amountsIn);

        // current bin liquidity
        uint256 binLiquidity = getLiquidity(binReserves, price);
        if (binLiquidity == 0) return (userLiquidity, amountsIn);

        shares = userLiquidity.mulDivRoundDown(totalSupply, binLiquidity);
        uint256 effectiveLiquidity = shares.mulDivRoundUp(binLiquidity, totalSupply);

        if (userLiquidity > effectiveLiquidity) {
            uint256 deltaLiquidity = userLiquidity - effectiveLiquidity;

            // The other way might be more efficient, but as y is the quote asset, it is more valuable
            if (deltaLiquidity >= Constants.SCALE) {
                uint256 deltaY = deltaLiquidity >> Constants.SCALE_OFFSET;
                deltaY = deltaY > y ? y : deltaY;

                y -= deltaY;
                deltaLiquidity -= deltaY << Constants.SCALE_OFFSET;
            }

            if (deltaLiquidity >= price) {
                uint256 deltaX = deltaLiquidity / price;
                deltaX = deltaX > x ? x : deltaX;

                x -= deltaX;
            }

            amountsIn = uint128(x).encode(uint128(y));
        }

        return (shares, amountsIn);
    }

    /// @dev Returns the amount of liquidity following the constant sum formula `L = price * x + y`
    /// @param amounts The amounts of tokens
    /// @param price The price of the bin
    /// @return liquidity The amount of liquidity
    function getLiquidity(bytes32 amounts, uint256 price) internal pure returns (uint256 liquidity) {
        (uint256 x, uint256 y) = amounts.decode();
        return getLiquidity(x, y, price);
    }

    /// @dev Returns the amount of liquidity following the constant sum formula `L = price * x + y`
    /// @param x The amount of the token X
    /// @param y The amount of the token Y
    /// @param price The price of the bin
    /// @return liquidity The amount of liquidity
    function getLiquidity(uint256 x, uint256 y, uint256 price) internal pure returns (uint256 liquidity) {
        if (x > 0) {
            unchecked {
                liquidity = price * x;
                if (liquidity / x != price) revert BinHelper__LiquidityOverflow();
            }
        }
        if (y > 0) {
            unchecked {
                y <<= Constants.SCALE_OFFSET;
                liquidity += y;

                if (liquidity < y) revert BinHelper__LiquidityOverflow();
            }
        }

        return liquidity;
    }

    /// @dev Verify that the amounts are correct and that the composition factor is not flawed
    /// @param amounts The amounts of tokens
    /// @param activeId The id of the active bin
    /// @param id The id of the bin
    function verifyAmounts(bytes32 amounts, uint24 activeId, uint24 id) internal pure {
        if ((id < activeId && (amounts << 128) > 0) || (id > activeId && uint256(amounts) > type(uint128).max)) {
            revert BinHelper__CompositionFactorFlawed(id);
        }
    }

    /// @dev Returns the composition fees when adding liquidity to the active bin with a different
    ///      composition factor than the bin's one, as it does an implicit swap
    /// @param binReserves The reserves of the bin
    /// @param fee 100 = 0.01%, 1000 = 0.1%
    /// @param amountsIn The amounts of tokens to add
    /// @param totalSupply The total supply of the liquidity book
    /// @param shares The share of the liquidity book that the user will receive
    /// @return fees The encoded fees that will be charged
    function getCompositionFees(
        bytes32 binReserves,
        uint24 fee, // fee: 100 = 0.01%
        bytes32 amountsIn,
        uint256 totalSupply,
        uint256 shares
    ) internal pure returns (bytes32 fees) {
        if (shares == 0) return 0;

        (uint128 amountX, uint128 amountY) = amountsIn.decode();
        (uint128 receivedAmountX, uint128 receivedAmountY) =
            getAmountOutOfBin(binReserves.add(amountsIn), shares, totalSupply + shares).decode();

        // if received more X than given X
        if (receivedAmountX > amountX) {
            uint128 feeY = (amountY - receivedAmountY).getCompositionFee(fee);
            fees = feeY.encodeSecond();
        } else if (receivedAmountY > amountY) {
            uint128 feeX = (amountX - receivedAmountX).getCompositionFee(fee);
            fees = feeX.encodeFirst();
        }
    }

    /// @dev Returns whether the bin is empty (true) or not (false)
    /// @param binReserves The reserves of the bin
    /// @param isX Whether the reserve to check is the X reserve (true) or the Y reserve (false)
    /// @return Whether the bin is empty (true) or not (false)
    function isEmpty(bytes32 binReserves, bool isX) internal pure returns (bool) {
        return isX ? binReserves.decodeX() == 0 : binReserves.decodeY() == 0;
    }

    /// @dev Returns the amounts of tokens that will be added and removed from the bin during a swap
    ///     along with the fees that will be charged
    /// @param binReserves The reserves of the bin
    /// @param fee 100 = 0.01%, 1_000 = 0.1%
    /// @param binStep The step of the bin
    /// @param swapForY Whether the swap is for Y (true) or for X (false)
    /// @param activeId The id of the active bin
    /// @param amountsInLeft The amounts of tokens left to swap
    /// @return amountsInWithFees The encoded amounts of tokens that will be added to the bin, including fees
    /// @return amountsOutOfBin The encoded amounts of tokens that will be removed from the bin
    /// @return totalFees The encoded fees that will be charged
    function getAmounts(
        bytes32 binReserves,
        uint24 fee,
        uint16 binStep,
        bool swapForY, // swap `swapForY` and `activeId` to avoid stack too deep
        uint24 activeId,
        bytes32 amountsInLeft
    ) internal pure returns (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) {
        uint256 price = activeId.getPriceFromId(binStep);

        uint128 binReserveOut = binReserves.decode(!swapForY);

        uint128 maxAmountIn = swapForY
            ? uint256(binReserveOut).shiftDivRoundUp(Constants.SCALE_OFFSET, price).safe128()
            : uint256(binReserveOut).mulShiftRoundUp(price, Constants.SCALE_OFFSET).safe128();

        uint128 maxFee = maxAmountIn.getFeeAmount(fee);

        maxAmountIn += maxFee;

        uint128 amountIn128 = amountsInLeft.decode(swapForY);
        uint128 fee128;
        uint128 amountOut128;

        if (amountIn128 >= maxAmountIn) {
            fee128 = maxFee;

            amountIn128 = maxAmountIn;
            amountOut128 = binReserveOut;
        } else {
            fee128 = amountIn128.getFeeAmountFrom(fee);

            uint256 amountIn = amountIn128 - fee128;

            amountOut128 = swapForY
                ? uint256(amountIn).mulShiftRoundDown(price, Constants.SCALE_OFFSET).safe128()
                : uint256(amountIn).shiftDivRoundDown(Constants.SCALE_OFFSET, price).safe128();

            if (amountOut128 > binReserveOut) amountOut128 = binReserveOut;
        }

        (amountsInWithFees, amountsOutOfBin, totalFees) = swapForY
            ? (amountIn128.encodeFirst(), amountOut128.encodeSecond(), fee128.encodeFirst())
            : (amountIn128.encodeSecond(), amountOut128.encodeFirst(), fee128.encodeSecond());
    }
}
