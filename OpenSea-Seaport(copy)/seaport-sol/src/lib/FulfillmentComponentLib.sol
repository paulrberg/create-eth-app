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

import { FulfillmentComponent } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ArrayLib } from "./ArrayLib.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title FulfillmentComponentLib
 * @author James Wenzel (emo.eth)
 * @notice FulfillmentComponentLib is a library for managing FulfillmentComponent
 *         structs and arrays. It allows chaining of functions to make
 *         struct creation more readable.
 */
library FulfillmentComponentLib {
    bytes32 private constant FULFILLMENT_COMPONENT_MAP_POSITION =
        keccak256("seaport.FulfillmentComponentDefaults");
    bytes32 private constant FULFILLMENT_COMPONENTS_MAP_POSITION =
        keccak256("seaport.FulfillmentComponentsDefaults");

    using ArrayLib for bytes32[];

    /**
     * @dev Clears a default FulfillmentComponent from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => FulfillmentComponent)
            storage fulfillmentComponentMap = _fulfillmentComponentMap();
        FulfillmentComponent storage component = fulfillmentComponentMap[
            defaultName
        ];
        clear(component);
    }

    /**
     * @dev Clears all fields on a FulfillmentComponent.
     *
     * @param component the FulfillmentComponent to clear
     */
    function clear(FulfillmentComponent storage component) internal {
        component.orderIndex = 0;
        component.itemIndex = 0;
    }

    /**
     * @dev Clears an array of FulfillmentComponents from storage.
     *
     * @param components the FulfillmentComponents to clear
     */
    function clear(FulfillmentComponent[] storage components) internal {
        while (components.length > 0) {
            clear(components[components.length - 1]);
            components.pop();
        }
    }

    /**
     * @dev Gets a default FulfillmentComponent from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the FulfillmentComponent retrieved from storage
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (FulfillmentComponent memory item) {
        mapping(string => FulfillmentComponent)
            storage fulfillmentComponentMap = _fulfillmentComponentMap();
        item = fulfillmentComponentMap[defaultName];
    }

    /**
     * @dev Gets an array of default FulfillmentComponents from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the FulfillmentComponents retrieved from storage
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (FulfillmentComponent[] memory items) {
        mapping(string => FulfillmentComponent[])
            storage fulfillmentComponentMap = _fulfillmentComponentsMap();
        items = fulfillmentComponentMap[defaultName];
    }

    /**
     * @dev Saves an FulfillmentComponent as a named default.
     *
     * @param fulfillmentComponent the FulfillmentComponent to save as a default
     * @param defaultName          the name of the default for retrieval
     *
     * @return _fulfillmentComponent the FulfillmentComponent saved as a default
     */
    function saveDefault(
        FulfillmentComponent memory fulfillmentComponent,
        string memory defaultName
    ) internal returns (FulfillmentComponent memory _fulfillmentComponent) {
        mapping(string => FulfillmentComponent)
            storage fulfillmentComponentMap = _fulfillmentComponentMap();
        FulfillmentComponent storage component = fulfillmentComponentMap[
            defaultName
        ];
        component.orderIndex = fulfillmentComponent.orderIndex;
        component.itemIndex = fulfillmentComponent.itemIndex;
        return fulfillmentComponent;
    }

    /**
     * @dev Saves an array of FulfillmentComponents as a named default.
     *
     * @param fulfillmentComponents the FulfillmentComponents to save as a
     *                              default
     * @param defaultName           the name of the default for retrieval
     *
     * @return _fulfillmentComponents the FulfillmentComponents saved as a
     *                                default
     */
    function saveDefaultMany(
        FulfillmentComponent[] memory fulfillmentComponents,
        string memory defaultName
    ) internal returns (FulfillmentComponent[] memory _fulfillmentComponents) {
        mapping(string => FulfillmentComponent[])
            storage fulfillmentComponentsMap = _fulfillmentComponentsMap();
        FulfillmentComponent[] storage components = fulfillmentComponentsMap[
            defaultName
        ];
        clear(components);
        StructCopier.setFulfillmentComponents(
            components,
            fulfillmentComponents
        );

        return fulfillmentComponents;
    }

    /**
     * @dev Makes a copy of an FulfillmentComponent in-memory.
     *
     * @param component the FulfillmentComponent to make a copy of in-memory.
     *
     * @return copiedComponent the copied FulfillmentComponent
     */
    function copy(
        FulfillmentComponent memory component
    ) internal pure returns (FulfillmentComponent memory) {
        return
            FulfillmentComponent({
                orderIndex: component.orderIndex,
                itemIndex: component.itemIndex
            });
    }

    /**
     * @dev Makes a copy of an array of FulfillmentComponents in-memory.
     *
     * @param components the FulfillmentComponents to make a copy of in-memory.
     *
     * @return copiedComponents the copied FulfillmentComponents
     */
    function copy(
        FulfillmentComponent[] memory components
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory copiedItems = new FulfillmentComponent[](
            components.length
        );
        for (uint256 i = 0; i < components.length; i++) {
            copiedItems[i] = copy(components[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Creates an empty FulfillmentComponent.
     *
     * @return component the empty FulfillmentComponent
     *
     * @custom:return emptyComponent the empty FulfillmentComponent
     */
    function empty() internal pure returns (FulfillmentComponent memory) {
        return FulfillmentComponent({ orderIndex: 0, itemIndex: 0 });
    }

    /**
     * @dev Gets the storage position of the default FulfillmentComponent map.
     *
     * @custom:return position the storage position of the default
     *                         FulfillmentComponent
     */
    function _fulfillmentComponentMap()
        private
        pure
        returns (
            mapping(string => FulfillmentComponent)
                storage fulfillmentComponentMap
        )
    {
        bytes32 position = FULFILLMENT_COMPONENT_MAP_POSITION;
        assembly {
            fulfillmentComponentMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default FulfillmentComponent array
     * map.
     *
     * @custom:return position the storage position of the default
     *                         FulfillmentComponent array
     */
    function _fulfillmentComponentsMap()
        private
        pure
        returns (
            mapping(string => FulfillmentComponent[])
                storage fulfillmentComponentsMap
        )
    {
        bytes32 position = FULFILLMENT_COMPONENTS_MAP_POSITION;
        assembly {
            fulfillmentComponentsMap.slot := position
        }
    }

    // Methods for configuring a single of each of a FulfillmentComponent's
    // fields, which modify the FulfillmentComponent in-place and return it.

    /**
     * @dev Sets the orderIndex of a FulfillmentComponent.
     *
     * @param component  the FulfillmentComponent to set the orderIndex of
     * @param orderIndex the orderIndex to set
     *
     * @return component the FulfillmentComponent with the orderIndex set
     */
    function withOrderIndex(
        FulfillmentComponent memory component,
        uint256 orderIndex
    ) internal pure returns (FulfillmentComponent memory) {
        component.orderIndex = orderIndex;
        return component;
    }

    /**
     * @dev Sets the itemIndex of a FulfillmentComponent.
     *
     * @param component the FulfillmentComponent to set the itemIndex of
     * @param itemIndex the itemIndex to set
     *
     * @return component the FulfillmentComponent with the itemIndex set
     */
    function withItemIndex(
        FulfillmentComponent memory component,
        uint256 itemIndex
    ) internal pure returns (FulfillmentComponent memory) {
        component.itemIndex = itemIndex;
        return component;
    }
}
