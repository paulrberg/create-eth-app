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

import { SafeCast } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeCast.sol";

import {
    IInstantDistributionAgreementV1, ISuperfluidToken
} from "../interfaces/agreements/IInstantDistributionAgreementV1.sol";
import { ISuperfluid, SuperAppDefinitions } from "../interfaces/superfluid/ISuperfluid.sol";
import { AgreementBase } from "./AgreementBase.sol";

import { SlotsBitmapLibrary } from "../libs/SlotsBitmapLibrary.sol";
import { AgreementLibrary } from "./AgreementLibrary.sol";


/**
 * @title InstantDistributionAgreementV1 contract
 * @author Superfluid
 * @dev Please read IInstantDistributionAgreementV1 for implementation notes.
 * @dev For more technical notes, please visit protocol-monorepo wiki area.
 *
 * Storage Layout Notes
 * Agreement State
 * NOTE The Agreement State slot is computed with the following function:
 * keccak256(abi.encode("AgreementState", msg.sender, account, slotId))
 * Publisher Deposit State Slot
 * slotId           = _PUBLISHER_DEPOSIT_STATE_SLOT_ID or 1 << 32 or 4294967296
 * msg.sender       = address of IDAv1
 * account          = context.msgSender
 * Publisher Deposit State stores deposit state for a publisher, this is the pending value.
 *
 * Subscriber Subscription Data Slot Id Start
 * slotId           = _SUBSCRIBER_SUB_DATA_STATE_SLOT_ID_START or 1 << 128 or 340282366920938463463374607431768211456
 * msg.sender       = address of IDAv1
 * account          = context.msgSender
 * Subscriber Subscription Data Slot Id Start indicates the starting slot for where we begin to store the indexes a
 * subscriber is a part of.
 *
 * Slots Bitmap Data Slot
 * slotId           = _SUBSCRIBER_SUBS_BITMAP_STATE_SLOT_ID or 0
 * msg.sender       = address of IDAv1
 * account          = context.msgSender
 * Slots Bitmap Data Slot stores the bitmap of the slots that are "enabled" for a subscriber.
 * This is used as an optimization to only get the data (index id's) for the slots that are "enabled".
 *
 *
 * Agreement Data
 * NOTE The Agreement Data slot is calculated with the following function:
 * keccak256(abi.encode("AgreementData", agreementClass, agreementId))
 * agreementClass   = address of IDAv1
 * agreementId      = PublisherId | SubscriptionId
 *
 * PublisherId      = keccak256(abi.encode("publisher", publisher, indexId))
 * publisher        = "owner" of the index
 * indexId          = arbitrary value for allowing multiple indexes by the same token-publisher pair
 * PublisherId stores IndexData for an Index.
 *
 * SubscriptionId   = keccak256(abi.encode("subscriber", subscriber, iId))
 * iId              = PublisherId, the index this particular subscriber is subscribed to
 * SubscriptionId stores SubscriptionData for a subscriber to an Index.
 */
