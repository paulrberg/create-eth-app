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

import {TickMath} from "../libraries/TickMath.sol";

contract TickMathTest {
    function getSqrtPriceAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtPriceAtTick(tick);
    }

    function getGasCostOfGetSqrtPriceAtTick(int24 tick) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        TickMath.getSqrtPriceAtTick(tick);
        return gasBefore - gasleft();
    }

    function getTickAtSqrtPrice(uint160 sqrtPriceX96) external pure returns (int24) {
        return TickMath.getTickAtSqrtPrice(sqrtPriceX96);
    }

    function getGasCostOfGetTickAtSqrtPrice(uint160 sqrtPriceX96) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        TickMath.getTickAtSqrtPrice(sqrtPriceX96);
        return gasBefore - gasleft();
    }

    function MIN_SQRT_PRICE() external pure returns (uint160) {
        return TickMath.MIN_SQRT_PRICE;
    }

    function MAX_SQRT_PRICE() external pure returns (uint160) {
        return TickMath.MAX_SQRT_PRICE;
    }

    function MIN_TICK() external pure returns (int24) {
        return TickMath.MIN_TICK;
    }

    function MAX_TICK() external pure returns (int24) {
        return TickMath.MAX_TICK;
    }
}
