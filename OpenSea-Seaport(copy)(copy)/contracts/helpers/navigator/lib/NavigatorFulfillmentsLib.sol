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

import { Fulfillment } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    FulfillmentGeneratorLib
} from "OpenSea-Seaport/seaport-sol/src/fulfillments/lib/FulfillmentLib.sol";

import {
    FulfillmentComponent,
    MatchComponent,
    OrderDetails
} from "OpenSea-Seaport/seaport-sol/src/fulfillments/lib/Structs.sol";

import { NavigatorContext } from "./SeaportNavigatorTypes.sol";

library NavigatorFulfillmentsLib {
    using FulfillmentGeneratorLib for OrderDetails[];

    /**
     * @dev Calculate fulfillments and match components for the provided orders
     *      and add them to the NavigatorResponse.
     */
    function withFulfillments(
        NavigatorContext memory context
    ) internal pure returns (NavigatorContext memory) {
        (
            ,
            FulfillmentComponent[][] memory offerFulfillments,
            FulfillmentComponent[][] memory considerationFulfillments,
            Fulfillment[] memory fulfillments,
            MatchComponent[] memory unspentOfferComponents,
            MatchComponent[] memory unmetConsiderationComponents
        ) = context.response.orderDetails.getFulfillments(
                context.request.fulfillmentStrategy,
                context.request.recipient,
                context.request.caller,
                context.request.seed
            );

        context.response.offerFulfillments = offerFulfillments;
        context.response.considerationFulfillments = considerationFulfillments;
        context.response.fulfillments = fulfillments;
        context.response.unspentOfferComponents = unspentOfferComponents;
        context
            .response
            .unmetConsiderationComponents = unmetConsiderationComponents;
        return context;
    }
}
