/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Gnosis-Safe?utm=code
  */
  
  // SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../../libraries/SafeStorage.sol";

/**
 * @title Migration - Migrates a Safe contract from 1.3.0 to 1.2.0
 * @author Richard Meissner - @rmeissner
 */
contract Migration is SafeStorage {
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    address public immutable migrationSingleton;
    address public immutable safe120Singleton;

    constructor(address targetSingleton) {
        // Singleton address cannot be zero address.
        require(targetSingleton != address(0), "Invalid singleton address provided");
        safe120Singleton = targetSingleton;
        migrationSingleton = address(this);
    }

    event ChangedMasterCopy(address singleton);

    /**
     * @notice Migrates the Safe to the Singleton contract at `migrationSingleton`.
     * @dev This can only be called via a delegatecall.
     */
    function migrate() public {
        require(address(this) != migrationSingleton, "Migration should only be called via delegatecall");

        singleton = safe120Singleton;
        _deprecatedDomainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        emit ChangedMasterCopy(singleton);
    }
}
