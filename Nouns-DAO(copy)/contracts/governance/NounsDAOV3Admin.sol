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

/// @title Library for NounsDAOLogicV3 contract containing admin related functions

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
import { NounsDAOV3DynamicQuorum } from './NounsDAOV3DynamicQuorum.sol';

library NounsDAOV3Admin {
    using NounsDAOV3DynamicQuorum for NounsDAOStorageV3.StorageV3;

    error AdminOnly();
    error VetoerOnly();
    error PendingVetoerOnly();
    error InvalidMinQuorumVotesBPS();
    error InvalidMaxQuorumVotesBPS();
    error MinQuorumBPSGreaterThanMaxQuorumBPS();
    error ForkPeriodTooLong();
    error ForkPeriodTooShort();
    error InvalidObjectionPeriodDurationInBlocks();
    error InvalidProposalUpdatablePeriodInBlocks();
    error VoteSnapshotSwitchAlreadySet();
    error DuplicateTokenAddress();

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice An event emitted when the objection period duration is set
    event ObjectionPeriodDurationSet(
        uint32 oldObjectionPeriodDurationInBlocks,
        uint32 newObjectionPeriodDurationInBlocks
    );

    /// @notice An event emitted when the objection period last minute window is set
    event LastMinuteWindowSet(uint32 oldLastMinuteWindowInBlocks, uint32 newLastMinuteWindowInBlocks);

    /// @notice An event emitted when the proposal updatable period is set
    event ProposalUpdatablePeriodSet(
        uint32 oldProposalUpdatablePeriodInBlocks,
        uint32 newProposalUpdatablePeriodInBlocks
    );

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when pendingVetoer is changed
    event NewPendingVetoer(address oldPendingVetoer, address newPendingVetoer);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);

    /// @notice Emitted when minQuorumVotesBPS is set
    event MinQuorumVotesBPSSet(uint16 oldMinQuorumVotesBPS, uint16 newMinQuorumVotesBPS);

    /// @notice Emitted when maxQuorumVotesBPS is set
    event MaxQuorumVotesBPSSet(uint16 oldMaxQuorumVotesBPS, uint16 newMaxQuorumVotesBPS);

    /// @notice Emitted when quorumCoefficient is set
    event QuorumCoefficientSet(uint32 oldQuorumCoefficient, uint32 newQuorumCoefficient);

    /// @notice Emitted when admin withdraws the DAO's balance.
    event Withdraw(uint256 amount, bool sent);

    /// @notice Emitted when the proposal id at which vote snapshot block changes is set
    event VoteSnapshotBlockSwitchProposalIdSet(
        uint256 oldVoteSnapshotBlockSwitchProposalId,
        uint256 newVoteSnapshotBlockSwitchProposalId
    );

    /// @notice Emitted when the fork DAO deployer is set
    event ForkDAODeployerSet(address oldForkDAODeployer, address newForkDAODeployer);

    /// @notice Emitted when the erc20 tokens to include in a fork are set
    event ERC20TokensToIncludeInForkSet(address[] oldErc20Tokens, address[] newErc20tokens);

    /// @notice Emitted when the fork escrow contract address is set
    event ForkEscrowSet(address oldForkEscrow, address newForkEscrow);

    /// @notice Emitted when the during of the forking period is set
    event ForkPeriodSet(uint256 oldForkPeriod, uint256 newForkPeriod);

    /// @notice Emitted when the threhsold for forking is set
    event ForkThresholdSet(uint256 oldForkThreshold, uint256 newForkThreshold);

    /// @notice Emitted when the main timelock, timelockV1 and admin are set
    event TimelocksAndAdminSet(address timelock, address timelockV1, address admin);

    /// @notice The minimum setable proposal threshold
    uint256 public constant MIN_PROPOSAL_THRESHOLD_BPS = 1; // 1 basis point or 0.01%

    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 1,000 basis points or 10%

    /// @notice The minimum setable voting period in blocks
    uint256 public constant MIN_VOTING_PERIOD_BLOCKS = 1 days / 12;

    /// @notice The max setable voting period in blocks
    uint256 public constant MAX_VOTING_PERIOD_BLOCKS = 2 weeks / 12;

    /// @notice The min setable voting delay in blocks
    uint256 public constant MIN_VOTING_DELAY_BLOCKS = 1;

    /// @notice The max setable voting delay in blocks
    uint256 public constant MAX_VOTING_DELAY_BLOCKS = 2 weeks / 12;

    /// @notice The lower bound of minimum quorum votes basis points
    uint256 public constant MIN_QUORUM_VOTES_BPS_LOWER_BOUND = 200; // 200 basis points or 2%

    /// @notice The upper bound of minimum quorum votes basis points
    uint256 public constant MIN_QUORUM_VOTES_BPS_UPPER_BOUND = 2_000; // 2,000 basis points or 20%

    /// @notice The upper bound of maximum quorum votes basis points
    uint256 public constant MAX_QUORUM_VOTES_BPS_UPPER_BOUND = 6_000; // 6,000 basis points or 60%

    /// @notice Upper bound for forking period. If forking period is too high it can block proposals for too long.
    uint256 public constant MAX_FORK_PERIOD = 14 days;

    /// @notice Lower bound for forking period
    uint256 public constant MIN_FORK_PERIOD = 2 days;

    /// @notice Upper bound for objection period duration in blocks.
    uint256 public constant MAX_OBJECTION_PERIOD_BLOCKS = 7 days / 12;

    /// @notice Upper bound for proposal updatable period duration in blocks.
    uint256 public constant MAX_UPDATABLE_PERIOD_BLOCKS = 7 days / 12;

    modifier onlyAdmin(NounsDAOStorageV3.StorageV3 storage ds) {
        if (msg.sender != ds.admin) {
            revert AdminOnly();
        }
        _;
    }

    /**
     * @notice Admin function for setting the voting delay. Best to set voting delay to at least a few days, to give
     * voters time to make sense of proposals, e.g. 21,600 blocks which should be at least 3 days.
     * @param newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(NounsDAOStorageV3.StorageV3 storage ds, uint256 newVotingDelay) external onlyAdmin(ds) {
        require(
            newVotingDelay >= MIN_VOTING_DELAY_BLOCKS && newVotingDelay <= MAX_VOTING_DELAY_BLOCKS,
            'NounsDAO::_setVotingDelay: invalid voting delay'
        );
        uint256 oldVotingDelay = ds.votingDelay;
        ds.votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, newVotingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * @param newVotingPeriod new voting period, in blocks
     */
    function _setVotingPeriod(NounsDAOStorageV3.StorageV3 storage ds, uint256 newVotingPeriod) external onlyAdmin(ds) {
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD_BLOCKS && newVotingPeriod <= MAX_VOTING_PERIOD_BLOCKS,
            'NounsDAO::_setVotingPeriod: invalid voting period'
        );
        uint256 oldVotingPeriod = ds.votingPeriod;
        ds.votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, newVotingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold basis points
     * @dev newProposalThresholdBPS must be in [`MIN_PROPOSAL_THRESHOLD_BPS`,`MAX_PROPOSAL_THRESHOLD_BPS`]
     * @param newProposalThresholdBPS new proposal threshold
     */
    function _setProposalThresholdBPS(NounsDAOStorageV3.StorageV3 storage ds, uint256 newProposalThresholdBPS)
        external
        onlyAdmin(ds)
    {
        require(
            newProposalThresholdBPS >= MIN_PROPOSAL_THRESHOLD_BPS &&
                newProposalThresholdBPS <= MAX_PROPOSAL_THRESHOLD_BPS,
            'NounsDAO::_setProposalThreshold: invalid proposal threshold bps'
        );
        uint256 oldProposalThresholdBPS = ds.proposalThresholdBPS;
        ds.proposalThresholdBPS = newProposalThresholdBPS;

        emit ProposalThresholdBPSSet(oldProposalThresholdBPS, newProposalThresholdBPS);
    }

    /**
     * @notice Admin function for setting the objection period duration
     * @param newObjectionPeriodDurationInBlocks new objection period duration, in blocks
     */
    function _setObjectionPeriodDurationInBlocks(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint32 newObjectionPeriodDurationInBlocks
    ) external onlyAdmin(ds) {
        if (newObjectionPeriodDurationInBlocks > MAX_OBJECTION_PERIOD_BLOCKS)
            revert InvalidObjectionPeriodDurationInBlocks();

        uint32 oldObjectionPeriodDurationInBlocks = ds.objectionPeriodDurationInBlocks;
        ds.objectionPeriodDurationInBlocks = newObjectionPeriodDurationInBlocks;

        emit ObjectionPeriodDurationSet(oldObjectionPeriodDurationInBlocks, newObjectionPeriodDurationInBlocks);
    }

    /**
     * @notice Admin function for setting the objection period last minute window
     * @param newLastMinuteWindowInBlocks new objection period last minute window, in blocks
     */
    function _setLastMinuteWindowInBlocks(NounsDAOStorageV3.StorageV3 storage ds, uint32 newLastMinuteWindowInBlocks)
        external
        onlyAdmin(ds)
    {
        uint32 oldLastMinuteWindowInBlocks = ds.lastMinuteWindowInBlocks;
        ds.lastMinuteWindowInBlocks = newLastMinuteWindowInBlocks;

        emit LastMinuteWindowSet(oldLastMinuteWindowInBlocks, newLastMinuteWindowInBlocks);
    }

    /**
     * @notice Admin function for setting the proposal updatable period
     * @param newProposalUpdatablePeriodInBlocks the new proposal updatable period, in blocks
     */
    function _setProposalUpdatablePeriodInBlocks(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint32 newProposalUpdatablePeriodInBlocks
    ) external onlyAdmin(ds) {
        if (newProposalUpdatablePeriodInBlocks > MAX_UPDATABLE_PERIOD_BLOCKS)
            revert InvalidProposalUpdatablePeriodInBlocks();

        uint32 oldProposalUpdatablePeriodInBlocks = ds.proposalUpdatablePeriodInBlocks;
        ds.proposalUpdatablePeriodInBlocks = newProposalUpdatablePeriodInBlocks;

        emit ProposalUpdatablePeriodSet(oldProposalUpdatablePeriodInBlocks, newProposalUpdatablePeriodInBlocks);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(NounsDAOStorageV3.StorageV3 storage ds, address newPendingAdmin) external onlyAdmin(ds) {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = ds.pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        ds.pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin(NounsDAOStorageV3.StorageV3 storage ds) external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(
            msg.sender == ds.pendingAdmin && msg.sender != address(0),
            'NounsDAO::_acceptAdmin: pending admin only'
        );

        // Save current values for inclusion in log
        address oldAdmin = ds.admin;
        address oldPendingAdmin = ds.pendingAdmin;

        // Store admin with value pendingAdmin
        ds.admin = ds.pendingAdmin;

        // Clear the pending value
        ds.pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, ds.admin);
        emit NewPendingAdmin(oldPendingAdmin, address(0));
    }

    /**
     * @notice Begins transition of vetoer. The newPendingVetoer must call _acceptVetoer to finalize the transfer.
     * @param newPendingVetoer New Pending Vetoer
     */
    function _setPendingVetoer(NounsDAOStorageV3.StorageV3 storage ds, address newPendingVetoer) public {
        if (msg.sender != ds.vetoer) {
            revert VetoerOnly();
        }

        emit NewPendingVetoer(ds.pendingVetoer, newPendingVetoer);

        ds.pendingVetoer = newPendingVetoer;
    }

    /**
     * @notice Called by the pendingVetoer to accept role and update vetoer
     */
    function _acceptVetoer(NounsDAOStorageV3.StorageV3 storage ds) external {
        if (msg.sender != ds.pendingVetoer) {
            revert PendingVetoerOnly();
        }

        // Update vetoer
        emit NewVetoer(ds.vetoer, ds.pendingVetoer);
        ds.vetoer = ds.pendingVetoer;

        // Clear the pending value
        emit NewPendingVetoer(ds.pendingVetoer, address(0));
        ds.pendingVetoer = address(0);
    }

    /**
     * @notice Burns veto priviledges
     * @dev Vetoer function destroying veto power forever
     */
    function _burnVetoPower(NounsDAOStorageV3.StorageV3 storage ds) public {
        // Check caller is vetoer
        require(msg.sender == ds.vetoer, 'NounsDAO::_burnVetoPower: vetoer only');

        // Update vetoer to 0x0
        emit NewVetoer(ds.vetoer, address(0));
        ds.vetoer = address(0);

        // Clear the pending value
        emit NewPendingVetoer(ds.pendingVetoer, address(0));
        ds.pendingVetoer = address(0);
    }

    /**
     * @notice Admin function for setting the minimum quorum votes bps
     * @param newMinQuorumVotesBPS minimum quorum votes bps
     *     Must be between `MIN_QUORUM_VOTES_BPS_LOWER_BOUND` and `MIN_QUORUM_VOTES_BPS_UPPER_BOUND`
     *     Must be lower than or equal to maxQuorumVotesBPS
     */
    function _setMinQuorumVotesBPS(NounsDAOStorageV3.StorageV3 storage ds, uint16 newMinQuorumVotesBPS)
        external
        onlyAdmin(ds)
    {
        NounsDAOStorageV3.DynamicQuorumParams memory params = ds.getDynamicQuorumParamsAt(block.number);

        require(
            newMinQuorumVotesBPS >= MIN_QUORUM_VOTES_BPS_LOWER_BOUND &&
                newMinQuorumVotesBPS <= MIN_QUORUM_VOTES_BPS_UPPER_BOUND,
            'NounsDAO::_setMinQuorumVotesBPS: invalid min quorum votes bps'
        );
        require(
            newMinQuorumVotesBPS <= params.maxQuorumVotesBPS,
            'NounsDAO::_setMinQuorumVotesBPS: min quorum votes bps greater than max'
        );

        uint16 oldMinQuorumVotesBPS = params.minQuorumVotesBPS;
        params.minQuorumVotesBPS = newMinQuorumVotesBPS;

        _writeQuorumParamsCheckpoint(ds, params);

        emit MinQuorumVotesBPSSet(oldMinQuorumVotesBPS, newMinQuorumVotesBPS);
    }

    /**
     * @notice Admin function for setting the maximum quorum votes bps
     * @param newMaxQuorumVotesBPS maximum quorum votes bps
     *     Must be lower than `MAX_QUORUM_VOTES_BPS_UPPER_BOUND`
     *     Must be higher than or equal to minQuorumVotesBPS
     */
    function _setMaxQuorumVotesBPS(NounsDAOStorageV3.StorageV3 storage ds, uint16 newMaxQuorumVotesBPS)
        external
        onlyAdmin(ds)
    {
        NounsDAOStorageV3.DynamicQuorumParams memory params = ds.getDynamicQuorumParamsAt(block.number);

        require(
            newMaxQuorumVotesBPS <= MAX_QUORUM_VOTES_BPS_UPPER_BOUND,
            'NounsDAO::_setMaxQuorumVotesBPS: invalid max quorum votes bps'
        );
        require(
            params.minQuorumVotesBPS <= newMaxQuorumVotesBPS,
            'NounsDAO::_setMaxQuorumVotesBPS: min quorum votes bps greater than max'
        );

        uint16 oldMaxQuorumVotesBPS = params.maxQuorumVotesBPS;
        params.maxQuorumVotesBPS = newMaxQuorumVotesBPS;

        _writeQuorumParamsCheckpoint(ds, params);

        emit MaxQuorumVotesBPSSet(oldMaxQuorumVotesBPS, newMaxQuorumVotesBPS);
    }

    /**
     * @notice Admin function for setting the dynamic quorum coefficient
     * @param newQuorumCoefficient the new coefficient, as a fixed point integer with 6 decimals
     */
    function _setQuorumCoefficient(NounsDAOStorageV3.StorageV3 storage ds, uint32 newQuorumCoefficient)
        external
        onlyAdmin(ds)
    {
        NounsDAOStorageV3.DynamicQuorumParams memory params = ds.getDynamicQuorumParamsAt(block.number);

        uint32 oldQuorumCoefficient = params.quorumCoefficient;
        params.quorumCoefficient = newQuorumCoefficient;

        _writeQuorumParamsCheckpoint(ds, params);

        emit QuorumCoefficientSet(oldQuorumCoefficient, newQuorumCoefficient);
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
        NounsDAOStorageV3.StorageV3 storage ds,
        uint16 newMinQuorumVotesBPS,
        uint16 newMaxQuorumVotesBPS,
        uint32 newQuorumCoefficient
    ) public onlyAdmin(ds) {
        if (
            newMinQuorumVotesBPS < MIN_QUORUM_VOTES_BPS_LOWER_BOUND ||
            newMinQuorumVotesBPS > MIN_QUORUM_VOTES_BPS_UPPER_BOUND
        ) {
            revert InvalidMinQuorumVotesBPS();
        }
        if (newMaxQuorumVotesBPS > MAX_QUORUM_VOTES_BPS_UPPER_BOUND) {
            revert InvalidMaxQuorumVotesBPS();
        }
        if (newMinQuorumVotesBPS > newMaxQuorumVotesBPS) {
            revert MinQuorumBPSGreaterThanMaxQuorumBPS();
        }

        NounsDAOStorageV3.DynamicQuorumParams memory oldParams = ds.getDynamicQuorumParamsAt(block.number);

        NounsDAOStorageV3.DynamicQuorumParams memory params = NounsDAOStorageV3.DynamicQuorumParams({
            minQuorumVotesBPS: newMinQuorumVotesBPS,
            maxQuorumVotesBPS: newMaxQuorumVotesBPS,
            quorumCoefficient: newQuorumCoefficient
        });
        _writeQuorumParamsCheckpoint(ds, params);

        emit MinQuorumVotesBPSSet(oldParams.minQuorumVotesBPS, params.minQuorumVotesBPS);
        emit MaxQuorumVotesBPSSet(oldParams.maxQuorumVotesBPS, params.maxQuorumVotesBPS);
        emit QuorumCoefficientSet(oldParams.quorumCoefficient, params.quorumCoefficient);
    }

    /**
     * @notice Withdraws all the ETH in the contract. This is callable only by the admin (timelock).
     */
    function _withdraw(NounsDAOStorageV3.StorageV3 storage ds) external onlyAdmin(ds) returns (uint256, bool) {
        uint256 amount = address(this).balance;
        (bool sent, ) = msg.sender.call{ value: amount }('');

        emit Withdraw(amount, sent);

        return (amount, sent);
    }

    /**
     * @notice Admin function for setting the proposal id at which vote snapshots start using the voting start block
     * instead of the proposal creation block.
     * Sets it to the next proposal id.
     */
    function _setVoteSnapshotBlockSwitchProposalId(NounsDAOStorageV3.StorageV3 storage ds) external onlyAdmin(ds) {
        uint256 oldVoteSnapshotBlockSwitchProposalId = ds.voteSnapshotBlockSwitchProposalId;
        if (oldVoteSnapshotBlockSwitchProposalId > 0) {
            revert VoteSnapshotSwitchAlreadySet();
        }

        uint256 newVoteSnapshotBlockSwitchProposalId = ds.proposalCount + 1;
        ds.voteSnapshotBlockSwitchProposalId = newVoteSnapshotBlockSwitchProposalId;

        emit VoteSnapshotBlockSwitchProposalIdSet(
            oldVoteSnapshotBlockSwitchProposalId,
            newVoteSnapshotBlockSwitchProposalId
        );
    }

    /**
     * @notice Admin function for setting the fork DAO deployer contract
     */
    function _setForkDAODeployer(NounsDAOStorageV3.StorageV3 storage ds, address newForkDAODeployer)
        external
        onlyAdmin(ds)
    {
        address oldForkDAODeployer = address(ds.forkDAODeployer);
        ds.forkDAODeployer = IForkDAODeployer(newForkDAODeployer);

        emit ForkDAODeployerSet(oldForkDAODeployer, newForkDAODeployer);
    }

    /**
     * @notice Admin function for setting the ERC20 tokens that are used when splitting funds to a fork
     */
    function _setErc20TokensToIncludeInFork(NounsDAOStorageV3.StorageV3 storage ds, address[] calldata erc20tokens)
        external
        onlyAdmin(ds)
    {
        checkForDuplicates(erc20tokens);

        emit ERC20TokensToIncludeInForkSet(ds.erc20TokensToIncludeInFork, erc20tokens);

        ds.erc20TokensToIncludeInFork = erc20tokens;
    }

    /**
     * @notice Admin function for setting the fork escrow contract
     */
    function _setForkEscrow(NounsDAOStorageV3.StorageV3 storage ds, address newForkEscrow) external onlyAdmin(ds) {
        emit ForkEscrowSet(address(ds.forkEscrow), newForkEscrow);

        ds.forkEscrow = INounsDAOForkEscrow(newForkEscrow);
    }

    function _setForkPeriod(NounsDAOStorageV3.StorageV3 storage ds, uint256 newForkPeriod) external onlyAdmin(ds) {
        if (newForkPeriod > MAX_FORK_PERIOD) {
            revert ForkPeriodTooLong();
        }

        if (newForkPeriod < MIN_FORK_PERIOD) {
            revert ForkPeriodTooShort();
        }

        emit ForkPeriodSet(ds.forkPeriod, newForkPeriod);

        ds.forkPeriod = newForkPeriod;
    }

    /**
     * @notice Admin function for setting the fork threshold
     * @param newForkThresholdBPS the new fork proposal threshold, in basis points
     */
    function _setForkThresholdBPS(NounsDAOStorageV3.StorageV3 storage ds, uint256 newForkThresholdBPS)
        external
        onlyAdmin(ds)
    {
        emit ForkThresholdSet(ds.forkThresholdBPS, newForkThresholdBPS);

        ds.forkThresholdBPS = newForkThresholdBPS;
    }

    /**
     * @notice Admin function for setting the timelocks and admin
     * @param timelock the new timelock contract
     * @param timelockV1 the new timelockV1 contract
     * @param admin the new admin address
     */
    function _setTimelocksAndAdmin(
        NounsDAOStorageV3.StorageV3 storage ds,
        address timelock,
        address timelockV1,
        address admin
    ) external onlyAdmin(ds) {
        ds.timelock = INounsDAOExecutorV2(timelock);
        ds.timelockV1 = INounsDAOExecutor(timelockV1);
        ds.admin = admin;

        emit TimelocksAndAdminSet(timelock, timelockV1, admin);
    }

    function _writeQuorumParamsCheckpoint(
        NounsDAOStorageV3.StorageV3 storage ds,
        NounsDAOStorageV3.DynamicQuorumParams memory params
    ) internal {
        uint32 blockNumber = safe32(block.number, 'block number exceeds 32 bits');
        uint256 pos = ds.quorumParamsCheckpoints.length;
        if (pos > 0 && ds.quorumParamsCheckpoints[pos - 1].fromBlock == blockNumber) {
            ds.quorumParamsCheckpoints[pos - 1].params = params;
        } else {
            ds.quorumParamsCheckpoints.push(
                NounsDAOStorageV3.DynamicQuorumParamsCheckpoint({ fromBlock: blockNumber, params: params })
            );
        }
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n <= type(uint32).max, errorMessage);
        return uint32(n);
    }

    function checkForDuplicates(address[] calldata erc20tokens) internal pure {
        if (erc20tokens.length == 0) return;

        for (uint256 i = 0; i < erc20tokens.length - 1; i++) {
            for (uint256 j = i + 1; j < erc20tokens.length; j++) {
                if (erc20tokens[i] == erc20tokens[j]) revert DuplicateTokenAddress();
            }
        }
    }
}
