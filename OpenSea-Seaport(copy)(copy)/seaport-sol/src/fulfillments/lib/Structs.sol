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

import {MatchComponent, MatchComponentType} from "../../lib/types/MatchComponentType.sol";

import {FulfillmentComponent, SpentItem, ReceivedItem} from "../../SeaportStructs.sol";

import {UnavailableReason} from "../../SpaceEnums.sol";

struct FulfillmentHelperCounterLayout {
    uint256 fulfillmentCounter;
}

// TODO: won't work for partial fulfills of criteria resolved
// TODO: won't work for hybrid tokens that implement multiple token interfaces
struct MatchFulfillmentStorageLayout {
    mapping(
        address /*tokenContract*/
            => mapping(
                uint256 /*identifier*/
                    => mapping(
                        address /*offerer*/ => mapping(bytes32 /*conduitKey*/ => MatchComponent[] /*components*/)
                    )
            )
        ) offerMap;
    mapping(
        address /*recipient*/
            => mapping(address /*tokenContract*/ => mapping(uint256 /*identifier*/ => MatchComponent[] /*components*/))
        ) considerationMap;
    // a given aggregatable consideration component will have its own set of aggregatable offer components
    mapping(address /*token*/ => mapping(uint256 /*tokenId*/ => AggregatableOfferer[] /*offererEnumeration*/))
        tokenToOffererEnumeration;
    // aggregatable consideration components can be enumerated normally
    AggregatableConsideration[] considerationEnumeration;
}

struct FulfillAvailableHelperStorageLayout {
    mapping(
        address /*tokenContract*/
            => mapping(
                uint256 /*identifier*/
                    => mapping(
                        address /*offerer*/ => mapping(bytes32 /*conduitKey*/ => FulfillmentComponent[] /*components*/)
                    )
            )
        ) offerMap;
    mapping(
        address /*recipient*/
            => mapping(
                address /*tokenContract*/ => mapping(uint256 /*identifier*/ => FulfillmentComponent[] /*components*/)
            )
        ) considerationMap;
    // a given aggregatable consideration component will have its own set of aggregatable offer components
    AggregatableOffer[] offerEnumeration;
    // aggregatable consideration components can be enumerated normally
    AggregatableConsideration[] considerationEnumeration;
}

/**
 * @notice Offers can only be aggregated if they share an offerer *and* conduitKey
 */
struct AggregatableOfferer {
    address offerer;
    bytes32 conduitKey;
}

struct AggregatableOffer {
    address offerer;
    bytes32 conduitKey;
    address contractAddress;
    uint256 tokenId;
}
/**
 *
 * @notice Considerations can only be aggregated if they share a token address, id, and recipient (and itemType, but in the vast majority of cases, a token is only one type)
 */

struct AggregatableConsideration {
    address recipient;
    address contractAddress;
    uint256 tokenId;
}

struct ProcessComponentParams {
    FulfillmentComponent[] offerFulfillmentComponents;
    FulfillmentComponent[] considerationFulfillmentComponents;
    uint256 offerItemIndex;
    uint256 considerationItemIndex;
    bool midCredit;
}

struct OrderDetails {
    address offerer;
    bytes32 conduitKey;
    SpentItem[] offer;
    ReceivedItem[] consideration;
    bool isContract;
    bytes32 orderHash;
    UnavailableReason unavailableReason;
}

/**
 * @dev Represents the details of a single fulfill/match call to Seaport.
 *
 * @param orders              processed details of individual orders
 * @param recipient           the explicit recipient of all offer items in
 *                            the fulfillAvailable case; implicit recipient
 *                            of excess offer items in the match case
 * @param fulfiller           the explicit recipient of all unspent native
 *                            tokens; provides all consideration items in
 *                            the fulfillAvailable case
 * @param fulfillerConduitKey used to transfer tokens from the fulfiller
 *                            providing all consideration items in the
 *                            fulfillAvailable case
 */
struct FulfillmentDetails {
    OrderDetails[] orders;
    address payable recipient;
    address payable fulfiller;
    uint256 nativeTokensSupplied;
    bytes32 fulfillerConduitKey;
    address seaport;
}
