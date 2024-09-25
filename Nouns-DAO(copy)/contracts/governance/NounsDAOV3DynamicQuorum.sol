/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Nouns-DAO?utm=code
  */
  
  // SPDX-License-Identifier: GPL-3.0

/// @title Library for NounsDAOLogicV3 contract containing functions related to quorum calculations

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.19;

import './NounsDAOInterfaces.sol';
import { NounsDAOV3Fork } from './fork/NounsDAOV3Fork.sol';

library NounsDAOV3DynamicQuorum {
    using NounsDAOV3Fork for NounsDAOStorageV3.StorageV3;

    error UnsafeUint16Cast();

    /**
     * @notice Quorum votes required for a specific proposal to succeed
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function quorumVotes(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) internal view returns (uint256) {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        if (proposal.totalSupply == 0) {
            return proposal.quorumVotes;
        }

        return
            dynamicQuorumVotes(
                proposal.againstVotes,
                proposal.totalSupply,
                getDynamicQuorumParamsAt(ds, proposal.creationBlock)
            );
    }

    /**
     * @notice Calculates the required quorum of for-votes based on the amount of against-votes
     *     The more against-votes there are for a proposal, the higher the required quorum is.
     *     The quorum BPS is between `params.minQuorumVotesBPS` and params.maxQuorumVotesBPS.
     *     The additional quorum is calculated as:
     *       quorumCoefficient * againstVotesBPS
     * @dev Note the coefficient is a fixed point integer with 6 decimals
     * @param againstVotes Number of against-votes in the proposal
     * @param totalSupply The total supply of Nouns at the time of proposal creation
     * @param params Configurable parameters for calculating the quorum based on againstVotes. See `DynamicQuorumParams` definition for additional details.
     * @return quorumVotes The required quorum
     */
    function dynamicQuorumVotes(
        uint256 againstVotes,
        uint256 totalSupply,
        NounsDAOStorageV3.DynamicQuorumParams memory params
    ) public pure returns (uint256) {
        uint256 againstVotesBPS = (10000 * againstVotes) / totalSupply;
        uint256 quorumAdjustmentBPS = (params.quorumCoefficient * againstVotesBPS) / 1e6;
        uint256 adjustedQuorumBPS = params.minQuorumVotesBPS + quorumAdjustmentBPS;
        uint256 quorumBPS = min(params.maxQuorumVotesBPS, adjustedQuorumBPS);
        return bps2Uint(quorumBPS, totalSupply);
    }

    /**
     * @notice returns the dynamic quorum parameters values at a certain block number
     * @dev The checkpoints array must not be empty, and the block number must be higher than or equal to
     *     the block of the first checkpoint
     * @param blockNumber_ the block number to get the params at
     * @return The dynamic quorum parameters that were set at the given block number
     */
    function getDynamicQuorumParamsAt(NounsDAOStorageV3.StorageV3 storage ds, uint256 blockNumber_)
        internal
        view
        returns (NounsDAOStorageV3.DynamicQuorumParams memory)
    {
        uint32 blockNumber = safe32(blockNumber_, 'NounsDAO::getDynamicQuorumParamsAt: block number exceeds 32 bits');
        uint256 len = ds.quorumParamsCheckpoints.length;

        if (len == 0) {
            return
                NounsDAOStorageV3.DynamicQuorumParams({
                    minQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    maxQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    quorumCoefficient: 0
                });
        }

        if (ds.quorumParamsCheckpoints[len - 1].fromBlock <= blockNumber) {
            return ds.quorumParamsCheckpoints[len - 1].params;
        }

        if (ds.quorumParamsCheckpoints[0].fromBlock > blockNumber) {
            return
                NounsDAOStorageV3.DynamicQuorumParams({
                    minQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    maxQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    quorumCoefficient: 0
                });
        }

        uint256 lower = 0;
        uint256 upper = len - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            NounsDAOStorageV3.DynamicQuorumParamsCheckpoint memory cp = ds.quorumParamsCheckpoints[center];
            if (cp.fromBlock == blockNumber) {
                return cp.params;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return ds.quorumParamsCheckpoints[lower].params;
    }

    /**
     * @notice Current min quorum votes using Nouns adjusted total supply
     */
    function minQuorumVotes(NounsDAOStorageV3.StorageV3 storage ds, uint256 adjustedTotalSupply)
        internal
        view
        returns (uint256)
    {
        return bps2Uint(getDynamicQuorumParamsAt(ds, block.number).minQuorumVotesBPS, adjustedTotalSupply);
    }

    /**
     * @notice Current max quorum votes using Nouns adjusted total supply
     */
    function maxQuorumVotes(NounsDAOStorageV3.StorageV3 storage ds, uint256 adjustedTotalSupply)
        internal
        view
        returns (uint256)
    {
        return bps2Uint(getDynamicQuorumParamsAt(ds, block.number).maxQuorumVotesBPS, adjustedTotalSupply);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n <= type(uint32).max, errorMessage);
        return uint32(n);
    }

    function safe16(uint256 n) internal pure returns (uint16) {
        if (n > type(uint16).max) {
            revert UnsafeUint16Cast();
        }
        return uint16(n);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
        return (number * bps) / 10000;
    }
}
