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

contract TickMathEchidnaTest {
    // uniqueness and increasing order
    function checkGetSqrtPriceAtTickInvariants(int24 tick) external pure {
        uint160 price = TickMath.getSqrtPriceAtTick(tick);
        assert(TickMath.getSqrtPriceAtTick(tick - 1) < price && price < TickMath.getSqrtPriceAtTick(tick + 1));
        assert(price >= TickMath.MIN_SQRT_PRICE);
        assert(price <= TickMath.MAX_SQRT_PRICE);
    }

    // the price is always between the returned tick and the returned tick+1
    function checkGetTickAtSqrtPriceInvariants(uint160 price) external pure {
        int24 tick = TickMath.getTickAtSqrtPrice(price);
        assert(price >= TickMath.getSqrtPriceAtTick(tick) && price < TickMath.getSqrtPriceAtTick(tick + 1));
        assert(tick >= TickMath.MIN_TICK);
        assert(tick < TickMath.MAX_TICK);
    }
}
