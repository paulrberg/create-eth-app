/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

import "Synthetix/openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/token/ERC20/SafeERC20.sol";
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import "./Owned.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/ILiquidatorRewards.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/ISynthetixDebtShare.sol";

/// @title Liquidator Rewards (SIP-148)
/// @notice This contract holds SNX from liquidated positions.
/// @dev SNX stakers may claim their rewards based on their share of the debt pool.
contract LiquidatorRewards is ILiquidatorRewards, Owned, MixinSystemSettings, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    struct AccountRewardsEntry {
        uint128 claimable;
        uint128 entryAccumulatedRewards;
    }

    /* ========== STATE VARIABLES ========== */

    uint256 public accumulatedRewardsPerShare;

    mapping(address => AccountRewardsEntry) public entries;
    mapping(address => bool) public initiated;

    bytes32 public constant CONTRACT_NAME = "LiquidatorRewards";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYNTHETIXDEBTSHARE = "SynthetixDebtShare";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](4);
        newAddresses[0] = CONTRACT_SYNTHETIXDEBTSHARE;
        newAddresses[1] = CONTRACT_ISSUER;
        newAddresses[2] = CONTRACT_REWARDESCROW_V2;
        newAddresses[3] = CONTRACT_SYNTHETIX;
        return combineArrays(existingAddresses, newAddresses);
    }

    function synthetixDebtShare() internal view returns (ISynthetixDebtShare) {
        return ISynthetixDebtShare(requireAndGetAddress(CONTRACT_SYNTHETIXDEBTSHARE));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }

    function synthetix() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function earned(address account) public view returns (uint256) {
        AccountRewardsEntry memory entry = entries[account];
        return
            synthetixDebtShare()
                .balanceOf(account)
                .multiplyDecimal(accumulatedRewardsPerShare.sub(entry.entryAccumulatedRewards))
                .add(entry.claimable);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward(address account) external nonReentrant {
        updateEntry(account);

        uint256 reward = entries[account].claimable;
        if (reward > 0) {
            entries[account].claimable = 0;
            synthetix().approve(address(rewardEscrowV2()), reward);
            rewardEscrowV2().createEscrowEntry(account, reward, getLiquidationEscrowDuration());
            emit RewardPaid(account, reward);
        }
    }

    // called every time a user's number of debt shares changes, or they claim rewards
    // has no useful purpose if called outside of these cases
    function updateEntry(address account) public {
        // when user enters for the first time
        if (!initiated[account]) {
            entries[account].entryAccumulatedRewards = uint128(accumulatedRewardsPerShare);
            initiated[account] = true;
        } else {
            entries[account] = AccountRewardsEntry(uint128(earned(account)), uint128(accumulatedRewardsPerShare));
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice This is called only after an account is liquidated and the SNX rewards are sent to this contract.
    function notifyRewardAmount(uint256 reward) external onlySynthetix {
        uint sharesSupply = synthetixDebtShare().totalSupply();

        if (sharesSupply > 0) {
            accumulatedRewardsPerShare = accumulatedRewardsPerShare.add(reward.divideDecimal(sharesSupply));
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlySynthetix {
        bool isSynthetix = msg.sender == address(synthetix());
        require(isSynthetix, "Synthetix only");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardPaid(address indexed user, uint256 reward);
}
