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
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";

import "../libraries/BeaconChainProofs.sol";
import "../libraries/BytesLib.sol";
import "../libraries/Endian.sol";

import "../interfaces/IETHPOSDeposit.sol";
import "../interfaces/IEigenPodManager.sol";
import "../interfaces/IEigenPod.sol";
import "../interfaces/IDelayedWithdrawalRouter.sol";
import "../interfaces/IPausable.sol";

import "./EigenPodPausingConstants.sol";

/**
 * @title The implementation contract used for restaking beacon chain ETH on EigenLayer 
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice The main functionalities are:
 * - creating new ETH validators with their withdrawal credentials pointed to this contract
 * - proving from beacon chain state roots that withdrawal credentials are pointed to this contract
 * - proving from beacon chain state roots the balances of ETH validators with their withdrawal credentials
 *   pointed to this contract
 * - updating aggregate balances in the EigenPodManager
 * - withdrawing eth when withdrawals are initiated
 * @dev Note that all beacon chain balances are stored as gwei within the beacon chain datastructures. We choose
 *   to account balances in terms of gwei in the EigenPod contract and convert to wei when making calls to other contracts
 */
contract EigenPod is IEigenPod, Initializable, ReentrancyGuardUpgradeable, EigenPodPausingConstants {
    using BytesLib for bytes;

    // CONSTANTS + IMMUTABLES
    uint256 internal constant GWEI_TO_WEI = 1e9;

    /// @notice Maximum "staleness" of a Beacon Chain state root against which `verifyBalanceUpdate` may be proven.
    uint256 internal constant VERIFY_BALANCE_UPDATE_WINDOW_SECONDS = 4.5 hours;

    /// @notice Maximum "staleness" of a Beacon Chain state root against which `verifyWithdrawalCredential` may be proven.
    uint256 internal constant VERIFY_WITHDRAWAL_CREDENTIAL_WINDOW = 4.5 hours;

    /// @notice This is the beacon chain deposit contract
    IETHPOSDeposit public immutable ethPOS;

    /// @notice Contract used for withdrawal routing, to provide an extra "safety net" mechanism
    IDelayedWithdrawalRouter public immutable delayedWithdrawalRouter;

    /// @notice The single EigenPodManager for EigenLayer
    IEigenPodManager public immutable eigenPodManager;

    ///@notice The maximum amount of ETH, in gwei, a validator can have staked in the beacon chain
    uint64 public immutable MAX_VALIDATOR_BALANCE_GWEI;

    /** 
    * @notice The value used in our effective restaked balance calculation, to set the 
    * amount by which to underestimate the validator's effective balance.
    */
    uint64 public immutable RESTAKED_BALANCE_OFFSET_GWEI;

    /// @notice The owner of this EigenPod
    address public podOwner;

    /**
     * @notice The latest block number at which the pod owner withdrew the balance of the pod.
     * @dev This variable is only updated when the `withdraw` function is called, which can only occur before `hasRestaked` is set to true for this pod.
     * Proofs for this pod are only valid against Beacon Chain state roots corresponding to blocks after the stored `mostRecentWithdrawalTimestamp`.
     */
    uint64 public mostRecentWithdrawalTimestamp;

    // STORAGE VARIABLES
    /// @notice the amount of execution layer ETH in this contract that is staked in EigenLayer (i.e. withdrawn from the Beacon Chain but not from EigenLayer), 
    uint64 public withdrawableRestakedExecutionLayerGwei;

    /// @notice an indicator of whether or not the podOwner has ever "fully restaked" by successfully calling `verifyCorrectWithdrawalCredentials`.
    bool public hasRestaked;

    /// @notice This is a mapping of validatorPubkeyHash to slot to whether or not they have proven a withdrawal for that slot
    mapping(bytes32 => mapping(uint64 => bool)) public provenWithdrawal;

    /// @notice This is a mapping that tracks a validator's information by their pubkey hash
    mapping(bytes32 => ValidatorInfo) internal _validatorPubkeyHashToInfo;

    /// @notice Emitted when an ETH validator stakes via this eigenPod
    event EigenPodStaked(bytes pubkey);

    /// @notice Emitted when an ETH validator's withdrawal credentials are successfully verified to be pointed to this eigenPod
    event ValidatorRestaked(uint40 validatorIndex);

    /// @notice Emitted when an ETH validator's  balance is proven to be updated.  Here newValidatorBalanceGwei
    //  is the validator's balance that is credited on EigenLayer.
    event ValidatorBalanceUpdated(uint40 validatorIndex, uint64 newValidatorBalanceGwei);
    
    /// @notice Emitted when an ETH validator is prove to have withdrawn from the beacon chain
    event FullWithdrawalRedeemed(uint40 validatorIndex, address indexed recipient, uint256 withdrawalAmountWei);

    /// @notice Emitted when a partial withdrawal claim is successfully redeemed
    event PartialWithdrawalRedeemed(uint40 validatorIndex, address indexed recipient, uint64 partialWithdrawalAmountGwei);

    /// @notice Emitted when restaked beacon chain ETH is withdrawn from the eigenPod.
    event RestakedBeaconChainETHWithdrawn(address indexed recipient, uint256 amount);

    /// @notice Emitted when podOwner enables restaking
    event restakingActivated(address indexed podOwner);
    

    modifier onlyEigenPodManager {
        require(msg.sender == address(eigenPodManager), "EigenPod.onlyEigenPodManager: not eigenPodManager");
        _;
    }

    modifier onlyEigenPodOwner {
        require(msg.sender == podOwner, "EigenPod.onlyEigenPodOwner: not podOwner");
        _;
    }

    modifier onlyNotFrozen {
        require(!eigenPodManager.slasher().isFrozen(podOwner), "EigenPod.onlyNotFrozen: pod owner is frozen");
        _;
    }

    modifier hasNeverRestaked {
        require(!hasRestaked, "EigenPod.hasNeverRestaked: restaking is enabled");
        _;
    }

    /// @notice checks that hasRestaked is set to true by calling activateRestaking()
    modifier hasEnabledRestaking {
        require(hasRestaked, "EigenPod.hasEnabledRestaking: restaking is not enabled");
        _;
    }

    /// @notice Checks that `timestamp` is strictly greater than the value stored in `mostRecentWithdrawalTimestamp`
    modifier proofIsForValidTimestamp(uint64 timestamp) {
        require(timestamp > mostRecentWithdrawalTimestamp,
            "EigenPod.proofIsForValidTimestamp: beacon chain proof must be for timestamp after mostRecentWithdrawalTimestamp");
        _;
    }

    /**
     * @notice Based on 'Pausable' code, but uses the storage of the EigenPodManager instead of this contract. This construction
     * is necessary for enabling pausing all EigenPods at the same time (due to EigenPods being Beacon Proxies).
     * Modifier throws if the `indexed`th bit of `_paused` in the EigenPodManager is 1, i.e. if the `index`th pause switch is flipped.
     */
    modifier onlyWhenNotPaused(uint8 index) {
        require(!IPausable(address(eigenPodManager)).paused(index), "EigenPod.onlyWhenNotPaused: index is paused in EigenPodManager");
        _;
    }

    constructor(
        IETHPOSDeposit _ethPOS,
        IDelayedWithdrawalRouter _delayedWithdrawalRouter,
        IEigenPodManager _eigenPodManager,
        uint64 _MAX_VALIDATOR_BALANCE_GWEI,
        uint64 _RESTAKED_BALANCE_OFFSET_GWEI
    ) {
        ethPOS = _ethPOS;
        delayedWithdrawalRouter = _delayedWithdrawalRouter;
        eigenPodManager = _eigenPodManager;
        MAX_VALIDATOR_BALANCE_GWEI = _MAX_VALIDATOR_BALANCE_GWEI;
        RESTAKED_BALANCE_OFFSET_GWEI = _RESTAKED_BALANCE_OFFSET_GWEI;
        _disableInitializers();
    }

    /// @notice Used to initialize the pointers to addresses crucial to the pod's functionality. Called on construction by the EigenPodManager.
    function initialize(address _podOwner) external initializer {
        require(_podOwner != address(0), "EigenPod.initialize: podOwner cannot be zero address");
        podOwner = _podOwner;
    }

    /// @notice Called by EigenPodManager when the owner wants to create another ETH validator.
    function stake(bytes calldata pubkey, bytes calldata signature, bytes32 depositDataRoot) external payable onlyEigenPodManager {
        // stake on ethpos
        require(msg.value == 32 ether, "EigenPod.stake: must initially stake for any validator with 32 ether");
        ethPOS.deposit{value : 32 ether}(pubkey, _podWithdrawalCredentials(), signature, depositDataRoot);
        emit EigenPodStaked(pubkey);
    }

    /**
     * @notice This function verifies that the withdrawal credentials of validator(s) owned by the podOwner are pointed to
     * this contract. It also verifies the effective balance  of the validator.  It verifies the provided proof of the ETH validator against the beacon chain state
     * root, marks the validator as 'active' in EigenLayer, and credits the restaked ETH in Eigenlayer.
     * @param oracleTimestamp is the Beacon Chain timestamp whose state root the `proof` will be proven against.
     * @param validatorIndices is the list of indices of the validators being proven, refer to consensus specs 
     * @param proofs is an array of proofs, where each proof proves each ETH validator's balance and withdrawal credentials against a beacon chain state root
     * @param validatorFields are the fields of the "Validator Container", refer to consensus specs 
     * for details: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator
     */
    function verifyWithdrawalCredentials(
        uint64 oracleTimestamp,
        uint40[] calldata validatorIndices,
        BeaconChainProofs.WithdrawalCredentialProofs[] calldata proofs,
        bytes32[][] calldata validatorFields
    ) external 
        onlyEigenPodOwner
        onlyWhenNotPaused(PAUSED_EIGENPODS_VERIFY_CREDENTIALS)
        // check that the provided `oracleTimestamp` is after the `mostRecentWithdrawalTimestamp`
        proofIsForValidTimestamp(oracleTimestamp)
        //ensure that caller has restaking enabled by calling "activateRestaking()"
        hasEnabledRestaking
    {
        // ensure that the timestamp being proven against is not "too stale", i.e. that the validator's effective balance *recently* changed.
        require(oracleTimestamp + VERIFY_WITHDRAWAL_CREDENTIAL_WINDOW >= block.timestamp,
            "EigenPod.verifyWithdrawalCredentials: specified timestamp is too far in past");



        require((validatorIndices.length == proofs.length) && (proofs.length == validatorFields.length), "EigenPod.verifyWithdrawalCredentials: validatorIndices and proofs must be same length");
        
        uint256 totalAmountToBeRestakedWei;
        for (uint256 i = 0; i < validatorIndices.length; i++) {
            totalAmountToBeRestakedWei += _verifyWithdrawalCredentials(oracleTimestamp, validatorIndices[i], proofs[i], validatorFields[i]);
        }

         // virtually deposit for new ETH validator(s)
        eigenPodManager.restakeBeaconChainETH(podOwner, totalAmountToBeRestakedWei);
    }


    /**
     * @notice This function records an update (either increase or decrease) in the pod's balance in the StrategyManager.  
               It also verifies a merkle proof of the validator's current beacon chain balance.  
     * @param oracleTimestamp The oracleTimestamp whose state root the `proof` will be proven against.
     *        Must be within `VERIFY_BALANCE_UPDATE_WINDOW_SECONDS` of the current block.
     * @param validatorIndex is the index of the validator being proven, refer to consensus specs 
     * @param proofs is the proof of the validator's balance and validatorFields in the balance tree and the balanceRoot to prove for
     * @param beaconChainETHStrategyIndex is the index of the beaconChainETHStrategy for the pod owner for the callback to 
     *                                    the StrategyManager in case it must be removed from the list of the podOwner's strategies
     * @param validatorFields are the fields of the "Validator Container", refer to consensus specs
     * @dev For more details on the Beacon Chain spec, see: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator
     */
    function verifyBalanceUpdate(
        uint40 validatorIndex,
        BeaconChainProofs.BalanceUpdateProofs calldata proofs,
        bytes32[] calldata validatorFields,
        uint256 beaconChainETHStrategyIndex,
        uint64 oracleTimestamp
    ) external onlyWhenNotPaused(PAUSED_EIGENPODS_VERIFY_BALANCE_UPDATE) {
       // ensure that the timestamp being proven against is not "too stale", i.e. that the validator's balance *recently* changed.
        require(oracleTimestamp + VERIFY_BALANCE_UPDATE_WINDOW_SECONDS >= block.timestamp,
            "EigenPod.verifyBalanceUpdate: specified timestamp is too far in past");

        bytes32 validatorPubkeyHash = validatorFields[BeaconChainProofs.VALIDATOR_PUBKEY_INDEX];

        ValidatorInfo memory validatorInfo = _validatorPubkeyHashToInfo[validatorPubkeyHash];

        require(validatorInfo.status == VALIDATOR_STATUS.ACTIVE, "EigenPod.verifyBalanceUpdate: Validator not active");
        //checking that the balance update being made is strictly after the previous balance update
        require(validatorInfo.mostRecentBalanceUpdateSlot < Endian.fromLittleEndianUint64(proofs.slotRoot),
            "EigenPod.verifyBalanceUpdate: Validator's balance has already been updated for this slot");
        
        // deserialize the balance field from the balanceRoot
        uint64 validatorNewBalanceGwei = BeaconChainProofs.getBalanceFromBalanceRoot(validatorIndex, proofs.balanceRoot);        

        {
            // verify ETH validator proof
            bytes32 latestBlockHeaderRoot = eigenPodManager.getBeaconChainStateRoot(oracleTimestamp);

            // verify that the provided state root is verified against the oracle-provided latest block header
            BeaconChainProofs.verifyStateRootAgainstLatestBlockHeaderRoot(proofs.beaconStateRoot, latestBlockHeaderRoot, proofs.latestBlockHeaderProof);
        }
        // verify validator fields
        BeaconChainProofs.verifyValidatorFields(
            proofs.beaconStateRoot,
            validatorFields,            
            proofs.validatorFieldsProof,
            validatorIndex
        );
 
        // verify ETH validator's current balance, which is stored in the `balances` container of the beacon state
        BeaconChainProofs.verifyValidatorBalance(
            proofs.beaconStateRoot,
            proofs.balanceRoot,
            proofs.validatorBalanceProof,
            validatorIndex
        );
        //verify provided slot is valid against beaconStateRoot
        BeaconChainProofs.verifySlotRoot(
            proofs.beaconStateRoot,
            proofs.slotRoot,
            proofs.slotProof
        );

        uint64 currentRestakedBalanceGwei = validatorInfo.restakedBalanceGwei;

        // calculate the effective (pessimistic) restaked balance
        uint64 newRestakedBalanceGwei = _calculateRestakedBalanceGwei(validatorNewBalanceGwei);

        //update the balance
        validatorInfo.restakedBalanceGwei = newRestakedBalanceGwei;

        //update the most recent balance update slot
        validatorInfo.mostRecentBalanceUpdateSlot = Endian.fromLittleEndianUint64(proofs.slotRoot);

        //record validatorInfo update in storage
        _validatorPubkeyHashToInfo[validatorPubkeyHash] = validatorInfo;
        

        if (newRestakedBalanceGwei != currentRestakedBalanceGwei){
            emit ValidatorBalanceUpdated(validatorIndex, newRestakedBalanceGwei);

            int256 sharesDelta = _calculateSharesDelta(newRestakedBalanceGwei * GWEI_TO_WEI, currentRestakedBalanceGwei* GWEI_TO_WEI);
            // update shares in strategy manager
            eigenPodManager.recordBeaconChainETHBalanceUpdate(podOwner, beaconChainETHStrategyIndex, sharesDelta);
        }
    }

    /**
     * @notice This function records full and partial withdrawals on behalf of one of the Ethereum validators for this EigenPod
     * @param withdrawalProofs is the information needed to check the veracity of the block numbers and withdrawals being proven
     * @param validatorFieldsProofs is the proof of the validator's fields' in the validator tree
     * @param withdrawalFields are the fields of the withdrawals being proven
     * @param validatorFields are the fields of the validators being proven
     * @param beaconChainETHStrategyIndex is the index of the beaconChainETHStrategy for the pod owner for the callback to 
     *        the EigenPodManager to the StrategyManager in case it must be removed from the podOwner's list of strategies
     * @param oracleTimestamp is the timestamp of the oracle slot that the withdrawal is being proven against
     */
    function verifyAndProcessWithdrawals(
        BeaconChainProofs.WithdrawalProofs[] calldata withdrawalProofs, 
        bytes[] calldata validatorFieldsProofs,
        bytes32[][] calldata validatorFields,
        bytes32[][] calldata withdrawalFields,
        uint256 beaconChainETHStrategyIndex,
        uint64 oracleTimestamp
    )
        external
        onlyWhenNotPaused(PAUSED_EIGENPODS_VERIFY_WITHDRAWAL)
        onlyNotFrozen
    {
        require(
            (validatorFields.length == validatorFieldsProofs.length) && 
            (validatorFieldsProofs.length == withdrawalProofs.length) && 
            (withdrawalProofs.length == withdrawalFields.length), "EigenPod.verifyAndProcessWithdrawals: inputs must be same length"
        );

        for (uint256 i = 0; i < withdrawalFields.length; i++) {
            _verifyAndProcessWithdrawal(withdrawalProofs[i], validatorFieldsProofs[i], validatorFields[i], withdrawalFields[i], beaconChainETHStrategyIndex, oracleTimestamp);
        }
    }

    /**
     * @notice This function is called to decrement withdrawableRestakedExecutionLayerGwei when a validator queues a withdrawal.
     * @param amountWei is the amount of ETH in wei to decrement withdrawableRestakedExecutionLayerGwei by
     */
    function decrementWithdrawableRestakedExecutionLayerGwei(uint256 amountWei) external onlyEigenPodManager {
        uint64 amountGwei = uint64(amountWei / GWEI_TO_WEI);
        require(withdrawableRestakedExecutionLayerGwei >= amountGwei , "EigenPod.decrementWithdrawableRestakedExecutionLayerGwei: amount to decrement is greater than current withdrawableRestakedRxecutionLayerGwei balance");
        withdrawableRestakedExecutionLayerGwei -= amountGwei;
    }
    /**
     * @notice This function is called to increment withdrawableRestakedExecutionLayerGwei when a validator's withdrawal is completed.
     * @param amountWei is the amount of ETH in wei to increment withdrawableRestakedExecutionLayerGwei by
     */
    function incrementWithdrawableRestakedExecutionLayerGwei(uint256 amountWei) external onlyEigenPodManager {
        uint64 amountGwei = uint64(amountWei / GWEI_TO_WEI);
        withdrawableRestakedExecutionLayerGwei += amountGwei;
    }

    /**
     * @notice internal function that proves an individual validator's withdrawal credentials
     * @param oracleTimestamp is the timestamp whose state root the `proof` will be proven against.
     * @param validatorIndex is the index of the validator being proven
     * @param proofs is the bytes that prove the ETH validator's  withdrawal credentials against a beacon chain state root
     * @param validatorFields are the fields of the "Validator Container", refer to consensus specs
     */
    function _verifyWithdrawalCredentials(
        uint64 oracleTimestamp,
        uint40 validatorIndex,
        BeaconChainProofs.WithdrawalCredentialProofs calldata proofs,
        bytes32[] calldata validatorFields
    )
        internal
        returns (uint256)
    {
        bytes32 validatorPubkeyHash = validatorFields[BeaconChainProofs.VALIDATOR_PUBKEY_INDEX];

        ValidatorInfo memory validatorInfo = _validatorPubkeyHashToInfo[validatorPubkeyHash];

        require(validatorInfo.status == VALIDATOR_STATUS.INACTIVE,
            "EigenPod.verifyCorrectWithdrawalCredentials: Validator must be inactive to prove withdrawal credentials");

        require(validatorFields[BeaconChainProofs.VALIDATOR_WITHDRAWAL_CREDENTIALS_INDEX] == bytes32(_podWithdrawalCredentials()),
            "EigenPod.verifyCorrectWithdrawalCredentials: Proof is not for this EigenPod");
        /**
        * Deserialize the balance field from the Validator struct.  Note that this is the "effective" balance of the validator
        * rather than the current balance.  Effective balance is generated via a hystersis function such that an effective 
        * balance, always a multiple of 1 ETH, will only lower to the next multiple of 1 ETH if the current balance is less
        * than 0.25 ETH below their current effective balance.  For example, if the effective balance is 31ETH, it only falls to 
        * 30ETH when the true balance falls below 30.75ETH.  Thus in the worst case, the effective balance is overestimating the
        * actual validator balance by 0.25 ETH.  In EigenLayer, we calculate our own "restaked balance" which is a further pessimistic
        * view of the validator's effective balance.
        */
        uint64 validatorEffectiveBalanceGwei = Endian.fromLittleEndianUint64(validatorFields[BeaconChainProofs.VALIDATOR_BALANCE_INDEX]);

        // verify ETH validator proof
        bytes32 latestBlockHeaderRoot = eigenPodManager.getBeaconChainStateRoot(oracleTimestamp);

        // verify that the provided state root is verified against the oracle-provided latest block header
       BeaconChainProofs.verifyStateRootAgainstLatestBlockHeaderRoot(proofs.beaconStateRoot, latestBlockHeaderRoot, proofs.latestBlockHeaderProof);


        BeaconChainProofs.verifyValidatorFields(
            proofs.beaconStateRoot,
            validatorFields,
            proofs.validatorFieldsProof,
            validatorIndex
        );

        // set the status to active
       validatorInfo.status = VALIDATOR_STATUS.ACTIVE;

        emit ValidatorRestaked(validatorIndex);

        //record validator's new restaked balance
        validatorInfo.restakedBalanceGwei = _calculateRestakedBalanceGwei(validatorEffectiveBalanceGwei);

        //record validatorInfo update in storage
        _validatorPubkeyHashToInfo[validatorPubkeyHash] = validatorInfo;

        return validatorInfo.restakedBalanceGwei * GWEI_TO_WEI;
    }

    function _verifyAndProcessWithdrawal(
        BeaconChainProofs.WithdrawalProofs calldata withdrawalProofs, 
        bytes calldata validatorFieldsProof,
        bytes32[] calldata validatorFields,
        bytes32[] calldata withdrawalFields,
        uint256 beaconChainETHStrategyIndex,
        uint64 oracleTimestamp
    )
        internal
        /** 
         * Check that the provided block number being proven against is after the `mostRecentWithdrawalTimestamp`.
         * Without this check, there is an edge case where a user proves a past withdrawal for a validator whose funds they already withdrew,
         * as a way to "withdraw the same funds twice" without providing adequate proof.
         * Note that this check is not made using the oracleTimestamp as in the `verifyWithdrawalCredentials` proof; instead this proof
         * proof is made for the timestamp of the withdrawal, which may be within SLOTS_PER_HISTORICAL_ROOT slots of the oracleTimestamp. 
         * This difference in modifier usage is OK, since it is still not possible to `verifyAndProcessWithdrawal` against a slot that occurred
         * *prior* to the proof provided in the `verifyWithdrawalCredentials` function.
         */
        proofIsForValidTimestamp(Endian.fromLittleEndianUint64(withdrawalProofs.timestampRoot))
    {
        uint40 validatorIndex = uint40(Endian.fromLittleEndianUint64(withdrawalFields[BeaconChainProofs.WITHDRAWAL_VALIDATOR_INDEX_INDEX]));
        
        bytes32 validatorPubkeyHash = validatorFields[BeaconChainProofs.VALIDATOR_PUBKEY_INDEX];

        /**
         * If the validator status is inactive, then withdrawal credentials were never verified for the validator,
         * and thus we cannot know that the validator is related to this EigenPod at all!
         */
        require(_validatorPubkeyHashToInfo[validatorPubkeyHash].status != VALIDATOR_STATUS.INACTIVE,
            "EigenPod._verifyAndProcessWithdrawal: Validator never proven to have withdrawal credentials pointed to this contract");
        require(!provenWithdrawal[validatorPubkeyHash][Endian.fromLittleEndianUint64(withdrawalProofs.slotRoot)],
            "EigenPod._verifyAndProcessWithdrawal: withdrawal has already been proven for this slot");

    
        // verify that the provided state root is verified against the oracle-provided latest block header
        BeaconChainProofs.verifyStateRootAgainstLatestBlockHeaderRoot(withdrawalProofs.beaconStateRoot, eigenPodManager.getBeaconChainStateRoot(oracleTimestamp), withdrawalProofs.latestBlockHeaderProof);

        // Verifying the withdrawal as well as the slot
        BeaconChainProofs.verifyWithdrawalProofs(withdrawalProofs.beaconStateRoot, withdrawalFields, withdrawalProofs);
        // Verifying the validator fields, specifically the withdrawable epoch
        BeaconChainProofs.verifyValidatorFields(withdrawalProofs.beaconStateRoot, validatorFields, validatorFieldsProof, validatorIndex);

        {
            uint64 withdrawalAmountGwei = Endian.fromLittleEndianUint64(withdrawalFields[BeaconChainProofs.WITHDRAWAL_VALIDATOR_AMOUNT_INDEX]);

            uint64 slot = Endian.fromLittleEndianUint64(withdrawalProofs.slotRoot);

            /**
            * if the validator's withdrawable epoch is less than or equal to the slot's epoch, then the validator has fully withdrawn because
            * a full withdrawal is only processable after the withdrawable epoch has passed.
            */
            // reference: uint64 withdrawableEpoch = Endian.fromLittleEndianUint64(validatorFields[BeaconChainProofs.VALIDATOR_WITHDRAWABLE_EPOCH_INDEX]);
            if (Endian.fromLittleEndianUint64(validatorFields[BeaconChainProofs.VALIDATOR_WITHDRAWABLE_EPOCH_INDEX]) <= slot/BeaconChainProofs.SLOTS_PER_EPOCH) {
                _processFullWithdrawal(withdrawalAmountGwei, validatorIndex, validatorPubkeyHash, beaconChainETHStrategyIndex, podOwner, _validatorPubkeyHashToInfo[validatorPubkeyHash].status, slot);
            } else {
                _processPartialWithdrawal(slot, withdrawalAmountGwei, validatorIndex, validatorPubkeyHash, podOwner);
            }
        }
    }

    function _processFullWithdrawal(
        uint64 withdrawalAmountGwei,
        uint40 validatorIndex,
        bytes32 validatorPubkeyHash,
        uint256 beaconChainETHStrategyIndex,
        address recipient,
        VALIDATOR_STATUS status,
        uint64 withdrawalHappenedSlot
    ) internal {
        uint256 amountToSend;
        uint256 withdrawalAmountWei;

        uint256 currentValidatorRestakedBalanceWei = _validatorPubkeyHashToInfo[validatorPubkeyHash].restakedBalanceGwei * GWEI_TO_WEI;
        
        /**
        * If the validator is already withdrawn and additional deposits are made, they will be automatically withdrawn
        * in the beacon chain as a full withdrawal.  Thus such a validator can prove another full withdrawal, and 
        * withdraw that ETH via the queuedWithdrawal flow in the strategy manager. 
        */
        if (status == VALIDATOR_STATUS.ACTIVE) {
            // if the withdrawal amount is greater than the MAX_VALIDATOR_BALANCE_GWEI (i.e. the max amount restaked on EigenLayer, per ETH validator)
            uint64 maxRestakedBalanceGwei = _calculateRestakedBalanceGwei(MAX_VALIDATOR_BALANCE_GWEI);
            if (withdrawalAmountGwei > maxRestakedBalanceGwei) {
                // then the excess is immediately withdrawable
                amountToSend = uint256(withdrawalAmountGwei - maxRestakedBalanceGwei) * uint256(GWEI_TO_WEI);
                // and the extra execution layer ETH in the contract is MAX_VALIDATOR_BALANCE_GWEI, which must be withdrawn through EigenLayer's normal withdrawal process
                withdrawableRestakedExecutionLayerGwei += maxRestakedBalanceGwei;
                withdrawalAmountWei = maxRestakedBalanceGwei * GWEI_TO_WEI;
                
            } else {

                // otherwise, just use the full withdrawal amount to continue to "back" the podOwner's remaining shares in EigenLayer (i.e. none is instantly withdrawable)
                withdrawalAmountGwei = _calculateRestakedBalanceGwei(withdrawalAmountGwei);
                withdrawableRestakedExecutionLayerGwei += withdrawalAmountGwei;
                withdrawalAmountWei = withdrawalAmountGwei * GWEI_TO_WEI;

            }
            // if the amount being withdrawn is not equal to the current accounted for validator balance, an update must be made
            if (currentValidatorRestakedBalanceWei != withdrawalAmountWei) {
                int256 sharesDelta = _calculateSharesDelta(withdrawalAmountWei, currentValidatorRestakedBalanceWei);
                //update podOwner's shares in the strategy manager
                eigenPodManager.recordBeaconChainETHBalanceUpdate(podOwner, beaconChainETHStrategyIndex, sharesDelta);
            }

        }  else {
            revert("EigenPod.verifyBeaconChainFullWithdrawal: VALIDATOR_STATUS is invalid VALIDATOR_STATUS");
        }
        // now that the validator has been proven to be withdrawn, we can set their restaked balance to 0
        _validatorPubkeyHashToInfo[validatorPubkeyHash].restakedBalanceGwei = 0;

        provenWithdrawal[validatorPubkeyHash][withdrawalHappenedSlot] = true;

        emit FullWithdrawalRedeemed(validatorIndex, recipient, withdrawalAmountGwei * GWEI_TO_WEI);

        // send ETH to the `recipient`, if applicable
        if (amountToSend != 0) {
            _sendETH(recipient, amountToSend);
        }
    }

    function _processPartialWithdrawal(uint64 withdrawalHappenedSlot, uint64 partialWithdrawalAmountGwei, uint40 validatorIndex, bytes32 validatorPubkeyHash, address recipient) internal {

        provenWithdrawal[validatorPubkeyHash][withdrawalHappenedSlot] = true;
        emit PartialWithdrawalRedeemed(validatorIndex, recipient, partialWithdrawalAmountGwei);

        // send the ETH to the `recipient`
        _sendETH(recipient, uint256(partialWithdrawalAmountGwei) * uint256(GWEI_TO_WEI));
    }

    /**
     * @notice Transfers `amountWei` in ether from this contract to the specified `recipient` address
     * @notice Called by EigenPodManager to withdrawBeaconChainETH that has been added to the EigenPod's balance due to a withdrawal from the beacon chain.
     * @dev Called during withdrawal or slashing.
     */
    function withdrawRestakedBeaconChainETH(
        address recipient,
        uint256 amountWei
    )
        external
        onlyEigenPodManager
    {
        emit RestakedBeaconChainETHWithdrawn(recipient, amountWei);
        // transfer ETH from pod to `recipient`
        _sendETH(recipient, amountWei);
    }


    /**
     * @notice Called by the pod owner to activate restaking by withdrawing 
     * all existing ETH from the pod and preventing further withdrawals via 
     * "withdrawBeforeRestaking()"
    */ 
    function activateRestaking() external onlyWhenNotPaused(PAUSED_EIGENPODS_VERIFY_CREDENTIALS) onlyEigenPodOwner hasNeverRestaked {
        hasRestaked = true;
        _processWithdrawalBeforeRestaking(podOwner);

        emit restakingActivated(podOwner);
    }

    /// @notice Called by the pod owner to withdraw the balance of the pod when `hasRestaked` is set to false
    function withdrawBeforeRestaking() external onlyEigenPodOwner hasNeverRestaked {
        _processWithdrawalBeforeRestaking(podOwner);
    }

    function validatorPubkeyHashToInfo(bytes32 validatorPubkeyHash) external view returns(ValidatorInfo memory) {
        return _validatorPubkeyHashToInfo[validatorPubkeyHash];
    }

    function validatorStatus(bytes32 pubkeyHash) external view returns (VALIDATOR_STATUS) {
        return _validatorPubkeyHashToInfo[pubkeyHash].status;
    }

    // INTERNAL FUNCTIONS
    function _podWithdrawalCredentials() internal view returns(bytes memory) {
        return abi.encodePacked(bytes1(uint8(1)), bytes11(0), address(this));
    }

    function _processWithdrawalBeforeRestaking(address _podOwner) internal {
        mostRecentWithdrawalTimestamp = uint32(block.timestamp);
        _sendETH(_podOwner, address(this).balance);
    }

    function _sendETH(address recipient, uint256 amountWei) internal {
        delayedWithdrawalRouter.createDelayedWithdrawal{value: amountWei}(podOwner, recipient);
    }

    function _calculateRestakedBalanceGwei(uint64 amountGwei) internal view returns (uint64){
        if (amountGwei <= RESTAKED_BALANCE_OFFSET_GWEI) {
            return 0;
        }
        /**
        * calculates the "floor" of amountGwei - RESTAKED_BALANCE_OFFSET_GWEI.  By using integer division 
        * (dividing by GWEI_TO_WEI = 1e9) and then multiplying by 1e9, we effectively "round down" amountGwei to 
        * the nearest ETH, effectively calculating the floor of amountGwei.
        */
        uint64 effectiveBalanceGwei = uint64((amountGwei - RESTAKED_BALANCE_OFFSET_GWEI) / GWEI_TO_WEI * GWEI_TO_WEI);
        return uint64(MathUpgradeable.min(MAX_VALIDATOR_BALANCE_GWEI, effectiveBalanceGwei));
    }

    function _calculateSharesDelta(uint256 newAmountWei, uint256 currentAmountWei) internal pure returns(int256){
        return (int256(newAmountWei) - int256(currentAmountWei));
    }




    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}