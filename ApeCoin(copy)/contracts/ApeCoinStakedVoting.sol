/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ApeCoin?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "ApeCoin/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "ApeCoin/@openzeppelin/contracts/access/Ownable.sol";
import "./ApeCoinStaking.sol";

/**
 * @title Staked ApeCoin's Voting Contract
 * @notice Provides a comprehensive vote count across all pools in the ApeCoinStaking contract
 * @author HorizenLabs
 */
contract ApeCoinStakedVoting is Ownable {

    /// @notice The ApeCoin staking contract
    ApeCoinStaking apeCoinStaking;

    /**
     * @notice Construct a new ApeCoinStakedVoting instance
     * @param _apeCoinStakingAddress The ApeCoinStaking contract being delegated to
     */
    constructor(address _apeCoinStakingAddress) {
        require(_apeCoinStakingAddress != address(0), "staking address cannot be zero");
        apeCoinStaking = ApeCoinStaking(_apeCoinStakingAddress);
    }

    /**
     * @notice Returns a vote count across all pools in the ApeCoinStaking contract for a given address
     * @param _address The address to return votes for
     */
    function getVotes(address _address) external view returns (uint256) {
        uint256 votes = apeCoinStaking.stakedTotal(_address);
        return votes;
    }
}

