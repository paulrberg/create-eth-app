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

import "./DefaultPoolOperator.sol";
import "./IStaking.sol";

interface IZrxTreasury {
    struct TreasuryParameters {
        uint256 votingPeriod;
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        bytes32 defaultPoolId;
    }

    struct ProposedAction {
        address target;
        bytes data;
        uint256 value;
    }

    struct Proposal {
        bytes32 actionsHash;
        uint256 executionEpoch;
        uint256 voteEpoch;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    event ProposalCreated(
        address proposer,
        bytes32[] operatedPoolIds,
        uint256 proposalId,
        ProposedAction[] actions,
        uint256 executionEpoch,
        string description
    );

    event VoteCast(address voter, bytes32[] operatedPoolIds, uint256 proposalId, bool support, uint256 votingPower);

    event ProposalExecuted(uint256 proposalId);

    function stakingProxy() external view returns (IStaking);

    function defaultPoolOperator() external view returns (DefaultPoolOperator);

    function defaultPoolId() external view returns (bytes32);

    function votingPeriod() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);

    function quorumThreshold() external view returns (uint256);

    /// @dev Updates the proposal and quorum thresholds to the given
    ///      values. Note that this function is only callable by the
    ///      treasury contract itself, so the threshold can only be
    ///      updated via a successful treasury proposal.
    /// @param newProposalThreshold The new value for the proposal threshold.
    /// @param newQuorumThreshold The new value for the quorum threshold.
    function updateThresholds(uint256 newProposalThreshold, uint256 newQuorumThreshold) external;

    /// @dev Creates a proposal to send ZRX from this treasury on the
    ///      the given actions. Must have at least `proposalThreshold`
    ///      of voting power to call this function. See `getVotingPower`
    ///      for how voting power is computed. If a proposal is successfully
    ///      created, voting starts at the epoch after next (currentEpoch + 2).
    ///      If the vote passes, the proposal is executable during the
    ///      `executionEpoch`. See `hasProposalPassed` for the passing criteria.
    /// @param actions The proposed ZRX actions. An action specifies a
    ///        contract call.
    /// @param executionEpoch The epoch during which the proposal is to
    ///        be executed if it passes. Must be at least two epochs
    ///        from the current epoch.
    /// @param description A text description for the proposal.
    /// @param operatedPoolIds The pools operated by `msg.sender`. The
    ///        ZRX currently delegated to those pools will be accounted
    ///        for in the voting power.
    /// @return proposalId The ID of the newly created proposal.
    function propose(
        ProposedAction[] calldata actions,
        uint256 executionEpoch,
        string calldata description,
        bytes32[] calldata operatedPoolIds
    ) external returns (uint256 proposalId);

    /// @dev Casts a vote for the given proposal. Only callable
    ///      during the voting period for that proposal.
    ///      One address can only vote once.
    ///      See `getVotingPower` for how voting power is computed.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support Whether to support the proposal or not.
    /// @param operatedPoolIds The pools operated by `msg.sender`. The
    ///        ZRX currently delegated to those pools will be accounted
    ///        for in the voting power.
    function castVote(uint256 proposalId, bool support, bytes32[] calldata operatedPoolIds) external;

    /// @dev Casts a vote for the given proposal, by signature.
    ///      Only callable during the voting period for that proposal.
    ///      One address/voter can only vote once.
    ///      See `getVotingPower` for how voting power is computed.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support Whether to support the proposal or not.
    /// @param operatedPoolIds The pools operated by the signer. The
    ///        ZRX currently delegated to those pools will be accounted
    ///        for in the voting power.
    /// @param v the v field of the signature
    /// @param r the r field of the signature
    /// @param s the s field of the signature
    function castVoteBySignature(
        uint256 proposalId,
        bool support,
        bytes32[] memory operatedPoolIds,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @dev Executes a proposal that has passed and is
    ///      currently executable.
    /// @param proposalId The ID of the proposal to execute.
    /// @param actions Actions associated with the proposal to execute.
    function execute(uint256 proposalId, ProposedAction[] memory actions) external payable;

    /// @dev Returns the total number of proposals.
    /// @return count The number of proposals.
    function proposalCount() external view returns (uint256 count);

    /// @dev Computes the current voting power of the given account.
    ///      Voting power is equal to:
    ///      (ZRX delegated to the default pool) +
    ///      0.5 * (ZRX delegated to other pools) +
    ///      0.5 * (ZRX delegated to pools operated by account)
    /// @param account The address of the account.
    /// @param operatedPoolIds The pools operated by `account`. The
    ///        ZRX currently delegated to those pools will be accounted
    ///        for in the voting power.
    /// @return votingPower The current voting power of the given account.
    function getVotingPower(
        address account,
        bytes32[] calldata operatedPoolIds
    ) external view returns (uint256 votingPower);
}
