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
    ISuperfluidToken,
    ISuperApp,
    SuperAppDefinitions
} from "../interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidToken } from "../interfaces/superfluid/ISuperfluidToken.sol";

import { SafeCast } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeCast.sol";


/**
 * @title Agreement Library
 * @author Superfluid
 * @dev Helper library for building super agreement
 */
library AgreementLibrary {

    using SafeCast for uint256;
    using SafeCast for int256;

    /**************************************************************************
     * Context helpers
     *************************************************************************/

    /**
     * @dev Authorize the msg.sender to access token agreement storage
     *
     * NOTE:
     * - msg.sender must be the expected host contract.
     * - it should revert on unauthorized access.
     */
    function authorizeTokenAccess(ISuperfluidToken token, bytes memory ctx)
        internal view
        returns (ISuperfluid.Context memory)
    {
        require(token.getHost() == msg.sender, "unauthorized host");
        require(ISuperfluid(msg.sender).isCtxValid(ctx), "invalid ctx");
        // [SECURITY] NOTE: we are holding the assumption here that the decoded ctx is correct
        // at this point.
        return ISuperfluid(msg.sender).decodeCtx(ctx);
    }

    /**************************************************************************
     * Agreement callback helpers
     *************************************************************************/

    struct CallbackInputs {
        ISuperfluidToken token;
        address account;
        bytes32 agreementId;
        bytes agreementData;
        uint256 appCreditGranted;
        int256 appCreditUsed;
        uint256 noopBit;
    }

    function createCallbackInputs(
        ISuperfluidToken token,
        address account,
        bytes32 agreementId,
        bytes memory agreementData
    )
       internal pure
       returns (CallbackInputs memory inputs)
    {
        inputs.token = token;
        inputs.account = account;
        inputs.agreementId = agreementId;
        inputs.agreementData = agreementData;
    }

    function callAppBeforeCallback(
        CallbackInputs memory inputs,
        bytes memory ctx
    )
        internal
        returns(bytes memory cbdata)
    {
        bool isSuperApp;
        bool isJailed;
        uint256 noopMask;
        (isSuperApp, isJailed, noopMask) = ISuperfluid(msg.sender).getAppManifest(ISuperApp(inputs.account));
        if (isSuperApp && !isJailed) {
            bytes memory appCtx = _pushCallbackStack(ctx, inputs);
            if ((noopMask & inputs.noopBit) == 0) {
                bytes memory callData = abi.encodeWithSelector(
                    _selectorFromNoopBit(inputs.noopBit),
                    inputs.token,
                    address(this) /* agreementClass */,
                    inputs.agreementId,
                    inputs.agreementData,
                    new bytes(0) // placeholder ctx
                );
                cbdata = ISuperfluid(msg.sender).callAppBeforeCallback(
                    ISuperApp(inputs.account),
                    callData,
                    inputs.noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP,
                    appCtx);
            }
            // [SECURITY] NOTE: ctx should be const, do not modify it ever to ensure callback stack correctness
            _popCallbackStack(ctx, 0);
        }
    }

    function callAppAfterCallback(
        CallbackInputs memory inputs,
        bytes memory cbdata,
        bytes /* const */ memory ctx
    )
        internal
        returns (ISuperfluid.Context memory appContext, bytes memory newCtx)
    {
        bool isSuperApp;
        bool isJailed;
        uint256 noopMask;
        (isSuperApp, isJailed, noopMask) = ISuperfluid(msg.sender).getAppManifest(ISuperApp(inputs.account));

        newCtx = ctx;
        if (isSuperApp && !isJailed) {
            newCtx = _pushCallbackStack(newCtx, inputs);
            if ((noopMask & inputs.noopBit) == 0) {
                bytes memory callData = abi.encodeWithSelector(
                    _selectorFromNoopBit(inputs.noopBit),
                    inputs.token,
                    address(this) /* agreementClass */,
                    inputs.agreementId,
                    inputs.agreementData,
                    cbdata,
                    new bytes(0) // placeholder ctx
                );
                newCtx = ISuperfluid(msg.sender).callAppAfterCallback(
                    ISuperApp(inputs.account),
                    callData,
                    inputs.noopBit == SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP,
                    newCtx);

                appContext = ISuperfluid(msg.sender).decodeCtx(newCtx);

                // adjust credit used to the range [appCreditUsed..appCreditGranted]
                appContext.appCreditUsed = _adjustNewAppCreditUsed(
                    inputs.appCreditGranted,
                    appContext.appCreditUsed
                );
            }
            // [SECURITY] NOTE: ctx should be const, do not modify it ever to ensure callback stack correctness
            newCtx = _popCallbackStack(ctx, appContext.appCreditUsed);
        }
    }

    /**
     * @dev Determines how much app credit the app will use.
     * @param appCreditGranted set prior to callback based on input flow
     * @param appCallbackDepositDelta set in callback - sum of deposit deltas of callback agreements and
     * current flow owed deposit amount
     */
    function _adjustNewAppCreditUsed(
        uint256 appCreditGranted,
        int256 appCallbackDepositDelta
    ) internal pure returns (int256) {
        // NOTE: we use max(0, ...) because appCallbackDepositDelta can be negative and appCallbackDepositDelta
        // should never go below 0, otherwise the SuperApp can return more money than borrowed
        return max(
            0,

            // NOTE: we use min(appCreditGranted, appCallbackDepositDelta) to ensure that the SuperApp borrows
            // appCreditGranted at most and appCallbackDepositDelta at least (if smaller than appCreditGranted)
            min(
                appCreditGranted.toInt256(),
                appCallbackDepositDelta
            )
        );
    }

    function _selectorFromNoopBit(uint256 noopBit)
        private pure
        returns (bytes4 selector)
    {
        if (noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP) {
            return ISuperApp.beforeAgreementCreated.selector;
        } else if (noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP) {
            return ISuperApp.beforeAgreementUpdated.selector;
        } else if (noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP) {
            return ISuperApp.beforeAgreementTerminated.selector;
        } else if (noopBit == SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP) {
            return ISuperApp.afterAgreementCreated.selector;
        } else if (noopBit == SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP) {
            return ISuperApp.afterAgreementUpdated.selector;
        } else /* if (noopBit == SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP) */ {
            return ISuperApp.afterAgreementTerminated.selector;
        }
    }

    function _pushCallbackStack(
        bytes memory ctx,
        CallbackInputs memory inputs
    )
        private
        returns (bytes memory appCtx)
    {
        // app credit params stack PUSH
        // pass app credit and current credit used to the app,
        appCtx = ISuperfluid(msg.sender).appCallbackPush(
            ctx,
            ISuperApp(inputs.account),
            inputs.appCreditGranted,
            inputs.appCreditUsed,
            inputs.token);
    }

    function _popCallbackStack(
        bytes memory ctx,
        int256 appCreditUsedDelta
    )
        private
        returns (bytes memory newCtx)
    {
        // app credit params stack POP
        return ISuperfluid(msg.sender).appCallbackPop(ctx, appCreditUsedDelta);
    }

    /**************************************************************************
     * Misc
     *************************************************************************/

    function max(int256 a, int256 b) internal pure returns (int256) { return a > b ? a : b; }
    function max(uint256 a, uint256 b) internal pure returns (uint256) { return a > b ? a : b; }

    function min(int256 a, int256 b) internal pure returns (int256) { return a > b ? b : a; }
}
