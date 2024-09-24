/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ChainLink?utm=code
  */
  
  pragma solidity ^0.5.0;

library SignedSafeMath {

  /**
   * @dev Adds two int256s and makes sure the result doesn't overflow. Signed
   * integers aren't supported by the SafeMath library, thus this method
   * @param _a The first number to be added
   * @param _a The second number to be added
   */
  function add(int256 _a, int256 _b)
    internal
    pure
    returns (int256)
  {
    // solium-disable-next-line zeppelin/no-arithmetic-operations
    int256 c = _a + _b;
    require((_b >= 0 && c >= _a) || (_b < 0 && c < _a), "SignedSafeMath: addition overflow");

    return c;
  }
}