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
 * @title Multi Flow tester App (MFA)
 * @author Superfluid
 * @dev A super app that can split incoming flows to multiple outgoing flows.
 *      This is used for testing CFA callbacks logic.
 */
contract MultiFlowTesterApp is SuperAppBase {

    struct ReceiverData {
        address to;
        uint256 proportion;
    }

    struct Configuration {
        uint8 ratioPct;
        ReceiverData[] receivers;
    }

    IConstantFlowAgreementV1 private _cfa;
    ISuperfluid private _host;

    constructor(IConstantFlowAgreementV1 cfa, ISuperfluid superfluid) {
        assert(address(cfa) != address(0));
        assert(address(superfluid) != address(0));
        _cfa = cfa;
        _host = superfluid;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        _host.registerAppWithKey(configWord, "");
    }

    function _parseUserData(
        bytes memory userData
    )
        private pure
        returns (address sender, Configuration memory configuration)
    {
        // parse user data
        uint8 ratioPct;
        address[] memory receivers;
        uint256[] memory proportions;
        (sender, ratioPct, receivers, proportions) = abi.decode(
            userData, (address, uint8, address[], uint256[]));
        assert(receivers.length == proportions.length);

        configuration.ratioPct = ratioPct;
        configuration.receivers = new ReceiverData[](receivers.length);
        for (uint256 i = 0; i < receivers.length; ++i) {
            assert(proportions[i] != 0);
            configuration.receivers[i] = ReceiverData(receivers[i], proportions[i]);
        }
    }

    function _sumProportions(ReceiverData[] memory receivers) internal pure returns(uint256 sum) {
        for (uint256 i = 0; i < receivers.length; ++i) {
            sum += receivers[i].proportion;
        }
    }

    function _updateMultiFlow(
        Configuration memory configuration,
        ISuperToken superToken,
        bytes4 selector,
        int96 flowRate,
        uint256 appCreditGranted,
        bytes calldata ctx
    )
        private
        returns (bytes memory newCtx)
    {
        uint256 sum = _sumProportions(configuration.receivers);

        newCtx = ctx;

        // in case of mfa, we underutlize the app credit for simplicity
        uint256 flowRateDeposit = _cfa.getDepositRequiredForFlowRate(superToken, flowRate);
        int96 safeFlowRate = _cfa.getMaximumFlowRateFromDeposit(superToken, flowRateDeposit - 1);
        appCreditGranted = _cfa.getDepositRequiredForFlowRate(superToken, safeFlowRate);

        // scale the flow rate and app credit numbers
        appCreditGranted = appCreditGranted * configuration.ratioPct / 100;
        // NOTE casting to int96 is okay here because ratioPct is uint8
        flowRate = flowRate * int96(uint96(configuration.ratioPct)) / 100;

        for (uint256 i = 0; i < configuration.receivers.length; ++i) {
            ReceiverData memory receiverData = configuration.receivers[i];
            uint256 targetCredit = appCreditGranted * receiverData.proportion / sum;
            int96 targetFlowRate = _cfa.getMaximumFlowRateFromDeposit(
                superToken,
                targetCredit
            );
            flowRate -= targetFlowRate;
            bytes memory callData = abi.encodeWithSelector(
                selector,
                superToken,
                receiverData.to,
                targetFlowRate,
                new bytes(0)
            );
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                callData,
                new bytes(0), // user data
                newCtx
            );
        }
        assert(flowRate >= 0);
    }

    // this function is for testing purpose
    function createFlow(
        ISuperToken superToken,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx)
    {
        bytes memory callData = abi.encodeCall(
            _cfa.createFlow,
            (
                superToken,
                receiver,
                flowRate,
                new bytes(0)
            )
        );
        (newCtx, ) = _host.callAgreementWithContext(
            _cfa,
            callData,
            new bytes(0), // user data
            ctx
        );
    }

    struct StackVars {
    	ISuperfluid.Context context;
        address mfaSender;
        Configuration configuration;
        address flowSender;
        address flowReceiver;
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns(bytes memory newCtx)
    {
        assert(agreementClass == address(_cfa));
        StackVars memory vars;

        vars.context = _host.decodeCtx(ctx);
        // parse user data
        (vars.mfaSender, vars.configuration) = _parseUserData(vars.context.userData);
        // validate the context
        {
            (vars.flowSender, vars.flowReceiver) = abi.decode(agreementData, (address, address));
            assert(vars.flowSender == vars.context.msgSender);
            assert(vars.flowReceiver == address(this));
            assert(vars.context.appCreditGranted > 0);
        }
        int96 flowRate;
        (,flowRate,,) = _cfa.getFlowByID(superToken, agreementId);
        newCtx = _updateMultiFlow(
            vars.configuration,
            superToken,
            _cfa.createFlow.selector,
            flowRate,
            vars.context.appCreditGranted,
            ctx);
    }

    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external view override
        onlyHost
        returns (bytes memory cbdata)
    {
        assert(agreementClass == address(_cfa));
        (, int256 oldFlowRate, ,) = _cfa.getFlowByID(superToken, agreementId);
        return abi.encode(oldFlowRate);
    }

    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata /* cbdata */,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        assert(agreementClass == address(_cfa));
        StackVars memory vars;

        vars.context = _host.decodeCtx(ctx);
        // parse user data
        (vars.mfaSender, vars.configuration) = _parseUserData(vars.context.userData);
        // validate the context
        {
            (vars.flowSender, vars.flowReceiver) = abi.decode(agreementData, (address, address));
            assert(vars.flowSender == vars.context.msgSender);
            assert(vars.flowReceiver == address(this));
            assert(vars.context.appCreditGranted > 0);
        }
        int96 flowRate;
        (,flowRate,,) = _cfa.getFlowByID(superToken, agreementId);
        newCtx = _updateMultiFlow(
            vars.configuration,
            superToken,
            _cfa.updateFlow.selector,
            flowRate,
            vars.context.appCreditGranted,
            ctx);
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata agreementData,
        bytes calldata /*cbdata*/,
        bytes calldata ctx
    )

        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        assert(agreementClass == address(_cfa));
        StackVars memory vars;

        vars.context = _host.decodeCtx(ctx);

        // parse user data
        (vars.mfaSender, vars.configuration) = _parseUserData(vars.context.userData);
        // validate the context
        (vars.flowSender, vars.flowReceiver) = abi.decode(agreementData, (address, address));
        assert(vars.flowSender == address(this) || vars.flowReceiver == address(this));

        bytes memory callData;
        newCtx = ctx;
        if (vars.flowReceiver == address(this)) {
            for (uint256 i = 0; i < vars.configuration.receivers.length; ++i) {
                callData = abi.encodeCall(
                    _cfa.deleteFlow,
                    (
                        superToken,
                        address(this),
                        vars.configuration.receivers[i].to,
                        new bytes(0) //placeholder ctx
                    )
                );
                (newCtx, ) = _host.callAgreementWithContext(
                    _cfa,
                    callData,
                    new bytes(0), // user data
                    newCtx
                );
            }
        } else /* if (vars.flowSender == address(this)) */ {
            for (uint256 i = 0; i < vars.configuration.receivers.length; ++i) {
                // skip current closed flow
                if (vars.configuration.receivers[i].to == vars.flowReceiver) continue;
                // close the rest of the mfa receiver flows
                callData = abi.encodeCall(
                    _cfa.deleteFlow,
                    (
                        superToken,
                        address(this),
                        vars.configuration.receivers[i].to,
                        new bytes(0) //placeholder ctx
                    )
                );
                (newCtx, ) = _host.callAgreementWithContext(
                    _cfa,
                    callData,
                    new bytes(0), // user data
                    newCtx
                );
            }
            // close the mfa sender flow
            callData = abi.encodeCall(
                _cfa.deleteFlow,
                (
                    superToken,
                    vars.mfaSender,
                    address(this),
                    new bytes(0) //placeholder ctx
                )
            );
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                callData,
                new bytes(0), // user data
                newCtx
            );
        }
    }

    modifier onlyHost() {
        assert(msg.sender == address(_host));
        _;
    }
}
