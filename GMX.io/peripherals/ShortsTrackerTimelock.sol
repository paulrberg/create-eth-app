/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/GMX.io?utm=code
  */
  
  // SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";
import "../access/Governable.sol";
import "../core/interfaces/IShortsTracker.sol";
import "./interfaces/IHandlerTarget.sol";

pragma solidity 0.6.12;

contract ShortsTrackerTimelock {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_BUFFER = 5 days;

    mapping (bytes32 => uint256) public pendingActions;

    address public admin;
    uint256 public buffer;

    mapping (address => bool) public isHandler;
    mapping (address => uint256) public lastUpdated;
    uint256 public averagePriceUpdateDelay;
    uint256 public maxAveragePriceChange;

    event GlobalShortAveragePriceUpdated(address indexed token, uint256 oldAveragePrice, uint256 newAveragePrice);

    event SignalSetGov(address target, address gov);
    event SetGov(address target, address gov);

    event SignalSetAdmin(address admin);
    event SetAdmin(address admin);

    event SetContractHandler(address indexed handler, bool isHandler);
    event SignalSetHandler(address target, address handler, bool isActive, bytes32 action);

    event SignalSetMaxAveragePriceChange(uint256 maxAveragePriceChange);
    event SetMaxAveragePriceChange(uint256 maxAveragePriceChange);

    event SignalSetAveragePriceUpdateDelay(uint256 averagePriceUpdateDelay);
    event SetAveragePriceUpdateDelay(uint256 averagePriceUpdateDelay);

    event SignalSetIsGlobalShortDataReady(address target, bool isGlobalShortDataReady);
    event SetIsGlobalShortDataReady(address target, bool isGlobalShortDataReady);

    event SignalPendingAction(bytes32 action);
    event ClearAction(bytes32 action);

    constructor(
        address _admin,
        uint256 _buffer,
        uint256 _averagePriceUpdateDelay,
        uint256 _maxAveragePriceChange
    ) public {
        admin = _admin;
        buffer = _buffer;
        averagePriceUpdateDelay = _averagePriceUpdateDelay;
        maxAveragePriceChange = _maxAveragePriceChange;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "ShortsTrackerTimelock: admin forbidden");
        _;
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender] || msg.sender == admin, "ShortsTrackerTimelock: handler forbidden");
        _;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "ShortsTrackerTimelock: invalid buffer");
        require(_buffer > buffer, "ShortsTrackerTimelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function signalSetAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "ShortsTrackerTimelock: invalid admin");

        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _setPendingAction(action);

        emit SignalSetAdmin(_admin);
    }

    function setAdmin(address _admin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _validateAction(action);
        _clearAction(action);

        admin = _admin;

        emit SetAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;

        emit SetContractHandler(_handler, _isActive);
    }

    function signalSetGov(address _shortsTracker, address _gov) external onlyAdmin {
        require(_gov != address(0), "ShortsTrackerTimelock: invalid gov");

        bytes32 action = keccak256(abi.encodePacked("setGov", _shortsTracker, _gov));
        _setPendingAction(action);

        emit SignalSetGov(_shortsTracker, _gov);
    }

    function setGov(address _shortsTracker, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _shortsTracker, _gov));
        _validateAction(action);
        _clearAction(action);

        Governable(_shortsTracker).setGov(_gov);

        emit SetGov(_shortsTracker, _gov);
    }

    function signalSetHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _setPendingAction(action);
        emit SignalSetHandler(_target, _handler, _isActive, action);
    }

    function setHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _validateAction(action);
        _clearAction(action);
        IHandlerTarget(_target).setHandler(_handler, _isActive);
    }

    function signalSetAveragePriceUpdateDelay(uint256 _averagePriceUpdateDelay) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAveragePriceUpdateDelay", _averagePriceUpdateDelay));
        _setPendingAction(action);

        emit SignalSetAveragePriceUpdateDelay(_averagePriceUpdateDelay);
    }

    function setAveragePriceUpdateDelay(uint256 _averagePriceUpdateDelay) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAveragePriceUpdateDelay", _averagePriceUpdateDelay));
        _validateAction(action);
        _clearAction(action);

        averagePriceUpdateDelay = _averagePriceUpdateDelay;

        emit SetAveragePriceUpdateDelay(_averagePriceUpdateDelay);
    }

    function signalSetMaxAveragePriceChange(uint256 _maxAveragePriceChange) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setMaxAveragePriceChange", _maxAveragePriceChange));
        _setPendingAction(action);

        emit SignalSetMaxAveragePriceChange(_maxAveragePriceChange);
    }

    function setMaxAveragePriceChange(uint256 _maxAveragePriceChange) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setMaxAveragePriceChange", _maxAveragePriceChange));
        _validateAction(action);
        _clearAction(action);

        maxAveragePriceChange = _maxAveragePriceChange;

        emit SetMaxAveragePriceChange(_maxAveragePriceChange);
    }

    function signalSetIsGlobalShortDataReady(IShortsTracker _shortsTracker, bool _value) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setIsGlobalShortDataReady", address(_shortsTracker), _value));
        _setPendingAction(action);

        emit SignalSetIsGlobalShortDataReady(address(_shortsTracker), _value);
    }

    function setIsGlobalShortDataReady(IShortsTracker _shortsTracker, bool _value) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setIsGlobalShortDataReady", address(_shortsTracker), _value));
        _validateAction(action);
        _clearAction(action);

        _shortsTracker.setIsGlobalShortDataReady(_value);

        emit SetIsGlobalShortDataReady(address(_shortsTracker), _value);
    }

    function disableIsGlobalShortDataReady(IShortsTracker _shortsTracker) external onlyAdmin {
        _shortsTracker.setIsGlobalShortDataReady(false);

        emit SetIsGlobalShortDataReady(address(_shortsTracker), false);
    }

    function setGlobalShortAveragePrices(IShortsTracker _shortsTracker, address[] calldata _tokens, uint256[] calldata _averagePrices) external onlyHandler {
        _shortsTracker.setIsGlobalShortDataReady(false);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 oldAveragePrice = _shortsTracker.globalShortAveragePrices(token);
            uint256 newAveragePrice = _averagePrices[i];
            uint256 diff = newAveragePrice > oldAveragePrice ? newAveragePrice.sub(oldAveragePrice) : oldAveragePrice.sub(newAveragePrice);
            require(diff.mul(BASIS_POINTS_DIVISOR).div(oldAveragePrice) < maxAveragePriceChange, "ShortsTrackerTimelock: too big change");

            require(block.timestamp >= lastUpdated[token].add(averagePriceUpdateDelay), "ShortsTrackerTimelock: too early");
            lastUpdated[token] = block.timestamp;

            emit GlobalShortAveragePriceUpdated(token, oldAveragePrice, newAveragePrice);
        }

        _shortsTracker.setInitData(_tokens, _averagePrices);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _setPendingAction(bytes32 _action) private {
        require(pendingActions[_action] == 0, "ShortsTrackerTimelock: action already signalled");
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "ShortsTrackerTimelock: action not signalled");
        require(pendingActions[_action] <= block.timestamp, "ShortsTrackerTimelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "ShortsTrackerTimelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}
