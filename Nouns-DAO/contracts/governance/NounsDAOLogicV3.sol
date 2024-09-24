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
  
  // SPDX-License-Identifier: BSD-3-Clause

/// @title The Nouns DAO logic version 3

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

// LICENSE
// NounsDAOLogicV2.sol is a modified version of Compound Lab's GovernorBravoDelegate.sol:
// https://github.com/compound-finance/compound-protocol/blob/b9b14038612d846b83f8a009a82c38974ff2dcfe/contracts/Governance/GovernorBravoDelegate.sol
//
// GovernorBravoDelegate.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
// With modifications by Nounders DAO.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause
//
// MODIFICATIONS
// See NounsDAOLogicV1 for initial GovernorBravoDelegate modifications.
// See NounsDAOLogicV2 for additional modifications
//
// NounsDAOLogicV3 adds:
// - Contract has been broken down to use libraries because of contract size limitations
// - Proposal editing: allowing proposers to update their proposal’s transactions and text description,
// during the Updatable period only, which is the state upon proposal creation. Editing also works with signatures,
// assuming the proposer is able to accumulate signatures from the same signers.
// - Propose by signature: allowing Nouners and delegates to pool their voting power towards submitting a proposal,
// by submitting their signature, instead of the current approach where sponsors must delegate their votes to help
// a proposer achieve threshold.
// - Objection-only Period: a conditional voting period that gets activated upon a last-minute proposal swing
// from defeated to successful, affording against voters more reaction time.
// Only against votes are possible during the objection period.
// - Votes snapshot after voting delay: moving votes snapshot up, to provide Nouners with reaction time per proposal,
// to get their votes ready (e.g. some might want to move their delegations around).
// In NounsDAOLogicV2 the vote snapshot block is the proposal creation block.
// - Nouns fork: any token holder can signal to fork (exit) in response to a governance proposal.
// If a quorum of a configured threshold amount of tokens signals to exit, the fork will succeed.
// This will deploy a new DAO and send part of the treasury to the new DAO.
//
// 2 new states have been added to the proposal state machine: Updatable, ObjectionPeriod
//
// Updated state machine:
// Updatable -> Pending -> Active -> ObjectionPeriod (conditional) -> Succeeded -> Queued -> Executed
//                                                                 ┖> Defeated
//

pragma solidity ^0.8.19;

import './NounsDAOInterfaces.sol';
import { NounsDAOV3Admin } from './NounsDAOV3Admin.sol';
import { NounsDAOV3DynamicQuorum } from './NounsDAOV3DynamicQuorum.sol';
import { NounsDAOV3Votes } from './NounsDAOV3Votes.sol';
import { NounsDAOV3Proposals } from './NounsDAOV3Proposals.sol';
import { NounsDAOV3Fork } from './fork/NounsDAOV3Fork.sol';

