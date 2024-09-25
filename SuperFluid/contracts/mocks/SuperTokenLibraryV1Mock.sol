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

import { ISuperfluid, ISuperToken } from "../interfaces/superfluid/ISuperfluid.sol";
import { SuperAppDefinitions } from "../interfaces/superfluid/ISuperfluid.sol";
import { SuperAppBase } from "../apps/SuperAppBase.sol";
import { SuperTokenV1Library } from "../apps/SuperTokenV1Library.sol";

contract SuperTokenLibraryCFAMock {

    using SuperTokenV1Library for ISuperToken;

     /**************************************************************************
     * View Functions
     *************************************************************************/

    function getFlowRateTest(
        ISuperToken token,
        address sender,
        address receiver
    ) public view returns (int96 rate) {
        return token.getFlowRate(sender, receiver);
    }

    function getFlowInfoTest(
        ISuperToken token,
        address sender,
        address receiver
    ) public view returns (uint256 lastUpdated, int96 flowRate, uint256 deposit, uint256 owedDeposit) {
        return token.getFlowInfo(sender, receiver);
    }

    function getNetFlowRateTest(
        ISuperToken token,
        address account
    ) public view returns (int96 netFlowRate) {
        return token.getNetFlowRate(account);
    }

    function getNetFlowInfoTest(
        ISuperToken token,
        address account
    ) public view returns  (uint256 lastUpdated, int96 flowRate, uint256 deposit, uint256 owedDeposit) {
        return token.getNetFlowInfo(account);
    }

    function getBufferAmountByFlowRateTest(
        ISuperToken token,
        int96 flowRate
    ) public view returns (uint256 bufferAmount) {
        return token.getBufferAmountByFlowRate(flowRate);
    }

    function getFlowPermissionsTest(
        ISuperToken token,
        address sender,
        address flowOperator
    ) public view returns (bool allowCreate, bool allowUpdate, bool allowDelete, int96 flowRateAllowance) {
        return token.getFlowPermissions(sender, flowOperator);
    }


      /**************************************************************************
     * CFA Operations
     *************************************************************************/

    function createFlowTest(
        ISuperToken token,
        address receiver,
        int96 flowRate
    ) public {
        token.createFlow(receiver, flowRate);
    }

    function createFlowWithUserDataTest(
        ISuperToken token,
        address receiver,
        int96 flowRate,
        bytes memory userData
    ) public {
        token.createFlow(receiver, flowRate, userData);
    }

    function deleteFlowTest(
        ISuperToken token,
        address sender,
        address receiver
    ) public {
        token.deleteFlow(sender, receiver);
    }

    function deleteFlowWithUserDataTest(
        ISuperToken token,
        address sender,
        address receiver,
        bytes memory userData
    ) public {
        token.deleteFlow(sender, receiver, userData);
    }

    function updateFlowWithUserDataTest(
        ISuperToken token,
        address receiver,
        int96 flowRate,
        bytes memory userData
    ) public {
        token.updateFlow(receiver, flowRate, userData);
    }

    function updateFlowTest(
        ISuperToken token,
        address receiver,
        int96 flowRate
    ) public {
        token.updateFlow(receiver, flowRate);
    }

    function createFlowFromTest(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowRate
    ) public {
        token.createFlowFrom(sender, receiver, flowRate);
    }

    function createFlowFromWithUserDataTest(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes memory userData
    ) public {
        token.createFlowFrom(sender, receiver, flowRate, userData);
    }

    function deleteFlowFromTest(
        ISuperToken token,
        address sender,
        address receiver
    ) public {
        token.deleteFlowFrom(sender, receiver);
    }

    function deleteFlowFromWithUserDataTest(
        ISuperToken token,
        address sender,
        address receiver,
        bytes memory userData
    ) public {
        token.deleteFlowFrom(sender, receiver, userData);
    }

    function updateFlowFromTest(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowRate
    ) public {
        token.updateFlowFrom(sender, receiver, flowRate);
    }

    function updateFlowFromWithUserDataTest(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes memory userData
    ) public {
        token.updateFlowFrom(sender, receiver, flowRate, userData);
    }

    function setFlowPermissionsTest(
        ISuperToken token,
        address flowOperator,
        bool allowCreate,
        bool allowUpdate,
        bool allowDelete,
        int96 flowRateAllowance
    ) public {
        token.setFlowPermissions(flowOperator, allowCreate, allowUpdate, allowDelete, flowRateAllowance);
    }


    function setMaxFlowPermissionsTest(
        address flowOperator,
        ISuperToken token
    ) public {
        token.setMaxFlowPermissions(flowOperator);
    }

    function revokeFlowPermissionsTest(
        address flowOperator,
        ISuperToken token
    ) public {
        token.revokeFlowPermissions(flowOperator);
    }

    function increaseFlowRateAllowanceTest(ISuperToken token, address flowOperator, int96 addedFlowRateAllowance)
        public
    {
        token.increaseFlowRateAllowance(flowOperator, addedFlowRateAllowance);
    }

    function decreaseFlowRateAllowanceTest(ISuperToken token, address flowOperator, int96 subtractedFlowRateAllowance)
        public
    {
        token.decreaseFlowRateAllowance(flowOperator, subtractedFlowRateAllowance);
    }

    function increaseFlowRateAllowanceWithUserDataTest(
        ISuperToken token,
        address flowOperator,
        int96 addedFlowRateAllowance,
        bytes memory userData
    ) public {
        token.increaseFlowRateAllowance(flowOperator, addedFlowRateAllowance, userData);
    }

    function decreaseFlowRateAllowanceWithUserDataTest(
        ISuperToken token,
        address flowOperator,
        int96 subtractedFlowRateAllowance,
        bytes memory userData
    ) public {
        token.decreaseFlowRateAllowance(flowOperator, subtractedFlowRateAllowance, userData);
    }

    function increaseFlowRateAllowanceWithPermissionsTest(
        ISuperToken token,
        address flowOperator,
        uint8 permissionsToAdd,
        int96 addedFlowRateAllowance
    ) public {
        token.increaseFlowRateAllowanceWithPermissions(flowOperator, permissionsToAdd, addedFlowRateAllowance);
    }

    function decreaseFlowRateAllowanceWithPermissionsTest(
        ISuperToken token,
        address flowOperator,
        uint8 permissionsToRemove,
        int96 subtractedFlowRateAllowance
    ) public {
        token.decreaseFlowRateAllowanceWithPermissions(flowOperator, permissionsToRemove, subtractedFlowRateAllowance);
    }

    function increaseFlowRateAllowanceWithPermissionsWithUserDataTest(
        ISuperToken token,
        address flowOperator,
        uint8 permissionsToAdd,
        int96 addedFlowRateAllowance,
        bytes memory userData
    ) public {
        token.increaseFlowRateAllowanceWithPermissions(
            flowOperator,
            permissionsToAdd,
            addedFlowRateAllowance,
            userData
        );
    }

    function decreaseFlowRateAllowanceWithPermissionsWithUserDataTest(
        ISuperToken token,
        address flowOperator,
        uint8 permissionsToRemove,
        int96 subtractedFlowRateAllowance,
        bytes memory userData
    ) public {
        token.decreaseFlowRateAllowanceWithPermissions(
            flowOperator, permissionsToRemove, subtractedFlowRateAllowance, userData
        );
    }
}

