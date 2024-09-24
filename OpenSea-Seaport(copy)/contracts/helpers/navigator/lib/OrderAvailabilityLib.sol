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
pragma solidity ^0.8.17;

import {
    ConsiderationInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ConsiderationInterface.sol";

import { AdvancedOrder } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { UnavailableReason } from "OpenSea-Seaport/seaport-sol/src/SpaceEnums.sol";

import { OrderStructureLib, State } from "./OrderStructureLib.sol";

/**
 * @notice Helper library for determining order availability.
 */
library OrderAvailabilityLib {
    using OrderStructureLib for AdvancedOrder;

    /**
     * @notice Returns true if the order is available for fulfillment.
     */
    function isAvailable(
        AdvancedOrder memory order,
        ConsiderationInterface seaport
    ) internal view returns (bool) {
        return unavailableReason(order, seaport) == UnavailableReason.AVAILABLE;
    }

    /**
     * @notice Returns the order's UnavailableReason. Available orders will
     *         return UnavailableReason.AVAILABLE to indicate that they are
     *         available for fulfillment.
     */
    function unavailableReason(
        AdvancedOrder memory order,
        ConsiderationInterface seaport
    ) internal view returns (UnavailableReason) {
        if (order.parameters.endTime <= block.timestamp) {
            return UnavailableReason.EXPIRED;
        }
        if (order.parameters.startTime > block.timestamp) {
            return UnavailableReason.STARTS_IN_FUTURE;
        }
        if (order.getState(seaport) == State.CANCELLED) {
            return UnavailableReason.CANCELLED;
        }
        if (order.getState(seaport) == State.FULLY_FILLED) {
            return UnavailableReason.ALREADY_FULFILLED;
        }
        return UnavailableReason.AVAILABLE;
    }

    /**
     * @notice Return an array of UnavailableReasons for the provided orders.
     */
    function unavailableReasons(
        AdvancedOrder[] memory orders,
        uint256 maximumFulfilled,
        ConsiderationInterface seaport
    ) internal view returns (UnavailableReason[] memory) {
        UnavailableReason[] memory reasons = new UnavailableReason[](
            orders.length
        );
        uint256 totalAvailable;
        UnavailableReason reason;
        for (uint256 i = 0; i < orders.length; i++) {
            if (totalAvailable < maximumFulfilled) {
                reason = unavailableReason(orders[i], seaport);
            } else {
                reason = UnavailableReason.MAX_FULFILLED_SATISFIED;
            }
            reasons[i] = reason;
            if (reason == UnavailableReason.AVAILABLE) {
                totalAvailable++;
            }
        }
        return reasons;
    }
}
