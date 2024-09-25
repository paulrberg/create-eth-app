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
pragma experimental ABIEncoderV2;

import {ISuperfluid, ISuperfluidToken, ISuperToken} from "../interfaces/superfluid/ISuperfluid.sol";

import {SuperAppBase, SuperAppDefinitions} from "../apps/SuperAppBase.sol";

import {
    IInstantDistributionAgreementV1
} from "../interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {IDAv1Library} from "../apps/IDAv1Library.sol";

contract IDAv1LibraryMock {
    using IDAv1Library for IDAv1Library.InitData;

    IDAv1Library.InitData internal _idaLib;

    bytes32 internal constant _IDAV1_HASH = keccak256(
        "org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
    );

    constructor(ISuperfluid host) {
        _idaLib = IDAv1Library.InitData(
            host,
            IInstantDistributionAgreementV1(
                address(host.getAgreementClass(_IDAV1_HASH))
            )
        );
    }

    /**************************************************************************
     * View Functions
     *************************************************************************/

    function getIndexTest(ISuperfluidToken token, address publisher, uint32 indexId)
        external
        view
        returns (
            bool exist,
            uint128 indexValue,
            uint128 totalUnitsApproved,
            uint128 totalUnitsPending
        )
    {
        return _idaLib.getIndex(token, publisher, indexId);
    }

    function calculateDistributionTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        uint256 amount
    )
        external
        view
        returns (
            uint256 actualAmount,
            uint128 newIndexValue
        )
    {
        return _idaLib.calculateDistribution(token, publisher, indexId, amount);
    }

    function listSubscriptionsTest(ISuperfluidToken token, address subscriber)
        external
        view
        returns (
            address[] memory publishers,
            uint32[] memory indexIds,
            uint128[] memory unitsList
        )
    {
        return _idaLib.listSubscriptions(token, subscriber);
    }

    function getSubscriptionTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    )
        external
        view
        returns (
            bool exist,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        return _idaLib.getSubscription(token, publisher, indexId, subscriber);
    }

    /// @dev agreementId == keccak256(abi.encodePacked("subscription", subscriber, indexId));
    function getSubscriptionByIDTest(ISuperfluidToken token, bytes32 agreementId)
        external
        view
        returns (
            address publisher,
            uint32 indexId,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        return _idaLib.getSubscriptionByID(token, agreementId);
    }

    /**************************************************************************
     * Index Operations
     *************************************************************************/

    function createIndexTest(ISuperfluidToken token, uint32 indexId) external {
        _idaLib.createIndex(token, indexId);
    }

    function createIndexWithUserDataTest(
        ISuperfluidToken token,
        uint32 indexId,
        bytes memory userData
    ) external {
        _idaLib.createIndex(token, indexId, userData);
    }

    function updateIndexValueTest(
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue
    ) external {
        _idaLib.updateIndexValue(token, indexId, indexValue);
    }

    function updateIndexValueWithUserDataTest(
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes memory userData
    ) external {
        _idaLib.updateIndexValue(token, indexId, indexValue, userData);
    }

    function distributeTest(ISuperfluidToken token, uint32 indexId, uint256 amount) external {
        _idaLib.distribute(token, indexId, amount);
    }

    function distributeWithUserDataTest(
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount,
        bytes memory userData
    ) external {
        _idaLib.distribute(token, indexId, amount, userData);
    }

    /**************************************************************************
     * Subscription Operations
     *************************************************************************/

    function approveSubscriptionTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    ) external {
        _idaLib.approveSubscription(token, publisher, indexId);
    }

    function approveSubscriptionWithUserDataTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) external {
        _idaLib.approveSubscription(token, publisher, indexId, userData);
    }

    function revokeSubscriptionTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    ) external {
        _idaLib.revokeSubscription(token, publisher, indexId);
    }

    function revokeSubscriptionWithUserDataTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) external {
        _idaLib.revokeSubscription(token, publisher, indexId, userData);
    }

    function updateSubscriptionUnitsTest(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units
    ) external {
        _idaLib.updateSubscriptionUnits(token, indexId, subscriber, units);
    }

    function updateSubscriptionUnitsWithUserDataTest(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes memory userData
    ) external {
        _idaLib.updateSubscriptionUnits(token, indexId, subscriber, units, userData);
    }

    function deleteSubscriptionTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) external {
        _idaLib.deleteSubscription(token, publisher, indexId, subscriber);
    }

    function deleteSubscriptionWithUserDataTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) external {
        _idaLib.deleteSubscription(token, publisher, indexId, subscriber, userData);
    }

    function claimTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) external {
        _idaLib.claim(token, publisher, indexId, subscriber);
    }

    function claimWithUserDataTest(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) external {
        _idaLib.claim(token, publisher, indexId, subscriber, userData);
    }
}

