/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Olympus-DAO?utm=code
  */
  
  // SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "../libraries/SafeERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../types/OlympusAccessControlledV2.sol";

/// @notice This contract handles migrating lps from sushiswap to uniswap v2
///         to make use of this contract ensure contract address is RESERVEMANAGER IN OHM Treasury
contract SushiMigrator is OlympusAccessControlledV2 {
    using SafeERC20 for IERC20;

    struct Amounts {
        uint128 sushiLpBeforeMigration;
        uint128 leftoverSushiLpAfterMigration;
        uint128 uniPoolToken0AddedToPool;
        uint128 uniPoolToken1AddedToPool;
        uint128 uniPoolLpReceived;
        uint128 uniPoolToken0ReturnedToTreasury;
        uint128 uniPoolToken1ReturnedToTreasury;
    }

    uint256 public txCount;

    mapping(uint256 => Amounts) public amountsByMigrationId;

    address immutable treasury = 0x9A315BdF513367C0377FB36545857d12e85813Ef;

    constructor(address _olympusAuthority) OlympusAccessControlledV2(IOlympusAuthority(_olympusAuthority)) {}

    /// @notice Takes lp from treasury, remove liquidity from sushi, adds liquidity to uniswap v2
    /// @param sushiRouter_ sushi router addres
    /// @param uniRouter_ uni router address
    /// @param sushiLpAddress_ sushi lp address
    /// @param uniswapLpAddress_ uni lp address
    /// @param amount_ lp amount to get from treasury and amount of liquidity to remove
    /// @param removeLiquiditySlippage_ slippage used when removing liquidity....i.e 95% will be 950
    /// @param addLiquiditySlippage_ slippage used when adding liquidity....i.e 95% will be 950
    function executeTx(
        address sushiRouter_,
        address uniRouter_,
        address sushiLpAddress_,
        address uniswapLpAddress_,
        uint256 amount_,
        uint256 removeLiquiditySlippage_,
        uint256 addLiquiditySlippage_
    ) external onlyGovernor {
        ITreasury(treasury).manage(sushiLpAddress_, amount_);

        uint256 amount = IUniswapV2Pair(sushiLpAddress_).balanceOf(address(this));

        (uint256 amountOHM, uint256 amountToken) = removeLiquidity(
            sushiLpAddress_,
            sushiRouter_,
            amount,
            removeLiquiditySlippage_
        );
        uint256 amountAfterTx = IUniswapV2Pair(sushiLpAddress_).balanceOf(address(this));
        (address token0, address token1, , ) = getTokenInfo(uniswapLpAddress_, address(this));

        (uint256 amountA, uint256 amountB, uint256 liquidity) = addLiquidity(
            uniRouter_,
            token0,
            token1,
            amountOHM,
            amountToken,
            addLiquiditySlippage_
        );

        amountsByMigrationId[txCount] = Amounts({
            sushiLpBeforeMigration: uint128(amount),
            leftoverSushiLpAfterMigration: uint128(amountAfterTx),
            uniPoolToken0AddedToPool: uint128(amountOHM),
            uniPoolToken1AddedToPool: uint128(amountToken),
            uniPoolLpReceived: uint128(liquidity),
            uniPoolToken0ReturnedToTreasury: uint128(amountA),
            uniPoolToken1ReturnedToTreasury: uint128(amountB)
        });

        txCount++;
    }

    /// @notice Removes liquidity from sushiswap
    /// @param pairAddr_ lp address
    /// @param router_ sushiswaprouter address
    /// @param amount_ amount of lp to remove
    /// @param slippage_ slippage to use
    function removeLiquidity(
        address pairAddr_,
        address router_,
        uint256 amount_,
        uint256 slippage_
    ) internal returns (uint256 amountOHM, uint256 amountToken) {
        (address token0, address token1, uint256 token0PoolBalance, uint256 token1PoolBalance) = getTokenInfo(
            pairAddr_,
            pairAddr_
        );

        uint256 amount1Min = (token0PoolBalance * amount_) / IUniswapV2Pair(pairAddr_).totalSupply();
        uint256 amount2Min = (token1PoolBalance * amount_) / IUniswapV2Pair(pairAddr_).totalSupply();

        IUniswapV2Pair(pairAddr_).approve(router_, amount_);

        (amountOHM, amountToken) = IUniswapV2Router(router_).removeLiquidity(
            token0,
            token1,
            amount_,
            (amount1Min * slippage_) / 1000,
            (amount2Min * slippage_) / 1000,
            address(this),
            type(uint256).max
        );
    }

    /// @notice Adds liquidity to uniswap pool
    /// @param router_ uniswap router address
    /// @param token0_ token address
    /// @param token1_ token address
    /// @param contractToken0Bal_ max amount of token 0 to be added as liquidity
    /// @param contractToken1Bal_ max amount of token 1 to be added as liquidity
    /// @param slippage_ slippage to use
    function addLiquidity(
        address router_,
        address token0_,
        address token1_,
        uint256 contractToken0Bal_,
        uint256 contractToken1Bal_,
        uint256 slippage_
    )
        internal
        returns (
            uint256 tokenAContractBalance,
            uint256 tokenBContractBalance,
            uint256 liquidity
        )
    {
        IERC20 token0 = IERC20(token0_);
        IERC20 token1 = IERC20(token1_);

        token0.approve(router_, contractToken0Bal_);
        token1.approve(router_, contractToken1Bal_);

        (, , liquidity) = IUniswapV2Router(router_).addLiquidity(
            token0_,
            token1_,
            contractToken0Bal_,
            contractToken1Bal_,
            (contractToken0Bal_ * slippage_) / 1000,
            (contractToken1Bal_ * slippage_) / 1000,
            treasury,
            type(uint256).max
        );

        tokenAContractBalance = token0.balanceOf((address(this)));
        tokenBContractBalance = token1.balanceOf((address(this)));

        if (tokenAContractBalance > 0) {
            token0.safeTransfer(treasury, tokenAContractBalance);
        }

        if (tokenBContractBalance > 0) {
            token1.safeTransfer(treasury, tokenBContractBalance);
        }
    }

    /// @notice Returns token 0, token 1, contract balance of token 0, contract balance of token 1
    /// @param lp_ lp address
    /// @return address, address, uint, uint
    function getTokenInfo(address lp_, address addr_)
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        address token0 = IUniswapV2Pair(lp_).token0();
        address token1 = IUniswapV2Pair(lp_).token1();

        uint256 token0Bal = IERC20(token0).balanceOf(addr_);
        uint256 token1Bal = IERC20(token1).balanceOf(addr_);

        return (token0, token1, token0Bal, token1Bal);
    }
}