contract SuperTokenLibraryIDAMock {

    using SuperTokenV1Library for ISuperToken;

    /**************************************************************************
     * View Functions
     *************************************************************************/

    function getIndexTest(ISuperToken token, address publisher, uint32 indexId)
        external view
        returns (
            bool exist,
            uint128 indexValue,
            uint128 totalUnitsApproved,
            uint128 totalUnitsPending
        )
    {
        return token.getIndex(publisher, indexId);
    }

    function calculateDistributionTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        uint256 amount
    )
        external view
        returns (
            uint256 actualAmount,
            uint128 newIndexValue
        )
    {
        return token.calculateDistribution(publisher, indexId, amount);
    }

    function listSubscriptionsTest(ISuperToken token, address subscriber)
        external view
        returns (
            address[] memory publishers,
            uint32[] memory indexIds,
            uint128[] memory unitsList
        )
    {
        return token.listSubscriptions(subscriber);
    }

    function getSubscriptionTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    )
        external view
        returns (
            bool exist,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        return token.getSubscription(publisher, indexId, subscriber);
    }

    /// @dev agreementId == keccak256(abi.encodePacked("subscription", subscriber, indexId));
    function getSubscriptionByIDTest(ISuperToken token, bytes32 agreementId)
        external view
        returns (
            address publisher,
            uint32 indexId,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        return token.getSubscriptionByID(agreementId);
    }

    /**************************************************************************
     * Index Operations
     *************************************************************************/

    function createIndexTest(ISuperToken token, uint32 indexId) external {
        token.createIndex(indexId);
    }

    function createIndexWithUserDataTest(
        ISuperToken token,
        uint32 indexId,
        bytes memory userData
    ) external {
        token.createIndex(indexId, userData);
    }

    function updateIndexValueTest(
        ISuperToken token,
        uint32 indexId,
        uint128 indexValue
    ) external {
        token.updateIndexValue(indexId, indexValue);
    }

    function updateIndexValueWithUserDataTest(
        ISuperToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes memory userData
    ) external {
        token.updateIndexValue(indexId, indexValue, userData);
    }

    function distributeTest(ISuperToken token, uint32 indexId, uint256 amount) external {
        token.distribute(indexId, amount);
    }

    function distributeWithUserDataTest(
        ISuperToken token,
        uint32 indexId,
        uint256 amount,
        bytes memory userData
    ) external {
        token.distribute(indexId, amount, userData);
    }

    /**************************************************************************
     * Subscription Operations
     *************************************************************************/

    function approveSubscriptionTest(
        ISuperToken token,
        address publisher,
        uint32 indexId
    ) external {
        token.approveSubscription(publisher, indexId);
    }

    function approveSubscriptionWithUserDataTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) external {
        token.approveSubscription(publisher, indexId, userData);
    }

    function revokeSubscriptionTest(
        ISuperToken token,
        address publisher,
        uint32 indexId
    ) external {
        token.revokeSubscription(publisher, indexId);
    }

    function revokeSubscriptionWithUserDataTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) external {
        token.revokeSubscription(publisher, indexId, userData);
    }

    function updateSubscriptionUnitsTest(
        ISuperToken token,
        uint32 indexId,
        address subscriber,
        uint128 units
    ) external {
        token.updateSubscriptionUnits(indexId, subscriber, units);
    }

    function updateSubscriptionUnitsWithUserDataTest(
        ISuperToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes memory userData
    ) external {
        token.updateSubscriptionUnits(indexId, subscriber, units, userData);
    }

    function deleteSubscriptionTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) external {
        token.deleteSubscription(publisher, indexId, subscriber);
    }

    function deleteSubscriptionWithUserDataTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) external {
        token.deleteSubscription(publisher, indexId, subscriber, userData);
    }

    function claimTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) external {
        token.claim(publisher, indexId, subscriber);
    }

    function claimWithUserDataTest(
        ISuperToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) external {
        token.claim(publisher, indexId, subscriber, userData);
    }
}