contract InstantDistributionAgreementV1 is
    AgreementBase,
    IInstantDistributionAgreementV1
{
    using SafeCast for uint256;

    address public constant SLOTS_BITMAP_LIBRARY_ADDRESS = address(SlotsBitmapLibrary);

    /// @dev Maximum number of subscriptions a subscriber can have
    uint32 public constant MAX_NUM_SUBSCRIPTIONS = SlotsBitmapLibrary._MAX_NUM_SLOTS;

    /// @dev Subscriber state slot id for storing subs bitmap
    uint256 private constant _SUBSCRIBER_SUBS_BITMAP_STATE_SLOT_ID = 0;
    /// @dev Publisher state slot id for storing its deposit amount
    uint256 private constant _PUBLISHER_DEPOSIT_STATE_SLOT_ID = 1 << 32;
    /// @dev Subscriber state slot id starting ptoint for subscription data
    uint256 private constant _SUBSCRIBER_SUB_DATA_STATE_SLOT_ID_START = 1 << 128;

    /// @dev A special id that indicating the subscription is not approved yet
    uint32 private constant _UNALLOCATED_SUB_ID = type(uint32).max;

    // solhint-disable-next-line no-empty-blocks
    constructor(ISuperfluid host) AgreementBase(address(host)) {}

    /// @dev Agreement data for the index
    struct IndexData {
        uint128 indexValue;
        uint128 totalUnitsApproved;
        uint128 totalUnitsPending;
    }

    /// @dev Agreement data for the subscription
    struct SubscriptionData {
        uint32 subId;
        address publisher;
        uint32 indexId;
        uint128 indexValue;
        uint128 units;
    }

    /**************************************************************************
     * ISuperAgreement interface
     *************************************************************************/

    /// @dev ISuperAgreement.realtimeBalanceOf implementation
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 /*time*/
    )
        external view override
        returns (
            int256 dynamicBalance,
            uint256 deposit,
            uint256 owedDeposit
        )
    {
        // as a subscriber
        // read all subs and calculate the real-time balance
        uint32[] memory slotIds;
        bytes32[] memory sidList;
        (slotIds, sidList) = _listSubscriptionIds(token, account);
        for (uint32 i = 0; i < sidList.length; ++i) {
            bool exist;
            SubscriptionData memory sdata;
            bytes32 iId;

            {
                uint32 subId = slotIds[i];
                (exist, sdata) = _getSubscriptionData(token, sidList[i]);
                assert(exist);
                assert(sdata.subId == subId);
                iId = token.getAgreementStateSlot(
                    address(this),
                    account,
                    _SUBSCRIBER_SUB_DATA_STATE_SLOT_ID_START + subId, 1)[0];
            }

            {
                IndexData memory idata;
                (exist, idata) = _getIndexData(token, iId);
                assert(exist);
                dynamicBalance = dynamicBalance + (
                    // NOTE casting these values to int256 is okay because the original values
                    // are uint128
                    int256(uint256(idata.indexValue - sdata.indexValue)) * int256(uint256(sdata.units))
                );
            }
        }

        // as a publisher
        // calculate the deposits due to pending subscriptions
        deposit = _getPublisherDeposit(token, account);
        owedDeposit = 0;
    }

    /**************************************************************************
     * Index operations
     *************************************************************************/

    /// @dev IInstantDistributionAgreementV1.createIndex implementation
    function createIndex(
        ISuperfluidToken token,
        uint32 indexId,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
        address publisher = context.msgSender;
        bytes32 iId = _getPublisherId(publisher, indexId);
        if (_hasIndexData(token, iId)) {
            revert IDA_INDEX_ALREADY_EXISTS();
        }

        token.createAgreement(iId, _encodeIndexData(IndexData(0, 0, 0)));

        emit IndexCreated(token, publisher, indexId, context.userData);

        // nothing to be recorded so far
        newCtx = ctx;
    }

    /// @dev IInstantDistributionAgreementV1.getIndex implementation
    function getIndex(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    )
        external view override
        returns (
            bool exist,
            uint128 indexValue,
            uint128 totalUnitsApproved,
            uint128 totalUnitsPending)
    {
        IndexData memory idata;
        bytes32 iId = _getPublisherId(publisher, indexId);
        (exist, idata) = _getIndexData(token, iId);
        if (exist) {
            indexValue = idata.indexValue;
            totalUnitsApproved = idata.totalUnitsApproved;
            totalUnitsPending = idata.totalUnitsPending;
        }
    }

    /// @dev IInstantDistributionAgreementV1.calculateDistribution implementation
    function calculateDistribution(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        uint256 amount
    )
        external view override
        returns(
            uint256 actualAmount,
            uint128 newIndexValue)
    {
        bytes32 iId = _getPublisherId(publisher, indexId);
        (bool exist, IndexData memory idata) = _getIndexData(token, iId);
        if (!exist) revert IDA_INDEX_DOES_NOT_EXIST();

        uint256 totalUnits = uint256(idata.totalUnitsApproved + idata.totalUnitsPending);
        uint128 indexDelta = (amount / totalUnits).toUint128();
        newIndexValue = idata.indexValue + indexDelta;
        actualAmount = uint256(indexDelta) * totalUnits;
    }

    /// @dev IInstantDistributionAgreementV1.updateIndex implementation
    function updateIndex(
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
        address publisher = context.msgSender;
        (bytes32 iId, IndexData memory idata) = _loadIndexData(token, publisher, indexId);
        if (indexValue < idata.indexValue) revert IDA_INDEX_SHOULD_GROW();

        _updateIndex(token, publisher, indexId, iId, idata, indexValue, context.userData);

        // nothing to be recorded so far
        newCtx = ctx;
    }

    /// @dev IInstantDistributionAgreementV1.distribute implementation
    function distribute(
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
        address publisher = context.msgSender;
        (bytes32 iId, IndexData memory idata) = _loadIndexData(token, publisher, indexId);
        uint256 totalUnits = uint256(idata.totalUnitsApproved + idata.totalUnitsPending);

        if (totalUnits > 0) {
            uint128 indexDelta = (amount / totalUnits).toUint128();
            _updateIndex(token, publisher, indexId, iId, idata, idata.indexValue + indexDelta, context.userData);
        }
        // nothing to be recorded so far
        newCtx = ctx;
    }

    function _updateIndex(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes32 iId,
        IndexData memory idata,
        uint128 newIndexValue,
        bytes memory userData
    )
        private
    {
        // - settle the publisher balance INSTANT-ly (ding ding ding, IDA)
        //   - adjust static balance directly
        token.settleBalance(publisher,
            // NOTE casting these values to int256 is okay because the original values
            // are uint128
            (-int256(uint256(newIndexValue - idata.indexValue))) * int256(uint256(idata.totalUnitsApproved)));
        //   - adjust the publisher's deposit amount
        _adjustPublisherDeposit(token, publisher,
            // NOTE casting these values to int256 is okay because the original values
            // are uint128
            int256(uint256(newIndexValue - idata.indexValue)) * int256(uint256(idata.totalUnitsPending)));
        // adjust the publisher's index data
        uint128 oldIndexValue = idata.indexValue;
        idata.indexValue = newIndexValue;
        token.updateAgreementData(iId, _encodeIndexData(idata));

        emit IndexUpdated(
            token,
            publisher,
            indexId,
            oldIndexValue,
            newIndexValue,
            idata.totalUnitsPending,
            idata.totalUnitsApproved,
            userData);

        // check account solvency
        if (token.isAccountCriticalNow(publisher)) {
            revert IDA_INSUFFICIENT_BALANCE();
        }
    }

    function _loadIndexData(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId)
        private view
        returns (
            bytes32 iId,
            IndexData memory idata
        )
    {
        bool exist;
        iId = _getPublisherId(publisher, indexId);
        (exist, idata) = _getIndexData(token, iId);
        if (!exist) revert IDA_INDEX_DOES_NOT_EXIST();
    }

    /**************************************************************************
     * Subscription operations
     *************************************************************************/

     // Stack variables to avoid stack too deep errors in some functions
     // solhint-disable-next-line contract-name-camelcase
     struct _SubscriptionOperationVars {
         bytes32 iId;
         bool subscriptionExists;
         bytes32 sId;
         IndexData idata;
         SubscriptionData sdata;
         bytes cbdata;
     }

    /// @dev IInstantDistributionAgreementV1.approveSubscription implementation
    function approveSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        _SubscriptionOperationVars memory vars;
        AgreementLibrary.CallbackInputs memory cbStates;
        address subscriber;
        bytes memory userData;
        {
            ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
            subscriber = context.msgSender;
            userData = context.userData;
        }

        (
            vars.iId,
            vars.sId,
            vars.idata,
            vars.subscriptionExists,
            vars.sdata
        ) = _loadAllData(token, publisher, subscriber, indexId, false);

        if (vars.subscriptionExists) {
            // required condition check
            if (vars.sdata.subId != _UNALLOCATED_SUB_ID) {
                revert IDA_SUBSCRIPTION_ALREADY_APPROVED();
            }
        }

        newCtx = ctx;
        cbStates = AgreementLibrary.createCallbackInputs(
            token,
            publisher,
            vars.sId,
            "");

        if (!vars.subscriptionExists) {
            cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;
            vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);

            vars.sdata = SubscriptionData({
                publisher: publisher,
                indexId: indexId,
                subId: 0,
                units: 0,
                indexValue: vars.idata.indexValue
            });
            // add to subscription list of the subscriber
            vars.sdata.subId = _findAndFillSubsBitmap(token, subscriber, vars.iId);
            token.createAgreement(vars.sId, _encodeSubscriptionData(vars.sdata));

            cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP;
            (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);
        } else {
            cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP;
            vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);
            // NOTE casting these values to int256 is okay because the original values
            // are uint128
            int balanceDelta = int256(uint256(vars.idata.indexValue - vars.sdata.indexValue))
                * int256(uint256(vars.sdata.units));

            // update publisher data and adjust publisher's deposits
            vars.idata.totalUnitsApproved += vars.sdata.units;
            vars.idata.totalUnitsPending -= vars.sdata.units;
            token.updateAgreementData(vars.iId, _encodeIndexData(vars.idata));
            _adjustPublisherDeposit(token, publisher, -balanceDelta);
            token.settleBalance(publisher, -balanceDelta);

            // update subscription data and adjust subscriber's balance
            token.settleBalance(subscriber, balanceDelta);
            vars.sdata.indexValue = vars.idata.indexValue;
            vars.sdata.subId = _findAndFillSubsBitmap(token, subscriber, vars.iId);
            token.updateAgreementData(vars.sId, _encodeSubscriptionData(vars.sdata));

            cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
            (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);
        }

        // can index up to three words, hence splitting into two events from publisher or subscriber's view.
        emit IndexSubscribed(token, publisher, indexId, subscriber, userData);
        emit SubscriptionApproved(token, subscriber, publisher, indexId, userData);
    }

    /// @dev IInstantDistributionAgreementV1.revokeSubscription implementation
    function revokeSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes calldata ctx
    )
         external override
         returns(bytes memory newCtx)
    {
        _SubscriptionOperationVars memory vars;
        AgreementLibrary.CallbackInputs memory cbStates;
        address subscriber;
        bytes memory userData;
        {
            ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
            subscriber = context.msgSender;
            userData = context.userData;
        }

        (
            vars.iId,
            vars.sId,
            vars.idata,
            ,
            vars.sdata
        ) = _loadAllData(token, publisher, subscriber, indexId, true);

        // should not revoke an pending(un-approved) subscription
        if (vars.sdata.subId == _UNALLOCATED_SUB_ID) {
            revert IDA_SUBSCRIPTION_IS_NOT_APPROVED();
        }

        cbStates = AgreementLibrary.createCallbackInputs(
            token,
            publisher,
            vars.sId,
            "");
        newCtx = ctx;

        cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;
        vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);
        // NOTE downcasting these values to int256 is okay because the original values
        // are uint128
        int256 balanceDelta = int256(uint256(vars.idata.indexValue - vars.sdata.indexValue))
            * int256(uint256(vars.sdata.units));

        vars.idata.totalUnitsApproved = vars.idata.totalUnitsApproved - vars.sdata.units;
        vars.idata.totalUnitsPending = vars.idata.totalUnitsPending + vars.sdata.units;
        token.updateAgreementData(vars.iId, _encodeIndexData(vars.idata));

        // remove subscription from subscriber's bitmap
        _clearSubsBitmap(token, subscriber, vars.sdata.subId);

        // sync pending distributions
        vars.sdata.indexValue = vars.idata.indexValue;
        // unlink publisher and subscriber
        vars.sdata.subId = _UNALLOCATED_SUB_ID;
        token.updateAgreementData(vars.sId, _encodeSubscriptionData(vars.sdata));
        // settle subscriber static balance as a result to keep balance unchanged
        token.settleBalance(subscriber, balanceDelta);

        cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
        (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);

        emit IndexUnsubscribed(token, publisher, indexId, subscriber, userData);
        emit SubscriptionRevoked(token, subscriber, publisher, indexId, userData);
    }

    /// @dev IInstantDistributionAgreementV1.updateSubscription implementation
    function updateSubscription(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        if (subscriber == address(0)) {
            revert IDA_ZERO_ADDRESS_SUBSCRIBER();
        }
        _SubscriptionOperationVars memory vars;
        AgreementLibrary.CallbackInputs memory cbStates;
        bytes memory userData;
        address publisher;
        {
            ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
            userData = context.userData;
            publisher = context.msgSender;
        }

        (
            vars.iId,
            vars.sId,
            vars.idata,
            vars.subscriptionExists,
            vars.sdata
        ) = _loadAllData(token, publisher, subscriber, indexId, false);

        cbStates = AgreementLibrary.createCallbackInputs(
            token,
            subscriber,
            vars.sId,
            "");
        newCtx = ctx;

        // before-hook callback
        if (vars.subscriptionExists) {
            cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP;
            vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);
        } else {
            cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;
            vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);
        }

        // update publisher data
        if (vars.subscriptionExists && vars.sdata.subId != _UNALLOCATED_SUB_ID) {
            // if the subscription exist and not approved, update the approved units amount

            // update total units
            vars.idata.totalUnitsApproved = (
                uint256(vars.idata.totalUnitsApproved) +
                uint256(units) -
                uint256(vars.sdata.units)
            ).toUint128();
            token.updateAgreementData(vars.iId, _encodeIndexData(vars.idata));
        } else if (vars.subscriptionExists) {
            // if the subscription exists and approved, update the pending units amount

            // update pending subscription units of the publisher
            vars.idata.totalUnitsPending = (
                uint256(vars.idata.totalUnitsPending) +
                uint256(units) -
                uint256(vars.sdata.units)
            ).toUint128();
            token.updateAgreementData(vars.iId, _encodeIndexData(vars.idata));
        } else {
            // if the subscription does not exist, create it and then update the pending units amount

            // create unallocated subscription
            vars.sdata = SubscriptionData({
                publisher: publisher,
                indexId: indexId,
                subId: _UNALLOCATED_SUB_ID,
                units: units,
                indexValue: vars.idata.indexValue
            });
            token.createAgreement(vars.sId, _encodeSubscriptionData(vars.sdata));

            vars.idata.totalUnitsPending = vars.idata.totalUnitsPending + units;
            token.updateAgreementData(vars.iId, _encodeIndexData(vars.idata));
        }
        // NOTE casting these values to int256 is okay because the original values
        // are uint128
        int256 balanceDelta = int256(uint256(vars.idata.indexValue - vars.sdata.indexValue))
            * int256(uint256(vars.sdata.units));

        // adjust publisher's deposit and balances if subscription is pending
        if (vars.sdata.subId == _UNALLOCATED_SUB_ID) {
            _adjustPublisherDeposit(token, publisher, -balanceDelta);
            token.settleBalance(publisher, -balanceDelta);
        }

        // settle subscriber static balance
        token.settleBalance(subscriber, balanceDelta);

        // update subscription data if necessary
        if (vars.subscriptionExists) {
            vars.sdata.indexValue = vars.idata.indexValue;
            vars.sdata.units = units;
            token.updateAgreementData(vars.sId, _encodeSubscriptionData(vars.sdata));
        }

        // after-hook callback
        if (vars.subscriptionExists) {
            cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
            (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);
        } else {
            cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP;
            (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);
        }

        emit IndexUnitsUpdated(token, publisher, indexId, subscriber, units, userData);
        emit SubscriptionUnitsUpdated(token, subscriber, publisher, indexId, units, userData);
    }

    /// @dev IInstantDistributionAgreementV1.getSubscription implementation
    function getSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    )
        external view override
        returns (
            bool exist,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        bytes32 iId;
        bytes32 sId;
        IndexData memory idata;
        SubscriptionData memory sdata;

        (
            iId,
            sId,
            idata,
            exist,
            sdata
        ) = _loadAllData(token, publisher, subscriber, indexId, false);

        if (!exist) return (false, false, 0, 0);
        approved = sdata.subId != _UNALLOCATED_SUB_ID;
        units = sdata.units;
        pendingDistribution = approved ? 0 : uint256(idata.indexValue - sdata.indexValue) * uint256(sdata.units);
    }

    /// @dev IInstantDistributionAgreementV1.getSubscriptionByID implementation
    function getSubscriptionByID(
       ISuperfluidToken token,
       bytes32 agreementId
    )
       external view override
       returns(
           address publisher,
           uint32 indexId,
           bool approved,
           uint128 units,
           uint256 pendingDistribution
       )
    {
        bool exist;
        bytes32 iId;
        IndexData memory idata;
        SubscriptionData memory sdata;

        (exist, sdata) = _getSubscriptionData(token, agreementId);
        if (!exist) {
            revert IDA_SUBSCRIPTION_DOES_NOT_EXIST();
        }

        publisher = sdata.publisher;
        indexId = sdata.indexId;
        iId = _getPublisherId(publisher, indexId);
        (exist, idata) = _getIndexData(token, iId);
        assert(exist);

        approved = sdata.subId != _UNALLOCATED_SUB_ID;
        units = sdata.units;
        pendingDistribution = approved ? 0 :
            uint256(idata.indexValue - sdata.indexValue) * uint256(sdata.units);
    }

    /// @dev IInstantDistributionAgreementV1.listSubscriptions implementation
    function listSubscriptions(
        ISuperfluidToken token,
        address subscriber
    )
        external view override
        returns(
            address[] memory publishers,
            uint32[] memory indexIds,
            uint128[] memory unitsList)
    {
        uint32[] memory slotIds;
        bytes32[] memory sidList;
        (slotIds, sidList) = _listSubscriptionIds(token, subscriber);
        bool exist;
        SubscriptionData memory sdata;
        publishers = new address[](sidList.length);
        indexIds = new uint32[](sidList.length);
        unitsList = new uint128[](sidList.length);
        for (uint32 i = 0; i < sidList.length; ++i) {
            uint32 subId = slotIds[i];
            bytes32 sId = sidList[i];
            (exist, sdata) = _getSubscriptionData(token, sId);
            assert(exist);
            assert(sdata.subId == subId);
            publishers[i] = sdata.publisher;
            indexIds[i] = sdata.indexId;
            unitsList[i] = sdata.units;
        }
    }

    /// @dev IInstantDistributionAgreementV1.deleteSubscription implementation
    function deleteSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        _SubscriptionOperationVars memory vars;
        AgreementLibrary.CallbackInputs memory cbStates;
        address sender;
        bytes memory userData;
        {
            ISuperfluid.Context memory context = AgreementLibrary.authorizeTokenAccess(token, ctx);
            sender = context.msgSender;
            userData = context.userData;
        }
        if (subscriber == address(0)) {
            revert IDA_ZERO_ADDRESS_SUBSCRIBER();
        }

        // only publisher can delete a subscription
        // follows from the invariant that only the publisher
        // has the ability to modify the units a subscriber has
        if (sender != publisher) revert IDA_OPERATION_NOT_ALLOWED();

        (
            vars.iId,
            vars.sId,
            vars.idata,
            ,
            vars.sdata
        ) = _loadAllData(token, publisher, subscriber, indexId, true);

        cbStates = AgreementLibrary.createCallbackInputs(
            token,
            subscriber,
            vars.sId,
            "");
        newCtx = ctx;

        cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;
        vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);
        // NOTE casting these values to int256 is okay because the original values
        // are uint128
        int256 balanceDelta = int256(uint256(vars.idata.indexValue - vars.sdata.indexValue))
            * int256(uint256(vars.sdata.units));

        // update publisher index agreement data
        if (vars.sdata.subId != _UNALLOCATED_SUB_ID) {
            vars.idata.totalUnitsApproved = vars.idata.totalUnitsApproved - vars.sdata.units;
        } else {
            vars.idata.totalUnitsPending = vars.idata.totalUnitsPending - vars.sdata.units;
        }
        token.updateAgreementData(vars.iId, _encodeIndexData(vars.idata));

        // remove subscription from subscriber's bitmap
        if (vars.sdata.subId != _UNALLOCATED_SUB_ID) {
            _clearSubsBitmap(token, subscriber, vars.sdata.subId);
        }

        // move from publisher's deposit to static balance
        if (vars.sdata.subId == _UNALLOCATED_SUB_ID) {
            _adjustPublisherDeposit(token, publisher, -balanceDelta);
            token.settleBalance(publisher, -balanceDelta);
        }

        // terminate subscription agreement data
        token.terminateAgreement(vars.sId, 2);

        // settle subscriber static balance
        token.settleBalance(subscriber, balanceDelta);

        cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
        (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);

        emit IndexUnsubscribed(token, publisher, indexId, subscriber, userData);
        emit SubscriptionRevoked(token, subscriber, publisher, indexId, userData);
        emit IndexUnitsUpdated(token, publisher, indexId, subscriber, 0, userData);
        emit SubscriptionUnitsUpdated(token, subscriber, publisher, indexId, 0, userData);
    }

    function claim(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        AgreementLibrary.authorizeTokenAccess(token, ctx);
        if (subscriber == address(0)) {
            revert IDA_ZERO_ADDRESS_SUBSCRIBER();
        }

        _SubscriptionOperationVars memory vars;
        AgreementLibrary.CallbackInputs memory cbStates;

        (
            vars.iId,
            vars.sId,
            vars.idata,
            ,
            vars.sdata
        ) = _loadAllData(token, publisher, subscriber, indexId, true);

        // required condition check
        if (vars.sdata.subId != _UNALLOCATED_SUB_ID) {
            revert IDA_SUBSCRIPTION_ALREADY_APPROVED();
        }

        uint256 pendingDistribution = uint256(vars.idata.indexValue - vars.sdata.indexValue)
            * uint256(vars.sdata.units);

        cbStates = AgreementLibrary.createCallbackInputs(
            token,
            publisher,
            vars.sId,
            "");
        newCtx = ctx;

        if (pendingDistribution > 0) {
            cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP;
            vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, newCtx);

            // adjust publisher's deposits
            _adjustPublisherDeposit(token, publisher, -int256(pendingDistribution));
            token.settleBalance(publisher, -int256(pendingDistribution));

            // update subscription data and adjust subscriber's balance
            vars.sdata.indexValue = vars.idata.indexValue;
            token.updateAgreementData(vars.sId, _encodeSubscriptionData(vars.sdata));
            token.settleBalance(subscriber, int256(pendingDistribution));

            emit IndexDistributionClaimed(token, publisher, indexId, subscriber, pendingDistribution);
            emit SubscriptionDistributionClaimed(token, subscriber, publisher, indexId, pendingDistribution);

            cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
            (, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);
        } else {
            // nothing to be recorded in this case
            newCtx = ctx;
        }
    }

    function _loadAllData(
        ISuperfluidToken token,
        address publisher,
        address subscriber,
        uint32 indexId,
        bool requireSubscriptionExisting
    )
        private view
        returns (
            bytes32 iId,
            bytes32 sId,
            IndexData memory idata,
            bool subscriptionExists,
            SubscriptionData memory sdata
        )
    {
        bool indexExists;
        iId = _getPublisherId(publisher, indexId);
        sId = _getSubscriptionId(subscriber, iId);
        (indexExists, idata) = _getIndexData(token, iId);
        if (!indexExists) revert IDA_INDEX_DOES_NOT_EXIST();
        (subscriptionExists, sdata) = _getSubscriptionData(token, sId);
        if (requireSubscriptionExisting) {
            if (!subscriptionExists) {
                revert IDA_SUBSCRIPTION_DOES_NOT_EXIST();
            }
             // sanity check
            assert(sdata.publisher == publisher);
            assert(sdata.indexId == indexId);
        }
    }

    /**************************************************************************
     * internal helpers
     *************************************************************************/

    function _getPublisherId(
        address publisher,
        uint32 indexId
    )
        private pure
        returns (bytes32 iId)
    {
        return keccak256(abi.encodePacked("publisher", publisher, indexId));
    }

    function _getSubscriptionId(
        address subscriber,
        bytes32 iId
    )
        private pure
        returns (bytes32 sId)
    {
        return keccak256(abi.encodePacked("subscription", subscriber, iId));
    }

    // # Index data operations
    //
    // Data packing:
    //
    // WORD 1: | existence bit  | indexValue |
    //         | 128b           | 128b       |
    // WORD 2: | totalUnitsPending | totalUnitsApproved |
    //         | 128b              | 12b                |

    function _encodeIndexData(
        IndexData memory idata
    )
        private pure
        returns (bytes32[] memory data) {
        data = new bytes32[](2);
        data[0] = bytes32(
            uint256(1 << 128) /* existance bit */ |
            uint256(idata.indexValue)
        );
        data[1] = bytes32(
            (uint256(idata.totalUnitsApproved)) |
            (uint256(idata.totalUnitsPending) << 128)
        );
    }

    function _hasIndexData(
        ISuperfluidToken token,
        bytes32 iId
    )
        private view
        returns (bool exist)
    {
        bytes32[] memory adata = token.getAgreementData(address(this), iId, 2);
        uint256 a = uint256(adata[0]);
        exist = a > 0;
    }

    function _getIndexData(
        ISuperfluidToken token,
        bytes32 iId
    )
        private view
        returns (bool exist, IndexData memory idata)
    {
        bytes32[] memory adata = token.getAgreementData(address(this), iId, 2);
        uint256 a = uint256(adata[0]);
        uint256 b = uint256(adata[1]);
        exist = a > 0;
        if (exist) {
            // NOTE We will do an unsafe downcast from uint256 => uint128
            // as we know this is safe
            // see https://gist.github.com/0xdavinchee/9834dc689543f19ec07872ad7d766b09
            idata.indexValue = uint128(a);
            idata.totalUnitsApproved = uint128(b);
            idata.totalUnitsPending = uint128(b >> 128);
        }
    }


    // # Publisher's deposit amount
    //
    // It is stored in state slot in one word

    function _getPublisherDeposit(
        ISuperfluidToken token,
        address publisher
    )
        private view
        returns (uint256)
    {
        bytes32[] memory data = token.getAgreementStateSlot(
            address(this),
            publisher,
            _PUBLISHER_DEPOSIT_STATE_SLOT_ID,
            1);
        return uint256(data[0]);
    }

    function _adjustPublisherDeposit(
        ISuperfluidToken token,
        address publisher,
        int256 delta
    )
        private
    {
        if (delta == 0) return;
        bytes32[] memory data = token.getAgreementStateSlot(
            address(this),
            publisher,
            _PUBLISHER_DEPOSIT_STATE_SLOT_ID,
            1);
        data[0] = bytes32(uint256(uint256(data[0]).toInt256() + delta));
        token.updateAgreementStateSlot(
            publisher,
            _PUBLISHER_DEPOSIT_STATE_SLOT_ID,
            data);
    }

    // # Subscription data operations
    //
    // Data packing:
    //
    // WORD 1: | publisher | RESERVED | indexId | subId |
    //         | 160b      | 32b      | 32b     | 32b   |
    // WORD 2: | units | indexValue |
    //         | 128b  | 128b       |

    function _encodeSubscriptionData(
        SubscriptionData memory sdata
    )
        private pure
        returns (bytes32[] memory data)
    {
        data = new bytes32[](2);
        data[0] = bytes32(
            (uint256(uint160(sdata.publisher)) << (12*8)) |
            (uint256(sdata.indexId) << 32) |
            uint256(sdata.subId)
        );
        data[1] = bytes32(
            uint256(sdata.indexValue) |
            (uint256(sdata.units) << 128)
        );
    }

    function _getSubscriptionData(
        ISuperfluidToken token,
        bytes32 sId
    )
        private view
        returns (bool exist, SubscriptionData memory sdata)
    {
        bytes32[] memory adata = token.getAgreementData(address(this), sId, 2);
        uint256 a = uint256(adata[0]);
        uint256 b = uint256(adata[1]);
        exist = a > 0;
        if (exist) {
            sdata.publisher = address(uint160(a >> (12*8)));
            sdata.indexId = uint32((a >> 32) & type(uint32).max);
            sdata.subId = uint32(a & type(uint32).max);
            // NOTE We will do an unsafe downcast from uint256 => uint128
            // as we know this is safe
            // see https://gist.github.com/0xdavinchee/9834dc689543f19ec07872ad7d766b09
            sdata.indexValue = uint128(b);
            sdata.units = uint128(b >> 128);
        }
    }

    // # Subscription bitmap operations
    //
    // ## Subscription bitmap state slot
    //
    // slotId: _SUBSCRIBER_SUBS_BITMAP_STATE_SLOT_ID)
    //
    // Subscriber can store up to _MAX_NUM_SUBS amount of subscriptions.
    // For each subscription approved it allocated with a subId with a value in [0, _MAX_NUM_SUBS).
    // The allocation is to fill one bit in the subscription bitmap.
    //
    // ## Subscription reference state slots
    //
    // slotId: _SUBSCRIBER_SUB_DATA_STATE_SLOT_ID_START + subId)
    //
    // It stores the index data ID.

    function _findAndFillSubsBitmap(
        ISuperfluidToken token,
        address subscriber,
        bytes32 iId
    )
        private
        returns (uint32 subId)
    {
        return SlotsBitmapLibrary.findEmptySlotAndFill(
            token,
            subscriber,
            _SUBSCRIBER_SUBS_BITMAP_STATE_SLOT_ID,
            _SUBSCRIBER_SUB_DATA_STATE_SLOT_ID_START,
            iId);
    }

    function _clearSubsBitmap(
        ISuperfluidToken token,
        address subscriber,
        uint32 subId
    )
        private
    {
        SlotsBitmapLibrary.clearSlot(
            token,
            subscriber,
            _SUBSCRIBER_SUBS_BITMAP_STATE_SLOT_ID,
            subId);
    }

    function _listSubscriptionIds(
       ISuperfluidToken token,
       address subscriber
    )
        private view
        returns (
            uint32[] memory slotIds,
            bytes32[] memory sidList)
    {
        (slotIds, sidList) = SlotsBitmapLibrary.listData(
            token,
            subscriber,
            _SUBSCRIBER_SUBS_BITMAP_STATE_SLOT_ID,
            _SUBSCRIBER_SUB_DATA_STATE_SLOT_ID_START);
        // map data to subId
        for (uint i = 0; i < sidList.length; ++i) {
            sidList[i] = _getSubscriptionId(subscriber, sidList[i]);
        }
    }

}
