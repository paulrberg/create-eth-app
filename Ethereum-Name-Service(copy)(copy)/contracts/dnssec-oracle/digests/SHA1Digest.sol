/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  pragma solidity ^0.8.4;

import "./Digest.sol";
import "../BytesUtils.sol";
import "Ethereum-Name-Service/@ensdomains/solsha1/contracts/SHA1.sol";

/**
 * @dev Implements the DNSSEC SHA1 digest.
 */
contract SHA1Digest is Digest {
    using BytesUtils for *;

    function verify(
        bytes calldata data,
        bytes calldata hash
    ) external pure override returns (bool) {
        require(hash.length == 20, "Invalid sha1 hash length");
        bytes32 expected = hash.readBytes20(0);
        bytes20 computed = SHA1.sha1(data);
        return expected == computed;
    }
}
