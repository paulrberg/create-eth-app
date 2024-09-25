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

import "../interfaces/IDexPriceAggregator.sol";
import "../interfaces/IERC20.sol";
import "../SafeDecimalMath.sol";

contract MockDexPriceAggregator is IDexPriceAggregator {
    uint public constant UNIT = 10**uint(18);

    mapping(address => uint) public rates;
    bool public assetToAssetShouldRevert;

    function assetToAsset(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint
    ) external view returns (uint amountOut) {
        if (assetToAssetShouldRevert) {
            revert("mock assetToAsset() reverted");
        }

        uint inDecimals = IERC20(tokenIn).decimals();
        uint outDecimals = IERC20(tokenOut).decimals();
        uint inAmountWithRatesDecimals = (amountIn * UNIT) / 10**uint(inDecimals);
        uint outAmountWithRatesDecimals = (inAmountWithRatesDecimals * rates[tokenIn]) / rates[tokenOut];

        return ((outAmountWithRatesDecimals * 10**uint(outDecimals)) / UNIT);
    }

    // Rate should be specified with 18 decimals
    function setAssetToAssetRate(address _asset, uint _rate) external {
        rates[_asset] = _rate;
    }

    function setAssetToAssetShouldRevert(bool _shouldRevert) external {
        assetToAssetShouldRevert = _shouldRevert;
    }
}
