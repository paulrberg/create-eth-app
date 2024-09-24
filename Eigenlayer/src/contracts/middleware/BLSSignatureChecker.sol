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

import "../interfaces/IBLSRegistry.sol";
import "../libraries/BytesLib.sol";
import "../libraries/MiddlewareUtils.sol";
import "../libraries/BN254.sol";

/**
 * @title Used for checking BLS aggregate signatures from the operators of a `BLSRegistry`.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This is the contract for checking the validity of aggregate operator signatures.
 */
abstract contract BLSSignatureChecker {
    // DATA STRUCTURES
    /**
     * @notice this data structure is used for recording the details on the total stake of the registered
     * operators and those operators who are part of the quorum for a particular taskNumber
     */

    struct SignatoryTotals {
        // total stake of the operators who are in the first quorum
        uint256 signedStakeFirstQuorum;
        // total stake of the operators who are in the second quorum
        uint256 signedStakeSecondQuorum;
        // total amount staked by all operators (irrespective of whether they are in the quorum or not)
        uint256 totalStakeFirstQuorum;
        // total amount staked by all operators (irrespective of whether they are in the quorum or not)
        uint256 totalStakeSecondQuorum;
    }

    // EVENTS
    /**
     * @notice used for recording the event that signature has been checked in checkSignatures function.
     */
    event SignatoryRecord(
        bytes32 msgHash,
        uint32 taskNumber,
        uint256 signedStakeFirstQuorum,
        uint256 signedStakeSecondQuorum,
        // uint256 totalStakeFirstQuorum,
        // uint256 totalStakeSecondQuorum,
        bytes32[] pubkeyHashes
    );

    IQuorumRegistry public immutable registry;

    constructor(IQuorumRegistry _registry) {
        registry = _registry;
    }

    // CONSTANTS -- commented out lines are due to inline assembly supporting *only* 'direct number constants' (for now, at least)
    uint256 internal constant BYTE_LENGTH_totalStakeIndex = 6;
    uint256 internal constant BYTE_LENGTH_referenceBlockNumber = 4;
    uint256 internal constant BYTE_LENGTH_taskNumberToConfirm = 4;
    uint256 internal constant BYTE_LENGTH_numberNonSigners = 4;
    // specifying a G2 public key requires 4 32-byte slots worth of data
    uint256 internal constant BYTE_LENGTH_G1_POINT = 64;
    uint256 internal constant BYTE_LENGTH_G2_POINT = 128;
    uint256 internal constant BYTE_LENGTH_stakeIndex = 4;
    // uint256 internal constant BYTE_LENGTH_NON_SIGNER_INFO = BYTE_LENGTH_G1_POINT + BYTE_LENGTH_stakeIndex;
    uint256 internal constant BYTE_LENGTH_NON_SIGNER_INFO = 68;
    uint256 internal constant BYTE_LENGTH_apkIndex = 4;

    // uint256 internal constant BIT_SHIFT_totalStakeIndex = 256 - (BYTE_LENGTH_totalStakeIndex * 8);
    uint256 internal constant BIT_SHIFT_totalStakeIndex = 208;
    // uint256 internal constant BIT_SHIFT_referenceBlockNumber = 256 - (BYTE_LENGTH_referenceBlockNumber * 8);
    uint256 internal constant BIT_SHIFT_referenceBlockNumber = 224;
    // uint256 internal constant BIT_SHIFT_taskNumberToConfirm = 256 - (BYTE_LENGTH_taskNumberToConfirm * 8);
    uint256 internal constant BIT_SHIFT_taskNumberToConfirm = 224;
    // uint256 internal constant BIT_SHIFT_numberNonSigners = 256 - (BYTE_LENGTH_numberNonSigners * 8);
    uint256 internal constant BIT_SHIFT_numberNonSigners = 224;
    // uint256 internal constant BIT_SHIFT_stakeIndex = 256 - (BYTE_LENGTH_stakeIndex * 8);
    uint256 internal constant BIT_SHIFT_stakeIndex = 224;
    // uint256 internal constant BIT_SHIFT_apkIndex = 256 - (BYTE_LENGTH_apkIndex * 8);
    uint256 internal constant BIT_SHIFT_apkIndex = 224;

    uint256 internal constant CALLDATA_OFFSET_totalStakeIndex = 32;
    // uint256 internal constant CALLDATA_OFFSET_referenceBlockNumber = CALLDATA_OFFSET_totalStakeIndex + BYTE_LENGTH_totalStakeIndex;
    uint256 internal constant CALLDATA_OFFSET_referenceBlockNumber = 38;
    // uint256 internal constant CALLDATA_OFFSET_taskNumberToConfirm = CALLDATA_OFFSET_referenceBlockNumber + BYTE_LENGTH_referenceBlockNumber;
    uint256 internal constant CALLDATA_OFFSET_taskNumberToConfirm = 42;
    // uint256 internal constant CALLDATA_OFFSET_numberNonSigners = CALLDATA_OFFSET_taskNumberToConfirm + BYTE_LENGTH_taskNumberToConfirm;
    uint256 internal constant CALLDATA_OFFSET_numberNonSigners = 46;
    // uint256 internal constant CALLDATA_OFFSET_NonsignerPubkeys = CALLDATA_OFFSET_numberNonSigners + BYTE_LENGTH_numberNonSigners;
    uint256 internal constant CALLDATA_OFFSET_NonsignerPubkeys = 50;

    /**
     * @notice This function is called by disperser when it has aggregated all the signatures of the operators
     * that are part of the quorum for a particular taskNumber and is asserting them into on-chain. The function
     * checks that the claim for aggregated signatures are valid.
     *
     * The thesis of this procedure entails:
     * - computing the aggregated pubkey of all the operators that are not part of the quorum for
     * this specific taskNumber (represented by aggNonSignerPubkey)
     * - getting the aggregated pubkey of all registered nodes at the time of pre-commit by the
     * disperser (represented by pk),
     * - do subtraction of aggNonSignerPubkey from pk over Jacobian coordinate system to get aggregated pubkey
     * of all operators that are part of quorum.
     * - use this aggregated pubkey to verify the aggregated signature under BLS scheme.
     */
    /**
     * @dev This calldata is of the format:
     * <
     * bytes32 msgHash, the taskHash for which disperser is calling checkSignatures
     * uint48 index of the totalStake corresponding to the dataStoreId in the 'totalStakeHistory' array of the BLSRegistry
     * uint32 blockNumber, the blockNumber at which the task was initated
     * uint32 taskNumberToConfirm
     * uint32 numberOfNonSigners,
     * {uint256[2] pubkeyG1, uint32 stakeIndex}[numberOfNonSigners] the G1 public key and the index to query of `pubkeyHashToStakeHistory` for each nonsigner,
     * uint32 apkIndex, the index in the `apkUpdates` array at which we want to load the aggregate public key
     * uint256[2] apkG1 (G1 aggregate public key, including nonSigners),
     * uint256[4] apkG2 (G2 aggregate public key, not including nonSigners),
     * uint256[2] sigma, the aggregate signature itself
     * >
     * 
     * @dev Before signature verification, the function verifies operator stake information.  This includes ensuring that the provided `referenceBlockNumber`
     * is correct, i.e., ensure that the stake returned from the specified block number is recent enough and that the stake is either the most recent update
     * for the total stake (or the operator) or latest before the referenceBlockNumber.
     * The next step involves computing the aggregated pub key of all the operators that are not part of the quorum for this specific taskNumber.
     * We use a loop to iterate through the `nonSignerPK` array, loading each individual public key from calldata. Before the loop, we isolate the first public key
     * calldataload - this implementation saves us one ecAdd operation, which would be performed in the i=0 iteration otherwise.
     * Within the loop, each non-signer public key is loaded from the calldata into memory.  The most recent staking-related information is retrieved and is subtracted
     * from the total stake of validators in the quorum.  Then the aggregate public key and the aggregate non-signer public key is subtracted from it.
     * Finally  the siganture is verified by computing the elliptic curve pairing.
     */
    function checkSignatures(bytes calldata data)
        public
        returns (
            uint32 taskNumberToConfirm,
            uint32 referenceBlockNumber,
            bytes32 msgHash,
            SignatoryTotals memory signedTotals,
            bytes32 compressedSignatoryRecord
        )
    {
        // temporary variable used to hold various numbers
        uint256 placeholder;

        uint256 pointer;
        
        assembly {
            pointer := data.offset
            /**
             * Get the 32 bytes immediately after the function signature and length + offset encoding of 'bytes
             * calldata' input type, which represents the msgHash for which the disperser is calling `checkSignatures`
             */
            msgHash := calldataload(pointer)
            
            // Get the 6 bytes immediately after the above, which represent the index of the totalStake in the 'totalStakeHistory' array
            placeholder := shr(BIT_SHIFT_totalStakeIndex, calldataload(add(pointer, CALLDATA_OFFSET_totalStakeIndex)))
        }

        // fetch the 4 byte referenceBlockNumber, the block number from which stakes are going to be read from
        assembly {
            referenceBlockNumber :=
                shr(BIT_SHIFT_referenceBlockNumber, calldataload(add(pointer, CALLDATA_OFFSET_referenceBlockNumber)))
        }

        // get information on total stakes
        IQuorumRegistry.OperatorStake memory localStakeObject = registry.getTotalStakeFromIndex(placeholder);

        // check that the returned OperatorStake object is the most recent for the referenceBlockNumber
        _validateOperatorStake(localStakeObject, referenceBlockNumber);

        // copy total stakes amounts to `signedTotals` -- the 'signedStake' amounts are decreased later, to reflect non-signers
        signedTotals.totalStakeFirstQuorum = localStakeObject.firstQuorumStake;
        signedTotals.signedStakeFirstQuorum = localStakeObject.firstQuorumStake;
        signedTotals.totalStakeSecondQuorum = localStakeObject.secondQuorumStake;
        signedTotals.signedStakeSecondQuorum = localStakeObject.secondQuorumStake;

        assembly {
            //fetch the task number to avoid replay signing on same taskhash for different datastore
            taskNumberToConfirm :=
                shr(BIT_SHIFT_taskNumberToConfirm, calldataload(add(pointer, CALLDATA_OFFSET_taskNumberToConfirm)))
            // get the 4 bytes immediately after the above, which represent the
            // number of operators that aren't present in the quorum
            // slither-disable-next-line write-after-write
            placeholder := shr(BIT_SHIFT_numberNonSigners, calldataload(add(pointer, CALLDATA_OFFSET_numberNonSigners)))
        }

        // we have read (32 + 6 + 4 + 4 + 4) = 50 bytes of calldata so far
        pointer += CALLDATA_OFFSET_NonsignerPubkeys;

        // to be used for holding the pub key hashes of the operators that aren't part of the quorum
        bytes32[] memory pubkeyHashes = new bytes32[](placeholder);
        // intialize some memory eventually to be the input for call to ecPairing precompile contract
        uint256[12] memory input;
        // used for verifying that precompile calls are successful
        bool success;

        /**
         * @dev The next step involves computing the aggregated pub key of all the operators
         * that are not part of the quorum for this specific taskNumber.
         */

        /**
         * @dev loading pubkey for the first operator that is not part of the quorum as listed in the calldata;
         * Note that this need not be a special case and *could* be subsumed in the for loop below.
         * However, this implementation saves one ecAdd operation, which would be performed in the i=0 iteration otherwise.
         * @dev Recall that `placeholder` here is the number of operators *not* included in the quorum
         * @dev (input[0], input[1]) is the aggregated non singer public key
         */
        if (placeholder != 0) {
            //load compressed pubkey and the index in the stakes array into memory
            uint32 stakeIndex;
            assembly {
                /**
                 * @notice retrieving the pubkey of the node in Jacobian coordinates
                 */
                // pk.X
                mstore(input, calldataload(pointer))
                // pk.Y
                mstore(add(input, 32), calldataload(add(pointer, 32)))

                /**
                 * @notice retrieving the index of the stake of the operator in pubkeyHashToStakeHistory in
                 * Registry.sol that was recorded at the time of pre-commit.
                 */
                stakeIndex := shr(BIT_SHIFT_stakeIndex, calldataload(add(pointer, BYTE_LENGTH_G1_POINT)))
            }
            // We have read (32 + 32 + 4) = 68 additional bytes of calldata in the above assembly block.
            // Update pointer accordingly.
            unchecked {
                pointer += BYTE_LENGTH_NON_SIGNER_INFO;
            }

            // get pubkeyHash and add it to pubkeyHashes of operators that aren't part of the quorum.
            bytes32 pubkeyHash = keccak256(abi.encodePacked(input[0], input[1]));


            pubkeyHashes[0] = pubkeyHash;

            // querying the VoteWeigher for getting information on the operator's stake
            // at the time of pre-commit
            localStakeObject = registry.getStakeFromPubkeyHashAndIndex(pubkeyHash, stakeIndex);

            // check that the returned OperatorStake object is the most recent for the referenceBlockNumber
            _validateOperatorStake(localStakeObject, referenceBlockNumber);

            // subtract operator stakes from totals
            signedTotals.signedStakeFirstQuorum -= localStakeObject.firstQuorumStake;
            signedTotals.signedStakeSecondQuorum -= localStakeObject.secondQuorumStake;
        }

        /**
         * @dev store each non signer's public key in (input[2], input[3]) and add them to the aggregate non signer public key
         * @dev keep track of the aggreagate non signing stake too
         */
        for (uint256 i = 1; i < placeholder;) {
            //load compressed pubkey and the index in the stakes array into memory
            uint32 stakeIndex;
            assembly {
                /// @notice retrieving the pubkey of the operator that is not part of the quorum
                mstore(add(input, 64), calldataload(pointer))
                mstore(add(input, 96), calldataload(add(pointer, 32)))

                /**
                 * @notice retrieving the index of the stake of the operator in pubkeyHashToStakeHistory in
                 * Registry.sol that was recorded at the time of pre-commit.
                 */
                // slither-disable-next-line variable-scope
                stakeIndex := shr(BIT_SHIFT_stakeIndex, calldataload(add(pointer, BYTE_LENGTH_G1_POINT)))
            }

            // We have read (32 + 32 + 4) = 68 additional bytes of calldata in the above assembly block.
            // Update pointer accordingly.
            unchecked {
                pointer += BYTE_LENGTH_NON_SIGNER_INFO;
            }

            // get pubkeyHash and add it to pubkeyHashes of operators that aren't part of the quorum.
            bytes32 pubkeyHash = keccak256(abi.encodePacked(input[2], input[3]));

            //pubkeys should be ordered in ascending order of hash to make proofs of signing or
            // non signing constant time
            /**
             * @dev this invariant is used in forceOperatorToDisclose in ServiceManager.sol
             */
            require(uint256(pubkeyHash) > uint256(pubkeyHashes[i - 1]), "BLSSignatureChecker.checkSignatures: Pubkey hashes must be in ascending order");

            // recording the pubkey hash
            pubkeyHashes[i] = pubkeyHash;

            // querying the VoteWeigher for getting information on the operator's stake
            // at the time of pre-commit
            localStakeObject = registry.getStakeFromPubkeyHashAndIndex(pubkeyHash, stakeIndex);

            // check that the returned OperatorStake object is the most recent for the referenceBlockNumber
            _validateOperatorStake(localStakeObject, referenceBlockNumber);

            //subtract validator stakes from totals
            signedTotals.signedStakeFirstQuorum -= localStakeObject.firstQuorumStake;
            signedTotals.signedStakeSecondQuorum -= localStakeObject.secondQuorumStake;
            
            // call to ecAdd
            // aggregateNonSignerPublicKey = aggregateNonSignerPublicKey + nonSignerPublicKey
            // (input[0], input[1])        = (input[0], input[1])        + (input[2], input[3])
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := staticcall(sub(gas(), 2000), 6, input, 0x80, input, 0x40)
                // Use "invalid" to make gas estimation work
                switch success
                case 0 {
                    invalid()
                }
            }
            require(success, "BLSSignatureChecker.checkSignatures: non signer addition failed");

            unchecked {
                ++i;
            }
        }
        // usage of a scoped block here minorly decreases gas usage
        {
            uint32 apkIndex;
            assembly {
                //get next 32 bits which would be the apkIndex of apkUpdates in Registry.sol
                apkIndex := shr(BIT_SHIFT_apkIndex, calldataload(pointer))
                // Update pointer to account for the 4 bytes specifying the apkIndex
                pointer := add(pointer, BYTE_LENGTH_apkIndex)

                /**
                 * @notice Get the aggregated publickey at the moment when pre-commit happened
                 * @dev Aggregated pubkey given as part of calldata instead of being retrieved from voteWeigher reduces number of SLOADs
                 * @dev (input[2], input[3]) is the apk
                 */
                mstore(add(input, 64), calldataload(pointer))
                mstore(add(input, 96), calldataload(add(pointer, 32)))
            }

            // We have read (32 + 32) = 64 additional bytes of calldata in the above assembly block.
            // Update pointer accordingly.
            unchecked {
                pointer += BYTE_LENGTH_G1_POINT;
            }

            // make sure the caller has provided the correct aggPubKey
            require(
                IBLSRegistry(address(registry)).getCorrectApkHash(apkIndex, referenceBlockNumber) == keccak256(abi.encodePacked(input[2], input[3])),
                "BLSSignatureChecker.checkSignatures: Incorrect apk provided"
            );

            
        }

        // if at least 1 non-signer
        if (placeholder != 0) {
            /**
             * @notice need to subtract aggNonSignerPubkey from the apk to get aggregate signature of all
             * operators that are part of the quorum
             */
            // negate aggNonSignerPubkey
            input[1] = (BN254.FP_MODULUS - input[1]) % BN254.FP_MODULUS;

            // call to ecAdd
            // singerPublicKey      = -aggregateNonSignerPublicKey + apk
            // (input[2], input[3]) = (input[0], input[1])         + (input[2], input[3])
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := staticcall(sub(gas(), 2000), 6, input, 0x80, add(input, 0x40), 0x40)
            }
            require(success, "BLSSignatureChecker.checkSignatures: aggregate non signer addition failed");

            // emit log_named_uint("agg new pubkey", input[2]);
            // emit log_named_uint("agg new pubkey", input[3]);
            
        }

        // Now, (input[2], input[3]) is the signingPubkey

        // compute H(M) in G1
        (input[6], input[7]) = BN254.hashToG1(msgHash);

        // emit log_named_uint("msgHash G1", input[6]);
        // emit log_named_uint("msgHash G1", pointer);


        // Load the G2 public key into (input[8], input[9], input[10], input[11])
        assembly {
            mstore(add(input, 288), calldataload(pointer)) //input[9] = pkG2.X1
            mstore(add(input, 256), calldataload(add(pointer, 32))) //input[8] = pkG2.X0
            mstore(add(input, 352), calldataload(add(pointer, 64))) //input[11] = pkG2.Y1
            mstore(add(input, 320), calldataload(add(pointer, 96))) //input[10] = pkG2.Y0
        }

        unchecked {
            pointer += BYTE_LENGTH_G2_POINT;
        }

        // Load the G1 signature, sigma, into (input[0], input[1])
        assembly {
            mstore(input, calldataload(pointer))
            mstore(add(input, 32), calldataload(add(pointer, 32)))
        }

        unchecked {
            pointer += BYTE_LENGTH_G1_POINT;
        }

        // generate random challenge for public key equality 
        // gamma = keccak(simga.X, sigma.Y, signingPublicKey.X, signingPublicKey.Y, H(m).X, H(m).Y, 
        //         signingPublicKeyG2.X1, signingPublicKeyG2.X0, signingPublicKeyG2.Y1, signingPublicKeyG2.Y0)
        input[4] = uint256(keccak256(abi.encodePacked(input[0], input[1], input[2], input[3], input[6], input[7], input[8], input[9], input[10], input[11])));

        // call ecMul
        // (input[2], input[3]) = (input[2], input[3]) * input[4] = signingPublicKey * gamma
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, add(input, 0x40), 0x60, add(input, 0x40), 0x40)
        }
        require(success, "BLSSignatureChecker.checkSignatures: aggregate signer public key random shift failed");
        


        // call ecAdd
        // (input[0], input[1]) = (input[0], input[1]) + (input[2], input[3]) = sigma + gamma * signingPublicKey
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, input, 0x40)
        }
        require(success, "BLSSignatureChecker.checkSignatures: aggregate signer public key and signature addition failed");

        // (input[2], input[3]) = g1, the G1 generator
        input[2] = 1;
        input[3] = 2;

        // call ecMul
        // (input[4], input[5]) = (input[2], input[3]) * input[4] = g1 * gamma 
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, add(input, 0x40), 0x60, add(input, 0x80), 0x40)
        }
        require(success, "BLSSignatureChecker.checkSignatures: generator random shift failed");

        // (input[6], input[7]) = (input[4], input[5]) + (input[6], input[7]) = g1 * gamma + H(m)
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, add(input, 0x80), 0x80, add(input, 0xC0), 0x40)
        }
        require(success, "BLSSignatureChecker.checkSignatures: generator random shift and G1 hash addition failed");

        // insert negated coordinates of the generator for G2
        input[2] = BN254.nG2x1;
        input[3] = BN254.nG2x0;
        input[4] = BN254.nG2y1;
        input[5] = BN254.nG2y0;

        // in summary
        // (input[0], input[1]) =  sigma + gamma * signingPublicKey
        // (input[2], input[3], input[4], input[5]) = negated generator of G2
        // (input[6], input[7]) = g1 * gamma + H(m)
        // (input[8], input[9], input[10], input[11]) = public key in G2
        
        
        /**
         * @notice now we verify that e(sigma + gamma * pk, -g2)e(H(m) + gamma * g1, pkG2) == 1
         */

        assembly {
            // check the pairing; if incorrect, revert                
            // staticcall address 8 (ecPairing precompile), forward all gas, send 384 bytes (0x180 in hex) = 12 (32-byte) inputs.
            // store the return data in input[0], and copy only 32 bytes of return data (since precompile returns boolean)
            success := staticcall(sub(gas(), 2000), 8, input, 0x180, input, 0x20)
        }
        require(success, "BLSSignatureChecker.checkSignatures: pairing precompile call failed");
        // check that the provided signature is correct
        require(input[0] == 1, "BLSSignatureChecker.checkSignatures: Pairing unsuccessful");

        emit SignatoryRecord(
            msgHash,
            taskNumberToConfirm,
            signedTotals.signedStakeFirstQuorum,
            signedTotals.signedStakeSecondQuorum,
            pubkeyHashes
        );

        // set compressedSignatoryRecord variable used for fraudproofs
        compressedSignatoryRecord = MiddlewareUtils.computeSignatoryRecordHash(
            taskNumberToConfirm,
            pubkeyHashes,
            signedTotals.signedStakeFirstQuorum,
            signedTotals.signedStakeSecondQuorum
        );

        // return taskNumber, referenceBlockNumber, msgHash, total stakes that signed, and a hash of the signatories
        return (taskNumberToConfirm, referenceBlockNumber, msgHash, signedTotals, compressedSignatoryRecord);
    }

    // simple internal function for validating that the OperatorStake returned from a specified index is the correct one
    function _validateOperatorStake(IQuorumRegistry.OperatorStake memory opStake, uint32 referenceBlockNumber)
        internal
        pure
    {
        // check that the stake returned from the specified index is recent enough
        require(opStake.updateBlockNumber <= referenceBlockNumber, "Provided stake index is too early");

        /**
         * check that stake is either the most recent update for the total stake (or the operator),
         * or latest before the referenceBlockNumber
         */
        require(
            opStake.nextUpdateBlockNumber == 0 || opStake.nextUpdateBlockNumber > referenceBlockNumber,
            "Provided stake index is not the most recent for blockNumber"
        );
    }
}
