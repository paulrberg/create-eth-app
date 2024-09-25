/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/Moonbirds-Core?utm=code
  */
  
  // SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "Moonbirds-Core/@openzeppelin/contracts/access/Ownable.sol";
import "Moonbirds-Core/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
@title SignerManager
@notice Manges addition and removal of a core set of addresses from which
valid ECDSA signatures can be accepted; see SignatureChecker.
 */
contract SignerManager is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
    @dev Addresses from which signatures can be accepted.
     */
    EnumerableSet.AddressSet internal signers;

    /**
    @notice Add an address to the set of accepted signers.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }

    /**
    @notice Remove an address previously added with addSigner().
     */
    function removeSigner(address signer) external onlyOwner {
        signers.remove(signer);
    }
}
