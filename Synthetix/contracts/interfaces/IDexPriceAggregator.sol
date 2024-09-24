/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

// https://sips.synthetix.io/sips/sip-120/
// Uniswap V3 based DecPriceAggregator (unaudited) e.g. https://etherscan.io/address/0xf120f029ac143633d1942e48ae2dfa2036c5786c#code
// https://github.com/sohkai/uniswap-v3-spot-twap-oracle
//  inteface: https://github.com/sohkai/uniswap-v3-spot-twap-oracle/blob/8f9777a6160a089c99f39f2ee297119ee293bc4b/contracts/interfaces/IDexPriceAggregator.sol
//  implementation: https://github.com/sohkai/uniswap-v3-spot-twap-oracle/blob/8f9777a6160a089c99f39f2ee297119ee293bc4b/contracts/DexPriceAggregatorUniswapV3.sol
interface IDexPriceAggregator {
    function assetToAsset(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint twapPeriod
    ) external view returns (uint amountOut);
}
