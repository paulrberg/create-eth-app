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
pragma solidity >=0.5.0;

import "./IRegistry.sol";

/**
 * @title Interface for a `Registry`-type contract that uses either 1 or 2 quorums.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This contract does not currently support n-quorums where n >= 3.
 * Note in particular the presence of only `firstQuorumStake` and `secondQuorumStake` in the `OperatorStake` struct.
 */
interface IQuorumRegistry is IRegistry {
    // DATA STRUCTURES
    enum Status
    {
        // default is inactive
        INACTIVE,
        ACTIVE
    }

    /**
     * @notice  Data structure for storing info on operators to be used for:
     * - sending data by the sequencer
     * - payment and associated challenges
     */
    struct Operator {
        // hash of pubkey of the operator
        bytes32 pubkeyHash;
        // start taskNumber from which the  operator has been registered
        uint32 fromTaskNumber;
        // indicates whether the operator is actively registered for serving the middleware or not
        Status status;
    }

    // struct used to give definitive ordering to operators at each blockNumber
    struct OperatorIndex {
        // blockNumber number at which operator index changed
        // note that the operator's index is different *for this block number*, i.e. the *new* index is *inclusive* of this value
        uint32 toBlockNumber;
        // index of the operator in array of operators, or the total number of operators if in the 'totalOperatorsHistory'
        uint32 index;
    }

    /// @notice struct used to store the stakes of an individual operator or the sum of all operators' stakes, for storage
    struct OperatorStake {
        // the block number at which the stake amounts were updated and stored
        uint32 updateBlockNumber;
        // the block number at which the *next update* occurred.
        /// @notice This entry has the value **0** until another update takes place.
        uint32 nextUpdateBlockNumber;
        // stake weight for the first quorum
        uint96 firstQuorumStake;
        // stake weight for the second quorum. Will always be zero in the event that only one quorum is used
        uint96 secondQuorumStake;
    }

    function getLengthOfTotalStakeHistory() external view returns (uint256);

    /**
     * @notice Returns the `index`-th entry in the dynamic array of total stake, `totalStakeHistory`.
     * @dev Function will revert in the event that `index` is out-of-bounds.
     */
    function getTotalStakeFromIndex(uint256 index) external view returns (OperatorStake memory);

    /// @notice Returns the stored pubkeyHash for the specified `operator`.
    function getOperatorPubkeyHash(address operator) external view returns (bytes32);

    /// @notice Returns task number from when `operator` has been registered.
    function getFromTaskNumberForOperator(address operator) external view returns (uint32);

    /**
     * @notice Returns the stake weight corresponding to `pubkeyHash`, at the
     * `index`-th entry in the `pubkeyHashToStakeHistory[pubkeyHash]` array.
     * @param pubkeyHash Hash of the public key of the operator of interest.
     * @param index Array index for lookup, within the dynamic array `pubkeyHashToStakeHistory[pubkeyHash]`.
     * @dev Function will revert if `index` is out-of-bounds.
     */
    function getStakeFromPubkeyHashAndIndex(bytes32 pubkeyHash, uint256 index)
        external
        view
        returns (OperatorStake memory);

    /**
     * @notice Checks that the `operator` was active at the `blockNumber`, using the specified `stakeHistoryIndex` as proof.
     * @param operator is the operator of interest
     * @param blockNumber is the block number of interest
     * @param stakeHistoryIndex specifies an index in `pubkeyHashToStakeHistory[pubkeyHash]`, where `pubkeyHash` is looked up
     * in `registry[operator].pubkeyHash`
     * @return 'true' if it is successfully proven that  the `operator` was active at the `blockNumber`, and 'false' otherwise
     * @dev In order for this function to return 'true', the inputs must satisfy all of the following list:
     * 1) `pubkeyHashToStakeHistory[pubkeyHash][index].updateBlockNumber <= blockNumber`
     * 2) `pubkeyHashToStakeHistory[pubkeyHash][index].nextUpdateBlockNumber` must be either `0` (signifying no next update) or
     * is must be strictly greater than `blockNumber`
     * 3) `pubkeyHashToStakeHistory[pubkeyHash][index].firstQuorumStake > 0`
     * or `pubkeyHashToStakeHistory[pubkeyHash][index].secondQuorumStake > 0`, i.e. the operator had nonzero stake
     * @dev Note that a return value of 'false' does not guarantee that the `operator` was inactive at `blockNumber`, since a
     * bad `stakeHistoryIndex` can be supplied in order to obtain a response of 'false'.
     */
    function checkOperatorActiveAtBlockNumber(
        address operator,
        uint256 blockNumber,
        uint256 stakeHistoryIndex
        ) external view returns (bool);

    /**
     * @notice Checks that the `operator` was inactive at the `blockNumber`, using the specified `stakeHistoryIndex` as proof.
     * @param operator is the operator of interest
     * @param blockNumber is the block number of interest
     * @param stakeHistoryIndex specifies an index in `pubkeyHashToStakeHistory[pubkeyHash]`, where `pubkeyHash` is looked up
     * in `registry[operator].pubkeyHash`
     * @return 'true' if it is successfully proven that  the `operator` was inactive at the `blockNumber`, and 'false' otherwise
     * @dev In order for this function to return 'true', the inputs must satisfy all of the following list:
     * 1) `pubkeyHashToStakeHistory[pubkeyHash][index].updateBlockNumber <= blockNumber`
     * 2) `pubkeyHashToStakeHistory[pubkeyHash][index].nextUpdateBlockNumber` must be either `0` (signifying no next update) or
     * is must be strictly greater than `blockNumber`
     * 3) `pubkeyHashToStakeHistory[pubkeyHash][index].firstQuorumStake > 0`
     * or `pubkeyHashToStakeHistory[pubkeyHash][index].secondQuorumStake > 0`, i.e. the operator had nonzero stake
     * @dev Note that a return value of 'false' does not guarantee that the `operator` was active at `blockNumber`, since a
     * bad `stakeHistoryIndex` can be supplied in order to obtain a response of 'false'.
     */
    function checkOperatorInactiveAtBlockNumber(
        address operator,
        uint256 blockNumber,
        uint256 stakeHistoryIndex
        ) external view returns (bool);

    /**
     * @notice Looks up the `operator`'s index in the dynamic array `operatorList` at the specified `blockNumber`.
     * @param index Used to specify the entry within the dynamic array `pubkeyHashToIndexHistory[pubkeyHash]` to 
     * read data from, where `pubkeyHash` is looked up from `operator`'s registration info
     * @param blockNumber Is the desired block number at which we wish to query the operator's position in the `operatorList` array
     * @dev Function will revert in the event that the specified `index` input does not identify the appropriate entry in the
     * array `pubkeyHashToIndexHistory[pubkeyHash]` to pull the info from.
    */
    function getOperatorIndex(address operator, uint32 blockNumber, uint32 index) external view returns (uint32);

    /**
     * @notice Looks up the number of total operators at the specified `blockNumber`.
     * @param index Input used to specify the entry within the dynamic array `totalOperatorsHistory` to read data from.
     * @dev This function will revert if the provided `index` is out of bounds.
    */
    function getTotalOperators(uint32 blockNumber, uint32 index) external view returns (uint32);

    /// @notice Returns the current number of operators of this service.
    function numOperators() external view returns (uint32);

    /**
     * @notice Returns the most recent stake weights for the `operator`
     * @dev Function returns weights of **0** in the event that the operator has no stake history
     */
    function operatorStakes(address operator) external view returns (uint96, uint96);

    /// @notice Returns the stake amounts from the latest entry in `totalStakeHistory`.
    function totalStake() external view returns (uint96, uint96);
}
