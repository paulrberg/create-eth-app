/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { AccessControlEnumerable } from "SuperFluid/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { SafeERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ISuperToken,
    IERC20
} from "../interfaces/superfluid/ISuperfluid.sol";

/**
 * @title Super upgrader contract
 * @author Superfluid
 * NOTE:
 * - User would need to first SuperToken.approve the `SuperUpgrader` for the job.
 * - Using access control to allow multiple backend agent to upgrade tokens for the users
 * - Risk taken by the user is that the underlying tokens are converted to the Super Tokens by the upgrader agents.
 */
contract SuperUpgrader is AccessControlEnumerable {

    using SafeERC20 for IERC20;
    // Create a new role identifier for the backend role
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");

    event OptoutAutoUpgrade(address indexed account);
    event OptinAutoUpgrade(address indexed account);

    mapping(address => bool) internal _optout;

    constructor(address adminRole, address[] memory backendAddr) {
        require(adminRole != address(0), "adminRole is empty");
        _setupRole(DEFAULT_ADMIN_ROLE, adminRole);
        for (uint256 i = 0; i < backendAddr.length; ++i) {
            require(backendAddr[i] != address(0), "backend can't be zero");
            _setupRole(BACKEND_ROLE, backendAddr[i]);
        }
    }

    /**
     * @notice The user should ERC20.approve this contract.
     * @dev Execute upgrade function in the name of the user
     * @param superTokenAddr Super Token Address to upgrade
     * @param account User address that previous approved this contract.
     * @param amount Amount value to be upgraded.
     */
    function upgrade(
        address superTokenAddr,
        address account,
        uint256 amount
    )
    external
    {
        require(msg.sender == account ||
            (hasRole(BACKEND_ROLE, msg.sender) &&
            !_optout[account])
        , "operation not allowed");
        // get underlying token
        ISuperToken superToken = ISuperToken(superTokenAddr);
        // get tokens from user
        IERC20 token = IERC20(superToken.getUnderlyingToken());
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(account, address(this), amount);
        token.safeApprove(address(superToken), 0);
        token.safeApprove(address(superToken), amount);
        // upgrade tokens and send back to user
        superToken.upgradeTo(
            account,
            token.balanceOf(address(this)) - beforeBalance, new bytes(0));
    }

    /**
     * @dev Test if account is member BACKEND_ROLE
     */
    function isBackendAgent(address account) external view returns(bool yes) {
        return hasRole(BACKEND_ROLE, account);
    }

    /**
     * @dev Add account to BACKEND_ROLE
     */
    function grantBackendAgent(address account) external {
        require(account != address(0), "operation not allowed");
        // grantRole will check if sender is adminRole member
        grantRole(BACKEND_ROLE, account);
    }

    /**
     * @dev Remove account to BACKEND_ROLE
     */
    function revokeBackendAgent(address account) external {
        // grantRole will check if sender is adminRole member
        revokeRole(BACKEND_ROLE, account);
    }

    /**
     * @dev Get list of all members of BACKEND_ROLE
     */
    function getBackendAgents() external view returns(address[] memory) {
        uint256 numberOfMembers = getRoleMemberCount(BACKEND_ROLE);
        address[] memory members = new address[](numberOfMembers);
        for (uint256 i = 0; i < numberOfMembers; ++i) {
            members[i] = getRoleMember(BACKEND_ROLE, i);
        }
        return members;
    }

    /**
     * @dev User signal that opt-out from backend upgrades
     */
    function optoutAutoUpgrades() external {
        _optout[msg.sender] = true;
        emit OptoutAutoUpgrade(msg.sender);
    }

    /**
     * @dev User signal that revoke opt-out from backend upgrades
     */
    function optinAutoUpgrades() external {
        delete _optout[msg.sender];
        emit OptinAutoUpgrade(msg.sender);
    }
}
