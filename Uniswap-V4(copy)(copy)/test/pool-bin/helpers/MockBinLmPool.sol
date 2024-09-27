/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IBinPoolManager} from "../../../src/pool-bin/interfaces/IBinPoolManager.sol";
import {PoolId} from "../../../src/types/PoolId.sol";
import {IBinLmPool} from "../../../src/pool-bin/interfaces/IBinLmPool.sol";

contract MockBinLmPool is IBinLmPool {
    struct BinInfo {
        uint256 accCakePerShare;
        uint256 totalShare;
    }

    /// @notice binId => BinInfo
    mapping(uint24 => BinInfo) public binIdToBinInfo;

    PoolId public poolId;

    uint32 public lastRewardTimestamp;

    IBinPoolManager poolManager;

    uint256 public accumulateRewardCounter;

    constructor(IBinPoolManager _poolManager, PoolId _poolId) {
        poolManager = _poolManager;
        poolId = _poolId;
        lastRewardTimestamp = uint32(block.timestamp);
    }

    function accumulateReward(uint32 currTimestamp) external override {
        (uint24 activeId,,) = poolManager.getSlot0(poolId);
        BinInfo storage binInfo = binIdToBinInfo[activeId];

        binInfo.accCakePerShare += 1;
        lastRewardTimestamp = currTimestamp;

        accumulateRewardCounter += 1;
    }
}
