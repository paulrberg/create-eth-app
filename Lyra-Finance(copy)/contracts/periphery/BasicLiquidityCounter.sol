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

// Inherited
import "../synthetix/Owned.sol";

/**
 * @title BasicFeeCounter
 */
contract BasicLiquidityCounter is Owned {
  address public liquidityToken;
  mapping(address => uint) public userLiquidity;

  constructor() Owned() {}

  /**
   * @dev
   * param lpToken liquidity token address
   */
  function setLiquidityToken(address lpToken) external onlyOwner {
    liquidityToken = lpToken;
  }

  /**
   * @dev
   * param trader the address of the trader that is exchaning liquidity
   * param amount the amount of liquidity tokens that are being exchanged
   */
  function addTokens(address trader, uint amount) external onlyLiquidityToken {
    userLiquidity[trader] += amount;
  }

  /**
   * @dev
   * param trader the address of the trader that is exchaning liquidity
   * param amount the amount of liquidity tokens that are being exchanged
   */
  function removeTokens(address trader, uint amount) external onlyLiquidityToken {
    userLiquidity[trader] -= amount;
  }

  modifier onlyLiquidityToken() {
    require(liquidityToken == msg.sender, "can only be called by LiquidityToken");
    _;
  }
}
