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

import "./Algorithm.sol";
import "./EllipticCurve.sol";
import "../BytesUtils.sol";

contract P256SHA256Algorithm is Algorithm, EllipticCurve {
    using BytesUtils for *;

    /**
     * @dev Verifies a signature.
     * @param key The public key to verify with.
     * @param data The signed data to verify.
     * @param signature The signature to verify.
     * @return True iff the signature is valid.
     */
    function verify(
        bytes calldata key,
        bytes calldata data,
        bytes calldata signature
    ) external view override returns (bool) {
        return
            validateSignature(
                sha256(data),
                parseSignature(signature),
                parseKey(key)
            );
    }

    function parseSignature(
        bytes memory data
    ) internal pure returns (uint256[2] memory) {
        require(data.length == 64, "Invalid p256 signature length");
        return [uint256(data.readBytes32(0)), uint256(data.readBytes32(32))];
    }

    function parseKey(
        bytes memory data
    ) internal pure returns (uint256[2] memory) {
        require(data.length == 68, "Invalid p256 key length");
        return [uint256(data.readBytes32(4)), uint256(data.readBytes32(36))];
    }
}
