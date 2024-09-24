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
    AdvancedOrder,
    CriteriaResolver
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    NavigatorAdvancedOrder,
    NavigatorContext
} from "./SeaportNavigatorTypes.sol";

import { NavigatorAdvancedOrderLib } from "./NavigatorAdvancedOrderLib.sol";

library NavigatorCriteriaResolverLib {
    using NavigatorAdvancedOrderLib for NavigatorAdvancedOrder[];

    /**
     * @dev Calculate criteria resolvers, merkle proofs, and criteria merkle
     *      roots for the provided orders and criteria constraints. Modifies
     *      orders in place to add criteria merkle roots to the appropriate
     *      offer/consdieration items. Adds calculated criteria resolvers to
     *      the NavigatorResponse.
     */
    function withCriteria(
        NavigatorContext memory context
    ) internal pure returns (NavigatorContext memory) {
        (
            AdvancedOrder[] memory orders,
            CriteriaResolver[] memory resolvers
        ) = context.request.orders.toAdvancedOrders();
        context.response.orders = orders;
        if (context.request.criteriaResolvers.length > 0) {
            context.response.criteriaResolvers = context
                .request
                .criteriaResolvers;
            return context;
        } else {
            context.response.criteriaResolvers = resolvers;
            return context;
        }
    }
}
