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
  
  //SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IGmxIou.sol";
import "./interfaces/IAmmRouter.sol";
import "./interfaces/IGmxMigrator.sol";

contract GmxMigrator is ReentrancyGuard, IGmxMigrator {
    using SafeMath for uint256;

    bool public isInitialized;
    bool public isMigrationActive = true;
    bool public hasMaxMigrationLimit = false;

    uint256 public minAuthorizations;

    address public ammRouter;
    uint256 public gmxPrice;

    uint256 public actionsNonce;
    address public admin;

    address[] public signers;
    mapping (address => bool) public isSigner;
    mapping (bytes32 => bool) public pendingActions;
    mapping (address => mapping (bytes32 => bool)) public signedActions;

    mapping (address => bool) public whitelistedTokens;
    mapping (address => address) public override iouTokens;
    mapping (address => uint256) public prices;
    mapping (address => uint256) public caps;

    mapping (address => bool) public lpTokens;
    mapping (address => address) public lpTokenAs;
    mapping (address => address) public lpTokenBs;

    mapping (address => uint256) public tokenAmounts;

    mapping (address => mapping (address => uint256)) public migratedAmounts;
    mapping (address => mapping (address => uint256)) public maxMigrationAmounts;

    event SignalApprove(address token, address spender, uint256 amount, bytes32 action, uint256 nonce);

    event SignalPendingAction(bytes32 action, uint256 nonce);
    event SignAction(bytes32 action, uint256 nonce);
    event ClearAction(bytes32 action, uint256 nonce);

    constructor(uint256 _minAuthorizations) public {
        admin = msg.sender;
        minAuthorizations = _minAuthorizations;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "GmxMigrator: forbidden");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "GmxMigrator: forbidden");
        _;
    }

    function initialize(
        address _ammRouter,
        uint256 _gmxPrice,
        address[] memory _signers,
        address[] memory _whitelistedTokens,
        address[] memory _iouTokens,
        uint256[] memory _prices,
        uint256[] memory _caps,
        address[] memory _lpTokens,
        address[] memory _lpTokenAs,
        address[] memory _lpTokenBs
    ) public onlyAdmin {
        require(!isInitialized, "GmxMigrator: already initialized");
        require(_whitelistedTokens.length == _iouTokens.length, "GmxMigrator: invalid _iouTokens.length");
        require(_whitelistedTokens.length == _prices.length, "GmxMigrator: invalid _prices.length");
        require(_whitelistedTokens.length == _caps.length, "GmxMigrator: invalid _caps.length");
        require(_lpTokens.length == _lpTokenAs.length, "GmxMigrator: invalid _lpTokenAs.length");
        require(_lpTokens.length == _lpTokenBs.length, "GmxMigrator: invalid _lpTokenBs.length");

        isInitialized = true;

        ammRouter = _ammRouter;
        gmxPrice = _gmxPrice;

        signers = _signers;
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            isSigner[signer] = true;
        }

        for (uint256 i = 0; i < _whitelistedTokens.length; i++) {
            address token = _whitelistedTokens[i];
            whitelistedTokens[token] = true;
            iouTokens[token] = _iouTokens[i];
            prices[token] = _prices[i];
            caps[token] = _caps[i];
        }

        for (uint256 i = 0; i < _lpTokens.length; i++) {
            address token = _lpTokens[i];
            lpTokens[token] = true;
            lpTokenAs[token] = _lpTokenAs[i];
            lpTokenBs[token] = _lpTokenBs[i];
        }
    }

    function endMigration() public onlyAdmin {
        isMigrationActive = false;
    }

    function setHasMaxMigrationLimit(bool _hasMaxMigrationLimit) public onlyAdmin {
        hasMaxMigrationLimit = _hasMaxMigrationLimit;
    }

    function setMaxMigrationAmount(address _account, address _token, uint256 _maxMigrationAmount) public onlyAdmin {
        maxMigrationAmounts[_account][_token] = _maxMigrationAmount;
    }

    function migrate(
        address _token,
        uint256 _tokenAmount
    ) public nonReentrant {
        require(isMigrationActive, "GmxMigrator: migration is no longer active");
        require(whitelistedTokens[_token], "GmxMigrator: token not whitelisted");
        require(_tokenAmount > 0, "GmxMigrator: invalid tokenAmount");

        if (hasMaxMigrationLimit) {
            migratedAmounts[msg.sender][_token] = migratedAmounts[msg.sender][_token].add(_tokenAmount);
            require(migratedAmounts[msg.sender][_token] <= maxMigrationAmounts[msg.sender][_token], "GmxMigrator: maxMigrationAmount exceeded");
        }

        uint256 tokenPrice = getTokenPrice(_token);
        uint256 mintAmount = _tokenAmount.mul(tokenPrice).div(gmxPrice);
        require(mintAmount > 0, "GmxMigrator: invalid mintAmount");

        tokenAmounts[_token] = tokenAmounts[_token].add(_tokenAmount);
        require(tokenAmounts[_token] < caps[_token], "GmxMigrator: token cap exceeded");

        IERC20(_token).transferFrom(msg.sender, address(this), _tokenAmount);

        if (lpTokens[_token]) {
            address tokenA = lpTokenAs[_token];
            address tokenB = lpTokenBs[_token];
            require(tokenA != address(0), "GmxMigrator: invalid tokenA");
            require(tokenB != address(0), "GmxMigrator: invalid tokenB");

            IERC20(_token).approve(ammRouter, _tokenAmount);
            IAmmRouter(ammRouter).removeLiquidity(tokenA, tokenB, _tokenAmount, 0, 0, address(this), block.timestamp);
        }

        address iouToken = getIouToken(_token);
        IGmxIou(iouToken).mint(msg.sender, mintAmount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, nonce));
        _setPendingAction(action, nonce);
        emit SignalApprove(_token, _spender, _amount, action, nonce);
    }

    function signApprove(address _token, address _spender, uint256 _amount, uint256 _nonce) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "GmxMigrator: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approve(address _token, address _spender, uint256 _amount, uint256 _nonce) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        IERC20(_token).approve(_spender, _amount);
        _clearAction(action, _nonce);
    }

    function getTokenAmounts(address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            amounts[i] = tokenAmounts[token];
        }

        return amounts;
    }

    function getTokenPrice(address _token) public view returns (uint256) {
        uint256 price = prices[_token];
        require(price != 0, "GmxMigrator: invalid token price");
        return price;
    }

    function getIouToken(address _token) public view returns (address) {
        address iouToken = iouTokens[_token];
        require(iouToken != address(0), "GmxMigrator: invalid iou token");
        return iouToken;
    }

    function _setPendingAction(bytes32 _action, uint256 _nonce) private {
        pendingActions[_action] = true;
        emit SignalPendingAction(_action, _nonce);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action], "GmxMigrator: action not signalled");
    }

    function _validateAuthorization(bytes32 _action) private view {
        uint256 count = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];
            if (signedActions[signer][_action]) {
                count++;
            }
        }

        if (count == 0) {
            revert("GmxMigrator: action not authorized");
        }
        require(count >= minAuthorizations, "GmxMigrator: insufficient authorization");
    }

    function _clearAction(bytes32 _action, uint256 _nonce) private {
        require(pendingActions[_action], "GmxMigrator: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action, _nonce);
    }
}
