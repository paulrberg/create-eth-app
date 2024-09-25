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

import {
    ISuperfluid,
    ISuperAgreement,
    ISuperfluidGovernance,
    ISuperfluidToken
} from "../interfaces/superfluid/ISuperfluid.sol";
import { SafeCast } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeCast.sol";
import { EventsEmitter } from "../libs/EventsEmitter.sol";
import { FixedSizeData } from "../libs/FixedSizeData.sol";

/**
 * @title Superfluid's token implementation
 *
 * @author Superfluid
 */
abstract contract SuperfluidToken is ISuperfluidToken
{

    bytes32 private constant _REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");

    using SafeCast for uint256;
    using SafeCast for int256;

    /// @dev Superfluid contract
    ISuperfluid immutable internal _host;

    /// @dev Active agreement bitmap
    mapping(address => uint256) internal _inactiveAgreementBitmap;

    /// @dev Shared Settled balance for the account
    mapping(address => int256) internal _sharedSettledBalances;

    /// @dev Total supply
    uint256 internal _totalSupply;

    // NOTE: for future compatibility, these are reserved solidity slots
    // The sub-class of SuperfluidToken solidity slot will start after _reserve13
    uint256 internal _reserve4;
    uint256 private _reserve5;
    uint256 private _reserve6;
    uint256 private _reserve7;
    uint256 private _reserve8;
    uint256 private _reserve9;
    uint256 private _reserve10;
    uint256 private _reserve11;
    uint256 private _reserve12;
    uint256 internal _reserve13;

    constructor(
        ISuperfluid host
    ) {
        _host = host;
    }

    /// @dev ISuperfluidToken.getHost implementation
    function getHost()
       external view
       override(ISuperfluidToken)
       returns(address host)
    {
       return address(_host);
    }

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/

    /// @dev ISuperfluidToken.realtimeBalanceOf implementation
    function realtimeBalanceOf(
       address account,
       uint256 timestamp
    )
       public view virtual override
       returns (
           int256 availableBalance,
           uint256 deposit,
           uint256 owedDeposit)
    {
        availableBalance = _sharedSettledBalances[account];
        ISuperAgreement[] memory activeAgreements = getAccountActiveAgreements(account);
        for (uint256 i = 0; i < activeAgreements.length; ++i) {
            (
                int256 agreementDynamicBalance,
                uint256 agreementDeposit,
                uint256 agreementOwedDeposit) = activeAgreements[i]
                    .realtimeBalanceOf(
                         this,
                         account,
                         timestamp
                     );
            deposit = deposit + agreementDeposit;
            owedDeposit = owedDeposit + agreementOwedDeposit;
            // 1. Available Balance = Dynamic Balance - Max(0, Deposit - OwedDeposit)
            // 2. Deposit should not be shared between agreements
            availableBalance = availableBalance
                + agreementDynamicBalance
                - (
                    agreementDeposit > agreementOwedDeposit ?
                    (agreementDeposit - agreementOwedDeposit) : 0
                ).toInt256();
        }
    }

    /// @dev ISuperfluidToken.realtimeBalanceOfNow implementation
    function realtimeBalanceOfNow(
       address account
    )
        public view virtual override
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit,
            uint256 timestamp)
    {
        timestamp = _host.getNow();
        (
            availableBalance,
            deposit,
            owedDeposit
        ) = realtimeBalanceOf(account, timestamp);
    }

    function isAccountCritical(
        address account,
        uint256 timestamp
    )
        public view virtual override
        returns(bool isCritical)
    {
        (int256 availableBalance,,) = realtimeBalanceOf(account, timestamp);
        return availableBalance < 0;
    }

    function isAccountCriticalNow(
       address account
    )
        external view virtual override
       returns(bool isCritical)
    {
        return isAccountCritical(account, _host.getNow());
    }

    function isAccountSolvent(
        address account,
        uint256 timestamp
    )
        public view virtual override
        returns(bool isSolvent)
    {
        (int256 availableBalance, uint256 deposit, uint256 owedDeposit) =
            realtimeBalanceOf(account, timestamp);
        // Available Balance = Realtime Balance - Max(0, Deposit - OwedDeposit)
        int realtimeBalance = availableBalance
            + (deposit > owedDeposit ? (deposit - owedDeposit) : 0).toInt256();
        return realtimeBalance >= 0;
    }

    function isAccountSolventNow(
       address account
    )
       external view virtual override
       returns(bool isSolvent)
    {
        return isAccountSolvent(account, _host.getNow());
    }

    /// @dev ISuperfluidToken.getAccountActiveAgreements implementation
    function getAccountActiveAgreements(address account)
       public view virtual override
       returns(ISuperAgreement[] memory)
    {
       return _host.mapAgreementClasses(~_inactiveAgreementBitmap[account]);
    }

    /**************************************************************************
     * Token implementation helpers
     *************************************************************************/

    function _mint(
        address account,
        uint256 amount
    )
        internal
    {
        _sharedSettledBalances[account] = _sharedSettledBalances[account] + amount.toInt256();
        _totalSupply = _totalSupply + amount;
    }

    function _burn(
        address account,
        uint256 amount
    )
        internal
    {
        (int256 availableBalance,,) = realtimeBalanceOf(account, _host.getNow());
        if (availableBalance < amount.toInt256()) {
            revert SF_TOKEN_BURN_INSUFFICIENT_BALANCE();
        }
        _sharedSettledBalances[account] = _sharedSettledBalances[account] - amount.toInt256();
        _totalSupply = _totalSupply - amount;
    }

    function _move(
        address from,
        address to,
        int256 amount
    )
        internal
    {
        (int256 availableBalance,,) = realtimeBalanceOf(from, _host.getNow());
        if (availableBalance < amount) {
            revert SF_TOKEN_MOVE_INSUFFICIENT_BALANCE();
        }
        _sharedSettledBalances[from] = _sharedSettledBalances[from] - amount;
        _sharedSettledBalances[to] = _sharedSettledBalances[to] + amount;
    }

    function _getRewardAccount() internal view returns (address rewardAccount) {
        ISuperfluidGovernance gov = _host.getGovernance();
        rewardAccount = gov.getConfigAsAddress(_host, this, _REWARD_ADDRESS_CONFIG_KEY);
    }

    /**************************************************************************
     * Super Agreement hosting functions
     *************************************************************************/

    /// @dev ISuperfluidToken.createAgreement implementation
    function createAgreement(
        bytes32 id,
        bytes32[] calldata data
    )
        external virtual override
    {
        address agreementClass = msg.sender;
        bytes32 slot = keccak256(abi.encode("AgreementData", agreementClass, id));
        if (FixedSizeData.hasData(slot, data.length)) {
            revert SF_TOKEN_AGREEMENT_ALREADY_EXISTS();
        }
        FixedSizeData.storeData(slot, data);
        emit AgreementCreated(agreementClass, id, data);
    }

    /// @dev ISuperfluidToken.getAgreementData implementation
    function getAgreementData(
        address agreementClass,
        bytes32 id,
        uint dataLength
    )
        external view virtual override
        returns(bytes32[] memory data)
    {
        bytes32 slot = keccak256(abi.encode("AgreementData", agreementClass, id));
        data = FixedSizeData.loadData(slot, dataLength);
    }

    /// @dev ISuperfluidToken.updateAgreementData implementation
    function updateAgreementData(
        bytes32 id,
        bytes32[] calldata data
    )
        external virtual override
    {
        address agreementClass = msg.sender;
        bytes32 slot = keccak256(abi.encode("AgreementData", agreementClass, id));
        FixedSizeData.storeData(slot, data);
        emit AgreementUpdated(msg.sender, id, data);
    }

    /// @dev ISuperfluidToken.terminateAgreement implementation
    function terminateAgreement(
        bytes32 id,
        uint dataLength
    )
        external virtual override
    {
        address agreementClass = msg.sender;
        bytes32 slot = keccak256(abi.encode("AgreementData", agreementClass, id));
        if (!FixedSizeData.hasData(slot,dataLength)) {
            revert SF_TOKEN_AGREEMENT_DOES_NOT_EXIST();
        }
        FixedSizeData.eraseData(slot, dataLength);
        emit AgreementTerminated(msg.sender, id);
    }

    /// @dev ISuperfluidToken.updateAgreementState implementation
    function updateAgreementStateSlot(
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
    )
        external virtual override
    {
        bytes32 slot = keccak256(abi.encode("AgreementState", msg.sender, account, slotId));
        FixedSizeData.storeData(slot, slotData);
        emit AgreementStateUpdated(msg.sender, account, slotId);
    }

    /// @dev ISuperfluidToken.getAgreementState implementation
    function getAgreementStateSlot(
        address agreementClass,
        address account,
        uint256 slotId,
        uint dataLength
    )
        external view virtual override
        returns (bytes32[] memory slotData) {
        bytes32 slot = keccak256(abi.encode("AgreementState", agreementClass, account, slotId));
        slotData = FixedSizeData.loadData(slot, dataLength);
    }

    /// @dev ISuperfluidToken.settleBalance implementation
    function settleBalance(
        address account,
        int256 delta
    )
        external virtual override
        onlyAgreement
    {
        _sharedSettledBalances[account] = _sharedSettledBalances[account] + delta;
    }

    /// @dev ISuperfluidToken.makeLiquidationPayoutsV2 implementation
    function makeLiquidationPayoutsV2(
        bytes32 id,
        bytes memory liquidationTypeData,
        address liquidatorAccount, // the address executing the liquidation
        bool useDefaultRewardAccount, // Whether or not the default reward account receives the rewardAmount
        address targetAccount, // Account to be liquidated
        uint256 rewardAmount, // The amount the rewarded account will receive
        int256 targetAccountBalanceDelta // The delta amount the target account balance should change by
    ) external virtual override onlyAgreement {
        address rewardAccount = _getRewardAccount();

        // we set the rewardAccount to the user who executed the liquidation if
        // no rewardAccount is set (aka. ANARCHY MODE - should not occur in reality, for testing purposes)
        if (rewardAccount == address(0)) {
            rewardAccount = liquidatorAccount;
        }

        address rewardAmountReceiver = useDefaultRewardAccount ? rewardAccount : liquidatorAccount;

        if (targetAccountBalanceDelta <= 0) {
            // LIKELY BRANCH: target account pays penalty to rewarded account
            assert(rewardAmount.toInt256() == -targetAccountBalanceDelta);

            _sharedSettledBalances[rewardAmountReceiver] += rewardAmount.toInt256();
            _sharedSettledBalances[targetAccount] += targetAccountBalanceDelta;
            EventsEmitter.emitTransfer(targetAccount, rewardAmountReceiver, rewardAmount);
        } else {
            // LESS LIKELY BRANCH: target account is bailed out
            // NOTE: useDefaultRewardAccount being true is undefined behavior
            // because the default reward account isn't receiving the rewardAmount by default
            assert(!useDefaultRewardAccount);
            _sharedSettledBalances[rewardAccount] -= (rewardAmount.toInt256() + targetAccountBalanceDelta);
            _sharedSettledBalances[liquidatorAccount] += rewardAmount.toInt256();
            _sharedSettledBalances[targetAccount] += targetAccountBalanceDelta;
            EventsEmitter.emitTransfer(rewardAccount, liquidatorAccount, rewardAmount);
            EventsEmitter.emitTransfer(rewardAccount, targetAccount, uint256(targetAccountBalanceDelta));
        }

        emit AgreementLiquidatedV2(
            msg.sender,
            id,
            liquidatorAccount,
            targetAccount,
            rewardAmountReceiver,
            rewardAmount,
            targetAccountBalanceDelta,
            liquidationTypeData
        );
    }

    /**************************************************************************
    * Modifiers
    *************************************************************************/

    modifier onlyAgreement() {
        if (!_host.isAgreementClassListed(ISuperAgreement(msg.sender))) {
            revert SF_TOKEN_ONLY_LISTED_AGREEMENT();
        }
        _;
    }

    modifier onlyHost() {
        if (address(_host) != msg.sender) {
            revert SF_TOKEN_ONLY_HOST();
        }
        _;
    }

}
