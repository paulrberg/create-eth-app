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

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../staking/interfaces/IVester.sol";
import "../staking/interfaces/IRewardTracker.sol";

contract EsGmxBatchSender {
    using SafeMath for uint256;

    address public admin;
    address public esGmx;

    constructor(address _esGmx) public {
        admin = msg.sender;
        esGmx = _esGmx;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "EsGmxBatchSender: forbidden");
        _;
    }

    function send(
        IVester _vester,
        uint256 _minRatio,
        address[] memory _accounts,
        uint256[] memory _amounts
    ) external onlyAdmin {
        IRewardTracker rewardTracker = IRewardTracker(_vester.rewardTracker());

        for (uint256 i = 0; i < _accounts.length; i++) {
            IERC20(esGmx).transferFrom(msg.sender, _accounts[i], _amounts[i]);

            uint256 nextTransferredCumulativeReward = _vester.transferredCumulativeRewards(_accounts[i]).add(_amounts[i]);
            _vester.setTransferredCumulativeRewards(_accounts[i], nextTransferredCumulativeReward);

            uint256 cumulativeReward = rewardTracker.cumulativeRewards(_accounts[i]);
            uint256 totalCumulativeReward = cumulativeReward.add(nextTransferredCumulativeReward);

            uint256 combinedAverageStakedAmount = _vester.getCombinedAverageStakedAmount(_accounts[i]);

            if (combinedAverageStakedAmount > totalCumulativeReward.mul(_minRatio)) {
                continue;
            }

            uint256 nextTransferredAverageStakedAmount = _minRatio.mul(totalCumulativeReward);
            nextTransferredAverageStakedAmount = nextTransferredAverageStakedAmount.sub(
                rewardTracker.averageStakedAmounts(_accounts[i]).mul(cumulativeReward).div(totalCumulativeReward)
            );

            nextTransferredAverageStakedAmount = nextTransferredAverageStakedAmount.mul(totalCumulativeReward).div(nextTransferredCumulativeReward);

            _vester.setTransferredAverageStakedAmounts(_accounts[i], nextTransferredAverageStakedAmount);
        }
    }
}
