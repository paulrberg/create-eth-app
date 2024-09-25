/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/GMX.io?utm=code
  */
  
  // SPDX-License-Identifier: MIT

import "../ShortsTracker.sol";

pragma solidity 0.6.12;

contract ShortsTrackerTest is ShortsTracker {
    constructor(address _vault) public ShortsTracker(_vault) {}

    function getNextGlobalShortDataWithRealisedPnl(
       address _indexToken,
       uint256 _nextPrice,
       uint256 _sizeDelta,
       int256 _realisedPnl,
       bool _isIncrease
    ) public view returns (uint256, uint256) {
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice ? averagePrice.sub(_nextPrice) : _nextPrice.sub(averagePrice);

        uint256 nextSize;
        uint256 delta;
        // avoid stack to deep
        {
            uint256 size = vault.globalShortSizes(_indexToken);
            nextSize = _isIncrease ? size.add(_sizeDelta) : size.sub(_sizeDelta);

            if (nextSize == 0) {
                return (0, 0);
            }

            if (averagePrice == 0) {
                return (nextSize, _nextPrice);
            }

            delta = size.mul(priceDelta).div(averagePrice);
        }

        uint256 nextAveragePrice = _getNextGlobalAveragePrice(
            averagePrice,
            _nextPrice,
            nextSize,
            delta,
            _realisedPnl
        );

        return (nextSize, nextAveragePrice);
    }

    function setGlobalShortAveragePrice(address _token, uint256 _averagePrice) public {
        globalShortAveragePrices[_token] = _averagePrice;
    }
}
