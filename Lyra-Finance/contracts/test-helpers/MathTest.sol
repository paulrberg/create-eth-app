/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

import "../libraries/FixedPointMathLib.sol";
import "./OldBlackScholesMath.sol";

contract MathTest {
  function lnV1(int x) external pure returns (int r) {
    return FixedPointMathLib.ln(x);
  }

  function expV1(int x) external pure returns (uint r) {
    return FixedPointMathLib.exp(x);
  }

  function lnV2(uint x) external pure returns (int r) {
    return OldBlackScholesMath.ln(x);
  }

  function expV2(int x) external pure returns (uint r) {
    return OldBlackScholesMath.exp(x);
  }
}
