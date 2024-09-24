/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./IPerpsV2MarketBaseTypes.sol";

interface IPerpsV2MarketDelayedIntent {
    function submitCloseOffchainDelayedOrderWithTracking(uint desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseDelayedOrderWithTracking(
        uint desiredTimeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitDelayedOrder(
        int sizeDelta,
        uint desiredTimeDelta,
        uint desiredFillPrice
    ) external;

    function submitDelayedOrderWithTracking(
        int sizeDelta,
        uint desiredTimeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitOffchainDelayedOrder(int sizeDelta, uint desiredFillPrice) external;

    function submitOffchainDelayedOrderWithTracking(
        int sizeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;
}