contract SuperTokenLibraryCFASuperAppMock is SuperAppBase {

    using SuperTokenV1Library for ISuperToken;

    // default values for smoke tests
    address internal immutable sender;
    address internal immutable receiver;
    address internal immutable flowOperator;
    ISuperfluid internal host;

    // for selectively testing functions in the same callback
    enum FunctionIndex {
        CREATE_FLOW,
        UPDATE_FLOW,
        DELETE_FLOW,
        CREATE_FLOW_BY_OPERATOR,
        UPDATE_FLOW_BY_OPERATOR,
        DELETE_FLOW_BY_OPERATOR,
        UPDATE_FLOW_OPERATOR_PERMISSIONS,
        AUTHORIZE_FLOW_OPERATOR_WITH_FULL_CONTROL,
        REVOKE_FLOW_OPERATOR_WITH_FULL_CONTROL
    }

    constructor(
        ISuperfluid _host,
        address defaultSender,
        address defaultReceiver,
        address defaultFlowOperator
    ) {
        host = _host;
        sender = defaultSender;
        receiver = defaultReceiver;
        flowOperator = defaultFlowOperator;

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            // SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP |
            SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;

        host.registerAppWithKey(configWord, "");
    }

    function createFlow(ISuperToken token) external {
        token.createFlow(receiver, 1000000000000);
    }

    // literally ONLY for the revokeFlowOperatorWithFullControlWithCtx test.
    function authorizeFlowOperatorWithFullControl(ISuperToken token) external {
        token.setMaxFlowPermissions(flowOperator);
    }

    function processTxAndReturnCtx(ISuperToken token, bytes memory ctx) internal returns (bytes memory updatedCtx) {
        uint8 functionIndex = abi.decode(host.decodeCtx(ctx).userData, (uint8));

        if (functionIndex == uint8(FunctionIndex.CREATE_FLOW))
            return token.createFlowWithCtx(receiver, 1000000000000, ctx);
        else if (functionIndex == uint8(FunctionIndex.UPDATE_FLOW))
            return token.updateFlowWithCtx(receiver, 2000000000000, ctx);
        else if (functionIndex == uint8(FunctionIndex.DELETE_FLOW))
            return token.deleteFlowWithCtx(address(this), receiver, ctx);
        else if (functionIndex == uint8(FunctionIndex.CREATE_FLOW_BY_OPERATOR))
            return token.createFlowFromWithCtx(sender, receiver, 1000000000000, ctx);
        else if (functionIndex == uint8(FunctionIndex.UPDATE_FLOW_BY_OPERATOR))
            return token.updateFlowFromWithCtx(sender, receiver, 2000000000000, ctx);
        else if (functionIndex == uint8(FunctionIndex.DELETE_FLOW_BY_OPERATOR))
            return token.deleteFlowFromWithCtx(sender, receiver, ctx);
        else if (functionIndex == uint8(FunctionIndex.UPDATE_FLOW_OPERATOR_PERMISSIONS))
            return token.setFlowPermissionsWithCtx(
                flowOperator,
                true,
                true,
                true,
                1000000000000,
                ctx
            );
        else if (functionIndex == uint8(FunctionIndex.AUTHORIZE_FLOW_OPERATOR_WITH_FULL_CONTROL))
            return token.setMaxFlowPermissionsWithCtx(flowOperator, ctx);
        else if (functionIndex == uint8(FunctionIndex.REVOKE_FLOW_OPERATOR_WITH_FULL_CONTROL))
            return token.revokeFlowPermissionsWithCtx(flowOperator, ctx);
        else revert("invalid function index");
    }

    function afterAgreementCreated(
        ISuperToken token,
        address,
        bytes32,
        bytes calldata,
        bytes calldata,
        bytes calldata ctx
    ) external override returns (bytes memory newCtx) {
        newCtx = processTxAndReturnCtx(token, ctx);
    }
}

