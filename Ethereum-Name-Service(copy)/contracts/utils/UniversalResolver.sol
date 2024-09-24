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
pragma solidity >=0.8.17 <0.9.0;

import {ERC165} from "Ethereum-Name-Service/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "Ethereum-Name-Service/@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "Ethereum-Name-Service/@openzeppelin/contracts/utils/Address.sol";
import {LowLevelCallUtils} from "./LowLevelCallUtils.sol";
import {ENS} from "../registry/ENS.sol";
import {IExtendedResolver} from "../resolvers/profiles/IExtendedResolver.sol";
import {Resolver, INameResolver, IAddrResolver} from "../resolvers/Resolver.sol";
import {NameEncoder} from "./NameEncoder.sol";
import {BytesUtils} from "../wrapper/BytesUtils.sol";
import {HexUtils} from "./HexUtils.sol";

error OffchainLookup(
    address sender,
    string[] urls,
    bytes callData,
    bytes4 callbackFunction,
    bytes extraData
);

error ResolverNotFound();

error ResolverWildcardNotSupported();

struct MulticallData {
    bytes name;
    bytes[] data;
    string[] gateways;
    bytes4 callbackFunction;
    bool isWildcard;
    address resolver;
    bytes metaData;
    bool[] failures;
}

struct OffchainLookupCallData {
    address sender;
    string[] urls;
    bytes callData;
}

struct OffchainLookupExtraData {
    bytes4 callbackFunction;
    bytes data;
}

interface BatchGateway {
    function query(
        OffchainLookupCallData[] memory data
    ) external returns (bool[] memory failures, bytes[] memory responses);
}

/**
 * The Universal Resolver is a contract that handles the work of resolving a name entirely onchain,
 * making it possible to make a single smart contract call to resolve an ENS name.
 */
