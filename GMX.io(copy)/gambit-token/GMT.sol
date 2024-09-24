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

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IGMT.sol";
import "../peripherals/interfaces/ITimelockTarget.sol";

contract GMT is IERC20, IGMT, ITimelockTarget {
    using SafeMath for uint256;

    string public constant name = "Gambit";
    string public constant symbol = "GMT";
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    address public gov;

    bool public hasActiveMigration;
    uint256 public migrationTime;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    mapping (address => bool) public admins;

    // only checked when hasActiveMigration is true
    // this can be used to block the AMM pair as a recipient
    // and protect liquidity providers during a migration
    // by disabling the selling of GMT
    mapping (address => bool) public blockedRecipients;

    // only checked when hasActiveMigration is true
    // this can be used for:
    // - only allowing tokens to be transferred by the distribution contract
    // during the initial distribution phase, this would prevent token buyers
    // from adding liquidity before the initial liquidity is seeded
    // - only allowing removal of GMT liquidity and no other actions
    // during the migration phase
    mapping (address => bool) public allowedMsgSenders;

    modifier onlyGov() {
        require(msg.sender == gov, "GMT: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "GMT: forbidden");
        _;
    }

    constructor(uint256 _initialSupply) public {
        gov = msg.sender;
        admins[msg.sender] = true;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external override onlyGov {
        gov = _gov;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external onlyGov {
        admins[_account] = false;
    }

    function setNextMigrationTime(uint256 _migrationTime) external onlyGov {
        require(_migrationTime > migrationTime, "GMT: invalid _migrationTime");
        migrationTime = _migrationTime;
    }

    function beginMigration() external override onlyAdmin {
        require(block.timestamp > migrationTime, "GMT: migrationTime not yet passed");
        hasActiveMigration = true;
    }

    function endMigration() external override onlyAdmin {
        hasActiveMigration = false;
    }

    function addBlockedRecipient(address _recipient) external onlyGov {
        blockedRecipients[_recipient] = true;
    }

    function removeBlockedRecipient(address _recipient) external onlyGov {
        blockedRecipients[_recipient] = false;
    }

    function addMsgSender(address _msgSender) external onlyGov {
        allowedMsgSenders[_msgSender] = true;
    }

    function removeMsgSender(address _msgSender) external onlyGov {
        allowedMsgSenders[_msgSender] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external override onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "GMT: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "GMT: transfer from the zero address");
        require(_recipient != address(0), "GMT: transfer to the zero address");

        if (hasActiveMigration) {
            require(allowedMsgSenders[msg.sender], "GMT: forbidden msg.sender");
            require(!blockedRecipients[_recipient], "GMT: forbidden recipient");
        }

        balances[_sender] = balances[_sender].sub(_amount, "GMT: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient,_amount);
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "GMT: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "GMT: approve from the zero address");
        require(_spender != address(0), "GMT: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }
}
