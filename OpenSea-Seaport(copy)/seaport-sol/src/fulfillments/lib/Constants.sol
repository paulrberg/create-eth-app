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

// used to effectively "wipe" the mappings and enumerations each time getAggregated is called
bytes32 constant MATCH_FULFILLMENT_COUNTER_KEY = keccak256(
    "MatchFulfillmentHelper.fulfillmentCounter"
);

bytes32 constant MATCH_FULFILLMENT_STORAGE_BASE_KEY = keccak256(
    "MatchFulfillmentHelper.storageBase"
);

// used to effectively "wipe" the mappings and enumerations each time getAggregated is called
bytes32 constant FULFILL_AVAILABLE_COUNTER_KEY = keccak256(
    "FulfillAvailableHelper.fulfillmentCounter"
);

bytes32 constant FULFILL_AVAILABLE_STORAGE_BASE_KEY = keccak256(
    "FulfillAvailableHelper.storageBase"
);
