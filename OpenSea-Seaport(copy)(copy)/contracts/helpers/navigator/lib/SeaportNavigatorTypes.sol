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
    SeaportValidatorInterface,
    ErrorsAndWarnings
} from "../../order-validator/SeaportValidator.sol";

import {
    ConsiderationInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/ConsiderationInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Execution,
    Order,
    OrderComponents,
    OrderParameters,
    ConsiderationItem,
    OfferItem,
    ReceivedItem,
    SpentItem,
    Fulfillment,
    FulfillmentComponent
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    ItemType,
    Side,
    OrderType
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import {
    MatchComponent
} from "OpenSea-Seaport/seaport-sol/src/lib/types/MatchComponentType.sol";

import {
    FulfillmentDetails,
    OrderDetails
} from "OpenSea-Seaport/seaport-sol/src/fulfillments/lib/Structs.sol";

import {
    FulfillmentStrategy
} from "OpenSea-Seaport/seaport-sol/src/fulfillments/lib/FulfillmentLib.sol";

struct NavigatorAdvancedOrder {
    NavigatorOrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

struct NavigatorOrderParameters {
    address offerer;
    address zone;
    NavigatorOfferItem[] offer;
    NavigatorConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 totalOriginalConsiderationItems;
}

struct NavigatorOfferItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 startAmount;
    uint256 endAmount;
    uint256[] candidateIdentifiers;
}

struct NavigatorConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
    uint256[] candidateIdentifiers;
}

/**
 * @dev Context struct for NavigatorContextLib. Includes context information
 *      necessary for fulfillment, like the caller and recipient addresses,
 *      and Seaport and SeaportValidator interfaces.
 */
struct NavigatorContext {
    NavigatorRequest request;
    NavigatorResponse response;
}

struct NavigatorRequest {
    ConsiderationInterface seaport;
    SeaportValidatorInterface validator;
    NavigatorAdvancedOrder[] orders;
    address caller;
    address recipient;
    uint256 nativeTokensSupplied;
    uint256 maximumFulfilled;
    bytes32 fulfillerConduitKey;
    uint256 seed;
    FulfillmentStrategy fulfillmentStrategy;
    CriteriaResolver[] criteriaResolvers;
    bool preferMatch;
}

struct NavigatorResponse {
    /**
     * @dev The provided orders. If the caller provides explicit criteria
     *      resolvers, the orders will not be modified. If the caller provides
     *      criteria constraints, the returned offer/consideration items will be
     *      updated with calculated merkle roots as their `identifierOrCriteria`
     */
    AdvancedOrder[] orders;
    /**
     * @dev The provided or calculated criteria resolvers. If the caller
     *      provides criteria constraints rather than explicit criteria
     *      resolvers, criteria resolvers and merkle proofs will be calculated
     *      based on provided criteria constraints.
     */
    CriteriaResolver[] criteriaResolvers;
    /**
     * @dev Human-readable name of the suggested Seaport fulfillment method for
     *      the provided orders.
     */
    string suggestedActionName;
    /**
     * @dev Encoded calldata for the suggested Seaport fulfillment method,
     *      provided orders, and context args.
     */
    bytes suggestedCallData;
    /**
     * @dev Array of errors and warnings returned by SeaportValidator for the
     *      provided orders, by order index in the orders array.
     */
    ErrorsAndWarnings[] validationErrors;
    /**
     * @dev Calculated OrderDetails structs for the provided orders, by order
     *      index. Includes offerer, conduit key, spent and received items,
     *      order hash, and unavailable reason.
     */
    OrderDetails[] orderDetails;
    /**
     * @dev Calculated fulfillment components and combined Fullfiilments.
     */
    FulfillmentComponent[][] offerFulfillments;
    FulfillmentComponent[][] considerationFulfillments;
    Fulfillment[] fulfillments;
    /**
     * @dev Calculated match components for matchable orders.
     */
    MatchComponent[] unspentOfferComponents;
    MatchComponent[] unmetConsiderationComponents;
    /**
     * @dev Calculated explicit and implicit executions.
     */
    Execution[] explicitExecutions;
    Execution[] implicitExecutions;
    Execution[] implicitExecutionsPre;
    Execution[] implicitExecutionsPost;
    /**
     * @dev Quantity of native tokens returned to caller.
     */
    uint256 nativeTokensReturned;
}
