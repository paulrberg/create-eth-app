/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Olympus-DAO?utm=code
  */
  
  // SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.10;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "../types/OlympusAccessControlled.sol";

interface ITokemakManager {
    function currentCycleIndex() external view returns (uint256);
}

interface ITokemaktALCX {
    function deposit(uint256 amount) external;

    function requestedWithdrawals(address addr) external view returns (uint256, uint256);

    function withdraw(uint256 requestedAmount) external;

    function requestWithdrawal(uint256 amount) external;
}

interface IStakingPools {
    function claim(uint256 _poolId) external;

    function exit(uint256 _poolId) external;

    function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256);

    function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256);

    function deposit(uint256 _poolId, uint256 _depositAmount) external;

    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
}

/**
 *  Contract deploys Alchemix from treasury into the Tokemak tALCX pool,
 *  tALCX contract gives tALCX token in ratio 1:1 of Alchemix token deposited,
 *  Contract stake tALCX token on Alchemix staking pool and earn ALCX as reward,
 *  Contract claims reward and compound it,
 *  Contract withdraw funds from Alchemix staking pool and Tokemak tALCX pool,
 *  Sends back Alchemix token with accured reward to treasury.
 */

contract AlchemixAllocator is OlympusAccessControlled {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== STATE VARIABLES ======== */

    address public immutable alchemix;
    address public immutable tokemakManager = 0xA86e412109f77c45a3BC1c5870b880492Fb86A14;

    ITokemaktALCX public immutable tALCX; // Tokemak tALCX deposit contract
    IStakingPools public immutable pool; // Alchemix staking contract
    ITreasury public treasury; // Olympus Treasury

    uint256 public totalAlchemixDeposited;

    /* ======== CONSTRUCTOR ======== */

    constructor(
        address _treasury,
        address _alchemix,
        address _tALCX,
        address _pool,
        address _olympusAuthority
    ) OlympusAccessControlled(IOlympusAuthority(_olympusAuthority)) {
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);

        require(_tALCX != address(0));
        tALCX = ITokemaktALCX(_tALCX);

        require(_pool != address(0));
        pool = IStakingPools(_pool);

        alchemix = _alchemix;
    }

    /* ======== GUARDIAN FUNCTIONS ======== */

    /**
     *  @notice compound reward by claiming pending rewards and
     *      calling the deposit function
     *  @param _poolId pool id of tALCX on Alchemix staking pool
     */
    function compoundReward(uint256 _poolId) external onlyGuardian {
        pool.claim(_poolId);
        uint256 alchemixBalance = IERC20(alchemix).balanceOf(address(this));

        require(alchemixBalance > 0, "contract has no alchemix token");
        deposit(alchemixBalance, _poolId, true);
    }

    /**
     *  @notice withdraws asset from treasury, deposits asset into Tokemak tALCX,
     *      then deposits tALCX into Alchemix staking pool
     *  @param _amount amount to deposit
     *  @param _poolId pool id of tALCX on Alchemix staking pool
     *  @param _isCompounding used to indicate if the contract is compounding pending rewards
     */
    function deposit(
        uint256 _amount,
        uint256 _poolId,
        bool _isCompounding
    ) public onlyGuardian {
        if (!_isCompounding) {
            treasury.manage(alchemix, _amount); // retrieve amount of asset from treasury
        }

        IERC20(alchemix).approve(address(tALCX), _amount); // approve tALCX pool to spend tokens
        tALCX.deposit(_amount);

        totalAlchemixDeposited = totalAlchemixDeposited + _amount;
        uint256 tALCX_balance = IERC20(address(tALCX)).balanceOf(address(this));

        IERC20(address(tALCX)).approve(address(pool), tALCX_balance); // approve to deposit to Alchemix staking pool
        pool.deposit(_poolId, tALCX_balance); // deposit into Alchemix staking pool
    }

    /**
     *  @notice as structured by Tokemak before one withdraws you must first request withdrawal,
            unstake tALCX from Alchemix staking pool and make a request on Tokemak tALCX pool.
     *  @param _poolId pool id of tALCX on Alchemix staking pool
     *  @param _amount amount to withdraw if _isEntireFunds is false
     *  @param _isEntireFunds used to indicate if amount to with is the entire funds deposited
     */
    function requestWithdraw(
        uint256 _poolId,
        uint256 _amount,
        bool _isEntireFunds
    ) external onlyGuardian {
        if (_isEntireFunds) {
            pool.exit(_poolId);
        } else {
            pool.withdraw(_poolId, _amount);
        }

        uint256 balance = IERC20(address(tALCX)).balanceOf(address(this));
        tALCX.requestWithdrawal(balance);
    }

    /**
     *  @notice withdraws ALCX from Tokemak tALCX pool then deposits asset into treasury,
            ensures cycle for withdraw has been reached.
     */
    function withdraw() external onlyGuardian {
        (uint256 minCycle, ) = tALCX.requestedWithdrawals(address(this));
        uint256 currentCycle = ITokemakManager(tokemakManager).currentCycleIndex();

        require(minCycle <= currentCycle, "requested withdraw cycle not reached yet");

        (, uint256 requestedAmountToWithdraw) = getRequestedWithdrawalInfo();
        tALCX.withdraw(requestedAmountToWithdraw);
        uint256 balance = IERC20(alchemix).balanceOf(address(this)); // balance of asset withdrawn

        totalAlchemixDeposited = totalAlchemixDeposited - requestedAmountToWithdraw;
        IERC20(alchemix).safeTransfer(address(treasury), balance);
    }

    function updateTreasury() external onlyGuardian {
        require(authority.vault() != address(0), "Zero address: Vault");
        require(address(authority.vault()) != address(treasury), "No change");
        treasury = ITreasury(authority.vault());
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice query all pending rewards
     *  @param _poolId pool id of tALCX on Alchemix staking pool
     *  @return uint
     */
    function alchemixToClaim(uint256 _poolId) external view returns (uint256) {
        return pool.getStakeTotalUnclaimed(address(this), _poolId);
    }

    /**
     *  @notice query all deposited tALCX in Alchemix staking pool
     *  @param _poolId pool id of tALCX on Alchemix staking pool
     *  @return uint
     */
    function totaltAlcxDeposited(uint256 _poolId) external view returns (uint256) {
        return pool.getStakeTotalDeposited(address(this), _poolId);
    }

    /**
     *  @notice query requested withdrawal info
     *  @return cycle eligible for withdrawal and amount
     */
    function getRequestedWithdrawalInfo() public view returns (uint256 cycle, uint256 amount) {
        (cycle, amount) = tALCX.requestedWithdrawals(address(this));
    }
}
