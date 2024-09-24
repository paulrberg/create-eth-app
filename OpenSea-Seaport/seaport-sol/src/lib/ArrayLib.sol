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

/**
 * @title ArrayLib
 * @author James Wenzel (emo.eth)
 * @notice ArrayLib is a library for managing arrays.
 */
library ArrayLib {
    /**
     * @dev Sets the values of an array.
     *
     * @param array  the array to set
     * @param values the values to set
     */
    function setBytes32s(
        bytes32[] storage array,
        bytes32[] memory values
    ) internal {
        while (array.length > 0) {
            array.pop();
        }
        for (uint256 i = 0; i < values.length; i++) {
            array.push(values[i]);
        }
    }

    /**
     * @dev Makes a copy of an array.
     *
     * @param array the array to copy
     *
     * @custom:return copiedArray the copied array
     */
    function copy(
        bytes32[] memory array
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory copiedArray = new bytes32[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            copiedArray[i] = array[i];
        }
        return copiedArray;
    }
}
