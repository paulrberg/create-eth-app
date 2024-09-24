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

pragma solidity ^0.8.0;

import "./Merkle.sol";
import "../libraries/Endian.sol";

//Utility library for parsing and PHASE0 beacon chain block headers
//SSZ Spec: https://github.com/ethereum/consensus-specs/blob/dev/ssz/simple-serialize.md#merkleization
//BeaconBlockHeader Spec: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#beaconblockheader
//BeaconState Spec: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#beaconstate
library BeaconChainProofs {
    // constants are the number of fields and the heights of the different merkle trees used in merkleizing beacon chain containers
    uint256 internal constant NUM_BEACON_BLOCK_HEADER_FIELDS = 5;
    uint256 internal constant BEACON_BLOCK_HEADER_FIELD_TREE_HEIGHT = 3;

    uint256 internal constant NUM_BEACON_BLOCK_BODY_FIELDS = 11;
    uint256 internal constant BEACON_BLOCK_BODY_FIELD_TREE_HEIGHT = 4;

    uint256 internal constant NUM_BEACON_STATE_FIELDS = 21;
    uint256 internal constant BEACON_STATE_FIELD_TREE_HEIGHT = 5;

    uint256 internal constant NUM_ETH1_DATA_FIELDS = 3;
    uint256 internal constant ETH1_DATA_FIELD_TREE_HEIGHT = 2;

    uint256 internal constant NUM_VALIDATOR_FIELDS = 8;
    uint256 internal constant VALIDATOR_FIELD_TREE_HEIGHT = 3;

    uint256 internal constant NUM_EXECUTION_PAYLOAD_HEADER_FIELDS = 15;
    uint256 internal constant EXECUTION_PAYLOAD_HEADER_FIELD_TREE_HEIGHT = 4;


    uint256 internal constant NUM_EXECUTION_PAYLOAD_FIELDS = 15;
    uint256 internal constant EXECUTION_PAYLOAD_FIELD_TREE_HEIGHT = 4;


    // HISTORICAL_ROOTS_LIMIT	 = 2**24, so tree height is 24
    uint256 internal constant HISTORICAL_ROOTS_TREE_HEIGHT = 24;

    // HISTORICAL_BATCH is root of state_roots and block_root, so number of leaves =  2^1
    uint256 internal constant HISTORICAL_BATCH_TREE_HEIGHT = 1;

    // SLOTS_PER_HISTORICAL_ROOT = 2**13, so tree height is 13
    uint256 internal constant STATE_ROOTS_TREE_HEIGHT = 13;
    uint256 internal constant BLOCK_ROOTS_TREE_HEIGHT = 13;


    uint256 internal constant NUM_WITHDRAWAL_FIELDS = 4;
    // tree height for hash tree of an individual withdrawal container
    uint256 internal constant WITHDRAWAL_FIELD_TREE_HEIGHT = 2;

    uint256 internal constant VALIDATOR_TREE_HEIGHT = 40;
    //refer to the eigenlayer-cli proof library.  Despite being the same dimensions as the validator tree, the balance tree is merkleized differently
    uint256 internal constant BALANCE_TREE_HEIGHT = 38;

    // MAX_WITHDRAWALS_PER_PAYLOAD = 2**4, making tree height = 4
    uint256 internal constant WITHDRAWALS_TREE_HEIGHT = 4;

    //in beacon block body
    uint256 internal constant EXECUTION_PAYLOAD_INDEX = 9;

    // in beacon block header
    uint256 internal constant STATE_ROOT_INDEX = 3;
    uint256 internal constant PROPOSER_INDEX_INDEX = 1;
    uint256 internal constant SLOT_INDEX = 0;
    uint256 internal constant BODY_ROOT_INDEX = 4;
    // in beacon state
    uint256 internal constant STATE_ROOTS_INDEX = 6;
    uint256 internal constant BLOCK_ROOTS_INDEX = 5;
    uint256 internal constant HISTORICAL_ROOTS_INDEX = 7;
    uint256 internal constant ETH_1_ROOT_INDEX = 8;
    uint256 internal constant VALIDATOR_TREE_ROOT_INDEX = 11;
    uint256 internal constant BALANCE_INDEX = 12;
    uint256 internal constant EXECUTION_PAYLOAD_HEADER_INDEX = 24;
    uint256 internal constant HISTORICAL_BATCH_STATE_ROOT_INDEX = 1;
    uint256 internal constant BEACON_STATE_SLOT_INDEX = 2;
    uint256 internal constant LATEST_BLOCK_HEADER_ROOT_INDEX = 4;

    // in validator
    uint256 internal constant VALIDATOR_PUBKEY_INDEX = 0;
    uint256 internal constant VALIDATOR_WITHDRAWAL_CREDENTIALS_INDEX = 1;
    uint256 internal constant VALIDATOR_BALANCE_INDEX = 2;
    uint256 internal constant VALIDATOR_SLASHED_INDEX = 3;
    uint256 internal constant VALIDATOR_WITHDRAWABLE_EPOCH_INDEX = 7;
    
    // in execution payload header
    uint256 internal constant TIMESTAMP_INDEX = 9;
    uint256 internal constant WITHDRAWALS_ROOT_INDEX = 14;

    //in execution payload
    uint256 internal constant WITHDRAWALS_INDEX = 14;

    // in withdrawal
    uint256 internal constant WITHDRAWAL_VALIDATOR_INDEX_INDEX = 1;
    uint256 internal constant WITHDRAWAL_VALIDATOR_AMOUNT_INDEX = 3;

    //In historicalBatch
    uint256 internal constant HISTORICALBATCH_STATEROOTS_INDEX = 1;

    //Misc Constants
    uint256 internal constant SLOTS_PER_EPOCH = 32;

    bytes8 internal constant UINT64_MASK = 0xffffffffffffffff;


    /// @notice This struct contains the merkle proofs and leaves needed to verify a partial/full withdrawal
    struct WithdrawalProofs {
        bytes32 beaconStateRoot;
        bytes latestBlockHeaderProof;
        bytes blockHeaderProof;
        bytes withdrawalProof;
        bytes slotProof;
        bytes executionPayloadProof;
        bytes timestampProof;
        uint64 blockHeaderRootIndex;
        uint64 withdrawalIndex;
        bytes32 blockHeaderRoot;
        bytes32 blockBodyRoot;
        bytes32 slotRoot;
        bytes32 timestampRoot;
        bytes32 executionPayloadRoot;
    }

    /// @notice This struct contains the merkle proofs and leaves needed to verify a balance update
    struct BalanceUpdateProofs {
        bytes32 beaconStateRoot;
        bytes latestBlockHeaderProof;
        bytes validatorBalanceProof;
        bytes validatorFieldsProof;
        bytes slotProof;
        bytes32 balanceRoot;
        bytes32 slotRoot;
    }

    // @notice This struct contains the merkle proofs and leaves needed to verify a validator's withdrawal credential
    struct WithdrawalCredentialProofs {
        bytes32 beaconStateRoot;
        bytes latestBlockHeaderProof;
        bytes validatorFieldsProof;
    }

    /**
     * 
     * @notice This function is parses the balanceRoot to get the uint64 balance of a validator.  During merkleization of the
     * beacon state balance tree, four uint64 values (making 32 bytes) are grouped together and treated as a single leaf in the merkle tree. Thus the
     * validatorIndex mod 4 is used to determine which of the four uint64 values to extract from the balanceRoot.
     * @param validatorIndex is the index of the validator being proven for.
     * @param balanceRoot is the combination of 4 validator balances being proven for.
     * @return The validator's balance, in Gwei
     */
   function getBalanceFromBalanceRoot(uint40 validatorIndex, bytes32 balanceRoot) internal pure returns (uint64) {
        uint256 bitShiftAmount = (validatorIndex % 4) * 64;
        bytes32 validatorBalanceLittleEndian = bytes32((uint256(balanceRoot) << bitShiftAmount));
        uint64 validatorBalance = Endian.fromLittleEndianUint64(validatorBalanceLittleEndian);
        return validatorBalance;
    }

    /**
     * @notice This function verifies merkle proofs of the fields of a certain validator against a beacon chain state root
     * @param validatorIndex the index of the proven validator
     * @param beaconStateRoot is the beacon chain state root to be proven against.
     * @param proof is the data used in proving the validator's fields
     * @param validatorFields the claimed fields of the validator
     */
    function verifyValidatorFields(
        bytes32 beaconStateRoot,
        bytes32[] calldata validatorFields,
        bytes calldata proof,
        uint40 validatorIndex
    ) internal view {
        
        require(validatorFields.length == 2**VALIDATOR_FIELD_TREE_HEIGHT, "BeaconChainProofs.verifyValidatorFields: Validator fields has incorrect length");

        /**
         * Note: the length of the validator merkle proof is BeaconChainProofs.VALIDATOR_TREE_HEIGHT + 1.
         * There is an additional layer added by hashing the root with the length of the validator list
         */
        require(proof.length == 32 * ((VALIDATOR_TREE_HEIGHT + 1) + BEACON_STATE_FIELD_TREE_HEIGHT), "BeaconChainProofs.verifyValidatorFields: Proof has incorrect length");
        uint256 index = (VALIDATOR_TREE_ROOT_INDEX << (VALIDATOR_TREE_HEIGHT + 1)) | uint256(validatorIndex);
        // merkleize the validatorFields to get the leaf to prove
        bytes32 validatorRoot = Merkle.merkleizeSha256(validatorFields);

        // verify the proof of the validatorRoot against the beaconStateRoot
        require(Merkle.verifyInclusionSha256(proof, beaconStateRoot, validatorRoot, index), "BeaconChainProofs.verifyValidatorFields: Invalid merkle proof");
    }

    /**
     * @notice This function verifies merkle proofs of the balance of a certain validator against a beacon chain state root
     * @param validatorIndex the index of the proven validator
     * @param beaconStateRoot is the beacon chain state root to be proven against.
     * @param proof is the proof of the balance against the beacon chain state root
     * @param balanceRoot is the serialized balance used to prove the balance of the validator (refer to `getBalanceFromBalanceRoot` above for detailed explanation)
     */
    function verifyValidatorBalance(
        bytes32 beaconStateRoot,
        bytes32 balanceRoot,
        bytes calldata proof,
        uint40 validatorIndex
    ) internal view {
        require(proof.length == 32 * ((BALANCE_TREE_HEIGHT + 1) + BEACON_STATE_FIELD_TREE_HEIGHT), "BeaconChainProofs.verifyValidatorBalance: Proof has incorrect length");

        /**
        * the beacon state's balance list is a list of uint64 values, and these are grouped together in 4s when merkleized.  
        * Therefore, the index of the balance of a validator is validatorIndex/4
        */
        uint256 balanceIndex = uint256(validatorIndex/4);
        balanceIndex = (BALANCE_INDEX << (BALANCE_TREE_HEIGHT + 1)) | balanceIndex;

        require(Merkle.verifyInclusionSha256(proof, beaconStateRoot, balanceRoot, balanceIndex), "BeaconChainProofs.verifyValidatorBalance: Invalid merkle proof");
    }

    /**
     * @notice This function verifies the slot against the state root. the slot is 
     * a tracked in the beacon state.
     * @param beaconStateRoot is the beacon chain state root to be proven against.
     * @param proof is the provided merkle proof
     * @param slotRoot is hashtree root of the slot in the beacon state
     */
    function verifySlotRoot(
        bytes32 beaconStateRoot,
        bytes32 slotRoot,
        bytes calldata proof
    ) internal view {
        require(proof.length == 32 * (BEACON_STATE_FIELD_TREE_HEIGHT), "BeaconChainProofs.verifySlotRoot: Proof has incorrect length");
        //Next we verify the slot against the blockHeaderRoot
        require(Merkle.verifyInclusionSha256(proof, beaconStateRoot, slotRoot, BEACON_STATE_SLOT_INDEX), "BeaconChainProofs.verifyWithdrawalProofs: Invalid slot merkle proof");
    }

    /**
     * @notice This function verifies the latestBlockHeader against the state root. the latestBlockHeader is 
     * a tracked in the beacon state.
     * @param beaconStateRoot is the beacon chain state root to be proven against.
     * @param proof is the provided merkle proof
     * @param latestBlockHeaderRoot is hashtree root of the latest block header in the beacon state
     */
    function verifyStateRootAgainstLatestBlockHeaderRoot(
        bytes32 beaconStateRoot,
        bytes32 latestBlockHeaderRoot,
        bytes calldata proof
    ) internal view {
        require(proof.length == 32 * (BEACON_STATE_FIELD_TREE_HEIGHT), "BeaconChainProofs.verifyStateRootAgainstLatestBlockHeaderRoot: Proof has incorrect length");
        //Next we verify the slot against the blockHeaderRoot
        require(Merkle.verifyInclusionSha256(proof, beaconStateRoot, latestBlockHeaderRoot, LATEST_BLOCK_HEADER_ROOT_INDEX), "BeaconChainProofs.verifyStateRootAgainstLatestBlockHeaderRoot: Invalid latest block header root merkle proof");
    }

    /**
     * @notice This function verifies the slot and the withdrawal fields for a given withdrawal
     * @param beaconStateRoot is the beacon chain state root to be proven against.
     * @param proofs is the provided set of merkle proofs
     * @param withdrawalFields is the serialized withdrawal container to be proven
     */
    function verifyWithdrawalProofs(
        bytes32 beaconStateRoot,
        bytes32[] calldata withdrawalFields,
        WithdrawalProofs calldata proofs
    ) internal view {
        require(withdrawalFields.length == 2**WITHDRAWAL_FIELD_TREE_HEIGHT, "BeaconChainProofs.verifyWithdrawalProofs: withdrawalFields has incorrect length");

        require(proofs.blockHeaderRootIndex < 2**BLOCK_ROOTS_TREE_HEIGHT, "BeaconChainProofs.verifyWithdrawalProofs: blockRootIndex is too large");
        require(proofs.withdrawalIndex < 2**WITHDRAWALS_TREE_HEIGHT, "BeaconChainProofs.verifyWithdrawalProofs: withdrawalIndex is too large");
       
        // verify the block header proof length
        require(proofs.blockHeaderProof.length == 32 * (BEACON_STATE_FIELD_TREE_HEIGHT + BLOCK_ROOTS_TREE_HEIGHT),
            "BeaconChainProofs.verifyWithdrawalProofs: blockHeaderProof has incorrect length");
        require(proofs.withdrawalProof.length == 32 * (EXECUTION_PAYLOAD_HEADER_FIELD_TREE_HEIGHT + WITHDRAWALS_TREE_HEIGHT + 1),
            "BeaconChainProofs.verifyWithdrawalProofs: withdrawalProof has incorrect length");
        require(proofs.executionPayloadProof.length == 32 * (BEACON_BLOCK_HEADER_FIELD_TREE_HEIGHT + BEACON_BLOCK_BODY_FIELD_TREE_HEIGHT),
            "BeaconChainProofs.verifyWithdrawalProofs: executionPayloadProof has incorrect length");
        require(proofs.slotProof.length == 32 * (BEACON_BLOCK_HEADER_FIELD_TREE_HEIGHT),
            "BeaconChainProofs.verifyWithdrawalProofs: slotProof has incorrect length");
        require(proofs.timestampProof.length == 32 * (EXECUTION_PAYLOAD_HEADER_FIELD_TREE_HEIGHT),
            "BeaconChainProofs.verifyWithdrawalProofs: timestampProof has incorrect length");

        {
            /**
            * Computes the block_header_index relative to the beaconStateRoot.  It concatenates the indexes of all the
            * intermediate root indexes from the bottom of the sub trees (the block header container) to the top of the tree
            */
            uint256 blockHeaderIndex = BLOCK_ROOTS_INDEX << (BLOCK_ROOTS_TREE_HEIGHT)  | uint256(proofs.blockHeaderRootIndex);
            // Verify the blockHeaderRoot against the beaconStateRoot
            require(Merkle.verifyInclusionSha256(proofs.blockHeaderProof, beaconStateRoot, proofs.blockHeaderRoot, blockHeaderIndex),
                "BeaconChainProofs.verifyWithdrawalProofs: Invalid block header merkle proof");
        }

        //Next we verify the slot against the blockHeaderRoot
        require(Merkle.verifyInclusionSha256(proofs.slotProof, proofs.blockHeaderRoot, proofs.slotRoot, SLOT_INDEX), "BeaconChainProofs.verifyWithdrawalProofs: Invalid slot merkle proof");
        
        {
            // Next we verify the executionPayloadRoot against the blockHeaderRoot
            uint256 executionPayloadIndex = BODY_ROOT_INDEX << (BEACON_BLOCK_BODY_FIELD_TREE_HEIGHT)| EXECUTION_PAYLOAD_INDEX ;
            require(Merkle.verifyInclusionSha256(proofs.executionPayloadProof, proofs.blockHeaderRoot, proofs.executionPayloadRoot, executionPayloadIndex),
                "BeaconChainProofs.verifyWithdrawalProofs: Invalid executionPayload merkle proof");
        }

        // Next we verify the timestampRoot against the executionPayload root
        require(Merkle.verifyInclusionSha256(proofs.timestampProof, proofs.executionPayloadRoot, proofs.timestampRoot, TIMESTAMP_INDEX),
            "BeaconChainProofs.verifyWithdrawalProofs: Invalid blockNumber merkle proof");


        {
            /**
            * Next we verify the withdrawal fields against the blockHeaderRoot:
            * First we compute the withdrawal_index relative to the blockHeaderRoot by concatenating the indexes of all the 
            * intermediate root indexes from the bottom of the sub trees (the withdrawal container) to the top, the blockHeaderRoot.
            * Then we calculate merkleize the withdrawalFields container to calculate the the withdrawalRoot.
            * Finally we verify the withdrawalRoot against the executionPayloadRoot.
            */
            uint256 withdrawalIndex = WITHDRAWALS_INDEX << (WITHDRAWALS_TREE_HEIGHT + 1) | uint256(proofs.withdrawalIndex);
            bytes32 withdrawalRoot = Merkle.merkleizeSha256(withdrawalFields);
            require(Merkle.verifyInclusionSha256(proofs.withdrawalProof, proofs.executionPayloadRoot, withdrawalRoot, withdrawalIndex),
                "BeaconChainProofs.verifyWithdrawalProofs: Invalid withdrawal merkle proof");
        }
    }

}