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
    AggregatableConsideration,
    ProcessComponentParams,
    MatchFulfillmentStorageLayout,
    AggregatableOfferer
} from "../lib/Structs.sol";
import {MatchComponent, MatchComponentType} from "../../lib/types/MatchComponentType.sol";
import {FulfillmentComponent, Fulfillment} from "../../SeaportStructs.sol";
import {LibSort} from "OpenSea-Seaport/solady/src/utils/LibSort.sol";
import {MatchArrays} from "../lib/MatchArrays.sol";

library MatchFulfillmentLib {
    using MatchComponentType for MatchComponent[];
    using MatchComponentType for MatchComponent;

    /**
     * @notice Check if a token already exists in a mapping by checking the length of the array at that slot
     * @param token token to check
     * @param layout storage layout
     */
    function aggregatableConsiderationExists(
        AggregatableConsideration memory token,
        MatchFulfillmentStorageLayout storage layout
    ) internal view returns (bool) {
        return layout.considerationMap[token.recipient][token.contractAddress][token.tokenId].length > 0;
    }

    /**
     * @notice Check if an entry into the offer component mapping already exists by checking its length
     */
    function aggregatableOffererExists(
        address token,
        uint256 tokenId,
        AggregatableOfferer memory offerer,
        MatchFulfillmentStorageLayout storage layout
    ) internal view returns (bool) {
        return layout.offerMap[token][tokenId][offerer.offerer][offerer.conduitKey].length > 0;
    }

    function processConsiderationComponent(
        MatchComponent[] storage offerComponents,
        MatchComponent[] storage considerationComponents,
        ProcessComponentParams memory params
    ) internal {
        while (params.offerItemIndex < offerComponents.length) {
            MatchComponent memory considerationComponent = considerationComponents[params.considerationItemIndex];

            // if consideration has been completely credited, break to next consideration component
            if (considerationComponent.getAmount() == 0) {
                break;
            }
            processOfferComponent({
                offerComponents: offerComponents,
                considerationComponents: considerationComponents,
                params: params
            });
        }

        MatchArrays.appendUnsafe(
            params.considerationFulfillmentComponents,
            considerationComponents[params.considerationItemIndex].toFulfillmentComponent()
        );
    }

    function processOfferComponent(
        MatchComponent[] storage offerComponents,
        MatchComponent[] storage considerationComponents,
        ProcessComponentParams memory params
    ) internal {
        // re-load components each iteration as they may have been modified
        MatchComponent memory offerComponent = offerComponents[params.offerItemIndex];
        MatchComponent memory considerationComponent = considerationComponents[params.considerationItemIndex];

        if (offerComponent.getAmount() > considerationComponent.getAmount()) {
            // if offer amount is greater than consideration amount, set consideration to zero and credit from offer amount
            offerComponent = offerComponent.subtractAmount(considerationComponent);
            considerationComponent = considerationComponent.setAmount(0);
            offerComponents[params.offerItemIndex] = offerComponent;
            considerationComponents[params.considerationItemIndex] = considerationComponent;
            // note that this offerItemIndex should be included when consolidating
            params.midCredit = true;
        } else {
            // otherwise deplete offer amount and credit consideration amount

            considerationComponent = considerationComponent.subtractAmount(offerComponent);
            offerComponent = offerComponent.setAmount(0);

            considerationComponents[params.considerationItemIndex] = considerationComponent;

            offerComponents[params.offerItemIndex] = offerComponent;
            ++params.offerItemIndex;
            // note that this offerItemIndex should not be included when consolidating
            params.midCredit = false;
        }
        // an offer component may have already been added if it was not depleted by an earlier consideration item
        if (!previouslyAdded(params.offerFulfillmentComponents, offerComponent.toFulfillmentComponent())) {
            MatchArrays.appendUnsafe(params.offerFulfillmentComponents, offerComponent.toFulfillmentComponent());
        }
    }

    function scuffLength(FulfillmentComponent[] memory components, uint256 newLength) internal pure {
        assembly {
            mstore(components, newLength)
        }
    }

    function previouslyAdded(FulfillmentComponent[] memory components, FulfillmentComponent memory fulfillmentComponent)
        internal
        pure
        returns (bool)
    {
        if (components.length == 0) {
            return false;
        }

        FulfillmentComponent memory lastComponent = components[components.length - 1];
        return lastComponent.orderIndex == fulfillmentComponent.orderIndex
            && lastComponent.itemIndex == fulfillmentComponent.itemIndex;
    }

    /**
     * Credit offer components to consideration components until either or both are exhausted
     * Updates arrays in storage to remove 0-item components after credits
     * @param offerComponents Aggregatable offer components
     * @param considerationComponents Aggregatable consideration components
     */
    function createFulfillment(
        MatchComponent[] storage offerComponents,
        MatchComponent[] storage considerationComponents
    ) internal returns (Fulfillment memory) {
        // optimistically allocate arrays of fulfillment components
        FulfillmentComponent[] memory offerFulfillmentComponents =
            MatchArrays.allocateFulfillmentComponents(offerComponents.length);
        FulfillmentComponent[] memory considerationFulfillmentComponents =
            MatchArrays.allocateFulfillmentComponents(considerationComponents.length);
        // iterate over consideration components
        ProcessComponentParams memory params = ProcessComponentParams({
            offerFulfillmentComponents: offerFulfillmentComponents,
            considerationFulfillmentComponents: considerationFulfillmentComponents,
            offerItemIndex: 0,
            considerationItemIndex: 0,
            midCredit: false
        });

        // iterate over all consideration components eligible to be fulfilled
        // in a single transfer; this means that any uncredited amounts will be
        // consolidated into the first component for later fulfillments
        // TODO: this may not be optimal in some cases with partial
        // fulfillments
        for (
            uint256 considerationItemIndex;
            considerationItemIndex < considerationComponents.length;
            ++considerationItemIndex
        ) {
            // params will be updated directly by called functions except for considerationItemIndex
            params.considerationItemIndex = considerationItemIndex;
            processConsiderationComponent({
                offerComponents: offerComponents,
                considerationComponents: considerationComponents,
                params: params
            });
        }

        // remove any zero-amount components so they are skipped in future
        // fulfillments, and consolidate any remaining offer amounts used
        // in this fulfillment into the first component.
        consolidateComponents(
            offerComponents,
            // if mid-credit, offerItemIndex should be included in consolidation
            (params.midCredit) ? params.offerItemIndex + 1 : params.offerItemIndex
        );
        // all eligible consideration components will be processed when matched
        // with the first eligible offer components, whether or not there are
        // enough offer items to credit each consideration item. This means
        // that all remaining amounts will be consolidated into the first
        // consideration component for later fulfillments.
        consolidateComponents(considerationComponents, considerationComponents.length);

        // return a discrete fulfillment since either or both of the sets of components have been exhausted
        // if offer or consideration items remain, they will be revisited in subsequent calls
        return Fulfillment({
            offerComponents: offerFulfillmentComponents,
            considerationComponents: considerationFulfillmentComponents
        });
    }

    /**
     * @dev Consolidate any remaining amounts
     * @param components Components to consolidate
     * @param excludeIndex First index to exclude from consolidation. For
     *        offerComponents this is the index after the last credited item,
     *        for considerationComponents, this is the length of the array
     */
    function consolidateComponents(MatchComponent[] storage components, uint256 excludeIndex) internal {
        // cache components in memory
        MatchComponent[] memory cachedComponents = components;
        if (cachedComponents.length == 0) {
            return;
        } else if (cachedComponents.length == 1) {
            // check if there is only one component
            // if it is zero, remove it
            if (cachedComponents[0].getAmount() == 0) {
                components.pop();
            }
            // otherwise do nothing
            return;
        }
        // otherwise clear the storage array
        while (components.length > 0) {
            components.pop();
        }

        // consolidate the amounts of credited non-zero components into the
        // first component. This is what Seaport does internally when a
        // fulfillment is credited.
        MatchComponent memory first = cachedComponents[0];

        // consolidate all non-zero components used in this fulfillment into the
        // first component
        for (uint256 i = 1; i < excludeIndex; ++i) {
            first = first.addAmount(cachedComponents[i]);
        }

        // push the first component back into storage if it is non-zero
        if (first.getAmount() > 0) {
            components.push(first);
        }
        // push any remaining non-zero components back into storage
        for (uint256 i = excludeIndex; i < cachedComponents.length; ++i) {
            MatchComponent memory component = cachedComponents[i];
            if (component.getAmount() > 0) {
                components.push(component);
            }
        }
    }

    function dedupe(MatchComponent[] memory components)
        internal
        pure
        returns (MatchComponent[] memory dedupedComponents)
    {
        if (components.length == 0 || components.length == 1) {
            return components;
        }
        // sort components
        // uint256[] memory cast = components.toUints();
        // LibSort.sort(cast);
        // components = MatchComponentType.fromUints(cast);
        // create a new array of same size; it will be truncated if necessary
        MatchArrays.sortByIndex(components);
        dedupedComponents = new MatchComponent[](components.length);
        dedupedComponents[0] = components[0];
        uint256 dedupedIndex = 1;
        for (uint256 i = 1; i < components.length; i++) {
            // compare current component to last deduped component
            if (!components[i].equals(dedupedComponents[dedupedIndex - 1])) {
                // if it is different, add it to the deduped array and increment the index
                dedupedComponents[dedupedIndex] = components[i];
                ++dedupedIndex;
            }
        }
        return MatchArrays.truncate(dedupedComponents, dedupedIndex);
    }
}
