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
    BasicOrderType,
    ItemType,
    OrderType
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

library SeaportEnumsLib {
    /**
     * @dev Parses a BasicOrderType into its constituent parts.
     *
     * @param basicOrderType the BasicOrderType to parse
     *
     * @return orderType                           the OrderType
     * @return offerType                           the ItemType of the offer
     * @return considerationType                   the ItemType of the
     *                                             consideration
     * @return additionalRecipientsType            the ItemType of the
     *                                             additional recipients
     * @return offerTypeIsAdditionalRecipientsType whether the offer type is the
     *                                             additional recipients type
     */
    function parseBasicOrderType(
        BasicOrderType basicOrderType
    )
        internal
        pure
        returns (
            OrderType orderType,
            ItemType offerType,
            ItemType considerationType,
            ItemType additionalRecipientsType,
            bool offerTypeIsAdditionalRecipientsType
        )
    {
        assembly {
            // Mask all but 2 least-significant bits to derive the order type.
            orderType := and(basicOrderType, 3)

            // Divide basicOrderType by four to derive the route.
            let route := shr(2, basicOrderType)
            offerTypeIsAdditionalRecipientsType := gt(route, 3)

            // If route > 1 additionalRecipient items are ERC20 (1) else Eth (0)
            additionalRecipientsType := gt(route, 1)

            // If route > 2, receivedItemType is route - 2. If route is 2,
            // the receivedItemType is ERC20 (1). Otherwise, it is Eth (0).
            considerationType := add(
                mul(sub(route, 2), gt(route, 2)),
                eq(route, 2)
            )

            // If route > 3, offeredItemType is ERC20 (1). Route is 2 or 3,
            // offeredItemType = route. Route is 0 or 1, it is route + 2.
            offerType := add(route, mul(iszero(additionalRecipientsType), 2))
        }
    }
}
