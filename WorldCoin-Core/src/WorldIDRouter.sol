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

import {WorldIDProxy} from "./abstract/WorldIDProxy.sol";

/// @title WorldID Router
/// @author Worldcoin
/// @notice A router component to allow external clients to get group addresses from a trusted
///         source.
contract WorldIDRouter is WorldIDProxy {
    ///////////////////////////////////////////////////////////////////////////////
    ///                    !!!! DO NOT ADD MEMBERS HERE !!!!                    ///
    ///////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////
    ///                             CONSTRUCTION                                ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Constructs a new instance of the WorldID router.
    /// @dev This constructor is only called once, and can be called with the encoded call necessary
    ///      to initialize the logic contract.
    ///
    /// @param _logic The initial implementation (delegate) of the contract that this acts as a proxy
    ///        for.
    /// @param _data If this is non-empty, it is used as the data for a `delegatecall` to `_logic`.
    ///        This is usually an encoded function call, and allows for initialising the storage of
    ///        the proxy in a way similar to a traditional solidity constructor.
    constructor(address _logic, bytes memory _data) payable WorldIDProxy(_logic, _data) {
        // !!!! DO NOT PUT PROGRAM LOGIC HERE !!!!
        // It should go in the `initialize` function of the delegate instead.
    }
}
