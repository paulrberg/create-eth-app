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

contract RewardReader {
    using SafeMath for uint256;

    function getDepositBalances(address _account, address[] memory _depositTokens, address[] memory _rewardTrackers) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_rewardTrackers.length);
        for (uint256 i = 0; i < _rewardTrackers.length; i++) {
            IRewardTracker rewardTracker = IRewardTracker(_rewardTrackers[i]);
            amounts[i] = rewardTracker.depositBalances(_account, _depositTokens[i]);
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _rewardTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 5;
        uint256[] memory amounts = new uint256[](_rewardTrackers.length * propsLength);
        for (uint256 i = 0; i < _rewardTrackers.length; i++) {
            IRewardTracker rewardTracker = IRewardTracker(_rewardTrackers[i]);
            amounts[i * propsLength] = rewardTracker.claimable(_account);
            amounts[i * propsLength + 1] = rewardTracker.tokensPerInterval();
            amounts[i * propsLength + 2] = rewardTracker.averageStakedAmounts(_account);
            amounts[i * propsLength + 3] = rewardTracker.cumulativeRewards(_account);
            amounts[i * propsLength + 4] = IERC20(_rewardTrackers[i]).totalSupply();
        }
        return amounts;
    }

    function getVestingInfoV2(address _account, address[] memory _vesters) public view returns (uint256[] memory) {
        uint256 propsLength = 12;
        uint256[] memory amounts = new uint256[](_vesters.length * propsLength);
        for (uint256 i = 0; i < _vesters.length; i++) {
            IVester vester = IVester(_vesters[i]);
            IRewardTracker rewardTracker = IRewardTracker(vester.rewardTracker());
            amounts[i * propsLength] = vester.pairAmounts(_account);
            amounts[i * propsLength + 1] = vester.getVestedAmount(_account);
            amounts[i * propsLength + 2] = IERC20(_vesters[i]).balanceOf(_account);
            amounts[i * propsLength + 3] = vester.claimedAmounts(_account);
            amounts[i * propsLength + 4] = vester.claimable(_account);
            amounts[i * propsLength + 5] = vester.getMaxVestableAmount(_account);
            amounts[i * propsLength + 6] = vester.getCombinedAverageStakedAmount(_account);
            amounts[i * propsLength + 7] = rewardTracker.cumulativeRewards(_account);
            amounts[i * propsLength + 8] = vester.transferredCumulativeRewards(_account);
            amounts[i * propsLength + 9] = vester.bonusRewards(_account);
            amounts[i * propsLength + 10] = rewardTracker.averageStakedAmounts(_account);
            amounts[i * propsLength + 11] = vester.transferredAverageStakedAmounts(_account);
        }
        return amounts;
    }
}
