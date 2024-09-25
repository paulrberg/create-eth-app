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

import "Eigenlayer/lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../interfaces/IServiceManager.sol";
import "../interfaces/IQuorumRegistry.sol";
import "./VoteWeigherBase.sol";

/**
 * @title An abstract Registry-type contract that is signature scheme agnostic.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This contract is used for
 * - registering new operators
 * - committing to and finalizing de-registration as an operator
 * - updating the stakes of the operator
 * @dev This contract is missing key functions. See `BLSRegistry` or `ECDSARegistry` for examples that inherit from this contract.
 */
abstract contract RegistryBase is VoteWeigherBase, IQuorumRegistry {

    // TODO: set these on initialization
    /// @notice In order to register, an operator must have at least `minimumStakeFirstQuorum` or `minimumStakeSecondQuorum`, as
    /// evaluated by this contract's 'VoteWeigher' logic.
    uint128 public minimumStakeFirstQuorum = 1 wei;
    uint128 public minimumStakeSecondQuorum = 1 wei;

    /// @notice used for storing Operator info on each operator while registration
    mapping(address => Operator) public registry;

    /// @notice used for storing the list of current and past registered operators
    address[] public operatorList;

    /// @notice array of the history of the total stakes -- marked as internal since getTotalStakeFromIndex is a getter for this
    OperatorStake[] internal totalStakeHistory;

    /// @notice array of the history of the number of operators, and the taskNumbers at which the number of operators changed
    OperatorIndex[] public totalOperatorsHistory;

    /// @notice mapping from operator's pubkeyhash to the history of their stake updates
    mapping(bytes32 => OperatorStake[]) public pubkeyHashToStakeHistory;

    /// @notice mapping from operator's pubkeyhash to the history of their index in the array of all operators
    mapping(bytes32 => OperatorIndex[]) public pubkeyHashToIndexHistory;

    // EVENTS
    /// @notice emitted when `operator` updates their socket address to `socket`
    event SocketUpdate(address operator, string socket);

    /// @notice emitted whenever the stake of `operator` is updated
    event StakeUpdate(
        address operator,
        uint96 firstQuorumStake,
        uint96 secondQuorumStake,
        uint32 updateBlockNumber,
        uint32 prevUpdateBlockNumber
    );

    /**
     * @notice Emitted whenever an operator deregisters.
     * The `swapped` address is the address returned by an internal call to the `_popRegistrant` function.
     */
    event Deregistration(address operator, address swapped);

    /**
     * @notice Irrevocably sets the (immutable) `delegation` & `strategyManager` addresses, and `NUMBER_OF_QUORUMS` variable.
     */
    constructor(
        IStrategyManager _strategyManager,
        IServiceManager _serviceManager,
        uint8 _NUMBER_OF_QUORUMS
    ) VoteWeigherBase(_strategyManager, _serviceManager, _NUMBER_OF_QUORUMS)
    // solhint-disable-next-line no-empty-blocks
    {
        require(_NUMBER_OF_QUORUMS <= 2 && _NUMBER_OF_QUORUMS > 0, "RegistryBase: NUMBER_OF_QUORUMS must be less than or equal to 2 and greater than 0");
    }

    /**
     * @notice Adds empty first entries to the dynamic arrays `totalStakeHistory` and `totalOperatorsHistory`,
     * to record an initial condition of zero operators with zero total stake.
     * Adds `_firstQuorumStrategiesConsideredAndMultipliers` and `_secondQuorumStrategiesConsideredAndMultipliers` to the dynamic arrays
     * `strategiesConsideredAndMultipliers[0]` and `strategiesConsideredAndMultipliers[1]` (i.e. to the weighing functions of the quorums)
     */
    function _initialize(
        uint256[] memory _quorumBips,
        StrategyAndWeightingMultiplier[] memory _firstQuorumStrategiesConsideredAndMultipliers,
        StrategyAndWeightingMultiplier[] memory _secondQuorumStrategiesConsideredAndMultipliers
    ) internal virtual onlyInitializing {
        VoteWeigherBase._initialize(_quorumBips);

        // push an empty OperatorStake struct to the total stake history to record starting with zero stake
        OperatorStake memory _totalStake;
        totalStakeHistory.push(_totalStake);

        // push an empty OperatorIndex struct to the total operators history to record starting with zero operators
        OperatorIndex memory _totalOperators;
        totalOperatorsHistory.push(_totalOperators);

        _addStrategiesConsideredAndMultipliers(0, _firstQuorumStrategiesConsideredAndMultipliers);
        _addStrategiesConsideredAndMultipliers(1, _secondQuorumStrategiesConsideredAndMultipliers);
    }

    /**
     * @notice Looks up the `operator`'s index in the dynamic array `operatorList` at the specified `blockNumber`.
     * @param index Used to specify the entry within the dynamic array `pubkeyHashToIndexHistory[pubkeyHash]` to 
     * read data from, where `pubkeyHash` is looked up from `operator`'s registration info
     * @param blockNumber Is the desired block number at which we wish to query the operator's position in the `operatorList` array
     * @dev Function will revert in the event that the specified `index` input does not identify the appropriate entry in the
     * array `pubkeyHashToIndexHistory[pubkeyHash]` to pull the info from.
    */
    function getOperatorIndex(address operator, uint32 blockNumber, uint32 index) external view returns (uint32) {
        // look up the operator's stored pubkeyHash
        bytes32 pubkeyHash = getOperatorPubkeyHash(operator);

        /**
         * Since the 'to' field represents the blockNumber at which a new index started, it is OK if the 
         * previous array entry has 'to' == blockNumber, so we check not strict inequality here
         */
        require(
            index == 0 || pubkeyHashToIndexHistory[pubkeyHash][index - 1].toBlockNumber <= blockNumber,
            "RegistryBase.getOperatorIndex: Operator indexHistory index is too high"
        );
        OperatorIndex memory operatorIndex = pubkeyHashToIndexHistory[pubkeyHash][index];
        /**
         * When deregistering, the operator does *not* serve the current block number -- 'to' gets set (from zero) to the current block number.
         * Since the 'to' field represents the blocknumber at which a new index started, we want to check strict inequality here.
        */
        require(
            operatorIndex.toBlockNumber == 0 || blockNumber < operatorIndex.toBlockNumber,
            "RegistryBase.getOperatorIndex: indexHistory index is too low"
        );
        return operatorIndex.index;
    }

    /**
     * @notice Looks up the number of total operators at the specified `blockNumber`.
     * @param index Input used to specify the entry within the dynamic array `totalOperatorsHistory` to read data from.
     * @dev This function will revert if the provided `index` is out of bounds.
    */
    function getTotalOperators(uint32 blockNumber, uint32 index) external view returns (uint32) {
        /**
         * Since the 'to' field represents the blockNumber at which a new index started, it is OK if the 
         * previous array entry has 'to' == blockNumber, so we check not strict inequality here
         */
        require(
            index == 0 || totalOperatorsHistory[index - 1].toBlockNumber <= blockNumber,
            "RegistryBase.getTotalOperators: TotalOperatorsHistory index is too high"
        );

    
        OperatorIndex memory operatorIndex = totalOperatorsHistory[index];

        // since the 'to' field represents the blockNumber at which a new index started, we want to check strict inequality here

        require(
            operatorIndex.toBlockNumber == 0 || blockNumber < operatorIndex.toBlockNumber,
            "RegistryBase.getTotalOperators: TotalOperatorsHistory index is too low"
        );
        return operatorIndex.index;
    }

    /// @notice Returns whether or not the `operator` is currently an active operator, i.e. is "registered".
    function isActiveOperator(address operator) external view virtual returns (bool) {
        return (registry[operator].status == IQuorumRegistry.Status.ACTIVE);
    }

    /// @notice Returns the stored pubkeyHash for the specified `operator`.
    function getOperatorPubkeyHash(address operator) public view returns (bytes32) {
        return registry[operator].pubkeyHash;
    }

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
        returns (OperatorStake memory)
    {
        return pubkeyHashToStakeHistory[pubkeyHash][index];
    }

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
        ) external view returns (bool)
    {
        // fetch the `operator`'s pubkey hash
        bytes32 pubkeyHash = registry[operator].pubkeyHash;
        // pull the stake history entry specified by `stakeHistoryIndex`
        OperatorStake memory operatorStake = pubkeyHashToStakeHistory[pubkeyHash][stakeHistoryIndex];
        return (
            // check that the update specified by `stakeHistoryIndex` occurred at or prior to `blockNumber`
            (operatorStake.updateBlockNumber <= blockNumber)
            &&
            // if there is a next update, then check that the next update occurred strictly after `blockNumber`
            (operatorStake.nextUpdateBlockNumber == 0 || operatorStake.nextUpdateBlockNumber > blockNumber)
            &&
            /// verify that the stake was non-zero at the time (note: here was use the assumption that the operator was 'inactive'
            /// once their stake fell to zero)
            (operatorStake.firstQuorumStake != 0 || operatorStake.secondQuorumStake != 0) 
        );
    }

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
        ) external view returns (bool)
    {
        // fetch the `operator`'s pubkey hash
        bytes32 pubkeyHash = registry[operator].pubkeyHash;
        // special case for `pubkeyHashToStakeHistory[pubkeyHash]` having lenght zero -- in which case we know the operator was never registered
        if (pubkeyHashToStakeHistory[pubkeyHash].length == 0) {
            return true;
        }
        // pull the stake history entry specified by `stakeHistoryIndex`
        OperatorStake memory operatorStake = pubkeyHashToStakeHistory[pubkeyHash][stakeHistoryIndex];
        return (
            // check that the update specified by `stakeHistoryIndex` occurred at or prior to `blockNumber`
            (operatorStake.updateBlockNumber <= blockNumber)
            &&
            // if there is a next update, then check that the next update occurred strictly after `blockNumber`
            (operatorStake.nextUpdateBlockNumber == 0 || operatorStake.nextUpdateBlockNumber > blockNumber)
            &&
            /// verify that the stake was zero at the time (note: here was use the assumption that the operator was 'inactive'
            /// once their stake fell to zero)
            (operatorStake.firstQuorumStake == 0 && operatorStake.secondQuorumStake == 0) 
        );
    }

    /**
     * @notice Returns the most recent stake weight for the `operator`
     * @dev Function returns an OperatorStake struct with **every entry equal to 0** in the event that the operator has no stake history
     */
    function getMostRecentStakeByOperator(address operator) public view returns (OperatorStake memory) {
        bytes32 pubkeyHash = getOperatorPubkeyHash(operator);
        uint256 historyLength = pubkeyHashToStakeHistory[pubkeyHash].length;
        OperatorStake memory opStake;
        if (historyLength == 0) {
            return opStake;
        } else {
            opStake = pubkeyHashToStakeHistory[pubkeyHash][historyLength - 1];
            return opStake;
        }
    }

    function getStakeHistoryLength(bytes32 pubkeyHash) external view returns (uint256) {
        return pubkeyHashToStakeHistory[pubkeyHash].length;
    }

    function firstQuorumStakedByOperator(address operator) external view returns (uint96) {
        OperatorStake memory opStake = getMostRecentStakeByOperator(operator);
        return opStake.firstQuorumStake;
    }

    function secondQuorumStakedByOperator(address operator) external view returns (uint96) {
        OperatorStake memory opStake = getMostRecentStakeByOperator(operator);
        return opStake.secondQuorumStake;
    }

    /**
     * @notice Returns the most recent stake weights for the `operator`
     * @dev Function returns weights of **0** in the event that the operator has no stake history
     */
    function operatorStakes(address operator) public view returns (uint96, uint96) {
        OperatorStake memory opStake = getMostRecentStakeByOperator(operator);
        return (opStake.firstQuorumStake, opStake.secondQuorumStake);
    }

    /// @notice Returns the stake amounts from the latest entry in `totalStakeHistory`.
    function totalStake() external view returns (uint96, uint96) {
        // no chance of underflow / error in next line, since an empty entry is pushed in the constructor
        OperatorStake memory _totalStake = totalStakeHistory[totalStakeHistory.length - 1];
        return (_totalStake.firstQuorumStake, _totalStake.secondQuorumStake);
    }

    function getLengthOfPubkeyHashStakeHistory(bytes32 pubkeyHash) external view returns (uint256) {
        return pubkeyHashToStakeHistory[pubkeyHash].length;
    }

    function getLengthOfPubkeyHashIndexHistory(bytes32 pubkeyHash) external view returns (uint256) {
        return pubkeyHashToIndexHistory[pubkeyHash].length;
    }

    function getLengthOfTotalStakeHistory() external view returns (uint256) {
        return totalStakeHistory.length;
    }

    function getLengthOfTotalOperatorsHistory() external view returns (uint256) {
        return totalOperatorsHistory.length;
    }

    /**
     * @notice Returns the `index`-th entry in the dynamic array of total stake, `totalStakeHistory`.
     * @dev Function will revert in the event that `index` is out-of-bounds.
     */
    function getTotalStakeFromIndex(uint256 index) external view returns (OperatorStake memory) {
        return totalStakeHistory[index];
    }

    /// @notice Returns task number from when `operator` has been registered.
    function getFromTaskNumberForOperator(address operator) external view returns (uint32) {
        return registry[operator].fromTaskNumber;
    }

    /// @notice Returns the current number of operators of this service.
    function numOperators() public view returns (uint32) {
        return uint32(operatorList.length);
    }

    // MUTATING FUNCTIONS

    /// @notice Adjusts the `minimumStakeFirstQuorum` -- i.e. the node stake (weight) requirement for inclusion in the 1st quorum.
    function setMinimumStakeFirstQuorum(uint128 _minimumStakeFirstQuorum) external onlyServiceManagerOwner {
        minimumStakeFirstQuorum = _minimumStakeFirstQuorum;
    }

    /// @notice Adjusts the `minimumStakeSecondQuorum` -- i.e. the node stake (weight) requirement for inclusion in the 2nd quorum.
    function setMinimumStakeSecondQuorum(uint128 _minimumStakeSecondQuorum) external onlyServiceManagerOwner {
        minimumStakeSecondQuorum = _minimumStakeSecondQuorum;
    }

    function updateSocket(string calldata newSocket) external {
        require(
            registry[msg.sender].status == IQuorumRegistry.Status.ACTIVE,
            "RegistryBase.updateSocket: Can only update socket if active on the service"
        );
        emit SocketUpdate(msg.sender, newSocket);
    }


    // INTERNAL FUNCTIONS
    /**
     * @notice Called when the total number of operators has changed.
     * Sets the `toBlockNumber` field on the last entry *so far* in thedynamic array `totalOperatorsHistory` to the current `block.number`,
     * recording that the previous entry is *no longer the latest* and the block number at which the next was added.
     * Pushes a new entry to `totalOperatorsHistory`, with `index` field set equal to the new amount of operators, recording the new number
     * of total operators (and leaving the `toBlockNumber` field at zero, signaling that this is the latest entry in the array)
     */
    function _updateTotalOperatorsHistory() internal {
        // set the 'toBlockNumber' field on the last entry *so far* in 'totalOperatorsHistory' to the current block number
        totalOperatorsHistory[totalOperatorsHistory.length - 1].toBlockNumber = uint32(block.number);
        // push a new entry to 'totalOperatorsHistory', with 'index' field set equal to the new amount of operators
        OperatorIndex memory _totalOperators;
        _totalOperators.index = uint32(operatorList.length);
        totalOperatorsHistory.push(_totalOperators);
    }

    /**
     * @notice Remove the operator from active status. Removes the operator with the given `pubkeyHash` from the `index` in `operatorList`,
     * updates operatorList and index histories, and performs other necessary updates for removing operator
     */
    function _removeOperator(address operator, bytes32 pubkeyHash, uint32 index) internal virtual {
        // remove the operator's stake
        uint32 updateBlockNumber = _removeOperatorStake(pubkeyHash);

        // store blockNumber at which operator index changed (stopped being applicable)
        pubkeyHashToIndexHistory[pubkeyHash][pubkeyHashToIndexHistory[pubkeyHash].length - 1].toBlockNumber =
            uint32(block.number);

        // remove the operator at `index` from the `operatorList`
        address swappedOperator = _popRegistrant(index);

        // @notice Registrant must continue to serve until the latest block at which an active task expires. this info is used in challenges
        uint32 latestServeUntilBlock = serviceManager.latestServeUntilBlock();
        // committing to not signing off on any more middleware tasks
        registry[operator].status = IQuorumRegistry.Status.INACTIVE;

        // record a stake update unbonding the operator after `latestServeUntilBlock`
        serviceManager.recordLastStakeUpdateAndRevokeSlashingAbility(operator, latestServeUntilBlock);

        // Emit `Deregistration` event
        emit Deregistration(operator, swappedOperator);

        emit StakeUpdate(
            operator,
            // new stakes are zero
            0,
            0,
            uint32(block.number),
            updateBlockNumber
        );
    }

    /**
     * @notice Removes the stakes of the operator with pubkeyHash `pubkeyHash`
     */
    function _removeOperatorStake(bytes32 pubkeyHash) internal returns(uint32) {
        // gas saving by caching length here
        uint256 pubkeyHashToStakeHistoryLengthMinusOne = pubkeyHashToStakeHistory[pubkeyHash].length - 1;

        // determine current stakes
        OperatorStake memory currentStakes =
            pubkeyHashToStakeHistory[pubkeyHash][pubkeyHashToStakeHistoryLengthMinusOne];
        //set nextUpdateBlockNumber in current stakes
        pubkeyHashToStakeHistory[pubkeyHash][pubkeyHashToStakeHistoryLengthMinusOne].nextUpdateBlockNumber =
            uint32(block.number);

        /**
         * @notice recording the information pertaining to change in stake for this operator in the history. operator stakes are set to 0 here.
         */
        pubkeyHashToStakeHistory[pubkeyHash].push(
            OperatorStake({
                // recording the current block number where the operator stake got updated
                updateBlockNumber: uint32(block.number),
                // mark as 0 since the next update has not yet occurred
                nextUpdateBlockNumber: 0,
                // setting the operator's stakes to 0
                firstQuorumStake: 0,
                secondQuorumStake: 0
            })
        );

        // subtract the amounts staked by the operator that is getting deregistered from the total stake
        // copy latest totalStakes to memory
        OperatorStake memory _totalStake = totalStakeHistory[totalStakeHistory.length - 1];
        _totalStake.firstQuorumStake -= currentStakes.firstQuorumStake;
        _totalStake.secondQuorumStake -= currentStakes.secondQuorumStake;
        // update storage of total stake
        _recordTotalStakeUpdate(_totalStake);

        emit StakeUpdate(
            msg.sender,
            // new stakes are zero
            0,
            0,
            uint32(block.number),
            currentStakes.updateBlockNumber
            );
        return currentStakes.updateBlockNumber;
    }

    /**
     * @notice Removes the registrant at the given `index` from the `operatorList`
     * @return swappedOperator is the operator who was swapped with the removed operator in the operatorList,
     * or the *zero address* in the case that the removed operator was already the list operator in the operatorList.
     */
    function _popRegistrant(uint32 index) internal returns (address swappedOperator) {
        // gas saving by caching length here
        uint256 operatorListLengthMinusOne = operatorList.length - 1;
        // Update index info for operator at end of list, if they are not the same as the removed operator
        if (index < operatorListLengthMinusOne) {
            // get existing operator at end of list, and retrieve their pubkeyHash
            swappedOperator = operatorList[operatorListLengthMinusOne];
            Operator memory registrant = registry[swappedOperator];
            bytes32 pubkeyHash = registrant.pubkeyHash;
            // store blockNumber at which operator index changed
            // same operation as above except pubkeyHash is now different (since different operator)
            pubkeyHashToIndexHistory[pubkeyHash][pubkeyHashToIndexHistory[pubkeyHash].length - 1].toBlockNumber =
                uint32(block.number);
            // push new 'OperatorIndex' struct to operator's array of historical indices, with 'index' set equal to 'index' input
            OperatorIndex memory operatorIndex;
            operatorIndex.index = index;
            pubkeyHashToIndexHistory[pubkeyHash].push(operatorIndex);

            // move 'swappedOperator' into 'index' slot in operatorList (swapping them with removed operator)
            operatorList[index] = swappedOperator;
        }

        // slither-disable-next-line costly-loop
        operatorList.pop();

        // Update totalOperatorsHistory
        _updateTotalOperatorsHistory();

        return swappedOperator;
    }

    /// @notice Adds the Operator `operator` with the given `pubkeyHash` to the `operatorList` and performs necessary related updates.
    function _addRegistrant(
        address operator,
        bytes32 pubkeyHash,
        OperatorStake memory _operatorStake
    )
        internal virtual
    {

        require(
            slasher.contractCanSlashOperatorUntilBlock(operator, address(serviceManager)) == type(uint32).max,
            "RegistryBase._addRegistrant: operator must be opted into slashing by the serviceManager"
        );
        // store the Operator's info in mapping
        registry[operator] = Operator({
            pubkeyHash: pubkeyHash,
            status: IQuorumRegistry.Status.ACTIVE,
            fromTaskNumber: serviceManager.taskNumber()
        });

        // add the operator to the list of operators
        operatorList.push(operator);

        // add the `updateBlockNumber` info
        _operatorStake.updateBlockNumber = uint32(block.number);
        // check special case that operator is re-registering (and thus already has some history)
        if (pubkeyHashToStakeHistory[pubkeyHash].length != 0) {
            // correctly set the 'nextUpdateBlockNumber' field for the re-registering operator's oldest history entry
            pubkeyHashToStakeHistory[pubkeyHash][pubkeyHashToStakeHistory[pubkeyHash].length - 1].nextUpdateBlockNumber
                = uint32(block.number);
        }
        // push the new stake for the operator to storage
        pubkeyHashToStakeHistory[pubkeyHash].push(_operatorStake);

        // record `operator`'s index in list of operators
        OperatorIndex memory operatorIndex;
        operatorIndex.index = uint32(operatorList.length - 1);
        pubkeyHashToIndexHistory[pubkeyHash].push(operatorIndex);

        // copy latest totalStakes to memory
        OperatorStake memory _totalStake = totalStakeHistory[totalStakeHistory.length - 1];
        // add operator stakes to total stake (in memory)
        _totalStake.firstQuorumStake += _operatorStake.firstQuorumStake;
        _totalStake.secondQuorumStake += _operatorStake.secondQuorumStake;
        // update storage of total stake
        _recordTotalStakeUpdate(_totalStake);

        // Update totalOperatorsHistory array
        _updateTotalOperatorsHistory();

        // record a stake update not bonding the operator at all (unbonded at 0), because they haven't served anything yet
        serviceManager.recordFirstStakeUpdate(operator, 0);

        emit StakeUpdate(
            operator,
            _operatorStake.firstQuorumStake,
            _operatorStake.secondQuorumStake,
            uint32(block.number),
            // no previous update block number -- use 0 instead
            0
        );
    }

    /**
     * TODO: critique: "Currently only `_registrationStakeEvaluation` uses the `uint8 registrantType` input -- we should **EITHER** store this
     * and keep using it in other places as well, **OR** stop using it altogether"
     */
    /**
     * @notice Used inside of inheriting contracts to validate the registration of `operator` and find their `OperatorStake`.
     * @dev This function does **not** update the stored state of the operator's stakes -- storage updates are performed elsewhere.
     * @return The newly calculated `OperatorStake` for `operator`, stored in memory but not yet committed to storage.
     */
    function _registrationStakeEvaluation(address operator, uint8 operatorType)
        internal
        returns (OperatorStake memory)
    {
        // verify that the `operator` is not already registered
        require(
            registry[operator].status == IQuorumRegistry.Status.INACTIVE,
            "RegistryBase._registrationStakeEvaluation: Operator is already registered"
        );

        OperatorStake memory _operatorStake;

        // if first bit of operatorType is '1', then operator wants to be a validator for the first quorum
        if ((operatorType & 1) == 1) {
            _operatorStake.firstQuorumStake = uint96(weightOfOperator(operator, 0));
            // check if minimum requirement has been met
            if (_operatorStake.firstQuorumStake < minimumStakeFirstQuorum) {
                _operatorStake.firstQuorumStake = uint96(0);
            }
        }

        //if second bit of operatorType is '1', then operator wants to be a validator for the second quorum
        if ((operatorType & 2) == 2) {
            _operatorStake.secondQuorumStake = uint96(weightOfOperator(operator, 1));
            // check if minimum requirement has been met
            if (_operatorStake.secondQuorumStake < minimumStakeSecondQuorum) {
                _operatorStake.secondQuorumStake = uint96(0);
            }
        }

        require(
            _operatorStake.firstQuorumStake > 0 || _operatorStake.secondQuorumStake > 0,
            "RegistryBase._registrationStakeEvaluation: Must register as at least one type of validator"
        );

        return _operatorStake;
    }

    /**
     * @notice Finds the updated stake for `operator`, stores it and records the update.
     * @dev **DOES NOT UPDATE `totalStake` IN ANY WAY** -- `totalStake` updates must be done elsewhere.
     */
    function _updateOperatorStake(address operator, bytes32 pubkeyHash, OperatorStake memory currentOperatorStake, uint256 insertAfter)
        internal
        returns (OperatorStake memory updatedOperatorStake)
    {
        // determine new stakes
        updatedOperatorStake.updateBlockNumber = uint32(block.number);
        updatedOperatorStake.firstQuorumStake = weightOfOperator(operator, 0);
        updatedOperatorStake.secondQuorumStake = weightOfOperator(operator, 1);

        // check if minimum requirements have been met
        if (updatedOperatorStake.firstQuorumStake < minimumStakeFirstQuorum) {
            updatedOperatorStake.firstQuorumStake = uint96(0);
        }
        if (updatedOperatorStake.secondQuorumStake < minimumStakeSecondQuorum) {
            updatedOperatorStake.secondQuorumStake = uint96(0);
        }
        // set nextUpdateBlockNumber in prev stakes
        pubkeyHashToStakeHistory[pubkeyHash][pubkeyHashToStakeHistory[pubkeyHash].length - 1].nextUpdateBlockNumber =
            uint32(block.number);
        // push new stake to storage
        pubkeyHashToStakeHistory[pubkeyHash].push(updatedOperatorStake);
        // record stake update in the slasher
        serviceManager.recordStakeUpdate(operator, uint32(block.number), serviceManager.latestServeUntilBlock(), insertAfter);

        emit StakeUpdate(
            operator,
            updatedOperatorStake.firstQuorumStake,
            updatedOperatorStake.secondQuorumStake,
            uint32(block.number),
            currentOperatorStake.updateBlockNumber
            );
    }

    /// @notice Records that the `totalStake` is now equal to the input param @_totalStake
    function _recordTotalStakeUpdate(OperatorStake memory _totalStake) internal {
        _totalStake.updateBlockNumber = uint32(block.number);
        totalStakeHistory[totalStakeHistory.length - 1].nextUpdateBlockNumber = uint32(block.number);
        totalStakeHistory.push(_totalStake);
    }

    /// @notice Verify that the `operator` is an active operator and that they've provided the correct `index`
    function _deregistrationCheck(address operator, uint32 index) internal view {
        require(
            registry[operator].status == IQuorumRegistry.Status.ACTIVE,
            "RegistryBase._deregistrationCheck: Operator is not registered"
        );

        require(operator == operatorList[index], "RegistryBase._deregistrationCheck: Incorrect index supplied");
    }
}
