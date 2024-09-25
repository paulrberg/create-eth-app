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

import "../../SeaportStructs.sol";
import "../../lib/SeaportArrays.sol";
import {
    FulfillAvailableHelperStorageLayout,
    FulfillmentHelperCounterLayout,
    AggregatableOffer,
    AggregatableConsideration
} from "../lib/Structs.sol";
import {FulfillAvailableLayout} from "./FulfillAvailableLayout.sol";
import {FULFILL_AVAILABLE_COUNTER_KEY, FULFILL_AVAILABLE_STORAGE_BASE_KEY} from "../lib/Constants.sol";
import {OrderDetails} from "../lib/Structs.sol";

contract FulfillAvailableHelper {
    /**
     * @notice get naive 2d fulfillment component arrays for
     * fulfillAvailableOrders, one 1d array for each offer and consideration
     * item
     * @param orders orders
     * @return offer
     * @return consideration
     */
    function getNaiveFulfillmentComponents(Order[] memory orders)
        public
        pure
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        OrderParameters[] memory orderParameters = new OrderParameters[](
            orders.length
        );
        for (uint256 i = 0; i < orders.length; i++) {
            orderParameters[i] = orders[i].parameters;
        }
        return getNaiveFulfillmentComponents(orderParameters);
    }

    /**
     * @notice get naive 2d fulfillment component arrays for
     * fulfillAvailableOrders, one 1d array for each offer and consideration
     * item
     * @param orders orders
     * @return offer
     * @return consideration
     */
    function getNaiveFulfillmentComponents(AdvancedOrder[] memory orders)
        public
        pure
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        OrderParameters[] memory orderParameters = new OrderParameters[](
            orders.length
        );
        for (uint256 i = 0; i < orders.length; i++) {
            orderParameters[i] = orders[i].parameters;
        }
        return getNaiveFulfillmentComponents(orderParameters);
    }

    /**
     * @notice get naive 2d fulfillment component arrays for
     * fulfillAvailableOrders, one 1d array for each offer and consideration
     * item
     * @param orderParameters orderParameters
     * @return offer
     * @return consideration
     */
    function getNaiveFulfillmentComponents(OrderParameters[] memory orderParameters)
        public
        pure
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        {
            // get total number of offer items and consideration items
            uint256 numOffers;
            uint256 numConsiderations;
            for (uint256 i = 0; i < orderParameters.length; i++) {
                OrderParameters memory parameters = orderParameters[i];

                numOffers += parameters.offer.length;
                numConsiderations += parameters.consideration.length;
            }

            // create arrays
            offer = new FulfillmentComponent[][](numOffers);
            consideration = new FulfillmentComponent[][](numConsiderations);
        }

        uint256 offerIndex;
        uint256 considerationIndex;
        // iterate over orders again, creating one one-element array per offer and consideration item
        for (uint256 i = 0; i < orderParameters.length; i++) {
            OrderParameters memory parameters = orderParameters[i];
            for (uint256 j; j < parameters.offer.length; j++) {
                offer[offerIndex] =
                    SeaportArrays.FulfillmentComponents(FulfillmentComponent({orderIndex: i, itemIndex: j}));
                ++offerIndex;
            }
            // do the same for consideration
            for (uint256 j; j < parameters.consideration.length; j++) {
                consideration[considerationIndex] =
                    SeaportArrays.FulfillmentComponents(FulfillmentComponent({orderIndex: i, itemIndex: j}));
                ++considerationIndex;
            }
        }
        return (offer, consideration);
    }

    /**
     * @notice get naive 2d fulfillment component arrays for
     * fulfillAvailableOrders, one 1d array for each offer and consideration
     * item
     * @param orders OrderDetails[]
     * @return offer
     * @return consideration
     */
    function getNaiveFulfillmentComponents(OrderDetails[] memory orders)
        public
        pure
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        {
            // get total number of offer items and consideration items
            uint256 numOffers;
            uint256 numConsiderations;
            for (uint256 i = 0; i < orders.length; i++) {
                OrderDetails memory order = orders[i];

                numOffers += order.offer.length;
                numConsiderations += order.consideration.length;
            }

            // create arrays
            offer = new FulfillmentComponent[][](numOffers);
            consideration = new FulfillmentComponent[][](numConsiderations);
        }

        uint256 offerIndex;
        uint256 considerationIndex;
        // iterate over orders again, creating one one-element array per offer and consideration item
        for (uint256 i = 0; i < orders.length; i++) {
            OrderDetails memory order = orders[i];
            for (uint256 j; j < order.offer.length; j++) {
                offer[offerIndex] =
                    SeaportArrays.FulfillmentComponents(FulfillmentComponent({orderIndex: i, itemIndex: j}));
                ++offerIndex;
            }
            // do the same for consideration
            for (uint256 j; j < order.consideration.length; j++) {
                consideration[considerationIndex] =
                    SeaportArrays.FulfillmentComponents(FulfillmentComponent({orderIndex: i, itemIndex: j}));
                ++considerationIndex;
            }
        }
        return (offer, consideration);
    }

    /**
     * @notice Get aggregated fulfillment components for aggregatable types from the same offerer or to the same recipient
     * NOTE: this will break for multiple criteria items that resolve
     * to different identifiers
     * @param orders orders
     * @return offer
     * @return consideration
     */
    function getAggregatedFulfillmentComponents(Order[] memory orders)
        public
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        OrderParameters[] memory orderParameters = new OrderParameters[](
            orders.length
        );
        for (uint256 i = 0; i < orders.length; i++) {
            orderParameters[i] = orders[i].parameters;
        }
        return getAggregatedFulfillmentComponents(orderParameters);
    }

    /**
     * @notice Get aggregated fulfillment components for aggregatable types from the same offerer or to the same recipient
     * NOTE: this will break for multiple criteria items that resolve
     * to different identifiers
     * @param orders orders
     * @return offer
     * @return consideration
     */
    function getAggregatedFulfillmentComponents(AdvancedOrder[] memory orders)
        public
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        OrderParameters[] memory orderParameters = new OrderParameters[](
            orders.length
        );
        for (uint256 i = 0; i < orders.length; i++) {
            orderParameters[i] = orders[i].parameters;
        }
        return getAggregatedFulfillmentComponents(orderParameters);
    }

    /**
     * @notice Get aggregated fulfillment components for aggregatable types from the same offerer or to the same recipient
     * NOTE: this will break for multiple criteria items that resolve
     * to different identifiers
     * @param orders orders
     * @return offer
     * @return consideration
     */
    function getAggregatedFulfillmentComponents(OrderParameters[] memory orders)
        public
        returns (FulfillmentComponent[][] memory offer, FulfillmentComponent[][] memory consideration)
    {
        // increment counter to get clean mappings and enumeration
        FulfillAvailableLayout.incrementFulfillmentCounter();
        FulfillAvailableHelperStorageLayout storage layout = FulfillAvailableLayout.getStorageLayout();

        // iterate over each order
        for (uint256 i; i < orders.length; ++i) {
            OrderParameters memory parameters = orders[i];
            preProcessOffer(parameters.offer, parameters.offerer, parameters.conduitKey, i, layout);
            preProcessConsideration(parameters.consideration, i, layout);
        }

        // allocate offer arrays
        offer = new FulfillmentComponent[][](layout.offerEnumeration.length);
        // iterate over enumerated groupings and add to array
        for (uint256 i; i < layout.offerEnumeration.length; ++i) {
            AggregatableOffer memory token = layout.offerEnumeration[i];

            offer[i] = layout.offerMap[token.contractAddress][token.tokenId][token.offerer][token.conduitKey];
        }
        // do the same for considerations
        consideration = new FulfillmentComponent[][](
            layout.considerationEnumeration.length
        );
        for (uint256 i; i < layout.considerationEnumeration.length; ++i) {
            AggregatableConsideration memory token = layout.considerationEnumeration[i];
            consideration[i] = layout.considerationMap[token.recipient][token.contractAddress][token.tokenId];
        }
        return (offer, consideration);
    }

    function extend(FulfillmentComponent[][] memory array, FulfillmentComponent[] memory toAdd)
        internal
        pure
        returns (FulfillmentComponent[][] memory extended)
    {
        extended = new FulfillmentComponent[][](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            extended[i] = array[i];
        }
        extended[array.length] = toAdd;
    }

    /**
     * @notice Process offer items and insert them into enumeration and map
     * @param offer offer items
     * @param offerer offerer
     * @param orderIndex order index of processed items
     * @param layout layout
     */
    function preProcessOffer(
        OfferItem[] memory offer,
        address offerer,
        bytes32 conduitKey,
        uint256 orderIndex,
        FulfillAvailableHelperStorageLayout storage layout
    ) private {
        // iterate over each offer item
        for (uint256 j; j < offer.length; ++j) {
            // create the fulfillment component for this offer item
            FulfillmentComponent memory component = FulfillmentComponent({orderIndex: orderIndex, itemIndex: j});
            // grab order parameters to get offerer
            // grab offer item
            OfferItem memory item = offer[j];
            // create enumeration struct
            AggregatableOffer memory aggregatableOffer = AggregatableOffer({
                offerer: offerer,
                conduitKey: conduitKey,
                contractAddress: item.token,
                tokenId: item.identifierOrCriteria
            });
            // if it does not exist in the map, add it to our enumeration
            if (!FulfillAvailableLayout.aggregatableOfferExists(aggregatableOffer, layout)) {
                layout.offerEnumeration.push(aggregatableOffer);
            }
            // update mapping with this component
            layout.offerMap[aggregatableOffer.contractAddress][aggregatableOffer.tokenId][aggregatableOffer.offerer][aggregatableOffer
                .conduitKey].push(component);
        }
    }

    /**
     * @notice Process consideration items and insert them into enumeration and map
     * @param consideration consideration items
     * @param orderIndex order index of processed items
     * @param layout layout
     */
    function preProcessConsideration(
        ConsiderationItem[] memory consideration,
        uint256 orderIndex,
        FulfillAvailableHelperStorageLayout storage layout
    ) private {
        // iterate over each offer item
        for (uint256 j; j < consideration.length; ++j) {
            // create the fulfillment component for this offer item
            FulfillmentComponent memory component = FulfillmentComponent({orderIndex: orderIndex, itemIndex: j});
            // grab consideration item
            ConsiderationItem memory item = consideration[j];
            // create enumeration struct
            AggregatableConsideration memory token = AggregatableConsideration({
                recipient: item.recipient,
                contractAddress: item.token,
                tokenId: item.identifierOrCriteria
            });
            // if it does not exist in the map, add it to our enumeration
            if (!FulfillAvailableLayout.aggregatableConsiderationExists(token, layout)) {
                layout.considerationEnumeration.push(token);
            }
            // update mapping with this component
            layout.considerationMap[token.recipient][token.contractAddress][token.tokenId].push(component);
        }
    }
}
