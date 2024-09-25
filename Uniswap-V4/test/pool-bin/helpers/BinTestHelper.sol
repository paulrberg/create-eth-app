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

import {PoolId, PoolIdLibrary} from "../../../src/types/PoolId.sol";
import {SafeCast} from "../../../src/pool-bin/libraries/math/SafeCast.sol";
import {Constants} from "../../../src/pool-bin/libraries/Constants.sol";
import {LiquidityConfigurations} from "../../../src/pool-bin/libraries/math/LiquidityConfigurations.sol";
import {IBinPoolManager} from "../../../src/pool-bin/interfaces/IBinPoolManager.sol";
import {PackedUint128Math} from "../../../src/pool-bin/libraries/math/PackedUint128Math.sol";
import {BinPoolManager} from "../../../src/pool-bin/BinPoolManager.sol";
import {PoolKey} from "../../../src/types/PoolKey.sol";
import {BalanceDelta, toBalanceDelta} from "../../../src/types/BalanceDelta.sol";
import {BinPool} from "../../../src/pool-bin/libraries/BinPool.sol";
import {PriceHelper} from "../../../src/pool-bin/libraries/PriceHelper.sol";
import {FeeHelper} from "../../../src/pool-bin/libraries/FeeHelper.sol";

abstract contract BinTestHelper is Test {
    using PoolIdLibrary for PoolKey;
    using SafeCast for uint256;
    using PackedUint128Math for bytes32;

    uint24 internal constant ID_ONE = 2 ** 23;
    uint16 internal constant DEFAULT_BIN_STEP = 10;

    function addLiquidityToBin(
        PoolKey memory key,
        BinPoolManager poolManager,
        address from,
        uint24 id,
        uint256 amountX,
        uint256 amountY,
        uint64 distribX, // 1e18 imply all amountX goes into bin
        uint64 distribY, // 1e17 imply 1/10 of amountY goes into bin
        bytes memory hookData
    ) public returns (BalanceDelta delta, BinPool.MintArrays memory array) {
        bytes32[] memory liquidityConfigurations = new bytes32[](1);
        liquidityConfigurations[0] = LiquidityConfigurations.encodeParams(distribX, distribY, id);

        IBinPoolManager.MintParams memory params = IBinPoolManager.MintParams({
            liquidityConfigs: liquidityConfigurations,
            amountIn: PackedUint128Math.encode(amountX.safe128(), amountY.safe128())
        });

        vm.prank(from);
        (delta, array) = poolManager.mint(key, params, hookData);
    }

    function addLiquidity(
        PoolKey memory key,
        BinPoolManager poolManager,
        address from,
        uint24 activeId,
        uint256 amountX,
        uint256 amountY,
        uint8 nbBinX,
        uint8 nbBinY
    ) public returns (BalanceDelta delta, BinPool.MintArrays memory array) {
        (IBinPoolManager.MintParams memory params,) =
            _getMultipleBinMintParams(activeId, amountX, amountY, nbBinX, nbBinY);

        vm.prank(from);
        (delta, array) = poolManager.mint(key, params, "0x00");
    }

    function _getSingleBinMintParams(uint24 binId, uint256 amountX, uint256 amountY)
        internal
        pure
        returns (IBinPoolManager.MintParams memory params)
    {
        (params,) = _getMultipleBinMintParams(binId, amountX, amountY, 1, 1);
    }

    /// @dev get mint param for single sided (either all tokenX or tokenY)
    /// @param left if true, indicate add to the left side of activeId which would be tokenY. vice verse if false, add tokenX
    function _getCustomSingleSidedBinMintParam(
        uint24 binId,
        uint256 amount,
        bool left // adding to the left side of activeId will be tokenY
    ) internal pure returns (IBinPoolManager.MintParams memory params) {
        bytes32[] memory liquidityConfigurations = new bytes32[](1);

        if (left) {
            liquidityConfigurations[0] = LiquidityConfigurations.encodeParams(0, 1e18, binId);

            params = IBinPoolManager.MintParams({
                liquidityConfigs: liquidityConfigurations,
                amountIn: PackedUint128Math.encode(0, amount.safe128())
            });
        } else {
            liquidityConfigurations[0] = LiquidityConfigurations.encodeParams(1e18, 0, binId);

            params = IBinPoolManager.MintParams({
                liquidityConfigs: liquidityConfigurations,
                amountIn: PackedUint128Math.encode(amount.safe128(), 0)
            });
        }
    }

    /// @dev get mint params for multiple mint param
    /// @param binId - active binId
    /// @param amountX - total tokenX amount
    /// @param amountY - total tokenY amount
    /// @param nbBinX - number of bins to the right (inclusive of active bin)
    /// @param nbBinY - number of bins to the left (inclusive of active bin)
    function _getMultipleBinMintParams(uint24 binId, uint256 amountX, uint256 amountY, uint8 nbBinX, uint8 nbBinY)
        internal
        pure
        returns (IBinPoolManager.MintParams memory params, uint24[] memory binIds)
    {
        uint256 total = getTotalBins(nbBinX, nbBinY); // nbBinX + nbBinY - 1

        bytes32[] memory liquidityConfigurations = new bytes32[](total);
        binIds = new uint24[](total);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(binId, i, nbBinY); // all the binId from left to right ::  id = activeId + i - nBinY + 1
            binIds[i] = id;

            uint64 distribX = id >= binId && nbBinX > 0 ? (Constants.PRECISION / nbBinX).safe64() : 0;
            uint64 distribY = id <= binId && nbBinY > 0 ? (Constants.PRECISION / nbBinY).safe64() : 0;

            liquidityConfigurations[i] = LiquidityConfigurations.encodeParams(distribX, distribY, id);
        }

        params = IBinPoolManager.MintParams({
            liquidityConfigs: liquidityConfigurations,
            amountIn: PackedUint128Math.encode(amountX.safe128(), amountY.safe128())
        });
    }

    function removeLiquidityFromBin(
        PoolKey memory key,
        BinPoolManager poolManager,
        address from,
        uint24 binId,
        uint256 amountsToBurn,
        bytes memory hookData
    ) public returns (BalanceDelta delta) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amtToBurn = new uint256[](1);

        ids[0] = binId;
        amtToBurn[0] = amountsToBurn;

        IBinPoolManager.BurnParams memory params = IBinPoolManager.BurnParams({ids: ids, amountsToBurn: amtToBurn});

        vm.prank(from);
        delta = poolManager.burn(key, params, hookData);
    }

    function removeLiquidity(
        PoolKey memory key,
        BinPoolManager poolManager,
        address from,
        uint256[] memory ids,
        uint256[] memory amountsToBurn
    ) public {
        IBinPoolManager.BurnParams memory params = IBinPoolManager.BurnParams({ids: ids, amountsToBurn: amountsToBurn});

        vm.prank(from);
        poolManager.burn(key, params, "0x00");
    }

    /// @dev get burn params assuming user is burning all liquidity at the binId
    /// @param sharePercentage - 100 means burn 100% of user share in the bin
    function _getSingleBinBurnLiquidityParams(
        PoolKey memory _key,
        BinPoolManager pm,
        uint24 binId,
        address from,
        uint256 sharePercentage
    ) internal view returns (IBinPoolManager.BurnParams memory params) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory balances = new uint256[](1);

        ids[0] = binId;
        balances[0] = (pm.getPosition(_key.toId(), from, binId).share * sharePercentage) / 100;

        params = IBinPoolManager.BurnParams({ids: ids, amountsToBurn: balances});
    }

    /// @dev get burn params assuming user is burning all liquidity at the binId
    /// @param sharePercentage - 100 means burn 100% of user share in the bin
    function _getMultipleBinBurnLiquidityParams(
        PoolKey memory _key,
        BinPoolManager pm,
        uint24[] memory binIds,
        address from,
        uint256 sharePercentage
    ) internal view returns (IBinPoolManager.BurnParams memory params) {
        uint256[] memory ids = new uint256[](binIds.length);
        uint256[] memory balances = new uint256[](binIds.length);

        for (uint256 i; i < binIds.length; i++) {
            ids[i] = binIds[i];
            balances[i] = (pm.getPosition(_key.toId(), from, binIds[i]).share * sharePercentage) / 100;
        }

        params = IBinPoolManager.BurnParams({ids: ids, amountsToBurn: balances});
    }

    function getTotalBins(uint8 nbBinX, uint8 nbBinY) public pure returns (uint256) {
        return nbBinX > 0 && nbBinY > 0 ? nbBinX + nbBinY - 1 : nbBinX + nbBinY;
    }

    function getId(uint24 activeId, uint256 i, uint8 nbBinY) public pure returns (uint24) {
        uint256 id = activeId + i;
        id = nbBinY > 0 ? id - nbBinY + 1 : id;

        return id.safe24();
    }
}
