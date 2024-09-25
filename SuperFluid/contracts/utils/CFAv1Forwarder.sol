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
    FlowOperatorDefinitions,
    IConstantFlowAgreementV1
} from "../interfaces/superfluid/ISuperfluid.sol";
import { ForwarderBase } from "./ForwarderBase.sol";


/**
 * @title CFAv1Forwarder
 * @author Superfluid
 * The CFAv1Forwarder contract provides an easy to use interface to
 * ConstantFlowAgreementV1 specific functionality of Super Tokens.
 * Instances of this contract can operate on the protocol only if configured as "trusted forwarder"
 * by protocol governance.
 */
contract CFAv1Forwarder is ForwarderBase {
    error CFA_FWD_INVALID_FLOW_RATE();

    IConstantFlowAgreementV1 internal immutable _cfa;

    // is tied to a specific instance of host and agreement contracts at deploy time
    constructor(ISuperfluid host) ForwarderBase(host) {
        _cfa = IConstantFlowAgreementV1(address(_host.getAgreementClass(
            keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
        )));
    }

    /**
     * @notice Sets the given flowrate between msg.sender and a given receiver.
     * If there's no pre-existing flow and `flowrate` non-zero, a new flow is created.
     * If there's an existing flow and `flowrate` non-zero, the flowrate of that flow is updated.
     * If there's an existing flow and `flowrate` zero, the flow is deleted.
     * If the existing and given flowrate are equal, no action is taken.
     * On creation of a flow, a "buffer" amount is automatically detracted from the sender account's available balance.
     * If the sender account is solvent when the flow is deleted, this buffer is redeemed to it.
     * @param token Super token address
     * @param receiver The receiver of the flow
     * @param flowrate The wanted flowrate in wad/second. Only positive values are valid here.
     * @return bool
     */
    function setFlowrate(ISuperToken token, address receiver, int96 flowrate) external returns (bool) {
       return _setFlowrateFrom(token, msg.sender, receiver, flowrate);
    }

    /**
     * @notice Like `setFlowrate`, but can be invoked by an account with flowOperator permissions
     * on behalf of the sender account.
     * @param token Super token address
     * @param sender The sender of the flow
     * @param receiver The receiver of the flow
     * @param flowrate The wanted flowrate in wad/second. Only positive values are valid here.
     * @return bool
     */
    function setFlowrateFrom(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowrate
    ) external returns (bool) {
        return _setFlowrateFrom(token, sender, receiver, flowrate);
    }

    /**
     * @notice Get the flowrate of the flow between 2 accounts if exists.
     * @dev Currently, only 0 or 1 flows can exist between 2 accounts. This may change in the future.
     * @param token Super token address
     * @param sender The sender of the flow
     * @param receiver The receiver of the flow
     * @return flowrate The flowrate from the sender to the receiver account. Returns 0 if no flow exists.
     */
    function getFlowrate(ISuperToken token, address sender, address receiver) external view
        returns(int96 flowrate)
    {
        (, flowrate, , ) = _cfa.getFlow(token, sender, receiver);
    }

    /**
     * @notice Get all available information about a flow (if exists).
     * If only the flowrate is needed, consider using `getFlowrate` instead.
     * @param token Super token address
     * @param sender The sender of the flow
     * @param receiver The receiver of the flow
     * @return lastUpdated Timestamp of last update (flowrate change) or zero if no flow exists
     * @return flowrate Current flowrate of the flow or zero if no flow exists
     * @return deposit Deposit amount locked as security buffer during the lifetime of the flow
     * @return owedDeposit Extra deposit amount borrowed to a SuperApp receiver by the flow sender
     */
    function getFlowInfo(ISuperToken token, address sender, address receiver) external view
        returns(uint256 lastUpdated, int96 flowrate, uint256 deposit, uint256 owedDeposit)
    {
        (lastUpdated, flowrate, deposit, owedDeposit) = _cfa.getFlow(token, sender, receiver);
    }

    /**
     * @notice Get the buffer amount required for the given token and flowrate.
     * This amount can vary based on the combination of token, flowrate and chain being queried.
     * The result for a given set of parameters can change over time,
     * because it depends on governance configurable protocol parameters.
     * Changes of the required buffer amount affect only flows created or updated after the change.
     * @param token Super token address
     * @param flowrate The flowrate for which the buffer amount is calculated
     * @return bufferAmount The buffer amount required for the given configuration.
     */
    function getBufferAmountByFlowrate(ISuperToken token, int96 flowrate) external view
        returns (uint256 bufferAmount)
    {
        return _cfa.getDepositRequiredForFlowRate(token, flowrate);
    }

    /**
     * @notice Get the net flowrate of an account.
     * @param token Super token address
     * @param account Account to query
     * @return flowrate The net flowrate (aggregate incoming minus aggregate outgoing flowrate), can be negative.
     */
    function getAccountFlowrate(ISuperToken token, address account) external view
        returns (int96 flowrate)
    {
        return _cfa.getNetFlow(token, account);
    }

    /**
     * @notice Get aggregated flow information (if any exist) of an account.
     * If only the net flowrate is needed, consider using `getAccountFlowrate` instead.
     * @param token Super token address
     * @param account Account to query
     * @return lastUpdated Timestamp of last update of a flow to or from the account (flowrate change)
     * @return flowrate Current net aggregate flowrate
     * @return deposit Aggregate deposit amount currently locked as security buffer for outgoing flows
     * @return owedDeposit Aggregate extra deposit amount currently borrowed to SuperApps receiving from this account
     */
    function getAccountFlowInfo(ISuperToken token, address account) external view
        returns (uint256 lastUpdated, int96 flowrate, uint256 deposit, uint256 owedDeposit)
    {
        return _cfa.getAccountFlowInfo(token, account);
    }

    /**
     * @notice Low-level wrapper of createFlow/createFlowByOperator.
     * If the address of msg.sender is not the same as the address of the `sender` argument,
     * createFlowByOperator is used internally. In this case msg.sender needs to have permission to create flows
     * on behalf of the given sender account with sufficient flowRateAllowance.
     * Currently, only 1 flow can exist between 2 accounts, thus `createFlow` will fail if one already exists.
     * @param token Super token address
     * @param sender Sender address of the flow
     * @param receiver Receiver address of the flow
     * @param flowrate The flowrate in wad/second to be set initially
     * @param userData (optional) User data to be set. Should be set to zero if not needed.
     * @return bool
     */
    function createFlow(ISuperToken token, address sender, address receiver, int96 flowrate, bytes memory userData)
        external returns (bool)
    {
        return _createFlow(token, sender, receiver, flowrate, userData);
    }

    /**
     * @notice Low-level wrapper if updateFlow/updateFlowByOperator.
     * If the address of msg.sender doesn't match the address of the `sender` argument,
     * updateFlowByOperator is invoked. In this case msg.sender needs to have permission to update flows
     * on behalf of the given sender account with sufficient flowRateAllowance.
     * @param token Super token address
     * @param sender Sender address of the flow
     * @param receiver Receiver address of the flow
     * @param flowrate The flowrate in wad/second the flow should be updated to
     * @param userData (optional) User data to be set. Should be set to zero if not needed.
     * @return bool
     */
    function updateFlow(ISuperToken token, address sender, address receiver, int96 flowrate, bytes memory userData)
        external returns (bool)
    {
        return _updateFlow(token, sender, receiver, flowrate, userData);
    }

    /**
     * @notice Low-level wrapper of deleteFlow/deleteFlowByOperator.
     * If msg.sender isn't the same as sender address, msg.sender needs to have permission
     * to delete flows on behalf of the given sender account.
     * @param token Super token address
     * @param sender Sender address of the flow
     * @param receiver Receiver address of the flow
     * @param userData (optional) User data to be set. Should be set to zero if not needed.
     * @return bool
     */
    function deleteFlow(
        ISuperToken token,
        address sender,
        address receiver,
        bytes memory userData
    )
        external returns (bool)
    {
        return _deleteFlow(token, sender, receiver, userData);
    }

    /**
     * @notice Grants a flowOperator permission to create/update/delete flows on behalf of msg.sender.
     * In order to restrict what a flowOperator can or can't do, the flowOperator account
     * should be a contract implementing the desired restrictions.
     * @param token Super token address
     * @param flowOperator Account to which permissions are granted
     * @return bool
     */
    function grantPermissions(ISuperToken token, address flowOperator) external returns (bool)
    {
        return _updateFlowOperatorPermissions(
            token,
            flowOperator,
            FlowOperatorDefinitions.AUTHORIZE_FULL_CONTROL,
            type(int96).max
        );
    }

    /**
     * @notice Revokes all permissions previously granted to a flowOperator by msg.sender.
     * Revocation doesn't undo or reset flows previously created/updated by the flowOperator.
     * In order to be sure about the state of flows at the time of revocation, you need to check that state
     * either in the same transaction or after this transaction.
     * @param token Super token address
     * @param flowOperator Account from which permissions are revoked
     * @return bool
     */
    function revokePermissions(ISuperToken token, address flowOperator) external returns (bool)
    {
        return _updateFlowOperatorPermissions(
            token,
            flowOperator,
            0,
            0
        );
    }

    /**
     * @notice Low-level wrapper of `IConstantFlowAgreementV1.updateFlowOperatorPermissions`
     * @param token Super token address
     * @param flowOperator Account for which permissions are set on behalf of msg.sender
     * @param permissions Bitmask for create/update/delete permission flags. See library `FlowOperatorDefinitions`
     * @param flowrateAllowance Max. flowrate in wad/second the operator can set for individual flows.
     * @return bool
     * @notice flowrateAllowance does NOT restrict the net flowrate a flowOperator is able to set.
     * In order to restrict that, flowOperator needs to be a contract implementing the wanted limitations.
     */
    function updateFlowOperatorPermissions(
        ISuperToken token,
        address flowOperator,
        uint8 permissions,
        int96 flowrateAllowance
    )
        external returns (bool)
    {
        return _updateFlowOperatorPermissions(token, flowOperator, permissions, flowrateAllowance);
    }

    /**
     * @notice Get the currently set permissions granted to the given flowOperator by the given sender account.
     * @param token Super token address
     * @param sender The account which (possiby) granted permissions
     * @param flowOperator Account to which (possibly) permissions were granted
     * @return permissions A bitmask of the permissions currently granted (or not) by `sender` to `flowOperator`
     * @return flowrateAllowance Max. flowrate in wad/second the flowOperator can set for individual flows.
     */
    function getFlowOperatorPermissions(ISuperToken token, address sender, address flowOperator) external view
        returns (uint8 permissions, int96 flowrateAllowance)
    {
        (, permissions, flowrateAllowance) = _cfa.getFlowOperatorData(token, sender, flowOperator);
    }

    /**************************************************************************
     * Internal functions
     *************************************************************************/

    function _setFlowrateFrom(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowrate
    ) internal returns (bool) {
        (, int96 prevFlowRate,,) = _cfa.getFlow(token, sender, receiver);

        if (flowrate > 0) {
            if (prevFlowRate == 0) {
                return _createFlow(token, sender, receiver, flowrate, new bytes(0));
            } else if (prevFlowRate != flowrate) {
                return _updateFlow(token, sender, receiver, flowrate, new bytes(0));
            } // else no change, do nothing
            return true;
        } else if (flowrate == 0) {
            if (prevFlowRate > 0) {
                return _deleteFlow(token, sender, receiver, new bytes(0));
            } // else no change, do nothing
            return true;
        } else {
            revert CFA_FWD_INVALID_FLOW_RATE();
        }
    }

    function _createFlow(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowrate,
        bytes memory userData
    )
        internal returns (bool)
    {
        bytes memory cfaCallData = sender == msg.sender ?
            abi.encodeCall(
                _cfa.createFlow,
                (
                    token,
                    receiver,
                    flowrate,
                    new bytes(0) // placeholder
                )
            ) :
            abi.encodeCall(
                _cfa.createFlowByOperator,
                (
                    token,
                    sender,
                    receiver,
                    flowrate,
                    new bytes(0) // placeholder
                )
            );

        return _forwardBatchCall(address(_cfa), cfaCallData, userData);
    }

    function _updateFlow(
        ISuperToken token,
        address sender,
        address receiver,
        int96 flowrate,
        bytes memory userData
    )
        internal returns (bool)
    {
        bytes memory cfaCallData = sender == msg.sender ?
            abi.encodeCall(
                _cfa.updateFlow,
                (
                    token,
                    receiver,
                    flowrate,
                    new bytes(0) // placeholder
                )
            ) :
            abi.encodeCall(
                _cfa.updateFlowByOperator,
                (
                    token,
                    sender,
                    receiver,
                    flowrate,
                    new bytes(0) // placeholder
                )
            );

        return _forwardBatchCall(address(_cfa), cfaCallData, userData);
    }

    function _deleteFlow(
        ISuperToken token,
        address sender,
        address receiver,
        bytes memory userData
    )
        internal returns (bool)
    {
        bytes memory cfaCallData = sender == msg.sender || receiver == msg.sender ?
            abi.encodeCall(
                _cfa.deleteFlow,
                (
                    token,
                    sender,
                    receiver,
                    new bytes(0) // placeholder
                )
            ) :
            abi.encodeCall(
                _cfa.deleteFlowByOperator,
                (
                    token,
                    sender,
                    receiver,
                    new bytes(0) // placeholder
                )
            );

        return _forwardBatchCall(address(_cfa), cfaCallData, userData);
    }

    function _updateFlowOperatorPermissions(
        ISuperToken token,
        address flowOperator,
        uint8 permissions,
        int96 flowrateAllowance
    )
        internal returns (bool)
    {
        bytes memory cfaCallData =
            abi.encodeCall(
                _cfa.updateFlowOperatorPermissions,
                (
                    token,
                    flowOperator,
                    permissions,
                    flowrateAllowance,
                    new bytes(0) // placeholder
                )
            );

        return _forwardBatchCall(address(_cfa), cfaCallData, new bytes(0));
    }
}
