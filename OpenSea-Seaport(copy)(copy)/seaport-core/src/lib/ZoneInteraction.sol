/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OrderType} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {AdvancedOrder, BasicOrderParameters, OrderParameters} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {ZoneInteractionErrors} from "OpenSea-Seaport/seaport-types/src/interfaces/ZoneInteractionErrors.sol";

import {LowLevelHelpers} from "./LowLevelHelpers.sol";

import {ConsiderationEncoder} from "./ConsiderationEncoder.sol";

import {MemoryPointer} from "OpenSea-Seaport/seaport-types/src/helpers/PointerLibraries.sol";

import {
    ContractOrder_orderHash_offerer_shift,
    MaskOverFirstFourBytes,
    OneWord,
    OrderParameters_zone_offset
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

import {
    Error_selector_offset,
    InvalidContractOrder_error_selector,
    InvalidRestrictedOrder_error_length,
    InvalidRestrictedOrder_error_orderHash_ptr,
    InvalidRestrictedOrder_error_selector
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrorConstants.sol";

/**
 * @title ZoneInteraction
 * @author 0age
 * @notice ZoneInteraction contains logic related to interacting with zones.
 */
contract ZoneInteraction is ConsiderationEncoder, ZoneInteractionErrors, LowLevelHelpers {
    /**
     * @dev Internal function to determine if an order has a restricted order
     *      type and, if so, to ensure that either the zone is the caller or
     *      that a call to `validateOrder` on the zone returns a magic value
     *      indicating that the order is currently valid. Note that contract
     *      orders are not accessible via the basic fulfillment method.
     *
     * @param orderHash  The hash of the order.
     * @param orderType  The order type.
     * @param parameters The parameters of the basic order.
     */
    function _assertRestrictedBasicOrderValidity(
        bytes32 orderHash,
        OrderType orderType,
        BasicOrderParameters calldata parameters
    ) internal {
        // Order type 2-3 require zone be caller or zone to approve.
        // Note that in cases where fulfiller == zone, the restricted order
        // validation will be skipped.
        if (_isRestrictedAndCallerNotZone(orderType, parameters.zone)) {
            // Encode the `validateOrder` call in memory.
            (MemoryPointer callData, uint256 size) = _encodeValidateBasicOrder(orderHash, parameters);

            // Perform `validateOrder` call and ensure magic value was returned.
            _callAndCheckStatus(parameters.zone, orderHash, callData, size, InvalidRestrictedOrder_error_selector);
        }
    }

    /**
     * @dev Internal function to determine the post-execution validity of
     *      restricted and contract orders. Restricted orders where the caller
     *      is not the zone must successfully call `validateOrder` with the
     *      correct magic value returned. Contract orders must successfully call
     *      `ratifyOrder` with the correct magic value returned.
     *
     * @param advancedOrder The advanced order in question.
     * @param orderHashes   The order hashes of each order included as part of
     *                      the current fulfillment.
     * @param orderHash     The hash of the order.
     */
    function _assertRestrictedAdvancedOrderValidity(
        AdvancedOrder memory advancedOrder,
        bytes32[] memory orderHashes,
        bytes32 orderHash
    ) internal {
        // Declare variables that will be assigned based on the order type.
        address target;
        uint256 errorSelector;
        MemoryPointer callData;
        uint256 size;

        // Retrieve the parameters of the order in question.
        OrderParameters memory parameters = advancedOrder.parameters;

        // OrderType 2-3 require zone to be caller or approve via validateOrder.
        if (_isRestrictedAndCallerNotZone(parameters.orderType, parameters.zone)) {
            // Encode the `validateOrder` call in memory.
            (callData, size) = _encodeValidateOrder(orderHash, parameters, advancedOrder.extraData, orderHashes);

            // Set the target to the zone.
            target = (parameters.toMemoryPointer().offset(OrderParameters_zone_offset).readAddress());

            // Set the restricted-order-specific error selector.
            errorSelector = InvalidRestrictedOrder_error_selector;
        } else if (parameters.orderType == OrderType.CONTRACT) {
            // Set the target to the offerer (note the offerer has no offset).
            target = parameters.toMemoryPointer().readAddress();

            // Shift the target 96 bits to the left.
            uint256 shiftedOfferer;
            assembly {
                shiftedOfferer := shl(ContractOrder_orderHash_offerer_shift, target)
            }

            // Encode the `ratifyOrder` call in memory.
            (callData, size) =
                _encodeRatifyOrder(orderHash, parameters, advancedOrder.extraData, orderHashes, shiftedOfferer);

            // Set the contract-order-specific error selector.
            errorSelector = InvalidContractOrder_error_selector;
        } else {
            return;
        }

        // Perform call and ensure a corresponding magic value was returned.
        _callAndCheckStatus(target, orderHash, callData, size, errorSelector);
    }

    /**
     * @dev Determines whether the specified order type is restricted and the
     *      caller is not the specified zone.
     *
     * @param orderType     The type of the order to check.
     * @param zone          The address of the zone to check against.
     *
     * @return mustValidate True if the order type is restricted and the caller
     *                      is not the specified zone, false otherwise.
     */
    function _isRestrictedAndCallerNotZone(OrderType orderType, address zone)
        internal
        view
        returns (bool mustValidate)
    {
        assembly {
            mustValidate :=
                and(
                    // Note that this check requires that there are no order types
                    // beyond the current set (0-4).  It will need to be modified if
                    // more order types are added.
                    and(lt(orderType, 4), gt(orderType, 1)),
                    iszero(eq(caller(), zone))
                )
        }
    }

    /**
     * @dev Calls the specified target with the given data and checks the status
     *      of the call. Revert reasons will be "bubbled up" if one is returned,
     *      otherwise reverting calls will throw a generic error based on the
     *      supplied error handler.
     *
     * @param target        The address of the contract to call.
     * @param orderHash     The hash of the order associated with the call.
     * @param callData      The data to pass to the contract call.
     * @param size          The size of calldata.
     * @param errorSelector The error handling function to call if the call
     *                      fails or the magic value does not match.
     */
    function _callAndCheckStatus(
        address target,
        bytes32 orderHash,
        MemoryPointer callData,
        uint256 size,
        uint256 errorSelector
    ) internal {
        bool success;
        bool magicMatch;
        assembly {
            // Get magic value from the selector at start of provided calldata.
            let magic := and(mload(callData), MaskOverFirstFourBytes)

            // Clear the start of scratch space.
            mstore(0, 0)

            // Perform call, placing result in the first word of scratch space.
            success := call(gas(), target, 0, callData, size, 0, OneWord)

            // Determine if returned magic value matches the calldata selector.
            magicMatch := eq(magic, mload(0))
        }

        // Revert if the call was not successful.
        if (!success) {
            // Revert and pass reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // If no reason was returned, revert with supplied error selector.
            assembly {
                mstore(0, errorSelector)
                mstore(InvalidRestrictedOrder_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSelector(
                //     "InvalidRestrictedOrder(bytes32)",
                //     orderHash
                // ))
                revert(Error_selector_offset, InvalidRestrictedOrder_error_length)
            }
        }

        // Revert if the correct magic value was not returned.
        if (!magicMatch) {
            // Revert with a generic error message.
            assembly {
                mstore(0, errorSelector)
                mstore(InvalidRestrictedOrder_error_orderHash_ptr, orderHash)

                // revert(abi.encodeWithSelector(
                //     "InvalidRestrictedOrder(bytes32)",
                //     orderHash
                // ))
                revert(Error_selector_offset, InvalidRestrictedOrder_error_length)
            }
        }
    }
}
