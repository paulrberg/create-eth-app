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
    MatchComponent
} from "OpenSea-Seaport/seaport-sol/src/lib/types/MatchComponentType.sol";
import { OrderDetails } from "OpenSea-Seaport/seaport-sol/src/fulfillments/lib/Structs.sol";

import {
    AdvancedOrder,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    CriteriaResolver
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    NavigatorRequest,
    NavigatorResponse,
    NavigatorContext,
    NavigatorOfferItem,
    NavigatorConsiderationItem,
    NavigatorOrderParameters,
    NavigatorAdvancedOrder
} from "./SeaportNavigatorTypes.sol";

import {
    SeaportValidatorInterface,
    ErrorsAndWarnings
} from "../../order-validator/SeaportValidator.sol";

library NavigatorContextLib {
    function from(
        NavigatorRequest memory request
    ) internal pure returns (NavigatorContext memory context) {
        context.request = request;
    }

    function withEmptyResponse(
        NavigatorContext memory context
    ) internal pure returns (NavigatorContext memory) {
        context.response = NavigatorResponse({
            orders: new AdvancedOrder[](0),
            criteriaResolvers: new CriteriaResolver[](0),
            suggestedActionName: "",
            suggestedCallData: hex"",
            validationErrors: new ErrorsAndWarnings[](0),
            orderDetails: new OrderDetails[](0),
            offerFulfillments: new FulfillmentComponent[][](0),
            considerationFulfillments: new FulfillmentComponent[][](0),
            fulfillments: new Fulfillment[](0),
            unspentOfferComponents: new MatchComponent[](0),
            unmetConsiderationComponents: new MatchComponent[](0),
            explicitExecutions: new Execution[](0),
            implicitExecutions: new Execution[](0),
            implicitExecutionsPre: new Execution[](0),
            implicitExecutionsPost: new Execution[](0),
            nativeTokensReturned: 0
        });
        return context;
    }
}
