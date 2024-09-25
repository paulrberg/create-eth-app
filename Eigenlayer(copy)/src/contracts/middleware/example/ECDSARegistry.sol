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

import "../RegistryBase.sol";

/**
 * @title A Registry-type contract identifying operators by their Ethereum address, with only 1 quorum.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice This contract is used for
 * - registering new operators
 * - committing to and finalizing de-registration as an operator
 * - updating the stakes of the operator
 */
contract ECDSARegistry is RegistryBase {

    /// @notice the address that can whitelist people
    address public operatorWhitelister;
    /// @notice toggle of whether the operator whitelist is on or off 
    bool public operatorWhitelistEnabled;
    /// @notice operator => are they whitelisted (can they register with the middleware)
    mapping(address => bool) public whitelisted;

    // EVENTS
    /**
     * @notice Emitted upon the registration of a new operator for the middleware
     * @param operator Address of the new operator
     * @param socket The ip:port of the operator
     */
    event Registration(
        address indexed operator,
        string socket
    );

    /// @notice Emitted when the `operatorWhitelister` role is transferred.
    event OperatorWhitelisterTransferred(address previousAddress, address newAddress);

    /// @notice Modifier that restricts a function to only be callable by the `whitelister` role.
    modifier onlyOperatorWhitelister {
        require(operatorWhitelister == msg.sender, "BLSRegistry.onlyOperatorWhitelister: not operatorWhitelister");
        _;
    }

    constructor(
        IStrategyManager _strategyManager,
        IServiceManager _serviceManager
    )
        RegistryBase(
            _strategyManager,
            _serviceManager,
            1 // set the number of quorums to 1
        )
    {}

    /// @notice Initialize whitelister and the quorum strategies + multipliers.
    function initialize(
        address _operatorWhitelister,
        bool _operatorWhitelistEnabled,
        uint256[] memory _quorumBips,
        StrategyAndWeightingMultiplier[] memory _quorumStrategiesConsideredAndMultipliers
    ) public virtual initializer {
        _setOperatorWhitelister(_operatorWhitelister);
        operatorWhitelistEnabled = _operatorWhitelistEnabled;

        RegistryBase._initialize(
            _quorumBips,
            _quorumStrategiesConsideredAndMultipliers,
            new StrategyAndWeightingMultiplier[](0)
        );
    }

    /**
     * @notice Called by the service manager owner to transfer the whitelister role to another address 
     */
    function setOperatorWhitelister(address _operatorWhitelister) external onlyServiceManagerOwner {
        _setOperatorWhitelister(_operatorWhitelister);
    }

    /**
     * @notice Callable only by the service manager owner, this function toggles the whitelist on or off
     * @param _operatorWhitelistEnabled true if turning whitelist on, false otherwise
     */
    function setOperatorWhitelistStatus(bool _operatorWhitelistEnabled) external onlyServiceManagerOwner {
        operatorWhitelistEnabled = _operatorWhitelistEnabled;
    }

    /**
     * @notice Called by the operatorWhitelister, adds a list of operators to the whitelist
     * @param operators the operators to add to the whitelist
     */
    function addToOperatorWhitelist(address[] calldata operators) external onlyOperatorWhitelister {
        for (uint i = 0; i < operators.length; i++) {
            whitelisted[operators[i]] = true;
        }
    }

    /**
     * @notice Called by the operatorWhitelister, removes a list of operators to the whitelist
     * @param operators the operators to remove from the whitelist
     */
    function removeFromWhitelist(address[] calldata operators) external onlyOperatorWhitelister {
        for (uint i = 0; i < operators.length; i++) {
            whitelisted[operators[i]] = false;
        }
    }
    /**
     * @notice called for registering as an operator
     * @param socket is the socket address of the operator
     */
    function registerOperator(string calldata socket) external virtual {
        _registerOperator(msg.sender, socket);
    }

    /**
     * @param operator is the node who is registering to be a operator
     * @param socket is the socket address of the operator
     */
    function _registerOperator(address operator, string calldata socket)
        internal
    {
        if(operatorWhitelistEnabled) {
            require(whitelisted[operator], "BLSRegistry._registerOperator: not whitelisted");
        }

        // validate the registration of `operator` and find their `OperatorStake`
        OperatorStake memory _operatorStake = _registrationStakeEvaluation(operator, 1);

        // add the operator to the list of registrants and do accounting
        _addRegistrant(operator, bytes32(uint256(uint160(operator))), _operatorStake);

        emit Registration(operator, socket);
    }

    /**
     * @notice Used by an operator to de-register itself from providing service to the middleware.
     * @param index is the sender's location in the dynamic array `operatorList`
     */
    function deregisterOperator(uint32 index) external virtual returns (bool) {
        _deregisterOperator(msg.sender, index);
        return true;
    }

    /**
     * @notice Used to process de-registering an operator from providing service to the middleware.
     * @param operator The operator to be deregistered
     * @param index is the sender's location in the dynamic array `operatorList`
     */
    function _deregisterOperator(address operator, uint32 index) internal {
        // verify that the `operator` is an active operator and that they've provided the correct `index`
        _deregistrationCheck(operator, index);

        // Perform necessary updates for removing operator, including updating operator list and index histories
        _removeOperator(operator, bytes32(uint256(uint160(operator))), index);
    }

    /**
     * @notice Used for updating information on deposits of nodes.
     * @param operators are the nodes whose deposit information is getting updated
     * @param prevElements are the elements before this middleware in the operator's linked list within the slasher
     */
    function updateStakes(address[] calldata operators, uint256[] calldata prevElements) external {
        // copy total stake to memory
        OperatorStake memory _totalStake = totalStakeHistory[totalStakeHistory.length - 1];

        // placeholders reused inside of loop
        OperatorStake memory currentStakes;
        bytes32 pubkeyHash;
        uint256 operatorsLength = operators.length;
        // make sure lengths are consistent
        require(operatorsLength == prevElements.length, "BLSRegistry.updateStakes: prevElement is not the same length as operators");
        // iterating over all the tuples that are to be updated
        for (uint256 i = 0; i < operatorsLength;) {
            // get operator's pubkeyHash
            pubkeyHash = bytes32(uint256(uint160(operators[i])));
            // fetch operator's existing stakes
            currentStakes = pubkeyHashToStakeHistory[pubkeyHash][pubkeyHashToStakeHistory[pubkeyHash].length - 1];

            // Note: we only edit the first quorum stake because this is a single quorum registry example
            // decrease _totalStake by operator's existing stakes
            _totalStake.firstQuorumStake -= currentStakes.firstQuorumStake;

            // update the stake for the i-th operator
            currentStakes = _updateOperatorStake(operators[i], pubkeyHash, currentStakes, prevElements[i]);

            // increase _totalStake by operator's updated stakes
            _totalStake.firstQuorumStake += currentStakes.firstQuorumStake;

            unchecked {
                ++i;
            }
        }

        // update storage of total stake
        _recordTotalStakeUpdate(_totalStake);
    }

    function _setOperatorWhitelister(address _operatorWhitelister) internal {
        require(_operatorWhitelister != address(0), "BLSRegistry.initialize: cannot set operatorWhitelister to zero address");
        emit OperatorWhitelisterTransferred(operatorWhitelister, _operatorWhitelister);
        operatorWhitelister = _operatorWhitelister;
    }
}
