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

import { AdvancedOrder } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { Type, OrderStructureLib } from "./OrderStructureLib.sol";
import { NavigatorContext } from "./SeaportNavigatorTypes.sol";

library NavigatorRequestValidatorLib {
    using OrderStructureLib for AdvancedOrder;

    /**
     * @dev Bad request error: provided orders include at least one contract order.
     *      The order helper does not currently support contract orders.
     */
    error ContractOrdersNotSupported();

    /**
     * @dev Validate the provided orders. Checks that none of the provided orders
     *      are contract orders and applies basic criteria constraint validations.
     */
    function validate(
        NavigatorContext memory context
    ) internal pure returns (NavigatorContext memory) {
        validateNoContractOrders(context);
        return context;
    }

    /**
     * @dev Checks that none of the provided orders are contract orders.
     */
    function validateNoContractOrders(
        NavigatorContext memory context
    ) internal pure returns (NavigatorContext memory) {
        for (uint256 i; i < context.response.orders.length; i++) {
            AdvancedOrder memory order = context.response.orders[i];
            if (order.getType() == Type.CONTRACT) {
                revert ContractOrdersNotSupported();
            }
        }
        return context;
    }
}
