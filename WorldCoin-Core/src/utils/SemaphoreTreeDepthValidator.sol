/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/WorldCoin-Core?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title Semaphore tree depth validator
/// @author Worldcoin
/// @notice
library SemaphoreTreeDepthValidator {
    /// @notice Checks if the provided `treeDepth` is amoung supported depths.
    ///
    /// @param treeDepth The tree depth to validate.
    /// @return supportedDepth Returns `true` if `treeDepth` is between 16 and 32 - depths supported by the Semaphore
    function validate(uint8 treeDepth) internal pure returns (bool supportedDepth) {
        uint8 minDepth = 16;
        uint8 maxDepth = 32;
        return treeDepth >= minDepth && treeDepth <= maxDepth;
    }
}
