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

import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IEigenPodManager.sol";
import "../interfaces/IDelayedWithdrawalRouter.sol";
import "../permissions/Pausable.sol";

contract DelayedWithdrawalRouter is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, Pausable, IDelayedWithdrawalRouter {
    /// @notice Emitted when the `withdrawalDelayBlocks` variable is modified from `previousValue` to `newValue`.
    event WithdrawalDelayBlocksSet(uint256 previousValue, uint256 newValue);

    // index for flag that pauses withdrawals (i.e. 'delayedWithdrawal claims') when set
    uint8 internal constant PAUSED_DELAYED_WITHDRAWAL_CLAIMS = 0;

    /**
     * @notice Delay enforced by this contract for completing any delayedWithdrawal. Measured in blocks, and adjustable by this contract's owner,
     * up to a maximum of `MAX_WITHDRAWAL_DELAY_BLOCKS`. Minimum value is 0 (i.e. no delay enforced).
     */
    uint256 public withdrawalDelayBlocks;
    // the number of 12-second blocks in one week (60 * 60 * 24 * 7 / 12 = 50,400)
    uint256 public constant MAX_WITHDRAWAL_DELAY_BLOCKS = 50400;

    /// @notice The EigenPodManager contract of EigenLayer.
    IEigenPodManager public immutable eigenPodManager;

    /// @notice Mapping: user => struct storing all delayedWithdrawal info. Marked as internal with an external getter function named `userWithdrawals`
    mapping(address => UserDelayedWithdrawals) internal _userWithdrawals;

    /// @notice event for delayedWithdrawal creation
    event DelayedWithdrawalCreated(address podOwner, address recipient, uint256 amount, uint256 index);

    /// @notice event for the claiming of delayedWithdrawals
    event DelayedWithdrawalsClaimed(address recipient, uint256 amountClaimed, uint256 delayedWithdrawalsCompleted);

    /// @notice Modifier used to permission a function to only be called by the EigenPod of the specified `podOwner`
    modifier onlyEigenPod(address podOwner) {
        require(address(eigenPodManager.getPod(podOwner)) == msg.sender, "DelayedWithdrawalRouter.onlyEigenPod: not podOwner's EigenPod");
        _;
    }

    constructor(IEigenPodManager _eigenPodManager) {
        require(address(_eigenPodManager) != address(0), "DelayedWithdrawalRouter.constructor: _eigenPodManager cannot be zero address");
        eigenPodManager = _eigenPodManager;
    }

    function initialize(address initOwner, IPauserRegistry _pauserRegistry, uint256 initPausedStatus, uint256 _withdrawalDelayBlocks) external initializer {
        _transferOwnership(initOwner);
        _initializePauser(_pauserRegistry, initPausedStatus);
        _setWithdrawalDelayBlocks(_withdrawalDelayBlocks);
    }

    /** 
     * @notice Creates a delayed withdrawal for `msg.value` to the `recipient`.
     * @dev Only callable by the `podOwner`'s EigenPod contract.
     */
    function createDelayedWithdrawal(address podOwner, address recipient) external payable onlyEigenPod(podOwner) onlyWhenNotPaused(PAUSED_DELAYED_WITHDRAWAL_CLAIMS) {
        require(recipient != address(0), "DelayedWithdrawalRouter.createDelayedWithdrawal: recipient cannot be zero address");
        uint224 withdrawalAmount = uint224(msg.value);
        if (withdrawalAmount != 0) {
            DelayedWithdrawal memory delayedWithdrawal = DelayedWithdrawal({
                amount: withdrawalAmount,
                blockCreated: uint32(block.number)
            });
            _userWithdrawals[recipient].delayedWithdrawals.push(delayedWithdrawal);
            emit DelayedWithdrawalCreated(podOwner, recipient, withdrawalAmount, _userWithdrawals[recipient].delayedWithdrawals.length - 1);
        }
    }

    /**
     * @notice Called in order to withdraw delayed withdrawals made to the `recipient` that have passed the `withdrawalDelayBlocks` period.
     * @param recipient The address to claim delayedWithdrawals for.
     * @param maxNumberOfDelayedWithdrawalsToClaim Used to limit the maximum number of delayedWithdrawals to loop through claiming.
     * @dev 
     *      WARNING: Note that the caller of this function cannot control where the funds are sent, but they can control when the 
     *              funds are sent once the withdrawal becomes claimable.
     */
    function claimDelayedWithdrawals(address recipient, uint256 maxNumberOfDelayedWithdrawalsToClaim)
        external
        nonReentrant
        onlyWhenNotPaused(PAUSED_DELAYED_WITHDRAWAL_CLAIMS)
    {
        _claimDelayedWithdrawals(recipient, maxNumberOfDelayedWithdrawalsToClaim);
    }

    /**
     * @notice Called in order to withdraw delayed withdrawals made to the caller that have passed the `withdrawalDelayBlocks` period.
     * @param maxNumberOfDelayedWithdrawalsToClaim Used to limit the maximum number of delayedWithdrawals to loop through claiming.
     */
    function claimDelayedWithdrawals(uint256 maxNumberOfDelayedWithdrawalsToClaim)
        external
        nonReentrant
        onlyWhenNotPaused(PAUSED_DELAYED_WITHDRAWAL_CLAIMS)
    {
        _claimDelayedWithdrawals(msg.sender, maxNumberOfDelayedWithdrawalsToClaim);
    }

    /// @notice Owner-only function for modifying the value of the `withdrawalDelayBlocks` variable.
    function setWithdrawalDelayBlocks(uint256 newValue) external onlyOwner {
        _setWithdrawalDelayBlocks(newValue);
    }

    /// @notice Getter function for the mapping `_userWithdrawals`
    function userWithdrawals(address user) external view returns (UserDelayedWithdrawals memory) {
        return _userWithdrawals[user];
    }

    /// @notice Getter function to get all delayedWithdrawals of the `user`
    function getUserDelayedWithdrawals(address user) external view returns (DelayedWithdrawal[] memory) {
        uint256 delayedWithdrawalsCompleted = _userWithdrawals[user].delayedWithdrawalsCompleted;
        uint256 totalDelayedWithdrawals = _userWithdrawals[user].delayedWithdrawals.length;
        uint256 userDelayedWithdrawalsLength = totalDelayedWithdrawals - delayedWithdrawalsCompleted;
        DelayedWithdrawal[] memory userDelayedWithdrawals = new DelayedWithdrawal[](userDelayedWithdrawalsLength);
        for (uint256 i = 0; i < userDelayedWithdrawalsLength; i++) {
            userDelayedWithdrawals[i] = _userWithdrawals[user].delayedWithdrawals[delayedWithdrawalsCompleted + i];
        }
        return userDelayedWithdrawals;
    }

    /// @notice Getter function to get all delayedWithdrawals that are currently claimable by the `user`
    function getClaimableUserDelayedWithdrawals(address user) external view returns (DelayedWithdrawal[] memory) {
        uint256 delayedWithdrawalsCompleted = _userWithdrawals[user].delayedWithdrawalsCompleted;
        uint256 totalDelayedWithdrawals = _userWithdrawals[user].delayedWithdrawals.length;
        uint256 userDelayedWithdrawalsLength = totalDelayedWithdrawals - delayedWithdrawalsCompleted;

        uint256 firstNonClaimableWithdrawalIndex = userDelayedWithdrawalsLength;

        for (uint256 i = 0; i < userDelayedWithdrawalsLength; i++) {
            DelayedWithdrawal memory delayedWithdrawal = _userWithdrawals[user].delayedWithdrawals[delayedWithdrawalsCompleted + i];
            // check if delayedWithdrawal can be claimed. break the loop as soon as a delayedWithdrawal cannot be claimed
            if (block.number < delayedWithdrawal.blockCreated + withdrawalDelayBlocks) {
                firstNonClaimableWithdrawalIndex = i;
                break;
            }
        }
        uint256 numberOfClaimableWithdrawals = firstNonClaimableWithdrawalIndex;
        DelayedWithdrawal[] memory claimableDelayedWithdrawals = new DelayedWithdrawal[](numberOfClaimableWithdrawals);
        
        if(numberOfClaimableWithdrawals != 0) {
            for (uint256 i = 0; i < numberOfClaimableWithdrawals; i++) {
                claimableDelayedWithdrawals[i] = _userWithdrawals[user].delayedWithdrawals[delayedWithdrawalsCompleted + i];
            }
        }
        return claimableDelayedWithdrawals;
    }

    /// @notice Getter function for fetching the delayedWithdrawal at the `index`th entry from the `_userWithdrawals[user].delayedWithdrawals` array
    function userDelayedWithdrawalByIndex(address user, uint256 index) external view returns (DelayedWithdrawal memory) {
        return _userWithdrawals[user].delayedWithdrawals[index];
    }

    /// @notice Getter function for fetching the length of the delayedWithdrawals array of a specific user
    function userWithdrawalsLength(address user) external view returns (uint256) {
        return _userWithdrawals[user].delayedWithdrawals.length;
    }

    /// @notice Convenience function for checking whether or not the delayedWithdrawal at the `index`th entry from the `_userWithdrawals[user].delayedWithdrawals` array is currently claimable
    function canClaimDelayedWithdrawal(address user, uint256 index) external view returns (bool) {
        return ((index >= _userWithdrawals[user].delayedWithdrawalsCompleted) && (block.number >= _userWithdrawals[user].delayedWithdrawals[index].blockCreated + withdrawalDelayBlocks));
    }

    /// @notice internal function used in both of the overloaded `claimDelayedWithdrawals` functions
    function _claimDelayedWithdrawals(address recipient, uint256 maxNumberOfDelayedWithdrawalsToClaim) internal {
        uint256 amountToSend = 0;
        uint256 delayedWithdrawalsCompletedBefore = _userWithdrawals[recipient].delayedWithdrawalsCompleted;
        uint256 _userWithdrawalsLength = _userWithdrawals[recipient].delayedWithdrawals.length;
        uint256 i = 0;
        while (i < maxNumberOfDelayedWithdrawalsToClaim && (delayedWithdrawalsCompletedBefore + i) < _userWithdrawalsLength) {
            // copy delayedWithdrawal from storage to memory
            DelayedWithdrawal memory delayedWithdrawal = _userWithdrawals[recipient].delayedWithdrawals[delayedWithdrawalsCompletedBefore + i];
            // check if delayedWithdrawal can be claimed. break the loop as soon as a delayedWithdrawal cannot be claimed
            if (block.number < delayedWithdrawal.blockCreated + withdrawalDelayBlocks) {
                break;
            }
            // otherwise, the delayedWithdrawal can be claimed, in which case we increase the amountToSend and increment i
            amountToSend += delayedWithdrawal.amount;
            // increment i to account for the delayedWithdrawal being claimed
            unchecked {
                ++i;
            }
        }
        // mark the i delayedWithdrawals as claimed
        _userWithdrawals[recipient].delayedWithdrawalsCompleted = delayedWithdrawalsCompletedBefore + i;
        // actually send the ETH
        if (amountToSend != 0) {
            AddressUpgradeable.sendValue(payable(recipient), amountToSend);
        }
        emit DelayedWithdrawalsClaimed(recipient, amountToSend, delayedWithdrawalsCompletedBefore + i);
    }

    /// @notice internal function for changing the value of `withdrawalDelayBlocks`. Also performs sanity check and emits an event.
    function _setWithdrawalDelayBlocks(uint256 newValue) internal {
        require(newValue <= MAX_WITHDRAWAL_DELAY_BLOCKS, "DelayedWithdrawalRouter._setWithdrawalDelayBlocks: newValue too large");
        emit WithdrawalDelayBlocksSet(withdrawalDelayBlocks, newValue);
        withdrawalDelayBlocks = newValue;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}