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
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions
} from "../superfluid/Superfluid.sol";
import { AgreementMock } from "./AgreementMock.sol";

contract SuperAppMockAux {

    function actionPingAgreement(ISuperfluid host, AgreementMock agreement, uint256 ping, bytes calldata ctx)
        external
    {
        host.callAgreementWithContext(
            agreement,
            abi.encodeCall(
                agreement.pingMe,
                (
                    address(this), // expectedMsgSender
                    ping,
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            ctx);
    }

    function actionCallActionNoop(ISuperfluid host, SuperAppMock app, bytes calldata ctx)
        external
    {
        host.callAppActionWithContext(
            app,
            abi.encodeCall(
                app.actionNoop,
                (new bytes(0))
            ),
            ctx);
    }
}

// The default SuperApp mock that does many tricks
contract SuperAppMock is ISuperApp {

    ISuperfluid private _host;
    SuperAppMockAux private _aux;

    constructor(ISuperfluid host, uint256 configWord, bool doubleRegistration) {
        _host = host;
        _host.registerAppWithKey(configWord, "");
        if (doubleRegistration) {
            _host.registerAppWithKey(configWord, "");
        }
        _aux = new SuperAppMockAux();
    }

    function tryRegisterApp(uint256 configWord) external {
        // @note this is deprecated keeping this here for testing/coverage
        _host.registerApp(configWord);
    }

    function allowCompositeApp(ISuperApp target) external {
        _host.allowCompositeApp(target);
    }

    /*************************************************************************
    * Test App Actions
    **************************************************************************/

    event NoopEvent(
        uint8 appLevel,
        uint8 callType,
        bytes4 agreementSelector);

    function actionNoop(bytes calldata ctx) external requireValidCtx(ctx) returns (bytes memory newCtx) {
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        emit NoopEvent(
            context.appCallbackLevel,
            context.callType,
            context.agreementSelector);
        return ctx;
    }

    function actionExpectMsgSender(address expectedMsgSender, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        assert(context.msgSender == expectedMsgSender);
        emit NoopEvent(
            context.appCallbackLevel,
            context.callType,
            context.agreementSelector);
        return ctx;
    }

    function actionAssert(bytes calldata ctx) external view requireValidCtx(ctx) {
        assert(false);
    }

    function actionRevert(bytes calldata ctx) external view requireValidCtx(ctx) {
        // solhint-disable-next-line reason-string
        revert();
    }

    function actionRevertWithReason(string calldata reason, bytes calldata ctx) external view requireValidCtx(ctx) {
        revert(reason);
    }

    function actionCallAgreementWithoutCtx(bytes calldata ctx) external requireValidCtx(ctx) {
        // this should fail, action should call agreement with ctx
        _host.callAgreement(ISuperAgreement(address(0)), new bytes(0), new bytes(0));
    }

    function actionCallAppActionWithoutCtx(bytes calldata ctx) external requireValidCtx(ctx) {
        // this should fail, action should call agreement with ctx
        _host.callAppAction(ISuperApp(address(0)), new bytes(0));
    }

    function actionAlteringCtx(bytes calldata ctx)
        external view
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        return abi.encode(42);
    }

    function actionReturnEmptyCtx(bytes calldata ctx)
        external view
        requireValidCtx(ctx)
    // solhint-disable-next-line no-empty-blocks
    {
    }

    function actionPingAgreementThroughAux(AgreementMock agreement, uint256 ping, bytes calldata ctx)
        external
        requireValidCtx(ctx)
    {
        // this should fail
        _aux.actionPingAgreement(_host, agreement, ping, ctx);
    }

    function actionCallActionNoopThroughAux(bytes calldata ctx)
        external
        requireValidCtx(ctx)
    {
        // this should fail
        _aux.actionCallActionNoop(_host, this, ctx);
    }

    function actionPingAgreement(AgreementMock agreement, uint256 ping, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        (newCtx, ) = _host.callAgreementWithContext(
            agreement,
            abi.encodeCall(
                agreement.pingMe,
                (
                    address(this), // expectedMsgSender
                    ping,
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            ctx);
    }

    function actionAgreementRevert(AgreementMock agreement, string calldata reason, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        (newCtx, ) = _host.callAgreementWithContext(
            agreement,
            abi.encodeCall(
                agreement.doRevert,
                (
                    reason,
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            ctx);
    }

    function actionCallActionNoop(bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        newCtx = _host.callAppActionWithContext(
            this,
            abi.encodeCall(
                this.actionNoop,
                (new bytes(0))
            ),
            ctx);
    }

    function actionCallActionRevert(string calldata reason, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        newCtx = _host.callAppActionWithContext(
            this,
            abi.encodeCall(
                this.actionRevertWithReason,
                (
                    reason,
                    new bytes(0)
                )
            ),
            ctx);
    }

    function actionCallAgreementWithInvalidCtx(AgreementMock agreement, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        (newCtx, ) = _host.callAgreementWithContext(
            agreement,
            abi.encodeCall(
                agreement.pingMe,
                (
                    address(this), // expectedMsgSender
                    42,
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            abi.encode(42));
    }

    function actionCallActionWithInvalidCtx(string calldata reason, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        newCtx = _host.callAppActionWithContext(
            this,
            abi.encodeCall(
                this.actionRevertWithReason,
                (
                    reason,
                    new bytes(0)
                )
            ),
            abi.encode(42));
    }

    function actionCallBadAction(bytes calldata ctx)
        external
        requireValidCtx(ctx)
    {
        _host.callAppActionWithContext(
            this,
            abi.encodeCall(
                this.actionAlteringCtx,
                (new bytes(0))
            ),
            ctx);
        assert(false);
    }

    function actionCallPayable(bytes calldata ctx) external payable returns (bytes memory newCtx) {
        newCtx = ctx;
    }

    /*************************************************************************
    * Callbacks
    **************************************************************************/

    enum NextCallbackActionType {
        Noop, // 0
        Assert, // 1
        Revert, // 2
        RevertWithReason, // 3
        AlteringCtx, // 4
        BurnGas, // 5
        ReturnEmptyCtx // 6
    }

    struct NextCallbackAction {
        NextCallbackActionType actionType;
        bytes data;
    }

    NextCallbackAction private _nextCallbackAction;

    function setNextCallbackAction(
        NextCallbackActionType actionType,
        bytes calldata data)
        external
    {
        _nextCallbackAction.actionType = actionType;
        _nextCallbackAction.data = data;
    }

    function _executeBeforeCallbackAction()
        private view
        returns (bytes memory cbdata)
    {
        if (_nextCallbackAction.actionType == NextCallbackActionType.Noop) {
            return "Noop";
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.Assert) {
            assert(false);
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.Revert) {
            // solhint-disable-next-line reason-string
            revert();
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.RevertWithReason) {
            revert(abi.decode(_nextCallbackAction.data, (string)));
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.BurnGas) {
            uint256 gasToBurn = abi.decode(_nextCallbackAction.data, (uint256));
            _burnGas(gasToBurn);
        } else assert(false);
    }

    function _executeAfterCallbackAction(bytes memory ctx)
        private
        returns (bytes memory newCtx)
    {
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        if (_nextCallbackAction.actionType == NextCallbackActionType.Noop) {
            emit NoopEvent(
                context.appCallbackLevel,
                context.callType,
                context.agreementSelector);
            return ctx;
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.Assert) {
            assert(false);
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.Revert) {
            // solhint-disable-next-line reason-string
            revert();
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.RevertWithReason) {
            revert(abi.decode(_nextCallbackAction.data, (string)));
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.AlteringCtx) {
            return new bytes(42);
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.BurnGas) {
            uint256 gasToBurn = abi.decode(_nextCallbackAction.data, (uint256));
            _burnGas(gasToBurn);
        } else if (_nextCallbackAction.actionType == NextCallbackActionType.ReturnEmptyCtx) {
            return new bytes(0);
        } else assert(false);
    }

    function beforeAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata ctx
    )
        external view
        requireValidCtx(ctx)
        virtual override
        returns (bytes memory /*cbdata*/)
    {
        return _executeBeforeCallbackAction();
    }

    function afterAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        virtual override
        returns (bytes memory newCtx)
    {
        return _executeAfterCallbackAction(ctx);
    }

    function beforeAgreementUpdated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata ctx
    )
        external view
        requireValidCtx(ctx)
        virtual override
        returns (bytes memory /*cbdata*/)
    {
        return _executeBeforeCallbackAction();
    }

    function afterAgreementUpdated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        virtual override
        returns (bytes memory newCtx)
    {
        return _executeAfterCallbackAction(ctx);
    }

    function beforeAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata ctx
    )
        external view
        requireValidCtx(ctx)
        virtual override
        returns (bytes memory /*cbdata*/)
    {
        return _executeBeforeCallbackAction();
    }

    function afterAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        virtual override
        returns (bytes memory newCtx)
    {
        return _executeAfterCallbackAction(ctx);
    }

    function _burnGas(uint256 gasToBurn) private view {
        uint256 gasStart = gasleft();
        uint256 gasNow = gasleft();
        while ((gasStart - gasNow) < gasToBurn - 1000 /* some margin for other things*/) {
            gasNow = gasleft();
        }
    }

    modifier requireValidCtx(bytes calldata ctx) {
        require(ISuperfluid(msg.sender).isCtxValid(ctx), "AgreementMock: ctx not valid before");
        _;
    }
}

// Bad super app! This one returns empty ctx
contract SuperAppMockReturningEmptyCtx {

    ISuperfluid private _host;

    constructor(ISuperfluid host) {
        _host = host;
        _host.registerAppWithKey(SuperAppDefinitions.APP_LEVEL_FINAL, "");
    }

    function beforeAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external pure
        // solhint-disable-next-line no-empty-blocks
    {
    }

    function afterAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external pure
        // solhint-disable-next-line no-empty-blocks
    {
    }

    function beforeAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external pure
        // solhint-disable-next-line no-empty-blocks
    {
    }

    function afterAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external pure
        // solhint-disable-next-line no-empty-blocks
    {
    }
}

// Bad super app! This one returns invalid ctx
contract SuperAppMockReturningInvalidCtx {

    ISuperfluid private _host;

    constructor(ISuperfluid host) {
        _host = host;
        _host.registerAppWithKey(SuperAppDefinitions.APP_LEVEL_FINAL, "");
    }

    function afterAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external pure
        returns (uint256)
    {
        return 42;
    }

    function afterAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external pure
        returns (uint256)
    {
        return 42;
    }
}

// Bad super app! A second level app that calls other app
contract SuperAppMock2ndLevel {

    ISuperfluid private _host;
    SuperAppMock private _app;
    AgreementMock private _agreement;

    constructor(ISuperfluid host, SuperAppMock app, AgreementMock agreement) {
        _host = host;
        _host.registerAppWithKey(SuperAppDefinitions.APP_LEVEL_SECOND, "");
        _app = app;
        _agreement = agreement;
    }

    function allowCompositeApp() external {
        _host.allowCompositeApp(_app);
    }

    function afterAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx)
    {
        (newCtx, ) = _host.callAgreementWithContext(
            _agreement,
            abi.encodeCall(
                _agreement.callAppAfterAgreementCreatedCallback,
                (
                    _app,
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            ctx);
    }
}

// An Super App that uses registerAppWithKey
contract SuperAppMockWithRegistrationKey {
    constructor(ISuperfluid host, uint256 configWord, string memory registrationKey) {
        host.registerAppWithKey(configWord, registrationKey);
    }
}

// An Super App that uses registerAppWithKey
contract SuperAppMockUsingRegisterApp {
    constructor(ISuperfluid host, uint256 configWord) {
        // @note this is deprecated keeping this here for testing/coverage
        host.registerApp(configWord);
    }
}

// minimal fake SuperApp contract
// solhint-disable-next-line no-empty-blocks
contract SuperAppMockNotSelfRegistering { }

// Factory which allows anybody to deploy arbitrary contracts as app (do NOT allow this in a real factory!)
contract SuperAppFactoryMock {
    function registerAppWithHost(ISuperfluid host, ISuperApp app, uint256 configWord) external {
        host.registerAppByFactory(app, configWord);
    }
}
