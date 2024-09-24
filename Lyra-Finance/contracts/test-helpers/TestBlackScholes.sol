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

// Libraries
import "../synthetix/SignedDecimalMath.sol";
import "../synthetix/DecimalMath.sol";
import "../libraries/Math.sol";
import "../libraries/BlackScholes.sol";
import "../libraries/FixedPointMathLib.sol";

contract TestBlackScholes {
  using DecimalMath for uint;
  using SignedDecimalMath for int;
  using BlackScholes for *;

  function expPub(int x) external pure returns (uint) {
    return FixedPointMathLib.exp(x);
  }

  function lnPub(int x) external pure returns (int) {
    return FixedPointMathLib.ln(x);
  }

  function sqrt_pub(uint x) external pure returns (uint) {
    return (x * DecimalMath.UNIT)._sqrt();
  }

  function abs_pub(int x) external pure returns (uint) {
    return Math.abs(x);
  }

  function stdNormal_pub(int x) external pure returns (uint) {
    return x._stdNormal().preciseDecimalToDecimal();
  }

  function stdNormalCDF_pub(int x) external pure returns (uint) {
    return x._stdNormalCDF().preciseDecimalToDecimal();
  }

  function annualise_pub(uint secs) external pure returns (uint yearFraction) {
    return secs._annualise().preciseDecimalToDecimal();
  }

  function d1d2_pub(
    uint tAnnualised,
    uint volatility,
    uint spot,
    uint strikePrice,
    int rate
  ) external pure returns (int d1, int d2) {
    (d1, d2) = tAnnualised._d1d2(volatility, spot, strikePrice, rate);
    return (d1.preciseDecimalToDecimal(), d2.preciseDecimalToDecimal());
  }

  function optionPrices_pub(
    BlackScholes.BlackScholesInputs memory bsInput
  ) external pure returns (uint call, uint put) {
    return bsInput.optionPrices();
  }

  function pricesDeltaStdVega_pub(
    BlackScholes.BlackScholesInputs memory bsInput
  ) external pure returns (BlackScholes.PricesDeltaStdVega memory) {
    return bsInput.pricesDeltaStdVega();
  }

  function delta_pub(BlackScholes.BlackScholesInputs memory bsInput) external pure returns (int, int) {
    return bsInput.delta();
  }

  function vega_pub(BlackScholes.BlackScholesInputs memory bsInput) external pure returns (uint) {
    return bsInput.vega();
  }
}
