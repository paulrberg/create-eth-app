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
  
  //SPDX-License-Identifier:ISC

pragma solidity 0.8.16;

// For full documentation refer to @lyrafinance/protocol/contracts/periphery/GWAVOracle.sol";

interface IGWAVOracle {
  function ivGWAV(uint boardId, uint secondsAgo) external view returns (uint);

  function skewGWAV(uint strikeId, uint secondsAgo) external view returns (uint);

  function volGWAV(uint strikeId, uint secondsAgo) external view returns (uint);

  function deltaGWAV(uint strikeId, uint secondsAgo) external view returns (int callDelta);

  function vegaGWAV(uint strikeId, uint secondsAgo) external view returns (uint vega);

  function optionPriceGWAV(uint strikeId, uint secondsAgo) external view returns (uint callPrice, uint putPrice);
}
