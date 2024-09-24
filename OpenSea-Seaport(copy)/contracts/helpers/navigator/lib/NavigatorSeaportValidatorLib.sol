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
import { AdvancedOrderLib } from "OpenSea-Seaport/seaport-sol/src/lib/AdvancedOrderLib.sol";

import { ErrorsAndWarnings } from "../../order-validator/SeaportValidator.sol";

import { NavigatorContext } from "./SeaportNavigatorTypes.sol";

library NavigatorSeaportValidatorLib {
    using AdvancedOrderLib for AdvancedOrder;

    error ValidatorReverted();

    /**
     * @dev Validate each order using SeaportValidator and add the results to
     *      the NavigatorResponse.
     */
    function withErrors(
        NavigatorContext memory context
    ) internal view returns (NavigatorContext memory) {
        AdvancedOrder[] memory orders = context.response.orders;

        ErrorsAndWarnings[] memory errors = new ErrorsAndWarnings[](
            orders.length
        );
        for (uint256 i; i < orders.length; i++) {
            errors[i] = context.request.validator.isValidOrder(
                orders[i].toOrder(),
                address(context.request.seaport)
            );
        }
        context.response.validationErrors = errors;
        return context;
    }
}
