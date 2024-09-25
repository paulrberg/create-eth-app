/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/0x?utm=code
  */
  
  // SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IStaking {
    /// @dev Statuses that stake can exist in.
    ///      Any stake can be (re)delegated effective at the next epoch
    ///      Undelegated stake can be withdrawn if it is available in both the current and next epoch
    enum StakeStatus {
        UNDELEGATED,
        DELEGATED
    }

    /// @dev Encapsulates a balance for the current and next epochs.
    /// Note that these balances may be stale if the current epoch
    /// is greater than `currentEpoch`.
    /// @param currentEpoch The current epoch
    /// @param currentEpochBalance Balance in the current epoch.
    /// @param nextEpochBalance Balance in `currentEpoch+1`.
    struct StoredBalance {
        uint64 currentEpoch;
        uint96 currentEpochBalance;
        uint96 nextEpochBalance;
    }

    /// @dev Holds the metadata for a staking pool.
    /// @param operator Operator of the pool.
    /// @param operatorShare Fraction of the total balance owned by the operator, in ppm.
    struct Pool {
        address operator;
        uint32 operatorShare;
    }

    /// @dev Create a new staking pool. The sender will be the operator of this pool.
    /// Note that an operator must be payable.
    /// @param operatorShare Portion of rewards owned by the operator, in ppm.
    /// @param addOperatorAsMaker Adds operator to the created pool as a maker for convenience iff true.
    /// @return poolId The unique pool id generated for this pool.
    function createStakingPool(uint32 operatorShare, bool addOperatorAsMaker) external returns (bytes32 poolId);

    /// @dev Returns the current staking epoch number.
    /// @return epoch The current epoch.
    function currentEpoch() external view returns (uint256 epoch);

    /// @dev Returns the time (in seconds) at which the current staking epoch started.
    /// @return startTime The start time of the current epoch, in seconds.
    function currentEpochStartTimeInSeconds() external view returns (uint256 startTime);

    /// @dev Returns the duration of an epoch in seconds. This value can be updated.
    /// @return duration The duration of an epoch, in seconds.
    function epochDurationInSeconds() external view returns (uint256 duration);

    /// @dev Returns a staking pool
    /// @param poolId Unique id of pool.
    function getStakingPool(bytes32 poolId) external view returns (Pool memory);

    /// @dev Gets global stake for a given status.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Global stake for given status.
    function getGlobalStakeByStatus(StakeStatus stakeStatus) external view returns (StoredBalance memory balance);

    /// @dev Gets an owner's stake balances by status.
    /// @param staker Owner of stake.
    /// @param stakeStatus UNDELEGATED or DELEGATED
    /// @return balance Owner's stake balances for given status.
    function getOwnerStakeByStatus(
        address staker,
        StakeStatus stakeStatus
    ) external view returns (StoredBalance memory balance);

    /// @dev Returns the total stake delegated to a specific staking pool,
    ///      across all members.
    /// @param poolId Unique Id of pool.
    /// @return balance Total stake delegated to pool.
    function getTotalStakeDelegatedToPool(bytes32 poolId) external view returns (StoredBalance memory balance);

    /// @dev Returns the stake delegated to a specific staking pool, by a given staker.
    /// @param staker of stake.
    /// @param poolId Unique Id of pool.
    /// @return balance Stake delegated to pool by staker.
    function getStakeDelegatedToPoolByOwner(
        address staker,
        bytes32 poolId
    ) external view returns (StoredBalance memory balance);
}
