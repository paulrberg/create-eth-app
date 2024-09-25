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

import {BalanceDelta, toBalanceDelta} from "../../types/BalanceDelta.sol";
import {IBinLmPool} from "../interfaces/IBinLmPool.sol";
import {LiquidityConfigurations} from "./math/LiquidityConfigurations.sol";
import {PackedUint128Math} from "./math/PackedUint128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {TreeMath} from "./math/TreeMath.sol";
import {PriceHelper} from "./PriceHelper.sol";
import {BinHelper} from "./BinHelper.sol";
import {BinPosition} from "./BinPosition.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";
import {FeeHelper} from "./FeeHelper.sol";

library BinPool {
    using BinHelper for bytes32;
    using LiquidityConfigurations for bytes32;
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using PriceHelper for uint24;
    using Uint256x256Math for uint256;
    using BinPosition for mapping(bytes32 => BinPosition.Info);
    using BinPosition for BinPosition.Info;
    using TreeMath for bytes32;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using FeeHelper for uint128;
    using BinPool for State;

    error PoolNotInitialized();
    error PoolAlreadyInitialized();
    error BinPool__EmptyLiquidityConfigs();
    error BinPool__ZeroShares(uint24 id);
    error BinPool__InvalidBurnInput();
    error BinPool__BurnZeroAmount(uint24 id);
    error BinPool__ZeroAmountsOut(uint24 id);
    error BinPool__InsufficientAmountIn();
    error BinPool__OutOfLiquidity();
    error BinPool__InsufficientAmountOut();
    error BinPool__NoLiquidityToReceiveFees();

    struct Slot0 {
        // the current activeId
        uint24 activeId;
        /// @dev Fee is involved when:
        // 1. During mint() incur composition fee when amountIn to active bin doesn't match the composition of asset in bin
        // 2. During swap()
        // protocol swap fee represented as integer denominator (1/x), taken as a % of the LP swap fee
        // upper 8 bits are for 1->0, and the lower 8 are for 0->1
        // the minimum permitted denominator is 4 - meaning the maximum protocol fee is 25%
        // granularity is increments of 0.38% (100/type(uint8).max)
        /// bits          16 14 12 10 8  6  4  2  0
        ///               |         swap          |
        ///               ┌───────────┬───────────┬
        /// protocolFee : |  1->0     |  0 -> 1   |
        ///               └───────────┴───────────┴
        uint16 protocolFee;
        // used for the swap fee, either static at initialize or dynamic via hook
        uint24 swapFee;
    }

    /// @dev The state of a pool
    struct State {
        Slot0 slot0;
        /// @notice binId ==> (reserve of token x and y in the bin)
        mapping(uint256 binId => bytes32 reserve) reserveOfBin;
        /// @notice binId ==> (total share minted)
        mapping(uint256 binId => uint256 share) shareOfBin;
        /// @notice (user, binId) => shares of user in a binId
        mapping(bytes32 => BinPosition.Info) positions;
        /// @dev todo: cannot nest a struct with mapping, error: recursive type is not allowed for public state variables.
        /// TreeMath.TreeUint24 _tree;
        /// the 3 attributes below come from TreeMath
        bytes32 level0;
        mapping(bytes32 => bytes32) level1;
        mapping(bytes32 => bytes32) level2;
        /// @notice liquidity mining pool, if set, indicate a farm is present for this pool
        IBinLmPool lmPool;
    }

    function initialize(State storage self, uint24 activeId, uint16 protocolFee, uint24 swapFee) internal {
        /// An initialized pool will not have activeId: 0
        if (self.slot0.activeId != 0) revert PoolAlreadyInitialized();

        self.slot0 = Slot0({activeId: activeId, protocolFee: protocolFee, swapFee: swapFee});
    }

    function setProtocolFee(State storage self, uint16 protocolFee) internal {
        if (self.isNotInitialized()) revert PoolNotInitialized();
        self.slot0.protocolFee = protocolFee;
    }

    /// @notice Only dynamic fee pools may update the swap fee.
    function setSwapFee(State storage self, uint24 swapFee) internal {
        if (self.isNotInitialized()) revert PoolNotInitialized();

        self.slot0.swapFee = swapFee;
    }

    function setLmPool(State storage self, address lmPool) internal {
        if (self.isNotInitialized()) revert PoolNotInitialized();
        self.lmPool = IBinLmPool(lmPool);
    }

    function getLmPool(State storage self) internal view returns (address) {
        if (self.isNotInitialized()) revert PoolNotInitialized();

        return address(self.lmPool);
    }

    struct SwapViewParams {
        bool swapForY;
        uint16 binStep;
        uint24 fee;
    }

    function getSwapIn(State storage self, SwapViewParams memory params, uint128 amountOut)
        internal
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee)
    {
        uint24 id = self.slot0.activeId;
        amountOutLeft = amountOut;

        while (true) {
            uint128 binReserves = self.reserveOfBin[id].decode(!params.swapForY);
            if (binReserves > 0) {
                uint256 price = id.getPriceFromId(params.binStep);

                uint128 amountOutOfBin = binReserves > amountOutLeft ? amountOutLeft : binReserves;

                uint128 amountInWithoutFee = uint128(
                    params.swapForY
                        ? uint256(amountOutOfBin).shiftDivRoundUp(Constants.SCALE_OFFSET, price)
                        : uint256(amountOutOfBin).mulShiftRoundUp(price, Constants.SCALE_OFFSET)
                );

                uint128 feeAmount = amountInWithoutFee.getFeeAmount(params.fee);

                amountIn += amountInWithoutFee + feeAmount;
                amountOutLeft -= amountOutOfBin;

                fee += feeAmount;
            }

            if (amountOutLeft == 0) {
                break;
            } else {
                uint24 nextId = getNextNonEmptyBin(self, params.swapForY, id);
                if (nextId == 0 || nextId == type(uint24).max) break;
                id = nextId;
            }
        }
    }

    function getSwapOut(State storage self, SwapViewParams memory params, uint128 amountIn)
        internal
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee)
    {
        uint24 id = self.slot0.activeId;
        bytes32 amountsInLeft = amountIn.encode(params.swapForY);

        while (true) {
            bytes32 binReserves = self.reserveOfBin[id];
            if (!binReserves.isEmpty(!params.swapForY)) {
                (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) =
                    binReserves.getAmounts(params.fee, params.binStep, params.swapForY, id, amountsInLeft);

                if (amountsInWithFees > 0) {
                    amountsInLeft = amountsInLeft.sub(amountsInWithFees);

                    amountOut += amountsOutOfBin.decode(!params.swapForY);

                    fee += totalFees.decode(params.swapForY);
                }
            }

            if (amountsInLeft == 0) {
                break;
            } else {
                uint24 nextId = getNextNonEmptyBin(self, params.swapForY, id);
                if (nextId == 0 || nextId == type(uint24).max) break;
                id = nextId;
            }
        }

        amountInLeft = amountsInLeft.decode(params.swapForY);
    }

    struct SwapParams {
        bool swapForY;
        uint16 binStep;
    }

    function swap(State storage self, SwapParams memory params, uint128 amountIn)
        internal
        returns (BalanceDelta result, bytes32 feeForProtocol, uint24 activeId, uint24 swapFee)
    {
        activeId = self.slot0.activeId;

        if (amountIn == 0) revert BinPool__InsufficientAmountIn();

        if (address(self.lmPool) != address(0)) {
            self.lmPool.accumulateReward(uint32(block.timestamp));
        }

        bytes32 amountsLeft = params.swapForY ? amountIn.encodeFirst() : amountIn.encodeSecond();
        bytes32 amountsOut;
        swapFee = self.slot0.swapFee;

        while (true) {
            bytes32 binReserves = self.reserveOfBin[activeId];
            if (!binReserves.isEmpty(!params.swapForY)) {
                (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) =
                    binReserves.getAmounts(swapFee, params.binStep, params.swapForY, activeId, amountsLeft);

                if (amountsInWithFees > 0) {
                    amountsLeft = amountsLeft.sub(amountsInWithFees);
                    amountsOut = amountsOut.add(amountsOutOfBin);

                    bytes32 pFee = totalFees.getExternalFeeAmt(self.slot0.protocolFee);
                    if (pFee != 0) {
                        feeForProtocol = feeForProtocol.add(pFee);
                        amountsInWithFees = amountsInWithFees.sub(pFee);
                    }

                    self.reserveOfBin[activeId] = binReserves.add(amountsInWithFees).sub(amountsOutOfBin);
                }
            }

            if (amountsLeft == 0) {
                break;
            } else {
                uint24 nextId = getNextNonEmptyBin(self, params.swapForY, activeId);
                if (nextId == 0 || nextId == type(uint24).max) revert BinPool__OutOfLiquidity();
                activeId = nextId;
            }
        }

        if (amountsOut == 0) revert BinPool__InsufficientAmountOut();

        self.slot0.activeId = activeId;

        if (params.swapForY) {
            uint128 consumed = amountIn - amountsLeft.decodeX();
            result = toBalanceDelta(consumed.safeInt128(), -(amountsOut.decodeY().safeInt128()));
        } else {
            uint128 consumed = amountIn - amountsLeft.decodeY();
            result = toBalanceDelta(-(amountsOut.decodeX().safeInt128()), consumed.safeInt128());
        }
    }

    struct MintParams {
        address to; // nft minted to
        bytes32[] liquidityConfigs;
        bytes32 amountIn;
        uint16 binStep;
    }

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    /// @return result the delta of the token balance of the pool (inclusive of fees)
    /// @return feeForProtocol total protocol fee amount
    /// @return arrays the ids, amounts and liquidity minted for each bin
    /// @return compositionFee composition fee for adding different ratio to active bin
    function mint(State storage self, MintParams memory params)
        internal
        returns (BalanceDelta result, bytes32 feeForProtocol, MintArrays memory arrays, bytes32 compositionFee)
    {
        if (params.liquidityConfigs.length == 0) revert BinPool__EmptyLiquidityConfigs();

        arrays = MintArrays({
            ids: new uint256[](params.liquidityConfigs.length),
            amounts: new bytes32[](params.liquidityConfigs.length),
            liquidityMinted: new uint256[](params.liquidityConfigs.length)
        });

        (bytes32 amountsLeft, bytes32 fee, bytes32 compoFee) = _mintBins(self, params, arrays);
        feeForProtocol = fee;
        compositionFee = compoFee;

        (uint128 x1, uint128 x2) = params.amountIn.sub(amountsLeft).decode();
        result = toBalanceDelta(x1.safeInt128(), x2.safeInt128());
    }

    /// @notice Returns the reserves of a bin
    /// @param id The id of the bin
    /// @return binReserveX The reserve of token X in the bin
    /// @return binReserveY The reserve of token Y in the bin
    function getBin(State storage self, uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY) {
        (binReserveX, binReserveY) = self.reserveOfBin[id].decode();
    }

    /// @dev Returns next non-empty bin
    /// @param swapForY Whether the swap is for Y
    /// @param id The id of the bin
    /// @return The id of the next non-empty bin
    function getNextNonEmptyBin(State storage self, bool swapForY, uint24 id) internal view returns (uint24) {
        return swapForY
            ? TreeMath.findFirstRight(self.level0, self.level1, self.level2, id)
            : TreeMath.findFirstLeft(self.level0, self.level1, self.level2, id);
    }

    struct BurnParams {
        address from;
        uint256[] ids;
        uint256[] amountsToBurn;
    }

    /// @notice Burn user's share and withdraw tokens form the pool.
    /// @return result the delta of the token balance of the pool
    function burn(State storage self, BurnParams memory params)
        internal
        returns (BalanceDelta result, uint256[] memory ids, bytes32[] memory amounts)
    {
        ids = params.ids;
        uint256[] memory amountsToBurn = params.amountsToBurn;

        if (ids.length == 0 || ids.length != amountsToBurn.length) revert BinPool__InvalidBurnInput();

        bytes32 amountsOut;
        amounts = new bytes32[](ids.length);
        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();
            uint256 amountToBurn = amountsToBurn[i];

            if (amountToBurn == 0) revert BinPool__BurnZeroAmount(id);

            bytes32 binReserves = self.reserveOfBin[id];
            uint256 supply = self.shareOfBin[id];

            _subShare(self, params.from, id, amountToBurn);

            bytes32 amountsOutFromBin = binReserves.getAmountOutOfBin(amountToBurn, supply);

            if (amountsOutFromBin == 0) revert BinPool__ZeroAmountsOut(id);

            binReserves = binReserves.sub(amountsOutFromBin);

            if (supply == amountToBurn) _removeBinIdToTree(self, id);

            self.reserveOfBin[id] = binReserves;
            amounts[i] = amountsOutFromBin;
            amountsOut = amountsOut.add(amountsOutFromBin);

            unchecked {
                ++i;
            }
        }

        // set amoutsOut to negative (so user can take/mint()) from the vault
        result = toBalanceDelta(-(amountsOut.decodeX().safeInt128()), -(amountsOut.decodeY().safeInt128()));
    }

    function donate(State storage self, uint16 binStep, uint128 amount0, uint128 amount1)
        internal
        returns (BalanceDelta result, uint24 activeId)
    {
        activeId = self.slot0.activeId;
        bytes32 amountIn = amount0.encode(amount1);

        bytes32 binReserves = self.reserveOfBin[activeId];
        if (binReserves == 0) revert BinPool__NoLiquidityToReceiveFees();

        /// @dev overflow check on total reserves and the resulting liquidity
        uint256 price = activeId.getPriceFromId(binStep);
        binReserves.add(amountIn).getLiquidity(price);

        self.reserveOfBin[activeId] = binReserves.add(amountIn);
        result = toBalanceDelta(amount0.safeInt128(), amount1.safeInt128());
    }

    /// @dev Helper function to mint liquidity in each bin in the liquidity configurations
    /// @param params MintParams (to, liquidityConfig, amountIn, binStep and fee)
    /// @param arrays MintArrays (ids[] , amounts[], liquidityMinted[])
    /// @return amountsLeft amountLeft after deducting all the input (inclusive of fee) from amountIn
    /// @return feeForProtocol total feeForProtocol for minting
    /// @return compositionFee composition fee for adding different ratio to active bin
    function _mintBins(State storage self, MintParams memory params, MintArrays memory arrays)
        private
        returns (bytes32 amountsLeft, bytes32 feeForProtocol, bytes32 compositionFee)
    {
        amountsLeft = params.amountIn;

        for (uint256 i; i < params.liquidityConfigs.length;) {
            (bytes32 maxAmountsInToBin, uint24 id) = params.liquidityConfigs[i].getAmountsAndId(params.amountIn);

            (uint256 shares, bytes32 amountsIn, bytes32 amountsInToBin, bytes32 binFeeAmt, bytes32 binCompositionFee) =
                _updateBin(self, params, id, maxAmountsInToBin);

            amountsLeft = amountsLeft.sub(amountsIn);
            feeForProtocol = feeForProtocol.add(binFeeAmt);

            arrays.ids[i] = id;
            arrays.amounts[i] = amountsInToBin;
            arrays.liquidityMinted[i] = shares;

            _addShare(self, params.to, id, shares);

            compositionFee = compositionFee.add(binCompositionFee);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Helper function to update a bin during minting
    /// @param id The id of the bin
    /// @param maxAmountsInToBin The maximum amounts in to the bin
    /// @return shares The amount of shares minted
    /// @return amountsIn The amounts in
    /// @return amountsInToBin The amounts in to the bin
    /// @return feeForProtocol The amounts of fee for protocol
    /// @return compositionFee The total amount of composition fee
    function _updateBin(State storage self, MintParams memory params, uint24 id, bytes32 maxAmountsInToBin)
        internal
        returns (
            uint256 shares,
            bytes32 amountsIn,
            bytes32 amountsInToBin,
            bytes32 feeForProtocol,
            bytes32 compositionFee
        )
    {
        uint24 activeId = self.slot0.activeId;
        bytes32 binReserves = self.reserveOfBin[id];

        uint256 price = id.getPriceFromId(params.binStep);
        uint256 supply = self.shareOfBin[id];

        (shares, amountsIn) = binReserves.getSharesAndEffectiveAmountsIn(maxAmountsInToBin, price, supply);
        amountsInToBin = amountsIn;

        if (id == activeId) {
            // Fees happens when user try to add liquidity in active bin but with different ratio of (x, y)
            /// eg. current bin is 40/60 (a,b) but user tries to add liquidity with 50/50 ratio
            bytes32 fees = binReserves.getCompositionFees(self.slot0.swapFee, amountsIn, supply, shares);
            compositionFee = fees;
            if (fees != 0) {
                {
                    uint256 userLiquidity = amountsIn.sub(fees).getLiquidity(price);
                    uint256 binLiquidity = binReserves.getLiquidity(price);
                    shares = userLiquidity.mulDivRoundDown(supply, binLiquidity);
                }

                {
                    feeForProtocol = fees.getExternalFeeAmt(self.slot0.protocolFee);
                    if (feeForProtocol != 0) {
                        amountsInToBin = amountsInToBin.sub(feeForProtocol);
                    }
                }
            }
        } else {
            amountsIn.verifyAmounts(activeId, id);
        }

        if (shares == 0 || amountsInToBin == 0) revert BinPool__ZeroShares(id);
        if (supply == 0) _addBinIdToTree(self, id);

        self.reserveOfBin[id] = binReserves.add(amountsInToBin);
    }

    /// @notice Subtract share from user's position and update total share supply of bin
    function _subShare(State storage self, address owner, uint24 binId, uint256 shares) internal {
        self.positions.get(owner, binId).subShare(shares);
        self.shareOfBin[binId] -= shares;
    }

    /// @notice Add share to user's position and update total share supply of bin
    function _addShare(State storage self, address owner, uint24 binId, uint256 shares) internal {
        self.positions.get(owner, binId).addShare(shares);
        self.shareOfBin[binId] += shares;
    }

    /// @notice Enable bin id for a pool
    function _addBinIdToTree(State storage self, uint24 binId) internal {
        (, self.level0) = TreeMath.add(self.level0, self.level1, self.level2, binId);
    }

    /// @notice remove bin id for a pool
    function _removeBinIdToTree(State storage self, uint24 binId) internal {
        (, self.level0) = TreeMath.remove(self.level0, self.level1, self.level2, binId);
    }

    function isNotInitialized(State storage self) internal view returns (bool) {
        return self.slot0.activeId == 0;
    }
}