// IDA LIBRARY SUPER APP CALLBACK MOCK
contract SuperTokenLibraryIDASuperAppMock is SuperTokenLibraryIDAMock, SuperAppBase {

    using SuperTokenV1Library for ISuperToken;

    bytes internal constant _MOCK_USER_DATA = abi.encode("oh hello");
    ISuperfluid internal host;

    constructor(ISuperfluid _host) SuperTokenLibraryIDAMock() {
        host = _host;
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
        bytes memory userData = host.decodeCtx(ctx).userData;
        (
            uint8 functionIndex,
            uint32 indexId,
            address publisher,
            address subscriber,
            uint128 units
        ) = abi.decode(userData, (uint8, uint32, address, address, uint128));

        if (functionIndex == uint8(FunctionIndex.CREATE_INDEX)) {
            return token.createIndexWithCtx(indexId, ctx);
        } else if (functionIndex == uint8(FunctionIndex.CREATE_INDEX_USER_DATA)) {
            return token.createIndexWithCtx(indexId, ctx);
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_INDEX)) {
            return token.updateIndexValueWithCtx(indexId, units, ctx);
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_INDEX_USER_DATA)) {
            return token.updateIndexValueWithCtx(indexId, units, ctx);
        } else if (functionIndex == uint8(FunctionIndex.DISTRIBUTE)) {
            return token.distributeWithCtx(indexId, units, ctx);
        } else if (functionIndex == uint8(FunctionIndex.DISTRIBUTE_USER_DATA)) {
            return token.distributeWithCtx(indexId, units, ctx);
        } else if (functionIndex == uint8(FunctionIndex.APROVE_SUBSCRIPTION)) {
            return token.approveSubscriptionWithCtx(publisher, indexId, ctx);
        } else if (functionIndex == uint8(FunctionIndex.APROVE_SUBSCRIPTION_USER_DATA)) {
            return token.approveSubscriptionWithCtx(
                publisher,
                indexId,
                ctx
            );
        } else if (functionIndex == uint8(FunctionIndex.REVOKE_SUBSCRIPTION)) {
            return token.revokeSubscriptionWithCtx(publisher, indexId, ctx);
        } else if (functionIndex == uint8(FunctionIndex.REVOKE_SUBSCRIPTION_USER_DATA)) {
            return token.revokeSubscriptionWithCtx(
                publisher,
                indexId,
                ctx
            );
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_SUBSCRIPTION)) {
            return token.updateSubscriptionUnitsWithCtx(indexId, subscriber, units, ctx);
        } else if (functionIndex == uint8(FunctionIndex.UPDATE_SUBSCRIPTION_USER_DATA)) {
            return token.updateSubscriptionUnitsWithCtx(
                indexId,
                subscriber,
                units,
                ctx
            );
        } else if (functionIndex == uint8(FunctionIndex.DELETE_SUBSCRIPTION)) {
            return token.deleteSubscriptionWithCtx(publisher, indexId, subscriber, ctx);
        } else if (functionIndex == uint8(FunctionIndex.DELETE_SUBSCRIPTION_USER_DATA)) {
            return token.deleteSubscriptionWithCtx(
                publisher,
                indexId,
                subscriber,
                ctx
            );
        } else if (functionIndex == uint8(FunctionIndex.CLAIM)) {
            return token.claimWithCtx(publisher, indexId, subscriber, ctx);
        } else if (functionIndex == uint8(FunctionIndex.CLAIM_USER_DATA)) {
            return token.claimWithCtx(
                publisher,
                indexId,
                subscriber,
                ctx
            );
        } else {
            revert("invalid function index");
        }
    }
}
