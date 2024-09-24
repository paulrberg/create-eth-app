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

/// @title Library for NounsDAOLogicV3 contract containing all the voting related code

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
import { NounsDAOV3Proposals } from './NounsDAOV3Proposals.sol';
import { SafeCast } from 'Nouns-DAO/@openzeppelin/contracts/utils/math/SafeCast.sol';

library NounsDAOV3Votes {
    using NounsDAOV3Proposals for NounsDAOStorageV3.StorageV3;

    error CanOnlyVoteAgainstDuringObjectionPeriod();

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice Emitted when a voter cast a vote requesting a gas refund.
    event RefundableVote(address indexed voter, uint256 refundAmount, bool refundSent);

    /// @notice Emitted when a proposal is set to have an objection period
    event ProposalObjectionPeriodSet(uint256 indexed id, uint256 objectionPeriodEndBlock);

    /// @notice The name of this contract
    string public constant name = 'Nouns DAO';

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256('Ballot(uint256 proposalId,uint8 support)');

    /// @notice The maximum priority fee used to cap gas refunds in `castRefundableVote`
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice The vote refund gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REFUND_BASE_GAS = 36000;

    /// @notice The maximum gas units the DAO will refund voters on; supports about 9,190 characters
    uint256 public constant MAX_REFUND_GAS_USED = 200_000;

    /// @notice The maximum basefee the DAO will refund voters on
    uint256 public constant MAX_REFUND_BASE_FEE = 200 gwei;

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint8 support
    ) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(ds, msg.sender, proposalId, support), '');
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
    function castRefundableVote(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint8 support
    ) external {
        castRefundableVoteInternal(ds, proposalId, support, '');
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
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        castRefundableVoteInternal(ds, proposalId, support, reason);
    }

    /**
     * @notice Internal function that carries out refundable voting logic
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     * @dev Reentrancy is defended against in `castVoteInternal` at the `receipt.hasVoted == false` require statement.
     */
    function castRefundableVoteInternal(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint8 support,
        string memory reason
    ) internal {
        uint256 startGas = gasleft();
        uint96 votes = castVoteInternal(ds, msg.sender, proposalId, support);
        emit VoteCast(msg.sender, proposalId, support, votes, reason);
        if (votes > 0) {
            _refundGas(startGas);
        }
    }

    /**
     * @notice Cast a vote for a proposal with a reason
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castVoteWithReason(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(ds, msg.sender, proposalId, support), reason);
    }

    /**
     * @notice Cast a vote for a proposal by signature
     * @dev External function that accepts EIP-712 signatures for voting on proposals.
     */
    function castVoteBySig(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'NounsDAO::castVoteBySig: invalid signature');
        emit VoteCast(signatory, proposalId, support, castVoteInternal(ds, signatory, proposalId, support), '');
    }

    /**
     * @notice Internal function that caries out voting logic
     * In case of a vote during the 'last minute window', which changes the proposal outcome from being defeated to
     * passing, and objection period is adding to the proposal's voting period.
     * During the objection period, only votes against a proposal can be cast.
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function castVoteInternal(
        NounsDAOStorageV3.StorageV3 storage ds,
        address voter,
        uint256 proposalId,
        uint8 support
    ) internal returns (uint96) {
        NounsDAOStorageV3.ProposalState proposalState = ds.stateInternal(proposalId);

        if (proposalState == NounsDAOStorageV3.ProposalState.Active) {
            return castVoteDuringVotingPeriodInternal(ds, proposalId, voter, support);
        } else if (proposalState == NounsDAOStorageV3.ProposalState.ObjectionPeriod) {
            if (support != 0) revert CanOnlyVoteAgainstDuringObjectionPeriod();
            return castObjectionInternal(ds, proposalId, voter);
        }

        revert('NounsDAO::castVoteInternal: voting is closed');
    }

    /**
     * @notice Internal function that handles voting logic during the voting period.
     * @dev Assumes it's only called by `castVoteInternal` which ensures the proposal is active.
     * @param proposalId The id of the proposal being voted on
     * @param voter The address of the voter
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function castVoteDuringVotingPeriodInternal(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        address voter,
        uint8 support
    ) internal returns (uint96) {
        require(support <= 2, 'NounsDAO::castVoteDuringVotingPeriodInternal: invalid vote type');
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        NounsDAOStorageV3.Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, 'NounsDAO::castVoteDuringVotingPeriodInternal: voter already voted');

        /// @notice: Unlike GovernerBravo, votes are considered from the block the proposal was created in order to normalize quorumVotes and proposalThreshold metrics
        uint96 votes = ds.nouns.getPriorVotes(voter, proposalVoteSnapshotBlock(ds, proposalId, proposal));

        bool isForVoteInLastMinuteWindow = false;
        if (support == 1) {
            isForVoteInLastMinuteWindow = (proposal.endBlock - block.number < ds.lastMinuteWindowInBlocks);
        }

        bool isDefeatedBefore = false;
        if (isForVoteInLastMinuteWindow) isDefeatedBefore = ds.isDefeated(proposal);

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        if (
            // only for votes can trigger an objection period
            // we're in the last minute window
            isForVoteInLastMinuteWindow &&
            // first part of the vote flip check
            // separated from the second part to optimize gas
            isDefeatedBefore &&
            // haven't turn on objection yet
            proposal.objectionPeriodEndBlock == 0 &&
            // second part of the vote flip check
            !ds.isDefeated(proposal)
        ) {
            proposal.objectionPeriodEndBlock = SafeCast.toUint64(
                proposal.endBlock + ds.objectionPeriodDurationInBlocks
            );

            emit ProposalObjectionPeriodSet(proposal.id, proposal.objectionPeriodEndBlock);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    /**
     * @notice Internal function that handles against votes during an objection period.
     * @dev Assumes it's being called by `castVoteInternal` which ensures:
     * 1. The proposal is in the objection period state.
     * 2. The vote is an against vote.
     * @param proposalId The id of the proposal being voted on
     * @param voter The address of the voter
     * @return The number of votes cast
     */
    function castObjectionInternal(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        address voter
    ) internal returns (uint96) {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        NounsDAOStorageV3.Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, 'NounsDAO::castVoteInternal: voter already voted');

        uint96 votes = receipt.votes = ds.nouns.getPriorVotes(
            voter,
            proposalVoteSnapshotBlock(ds, proposalId, proposal)
        );
        receipt.hasVoted = true;
        receipt.support = 0;
        proposal.againstVotes = proposal.againstVotes + votes;

        return votes;
    }

    function _refundGas(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            uint256 basefee = min(block.basefee, MAX_REFUND_BASE_FEE);
            uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            (bool refundSent, ) = msg.sender.call{ value: refundAmount }('');
            emit RefundableVote(msg.sender, refundAmount, refundSent);
        }
    }

    /**
     * @notice Internal function that returns the snapshot block number to use given a proposalId. The choice is
     * between the proposal's creation block and the proposal's voting start block, to allow a smooth migration from
     * creation block to start block.
     * @param proposalId The id of the proposal being voted on
     * @param proposal The proposal storage reference, used to read `creationBlock` and `startBlock`
     */
    function proposalVoteSnapshotBlock(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        NounsDAOStorageV3.Proposal storage proposal
    ) internal view returns (uint256) {
        // The idea is to temporarily use this code that would still use `creationBlock` until all proposals are using
        // `startBlock`, then we can deploy a quick DAO fix that removes this line and only uses `startBlock`.
        // In that version upgrade we can also zero-out and remove this storage variable for max cleanup.
        uint256 voteSnapshotBlockSwitchProposalId = ds.voteSnapshotBlockSwitchProposalId;
        if (proposalId < voteSnapshotBlockSwitchProposalId || voteSnapshotBlockSwitchProposalId == 0) {
            return proposal.creationBlock;
        }
        return proposal.startBlock;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
