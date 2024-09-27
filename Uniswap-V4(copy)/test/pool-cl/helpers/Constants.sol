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

library Constants {
    uint160 public constant SQRT_RATIO_1_1 = 79228162514264337593543950336;
    uint160 public constant SQRT_RATIO_1_2 = 56022770974786139918731938227;
    uint160 public constant SQRT_RATIO_1_4 = 39614081257132168796771975168;
    uint160 public constant SQRT_RATIO_2_1 = 112045541949572279837463876454;
    uint160 public constant SQRT_RATIO_4_1 = 158456325028528675187087900672;
    uint160 public constant SQRT_RATIO_121_100 = 87150978765690771352898345369;

    uint256 constant MAX_UINT256 = type(uint256).max;
    uint128 constant MAX_UINT128 = type(uint128).max;
    uint160 constant MAX_UINT160 = type(uint160).max;

    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = 887272;
}
