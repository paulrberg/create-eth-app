/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/token-staking?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "token-staking/@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Wording below needs to properly represent the legal terms so has to be reviewed
/// @notice Comments have been written by the development team and may not represent the actual terms of the contract correctly

/// @title Oiler Staking
/// @author oiler.network
/// @dev that staking contract is fully dependent on the provided reward token and the underlying LP token.
/**
 * @notice Staking contract assumes there is a Staking Program going on until a specified Staking Program End Date.
 * And there is an amount of Oiler tokens that is gonna be given away to incentivise participation in the Staking Program (called StakingFund).
 * 
 * During this Program - users commit to lock tokens for some period of time, earning RewardPoints (if they don't unlock prematurely).
 * RewardPoints multiplier grows linearly with the locking period length (see the formula in calculateStakingRewardPoints() function)
 * 
 * After the end of the Staking Program - the amount of RewardPoints earned by each user is relatively compared to the total RewardPoints
 * earned by all staking participants - and the OIL tokens from StakingFund are divided among them accordingly, by their RewardPoints proportions.
 */
contract Staking {

  /**
   * @dev Saving gas by using lower-bit variables to fit the Stake struct into 256bits
   *
   * LP Tokens are calculated by this formula:
   * LP Tokens = sqrt(tokenAmount * e18 * usdcAmount * e6) =
   *           = sqrt(100 000 000 * usdcAmount * e24) =          // here 100 000 000 is totalSupply of OIL
   *           = sqrt(usdcAmount * e32) =
   *           = sqrt(usdcAmount) * e16
   * 
   * Thus the maximum amount of USDC we can use to not overflow the maximum amount of uint72 (4722 e18) will be:
   *             sqrt(usdcAmount) * e16 < 4722 * e18
   *             sqrt(usdcAmount) < 472 200
   *             usdcAmount < 222 972 840 000
   * Which is over two hundred trillion dollars - the amount highly improbable at our Uniswap pool as for today
   *
   * tokenAmount is limited by LP tokens amount (4722e18 LPs for hundreds of trillions of dollars)   (Range: [0 - 4722 e18]          - uint72 (max 4722 e18))
   * lockingPeriodInBlocks is limited by Staking Program duration (around 700000 blocks)             (Range: [1 - 700000]            - uint24 (max 16 777 215))
   * startBlock is in a typical range of Mainnet, Testnets, local networks blocks range              (Range: [0 - 100 000 000]       - uint32 (max 4 294 967 295))
   * 
   * expectedStakingRewardPoints is limited by:
   * LP tokens amount * lockingPeriodInBlocks * lockingPeriodInBlocks
   * which is:
   * uint72 * uint24 * uint24 = which gives us max uint120, but we use uint128 anyway                (Range: [0 - 1.33 e36]           - uint128 (max 340 e36))
   */
    struct Stake {
        uint72 tokenAmount;                   // Amount of tokens locked in a stake                                                             
        uint24 lockingPeriodInBlocks;         // Arbitrary lock period that will give you a reward                                    
        uint32 startBlock;                    // Start of the locking                                                                            
        uint128 expectedStakingRewardPoints;  // The amount of RewardPoints the stake will earn if not unlocked prematurely    
    }
    
    /// @notice Active stakes for each user
    mapping (address => Stake) public stakes;

    /// @notice "Reward points" each user earned (would be relative to totalRewardPoints to get the percentage)
    mapping (address => uint256) public rewardPointsEarned;
    
    /// @notice Total "reward points" all users earned
    uint256 public totalRewardPoints;
    /// @notice Block when Staking Program ends          
    uint256 immutable public stakingProgramEndsBlock;
    /// @notice Amount of Staking Bonus Fund (500 000 OIL), Oiler funds must be here, approved and ready to be transferredFrom
    uint256 immutable public stakingFundAmount;
    
    /// @notice Uniswap pool that we accept LP tokens from
    IERC20 public poolToken;
    /// @notice Oiler token that will be given as a reward
    IERC20 immutable public oilerToken;
    
    /// @notice The amount of OIL tokens earned, granted to be released during vesting period 
    mapping (address => uint256) public grantedTokens;
    /// @notice The amount of OIL tokens that were already released during vesting period
    mapping (address => uint256) public releasedTokens;
    
    /// @dev In blocks - should be around 100 days
    uint256 immutable public vestingDuration;

    /// @dev Check if poolToken was initialized
    modifier poolTokenSet() {
        require(address(poolToken) != address(0x0), "poolToken not set");
        _;
    }

    /// @dev Owner is used only in setPoolToken()
    address immutable public owner;

    /// @dev Used only in setPoolToken()
    modifier onlyOwner() {
        require(msg.sender == owner, "Can only be called by owner");
        _;
    }

    /**
     * @dev before deploying the stakingFundAddress must have set allowances on behalf of that contract. The address can be predicted basing on the CREATE or CREATE2 opcode.
     * @param oilerToken_ - address of the token in which rewards will be payed off.
     * @param stakingDurationInBlocks_ - Number of blocks after which staking will end.
     * @param stakingFundAmount_ - Amount of tokens to be payed of as rewards.
     * @param vestingDuration_ - Number of blocks after which OIL tokens earned by staking will be released (duration of Vesting period).
     * @param owner_ - Owner of the contract (is used to initialize poolToken after it's available).
     */
    constructor(address oilerToken_, uint256 stakingDurationInBlocks_, uint256 stakingFundAmount_, uint256 vestingDuration_, address owner_) {
        require(owner_ != address(0x0), "Owner address cannot be zero");
        owner = owner_;

        require(oilerToken_ != address(0x0), "oilerToken address cannot be zero");
        oilerToken = IERC20(oilerToken_);
        
        stakingProgramEndsBlock = block.number + stakingDurationInBlocks_;
        vestingDuration = vestingDuration_;

        
        stakingFundAmount = stakingFundAmount_;
    }

    /// @notice Initialize poolToken when OIL<>USDC Uniswap pool is available
    function setPoolToken(address poolToken_, address stakingFundAddress_) public onlyOwner {
        require(address(poolToken) == address(0x0), "poolToken was already set");
        require(poolToken_ != address(0x0), "poolToken address cannot be zero");
        poolToken = IERC20(poolToken_);
        // Transfer the Staking Bonus Funds from stakingFundAddress here
        require(IERC20(oilerToken).balanceOf(stakingFundAddress_) >= stakingFundAmount, "StakingFund doesn't have enough OIL balance");
        require(IERC20(oilerToken).allowance(stakingFundAddress_, address(this)) >= stakingFundAmount, "StakingFund doesn't have enough allowance");
        require(IERC20(oilerToken).transferFrom(stakingFundAddress_, address(this), stakingFundAmount), "TransferFrom of OIL from StakingFund failed");
    }

    /**
     * @notice Calculates the RewardPoints user will earn for a given tokenAmount locked for a given period
     * @dev If any parameter is zero - it will fail, thus we save gas on "requires" by not checking in other places
     * @param tokenAmount_ - Amount of tokens to be stake.
     * @param lockingPeriodInBlocks_ - Lock duration defined in blocks.
     */
    function calculateStakingRewardPoints(uint72 tokenAmount_, uint24 lockingPeriodInBlocks_) public pure returns (uint128) {
        //
        //                         /                                   \
        //  stakingRewardPoints = ( tokenAmount * lockingPeriodInBlocks )  *  lockingPeriodInBlocks
        //                         \                                   /
        //

        uint256 stakingRewardPoints = uint256(tokenAmount_) * uint256(lockingPeriodInBlocks_) * uint256(lockingPeriodInBlocks_);
        require(stakingRewardPoints > 0, "Neither tokenAmount nor lockingPeriod couldn't be 0");
        return uint128(stakingRewardPoints);
    }

    /**
     * @notice Lock the LP tokens for a specified period of Blocks.
     * @notice Can only be called before Staking Program ends.
     * @notice And the locking period can't last longer than the end of Staking Program block.
     * @param tokenAmount_ - Amount of LP tokens to be locked.
     * @param lockingPeriodInBlocks_ - locking period duration defined in blocks.
     */
    function lockTokens(uint72 tokenAmount_, uint24 lockingPeriodInBlocks_) public poolTokenSet {
        // Here we don't check lockingPeriodInBlocks_ for being non-zero, cause its happening in calculateStakingRewardPoints() calculation
        require(block.number <= stakingProgramEndsBlock - lockingPeriodInBlocks_, "Your lock period exceeds Staking Program duration");
        require(stakes[msg.sender].tokenAmount == 0, "Already staking");

        // This is a locking reward - will be earned only after the full lock period is over - otherwise not applicable
        uint128 expectedStakingRewardPoints = calculateStakingRewardPoints(tokenAmount_, lockingPeriodInBlocks_);

        Stake memory stake = Stake(tokenAmount_, lockingPeriodInBlocks_, uint32(block.number), expectedStakingRewardPoints);
        stakes[msg.sender] = stake;
        
        // We add the rewards initially during locking of tokens, and subtract them later if unlocking is made prematurely
        // That prevents us from waiting for all users to unlock to distribute the rewards after Staking Program Ends
        totalRewardPoints += expectedStakingRewardPoints;
        rewardPointsEarned[msg.sender] += expectedStakingRewardPoints;
        
        // We transfer LP tokens from user to this contract, "locking" them
        // We don't check for allowances or balance cause it's done within the transferFrom() and would only raise gas costs
        require(poolToken.transferFrom(msg.sender, address(this), tokenAmount_), "TransferFrom of poolTokens failed");

        emit StakeLocked(msg.sender, tokenAmount_, lockingPeriodInBlocks_, expectedStakingRewardPoints);
    }

    /**
     * @notice Unlock the tokens and get the reward
     * @notice This can be called at any time, even after Staking Program end block
     */
    function unlockTokens() public poolTokenSet {
        Stake memory stake = stakes[msg.sender];

        uint256 stakeAmount = stake.tokenAmount;

        require(stakeAmount != 0, "You don't have a stake to unlock");

        require(block.number > stake.startBlock, "You can't withdraw the stake in the same block it was locked");

        // Check if the unlock is called prematurely - and subtract the reward if it is the case
        _punishEarlyWithdrawal(stake);

        // Zero the Stake - to protect from double-unlocking and to be able to stake again
        delete stakes[msg.sender];

        require(poolToken.transfer(msg.sender, stakeAmount), "Pool token transfer failed");
    }
    
    /**
     * @notice If the unlock is called prematurely - we subtract the bonus
     */
    function _punishEarlyWithdrawal(Stake memory stake_) internal {
        // As any of the locking periods can't be longer than Staking Program end block - this will automatically mean that if called after Staking Program end - all stakes locking periods are over
        // So no rewards can be manipulated after Staking Program ends
        if (block.number < (stake_.startBlock + stake_.lockingPeriodInBlocks)) { // lt - cause you can only withdraw at or after startBlock + lockPeriod
            rewardPointsEarned[msg.sender] -= stake_.expectedStakingRewardPoints;
            totalRewardPoints -= stake_.expectedStakingRewardPoints;
            emit StakeUnlockedPrematurely(msg.sender, stake_.tokenAmount, stake_.lockingPeriodInBlocks, block.number - stake_.startBlock);
        } else {
            emit StakeUnlocked(msg.sender, stake_.tokenAmount, stake_.lockingPeriodInBlocks, stake_.expectedStakingRewardPoints);
        }
    }
    
    /** 
     * @notice This can only be called after the Staking Program ended
     * @dev Which means that all stakes lock periods are already over, and totalRewardPoints value isn't changing anymore - so we can now calculate the percentages of rewards
     */
    function getRewards() public {
        require(block.number > stakingProgramEndsBlock, "You can only get Rewards after Staking Program ends");
        require(stakes[msg.sender].tokenAmount == 0, "You still have a stake locked - please unlock first, don't leave free money here");
        require(rewardPointsEarned[msg.sender] > 0, "You don't have any rewardPoints");
        
        // The amount earned is calculated as:
        //
        //                                  user RewardPoints earned during Staking Program
        // amountEarned = stakingFund * -------------------------------------------------------
        //                                 total RewardPoints earned by everyone participated
        //
        // Division always rounds towards zero in solidity.
        // And because of this rounding somebody always misses the fractional part of their earnings and gets only integer amount.
        // Thus the worst thing that can happen is amountEarned becomes 0, and we check for that in _grantTokens()
        uint256 amountEarned = stakingFundAmount * rewardPointsEarned[msg.sender] / totalRewardPoints;
        rewardPointsEarned[msg.sender] = 0; // Zero rewardPoints of a user - so this function can be called only once per user

        _grantTokens(msg.sender, amountEarned); // Grant OIL reward earned by user for future vesting during the Vesting period
    }
    
    //////////////////////////////////////////////////////
    //
    //     VESTING PART
    //
    //////////////////////////////////////////////////////
    

    /**
     * @param recipient_ - Recipient of granted tokens
     * @param amountEarned_ - Amount of tokens earned to be granted
     */
    function _grantTokens(address recipient_, uint256 amountEarned_) internal {
        require(amountEarned_ > 0, "You didn't earn any integer amount of wei");
        require(recipient_ != address(0), "TokenVesting: beneficiary is the zero address");
        grantedTokens[recipient_] = amountEarned_;
        emit RewardGranted(recipient_, amountEarned_);
    }
    
    /// @notice Releases granted tokens
    function release() public {
        uint256 releasable = _releasableAmount(msg.sender);
        require(releasable > 0, "Vesting release: no tokens are due");

        releasedTokens[msg.sender] += releasable;
        require(oilerToken.transfer(msg.sender, releasable), "Reward oilers transfer failed");

        emit grantedTokensReleased(msg.sender, releasable);
    }
    
    /// @notice Releasable amount is what is available at a given time minus what was already withdrawn
    function _releasableAmount(address recipient_) internal view returns (uint256) {
        return _vestedAmount(recipient_) - releasedTokens[recipient_];
    }
    
    /**
     * @notice The output of this function gradually changes from [0.. to ..grantedAmount] while the vesting is going
     * @param recipient_ - vested tokens recipient
     * @return vested amount
     */
    function _vestedAmount(address recipient_) internal view returns (uint256) {
        if (block.number >= stakingProgramEndsBlock + vestingDuration) {
            // Return the full granted amount if Vesting Period is over
            return grantedTokens[recipient_];
        } else {
            // Return the proportional amount if Vesting Period is still going
            return grantedTokens[recipient_] * (block.number - stakingProgramEndsBlock) / vestingDuration;
        }
    }
    
    event StakeLocked(address recipient, uint256 tokenAmount, uint256 lockingPeriodInBlocks, uint256 expectedStakingRewardPoints);
    event StakeUnlockedPrematurely(address recipient, uint256 tokenAmount, uint256 lockingPeriodInBlocks, uint256 actualLockingPeriodInBlocks);
    event StakeUnlocked(address recipient, uint256 tokenAmount, uint256 lockingPeriodInBlocks, uint256 rewardPoints);
    event RewardGranted(address recipient, uint256 amountEarned);
    event grantedTokensReleased(address recipient, uint256 amount);
}