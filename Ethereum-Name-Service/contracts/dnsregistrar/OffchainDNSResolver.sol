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
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../contracts/resolvers/profiles/IAddrResolver.sol";
import "../../contracts/resolvers/profiles/IExtendedResolver.sol";
import "../../contracts/resolvers/profiles/IExtendedDNSResolver.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../dnssec-oracle/BytesUtils.sol";
import "../dnssec-oracle/DNSSEC.sol";
import "../dnssec-oracle/RRUtils.sol";
import "../registry/ENSRegistry.sol";
import "../utils/HexUtils.sol";

error OffchainLookup(
    address sender,
    string[] urls,
    bytes callData,
    bytes4 callbackFunction,
    bytes extraData
);

interface IDNSGateway {
    function resolve(
        bytes memory name,
        uint16 qtype
    ) external returns (DNSSEC.RRSetWithSignature[] memory);
}

uint16 constant CLASS_INET = 1;
uint16 constant TYPE_TXT = 16;

contract OffchainDNSResolver is IExtendedResolver {
    using RRUtils for *;
    using BytesUtils for bytes;
    using HexUtils for bytes;

    ENS public immutable ens;
    DNSSEC public immutable oracle;
    string public gatewayURL;

    error CouldNotResolve(bytes name);

    constructor(ENS _ens, DNSSEC _oracle, string memory _gatewayURL) {
        ens = _ens;
        oracle = _oracle;
        gatewayURL = _gatewayURL;
    }

    function resolve(
        bytes calldata name,
        bytes calldata data
    ) external view returns (bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = gatewayURL;

        revert OffchainLookup(
            address(this),
            urls,
            abi.encodeCall(IDNSGateway.resolve, (name, TYPE_TXT)),
            OffchainDNSResolver.resolveCallback.selector,
            abi.encode(name, data)
        );
    }

    function resolveCallback(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes memory) {
        (bytes memory name, bytes memory query) = abi.decode(
            extraData,
            (bytes, bytes)
        );
        DNSSEC.RRSetWithSignature[] memory rrsets = abi.decode(
            response,
            (DNSSEC.RRSetWithSignature[])
        );

        (bytes memory data, ) = oracle.verifyRRSet(rrsets);
        for (
            RRUtils.RRIterator memory iter = data.iterateRRs(0);
            !iter.done();
            iter.next()
        ) {
            // Ignore records with wrong name, type, or class
            bytes memory rrname = RRUtils.readName(iter.data, iter.offset);
            if (
                !rrname.equals(name) ||
                iter.class != CLASS_INET ||
                iter.dnstype != TYPE_TXT
            ) {
                continue;
            }

            // Look for a valid ENS-DNS TXT record
            (address dnsresolver, bytes memory context) = parseRR(
                iter.data,
                iter.rdataOffset,
                iter.nextOffset
            );

            // If we found a valid record, try to resolve it
            if (dnsresolver != address(0)) {
                if (
                    IERC165(dnsresolver).supportsInterface(
                        IExtendedDNSResolver.resolve.selector
                    )
                ) {
                    return
                        IExtendedDNSResolver(dnsresolver).resolve(
                            name,
                            query,
                            context
                        );
                } else if (
                    IERC165(dnsresolver).supportsInterface(
                        IExtendedResolver.resolve.selector
                    )
                ) {
                    return IExtendedResolver(dnsresolver).resolve(name, query);
                } else {
                    (bool ok, bytes memory ret) = address(dnsresolver)
                        .staticcall(query);
                    if (ok) {
                        return ret;
                    } else {
                        revert CouldNotResolve(name);
                    }
                }
            }
        }

        // No valid records; revert.
        revert CouldNotResolve(name);
    }

    function parseRR(
        bytes memory data,
        uint256 idx,
        uint256 lastIdx
    ) internal view returns (address, bytes memory) {
        bytes memory txt = readTXT(data, idx, lastIdx);

        // Must start with the magic word
        if (txt.length < 5 || !txt.equals(0, "ENS1 ", 0, 5)) {
            return (address(0), "");
        }

        // Parse the name or address
        uint256 lastTxtIdx = txt.find(5, txt.length - 5, " ");
        if (lastTxtIdx > txt.length) {
            address dnsResolver = parseAndResolve(txt, 5, txt.length);
            return (dnsResolver, "");
        } else {
            address dnsResolver = parseAndResolve(txt, 5, lastTxtIdx);
            return (
                dnsResolver,
                txt.substring(lastTxtIdx + 1, txt.length - lastTxtIdx - 1)
            );
        }
    }

    function readTXT(
        bytes memory data,
        uint256 startIdx,
        uint256 lastIdx
    ) internal pure returns (bytes memory) {
        // TODO: Concatenate multiple text fields
        uint256 fieldLength = data.readUint8(startIdx);
        assert(startIdx + fieldLength < lastIdx);
        return data.substring(startIdx + 1, fieldLength);
    }

    function parseAndResolve(
        bytes memory nameOrAddress,
        uint256 idx,
        uint256 lastIdx
    ) internal view returns (address) {
        if (nameOrAddress[idx] == "0" && nameOrAddress[idx + 1] == "x") {
            (address ret, bool valid) = nameOrAddress.hexToAddress(
                idx + 2,
                lastIdx
            );
            if (valid) {
                return ret;
            }
        }
        return resolveName(nameOrAddress, idx, lastIdx);
    }

    function resolveName(
        bytes memory name,
        uint256 idx,
        uint256 lastIdx
    ) internal view returns (address) {
        bytes32 node = textNamehash(name, idx, lastIdx);
        address resolver = ens.resolver(node);
        if (resolver == address(0)) {
            return address(0);
        }
        return IAddrResolver(resolver).addr(node);
    }

    /**
     * @dev Namehash function that operates on dot-separated names (not dns-encoded names)
     * @param name Name to hash
     * @param idx Index to start at
     * @param lastIdx Index to end at
     */
    function textNamehash(
        bytes memory name,
        uint256 idx,
        uint256 lastIdx
    ) internal view returns (bytes32) {
        uint256 separator = name.find(idx, name.length - idx, bytes1("."));
        bytes32 parentNode = bytes32(0);
        if (separator < lastIdx) {
            parentNode = textNamehash(name, separator + 1, lastIdx);
        } else {
            separator = lastIdx;
        }
        return
            keccak256(
                abi.encodePacked(parentNode, name.keccak(idx, separator - idx))
            );
    }
}