// IDA LIBRARY SUPER APP CALLBACK MOCK
contract IDAv1LibrarySuperAppMock is IDAv1LibraryMock, SuperAppBase {
    using IDAv1Library for IDAv1Library.InitData;

    bytes internal constant _MOCK_USER_DATA = abi.encode("oh hello");

    constructor(ISuperfluid host) IDAv1LibraryMock(host) {
        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            // SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            // SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP |
            SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;

        host.registerAppWithKey(configWord, "");
    }

    function afterAgreementCreated(
        ISuperToken token,
        address,
        bytes32,
        bytes calldata,
        bytes calldata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        return _callbackTest(token, ctx);
    }

    function afterAgreementUpdated(
        ISuperToken token,
        address,
        bytes32,
        bytes calldata,
        bytes calldata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        return _callbackTest(token, ctx);
    }

    enum FunctionIndex {
        CREATE_INDEX,
        CREATE_INDEX_USER_DATA,
        UPDATE_INDEX,
        UPDATE_INDEX_USER_DATA,
        DISTRIBUTE,
        DISTRIBUTE_USER_DATA,
        APROVE_SUBSCRIPTION,
        APROVE_SUBSCRIPTION_USER_DATA,
        REVOKE_SUBSCRIPTION,
        REVOKE_SUBSCRIPTION_USER_DATA,
        UPDATE_SUBSCRIPTION,
        UPDATE_SUBSCRIPTION_USER_DATA,
        DELETE_SUBSCRIPTION,
        DELETE_SUBSCRIPTION_USER_DATA,
        CLAIM,
        CLAIM_USER_DATA
    }

    /// @dev extracts some user data to test out all callback library functions
    /// @param token super token
    /// @param ctx Context string
    /// @return New Context
    function _callbackTest(
        ISuperToken token,
        bytes memory ctx
    ) internal returns (bytes memory) {

        // extract userData, then decode everything else
        bytes memory userData = _idaLib.host.decodeCtx(ctx).userData;
        (
            uint8 functionIndex,
            uint32 indexId,
            address publisher,
            address subscriber,
            uint128 units
        ) = abi.decode(userData, (uint8, uint32, address, address, uint128));

        if (functionIndex == uint8(FunctionIndex.CREATE_INDEX)) {
            return _idaLib.createIndexWithCtx(ctx, token, indexId);
        } else if (functionIndex == uint8(FunctionIndex.CREATE_INDEX_USER_DATA)) {
            return _idaLib.createIndexWithCtx(ctx, token, indexId, _MOCK_USER_DATA);
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_INDEX)) {
            return _idaLib.updateIndexValueWithCtx(ctx, token, indexId, units);
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_INDEX_USER_DATA)) {
            return _idaLib.updateIndexValueWithCtx(ctx, token, indexId, units, _MOCK_USER_DATA);
        } else if (functionIndex == uint8(FunctionIndex.DISTRIBUTE)) {
            return _idaLib.distributeWithCtx(ctx, token, indexId, units);
        } else if (functionIndex == uint8(FunctionIndex.DISTRIBUTE_USER_DATA)) {
            return _idaLib.distributeWithCtx(ctx, token, indexId, units, _MOCK_USER_DATA);
        } else if (functionIndex == uint8(FunctionIndex.APROVE_SUBSCRIPTION)) {
            return _idaLib.approveSubscriptionWithCtx(ctx, token, publisher, indexId);
        } else if (functionIndex == uint8(FunctionIndex.APROVE_SUBSCRIPTION_USER_DATA)) {
            return _idaLib.approveSubscriptionWithCtx(
                ctx,
                token,
                publisher,
                indexId,
                _MOCK_USER_DATA
            );
        } else if (functionIndex == uint8(FunctionIndex.REVOKE_SUBSCRIPTION)) {
            return _idaLib.revokeSubscriptionWithCtx(ctx, token, publisher, indexId);
        } else if (functionIndex == uint8(FunctionIndex.REVOKE_SUBSCRIPTION_USER_DATA)) {
            return _idaLib.revokeSubscriptionWithCtx(
                ctx,
                token,
                publisher,
                indexId,
                _MOCK_USER_DATA
            );
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_SUBSCRIPTION)) {
            return _idaLib.updateSubscriptionUnitsWithCtx(ctx, token, indexId, subscriber, units);
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_SUBSCRIPTION_USER_DATA)) {
            return _idaLib.updateSubscriptionUnitsWithCtx(
                ctx,
                token,
                indexId,
                subscriber,
                units,
                _MOCK_USER_DATA
            );
        } else if (functionIndex == uint8(FunctionIndex.DELETE_SUBSCRIPTION)) {
            return _idaLib.deleteSubscriptionWithCtx(ctx, token, publisher, indexId, subscriber);
        } else if (functionIndex == uint8(FunctionIndex.DELETE_SUBSCRIPTION_USER_DATA)) {
            return _idaLib.deleteSubscriptionWithCtx(
                ctx,
                token,
                publisher,
                indexId,
                subscriber,
                _MOCK_USER_DATA
            );
        } else if (functionIndex == uint8(FunctionIndex.CLAIM)) {
            return _idaLib.claimWithCtx(ctx, token, publisher, indexId, subscriber);
        } else if (functionIndex == uint8(FunctionIndex.CLAIM_USER_DATA)) {
            return _idaLib.claimWithCtx(
                ctx,
                token,
                publisher,
                indexId,
                subscriber,
                _MOCK_USER_DATA
            );
        } else {
            revert("invalid function index");
        }
    }
}
