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

import "../synthetix/SignedDecimalMath.sol";
import "../synthetix/DecimalMath.sol";

library OldBlackScholesMath {
  using DecimalMath for uint;
  using SignedDecimalMath for int;

  /// @dev Internally this library uses 18 decimals of precision
  uint private constant UNIT = 1e18;
  /// @dev Below this value, the result is always 0
  int private constant MIN_EXP = -41 * int(UNIT);
  /// @dev Above this value precision is lost, and uint256s cannot handle the size
  uint private constant MAX_EXP = 100 * UNIT;
  uint private constant LN_2 = 693147180559945309;

  /**
   * @dev Returns the floor relative to UINT
   */
  function floor(uint x) internal pure returns (uint) {
    return x - (x % UNIT);
  }

  /**
   * @dev Returns the natural log of the value using Halley's method.
   * 0.000001 -> 1000000+ work fine
   * this contract will deal with values between 0.3-10, so very safe for this method
   */
  function ln(uint x) internal pure returns (int) {
    int res;
    int next;

    for (uint i = 0; i < 8; ++i) {
      int e = int(exp(res));

      next = res + ((int(x) - e) * 2).divideDecimalRound(int(x) + e);

      if (next == res) {
        break;
      }
      res = next;
    }

    return res;
  }

  /**
   * @dev Returns the exponent of the value using taylor expansion with range reduction.
   */
  function exp(uint x) internal pure returns (uint) {
    if (x == 0) {
      return UNIT;
    }
    require(x <= MAX_EXP, "cannot handle exponents greater than 100");

    uint k = floor(x.divideDecimalRound(LN_2)) / UNIT;
    uint p = 2 ** k;
    uint r = x - (k * LN_2);

    uint _t = UNIT;

    uint lastT;
    for (uint8 i = 16; i > 0; i--) {
      _t = _t.multiplyDecimalRound(r / i) + UNIT;
      if (_t == lastT) {
        break;
      }
      lastT = _t;
    }

    return p * _t;
  }

  /**
   * @dev Returns the exponent of the value using taylor expansion with range reduction,
   * with support for negative numbers.
   */
  function exp(int x) internal pure returns (uint) {
    if (0 <= x) {
      return exp(uint(x));
    } else if (x < MIN_EXP) {
      // exp(-63) < 1e-27, so we just return 0
      return 0;
    } else {
      return UNIT.divideDecimalRound(exp(uint(-x)));
    }
  }
}
