/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Eigenlayer?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "../interfaces/IDelegationManager.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/IVoteWeigher.sol";
import "../interfaces/IServiceManager.sol";

import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title Storage variables for the `VoteWeigherBase` contract.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This storage contract is separate from the logic to simplify the upgrade process.
 */
abstract contract VoteWeigherBaseStorage is Initializable, IVoteWeigher {
    /**
     * @notice In weighing a particular strategy, the amount of underlying asset for that strategy is
     * multiplied by its multiplier, then divided by WEIGHTING_DIVISOR
     */
    struct StrategyAndWeightingMultiplier {
        IStrategy strategy;
        uint96 multiplier;
    }

    /// @notice Constant used as a divisor in calculating weights.
    uint256 internal constant WEIGHTING_DIVISOR = 1e18;
    /// @notice Maximum length of dynamic arrays in the `strategiesConsideredAndMultipliers` mapping.
    uint8 internal constant MAX_WEIGHING_FUNCTION_LENGTH = 32;
    /// @notice Constant used as a divisor in dealing with BIPS amounts.
    uint256 internal constant MAX_BIPS = 10000;

    /// @notice The address of the Delegation contract for EigenLayer.
    IDelegationManager public immutable delegation;
    
    /// @notice The address of the StrategyManager contract for EigenLayer.
    IStrategyManager public immutable strategyManager;

    /// @notice The address of the Slasher contract for EigenLayer.
    ISlasher public immutable slasher;

    /// @notice The ServiceManager contract for this middleware, where tasks are created / initiated.
    IServiceManager public immutable serviceManager;

    /// @notice Number of quorums that are being used by the middleware.
    uint256 public immutable NUMBER_OF_QUORUMS;

    /**
     * @notice mapping from quorum number to the list of strategies considered and their
     * corresponding multipliers for that specific quorum
     */
    mapping(uint256 => StrategyAndWeightingMultiplier[]) public strategiesConsideredAndMultipliers;

    /**
     * @notice This defines the earnings split between different quorums. Mapping is quorumNumber => BIPS which the quorum earns, out of the total earnings.
     * @dev The sum of all entries, i.e. sum(quorumBips[0] through quorumBips[NUMBER_OF_QUORUMS - 1]) should *always* be 10,000!
     */
    mapping(uint256 => uint256) public quorumBips;

    constructor(
        IStrategyManager _strategyManager,
        IServiceManager _serviceManager,
        uint8 _NUMBER_OF_QUORUMS
    ) {
        // sanity check that the VoteWeigher is being initialized with at least 1 quorum
        require(_NUMBER_OF_QUORUMS != 0, "VoteWeigherBaseStorage.constructor: _NUMBER_OF_QUORUMS == 0");
        strategyManager = _strategyManager;
        delegation = _strategyManager.delegation();
        slasher = _strategyManager.slasher();
        serviceManager = _serviceManager;
        NUMBER_OF_QUORUMS = _NUMBER_OF_QUORUMS;
        // disable initializers so that the implementation contract cannot be initialized
        _disableInitializers();
    }
}
