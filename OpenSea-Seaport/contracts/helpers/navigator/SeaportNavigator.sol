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
import {
    AdvancedOrder,
    CriteriaResolver
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    SeaportValidatorInterface
} from "../order-validator/SeaportValidator.sol";

import { NavigatorContextLib } from "./lib/NavigatorContextLib.sol";

import { CriteriaHelperLib } from "./lib/CriteriaHelperLib.sol";

import {
    NavigatorContext,
    NavigatorRequest,
    NavigatorResponse
} from "./lib/SeaportNavigatorTypes.sol";

import { SeaportNavigatorInterface } from "./lib/SeaportNavigatorInterface.sol";

import { HelperInterface } from "./lib/HelperInterface.sol";

/**
 * @notice SeaportNavigator is a helper contract that generates additional
 *         information useful for fulfilling Seaport orders. Given an array of
 *         orders and external parameters like caller, recipient, and native
 *         tokens supplied, SeaportNavigator will validate the orders and
 *         return associated errors and warnings, recommend a fulfillment
 *         method, suggest fulfillments, provide execution and order details,
 *         and optionally generate criteria resolvers from provided token IDs.
 */
contract SeaportNavigator is SeaportNavigatorInterface {
    using NavigatorContextLib for NavigatorContext;
    using CriteriaHelperLib for uint256[];

    HelperInterface public immutable requestValidator;
    HelperInterface public immutable criteriaHelper;
    HelperInterface public immutable validatorHelper;
    HelperInterface public immutable orderDetailsHelper;
    HelperInterface public immutable fulfillmentsHelper;
    HelperInterface public immutable suggestedActionHelper;
    HelperInterface public immutable executionsHelper;

    HelperInterface[] public helpers;

    constructor(
        address _requestValidator,
        address _criteriaHelper,
        address _validatorHelper,
        address _orderDetailsHelper,
        address _fulfillmentsHelper,
        address _suggestedActionHelper,
        address _executionsHelper
    ) {
        requestValidator = HelperInterface(_requestValidator);
        helpers.push(requestValidator);

        criteriaHelper = HelperInterface(_criteriaHelper);
        helpers.push(criteriaHelper);

        validatorHelper = HelperInterface(_validatorHelper);
        helpers.push(validatorHelper);

        orderDetailsHelper = HelperInterface(_orderDetailsHelper);
        helpers.push(orderDetailsHelper);

        fulfillmentsHelper = HelperInterface(_fulfillmentsHelper);
        helpers.push(fulfillmentsHelper);

        suggestedActionHelper = HelperInterface(_suggestedActionHelper);
        helpers.push(suggestedActionHelper);

        executionsHelper = HelperInterface(_executionsHelper);
        helpers.push(executionsHelper);
    }

    function prepare(
        NavigatorRequest calldata request
    ) public view returns (NavigatorResponse memory) {
        NavigatorContext memory context = NavigatorContextLib
            .from(request)
            .withEmptyResponse();

        for (uint256 i; i < helpers.length; i++) {
            context = helpers[i].prepare(context);
        }

        return context.response;
    }

    /**
     * @notice Generate a criteria merkle root from an array of `tokenIds`. Use
     *         this helper to construct an order item's `identifierOrCriteria`.
     *
     * @param tokenIds An array of integer token IDs to be converted to a merkle
     *                 root.
     *
     * @return The bytes32 merkle root of a criteria tree containing the given
     *         token IDs.
     */
    function criteriaRoot(
        uint256[] memory tokenIds
    ) external pure returns (bytes32) {
        return tokenIds.criteriaRoot();
    }

    /**
     * @notice Generate a criteria merkle proof that `id` is a member of
     *        `tokenIds`. Reverts if `id` is not a member of `tokenIds`. Use
     *         this helper to construct proof data for criteria resolvers.
     *
     * @param tokenIds An array of integer token IDs.
     * @param id       The integer token ID to generate a proof for.
     *
     * @return Merkle proof that the given token ID is  amember of the criteria
     *         tree containing the given token IDs.
     */
    function criteriaProof(
        uint256[] memory tokenIds,
        uint256 id
    ) external pure returns (bytes32[] memory) {
        return tokenIds.criteriaProof(id);
    }
}
