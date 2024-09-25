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

import "../synthetix/DecimalMath.sol";
import "../interfaces/ICurve.sol";
import "./TestERC20.sol";
import "../synthetix/Owned.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Curve
contract TestCurve is ICurve, Owned {
  using DecimalMath for uint;

  mapping(address => uint) public rates;
  mapping(int128 => address) public curveStables;

  constructor() {}

  function setRate(address token, uint rate) external onlyOwner {
    rates[token] = rate;
  }

  // function addCurveStable(address stablecoin, int128 desiredIndex) external onlyOwner {
  //   curveStables[desiredIndex] = stablecoin;
  // }

  function get_best_rate(
    address _from,
    address _to,
    uint _amount
  ) external view returns (address pool, uint amountOut) {
    // grab the rates of each token
    uint _fromRate = rates[address(_from)];
    uint _toRate = rates[address(_to)];

    amountOut = (_amount * _toRate) / _fromRate;
    pool = address(this);
  }

  function exchange_with_best_rate(
    address _from,
    address _to,
    uint _amount,
    uint _expected,
    address _receiver
  ) external payable override returns (uint amountOut) {
    // turn the _from into an ERC20 token
    // turn the _to into an ERC20 token
    TestERC20 fromToken = TestERC20(_from);
    TestERC20 toToken = TestERC20(_to);

    // if either _from or _to is zero throw error
    require(
      fromToken != TestERC20(address(0)) && toToken != TestERC20(address(0)),
      "token in or token out is zero address"
    );

    // if balance of the sender is less than _amount throw error
    uint bal = fromToken.balanceOf(_receiver);
    require(bal >= _amount, "not enough to exchange");

    // burn the tokens sent
    fromToken.burn(_receiver, _amount);

    // grab the rates of each token
    uint _fromRate = rates[address(_from)];
    uint _toRate = rates[address(_to)];

    // if the amount we get out is less than expected throw error
    // amountOut = (_amount * _fromRate) / _toRate;
    amountOut = (_amount * _toRate) / _fromRate;
    require(amountOut >= _expected, "not enough expected");

    // convert amount out to be the number of decimals that from has
    if (ERC20(_from).decimals() != 18) {
      amountOut = amountOut * (10 ** (ERC20(_to).decimals() - fromToken.decimals()));
    }

    // mint the amountOut
    toToken.mint(_receiver, amountOut);
    return amountOut;
  }

  // old exchanging function, currently unused
  function exchange_underlying(
    int128 _from,
    int128 _to,
    uint _amount,
    uint _expected
  ) external payable override returns (uint amountOut) {
    // turn the _from into an ERC20 token
    // turn the _to into an ERC20 token
    TestERC20 fromToken = TestERC20(curveStables[_from]);
    TestERC20 toToken = TestERC20(curveStables[_to]);

    // if either _from or _to is zero throw error
    require(
      fromToken != TestERC20(address(0)) && toToken != TestERC20(address(0)),
      "token in or token out is zero address"
    );

    // if balance of the sender is less than _amount throw error
    uint bal = fromToken.balanceOf(msg.sender);
    require(bal >= _amount, "not enough to exchange");

    // burn the tokens sent
    fromToken.burn(msg.sender, _amount);

    // grab the rates of each token
    uint _fromRate = rates[address(curveStables[_from])];
    uint _toRate = rates[address(curveStables[_to])];

    // if the amount we get out is less than expected throw error
    // amountOut = (_amount * _fromRate) / _toRate;
    amountOut = (_amount * _toRate) / _fromRate;
    require(amountOut >= _expected, "not enough expected");

    // mint the amountOut
    toToken.mint(msg.sender, amountOut);
    return amountOut;
  }

  function _getDecimals(ERC20 token) internal view returns (uint8) {
    uint8 decimals;
    try token.decimals() returns (uint8 dec) {
      decimals = dec;
    } catch {
      decimals = 18;
    }
    return decimals;
  }
}
