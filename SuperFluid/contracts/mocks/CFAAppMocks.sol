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
    SuperAppBase,
    SuperAppDefinitions,
    IConstantFlowAgreementV1
} from "../apps/SuperAppBase.sol";

/**
 * @dev This is a CFA SuperApp that maintains at most one inflow from a sender at any moment.
 *
 * This can test the deposit credit logic in the deleteFlow as a recipient.
 */
contract ExclusiveInflowTestApp is SuperAppBase {

    IConstantFlowAgreementV1 private _cfa;
    ISuperfluid private _host;
    address private _currentSender;

    constructor(IConstantFlowAgreementV1 cfa, ISuperfluid superfluid) {
        assert(address(cfa) != address(0));
        assert(address(superfluid) != address(0));
        _cfa = cfa;
        _host = superfluid;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL
            | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP
            // | SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
            // | SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP
            ;

        _host.registerAppWithKey(configWord, "");
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        newCtx = ctx;
        ISuperfluid.Context memory context = _host.decodeCtx(ctx);
        if (_currentSender != address(0)) {
            bytes memory callData = abi.encodeCall(
                _cfa.deleteFlow,
                (
                    superToken,
                    _currentSender,
                    address(this),
                    new bytes(0)
                )
            );
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                callData,
                new bytes(0), // user data
                newCtx
            );
        }
        _currentSender = context.msgSender;
    }

    function afterAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        (address flowSender, ) = abi.decode(agreementData, (address, address));
        assert(flowSender == _currentSender);
        _currentSender = address(0);
        return ctx;
    }

}

/**
 * @dev This is CFA SuperApp that refuses to close its outflow by its receiver.
 *
 * This test the logic that the app re-opens the same stream in the termination callback.
 * In reality, the app would have to fund the app with enough tokens to not to be jailed due
 * to low balance.
 */
contract NonClosableOutflowTestApp is SuperAppBase {

    IConstantFlowAgreementV1 private _cfa;
    ISuperfluid private _host;
    address private _receiver;
    int96 private _flowRate;

    constructor(IConstantFlowAgreementV1 cfa, ISuperfluid superfluid) {
        assert(address(cfa) != address(0));
        assert(address(superfluid) != address(0));
        _cfa = cfa;
        _host = superfluid;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL
            | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
            // | SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP
            ;

        _host.registerAppWithKey(configWord, "");
    }

    function setupOutflow(
        ISuperToken superToken,
        address receiver,
        int96 flowRate
    )
        external
    {
        _receiver = receiver;
        _flowRate = flowRate;
        _host.callAgreement(
            _cfa,
            abi.encodeCall(
                _cfa.createFlow,
                (
                    superToken,
                    receiver,
                    flowRate,
                    new bytes(0)
                )
            ),
            new bytes(0) // user data
        );
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        (address flowSender, address flowReceiver) = abi.decode(agreementData, (address, address));
        assert(flowSender == address(this));
        assert(flowReceiver == _receiver);

        // moved out to avoid stack too deep error
        bytes memory callData = abi.encodeCall(
            _cfa.createFlow,
            (
                superToken,
                flowReceiver,
                _flowRate,
                new bytes(0)
            )
        );

        // recreate the flow
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            callData,
            "0x",
            ctx
        );
    }
}

/**
 * @dev This is CFA SuperApp that refuses to accept any opening flow without reverting them.
 */
contract SelfDeletingFlowTestApp is SuperAppBase {

    IConstantFlowAgreementV1 private _cfa;
    ISuperfluid private _host;
    address private _receiver;
    int96 private _flowRate;

    constructor(IConstantFlowAgreementV1 cfa, ISuperfluid superfluid) {
        assert(address(cfa) != address(0));
        assert(address(superfluid) != address(0));
        _cfa = cfa;
        _host = superfluid;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL
            | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP
            // | SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP
            ;

        _host.registerAppWithKey(configWord, "");
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        newCtx = ctx;
        ISuperfluid.Context memory context = _host.decodeCtx(ctx);
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeCall(
                _cfa.deleteFlow,
                (
                    superToken,
                    context.msgSender,
                    address(this),
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            newCtx
        );
    }
}

/**
 * @dev This is CFA SuperApp that closes an updated flow.
 */
contract ClosingOnUpdateFlowTestApp is SuperAppBase {

    IConstantFlowAgreementV1 private _cfa;
    ISuperfluid private _host;

    constructor(IConstantFlowAgreementV1 cfa, ISuperfluid superfluid) {
        assert(address(cfa) != address(0));
        assert(address(superfluid) != address(0));
        _cfa = cfa;
        _host = superfluid;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL
            | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP
            // | SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP
            ;

        _host.registerAppWithKey(configWord, "");
    }

    function afterAgreementUpdated(
        ISuperToken superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        newCtx = ctx;
        ISuperfluid.Context memory context = _host.decodeCtx(ctx);
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeCall(
                _cfa.deleteFlow,
                (
                    superToken,
                    context.msgSender,
                    address(this),
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            newCtx
        );
    }
}

contract FlowExchangeTestApp is SuperAppBase {

    IConstantFlowAgreementV1 private _cfa;
    ISuperfluid private _host;
    ISuperToken private _targetToken;

    constructor(
        IConstantFlowAgreementV1 cfa,
        ISuperfluid superfluid,
        ISuperToken targetToken) {
        assert(address(cfa) != address(0));
        assert(address(superfluid) != address(0));
        _cfa = cfa;
        _host = superfluid;
        _targetToken = targetToken;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL
            | SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP
            // | SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP
            | SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP
            | SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP
            ;

        _host.registerAppWithKey(configWord, "");
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        newCtx = ctx;
        ISuperfluid.Context memory context = _host.decodeCtx(ctx);
        (,int96 flowRate,,) = _cfa.getFlow(superToken, context.msgSender, address(this));
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            abi.encodeCall(
                _cfa.createFlow,
                (
                    _targetToken,
                    context.msgSender,
                    flowRate,
                    new bytes(0)
                )
            ),
            new bytes(0), // user data
            newCtx
        );
    }
}
