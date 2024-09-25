/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V3?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/UnsafeMath.sol';

contract UnsafeMathEchidnaTest {
    function checkDivRoundingUp(uint256 x, uint256 d) external pure {
        require(d > 0);
        uint256 z = UnsafeMath.divRoundingUp(x, d);
        uint256 diff = z - (x / d);
        if (x % d == 0) {
            assert(diff == 0);
        } else {
            assert(diff == 1);
        }
    }
}
