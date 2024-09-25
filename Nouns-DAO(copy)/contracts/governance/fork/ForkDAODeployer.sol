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

/// @title The deployer of new Nouns DAO forks

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

import { ERC1967Proxy } from 'Nouns-DAO/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';
import { IForkDAODeployer, INounsDAOForkEscrow, NounsDAOStorageV3 } from '../NounsDAOInterfaces.sol';
import { NounsTokenFork } from './newdao/token/NounsTokenFork.sol';
import { NounsAuctionHouseFork } from './newdao/NounsAuctionHouseFork.sol';
import { NounsDAOExecutorV2 } from '../NounsDAOExecutorV2.sol';
import { NounsDAOProxy } from '../NounsDAOProxy.sol';
import { NounsDAOLogicV3 } from '../NounsDAOLogicV3.sol';
import { NounsDAOLogicV1Fork } from './newdao/governance/NounsDAOLogicV1Fork.sol';
import { NounsToken } from '../../NounsToken.sol';
import { NounsAuctionHouse } from '../../NounsAuctionHouse.sol';

contract ForkDAODeployer is IForkDAODeployer {
    event DAODeployed(address token, address auction, address governor, address treasury);

    /// @notice The token implementation address
    address public immutable tokenImpl;

    /// @notice The auction house implementation address
    address public immutable auctionImpl;

    /// @notice The treasury implementation address
    address public immutable treasuryImpl;

    /// @notice The governor implementation address
    address public immutable governorImpl;

    /// @notice The maximum duration of the governance delay in new DAOs
    uint256 public immutable delayedGovernanceMaxDuration;

    /// @notice The initial voting period in new DAOs, in blocks
    uint256 public immutable initialVotingPeriod;

    /// @notice The initial voting delay in new DAOs, in blocks
    uint256 public immutable initialVotingDelay;

    /// @notice The initial proposal threshold in new DAOs, in BPS
    uint256 public immutable initialProposalThresholdBPS;

    /// @notice The initial quorum votes in new DAOs, in BPS
    uint256 public immutable initialQuorumVotesBPS;

    constructor(
        address tokenImpl_,
        address auctionImpl_,
        address governorImpl_,
        address treasuryImpl_,
        uint256 delayedGovernanceMaxDuration_,
        uint256 initialVotingPeriod_,
        uint256 initialVotingDelay_,
        uint256 initialProposalThresholdBPS_,
        uint256 initialQuorumVotesBPS_
    ) {
        tokenImpl = tokenImpl_;
        auctionImpl = auctionImpl_;
        governorImpl = governorImpl_;
        treasuryImpl = treasuryImpl_;
        delayedGovernanceMaxDuration = delayedGovernanceMaxDuration_;
        initialVotingPeriod = initialVotingPeriod_;
        initialVotingDelay = initialVotingDelay_;
        initialProposalThresholdBPS = initialProposalThresholdBPS_;
        initialQuorumVotesBPS = initialQuorumVotesBPS_;
    }

    /**
     * @notice Deploys a new Nouns DAO fork, including a new token, auction house, governor, and treasury.
     * All contracts are upgradable, and are almost entirely initialized with the same parameters as the original DAO.
     * @param forkingPeriodEndTimestamp The timestamp at which the forking period ends
     * @param forkEscrow The address of the fork escrow contract, used for claiming tokens that were escrowed in the original DAO
     * and to get references to the original DAO's auction house and timelock
     * @return treasury The address of the fork DAO treasury
     * @return token The address of the fork DAO token
     */
    function deployForkDAO(uint256 forkingPeriodEndTimestamp, INounsDAOForkEscrow forkEscrow)
        external
        returns (address treasury, address token)
    {
        token = address(new ERC1967Proxy(tokenImpl, ''));
        address auction = address(new ERC1967Proxy(auctionImpl, ''));
        address governor = address(new ERC1967Proxy(governorImpl, ''));
        treasury = address(new ERC1967Proxy(treasuryImpl, ''));

        NounsAuctionHouse originalAuction = getOriginalAuction(forkEscrow);
        NounsDAOExecutorV2 originalTimelock = getOriginalTimelock(forkEscrow);

        NounsTokenFork(token).initialize(
            treasury,
            auction,
            forkEscrow,
            forkEscrow.forkId(),
            getStartNounId(originalAuction),
            forkEscrow.numTokensInEscrow(),
            forkingPeriodEndTimestamp
        );

        NounsAuctionHouseFork(auction).initialize(
            treasury,
            NounsToken(token),
            originalAuction.weth(),
            originalAuction.timeBuffer(),
            originalAuction.reservePrice(),
            originalAuction.minBidIncrementPercentage(),
            originalAuction.duration()
        );

        initDAO(governor, treasury, token, originalTimelock);

        NounsDAOExecutorV2(payable(treasury)).initialize(governor, originalTimelock.delay());

        emit DAODeployed(token, auction, governor, treasury);
    }

    /**
     * @dev Used to prevent the 'Stack too deep' error in the main deploy function.
     */
    function initDAO(
        address governor,
        address treasury,
        address token,
        NounsDAOExecutorV2 originalTimelock
    ) internal {
        NounsDAOLogicV3 originalDAO = NounsDAOLogicV3(payable(originalTimelock.admin()));
        NounsDAOLogicV1Fork(governor).initialize(
            treasury,
            token,
            initialVotingPeriod,
            initialVotingDelay,
            initialProposalThresholdBPS,
            initialQuorumVotesBPS,
            originalDAO.erc20TokensToIncludeInFork(),
            block.timestamp + delayedGovernanceMaxDuration
        );
    }

    /**
     * @dev Used to prevent the 'Stack too deep' error in the main deploy function.
     */
    function getOriginalTimelock(INounsDAOForkEscrow forkEscrow) internal view returns (NounsDAOExecutorV2) {
        NounsToken originalToken = NounsToken(address(forkEscrow.nounsToken()));
        return NounsDAOExecutorV2(payable(originalToken.owner()));
    }

    /**
     * @dev Used to prevent the 'Stack too deep' error in the main deploy function.
     */
    function getOriginalAuction(INounsDAOForkEscrow forkEscrow) internal view returns (NounsAuctionHouse) {
        NounsToken originalToken = NounsToken(address(forkEscrow.nounsToken()));
        return NounsAuctionHouse(originalToken.minter());
    }

    function getStartNounId(NounsAuctionHouse originalAuction) internal view returns (uint256) {
        (uint256 nounId, , , , , ) = originalAuction.auction();
        return nounId;
    }
}
