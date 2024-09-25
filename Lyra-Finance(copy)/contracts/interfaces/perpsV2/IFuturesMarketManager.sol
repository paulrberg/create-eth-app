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
  
  pragma solidity 0.8.16;

interface IFuturesMarketManager {
  function markets(uint index, uint pageSize) external view returns (address[] memory);

  function markets(uint index, uint pageSize, bool proxiedMarkets) external view returns (address[] memory);

  function numMarkets() external view returns (uint);

  function numMarkets(bool proxiedMarkets) external view returns (uint);

  function allMarkets() external view returns (address[] memory);

  function allMarkets(bool proxiedMarkets) external view returns (address[] memory);

  function marketForKey(bytes32 marketKey) external view returns (address);

  function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

  function totalDebt() external view returns (uint debt, bool isInvalid);
}
