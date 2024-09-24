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

import "../interfaces/ISlasher.sol";
import "../interfaces/IDelegationManager.sol";
import "../interfaces/IStrategyManager.sol";
import "../libraries/StructuredLinkedList.sol";
import "../permissions/Pausable.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title The primary 'slashing' contract for EigenLayer.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This contract specifies details on slashing. The functionalities are:
 * - adding contracts who have permission to perform slashing,
 * - revoking permission for slashing from specified contracts,
 * - tracking historic stake updates to ensure that withdrawals can only be completed once no middlewares have slashing rights
 * over the funds being withdrawn
 */
contract Slasher is Initializable, OwnableUpgradeable, ISlasher, Pausable {
    using StructuredLinkedList for StructuredLinkedList.List;

    uint256 private constant HEAD = 0;

    uint8 internal constant PAUSED_OPT_INTO_SLASHING = 0;
    uint8 internal constant PAUSED_FIRST_STAKE_UPDATE = 1;
    uint8 internal constant PAUSED_NEW_FREEZING = 2;

    /// @notice The central StrategyManager contract of EigenLayer
    IStrategyManager public immutable strategyManager;
    /// @notice The DelegationManager contract of EigenLayer
    IDelegationManager public immutable delegation;
    // operator => whitelisted contract with slashing permissions => (the time before which the contract is allowed to slash the user, block it was last updated)
    mapping(address => mapping(address => MiddlewareDetails)) internal _whitelistedContractDetails;
    // staker => if their funds are 'frozen' and potentially subject to slashing or not
    mapping(address => bool) internal frozenStatus;

    uint32 internal constant MAX_CAN_SLASH_UNTIL = type(uint32).max;

    /**
     * operator => a linked list of the addresses of the whitelisted middleware with permission to slash the operator, i.e. which  
     * the operator is serving. Sorted by the block at which they were last updated (content of updates below) in ascending order.
     * This means the 'HEAD' (i.e. start) of the linked list will have the stalest 'updateBlock' value.
     */
    mapping(address => StructuredLinkedList.List) internal _operatorToWhitelistedContractsByUpdate;

    /**
     * operator => 
     *  [
     *      (
     *          the least recent update block of all of the middlewares it's serving/served, 
     *          latest time that the stake bonded at that update needed to serve until
     *      )
     *  ]
     */
    mapping(address => MiddlewareTimes[]) internal _operatorToMiddlewareTimes;

    /// @notice Emitted when a middleware times is added to `operator`'s array.
    event MiddlewareTimesAdded(address operator, uint256 index, uint32 stalestUpdateBlock, uint32 latestServeUntilBlock);

    /// @notice Emitted when `operator` begins to allow `contractAddress` to slash them.
    event OptedIntoSlashing(address indexed operator, address indexed contractAddress);

    /// @notice Emitted when `contractAddress` signals that it will no longer be able to slash `operator` after the `contractCanSlashOperatorUntilBlock`.
    event SlashingAbilityRevoked(address indexed operator, address indexed contractAddress, uint32 contractCanSlashOperatorUntilBlock);

    /**
     * @notice Emitted when `slashingContract` 'freezes' the `slashedOperator`.
     * @dev The `slashingContract` must have permission to slash the `slashedOperator`, i.e. `canSlash(slasherOperator, slashingContract)` must return 'true'.
     */
    event OperatorFrozen(address indexed slashedOperator, address indexed slashingContract);

    /// @notice Emitted when `previouslySlashedAddress` is 'unfrozen', allowing them to again move deposited funds within EigenLayer.
    event FrozenStatusReset(address indexed previouslySlashedAddress);

    constructor(IStrategyManager _strategyManager, IDelegationManager _delegation) {
        strategyManager = _strategyManager;
        delegation = _delegation;
        _disableInitializers();
    }

    /// @notice Ensures that the operator has opted into slashing by the caller, and that the caller has never revoked its slashing ability.
    modifier onlyRegisteredForService(address operator) {
        require(_whitelistedContractDetails[operator][msg.sender].contractCanSlashOperatorUntilBlock == MAX_CAN_SLASH_UNTIL,
            "Slasher.onlyRegisteredForService: Operator has not opted into slashing by caller");
        _;
    }

    // EXTERNAL FUNCTIONS
    function initialize(
        address initialOwner,
        IPauserRegistry _pauserRegistry,
        uint256 initialPausedStatus
    ) external initializer {
        _initializePauser(_pauserRegistry, initialPausedStatus);
        _transferOwnership(initialOwner);
    }

    /**
     * @notice Gives the `contractAddress` permission to slash the funds of the caller.
     * @dev Typically, this function must be called prior to registering for a middleware.
     */
    function optIntoSlashing(address contractAddress) external onlyWhenNotPaused(PAUSED_OPT_INTO_SLASHING) {
        require(delegation.isOperator(msg.sender), "Slasher.optIntoSlashing: msg.sender is not a registered operator");
        _optIntoSlashing(msg.sender, contractAddress);
    }

    /**
     * @notice Used for 'slashing' a certain operator.
     * @param toBeFrozen The operator to be frozen.
     * @dev Technically the operator is 'frozen' (hence the name of this function), and then subject to slashing pending a decision by a human-in-the-loop.
     * @dev The operator must have previously given the caller (which should be a contract) the ability to slash them, through a call to `optIntoSlashing`.
     */
    function freezeOperator(address toBeFrozen) external onlyWhenNotPaused(PAUSED_NEW_FREEZING) {
        require(
            canSlash(toBeFrozen, msg.sender),
            "Slasher.freezeOperator: msg.sender does not have permission to slash this operator"
        );
        _freezeOperator(toBeFrozen, msg.sender);
    }

    /**
     * @notice Removes the 'frozen' status from each of the `frozenAddresses`
     * @dev Callable only by the contract owner (i.e. governance).
     */
    function resetFrozenStatus(address[] calldata frozenAddresses) external onlyOwner {
        for (uint256 i = 0; i < frozenAddresses.length;) {
            _resetFrozenStatus(frozenAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice this function is a called by middlewares during an operator's registration to make sure the operator's stake at registration 
     *         is slashable until serveUntilBlock
     * @param operator the operator whose stake update is being recorded
     * @param serveUntilBlock the block until which the operator's stake at the current block is slashable
     * @dev adds the middleware's slashing contract to the operator's linked list
     */
    function recordFirstStakeUpdate(address operator, uint32 serveUntilBlock) 
        external 
        onlyWhenNotPaused(PAUSED_FIRST_STAKE_UPDATE)
        onlyRegisteredForService(operator)
    {
        // update the 'stalest' stakes update time + latest 'serveUntil' time of the `operator`
        _recordUpdateAndAddToMiddlewareTimes(operator, uint32(block.number), serveUntilBlock);

        // Push the middleware to the end of the update list. This will fail if the caller *is* already in the list.
        require(_operatorToWhitelistedContractsByUpdate[operator].pushBack(_addressToUint(msg.sender)), 
            "Slasher.recordFirstStakeUpdate: Appending middleware unsuccessful");
    }

    /**
     * @notice this function is a called by middlewares during a stake update for an operator (perhaps to free pending withdrawals)
     *         to make sure the operator's stake at updateBlock is slashable until serveUntilBlock
     * @param operator the operator whose stake update is being recorded
     * @param updateBlock the block for which the stake update is being recorded
     * @param serveUntilBlock the block until which the operator's stake at updateBlock is slashable
     * @param insertAfter the element of the operators linked list that the currently updating middleware should be inserted after
     * @dev insertAfter should be calculated offchain before making the transaction that calls this. this is subject to race conditions, 
     *      but it is anticipated to be rare and not detrimental.
     */
    function recordStakeUpdate(address operator, uint32 updateBlock, uint32 serveUntilBlock, uint256 insertAfter) 
        external 
        onlyRegisteredForService(operator) 
    {
        // sanity check on input
        require(updateBlock <= block.number, "Slasher.recordStakeUpdate: cannot provide update for future block");
        // update the 'stalest' stakes update time + latest 'serveUntilBlock' of the `operator`
        _recordUpdateAndAddToMiddlewareTimes(operator, updateBlock, serveUntilBlock);

        /**
         * Move the middleware to its correct update position, determined by `updateBlock` and indicated via `insertAfter`.
         * If the the middleware is the only one in the list, then no need to mutate the list
         */
        if (_operatorToWhitelistedContractsByUpdate[operator].sizeOf() != 1) {
            // Remove the caller (middleware) from the list. This will fail if the caller is *not* already in the list.
            require(_operatorToWhitelistedContractsByUpdate[operator].remove(_addressToUint(msg.sender)) != 0, 
                "Slasher.recordStakeUpdate: Removing middleware unsuccessful");
            // Run routine for updating the `operator`'s linked list of middlewares
            _updateMiddlewareList(operator, updateBlock, insertAfter);
        // if there is precisely one middleware in the list, then ensure that the caller is indeed the singular list entrant
        } else {
            require(_operatorToWhitelistedContractsByUpdate[operator].getHead() == _addressToUint(msg.sender),
                "Slasher.recordStakeUpdate: Caller is not the list entrant");
        }
    }

    /**
     * @notice this function is a called by middlewares during an operator's deregistration to make sure the operator's stake at deregistration 
     *         is slashable until serveUntilBlock
     * @param operator the operator whose stake update is being recorded
     * @param serveUntilBlock the block until which the operator's stake at the current block is slashable
     * @dev removes the middleware's slashing contract to the operator's linked list and revokes the middleware's (i.e. caller's) ability to
     * slash `operator` once `serveUntilBlock` is reached
     */
    function recordLastStakeUpdateAndRevokeSlashingAbility(address operator, uint32 serveUntilBlock) external onlyRegisteredForService(operator) {
        // update the 'stalest' stakes update time + latest 'serveUntilBlock' of the `operator`
        _recordUpdateAndAddToMiddlewareTimes(operator, uint32(block.number), serveUntilBlock);
        // remove the middleware from the list
        require(_operatorToWhitelistedContractsByUpdate[operator].remove(_addressToUint(msg.sender)) != 0,
             "Slasher.recordLastStakeUpdateAndRevokeSlashingAbility: Removing middleware unsuccessful");
        // revoke the middleware's ability to slash `operator` after `serverUntil`
        _revokeSlashingAbility(operator, msg.sender, serveUntilBlock);
    }

    // VIEW FUNCTIONS

    /// @notice Returns the block until which `serviceContract` is allowed to slash the `operator`.
    function contractCanSlashOperatorUntilBlock(address operator, address serviceContract) external view returns (uint32) {
        return _whitelistedContractDetails[operator][serviceContract].contractCanSlashOperatorUntilBlock;
    }

    /// @notice Returns the block at which the `serviceContract` last updated its view of the `operator`'s stake
    function latestUpdateBlock(address operator, address serviceContract) external view returns (uint32) {
        return _whitelistedContractDetails[operator][serviceContract].latestUpdateBlock;
    }

    /*
    * @notice Returns `_whitelistedContractDetails[operator][serviceContract]`.
    * @dev A getter function like this appears to be necessary for returning a struct from storage in struct form, rather than as a tuple.
    */
    function whitelistedContractDetails(address operator, address serviceContract) external view returns (MiddlewareDetails memory) {
        return _whitelistedContractDetails[operator][serviceContract];
    }


    /**
     * @notice Used to determine whether `staker` is actively 'frozen'. If a staker is frozen, then they are potentially subject to
     * slashing of their funds, and cannot cannot deposit or withdraw from the strategyManager until the slashing process is completed
     * and the staker's status is reset (to 'unfrozen').
     * @param staker The staker of interest.
     * @return Returns 'true' if `staker` themselves has their status set to frozen, OR if the staker is delegated
     * to an operator who has their status set to frozen. Otherwise returns 'false'.
     */
    function isFrozen(address staker) external view returns (bool) {
        if (frozenStatus[staker]) {
            return true;
        } else if (delegation.isDelegated(staker)) {
            address operatorAddress = delegation.delegatedTo(staker);
            return (frozenStatus[operatorAddress]);
        } else {
            return false;
        }
    }

    /// @notice Returns true if `slashingContract` is currently allowed to slash `toBeSlashed`.
    function canSlash(address toBeSlashed, address slashingContract) public view returns (bool) {
        if (block.number < _whitelistedContractDetails[toBeSlashed][slashingContract].contractCanSlashOperatorUntilBlock) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Returns 'true' if `operator` can currently complete a withdrawal started at the `withdrawalStartBlock`, with `middlewareTimesIndex` used
     * to specify the index of a `MiddlewareTimes` struct in the operator's list (i.e. an index in `_operatorToMiddlewareTimes[operator]`). The specified
     * struct is consulted as proof of the `operator`'s ability (or lack thereof) to complete the withdrawal.
     * This function will return 'false' if the operator cannot currently complete a withdrawal started at the `withdrawalStartBlock`, *or* in the event
     * that an incorrect `middlewareTimesIndex` is supplied, even if one or more correct inputs exist.
     * @param operator Either the operator who queued the withdrawal themselves, or if the withdrawing party is a staker who delegated to an operator,
     * this address is the operator *who the staker was delegated to* at the time of the `withdrawalStartBlock`.
     * @param withdrawalStartBlock The block number at which the withdrawal was initiated.
     * @param middlewareTimesIndex Indicates an index in `_operatorToMiddlewareTimes[operator]` to consult as proof of the `operator`'s ability to withdraw
     * @dev The correct `middlewareTimesIndex` input should be computable off-chain.
     */
    function canWithdraw(address operator, uint32 withdrawalStartBlock, uint256 middlewareTimesIndex) external view returns (bool) {
        // if the operator has never registered for a middleware, just return 'true'
        if (_operatorToMiddlewareTimes[operator].length == 0) {
            return true;
        }

        // pull the MiddlewareTimes struct at the `middlewareTimesIndex`th position in `_operatorToMiddlewareTimes[operator]`
        MiddlewareTimes memory update = _operatorToMiddlewareTimes[operator][middlewareTimesIndex];

        /**
         * Case-handling for if the operator is not registered for any middlewares (i.e. they previously registered but are no longer registered for any),
         * AND the withdrawal was initiated after the 'stalestUpdateBlock' of the MiddlewareTimes struct specified by the provided `middlewareTimesIndex`.
         * NOTE: we check the 2nd of these 2 conditions first for gas efficiency, to help avoid an extra SLOAD in all other cases.
         */
        if (withdrawalStartBlock >= update.stalestUpdateBlock && _operatorToWhitelistedContractsByUpdate[operator].size == 0) {
            /**
             * In this case, we just check against the 'latestServeUntilBlock' of the last MiddlewareTimes struct. This is because the operator not being registered
             * for any middlewares (i.e. `_operatorToWhitelistedContractsByUpdate.size == 0`) means no new MiddlewareTimes structs will be being pushed, *and* the operator 
             * will not be undertaking any new obligations (so just checking against the last entry is OK, unlike when the operator is actively registered for >=1 middleware).
             */
            update = _operatorToMiddlewareTimes[operator][_operatorToMiddlewareTimes[operator].length - 1];
            return (uint32(block.number) > update.latestServeUntilBlock);
        }
        
        /**
         * Make sure the stalest update block at the time of the update is strictly after `withdrawalStartBlock` and ensure that the current time
         * is after the `latestServeUntilBlock` of the update. This assures us that this that all middlewares were updated after the withdrawal began, and
         * that the stake is no longer slashable.
         */
        return(
            withdrawalStartBlock < update.stalestUpdateBlock 
            &&
            uint32(block.number) > update.latestServeUntilBlock
        );
    }

    /// @notice Getter function for fetching `_operatorToMiddlewareTimes[operator][arrayIndex]`.
    function operatorToMiddlewareTimes(address operator, uint256 arrayIndex) external view returns (MiddlewareTimes memory) {
        return _operatorToMiddlewareTimes[operator][arrayIndex];
    }

    /// @notice Getter function for fetching `_operatorToMiddlewareTimes[operator].length`.
    function middlewareTimesLength(address operator) external view returns (uint256) {
        return _operatorToMiddlewareTimes[operator].length;
    }

    /// @notice Getter function for fetching `_operatorToMiddlewareTimes[operator][index].stalestUpdateBlock`.
    function getMiddlewareTimesIndexStalestUpdateBlock(address operator, uint32 index) external view returns (uint32) {
        return _operatorToMiddlewareTimes[operator][index].stalestUpdateBlock;
    }

    /// @notice Getter function for fetching `_operatorToMiddlewareTimes[operator][index].latestServeUntilBlock`.
    function getMiddlewareTimesIndexServeUntilBlock(address operator, uint32 index) external view returns (uint32) {
        return _operatorToMiddlewareTimes[operator][index].latestServeUntilBlock;
    }

    /// @notice Getter function for fetching `_operatorToWhitelistedContractsByUpdate[operator].size`.
    function operatorWhitelistedContractsLinkedListSize(address operator) external view returns (uint256) {
        return _operatorToWhitelistedContractsByUpdate[operator].size;
    }

    /// @notice Getter function for fetching a single node in the operator's linked list (`_operatorToWhitelistedContractsByUpdate[operator]`).
    function operatorWhitelistedContractsLinkedListEntry(address operator, address node) external view returns (bool, uint256, uint256) {
        return StructuredLinkedList.getNode(_operatorToWhitelistedContractsByUpdate[operator], _addressToUint(node));
    }

    /**
     * @notice A search routine for finding the correct input value of `insertAfter` to `recordStakeUpdate` / `_updateMiddlewareList`.
     * @dev Used within this contract only as a fallback in the case when an incorrect value of `insertAfter` is supplied as an input to `_updateMiddlewareList`.
     * @dev The return value should *either* be 'HEAD' (i.e. zero) in the event that the node being inserted in the linked list has an `updateBlock`
     * that is less than the HEAD of the list, *or* the return value should specify the last `node` in the linked list for which
     * `_whitelistedContractDetails[operator][node].latestUpdateBlock <= updateBlock`,
     * i.e. the node such that the *next* node either doesn't exist,
     * OR
     * `_whitelistedContractDetails[operator][nextNode].latestUpdateBlock > updateBlock`.
     */
    function getCorrectValueForInsertAfter(address operator, uint32 updateBlock) public view returns (uint256) {
        uint256 node = _operatorToWhitelistedContractsByUpdate[operator].getHead();
        /**
         * Special case:
         * If the node being inserted in the linked list has an `updateBlock` that is less than the HEAD of the list, then we set `insertAfter = HEAD`.
         * In _updateMiddlewareList(), the new node will be pushed to the front (HEAD) of the list.
         */
        if (_whitelistedContractDetails[operator][_uintToAddress(node)].latestUpdateBlock > updateBlock) {
            return HEAD;
        }
        /**
         * `node` being zero (i.e. equal to 'HEAD') indicates an empty/non-existent node, i.e. reaching the end of the linked list.
         * Since the linked list is ordered in ascending order of update blocks, we simply start from the head of the list and step through until
         * we find a the *last* `node` for which `_whitelistedContractDetails[operator][node].latestUpdateBlock <= updateBlock`, or
         * otherwise reach the end of the list.
         */
        (, uint256 nextNode) = _operatorToWhitelistedContractsByUpdate[operator].getNextNode(node);
        while ((nextNode != HEAD) && (_whitelistedContractDetails[operator][_uintToAddress(node)].latestUpdateBlock <= updateBlock)) {
            node = nextNode;
            (, nextNode) = _operatorToWhitelistedContractsByUpdate[operator].getNextNode(node);
        }
        return node;
    }

    /// @notice gets the node previous to the given node in the operators middleware update linked list
    /// @dev used in offchain libs for updating stakes
    function getPreviousWhitelistedContractByUpdate(address operator, uint256 node) external view returns (bool, uint256) {
        return _operatorToWhitelistedContractsByUpdate[operator].getPreviousNode(node);
    }

    // INTERNAL FUNCTIONS

    function _optIntoSlashing(address operator, address contractAddress) internal {
        //allow the contract to slash anytime before a time VERY far in the future
        _whitelistedContractDetails[operator][contractAddress].contractCanSlashOperatorUntilBlock = MAX_CAN_SLASH_UNTIL;
        emit OptedIntoSlashing(operator, contractAddress);
    }

    function _revokeSlashingAbility(address operator, address contractAddress, uint32 serveUntilBlock) internal {
        require(serveUntilBlock != MAX_CAN_SLASH_UNTIL, "Slasher._revokeSlashingAbility: serveUntilBlock time must be limited");
        // contractAddress can now only slash operator before `serveUntilBlock`
        _whitelistedContractDetails[operator][contractAddress].contractCanSlashOperatorUntilBlock = serveUntilBlock;
        emit SlashingAbilityRevoked(operator, contractAddress, serveUntilBlock);
    }

    function _freezeOperator(address toBeFrozen, address slashingContract) internal {
        if (!frozenStatus[toBeFrozen]) {
            frozenStatus[toBeFrozen] = true;
            emit OperatorFrozen(toBeFrozen, slashingContract);
        }
    }

    function _resetFrozenStatus(address previouslySlashedAddress) internal {
        if (frozenStatus[previouslySlashedAddress]) {
            frozenStatus[previouslySlashedAddress] = false;
            emit FrozenStatusReset(previouslySlashedAddress);
        }
    }

    /**
     * @notice records the most recent updateBlock for the currently updating middleware and appends an entry to the operator's list of 
     *         MiddlewareTimes if relavent information has updated
     * @param operator the entity whose stake update is being recorded
     * @param updateBlock the block number for which the currently updating middleware is updating the serveUntilBlock for
     * @param serveUntilBlock the block until which the operator's stake at updateBlock is slashable
     * @dev this function is only called during externally called stake updates by middleware contracts that can slash operator
     */
    function _recordUpdateAndAddToMiddlewareTimes(address operator, uint32 updateBlock, uint32 serveUntilBlock) internal {
        // reject any stale update, i.e. one from before that of the most recent recorded update for the currently updating middleware
        require(_whitelistedContractDetails[operator][msg.sender].latestUpdateBlock <= updateBlock, 
                "Slasher._recordUpdateAndAddToMiddlewareTimes: can't push a previous update");
        _whitelistedContractDetails[operator][msg.sender].latestUpdateBlock = updateBlock;
        // get the latest recorded MiddlewareTimes, if the operator's list of MiddlwareTimes is non empty
        MiddlewareTimes memory curr;
        uint256 _operatorToMiddlewareTimesLength = _operatorToMiddlewareTimes[operator].length;
        if (_operatorToMiddlewareTimesLength != 0) {
            curr = _operatorToMiddlewareTimes[operator][_operatorToMiddlewareTimesLength - 1];
        }
        MiddlewareTimes memory next = curr;
        bool pushToMiddlewareTimes;
        // if the serve until is later than the latest recorded one, update it
        if (serveUntilBlock > curr.latestServeUntilBlock) {
            next.latestServeUntilBlock = serveUntilBlock;
            // mark that we need push next to middleware times array because it contains new information
            pushToMiddlewareTimes = true;
        } 
        
        // If this is the very first middleware added to the operator's list of middleware, then we add an entry to _operatorToMiddlewareTimes
        if (_operatorToWhitelistedContractsByUpdate[operator].size == 0) {
            next.stalestUpdateBlock = updateBlock;
            pushToMiddlewareTimes = true;
        }
        // If the middleware is the first in the list, we will update the `stalestUpdateBlock` field in MiddlewareTimes
        else if (_operatorToWhitelistedContractsByUpdate[operator].getHead() == _addressToUint(msg.sender)) {
            // if the updated middleware was the earliest update, set it to the 2nd earliest update's update time
            (bool hasNext, uint256 nextNode) = _operatorToWhitelistedContractsByUpdate[operator].getNextNode(_addressToUint(msg.sender));

            if (hasNext) {
                // get the next middleware's latest update block
                uint32 nextMiddlewaresLeastRecentUpdateBlock = _whitelistedContractDetails[operator][_uintToAddress(nextNode)].latestUpdateBlock;
                if (nextMiddlewaresLeastRecentUpdateBlock < updateBlock) {
                    // if there is a next node, then set the stalestUpdateBlock to its recorded value
                    next.stalestUpdateBlock = nextMiddlewaresLeastRecentUpdateBlock;
                } else {
                    //otherwise updateBlock is the least recent update as well
                    next.stalestUpdateBlock = updateBlock;
                }
            } else {
                // otherwise this is the only middleware so right now is the stalestUpdateBlock
                next.stalestUpdateBlock = updateBlock;
            }
            // mark that we need to push `next` to middleware times array because it contains new information
            pushToMiddlewareTimes = true;
        }
        
        // if `next` has new information, then push it
        if (pushToMiddlewareTimes) {
            _operatorToMiddlewareTimes[operator].push(next);
            emit MiddlewareTimesAdded(operator, _operatorToMiddlewareTimes[operator].length - 1, next.stalestUpdateBlock, next.latestServeUntilBlock);
        }
    }

    /// @notice A routine for updating the `operator`'s linked list of middlewares, inside `recordStakeUpdate`.
    function _updateMiddlewareList(address operator, uint32 updateBlock, uint256 insertAfter) internal {
        /**
         * boolean used to track if the `insertAfter input to this function is incorrect. If it is, then `runFallbackRoutine` will
         * be flipped to 'true', and we will use `getCorrectValueForInsertAfter` to find the correct input. This routine helps solve
         * a race condition where the proper value of `insertAfter` changes while a transaction is pending.
         */
       
        bool runFallbackRoutine = false;
        // If this condition is met, then the `updateBlock` input should be after `insertAfter`'s latest updateBlock
        if (insertAfter != HEAD) {
            // Check that `insertAfter` exists. If not, we will use the fallback routine to find the correct value for `insertAfter`.
            if (!_operatorToWhitelistedContractsByUpdate[operator].nodeExists(insertAfter)) {
                runFallbackRoutine = true;
            }

            /**
             * Make sure `insertAfter` specifies a node for which the most recent updateBlock was *at or before* updateBlock.
             * Again, if not,  we will use the fallback routine to find the correct value for `insertAfter`.
             */
            if ((!runFallbackRoutine) && (_whitelistedContractDetails[operator][_uintToAddress(insertAfter)].latestUpdateBlock > updateBlock)) {
                runFallbackRoutine = true;
            }

            // if we have not marked `runFallbackRoutine` as 'true' yet, then that means the `insertAfter` input was correct so far
            if (!runFallbackRoutine) {
                // Get `insertAfter`'s successor. `hasNext` will be false if `insertAfter` is the last node in the list
                (bool hasNext, uint256 nextNode) = _operatorToWhitelistedContractsByUpdate[operator].getNextNode(insertAfter);
                if (hasNext) {
                    /**
                     * Make sure the element after `insertAfter`'s most recent updateBlock was *strictly after* `updateBlock`.
                     * Again, if not,  we will use the fallback routine to find the correct value for `insertAfter`.
                     */
                    if (_whitelistedContractDetails[operator][_uintToAddress(nextNode)].latestUpdateBlock <= updateBlock) {
                        runFallbackRoutine = true;
                    }
                }
            }

            // if we have not marked `runFallbackRoutine` as 'true' yet, then that means the `insertAfter` input was correct on all counts
            if (!runFallbackRoutine) {
                /** 
                 * Insert the caller (middleware) after `insertAfter`.
                 * This will fail if `msg.sender` is already in the list, which they shouldn't be because they were removed from the list above.
                 */
                require(_operatorToWhitelistedContractsByUpdate[operator].insertAfter(insertAfter, _addressToUint(msg.sender)),
                    "Slasher.recordStakeUpdate: Inserting middleware unsuccessful");
            // in this case (runFallbackRoutine == true), we run a search routine to find the correct input value of `insertAfter` and then rerun this function
            } else {
                insertAfter = getCorrectValueForInsertAfter(operator, updateBlock);
                _updateMiddlewareList(operator, updateBlock, insertAfter);
            }
        // In this case (insertAfter == HEAD), the `updateBlock` input should be before every other middleware's latest updateBlock.
        } else {
            /**
             * Check that `updateBlock` is before any other middleware's latest updateBlock.
             * If not, use the fallback routine to find the correct value for `insertAfter`.
             */
            if (_whitelistedContractDetails[operator][
                _uintToAddress(_operatorToWhitelistedContractsByUpdate[operator].getHead()) ].latestUpdateBlock <= updateBlock)
            {
                runFallbackRoutine = true;
            }
            // if we have not marked `runFallbackRoutine` as 'true' yet, then that means the `insertAfter` input was correct on all counts
            if (!runFallbackRoutine) {
                /**
                 * Insert the middleware at the start (i.e. HEAD) of the list.
                 * This will fail if `msg.sender` is already in the list, which they shouldn't be because they were removed from the list above.
                 */
                require(_operatorToWhitelistedContractsByUpdate[operator].pushFront(_addressToUint(msg.sender)), 
                    "Slasher.recordStakeUpdate: Preppending middleware unsuccessful");
            // in this case (runFallbackRoutine == true), we run a search routine to find the correct input value of `insertAfter` and then rerun this function
            } else {
                insertAfter = getCorrectValueForInsertAfter(operator, updateBlock);
                _updateMiddlewareList(operator, updateBlock, insertAfter);
            }
        }
    }

    function _addressToUint(address addr) internal pure returns(uint256) {
        return uint256(uint160(addr));
    }

    function _uintToAddress(uint256 x) internal pure returns(address) {
        return address(uint160(x));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
