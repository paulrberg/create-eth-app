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
pragma solidity ^0.8.13;

import {
    AdvancedOrder,
    CriteriaResolver,
    FulfillmentComponent
} from "../lib/ConsiderationStructs.sol";

import { Execution } from "../lib/ConsiderationStructs.sol";

/**
 * @title  SeaportRouterInterface
 * @author Ryan Ghods (ralxz.eth), 0age (0age.eth), James Wenzel (emo.eth)
 * @notice A utility contract for fulfilling orders with multiple
 *         Seaport versions. DISCLAIMER: This contract only works when
 *         all consideration items across all listings are native tokens.
 */
interface SeaportRouterInterface {
    /**
     * @dev Revert with an error when attempting to fulfill any number of
     *      available orders when none are fulfillable.
     */
    error NoSpecifiedOrdersAvailable();

    /**
     * @dev Advanced order parameters for use through the
     *      FulfillAvailableAdvancedOrdersParams struct.
     */
    struct AdvancedOrderParams {
        AdvancedOrder[] advancedOrders;
        CriteriaResolver[] criteriaResolvers;
        FulfillmentComponent[][] offerFulfillments;
        FulfillmentComponent[][] considerationFulfillments;
        uint256 etherValue; /// The ether value to send with the set of orders.
    }

    /**
     * @dev Parameters for using fulfillAvailableAdvancedOrders
     *      through SeaportRouter.
     */
    struct FulfillAvailableAdvancedOrdersParams {
        address[] seaportContracts;
        AdvancedOrderParams[] advancedOrderParams;
        bytes32 fulfillerConduitKey;
        address recipient;
        uint256 maximumFulfilled;
    }

    /**
     * @dev Calldata params for calling FulfillAvailableAdvancedOrders.
     */
    struct CalldataParams {
        AdvancedOrder[] advancedOrders;
        CriteriaResolver[] criteriaResolvers;
        FulfillmentComponent[][] offerFulfillments;
        FulfillmentComponent[][] considerationFulfillments;
        bytes32 fulfillerConduitKey;
        address recipient;
        uint256 maximumFulfilled;
    }

    /**
     * @dev Revert with an error if a provided Seaport contract is not allowed
     *      to be used in the router.
     */
    error SeaportNotAllowed(address seaport);

    /**
     * @dev Revert with an error if an ether transfer back to the fulfiller
     *      fails.
     */
    error EtherReturnTransferFailed(
        address recipient,
        uint256 amount,
        bytes returnData
    );

    /**
     * @dev Fallback function to receive excess ether, in case total amount of
     *      ether sent is more than the amount required to fulfill the order.
     */
    receive() external payable;

    /**
     * @notice Fulfill available advanced orders through multiple Seaport
     *         versions.
     *         See {SeaportInterface-fulfillAvailableAdvancedOrders}
     *
     * @param params The parameters for fulfilling available advanced orders.
     */
    function fulfillAvailableAdvancedOrders(
        FulfillAvailableAdvancedOrdersParams calldata params
    )
        external
        payable
        returns (
            bool[][] memory availableOrders,
            Execution[][] memory executions
        );

    /**
     * @notice Returns the Seaport contracts allowed to be used through this
     *         router.
     */
    function getAllowedSeaportContracts()
        external
        view
        returns (address[] memory);
}
