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
import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IEigenPodManager.sol";
import "../permissions/Pausable.sol";
import "./StrategyManagerStorage.sol";
import "../libraries/EIP1271SignatureUtils.sol";

/**
 * @title The primary entry- and exit-point for funds into and out of EigenLayer.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This contract is for managing deposits in different strategies. The main
 * functionalities are:
 * - adding and removing strategies that any delegator can deposit into
 * - enabling deposit of assets into specified strategy(s)
 * - enabling withdrawal of assets from specified strategy(s)
 * - recording deposit of ETH into settlement layer
 * - slashing of assets for permissioned strategies
 */
contract StrategyManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Pausable,
    StrategyManagerStorage
{
    using SafeERC20 for IERC20;

    uint256 internal constant GWEI_TO_WEI = 1e9;

    // index for flag that pauses deposits when set
    uint8 internal constant PAUSED_DEPOSITS = 0;
    // index for flag that pauses withdrawals when set
    uint8 internal constant PAUSED_WITHDRAWALS = 1;

    // chain id at the time of contract deployment
    uint256 internal immutable ORIGINAL_CHAIN_ID;

    /**
     * @notice Emitted when a new deposit occurs on behalf of `depositor`.
     * @param depositor Is the staker who is depositing funds into EigenLayer.
     * @param strategy Is the strategy that `depositor` has deposited into.
     * @param token Is the token that `depositor` deposited.
     * @param shares Is the number of new shares `depositor` has been granted in `strategy`.
     */
    event Deposit(
        address depositor, IERC20 token, IStrategy strategy, uint256 shares
    );

    /**
     * @notice Emitted when a new withdrawal occurs on behalf of `depositor`.
     * @param depositor Is the staker who is queuing a withdrawal from EigenLayer.
     * @param nonce Is the withdrawal's unique identifier (to the depositor).
     * @param strategy Is the strategy that `depositor` has queued to withdraw from.
     * @param shares Is the number of shares `depositor` has queued to withdraw.
     */
    event ShareWithdrawalQueued(
        address depositor, uint96 nonce, IStrategy strategy, uint256 shares
    );

    /**
     * @notice Emitted when a new withdrawal is queued by `depositor`.
     * @param depositor Is the staker who is withdrawing funds from EigenLayer.
     * @param nonce Is the withdrawal's unique identifier (to the depositor).
     * @param withdrawer Is the party specified by `staker` who will be able to complete the queued withdrawal and receive the withdrawn funds.
     * @param delegatedAddress Is the party who the `staker` was delegated to at the time of creating the queued withdrawal
     * @param withdrawalRoot Is a hash of the input data for the withdrawal.
     */
    event WithdrawalQueued(
        address depositor, uint96 nonce, address withdrawer, address delegatedAddress, bytes32 withdrawalRoot
    );

    /// @notice Emitted when a queued withdrawal is completed
    event WithdrawalCompleted(address indexed depositor, uint96 nonce, address indexed withdrawer, bytes32 withdrawalRoot);

    /// @notice Emitted when the `strategyWhitelister` is changed
    event StrategyWhitelisterChanged(address previousAddress, address newAddress);

    /// @notice Emitted when a strategy is added to the approved list of strategies for deposit
    event StrategyAddedToDepositWhitelist(IStrategy strategy);

    /// @notice Emitted when a strategy is removed from the approved list of strategies for deposit
    event StrategyRemovedFromDepositWhitelist(IStrategy strategy);

    /// @notice Emitted when the `withdrawalDelayBlocks` variable is modified from `previousValue` to `newValue`.
    event WithdrawalDelayBlocksSet(uint256 previousValue, uint256 newValue);

    modifier onlyNotFrozen(address staker) {
        require(
            !slasher.isFrozen(staker),
            "StrategyManager.onlyNotFrozen: staker has been frozen and may be subject to slashing"
        );
        _;
    }

    modifier onlyFrozen(address staker) {
        require(slasher.isFrozen(staker), "StrategyManager.onlyFrozen: staker has not been frozen");
        _;
    }

    modifier onlyEigenPodManager {
        require(address(eigenPodManager) == msg.sender, "StrategyManager.onlyEigenPodManager: not the eigenPodManager");
        _;
    }

    modifier onlyStrategyWhitelister {
        require(msg.sender == strategyWhitelister, "StrategyManager.onlyStrategyWhitelister: not the strategyWhitelister");
        _;
    }

    modifier onlyStrategiesWhitelistedForDeposit(IStrategy strategy) {
        require(strategyIsWhitelistedForDeposit[strategy], "StrategyManager.onlyStrategiesWhitelistedForDeposit: strategy not whitelisted");
        _;
    }

    modifier onlyDelegationManager {
        require(msg.sender == address(delegation), "StrategyManager.onlyDelegationManager: not the DelegationManager");
        _;
    }

    /**
     * @param _delegation The delegation contract of EigenLayer.
     * @param _slasher The primary slashing contract of EigenLayer.
     * @param _eigenPodManager The contract that keeps track of EigenPod stakes for restaking beacon chain ether.
     */
    constructor(IDelegationManager _delegation, IEigenPodManager _eigenPodManager, ISlasher _slasher)
        StrategyManagerStorage(_delegation, _eigenPodManager, _slasher)
    {
        _disableInitializers();
        ORIGINAL_CHAIN_ID = block.chainid;
    }

    // EXTERNAL FUNCTIONS

    /**
     * @notice Initializes the strategy manager contract. Sets the `pauserRegistry` (currently **not** modifiable after being set),
     * and transfers contract ownership to the specified `initialOwner`.
     * @param _pauserRegistry Used for access control of pausing.
     * @param initialOwner Ownership of this contract is transferred to this address.
     * @param initialStrategyWhitelister The initial value of `strategyWhitelister` to set.
     * @param  initialPausedStatus The initial value of `_paused` to set.
     * @param _withdrawalDelayBlocks The initial value of `withdrawalDelayBlocks` to set.
     */
    function initialize(address initialOwner, address initialStrategyWhitelister, IPauserRegistry _pauserRegistry, uint256 initialPausedStatus, uint256 _withdrawalDelayBlocks)
        external
        initializer
    {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator();
        _initializePauser(_pauserRegistry, initialPausedStatus);
        _transferOwnership(initialOwner);
        _setStrategyWhitelister(initialStrategyWhitelister);
        _setWithdrawalDelayBlocks(_withdrawalDelayBlocks);
    }

    /**
     * @notice Deposits `amount` of beaconchain ETH into this contract on behalf of `staker`
     * @param staker is the entity that is restaking in eigenlayer,
     * @param amount is the amount of beaconchain ETH being restaked,
     * @dev Only callable by EigenPodManager.
     */
    function depositBeaconChainETH(address staker, uint256 amount)
        external
        onlyEigenPodManager
        onlyWhenNotPaused(PAUSED_DEPOSITS)
        onlyNotFrozen(staker)
        nonReentrant
    {
        // add shares for the enshrined beacon chain ETH strategy
        _addShares(staker, beaconChainETHStrategy, amount);
    }

    /**
     * @notice Records a beacon chain balance update event on behalf of a staker. The staker's beaconChainETH shares are decremented by `amount`.
     * @param podOwner is the pod owner whose beaconchain ETH balance is being updated,
     * @param beaconChainETHStrategyIndex is the index of the beaconChainETHStrategy in case it must be removed,
     * @param sharesDelta is the change in podOwner's beaconChainETHStrategy shares
     * @dev Only callable by EigenPodManager.
     */
    function recordBeaconChainETHBalanceUpdate(address podOwner, uint256 beaconChainETHStrategyIndex, int256 sharesDelta)
        external
        onlyEigenPodManager
        nonReentrant
    {
        // remove or add shares for the enshrined beacon chain ETH strategy, and update delegated shares.
        _updateSharesToReflectBeaconChainETHBalance(podOwner, beaconChainETHStrategyIndex, sharesDelta);
    }

    /**
     * @notice Deposits `amount` of `token` into the specified `strategy`, with the resultant shares credited to `msg.sender`
     * @param strategy is the specified strategy where deposit is to be made,
     * @param token is the denomination in which the deposit is to be made,
     * @param amount is the amount of token to be deposited in the strategy by the depositor
     * @return shares The amount of new shares in the `strategy` created as part of the action.
     * @dev The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
     * @dev Cannot be called by an address that is 'frozen' (this function will revert if the `msg.sender` is frozen).
     * 
     * WARNING: Depositing tokens that allow reentrancy (eg. ERC-777) into a strategy is not recommended.  This can lead to attack vectors
     *          where the token balance and corresponding strategy shares are not in sync upon reentrancy.
     */
    function depositIntoStrategy(IStrategy strategy, IERC20 token, uint256 amount)
        external
        onlyWhenNotPaused(PAUSED_DEPOSITS)
        onlyNotFrozen(msg.sender)
        nonReentrant
        returns (uint256 shares)
    {
        shares = _depositIntoStrategy(msg.sender, strategy, token, amount);
    }

    /**
     * @notice Used for depositing an asset into the specified strategy with the resultant shares credited to `staker`,
     * who must sign off on the action.
     * Note that the assets are transferred out/from the `msg.sender`, not from the `staker`; this function is explicitly designed 
     * purely to help one address deposit 'for' another.
     * @param strategy is the specified strategy where deposit is to be made,
     * @param token is the denomination in which the deposit is to be made,
     * @param amount is the amount of token to be deposited in the strategy by the depositor
     * @param staker the staker that the deposited assets will be credited to
     * @param expiry the timestamp at which the signature expires
     * @param signature is a valid signature from the `staker`. either an ECDSA signature if the `staker` is an EOA, or data to forward
     * following EIP-1271 if the `staker` is a contract
     * @return shares The amount of new shares in the `strategy` created as part of the action.
     * @dev The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
     * @dev A signature is required for this function to eliminate the possibility of griefing attacks, specifically those
     * targeting stakers who may be attempting to undelegate.
     * @dev Cannot be called on behalf of a staker that is 'frozen' (this function will revert if the `staker` is frozen).
     * 
     *  WARNING: Depositing tokens that allow reentrancy (eg. ERC-777) into a strategy is not recommended.  This can lead to attack vectors
     *          where the token balance and corresponding strategy shares are not in sync upon reentrancy
     */
    function depositIntoStrategyWithSignature(
        IStrategy strategy,
        IERC20 token,
        uint256 amount,
        address staker,
        uint256 expiry,
        bytes memory signature
    )
        external
        onlyWhenNotPaused(PAUSED_DEPOSITS)
        onlyNotFrozen(staker)
        nonReentrant
        returns (uint256 shares)
    {
        require(
            expiry >= block.timestamp,
            "StrategyManager.depositIntoStrategyWithSignature: signature expired"
        );
        // calculate struct hash, then increment `staker`'s nonce
        uint256 nonce = nonces[staker];
        bytes32 structHash = keccak256(abi.encode(DEPOSIT_TYPEHASH, strategy, token, amount, nonce, expiry));
        unchecked {
            nonces[staker] = nonce + 1;
        }

        // calculate the digest hash
        bytes32 digestHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator(), structHash));

        /**
         * check validity of signature:
         * 1) if `staker` is an EOA, then `signature` must be a valid ECDSA signature from `staker`,
         * indicating their intention for this action
         * 2) if `staker` is a contract, then `signature` will be checked according to EIP-1271
         */
        EIP1271SignatureUtils.checkSignature_EIP1271(staker, digestHash, signature);

        // deposit the tokens (from the `msg.sender`) and credit the new shares to the `staker`
        shares = _depositIntoStrategy(staker, strategy, token, amount);
    }

    /**
     * @notice Called by a staker to undelegate entirely from EigenLayer. The staker must first withdraw all of their existing deposits
     * (through use of the `queueWithdrawal` function), or else otherwise have never deposited in EigenLayer prior to delegating.
     */
    function undelegate() external {
        _undelegate(msg.sender);
    }

    /**
     * @notice Called by the DelegationManager as part of the forced undelegation of the @param staker from their delegated operator.
     * This function queues a withdrawal of all of the `staker`'s shares in EigenLayer to the staker themself, and then undelegates the staker.
     * The staker will consequently be able to complete this withdrawal by calling the `completeQueuedWithdrawal` function.
     * @param staker The staker to force-undelegate.
     * @return The root of the newly queued withdrawal.
     */
    function forceTotalWithdrawal(address staker) external
        onlyDelegationManager
        onlyWhenNotPaused(PAUSED_WITHDRAWALS)
        onlyNotFrozen(staker)
        nonReentrant
        returns (bytes32)
    {
        uint256 strategiesLength = stakerStrategyList[staker].length;
        IStrategy[] memory strategies = new IStrategy[](strategiesLength);
        uint256[] memory shares = new uint256[](strategiesLength);
        uint256[] memory strategyIndexes = new uint256[](strategiesLength);

        for (uint256 i = 0; i < strategiesLength;) {
            uint256 index = (strategiesLength - 1) - i;
            strategies[i] = stakerStrategyList[staker][index];
            shares[i] = stakerStrategyShares[staker][strategies[i]];
            strategyIndexes[i] = index;
            unchecked {
                ++i;
            }
        }
        return _queueWithdrawal(staker, strategyIndexes, strategies, shares, staker, true);
    }

    /**
     * @notice Called by a staker to queue a withdrawal of the given amount of `shares` from each of the respective given `strategies`.
     * @dev Stakers will complete their withdrawal by calling the 'completeQueuedWithdrawal' function.
     * User shares are decreased in this function, but the total number of shares in each strategy remains the same.
     * The total number of shares is decremented in the 'completeQueuedWithdrawal' function instead, which is where
     * the funds are actually sent to the user through use of the strategies' 'withdrawal' function. This ensures
     * that the value per share reported by each strategy will remain consistent, and that the shares will continue
     * to accrue gains during the enforced withdrawal waiting period.
     * @param strategyIndexes is a list of the indices in `stakerStrategyList[msg.sender]` that correspond to the strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @param strategies The Strategies to withdraw from
     * @param shares The amount of shares to withdraw from each of the respective Strategies in the `strategies` array
     * @param withdrawer The address that can complete the withdrawal and will receive any withdrawn funds or shares upon completing the withdrawal
     * @param undelegateIfPossible If this param is marked as 'true' *and the withdrawal will result in `msg.sender` having no shares in any Strategy,*
     * then this function will also make an internal call to `undelegate(msg.sender)` to undelegate the `msg.sender`.
     * @return The 'withdrawalRoot' of the newly created Queued Withdrawal
     * @dev Strategies are removed from `stakerStrategyList` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `stakerStrategyList`. The simplest way to calculate the correct `strategyIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `stakerStrategyList` to lowest index
     * @dev Note that if the withdrawal includes shares in the enshrined 'beaconChainETH' strategy, then it must *only* include shares in this strategy, and
     * `withdrawer` must match the caller's address. The first condition is because slashing of queued withdrawals cannot be guaranteed 
     * for Beacon Chain ETH (since we cannot trigger a withdrawal from the beacon chain through a smart contract) and the second condition is because shares in
     * the enshrined 'beaconChainETH' strategy technically represent non-fungible positions (deposits to the Beacon Chain, each pointed at a specific EigenPod).
     */
    function queueWithdrawal(
        uint256[] calldata strategyIndexes,
        IStrategy[] calldata strategies,
        uint256[] calldata shares,
        address withdrawer,
        bool undelegateIfPossible
    )
        external
        onlyWhenNotPaused(PAUSED_WITHDRAWALS)
        onlyNotFrozen(msg.sender)
        nonReentrant
        returns (bytes32)
    {
        return _queueWithdrawal(msg.sender, strategyIndexes, strategies, shares, withdrawer, undelegateIfPossible);
    }

    /**
     * @notice Used to complete the specified `queuedWithdrawal`. The function caller must match `queuedWithdrawal.withdrawer`
     * @param queuedWithdrawal The QueuedWithdrawal to complete.
     * @param tokens Array in which the i-th entry specifies the `token` input to the 'withdraw' function of the i-th Strategy in the `strategies` array
     * of the `queuedWithdrawal`. This input can be provided with zero length if `receiveAsTokens` is set to 'false' (since in that case, this input will be unused)
     * @param middlewareTimesIndex is the index in the operator that the staker who triggered the withdrawal was delegated to's middleware times array
     * @param receiveAsTokens If true, the shares specified in the queued withdrawal will be withdrawn from the specified strategies themselves
     * and sent to the caller, through calls to `queuedWithdrawal.strategies[i].withdraw`. If false, then the shares in the specified strategies
     * will simply be transferred to the caller directly.
     * @dev middlewareTimesIndex should be calculated off chain before calling this function by finding the first index that satisfies `slasher.canWithdraw`
     */
    function completeQueuedWithdrawal(QueuedWithdrawal calldata queuedWithdrawal, IERC20[] calldata tokens, uint256 middlewareTimesIndex, bool receiveAsTokens)
        external
        onlyWhenNotPaused(PAUSED_WITHDRAWALS)
        // check that the address that the staker *was delegated to* – at the time that they queued the withdrawal – is not frozen
        nonReentrant
    {
        _completeQueuedWithdrawal(queuedWithdrawal, tokens, middlewareTimesIndex, receiveAsTokens);
    }

    /**
     * @notice Used to complete the specified `queuedWithdrawals`. The function caller must match `queuedWithdrawals[...].withdrawer`
     * @param queuedWithdrawals The QueuedWithdrawals to complete.
     * @param tokens Array of tokens for each QueuedWithdrawal. See `completeQueuedWithdrawal` for the usage of a single array.
     * @param middlewareTimesIndexes One index to reference per QueuedWithdrawal. See `completeQueuedWithdrawal` for the usage of a single index.
     * @param receiveAsTokens If true, the shares specified in the queued withdrawal will be withdrawn from the specified strategies themselves
     * and sent to the caller, through calls to `queuedWithdrawal.strategies[i].withdraw`. If false, then the shares in the specified strategies
     * will simply be transferred to the caller directly.
     * @dev Array-ified version of `completeQueuedWithdrawal`
     * @dev middlewareTimesIndex should be calculated off chain before calling this function by finding the first index that satisfies `slasher.canWithdraw`
     */
    function completeQueuedWithdrawals(
        QueuedWithdrawal[] calldata queuedWithdrawals,
        IERC20[][] calldata tokens,
        uint256[] calldata middlewareTimesIndexes,
        bool[] calldata receiveAsTokens
    ) external
        onlyWhenNotPaused(PAUSED_WITHDRAWALS)
        // check that the address that the staker *was delegated to* – at the time that they queued the withdrawal – is not frozen
        nonReentrant
    {
        for(uint256 i = 0; i < queuedWithdrawals.length; i++) {
            _completeQueuedWithdrawal(queuedWithdrawals[i], tokens[i], middlewareTimesIndexes[i], receiveAsTokens[i]);
        }
    }

    /**
     * @notice Slashes the shares of a 'frozen' operator (or a staker delegated to one)
     * @param slashedAddress is the frozen address that is having its shares slashed
     * @param recipient is the address that will receive the slashed funds, which could e.g. be a harmed party themself,
     * or a MerkleDistributor-type contract that further sub-divides the slashed funds.
     * @param strategies Strategies to slash
     * @param shareAmounts The amount of shares to slash in each of the provided `strategies`
     * @param tokens The tokens to use as input to the `withdraw` function of each of the provided `strategies`
     * @param strategyIndexes is a list of the indices in `stakerStrategyList[msg.sender]` that correspond to the strategies
     * for which `msg.sender` is withdrawing 100% of their shares
     * @param recipient The slashed funds are withdrawn as tokens to this address.
     * @dev strategies are removed from `stakerStrategyList` by swapping the last entry with the entry to be removed, then
     * popping off the last entry in `stakerStrategyList`. The simplest way to calculate the correct `strategyIndexes` to input
     * is to order the strategies *for which `msg.sender` is withdrawing 100% of their shares* from highest index in
     * `stakerStrategyList` to lowest index
     */
    function slashShares(
        address slashedAddress,
        address recipient,
        IStrategy[] calldata strategies,
        IERC20[] calldata tokens,
        uint256[] calldata strategyIndexes,
        uint256[] calldata shareAmounts
    )
        external
        onlyOwner
        onlyFrozen(slashedAddress)
        nonReentrant
    {
        require(tokens.length == strategies.length, "StrategyManager.slashShares: input length mismatch");
        uint256 strategyIndexIndex;
        uint256 strategiesLength = strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            // the internal function will return 'true' in the event the strategy was
            // removed from the slashedAddress's array of strategies -- i.e. stakerStrategyList[slashedAddress]
            if (_removeShares(slashedAddress, strategyIndexes[strategyIndexIndex], strategies[i], shareAmounts[i])) {
                unchecked {
                    ++strategyIndexIndex;
                }
            }

            if (strategies[i] == beaconChainETHStrategy) {
                 //withdraw the beaconChainETH to the recipient
                eigenPodManager.withdrawRestakedBeaconChainETH(slashedAddress, recipient, shareAmounts[i]);
            }
            else {
                // withdraw the shares and send funds to the recipient
                strategies[i].withdraw(recipient, tokens[i], shareAmounts[i]);
            }

            // increment the loop
            unchecked {
                ++i;
            }
        }

        // modify delegated shares accordingly, if applicable
        delegation.decreaseDelegatedShares(slashedAddress, strategies, shareAmounts);
    }
    
    /**
     * @notice Slashes an existing queued withdrawal that was created by a 'frozen' operator (or a staker delegated to one)
     * @param recipient The funds in the slashed withdrawal are withdrawn as tokens to this address.
     * @param queuedWithdrawal The previously queued withdrawal to be slashed
     * @param tokens Array in which the i-th entry specifies the `token` input to the 'withdraw' function of the i-th Strategy in the `strategies`
     * array of the `queuedWithdrawal`.
     * @param indicesToSkip Optional input parameter -- indices in the `strategies` array to skip (i.e. not call the 'withdraw' function on). This input exists
     * so that, e.g., if the slashed QueuedWithdrawal contains a malicious strategy in the `strategies` array which always reverts on calls to its 'withdraw' function,
     * then the malicious strategy can be skipped (with the shares in effect "burned"), while the non-malicious strategies are still called as normal.
     */
    function slashQueuedWithdrawal(address recipient, QueuedWithdrawal calldata queuedWithdrawal, IERC20[] calldata tokens, uint256[] calldata indicesToSkip)
        external
        onlyOwner
        onlyFrozen(queuedWithdrawal.delegatedAddress)
        nonReentrant
    {
        require(tokens.length == queuedWithdrawal.strategies.length, "StrategyManager.slashQueuedWithdrawal: input length mismatch");

        // find the withdrawalRoot
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        // verify that the queued withdrawal is pending
        require(
            withdrawalRootPending[withdrawalRoot],
            "StrategyManager.slashQueuedWithdrawal: withdrawal is not pending"
        );

        // reset the storage slot in mapping of queued withdrawals
        withdrawalRootPending[withdrawalRoot] = false;

        // keeps track of the index in the `indicesToSkip` array
        uint256 indicesToSkipIndex = 0;

        uint256 strategiesLength = queuedWithdrawal.strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            // check if the index i matches one of the indices specified in the `indicesToSkip` array
            if (indicesToSkipIndex < indicesToSkip.length && indicesToSkip[indicesToSkipIndex] == i) {
                unchecked {
                    ++indicesToSkipIndex;
                }
            } else {
                if (queuedWithdrawal.strategies[i] == beaconChainETHStrategy){
                     //withdraw the beaconChainETH to the recipient
                    eigenPodManager.withdrawRestakedBeaconChainETH(queuedWithdrawal.depositor, recipient, queuedWithdrawal.shares[i]);
                } else {
                    // tell the strategy to send the appropriate amount of funds to the recipient
                    queuedWithdrawal.strategies[i].withdraw(recipient, tokens[i], queuedWithdrawal.shares[i]);
                }
            }
            unchecked {
                    ++i;
                }
        }
    }

    /**
     * @notice Owner-only function for modifying the value of the `withdrawalDelayBlocks` variable.
     * @param _withdrawalDelayBlocks new value of `withdrawalDelayBlocks`.
    */
    function setWithdrawalDelayBlocks(uint256 _withdrawalDelayBlocks) external onlyOwner {
        _setWithdrawalDelayBlocks(_withdrawalDelayBlocks);
    }

    /**
     * @notice Owner-only function to change the `strategyWhitelister` address.
     * @param newStrategyWhitelister new address for the `strategyWhitelister`.
    */
    function setStrategyWhitelister(address newStrategyWhitelister) external onlyOwner {
        _setStrategyWhitelister(newStrategyWhitelister);
    }

    /**
     * @notice Owner-only function that adds the provided Strategies to the 'whitelist' of strategies that stakers can deposit into
     * @param strategiesToWhitelist Strategies that will be added to the `strategyIsWhitelistedForDeposit` mapping (if they aren't in it already)
    */
    function addStrategiesToDepositWhitelist(IStrategy[] calldata strategiesToWhitelist) external onlyStrategyWhitelister {
        uint256 strategiesToWhitelistLength = strategiesToWhitelist.length;
        for (uint256 i = 0; i < strategiesToWhitelistLength;) {
            // change storage and emit event only if strategy is not already in whitelist
            if (!strategyIsWhitelistedForDeposit[strategiesToWhitelist[i]]) {
                strategyIsWhitelistedForDeposit[strategiesToWhitelist[i]] = true;
                emit StrategyAddedToDepositWhitelist(strategiesToWhitelist[i]);
            }
            unchecked {
                ++i;
            }
        }
    } 

    /**
     * @notice Owner-only function that removes the provided Strategies from the 'whitelist' of strategies that stakers can deposit into
     * @param strategiesToRemoveFromWhitelist Strategies that will be removed to the `strategyIsWhitelistedForDeposit` mapping (if they are in it)
    */
    function removeStrategiesFromDepositWhitelist(IStrategy[] calldata strategiesToRemoveFromWhitelist) external onlyStrategyWhitelister {
        uint256 strategiesToRemoveFromWhitelistLength = strategiesToRemoveFromWhitelist.length;
        for (uint256 i = 0; i < strategiesToRemoveFromWhitelistLength;) {
            // change storage and emit event only if strategy is already in whitelist
            if (strategyIsWhitelistedForDeposit[strategiesToRemoveFromWhitelist[i]]) {
                strategyIsWhitelistedForDeposit[strategiesToRemoveFromWhitelist[i]] = false;
                emit StrategyRemovedFromDepositWhitelist(strategiesToRemoveFromWhitelist[i]);
            }
            unchecked {
                ++i;
            }
        }
    } 

    // INTERNAL FUNCTIONS

    /**
     * @notice This function adds `shares` for a given `strategy` to the `depositor` and runs through the necessary update logic.
     * @param depositor The address to add shares to
     * @param strategy The Strategy in which the `depositor` is receiving shares
     * @param shares The amount of shares to grant to the `depositor`
     * @dev In particular, this function calls `delegation.increaseDelegatedShares(depositor, strategy, shares)` to ensure that all
     * delegated shares are tracked, increases the stored share amount in `stakerStrategyShares[depositor][strategy]`, and adds `strategy`
     * to the `depositor`'s list of strategies, if it is not in the list already.
     */
    function _addShares(address depositor, IStrategy strategy, uint256 shares) internal {
        // sanity checks on inputs
        require(depositor != address(0), "StrategyManager._addShares: depositor cannot be zero address");
        require(shares != 0, "StrategyManager._addShares: shares should not be zero!");

        // if they dont have existing shares of this strategy, add it to their strats
        if (stakerStrategyShares[depositor][strategy] == 0) {
            require(
                stakerStrategyList[depositor].length < MAX_STAKER_STRATEGY_LIST_LENGTH,
                "StrategyManager._addShares: deposit would exceed MAX_STAKER_STRATEGY_LIST_LENGTH"
            );
            stakerStrategyList[depositor].push(strategy);
        }

        // add the returned shares to their existing shares for this strategy
        stakerStrategyShares[depositor][strategy] += shares;

        // if applicable, increase delegated shares accordingly
        delegation.increaseDelegatedShares(depositor, strategy, shares);
    }

    /**
     * @notice Internal function in which `amount` of ERC20 `token` is transferred from `msg.sender` to the Strategy-type contract
     * `strategy`, with the resulting shares credited to `depositor`.
     * @param depositor The address that will be credited with the new shares.
     * @param strategy The Strategy contract to deposit into.
     * @param token The ERC20 token to deposit.
     * @param amount The amount of `token` to deposit.
     * @return shares The amount of *new* shares in `strategy` that have been credited to the `depositor`.
     */
    function _depositIntoStrategy(address depositor, IStrategy strategy, IERC20 token, uint256 amount)
        internal
        onlyStrategiesWhitelistedForDeposit(strategy)
        returns (uint256 shares)
    {
        // transfer tokens from the sender to the strategy
        token.safeTransferFrom(msg.sender, address(strategy), amount);

        // deposit the assets into the specified strategy and get the equivalent amount of shares in that strategy
        shares = strategy.deposit(token, amount);

        // add the returned shares to the depositor's existing shares for this strategy
        _addShares(depositor, strategy, shares);

        emit Deposit(depositor, token, strategy, shares);
        return shares;
    }

    /**
     * @notice Decreases the shares that `depositor` holds in `strategy` by `shareAmount`.
     * @param depositor The address to decrement shares from
     * @param strategyIndex The `strategyIndex` input for the internal `_removeStrategyFromStakerStrategyList`. Used only in the case that
     * the removal of the depositor's shares results in them having zero remaining shares in the `strategy`
     * @param strategy The strategy for which the `depositor`'s shares are being decremented
     * @param shareAmount The amount of shares to decrement
     * @dev If the amount of shares represents all of the depositor`s shares in said strategy,
     * then the strategy is removed from stakerStrategyList[depositor] and 'true' is returned. Otherwise 'false' is returned.
     */
    function _removeShares(address depositor, uint256 strategyIndex, IStrategy strategy, uint256 shareAmount)
        internal
        returns (bool)
    {
        // sanity checks on inputs
        require(depositor != address(0), "StrategyManager._removeShares: depositor cannot be zero address");
        require(shareAmount != 0, "StrategyManager._removeShares: shareAmount should not be zero!");

        //check that the user has sufficient shares
        uint256 userShares = stakerStrategyShares[depositor][strategy];
        
        require(shareAmount <= userShares, "StrategyManager._removeShares: shareAmount too high");
        //unchecked arithmetic since we just checked this above
        unchecked {
            userShares = userShares - shareAmount;
        }

        // subtract the shares from the depositor's existing shares for this strategy
        stakerStrategyShares[depositor][strategy] = userShares;

        // if no existing shares, remove the strategy from the depositor's dynamic array of strategies
        if (userShares == 0) {
            _removeStrategyFromStakerStrategyList(depositor, strategyIndex, strategy);

            // return true in the event that the strategy was removed from stakerStrategyList[depositor]
            return true;
        }
        // return false in the event that the strategy was *not* removed from stakerStrategyList[depositor]
        return false;
    }

    /**
     * @notice Removes `strategy` from `depositor`'s dynamic array of strategies, i.e. from `stakerStrategyList[depositor]`
     * @param depositor The user whose array will have an entry removed
     * @param strategyIndex Preferably the index of `strategy` in `stakerStrategyList[depositor]`. If the input is incorrect, then a brute-force
     * fallback routine will be used to find the correct input
     * @param strategy The Strategy to remove from `stakerStrategyList[depositor]`
     * @dev the provided `strategyIndex` input is optimistically used to find the strategy quickly in the list. If the specified
     * index is incorrect, then we revert to a brute-force search.
     */
    function _removeStrategyFromStakerStrategyList(address depositor, uint256 strategyIndex, IStrategy strategy) internal {
        // if the strategy matches with the strategy index provided
        if (stakerStrategyList[depositor][strategyIndex] == strategy) {
            // replace the strategy with the last strategy in the list
            stakerStrategyList[depositor][strategyIndex] =
                stakerStrategyList[depositor][stakerStrategyList[depositor].length - 1];
        } else {
            //loop through all of the strategies, find the right one, then replace
            uint256 stratsLength = stakerStrategyList[depositor].length;
            uint256 j = 0;
            for (; j < stratsLength;) {
                if (stakerStrategyList[depositor][j] == strategy) {
                    //replace the strategy with the last strategy in the list
                    stakerStrategyList[depositor][j] = stakerStrategyList[depositor][stakerStrategyList[depositor].length - 1];
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            // if we didn't find the strategy, revert
            require(j != stratsLength, "StrategyManager._removeStrategyFromStakerStrategyList: strategy not found");
        }
        // pop off the last entry in the list of strategies
        stakerStrategyList[depositor].pop();
    }

    // @notice Internal function for queuing a withdrawal from `staker` to `withdrawer` of `shares` in `strategies`.
    function _queueWithdrawal(
        address staker,
        uint256[] memory strategyIndexes,
        IStrategy[] memory strategies,
        uint256[] memory shares,
        address withdrawer,
        bool undelegateIfPossible
    )
        internal
        returns (bytes32)
    {
        require(strategies.length == shares.length, "StrategyManager.queueWithdrawal: input length mismatch");
        require(withdrawer != address(0), "StrategyManager.queueWithdrawal: cannot withdraw to zero address");
    
        // modify delegated shares accordingly, if applicable
        delegation.decreaseDelegatedShares(staker, strategies, shares);

        uint96 nonce = uint96(numWithdrawalsQueued[staker]);
        
        // keeps track of the current index in the `strategyIndexes` array
        uint256 strategyIndexIndex;

        /**
         * Ensure that if the withdrawal includes beacon chain ETH, the specified 'withdrawer' is not different than the caller.
         * This is because shares in the enshrined `beaconChainETHStrategy` ultimately represent tokens in **non-fungible** EigenPods,
         * while other share in all other strategies represent purely fungible positions.
         */
        for (uint256 i = 0; i < strategies.length;) {
            if (strategies[i] == beaconChainETHStrategy) {
                require(withdrawer == staker,
                    "StrategyManager.queueWithdrawal: cannot queue a withdrawal of Beacon Chain ETH to a different address");
                require(strategies.length == 1,
                    "StrategyManager.queueWithdrawal: cannot queue a withdrawal including Beacon Chain ETH and other tokens");
                require(shares[i] % GWEI_TO_WEI == 0,
                    "StrategyManager.queueWithdrawal: cannot queue a withdrawal of Beacon Chain ETH for an non-whole amount of gwei");
                /**
                * This decrements the withdrawableRestakedExecutionLayerGwei which is incremented only when a podOwner proves a full withdrawal.
                * Remember that withdrawableRestakedExecutionLayerGwei tracks the currently withdrawable ETH from the EigenPod.  
                * By doing this, we ensure that the number of shares in EigenLayer matches the amount of withdrawable ETH in 
                * the pod plus any ETH still staked on the beacon chain via other validators pointed to the pod. As a result, a validator 
                * must complete a full withdrawal from the execution layer prior to queuing a withdrawal of 'beacon chain ETH shares' 
                * via EigenLayer, since otherwise withdrawableRestakedExecutionLayerGwei will be 0.
                */         
                eigenPodManager.decrementWithdrawableRestakedExecutionLayerGwei(msg.sender, shares[i]);   

            }
            
            // the internal function will return 'true' in the event the strategy was
            // removed from the depositor's array of strategies -- i.e. stakerStrategyList[depositor]
            if (_removeShares(staker, strategyIndexes[strategyIndexIndex], strategies[i], shares[i])) {
                unchecked {
                    ++strategyIndexIndex;
                }
            }

            emit ShareWithdrawalQueued(staker, nonce, strategies[i], shares[i]);

            //increment the loop
            unchecked {
                ++i;
            }
        }

        // fetch the address that the `staker` is delegated to
        address delegatedAddress = delegation.delegatedTo(staker);

        QueuedWithdrawal memory queuedWithdrawal;

        {
            WithdrawerAndNonce memory withdrawerAndNonce = WithdrawerAndNonce({
                withdrawer: withdrawer,
                nonce: nonce
            });
            // increment the numWithdrawalsQueued of the sender
            unchecked {
                numWithdrawalsQueued[staker] = nonce + 1;
            }

            // copy arguments into struct and pull delegation info
            queuedWithdrawal = QueuedWithdrawal({
                strategies: strategies,
                shares: shares,
                depositor: staker,
                withdrawerAndNonce: withdrawerAndNonce,
                withdrawalStartBlock: uint32(block.number),
                delegatedAddress: delegatedAddress
            });

        }

        // calculate the withdrawal root
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        // mark withdrawal as pending
        withdrawalRootPending[withdrawalRoot] = true;

        // If the `staker` has withdrawn all of their funds from EigenLayer in this transaction, then they can choose to also undelegate
        /**
         * Checking that `stakerStrategyList[staker].length == 0` is not strictly necessary here, but prevents reverting very late in logic,
         * in the case that 'undelegate' is set to true but the `staker` still has active deposits in EigenLayer.
         */
        if (undelegateIfPossible && stakerStrategyList[staker].length == 0) {
            _undelegate(staker);
        }

        emit WithdrawalQueued(staker, nonce, withdrawer, delegatedAddress, withdrawalRoot);

        return withdrawalRoot;

    }


    /**
     * @notice Internal function for completing the given `queuedWithdrawal`.
     * @param queuedWithdrawal The QueuedWithdrawal to complete
     * @param tokens The ERC20 tokens to provide as inputs to `Strategy.withdraw`. Only relevant if `receiveAsTokens = true`
     * @param middlewareTimesIndex Passed on as an input to the `slasher.canWithdraw` function, to ensure the withdrawal is completable.
     * @param receiveAsTokens If marked 'true', then calls will be passed on to the `Strategy.withdraw` function for each strategy.
     * If marked 'false', then the shares will simply be internally transferred to the `msg.sender`.
     */
    function _completeQueuedWithdrawal(QueuedWithdrawal calldata queuedWithdrawal, IERC20[] calldata tokens, uint256 middlewareTimesIndex, bool receiveAsTokens)
        onlyNotFrozen(queuedWithdrawal.delegatedAddress) internal
    {
        // find the withdrawalRoot
        bytes32 withdrawalRoot = calculateWithdrawalRoot(queuedWithdrawal);

        // verify that the queued withdrawal is pending
        require(
            withdrawalRootPending[withdrawalRoot],
            "StrategyManager.completeQueuedWithdrawal: withdrawal is not pending"
        );


        require(
            slasher.canWithdraw(queuedWithdrawal.delegatedAddress, queuedWithdrawal.withdrawalStartBlock, middlewareTimesIndex),
            "StrategyManager.completeQueuedWithdrawal: shares pending withdrawal are still slashable"
        );

        // enforce minimum delay lag (not applied to withdrawals of 'beaconChainETH', since the EigenPods enforce their own delay)
        require(queuedWithdrawal.withdrawalStartBlock + withdrawalDelayBlocks <= block.number 
                || queuedWithdrawal.strategies[0] == beaconChainETHStrategy,
            "StrategyManager.completeQueuedWithdrawal: withdrawalDelayBlocks period has not yet passed"
        );

        require(
            msg.sender == queuedWithdrawal.withdrawerAndNonce.withdrawer,
            "StrategyManager.completeQueuedWithdrawal: only specified withdrawer can complete a queued withdrawal"
        );

        // reset the storage slot in mapping of queued withdrawals
        withdrawalRootPending[withdrawalRoot] = false;

        // store length for gas savings
        uint256 strategiesLength = queuedWithdrawal.strategies.length;
        // if the withdrawer has flagged to receive the funds as tokens, withdraw from strategies

        if (receiveAsTokens) {
            require(tokens.length == queuedWithdrawal.strategies.length, "StrategyManager.completeQueuedWithdrawal: input length mismatch");
            // actually withdraw the funds
            for (uint256 i = 0; i < strategiesLength;) {
                if (queuedWithdrawal.strategies[i] == beaconChainETHStrategy) {

                    // if the strategy is the beaconchaineth strategy, then withdraw through the ETH from the EigenPod
                    eigenPodManager.withdrawRestakedBeaconChainETH(queuedWithdrawal.depositor, msg.sender, queuedWithdrawal.shares[i]);
                } else {
                    // tell the strategy to send the appropriate amount of funds to the depositor
                    queuedWithdrawal.strategies[i].withdraw(
                        msg.sender, tokens[i], queuedWithdrawal.shares[i]
                    );
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            // else increase their shares
            for (uint256 i = 0; i < strategiesLength;) {
                _addShares(msg.sender, queuedWithdrawal.strategies[i], queuedWithdrawal.shares[i]);
                if(queuedWithdrawal.strategies[i] == beaconChainETHStrategy) {
                    //increase the withdrawableRestakedExecutionLayerGwei so that shares and withdrawableRestakedExecutionLayerGwei in the pod are in sync.
                    eigenPodManager.incrementWithdrawableRestakedExecutionLayerGwei(queuedWithdrawal.depositor, queuedWithdrawal.shares[i]);
                }
                unchecked {
                    ++i;
                }
            }
        }
        emit WithdrawalCompleted(queuedWithdrawal.depositor, queuedWithdrawal.withdrawerAndNonce.nonce, msg.sender, withdrawalRoot);
    }

    /**
     * @notice If the `depositor` has no existing shares, then they can `undelegate` themselves.
     * This allows people a "hard reset" in their relationship with EigenLayer after withdrawing all of their stake.
     * @param depositor The address to undelegate. Passed on as an input to the `delegation.undelegate` function.
     */
    function _undelegate(address depositor) internal onlyNotFrozen(depositor) {
        require(stakerStrategyList[depositor].length == 0, "StrategyManager._undelegate: depositor has active deposits");
        delegation.undelegate(depositor);
    }

    /**
     * @notice internal function for changing the value of `withdrawalDelayBlocks`. Also performs sanity check and emits an event.
     * @param _withdrawalDelayBlocks The new value for `withdrawalDelayBlocks` to take.
     */
    function _setWithdrawalDelayBlocks(uint256 _withdrawalDelayBlocks) internal {
        require(_withdrawalDelayBlocks <= MAX_WITHDRAWAL_DELAY_BLOCKS, "StrategyManager.setWithdrawalDelay: _withdrawalDelayBlocks too high");
        emit WithdrawalDelayBlocksSet(withdrawalDelayBlocks, _withdrawalDelayBlocks);
        withdrawalDelayBlocks = _withdrawalDelayBlocks;
    }

    /**
     * @notice Internal function for modifying the `strategyWhitelister`. Used inside of the `setStrategyWhitelister` and `initialize` functions.
     * @param newStrategyWhitelister The new address for the `strategyWhitelister` to take.
     */
    function _setStrategyWhitelister(address newStrategyWhitelister) internal {
        emit StrategyWhitelisterChanged(strategyWhitelister, newStrategyWhitelister);
        strategyWhitelister = newStrategyWhitelister;
    }


    /**
     * @notice internal function for updating strategy manager's accounting of shares for the beacon chain ETH strategy
        * @param sharesDelta is the change in podOwner's beaconChainETHStrategy shares
     */
    function _updateSharesToReflectBeaconChainETHBalance(address podOwner, uint256 beaconChainETHStrategyIndex, int256 sharesDelta) internal {
        
        if (sharesDelta < 0) {
                IStrategy[] memory strategies = new IStrategy[](1);
                strategies[0] = beaconChainETHStrategy;
                uint256[] memory shareAmounts = new uint256[](1);
                shareAmounts[0] = uint256(-sharesDelta);

                //if change in shares is negative, remove the shares
                _removeShares(podOwner, beaconChainETHStrategyIndex, beaconChainETHStrategy, shareAmounts[0]);
                delegation.decreaseDelegatedShares(podOwner, strategies, shareAmounts);
        }   else {
                uint256 shareAmount = uint256(sharesDelta);
                //if change in shares is positive, add the shares
                _addShares(podOwner, beaconChainETHStrategy, shareAmount);
                delegation.increaseDelegatedShares(podOwner, beaconChainETHStrategy, shareAmount);
            }      
    }

    // VIEW FUNCTIONS
    /**
     * @notice Get all details on the depositor's deposits and corresponding shares
     * @param depositor The staker of interest, whose deposits this function will fetch
     * @return (depositor's strategies, shares in these strategies)
     */
    function getDeposits(address depositor) external view returns (IStrategy[] memory, uint256[] memory) {
        uint256 strategiesLength = stakerStrategyList[depositor].length;
        uint256[] memory shares = new uint256[](strategiesLength);

        for (uint256 i = 0; i < strategiesLength;) {
            shares[i] = stakerStrategyShares[depositor][stakerStrategyList[depositor][i]];
            unchecked {
                ++i;
            }
        }
        return (stakerStrategyList[depositor], shares);
    }

    /// @notice Simple getter function that returns `stakerStrategyList[staker].length`.
    function stakerStrategyListLength(address staker) external view returns (uint256) {
        return stakerStrategyList[staker].length;
    }

    /**
     * @notice Getter function for the current EIP-712 domain separator for this contract.
     * @dev The domain separator will change in the event of a fork that changes the ChainID.
     */
    function domainSeparator() public view returns (bytes32) {
        if (block.chainid == ORIGINAL_CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        }
        else {
            return _calculateDomainSeparator();
        }
    }

    /// @notice Returns the keccak256 hash of `queuedWithdrawal`.
    function calculateWithdrawalRoot(QueuedWithdrawal memory queuedWithdrawal) public pure returns (bytes32) {
        return (
            keccak256(
                abi.encode(
                    queuedWithdrawal.strategies,
                    queuedWithdrawal.shares,
                    queuedWithdrawal.depositor,
                    queuedWithdrawal.withdrawerAndNonce,
                    queuedWithdrawal.withdrawalStartBlock,
                    queuedWithdrawal.delegatedAddress
                )
            )
        );
    }

    // @notice Internal function for calculating the current domain separator of this contract
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("EigenLayer")), block.chainid, address(this)));
    }
}
