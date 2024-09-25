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

import "../../synthetix/DecimalMath.sol";
import "../../interfaces/gmx/IVault.sol";
import "../../synthetix/Owned.sol";
import "../TestERC20.sol";
import "../../interfaces/IAggregatorV3.sol";
import "../../libraries/ConvertDecimals.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/utils/math/SafeCast.sol";

contract TestGMXVaultChainlinkPrice is Owned {
  using DecimalMath for uint;
  using SafeCast for int;

  mapping(address => AggregatorV2V3Interface) public priceFeeds;

  uint public constant PRICE_PRECISION = 1e30;
  uint public constant FUNDING_RATE_PRECISION = 1e8;
  uint public constant SPREAD_PERCENT = 1;

  constructor() {}

  function setFeed(address token, AggregatorV2V3Interface chainlinkFeed) external onlyOwner {
    priceFeeds[token] = chainlinkFeed;
  }

  function getMaxPrice(address _token) public view returns (uint) {
    return (_getCLPrice(_token) * (100 + SPREAD_PERCENT)) / 100;
  }

  function getMinPrice(address _token) public view returns (uint) {
    return (_getCLPrice(_token) * (100 - SPREAD_PERCENT)) / 100;
  }

  function _getCLPrice(address _token) internal view returns (uint) {
    (, int price, , , ) = priceFeeds[_token].latestRoundData();
    uint decimals = priceFeeds[_token].decimals();
    return (SafeCast.toUint256(price) * PRICE_PRECISION) / 10 ** decimals;
  }

  function getPosition(
    address, // _account
    address, // _collateralToken
    address, // _indexToken
    bool // _isLong
  )
    external
    pure
    returns (
      uint size,
      uint collateral,
      uint averagePrice,
      uint entryFundingRate,
      uint reserveAmount,
      uint realisedProfit,
      bool hasProfit,
      uint lastIncreasedTime
    )
  {
    return (0, 0, 0, 0, 0, 0, false, 0);
  }

  function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint amountOut) {
    TestERC20 tokenIn = TestERC20(_tokenIn);
    TestERC20 tokenOut = TestERC20(_tokenOut);

    require(
      tokenIn != TestERC20(address(0)) && tokenOut != TestERC20(address(0)),
      "token in or token out is zero address"
    );

    uint bal = tokenIn.balanceOf(address(this));

    // burn the tokens sent
    tokenIn.burn(address(this), bal);

    bal = ConvertDecimals.convertTo18(bal, tokenIn.decimals());

    // grab the assetPrices of each token
    uint fromPrice = getMinPrice(address(_tokenIn));
    uint toPrice = getMaxPrice(address(_tokenOut));

    amountOut = ConvertDecimals.convertFrom18((bal * fromPrice) / toPrice, tokenOut.decimals());

    // mint the amountOut
    tokenOut.mint(_receiver, amountOut);
    return amountOut;
  }

  function _getChainlinkPrice(address token) internal view returns (uint spotPrice) {
    AggregatorV2V3Interface assetPriceFeed = priceFeeds[token];
    require(assetPriceFeed != AggregatorV2V3Interface(address(0)), "invalid price feed");

    (, int answer, , , ) = assetPriceFeed.latestRoundData();
    return _convertPriceTo18(SafeCast.toUint256(answer), assetPriceFeed.decimals());
  }

  function poolAmounts(address /* token */) external pure returns (uint) {
    return 1000000000e18;
  }

  function reservedAmounts(address /* token */) external pure returns (uint) {
    return 100000000e18;
  }

  //////////
  // Misc //
  //////////

  /// @dev Converts input to 18 dp precision
  function _convertPriceTo18(uint spotPrice, uint decimals) internal pure returns (uint price18) {
    return (spotPrice * 1e18) / (10 ** decimals);
  }
}
