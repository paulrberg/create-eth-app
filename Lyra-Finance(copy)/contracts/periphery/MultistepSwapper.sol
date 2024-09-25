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
import "Lyra-Finance/openzeppelin-contracts-4.4.1/security/ReentrancyGuard.sol";

// Interfaces
import "../interfaces/ISwapRouter.sol";
import "../interfaces/ISynthetix.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/token/ERC20/IERC20.sol";

/**
 * @title SwapRouter
 * @author Lyra
 * @dev Swap between tokens and synths using uniswap router and synthetix exchanger
 */
contract MultistepSwapper is ReentrancyGuard {
  ISwapRouter internal swapRouter;
  ISynthetix internal synthetix;

  bool internal initialized = false;
  mapping(IERC20 => bool) internal approved;
  uint internal constant UINT_MAX = ~uint(0);

  enum SwapType {
    Synthetix,
    Uniswap
  }

  struct Swap {
    SwapType swapType;
    address tokenOut;
    bytes32 tokenOutCurrencyKey;
    uint24 poolFee;
  }

  constructor() {}

  /**
   * @dev Initialize the contract.
   */
  function init(ISwapRouter _swapRouter, ISynthetix _synthetix) external {
    require(!initialized, "already initialized");
    swapRouter = _swapRouter;
    synthetix = _synthetix;
    initialized = true;
  }

  /**
   * @dev Swaps `amountIn` of one token for as much as possible of another token
   * @param tokenIn The token address being swapped from
   * @param tokenInCurrencyKey The synth currency key for `tokenIn`, set to zero if `tokenIn` is not a synth
   * @param amountIn The amount of `tokenIn` to be swapped
   * @param swaps The swap route encoded into an array of `Swap` structs
   * @param amountOutMinimum The minimum amount of the last `Swap` struct `tokenOut` token that must be returned
   * @return amountOut The amount of the received token
   */
  function swap(
    IERC20 tokenIn,
    bytes32 tokenInCurrencyKey,
    uint amountIn,
    Swap[] calldata swaps,
    uint amountOutMinimum
  ) external payable nonReentrant returns (uint amountOut) {
    require(swaps.length > 0, "0 length swaps");
    if (!approved[tokenIn]) {
      tokenIn.approve(address(swapRouter), UINT_MAX);
      approved[tokenIn] = true;
    }
    tokenIn.transferFrom(msg.sender, address(this), amountIn);
    amountOut = amountIn;
    bytes memory path = "";
    for (uint i = 0; i < swaps.length; ++i) {
      require(uint(swaps[i].swapType) <= uint(SwapType.Uniswap), "Invalid swaptype");
      if (swaps[i].swapType == SwapType.Synthetix) {
        amountOut = synthetix.exchange(tokenInCurrencyKey, amountOut, swaps[i].tokenOutCurrencyKey);
      } else if (swaps[i].swapType == SwapType.Uniswap) {
        if (path.length == 0) {
          // initialize byte path
          path = abi.encodePacked(address(tokenIn));
        }
        // append current byte path
        path = abi.encodePacked(path, swaps[i].poolFee, swaps[i].tokenOut);
        if (i == swaps.length - 1 || (i < swaps.length - 1 && swaps[i + 1].swapType != SwapType.Uniswap)) {
          amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
              path: path,
              recipient: address(this),
              deadline: block.timestamp,
              amountIn: amountOut,
              amountOutMinimum: 0
            })
          );
          path = "";
        }
      }
      tokenIn = IERC20(swaps[i].tokenOut);
      tokenInCurrencyKey = swaps[i].tokenOutCurrencyKey;
    }
    require(amountOut >= amountOutMinimum, "amountOut lower than minimum");
    tokenIn.transfer(msg.sender, amountOut);
    return amountOut;
  }
}
