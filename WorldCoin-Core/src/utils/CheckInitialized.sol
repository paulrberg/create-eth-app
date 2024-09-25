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

import {Initializable} from "WorldCoin-Core/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @title Initialization Checker
/// @author Worldcoin
/// @notice A contract that represents the ability to initialize a proxy-based contract but also to
///         check that said contract is initialized.
contract CheckInitialized is Initializable {
    /// @notice Whether the initialization has been completed.
    /// @dev This relies on the fact that a default-init `bool` is `false` here.
    bool private _initialized;

    /// @notice Thrown when attempting to call a function while the implementation has not been
    ///         initialized.
    error ImplementationNotInitialized();

    /// @notice Sets the contract as initialized.
    function __setInitialized() internal onlyInitializing {
        _initialized = true;
    }

    /// @notice Asserts that the annotated function can only be called once the contract has been
    ///         initialized.
    modifier onlyInitialized() {
        if (!_initialized) {
            revert ImplementationNotInitialized();
        }
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
