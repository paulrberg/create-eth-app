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
  
  //SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "../../types/Currency.sol";
import {IFees} from "../../interfaces/IFees.sol";
import {PoolId} from "../../types/PoolId.sol";
import {PoolKey} from "../../types/PoolKey.sol";
import {BalanceDelta} from "../../types/BalanceDelta.sol";
import {IPoolManager} from "../../interfaces/IPoolManager.sol";
import {IExtsload} from "../../interfaces/IExtsload.sol";
import {IBinHooks} from "./IBinHooks.sol";
import {BinPosition, BinPool} from "../libraries/BinPool.sol";

interface IBinPoolManager is IFees, IPoolManager, IExtsload {
    /// @notice PoolManagerMismatch is thrown when pool manager specified in the pool key does not match current contract
    error PoolManagerMismatch();

    /// @notice Pool binStep cannot be lesser than 1. Otherwise there will be no price jump between bin
    error BinStepTooSmall();

    /// @notice Pool binstep cannot be greater than the limit set at MAX_BIN_STEP
    error BinStepTooLarge();

    /// @notice Error thrown when owner set max bin step too small
    error MaxBinStepTooSmall(uint16 maxBinStep);

    /// @notice Error thrown when Unauthorized caller
    error UnauthorizedCaller();

    /// @notice Returns the constant representing the max bin step
    /// @return maxBinStep a value of 100 would represent a 1% price jump between bin (limit can be raised by owner)
    function MAX_BIN_STEP() external view returns (uint16);

    /// @notice Returns the constant representing the min bin step
    /// @dev 1 would represent a 0.01% price jump between bin
    function MIN_BIN_STEP() external view returns (uint16);

    /// @notice Emitted when a new pool is initialized
    /// @param id The abi encoded hash of the pool key struct for the new pool
    /// @param currency0 The first currency of the pool by address sort order
    /// @param currency1 The second currency of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param binStep The bin step in basis point, used to calculate log(1 + binStep / 10_000)
    /// @param hooks The hooks contract address for the pool, or address(0) if none
    event Initialize(
        PoolId indexed id,
        Currency indexed currency0,
        Currency indexed currency1,
        uint24 fee,
        uint16 binStep,
        IBinHooks hooks
    );

    /// @notice Emitted for swaps between currency0 and currency1
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param amount0 The delta of the currency0 balance of the pool
    /// @param amount1 The delta of the currency1 balance of the pool
    /// @param activeId The activeId of the pool after the swap
    /// @param fee Total swap fee - 10_000 = 1%
    /// @param pFee Protocol fee from the swap: token0 and token1 amount
    event Swap(
        PoolId indexed id,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint24 activeId,
        uint24 fee,
        bytes32 pFee
    );

    /// @notice Emitted when liquidity is added
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param ids List of binId with liquidity added
    /// @param amounts List of amount added to each bin
    /// @param compositionFee fee occurred
    /// @param pFee Protocol fee from the swap: token0 and token1 amount
    event Mint(
        PoolId indexed id,
        address indexed sender,
        uint256[] ids,
        bytes32[] amounts,
        bytes32 compositionFee,
        bytes32 pFee
    );

    /// @notice Emitted when liquidity is removed
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param ids List of binId with liquidity removed
    /// @param amounts List of amount removed from each bin
    event Burn(PoolId indexed id, address indexed sender, uint256[] ids, bytes32[] amounts);

    /// @notice Emitted when donate happen
    /// @param id The abi encoded hash of the pool key struct for the pool that was modified
    /// @param sender The address that modified the pool
    /// @param amount0 The delta of the currency0 balance of the pool
    /// @param amount1 The delta of the currency1 balance of the pool
    /// @param binId The donated bin id
    event Donate(PoolId indexed id, address indexed sender, int128 amount0, int128 amount1, uint24 binId);

    /// @notice Emitted when bin step is updated
    event SetMaxBinStep(uint16 maxBinStep);

    /// @notice Emitted when masterChef is updated
    event SetMasterChef(address masterChef);

    /// @notice Emitted when LMPool is set for a pool
    event SetLmPool(PoolId indexed id, address lmPool);

    struct MintParams {
        bytes32[] liquidityConfigs;
        /// @dev amountIn intended
        bytes32 amountIn;
    }

    struct BurnParams {
        /// @notice id of the bin from which to withdraw
        uint256[] ids;
        /// @notice amount of share to burn for each bin
        uint256[] amountsToBurn;
    }