contract NounsDAOLogicV3 is NounsDAOStorageV3, NounsDAOEventsV3 {
    using NounsDAOV3Admin for StorageV3;
    using NounsDAOV3DynamicQuorum for StorageV3;
    using NounsDAOV3Votes for StorageV3;
    using NounsDAOV3Proposals for StorageV3;
    using NounsDAOV3Fork for StorageV3;

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   CONSTANTS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice The minimum setable proposal threshold
    function MIN_PROPOSAL_THRESHOLD_BPS() public pure returns (uint256) {
        return NounsDAOV3Admin.MIN_PROPOSAL_THRESHOLD_BPS;
    }

    /// @notice The maximum setable proposal threshold
    function MAX_PROPOSAL_THRESHOLD_BPS() public pure returns (uint256) {
        return NounsDAOV3Admin.MAX_PROPOSAL_THRESHOLD_BPS;
    }

    /// @notice The minimum setable voting period in blocks
    function MIN_VOTING_PERIOD() public pure returns (uint256) {
        return NounsDAOV3Admin.MIN_VOTING_PERIOD_BLOCKS;
    }

    /// @notice The max setable voting period in blocks
    function MAX_VOTING_PERIOD() public pure returns (uint256) {
        return NounsDAOV3Admin.MAX_VOTING_PERIOD_BLOCKS;
    }

    /// @notice The min setable voting delay in blocks
    function MIN_VOTING_DELAY() public pure returns (uint256) {
        return NounsDAOV3Admin.MIN_VOTING_DELAY_BLOCKS;
    }

    /// @notice The max setable voting delay in blocks
    function MAX_VOTING_DELAY() public pure returns (uint256) {
        return NounsDAOV3Admin.MAX_VOTING_DELAY_BLOCKS;
    }

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint256) {
        return NounsDAOV3Proposals.PROPOSAL_MAX_OPERATIONS;
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   ERRORS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    error AdminOnly();
    error CanOnlyInitializeOnce();
    error InvalidTimelockAddress();
    error InvalidNounsAddress();

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   INITIALIZER
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Used to initialize the contract during delegator contructor
     * @dev This will only be called for a newly deployed DAO, not as part of an upgrade from V2 to V3
     * @param timelock_ The address of the NounsDAOExecutor
     * @param nouns_ The address of the NOUN tokens
     * @param forkEscrow_ The escrow contract used for creating forks
     * @param forkDAODeployer_ The contract used to deploy new forked DAOs
     * @param vetoer_ The address allowed to unilaterally veto proposals
     * @param daoParams_ Initial DAO parameters
     * @param dynamicQuorumParams_ The initial dynamic quorum parameters
     */
    function initialize(
        address timelock_,
        address nouns_,
        address forkEscrow_,
        address forkDAODeployer_,
        address vetoer_,
        NounsDAOParams calldata daoParams_,
        DynamicQuorumParams calldata dynamicQuorumParams_
    ) public virtual {
        if (address(ds.timelock) != address(0)) revert CanOnlyInitializeOnce();
        if (msg.sender != ds.admin) revert AdminOnly();
        if (timelock_ == address(0)) revert InvalidTimelockAddress();
        if (nouns_ == address(0)) revert InvalidNounsAddress();

        ds._setVotingPeriod(daoParams_.votingPeriod);
        ds._setVotingDelay(daoParams_.votingDelay);
        ds._setProposalThresholdBPS(daoParams_.proposalThresholdBPS);
        ds.timelock = INounsDAOExecutorV2(timelock_);
        ds.nouns = NounsTokenLike(nouns_);
        ds.forkEscrow = INounsDAOForkEscrow(forkEscrow_);
        ds.forkDAODeployer = IForkDAODeployer(forkDAODeployer_);
        ds.vetoer = vetoer_;
        _setDynamicQuorumParams(
            dynamicQuorumParams_.minQuorumVotesBPS,
            dynamicQuorumParams_.maxQuorumVotesBPS,
            dynamicQuorumParams_.quorumCoefficient
        );

        ds._setLastMinuteWindowInBlocks(daoParams_.lastMinuteWindowInBlocks);
        ds._setObjectionPeriodDurationInBlocks(daoParams_.objectionPeriodDurationInBlocks);
        ds._setProposalUpdatablePeriodInBlocks(daoParams_.proposalUpdatablePeriodInBlocks);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   PROPOSALS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return uint256 Proposal id of new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        return ds.propose(NounsDAOV3Proposals.ProposalTxs(targets, values, signatures, calldatas), description);
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold.
     * This proposal would be executed via the timelockV1 contract. This is meant to be used in case timelockV1
     * is still holding funds or has special permissions to execute on certain contracts.
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return uint256 Proposal id of new proposal
     */
    function proposeOnTimelockV1(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        return
            ds.proposeOnTimelockV1(
                NounsDAOV3Proposals.ProposalTxs(targets, values, signatures, calldatas),
                description
            );
    }

    /**
     * @notice Function used to propose a new proposal. Sender and signers must have delegates above the proposal threshold
     * Signers are regarded as co-proposers, and therefore have the ability to cancel the proposal at any time.
     * @param proposerSignatures Array of signers who have signed the proposal and their signatures.
     * @dev The signatures follow EIP-712. See `PROPOSAL_TYPEHASH` in NounsDAOV3Proposals.sol
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return uint256 Proposal id of new proposal
     */
    function proposeBySigs(
        ProposerSignature[] memory proposerSignatures,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        return
            ds.proposeBySigs(
                proposerSignatures,
                NounsDAOV3Proposals.ProposalTxs(targets, values, signatures, calldatas),
                description
            );
    }

    /**
     * @notice Invalidates a signature that may be used for signing a new proposal.
     * Once a signature is canceled, the sender can no longer use it again.
     * If the sender changes their mind and want to sign the proposal, they can change the expiry timestamp
     * in order to produce a new signature.
     * The signature will only be invalidated when used by the sender. If used by a different account, it will
     * not be invalidated.
     * Cancelling a signature for an existing proposal will have no effect. Signers have the ability to cancel
     * a proposal they signed if necessary.
     * @param sig The signature to cancel
     */
    function cancelSig(bytes calldata sig) external {
        ds.cancelSig(sig);
    }

    /**
     * @notice Update a proposal transactions and description.
     * Only the proposer can update it, and only during the updateable period.
     * @param proposalId Proposal's id
     * @param targets Updated target addresses for proposal calls
     * @param values Updated eth values for proposal calls
     * @param signatures Updated function signatures for proposal calls
     * @param calldatas Updated calldatas for proposal calls
     * @param description Updated description of the proposal
     * @param updateMessage Short message to explain the update
     */
    function updateProposal(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory updateMessage
    ) external {
        ds.updateProposal(proposalId, targets, values, signatures, calldatas, description, updateMessage);
    }

    /**
     * @notice Updates the proposal's description. Only the proposer can update it, and only during the updateable period.
     * @param proposalId Proposal's id
     * @param description Updated description of the proposal
     * @param updateMessage Short message to explain the update
     */
    function updateProposalDescription(
        uint256 proposalId,
        string calldata description,
        string calldata updateMessage
    ) external {
        ds.updateProposalDescription(proposalId, description, updateMessage);
    }

    /**
     * @notice Updates the proposal's transactions. Only the proposer can update it, and only during the updateable period.
     * @param proposalId Proposal's id
     * @param targets Updated target addresses for proposal calls
     * @param values Updated eth values for proposal calls
     * @param signatures Updated function signatures for proposal calls
     * @param calldatas Updated calldatas for proposal calls
     * @param updateMessage Short message to explain the update
     */
    function updateProposalTransactions(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory updateMessage
    ) external {
        ds.updateProposalTransactions(proposalId, targets, values, signatures, calldatas, updateMessage);
    }

    /**
     * @notice Update a proposal's transactions and description that was created with proposeBySigs.
     * Only the proposer can update it, during the updateable period.
     * Requires the original signers to sign the update.
     * @param proposalId Proposal's id
     * @param proposerSignatures Array of signers who have signed the proposal and their signatures.
     * @dev The signatures follow EIP-712. See `UPDATE_PROPOSAL_TYPEHASH` in NounsDAOV3Proposals.sol
     * @param targets Updated target addresses for proposal calls
     * @param values Updated eth values for proposal calls
     * @param signatures Updated function signatures for proposal calls
     * @param calldatas Updated calldatas for proposal calls
     * @param description Updated description of the proposal
     * @param updateMessage Short message to explain the update
     */
    function updateProposalBySigs(
        uint256 proposalId,
        ProposerSignature[] memory proposerSignatures,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory updateMessage
    ) external {
        ds.updateProposalBySigs(
            proposalId,
            proposerSignatures,
            NounsDAOV3Proposals.ProposalTxs(targets, values, signatures, calldatas),
            description,
            updateMessage
        );
    }

    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId) external {
        ds.queue(proposalId);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external {
        ds.execute(proposalId);
    }

    /**
     * @notice Executes a queued proposal on timelockV1 if eta has passed
     * This is only required for proposal that were queued on timelockV1, but before the upgrade to DAO V3.
     * These proposals will not have the `executeOnTimelockV1` bool turned on.
     */
    function executeOnTimelockV1(uint256 proposalId) external {
        ds.executeOnTimelockV1(proposalId);
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer or a signer, or proposer & signers voting power
     * dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external {
        ds.cancel(proposalId);
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        return ds.state(proposalId);
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets
     * @return values
     * @return signatures
     * @return calldatas
     */
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        return ds.getActions(proposalId);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return ds.getReceipt(proposalId, voter);
    }

    /**
     * @notice Returns the proposal details given a proposal id.
     *     The `quorumVotes` member holds the *current* quorum, given the current votes.
     * @param proposalId the proposal id to get the data for
     * @return A `ProposalCondensed` struct with the proposal data, backwards compatible with V1 and V2
     */
    function proposals(uint256 proposalId) external view returns (NounsDAOStorageV2.ProposalCondensed memory) {
        return ds.proposals(proposalId);
    }

    /**
     * @notice Returns the proposal details given a proposal id.
     *     The `quorumVotes` member holds the *current* quorum, given the current votes.
     * @param proposalId the proposal id to get the data for
     * @return A `ProposalCondensed` struct with the proposal data, not backwards compatible as it contains additional values
     * like `objectionPeriodEndBlock` and `signers`
     */
    function proposalsV3(uint256 proposalId) external view returns (ProposalCondensed memory) {
        return ds.proposalsV3(proposalId);
    }

    /**
     * @notice Current proposal threshold using Noun Total Supply
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function proposalThreshold() public view returns (uint256) {
        return ds.proposalThreshold(ds.adjustedTotalSupply());
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   DAO FORK
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Escrow Nouns to contribute to the fork threshold
     * @dev Requires approving the tokenIds or the entire noun token to the DAO contract
     * @param tokenIds the tokenIds to escrow. They will be sent to the DAO once the fork threshold is reached and the escrow is closed.
     * @param proposalIds array of proposal ids which are the reason for wanting to fork. This will only be used to emit event.
     * @param reason the reason for want to fork. This will only be used to emit event.
     */
    function escrowToFork(
        uint256[] calldata tokenIds,
        uint256[] calldata proposalIds,
        string calldata reason
    ) external {
        ds.escrowToFork(tokenIds, proposalIds, reason);
    }

    /**
     * @notice Withdraw Nouns from the fork escrow. Only possible if the fork has not been executed.
     * Only allowed to withdraw tokens that the sender has escrowed.
     * @param tokenIds the tokenIds to withdraw
     */
    function withdrawFromForkEscrow(uint256[] calldata tokenIds) external {
        ds.withdrawFromForkEscrow(tokenIds);
    }

    /**
     * @notice Execute the fork. Only possible if the fork threshold has been met.
     * This will deploy a new DAO and send part of the treasury to the new DAO's treasury.
     * This will also close the active escrow and all nouns in the escrow belong to the original DAO.
     * @return forkTreasury The address of the new DAO's treasury
     * @return forkToken The address of the new DAO's token
     */
    function executeFork() external returns (address forkTreasury, address forkToken) {
        return ds.executeFork();
    }

    /**
     * @notice Joins a fork while a fork is active
     * @param tokenIds the tokenIds to send to the DAO in exchange for joining the fork
     * @param proposalIds array of proposal ids which are the reason for wanting to fork. This will only be used to emit event.
     * @param reason the reason for want to fork. This will only be used to emit event.
     */
    function joinFork(
        uint256[] calldata tokenIds,
        uint256[] calldata proposalIds,
        string calldata reason
    ) external {
        ds.joinFork(tokenIds, proposalIds, reason);
    }

    /**
     * @notice Withdraws nouns from the fork escrow to the treasury after the fork has been executed
     * @dev Only the DAO can call this function
     * @param tokenIds the tokenIds to withdraw
     */
    function withdrawDAONounsFromEscrowToTreasury(uint256[] calldata tokenIds) external {
        ds.withdrawDAONounsFromEscrowToTreasury(tokenIds);
    }

    /**
     * @notice Withdraws nouns from the fork escrow after the fork has been executed to an address other than the treasury
     * @dev Only the DAO can call this function
     * @param tokenIds the tokenIds to withdraw
     * @param to the address to send the nouns to
     */
    function withdrawDAONounsFromEscrowIncreasingTotalSupply(uint256[] calldata tokenIds, address to) external {
        ds.withdrawDAONounsFromEscrowIncreasingTotalSupply(tokenIds, to);
    }

    /**
     * @notice Returns the number of nouns in supply minus nouns owned by the DAO, i.e. held in the treasury or in an
     * escrow after it has closed.
     * This is used when calculating proposal threshold, quorum, fork threshold & treasury split.
     */
    function adjustedTotalSupply() external view returns (uint256) {
        return ds.adjustedTotalSupply();
    }

    /**
     * @notice returns the required number of tokens to escrow to trigger a fork
     */
    function forkThreshold() external view returns (uint256) {
        return ds.forkThreshold();
    }

    /**
     * @notice Returns the number of tokens currently in escrow, contributing to the fork threshold
     */
    function numTokensInForkEscrow() external view returns (uint256) {
        return ds.numTokensInForkEscrow();
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   VOTES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Vetoes a proposal only if sender is the vetoer and the proposal has not been executed.
     * @param proposalId The id of the proposal to veto
     */
    function veto(uint256 proposalId) external {
        ds.veto(proposalId);
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint256 proposalId, uint8 support) external {
        ds.castVote(proposalId, support);
    }

    /**
     * @notice Cast a vote for a proposal, asking the DAO to refund gas costs.
     * Users with > 0 votes receive refunds. Refunds are partial when using a gas priority fee higher than the DAO's cap.
     * Refunds are partial when the DAO's balance is insufficient.
     * No refund is sent when the DAO's balance is empty. No refund is sent to users with no votes.
     * Voting takes place regardless of refund success.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @dev Reentrancy is defended against in `castVoteInternal` at the `receipt.hasVoted == false` require statement.
     */
    function castRefundableVote(uint256 proposalId, uint8 support) external {
        ds.castRefundableVote(proposalId, support);
    }

    /**
     * @notice Cast a vote for a proposal, asking the DAO to refund gas costs.
     * Users with > 0 votes receive refunds. Refunds are partial when using a gas priority fee higher than the DAO's cap.
     * Refunds are partial when the DAO's balance is insufficient.
     * No refund is sent when the DAO's balance is empty. No refund is sent to users with no votes.
     * Voting takes place regardless of refund success.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     * @dev Reentrancy is defended against in `castVoteInternal` at the `receipt.hasVoted == false` require statement.
     */
    function castRefundableVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        ds.castRefundableVoteWithReason(proposalId, support, reason);
    }

    /**
     * @notice Cast a vote for a proposal with a reason
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        ds.castVoteWithReason(proposalId, support, reason);
    }

    /**
     * @notice Cast a vote for a proposal by signature
     * @dev External function that accepts EIP-712 signatures for voting on proposals.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        ds.castVoteBySig(proposalId, support, v, r, s);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   ADMIN
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Admin function for setting the voting delay. Best to set voting delay to at least a few days, to give
     * voters time to make sense of proposals, e.g. 21,600 blocks which should be at least 3 days.
     * @param newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(uint256 newVotingDelay) external {
        ds._setVotingDelay(newVotingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * @param newVotingPeriod new voting period, in blocks
     */
    function _setVotingPeriod(uint256 newVotingPeriod) external {
        ds._setVotingPeriod(newVotingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold basis points
     * @dev newProposalThresholdBPS must be in [`MIN_PROPOSAL_THRESHOLD_BPS`,`MAX_PROPOSAL_THRESHOLD_BPS`]
     * @param newProposalThresholdBPS new proposal threshold
     */
    function _setProposalThresholdBPS(uint256 newProposalThresholdBPS) external {
        ds._setProposalThresholdBPS(newProposalThresholdBPS);
    }

    /**
     * @notice Admin function for setting the objection period duration
     * @param newObjectionPeriodDurationInBlocks new objection period duration, in blocks
     */
    function _setObjectionPeriodDurationInBlocks(uint32 newObjectionPeriodDurationInBlocks) external {
        ds._setObjectionPeriodDurationInBlocks(newObjectionPeriodDurationInBlocks);
    }

    /**
     * @notice Admin function for setting the objection period last minute window
     * @param newLastMinuteWindowInBlocks new objection period last minute window, in blocks
     */
    function _setLastMinuteWindowInBlocks(uint32 newLastMinuteWindowInBlocks) external {
        ds._setLastMinuteWindowInBlocks(newLastMinuteWindowInBlocks);
    }

    /**
     * @notice Admin function for setting the proposal updatable period
     * @param newProposalUpdatablePeriodInBlocks the new proposal updatable period, in blocks
     */
    function _setProposalUpdatablePeriodInBlocks(uint32 newProposalUpdatablePeriodInBlocks) external {
        ds._setProposalUpdatablePeriodInBlocks(newProposalUpdatablePeriodInBlocks);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) external {
        ds._setPendingAdmin(newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() external {
        ds._acceptAdmin();
    }

    /**
     * @notice Begins transition of vetoer. The newPendingVetoer must call _acceptVetoer to finalize the transfer.
     * @param newPendingVetoer New Pending Vetoer
     */
    function _setPendingVetoer(address newPendingVetoer) public {
        ds._setPendingVetoer(newPendingVetoer);
    }

    /**
     * @notice Called by the pendingVetoer to accept role and update vetoer
     */
    function _acceptVetoer() external {
        ds._acceptVetoer();
    }

    /**
     * @notice Burns veto priviledges
     * @dev Vetoer function destroying veto power forever
     */
    function _burnVetoPower() public {
        ds._burnVetoPower();
    }

    /**
     * @notice Admin function for setting the minimum quorum votes bps
     * @param newMinQuorumVotesBPS minimum quorum votes bps
     *     Must be between `MIN_QUORUM_VOTES_BPS_LOWER_BOUND` and `MIN_QUORUM_VOTES_BPS_UPPER_BOUND`
     *     Must be lower than or equal to maxQuorumVotesBPS
     */
    function _setMinQuorumVotesBPS(uint16 newMinQuorumVotesBPS) external {
        ds._setMinQuorumVotesBPS(newMinQuorumVotesBPS);
    }

    /**
     * @notice Admin function for setting the maximum quorum votes bps
     * @param newMaxQuorumVotesBPS maximum quorum votes bps
     *     Must be lower than `MAX_QUORUM_VOTES_BPS_UPPER_BOUND`
     *     Must be higher than or equal to minQuorumVotesBPS
     */
    function _setMaxQuorumVotesBPS(uint16 newMaxQuorumVotesBPS) external {
        ds._setMaxQuorumVotesBPS(newMaxQuorumVotesBPS);
    }

    /**
     * @notice Admin function for setting the dynamic quorum coefficient
     * @param newQuorumCoefficient the new coefficient, as a fixed point integer with 6 decimals
     */
    function _setQuorumCoefficient(uint32 newQuorumCoefficient) external {
        ds._setQuorumCoefficient(newQuorumCoefficient);
    }

    /**
     * @notice Admin function for setting all the dynamic quorum parameters
     * @param newMinQuorumVotesBPS minimum quorum votes bps
     *     Must be between `MIN_QUORUM_VOTES_BPS_LOWER_BOUND` and `MIN_QUORUM_VOTES_BPS_UPPER_BOUND`
     *     Must be lower than or equal to maxQuorumVotesBPS
     * @param newMaxQuorumVotesBPS maximum quorum votes bps
     *     Must be lower than `MAX_QUORUM_VOTES_BPS_UPPER_BOUND`
     *     Must be higher than or equal to minQuorumVotesBPS
     * @param newQuorumCoefficient the new coefficient, as a fixed point integer with 6 decimals
     */
    function _setDynamicQuorumParams(
        uint16 newMinQuorumVotesBPS,
        uint16 newMaxQuorumVotesBPS,
        uint32 newQuorumCoefficient
    ) public {
        ds._setDynamicQuorumParams(newMinQuorumVotesBPS, newMaxQuorumVotesBPS, newQuorumCoefficient);
    }

    /**
     * @notice Withdraws all the ETH in the contract. This is callable only by the admin (timelock).
     */
    function _withdraw() external returns (uint256, bool) {
        return ds._withdraw();
    }

    /**
     * @notice Admin function for setting the fork period
     * @param newForkPeriod the new fork proposal period, in seconds
     */
    function _setForkPeriod(uint256 newForkPeriod) external {
        ds._setForkPeriod(newForkPeriod);
    }

    /**
     * @notice Admin function for setting the fork threshold
     * @param newForkThresholdBPS the new fork proposal threshold, in basis points
     */
    function _setForkThresholdBPS(uint256 newForkThresholdBPS) external {
        ds._setForkThresholdBPS(newForkThresholdBPS);
    }

    /**
     * @notice Admin function for setting the proposal id at which vote snapshots start using the voting start block
     * instead of the proposal creation block.
     * Sets it to the next proposal id.
     */
    function _setVoteSnapshotBlockSwitchProposalId() external {
        ds._setVoteSnapshotBlockSwitchProposalId();
    }

    /**
     * @notice Admin function for setting the fork DAO deployer contract
     */
    function _setForkDAODeployer(address newForkDAODeployer) external {
        ds._setForkDAODeployer(newForkDAODeployer);
    }

    /**
     * @notice Admin function for setting the ERC20 tokens that are used when splitting funds to a fork
     */
    function _setErc20TokensToIncludeInFork(address[] calldata erc20tokens) external {
        ds._setErc20TokensToIncludeInFork(erc20tokens);
    }

    /**
     * @notice Admin function for setting the fork escrow contract
     */
    function _setForkEscrow(address newForkEscrow) external {
        ds._setForkEscrow(newForkEscrow);
    }

    /**
     * @notice Admin function for setting the fork related parameters
     * @param forkEscrow_ the fork escrow contract
     * @param forkDAODeployer_ the fork dao deployer contract
     * @param erc20TokensToIncludeInFork_ the ERC20 tokens used when splitting funds to a fork
     * @param forkPeriod_ the period during which it's possible to join a fork after exeuction
     * @param forkThresholdBPS_ the threshold required of escrowed nouns in order to execute a fork
     */
    function _setForkParams(
        address forkEscrow_,
        address forkDAODeployer_,
        address[] calldata erc20TokensToIncludeInFork_,
        uint256 forkPeriod_,
        uint256 forkThresholdBPS_
    ) external {
        ds._setForkEscrow(forkEscrow_);
        ds._setForkDAODeployer(forkDAODeployer_);
        ds._setErc20TokensToIncludeInFork(erc20TokensToIncludeInFork_);
        ds._setForkPeriod(forkPeriod_);
        ds._setForkThresholdBPS(forkThresholdBPS_);
    }

    /**
     * @notice Admin function for setting the timelocks and admin
     * @param newTimelock the new timelock contract
     * @param newTimelockV1 the new timelockV1 contract
     * @param newAdmin the new admin address
     */
    function _setTimelocksAndAdmin(
        address newTimelock,
        address newTimelockV1,
        address newAdmin
    ) external {
        ds._setTimelocksAndAdmin(newTimelock, newTimelockV1, newAdmin);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   DYNAMIC QUORUM
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Quorum votes required for a specific proposal to succeed
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function quorumVotes(uint256 proposalId) public view returns (uint256) {
        return ds.quorumVotes(proposalId);
    }

    /**
     * @notice Calculates the required quorum of for-votes based on the amount of against-votes
     *     The more against-votes there are for a proposal, the higher the required quorum is.
     *     The quorum BPS is between `params.minQuorumVotesBPS` and params.maxQuorumVotesBPS.
     *     The additional quorum is calculated as:
     *       quorumCoefficient * againstVotesBPS
     * @dev Note the coefficient is a fixed point integer with 6 decimals
     * @param againstVotes Number of against-votes in the proposal
     * @param adjustedTotalSupply_ The adjusted total supply of Nouns at the time of proposal creation
     * @param params Configurable parameters for calculating the quorum based on againstVotes. See `DynamicQuorumParams` definition for additional details.
     * @return quorumVotes The required quorum
     */
    function dynamicQuorumVotes(
        uint256 againstVotes,
        uint256 adjustedTotalSupply_,
        DynamicQuorumParams memory params
    ) public pure returns (uint256) {
        return NounsDAOV3DynamicQuorum.dynamicQuorumVotes(againstVotes, adjustedTotalSupply_, params);
    }

    /**
     * @notice returns the dynamic quorum parameters values at a certain block number
     * @dev The checkpoints array must not be empty, and the block number must be higher than or equal to
     *     the block of the first checkpoint
     * @param blockNumber_ the block number to get the params at
     * @return The dynamic quorum parameters that were set at the given block number
     */
    function getDynamicQuorumParamsAt(uint256 blockNumber_) public view returns (DynamicQuorumParams memory) {
        return ds.getDynamicQuorumParamsAt(blockNumber_);
    }

    /**
     * @notice Current min quorum votes using Nouns adjusted total supply
     */
    function minQuorumVotes() public view returns (uint256) {
        return ds.minQuorumVotes(ds.adjustedTotalSupply());
    }

    /**
     * @notice Current max quorum votes using Nouns adjusted total supply
     */
    function maxQuorumVotes() public view returns (uint256) {
        return ds.maxQuorumVotes(ds.adjustedTotalSupply());
    }

    /**
     * @notice Get all quorum params checkpoints
     */
    function quorumParamsCheckpoints() public view returns (DynamicQuorumParamsCheckpoint[] memory) {
        return ds.quorumParamsCheckpoints;
    }

    /**
     * @notice Get a quorum params checkpoint by its index
     */
    function quorumParamsCheckpoints(uint256 index) public view returns (DynamicQuorumParamsCheckpoint memory) {
        return ds.quorumParamsCheckpoints[index];
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   STATE VARIABLE GETTERS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function vetoer() public view returns (address) {
        return ds.vetoer;
    }

    function pendingVetoer() public view returns (address) {
        return ds.pendingVetoer;
    }

    function votingDelay() public view returns (uint256) {
        return ds.votingDelay;
    }

    function votingPeriod() public view returns (uint256) {
        return ds.votingPeriod;
    }

    function proposalThresholdBPS() public view returns (uint256) {
        return ds.proposalThresholdBPS;
    }

    function quorumVotesBPS() public view returns (uint256) {
        return ds.quorumVotesBPS;
    }

    function proposalCount() public view returns (uint256) {
        return ds.proposalCount;
    }

    function timelock() public view returns (INounsDAOExecutor) {
        return ds.timelock;
    }

    function nouns() public view returns (NounsTokenLike) {
        return ds.nouns;
    }

    function latestProposalIds(address account) public view returns (uint256) {
        return ds.latestProposalIds[account];
    }

    function lastMinuteWindowInBlocks() public view returns (uint256) {
        return ds.lastMinuteWindowInBlocks;
    }

    function objectionPeriodDurationInBlocks() public view returns (uint256) {
        return ds.objectionPeriodDurationInBlocks;
    }

    function erc20TokensToIncludeInFork() public view returns (address[] memory) {
        return ds.erc20TokensToIncludeInFork;
    }

    function forkEscrow() public view returns (INounsDAOForkEscrow) {
        return ds.forkEscrow;
    }

    function forkDAODeployer() public view returns (IForkDAODeployer) {
        return ds.forkDAODeployer;
    }

    function forkEndTimestamp() public view returns (uint256) {
        return ds.forkEndTimestamp;
    }

    function forkPeriod() public view returns (uint256) {
        return ds.forkPeriod;
    }

    function forkThresholdBPS() public view returns (uint256) {
        return ds.forkThresholdBPS;
    }

    function proposalUpdatablePeriodInBlocks() public view returns (uint256) {
        return ds.proposalUpdatablePeriodInBlocks;
    }

    function timelockV1() public view returns (address) {
        return address(ds.timelockV1);
    }

    function voteSnapshotBlockSwitchProposalId() public view returns (uint256) {
        return ds.voteSnapshotBlockSwitchProposalId;
    }

    receive() external payable {}
}