contract UniversalResolver is ERC165, Ownable {
    using Address for address;
    using NameEncoder for string;
    using BytesUtils for bytes;
    using HexUtils for bytes;

    string[] public batchGatewayURLs;
    ENS public immutable registry;

    constructor(address _registry, string[] memory _urls) {
        registry = ENS(_registry);
        batchGatewayURLs = _urls;
    }

    function setGatewayURLs(string[] memory _urls) public onlyOwner {
        batchGatewayURLs = _urls;
    }

    /**
     * @dev Performs ENS name resolution for the supplied name and resolution data.
     * @param name The name to resolve, in normalised and DNS-encoded form.
     * @param data The resolution data, as specified in ENSIP-10.
     * @return The result of resolving the name.
     */
    function resolve(
        bytes calldata name,
        bytes memory data
    ) external view returns (bytes memory, address) {
        return
            _resolveSingle(
                name,
                data,
                batchGatewayURLs,
                this.resolveSingleCallback.selector,
                ""
            );
    }

    function resolve(
        bytes calldata name,
        bytes[] memory data
    ) external view returns (bytes[] memory, address) {
        return resolve(name, data, batchGatewayURLs);
    }

    function resolve(
        bytes calldata name,
        bytes memory data,
        string[] memory gateways
    ) external view returns (bytes memory, address) {
        return
            _resolveSingle(
                name,
                data,
                gateways,
                this.resolveSingleCallback.selector,
                ""
            );
    }

    function resolve(
        bytes calldata name,
        bytes[] memory data,
        string[] memory gateways
    ) public view returns (bytes[] memory, address) {
        return
            _resolve(name, data, gateways, this.resolveCallback.selector, "");
    }

    function _resolveSingle(
        bytes calldata name,
        bytes memory data,
        string[] memory gateways,
        bytes4 callbackFunction,
        bytes memory metaData
    ) public view returns (bytes memory, address) {
        bytes[] memory dataArr = new bytes[](1);
        dataArr[0] = data;
        (bytes[] memory results, address resolver) = _resolve(
            name,
            dataArr,
            gateways,
            callbackFunction,
            metaData
        );
        return (results[0], resolver);
    }

    function _resolve(
        bytes calldata name,
        bytes[] memory data,
        string[] memory gateways,
        bytes4 callbackFunction,
        bytes memory metaData
    ) internal view returns (bytes[] memory results, address resolverAddress) {
        (Resolver resolver, , uint256 finalOffset) = findResolver(name);
        resolverAddress = address(resolver);
        if (resolverAddress == address(0)) {
            revert ResolverNotFound();
        }

        bool isWildcard = finalOffset != 0;

        results = _multicall(
            MulticallData(
                name,
                data,
                gateways,
                callbackFunction,
                isWildcard,
                resolverAddress,
                metaData,
                new bool[](data.length)
            )
        );
    }

    function reverse(
        bytes calldata reverseName
    ) external view returns (string memory, address, address, address) {
        return reverse(reverseName, batchGatewayURLs);
    }

    /**
     * @dev Performs ENS name reverse resolution for the supplied reverse name.
     * @param reverseName The reverse name to resolve, in normalised and DNS-encoded form. e.g. b6E040C9ECAaE172a89bD561c5F73e1C48d28cd9.addr.reverse
     * @return The resolved name, the resolved address, the reverse resolver address, and the resolver address.
     */
    function reverse(
        bytes calldata reverseName,
        string[] memory gateways
    ) public view returns (string memory, address, address, address) {
        bytes memory encodedCall = abi.encodeCall(
            INameResolver.name,
            reverseName.namehash(0)
        );
        (
            bytes memory resolvedReverseData,
            address reverseResolverAddress
        ) = _resolveSingle(
                reverseName,
                encodedCall,
                gateways,
                this.reverseCallback.selector,
                ""
            );

        return
            getForwardDataFromReverse(
                resolvedReverseData,
                reverseResolverAddress,
                gateways
            );
    }

    function getForwardDataFromReverse(
        bytes memory resolvedReverseData,
        address reverseResolverAddress,
        string[] memory gateways
    ) internal view returns (string memory, address, address, address) {
        string memory resolvedName = abi.decode(resolvedReverseData, (string));

        (bytes memory encodedName, bytes32 namehash) = resolvedName
            .dnsEncodeName();

        bytes memory encodedCall = abi.encodeCall(IAddrResolver.addr, namehash);
        bytes memory metaData = abi.encode(
            resolvedName,
            reverseResolverAddress
        );
        (bytes memory resolvedData, address resolverAddress) = this
            ._resolveSingle(
                encodedName,
                encodedCall,
                gateways,
                this.reverseCallback.selector,
                metaData
            );

        address resolvedAddress = abi.decode(resolvedData, (address));

        return (
            resolvedName,
            resolvedAddress,
            reverseResolverAddress,
            resolverAddress
        );
    }

    function resolveSingleCallback(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes memory, address) {
        (bytes[] memory results, address resolver, , ) = _resolveCallback(
            response,
            extraData,
            this.resolveSingleCallback.selector
        );
        return (results[0], resolver);
    }

    function resolveCallback(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes[] memory, address) {
        (bytes[] memory results, address resolver, , ) = _resolveCallback(
            response,
            extraData,
            this.resolveCallback.selector
        );
        return (results, resolver);
    }

    function reverseCallback(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (string memory, address, address, address) {
        (
            bytes[] memory resolvedData,
            address resolverAddress,
            string[] memory gateways,
            bytes memory metaData
        ) = _resolveCallback(
                response,
                extraData,
                this.reverseCallback.selector
            );

        if (metaData.length > 0) {
            (string memory resolvedName, address reverseResolverAddress) = abi
                .decode(metaData, (string, address));
            address resolvedAddress = abi.decode(resolvedData[0], (address));
            return (
                resolvedName,
                resolvedAddress,
                reverseResolverAddress,
                resolverAddress
            );
        }

        return
            getForwardDataFromReverse(
                resolvedData[0],
                resolverAddress,
                gateways
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _resolveCallback(
        bytes calldata response,
        bytes calldata extraData,
        bytes4 callbackFunction
    )
        internal
        view
        returns (bytes[] memory, address, string[] memory, bytes memory)
    {
        MulticallData memory multicallData;
        multicallData.callbackFunction = callbackFunction;
        (bool[] memory failures, bytes[] memory responses) = abi.decode(
            response,
            (bool[], bytes[])
        );
        OffchainLookupExtraData[] memory extraDatas;
        (
            multicallData.isWildcard,
            multicallData.resolver,
            multicallData.gateways,
            multicallData.metaData,
            extraDatas
        ) = abi.decode(
            extraData,
            (bool, address, string[], bytes, OffchainLookupExtraData[])
        );
        require(responses.length <= extraDatas.length);
        multicallData.data = new bytes[](extraDatas.length);
        multicallData.failures = new bool[](extraDatas.length);
        uint256 offchainCount = 0;
        for (uint256 i = 0; i < extraDatas.length; i++) {
            if (extraDatas[i].callbackFunction == bytes4(0)) {
                // This call did not require an offchain lookup; use the previous input data.
                multicallData.data[i] = extraDatas[i].data;
            } else {
                if (failures[offchainCount]) {
                    multicallData.failures[i] = true;
                    multicallData.data[i] = responses[offchainCount];
                } else {
                    multicallData.data[i] = abi.encodeWithSelector(
                        extraDatas[i].callbackFunction,
                        responses[offchainCount],
                        extraDatas[i].data
                    );
                }
                offchainCount = offchainCount + 1;
            }
        }

        return (
            _multicall(multicallData),
            multicallData.resolver,
            multicallData.gateways,
            multicallData.metaData
        );
    }

    /**
     * @dev Makes a call to `target` with `data`. If the call reverts with an `OffchainLookup` error, wraps
     *      the error with the data necessary to continue the request where it left off.
     * @param target The address to call.
     * @param data The data to call `target` with.
     * @return offchain Whether the call reverted with an `OffchainLookup` error.
     * @return returnData If `target` did not revert, contains the return data from the call to `target`. Otherwise, contains a `OffchainLookupCallData` struct.
     * @return extraData If `target` did not revert, is empty. Otherwise, contains a `OffchainLookupExtraData` struct.
     * @return result Whether the call succeeded.
     */
    function callWithOffchainLookupPropagation(
        address target,
        bytes memory data
    )
        internal
        view
        returns (
            bool offchain,
            bytes memory returnData,
            OffchainLookupExtraData memory extraData,
            bool result
        )
    {
        result = LowLevelCallUtils.functionStaticCall(address(target), data);
        uint256 size = LowLevelCallUtils.returnDataSize();

        if (result) {
            return (
                false,
                LowLevelCallUtils.readReturnData(0, size),
                extraData,
                true
            );
        }

        // Failure
        if (size >= 4) {
            bytes memory errorId = LowLevelCallUtils.readReturnData(0, 4);
            // Offchain lookup. Decode the revert message and create our own that nests it.
            bytes memory revertData = LowLevelCallUtils.readReturnData(
                4,
                size - 4
            );
            if (bytes4(errorId) == OffchainLookup.selector) {
                (
                    address wrappedSender,
                    string[] memory wrappedUrls,
                    bytes memory wrappedCallData,
                    bytes4 wrappedCallbackFunction,
                    bytes memory wrappedExtraData
                ) = abi.decode(
                        revertData,
                        (address, string[], bytes, bytes4, bytes)
                    );
                if (wrappedSender == target) {
                    returnData = abi.encode(
                        OffchainLookupCallData(
                            wrappedSender,
                            wrappedUrls,
                            wrappedCallData
                        )
                    );
                    extraData = OffchainLookupExtraData(
                        wrappedCallbackFunction,
                        wrappedExtraData
                    );
                    return (true, returnData, extraData, false);
                }
            } else {
                returnData = bytes.concat(errorId, revertData);
                return (false, returnData, extraData, false);
            }
        }
    }

    /**
     * @dev Finds a resolver by recursively querying the registry, starting at the longest name and progressively
     *      removing labels until it finds a result.
     * @param name The name to resolve, in DNS-encoded and normalised form.
     * @return resolver The Resolver responsible for this name.
     * @return namehash The namehash of the full name.
     * @return finalOffset The offset of the first label with a resolver.
     */
    function findResolver(
        bytes calldata name
    ) public view returns (Resolver, bytes32, uint256) {
        (
            address resolver,
            bytes32 namehash,
            uint256 finalOffset
        ) = findResolver(name, 0);
        return (Resolver(resolver), namehash, finalOffset);
    }

    function findResolver(
        bytes calldata name,
        uint256 offset
    ) internal view returns (address, bytes32, uint256) {
        uint256 labelLength = uint256(uint8(name[offset]));
        if (labelLength == 0) {
            return (address(0), bytes32(0), offset);
        }
        uint256 nextLabel = offset + labelLength + 1;
        bytes32 labelHash;
        if (
            labelLength == 66 &&
            // 0x5b == '['
            name[offset + 1] == 0x5b &&
            // 0x5d == ']'
            name[nextLabel - 1] == 0x5d
        ) {
            // Encrypted label
            (labelHash, ) = bytes(name[offset + 2:nextLabel - 1])
                .hexStringToBytes32(0, 64);
        } else {
            labelHash = keccak256(name[offset + 1:nextLabel]);
        }
        (
            address parentresolver,
            bytes32 parentnode,
            uint256 parentoffset
        ) = findResolver(name, nextLabel);
        bytes32 node = keccak256(abi.encodePacked(parentnode, labelHash));
        address resolver = registry.resolver(node);
        if (resolver != address(0)) {
            return (resolver, node, offset);
        }
        return (parentresolver, node, parentoffset);
    }

    function _hasExtendedResolver(
        address resolver
    ) internal view returns (bool) {
        try
            Resolver(resolver).supportsInterface{gas: 50000}(
                type(IExtendedResolver).interfaceId
            )
        returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }

    function _multicall(
        MulticallData memory multicallData
    ) internal view returns (bytes[] memory results) {
        uint256 length = multicallData.data.length;
        uint256 offchainCount = 0;
        OffchainLookupCallData[]
            memory callDatas = new OffchainLookupCallData[](length);
        OffchainLookupExtraData[]
            memory extraDatas = new OffchainLookupExtraData[](length);
        results = new bytes[](length);
        bool isCallback = multicallData.name.length == 0;
        bool hasExtendedResolver = _hasExtendedResolver(multicallData.resolver);

        if (multicallData.isWildcard && !hasExtendedResolver) {
            revert ResolverWildcardNotSupported();
        }

        for (uint256 i = 0; i < length; i++) {
            bytes memory item = multicallData.data[i];
            bool failure = multicallData.failures[i];
            if (failure) {
                results[i] = item;
                continue;
            }
            if (!isCallback && hasExtendedResolver) {
                item = abi.encodeCall(
                    IExtendedResolver.resolve,
                    (multicallData.name, item)
                );
            }
            (
                bool offchain,
                bytes memory returnData,
                OffchainLookupExtraData memory extraData,
                bool success
            ) = callWithOffchainLookupPropagation(multicallData.resolver, item);

            if (offchain) {
                callDatas[offchainCount] = abi.decode(
                    returnData,
                    (OffchainLookupCallData)
                );
                extraDatas[i] = extraData;
                offchainCount += 1;
                continue;
            }

            if (success && hasExtendedResolver) {
                // if this is a successful resolve() call, unwrap the result
                returnData = abi.decode(returnData, (bytes));
            }
            results[i] = returnData;
            extraDatas[i].data = multicallData.data[i];
        }

        if (offchainCount == 0) {
            return results;
        }

        // Trim callDatas if offchain data exists
        assembly {
            mstore(callDatas, offchainCount)
        }

        revert OffchainLookup(
            address(this),
            multicallData.gateways,
            abi.encodeWithSelector(BatchGateway.query.selector, callDatas),
            multicallData.callbackFunction,
            abi.encode(
                multicallData.isWildcard,
                multicallData.resolver,
                multicallData.gateways,
                multicallData.metaData,
                extraDatas
            )
        );
    }
}
