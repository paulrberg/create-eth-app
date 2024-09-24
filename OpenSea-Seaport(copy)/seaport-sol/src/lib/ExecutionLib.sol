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
    Execution,
    ItemType,
    ReceivedItem
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { ReceivedItemLib } from "./ReceivedItemLib.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title ExecutionLib
 * @author James Wenzel (emo.eth)
 * @notice ExecutionLib is a library for managing Execution structs and arrays.
 *         It allows chaining of functions to make struct creation more
 *         readable.
 */
library ExecutionLib {
    bytes32 private constant EXECUTION_MAP_POSITION =
        keccak256("seaport.ExecutionDefaults");
    bytes32 private constant EXECUTIONS_MAP_POSITION =
        keccak256("seaport.ExecutionsDefaults");
    bytes32 private constant EMPTY_EXECUTION =
        keccak256(
            abi.encode(
                Execution({
                    item: ReceivedItem({
                        itemType: ItemType(0),
                        token: address(0),
                        identifier: 0,
                        amount: 0,
                        recipient: payable(address(0))
                    }),
                    offerer: address(0),
                    conduitKey: bytes32(0)
                })
            )
        );

    using ReceivedItemLib for ReceivedItem;
    using ReceivedItemLib for ReceivedItem[];

    /**
     * @dev Clears a default Execution from storage.
     *
     * @param defaultName the name of the default to clear.
     */
    function clear(string memory defaultName) internal {
        mapping(string => Execution) storage executionMap = _executionMap();
        Execution storage item = executionMap[defaultName];
        clear(item);
    }

    /**
     * @dev Clears all fields on an Execution.
     *
     * @param execution the Execution to clear
     */
    function clear(Execution storage execution) internal {
        // clear all fields
        execution.item = ReceivedItemLib.empty();
        execution.offerer = address(0);
        execution.conduitKey = bytes32(0);
    }

    /**
     * @dev Clears an array of Executions from storage.
     *
     * @param executions the name of the default to clear
     */
    function clear(Execution[] storage executions) internal {
        while (executions.length > 0) {
            clear(executions[executions.length - 1]);
            executions.pop();
        }
    }

    /**
     * @dev Gets a default Execution from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return item the Execution retrieved from storage
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (Execution memory item) {
        mapping(string => Execution) storage executionMap = _executionMap();
        item = executionMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_EXECUTION) {
            revert("Empty Execution selected.");
        }
    }

    /**
     * @dev Gets an array of default Executions from storage.
     *
     * @param defaultName the name of the default for retrieval
     *
     * @return items the Executions retrieved from storage
     */
    function fromDefaultMany(
        string memory defaultName
    ) internal view returns (Execution[] memory items) {
        mapping(string => Execution[]) storage executionsMap = _executionsMap();
        items = executionsMap[defaultName];

        if (items.length == 0) {
            revert("Empty Execution array selected.");
        }
    }

    /**
     * @dev Saves an Execution as a named default.
     *
     * @param execution   the Execution to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _execution the Execution saved as a default
     */
    function saveDefault(
        Execution memory execution,
        string memory defaultName
    ) internal returns (Execution memory _execution) {
        mapping(string => Execution) storage executionMap = _executionMap();
        executionMap[defaultName] = execution;
        return execution;
    }

    /**
     * @dev Saves an array of Executions as a named default.
     *
     * @param executions  the Executions to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _executions the Executions saved as a default
     */
    function saveDefaultMany(
        Execution[] memory executions,
        string memory defaultName
    ) internal returns (Execution[] memory _executions) {
        mapping(string => Execution[]) storage executionsMap = _executionsMap();
        StructCopier.setExecutions(executionsMap[defaultName], executions);
        return executions;
    }

    /**
     * @dev Makes a copy of an Execution in-memory.
     *
     * @param item the Execution to make a copy of in-memory
     *
     * @custom:return copy the copy of the Execution in-memory
     */
    function copy(
        Execution memory item
    ) internal pure returns (Execution memory) {
        return
            Execution({
                item: item.item.copy(),
                offerer: item.offerer,
                conduitKey: item.conduitKey
            });
    }

    /**
     * @dev Makes a copy of an array of Executions in-memory.
     *
     * @param items the array of Executions to make a copy of in-memory
     *
     * @custom:return copy the copy of the array of Executions in-memory
     */
    function copy(
        Execution[] memory items
    ) internal pure returns (Execution[] memory) {
        Execution[] memory copies = new Execution[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            copies[i] = copy(items[i]);
        }
        return copies;
    }

    /**
     * @dev Creates an empty Execution.
     *
     * @custom:return empty the empty Execution
     */
    function empty() internal pure returns (Execution memory) {
        return
            Execution({
                item: ReceivedItemLib.empty(),
                offerer: address(0),
                conduitKey: bytes32(0)
            });
    }

    /**
     * @dev Gets the storage position of the default Execution map.
     *
     * @return executionMap the storage position of the default Execution map
     */
    function _executionMap()
        private
        pure
        returns (mapping(string => Execution) storage executionMap)
    {
        bytes32 position = EXECUTION_MAP_POSITION;
        assembly {
            executionMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default array of Executions map.
     *
     * @return executionsMap the storage position of the default Executions map
     */
    function _executionsMap()
        private
        pure
        returns (mapping(string => Execution[]) storage executionsMap)
    {
        bytes32 position = EXECUTIONS_MAP_POSITION;
        assembly {
            executionsMap.slot := position
        }
    }

    // Methods for configuring a single of each of an Execution's fields, which
    // modify the Execution in-place and return it.

    /**
     * @dev Configures an Execution's item field.
     *
     * @param execution the Execution to configure
     * @param item      the value to set the Execution's item field to
     *
     * @return _execution the configured Execution
     */
    function withItem(
        Execution memory execution,
        ReceivedItem memory item
    ) internal pure returns (Execution memory) {
        execution.item = item.copy();
        return execution;
    }

    /**
     * @dev Configures an Execution's offerer field.
     *
     * @param execution the Execution to configure
     * @param offerer   the value to set the Execution's offerer field to
     *
     * @return _execution the configured Execution
     */
    function withOfferer(
        Execution memory execution,
        address offerer
    ) internal pure returns (Execution memory) {
        execution.offerer = offerer;
        return execution;
    }

    /**
     * @dev Configures an Execution's conduitKey field.
     *
     * @param execution the Execution to configure
     * @param conduitKey the value to set the Execution's conduitKey field to
     *
     * @return _execution the configured Execution
     */
    function withConduitKey(
        Execution memory execution,
        bytes32 conduitKey
    ) internal pure returns (Execution memory) {
        execution.conduitKey = conduitKey;
        return execution;
    }
}