    /// @notice Get the current value in slot0 of the given pool
    function getSlot0(PoolId id) external view returns (uint24 activeId, uint16 protocolFee, uint24 swapFee);

    /// @notice Returns the reserves of a bin
    /// @param id The id of the bin
    /// @return binReserveX The reserve of token X in the bin
    /// @return binReserveY The reserve of token Y in the bin
    function getBin(PoolId id, uint24 binId) external view returns (uint128 binReserveX, uint128 binReserveY);

    /// @notice Returns the positon of owner at a binId
    /// @param id The id of PoolKey
    /// @param owner Address of the owner
    /// @param binId The id of the bin
    function getPosition(PoolId id, address owner, uint24 binId)
        external
        view
        returns (BinPosition.Info memory position);

    /// @notice Returns the next non-empty bin
    /// @dev The next non-empty bin is the bin with a higher (if swapForY is true) or lower (if swapForY is false)
    ///     id that has a non-zero reserve of token X or Y.
    /// @param swapForY Whether the swap is for token Y (true) or token X (false)
    /// @param id The id of the bin
    /// @return nextId The id of the next non-empty bin
    function getNextNonEmptyBin(PoolId id, bool swapForY, uint24 binId) external view returns (uint24 nextId);

    /// @notice Initialize a new pool
    function initialize(PoolKey memory key, uint24 activeId, bytes calldata hookData) external;

    /// @notice Add liquidity to a pool
    /// @return delta BalanceDelta, will be positive indicating how much total amt0 and amt1 liquidity added
    /// @return mintArray Liquidity added in which ids, how much amt0, amt1 and how much liquidity added
    function mint(PoolKey memory key, IBinPoolManager.MintParams calldata params, bytes calldata hookData)
        external
        returns (BalanceDelta delta, BinPool.MintArrays memory mintArray);

    /// @notice Remove liquidity from a pool
    function burn(PoolKey memory key, IBinPoolManager.BurnParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta delta);

    /// @notice Peform a swap to a pool
    function swap(PoolKey memory key, bool swapForY, uint128 amountIn, bytes calldata hookData)
        external
        returns (BalanceDelta delta);

    /// @notice Donate the given currency amounts to the pool with the given pool key.
    /// @return delta Positive amt means the caller owes the vault, while negative amt means the vault owes the caller
    /// @return binId The donated bin id, which is the current active bin id. if no-op happen, binId will be 0
    function donate(PoolKey memory key, uint128 amount0, uint128 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta delta, uint24 binId);

    /// @notice Given amountOut, calculate how much amountIn is required for a swap
    /// @param swapForY if true, swap token X for Y. if false, swap token Y for X
    /// @param amountOut amount of tokenOut
    /// @return amountIn total amount in required
    /// @return amountOutLeft total amount out left
    /// @return fee total fee incurred
    function getSwapIn(PoolKey memory key, bool swapForY, uint128 amountOut)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    /// @notice Given amountIn, calculate how much amountOut
    /// @param swapForY if true, swap token X for Y. if false, swap token Y for X
    /// @param amountIn amount of tokenX (if swapForY) or amount of tokenY (if !swapForY)
    /// @return amountInLeft total amount in left
    /// @return amountOut total amount out
    /// @return fee total fee incurred
    function getSwapOut(PoolKey memory key, bool swapForY, uint128 amountIn)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    /// @notice Set max bin step for BinPool
    /// @dev To be realistic, its highly unlikely a pool type with > 100 bin step is required. (>1% price jump per bin)
    function setMaxBinStep(uint16 maxBinStep) external;

    /// @notice Set masterChef address, in case when farming incentive for a pool begin.
    /// @dev If farming is migrated to off-chain in the future, masterChef can be reverted to address(0)
    function setMasterChef(address masterChef) external;

    /// @notice Return the masterChef address set
    function masterChef() external returns (address);

    /// @notice Set liquidity mining pool for a poolId. if a pool has farmining incentive, masterChef
    ///         will deploy and assign an LM Pool to a pool.
    /// @dev The only reason why owner call is when we no longer rely on lmPool for farming incentives or
    ///      there is an issue with the existing lmPool and we need to change it.
    function setLmPool(PoolKey memory key, address lmPool) external;

    /// @notice Return the lmPool for a poolId, address(0) if not set
    function getLmPool(PoolId id) external view returns (address);
}
