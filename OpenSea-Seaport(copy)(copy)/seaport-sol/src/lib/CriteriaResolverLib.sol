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

import { CriteriaResolver } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import { Side } from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationEnums.sol";

import { ArrayLib } from "./ArrayLib.sol";

import { StructCopier } from "./StructCopier.sol";

/**
 * @title CriteriaResolverLib
 * @author James Wenzel (emo.eth)
 * @notice CriteriaResolverLib is a library for managing CriteriaResolver
 *         structs and arrays. It allows chaining of functions to make
 *         struct creation more readable.
 */
library CriteriaResolverLib {
    bytes32 private constant CRITERIA_RESOLVER_MAP_POSITION =
        keccak256("seaport.CriteriaResolverDefaults");
    bytes32 private constant CRITERIA_RESOLVERS_MAP_POSITION =
        keccak256("seaport.CriteriaResolversDefaults");
    bytes32 private constant EMPTY_CRITERIA_RESOLVER =
        keccak256(
            abi.encode(
                CriteriaResolver({
                    orderIndex: 0,
                    side: Side(0),
                    index: 0,
                    identifier: 0,
                    criteriaProof: new bytes32[](0)
                })
            )
        );

    using ArrayLib for bytes32[];

    /**
     * @dev Clears a default CriteriaResolver from storage.
     *
     * @param defaultName the name of the default to clear
     */
    function clear(string memory defaultName) internal {
        mapping(string => CriteriaResolver)
            storage criteriaResolverMap = _criteriaResolverMap();
        CriteriaResolver storage resolver = criteriaResolverMap[defaultName];
        // clear all fields
        clear(resolver);
    }

    /**
     * @dev Clears all fields on a CriteriaResolver.
     *
     * @param resolver the CriteriaResolver to clear
     */
    function clear(CriteriaResolver storage resolver) internal {
        bytes32[] memory criteriaProof;
        resolver.orderIndex = 0;
        resolver.side = Side(0);
        resolver.index = 0;
        resolver.identifier = 0;
        ArrayLib.setBytes32s(resolver.criteriaProof, criteriaProof);
    }

    /**
     * @dev Clears an array of CriteriaResolvers from storage.
     *
     * @param resolvers the CriteriaResolvers to clear
     */
    function clear(CriteriaResolver[] storage resolvers) internal {
        while (resolvers.length > 0) {
            clear(resolvers[resolvers.length - 1]);
            resolvers.pop();
        }
    }

    /**
     * @dev Gets a default CriteriaResolver from storage.
     *
     * @param item the name of the default for retrieval
     */
    function fromDefault(
        string memory defaultName
    ) internal view returns (CriteriaResolver memory item) {
        mapping(string => CriteriaResolver)
            storage criteriaResolverMap = _criteriaResolverMap();
        item = criteriaResolverMap[defaultName];

        if (keccak256(abi.encode(item)) == EMPTY_CRITERIA_RESOLVER) {
            revert("Empty CriteriaResolver selected.");
        }
    }

    /**
     * @dev Gets an array of CriteriaResolvers from storage.
     *
     * @param defaultsName the name of the default array for retrieval
     *
     * @return items the CriteriaResolvers retrieved from storage
     */
    function fromDefaultMany(
        string memory defaultsName
    ) internal view returns (CriteriaResolver[] memory items) {
        mapping(string => CriteriaResolver[])
            storage criteriaResolversMap = _criteriaResolversMap();
        items = criteriaResolversMap[defaultsName];

        if (items.length == 0) {
            revert("Empty CriteriaResolver array selected.");
        }
    }

    /**
     * @dev Saves an CriteriaResolver as a named default.
     *
     * @param criteriaResolver the CriteriaResolver to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _criteriaResolver the CriteriaResolver that was saved
     */
    function saveDefault(
        CriteriaResolver memory criteriaResolver,
        string memory defaultName
    ) internal returns (CriteriaResolver memory _criteriaResolver) {
        mapping(string => CriteriaResolver)
            storage criteriaResolverMap = _criteriaResolverMap();
        CriteriaResolver storage resolver = criteriaResolverMap[defaultName];
        resolver.orderIndex = criteriaResolver.orderIndex;
        resolver.side = criteriaResolver.side;
        resolver.index = criteriaResolver.index;
        resolver.identifier = criteriaResolver.identifier;
        ArrayLib.setBytes32s(
            resolver.criteriaProof,
            criteriaResolver.criteriaProof
        );
        return criteriaResolver;
    }

    /**
     * @dev Saves an array of CriteriaResolvers as a named default.
     *
     * @param criteriaResolvers the CriteriaResolvers to save as a default
     * @param defaultName the name of the default for retrieval
     *
     * @return _criteriaResolvers the CriteriaResolvers that were saved
     */
    function saveDefaultMany(
        CriteriaResolver[] memory criteriaResolvers,
        string memory defaultName
    ) internal returns (CriteriaResolver[] memory _criteriaResolvers) {
        mapping(string => CriteriaResolver[])
            storage criteriaResolversMap = _criteriaResolversMap();
        CriteriaResolver[] storage resolvers = criteriaResolversMap[
            defaultName
        ];
        // todo: make sure we do this elsewhere
        clear(resolvers);
        StructCopier.setCriteriaResolvers(resolvers, criteriaResolvers);
        return criteriaResolvers;
    }

    /**
     * @dev Makes a copy of a CriteriaResolver in-memory.
     *
     * @param resolver the CriteriaResolver to make a copy of in-memory
     *
     * @custom:return copiedItem the copied CriteriaResolver
     */
    function copy(
        CriteriaResolver memory resolver
    ) internal pure returns (CriteriaResolver memory) {
        return
            CriteriaResolver({
                orderIndex: resolver.orderIndex,
                side: resolver.side,
                index: resolver.index,
                identifier: resolver.identifier,
                criteriaProof: resolver.criteriaProof.copy()
            });
    }

    /**
     * @dev Makes a copy of an array of CriteriaResolvers in-memory.
     *
     * @param resolvers the CriteriaResolvers to make a copy of in-memory
     *
     * @custom:return copiedItems the copied CriteriaResolvers
     */
    function copy(
        CriteriaResolver[] memory resolvers
    ) internal pure returns (CriteriaResolver[] memory) {
        CriteriaResolver[] memory copiedItems = new CriteriaResolver[](
            resolvers.length
        );
        for (uint256 i = 0; i < resolvers.length; i++) {
            copiedItems[i] = copy(resolvers[i]);
        }
        return copiedItems;
    }

    /**
     * @dev Creates an empty CriteriaResolver.
     *
     * @custom:return emptyResolver the empty CriteriaResolver
     */
    function empty() internal pure returns (CriteriaResolver memory) {
        bytes32[] memory proof;
        return
            CriteriaResolver({
                orderIndex: 0,
                side: Side(0),
                index: 0,
                identifier: 0,
                criteriaProof: proof
            });
    }

    /**
     * @dev Gets the storage position of the default CriteriaResolver map.
     *
     * @custom:return position the storage position of the default
     *                CriteriaResolver map.
     *
     */
    function _criteriaResolverMap()
        private
        pure
        returns (
            mapping(string => CriteriaResolver) storage criteriaResolverMap
        )
    {
        bytes32 position = CRITERIA_RESOLVER_MAP_POSITION;
        assembly {
            criteriaResolverMap.slot := position
        }
    }

    /**
     * @dev Gets the storage position of the default CriteriaResolver array map.
     *
     * @custom:return position the storage position of the default
     *                CriteriaResolver array map.
     *
     */
    function _criteriaResolversMap()
        private
        pure
        returns (
            mapping(string => CriteriaResolver[]) storage criteriaResolversMap
        )
    {
        bytes32 position = CRITERIA_RESOLVERS_MAP_POSITION;
        assembly {
            criteriaResolversMap.slot := position
        }
    }

    // Methods for configuring a single of each of an CriteriaResolver's fields,
    // which modify the CriteriaResolver in-place and return it.

    /**
     * @dev Sets the orderIndex of a CriteriaResolver.
     *
     * @param resolver   the CriteriaResolver to set the orderIndex of
     * @param orderIndex the orderIndex to set
     *
     * @return _resolver the CriteriaResolver with the orderIndex set
     */
    function withOrderIndex(
        CriteriaResolver memory resolver,
        uint256 orderIndex
    ) internal pure returns (CriteriaResolver memory) {
        resolver.orderIndex = orderIndex;
        return resolver;
    }

    /**
     * @dev Sets the side of a CriteriaResolver.
     *
     * @param resolver the CriteriaResolver to set the side of
     * @param side     the side to set
     *
     * @return _resolver the CriteriaResolver with the side set
     */
    function withSide(
        CriteriaResolver memory resolver,
        Side side
    ) internal pure returns (CriteriaResolver memory) {
        resolver.side = side;
        return resolver;
    }

    /**
     * @dev Sets the index of a CriteriaResolver.
     *
     * @param resolver the CriteriaResolver to set the index of
     * @param index    the index to set
     *
     * @return _resolver the CriteriaResolver with the index set
     */
    function withIndex(
        CriteriaResolver memory resolver,
        uint256 index
    ) internal pure returns (CriteriaResolver memory) {
        resolver.index = index;
        return resolver;
    }

    /**
     * @dev Sets the identifier of a CriteriaResolver.
     *
     * @param resolver   the CriteriaResolver to set the identifier of
     * @param identifier the identifier to set
     *
     * @return _resolver the CriteriaResolver with the identifier set
     */
    function withIdentifier(
        CriteriaResolver memory resolver,
        uint256 identifier
    ) internal pure returns (CriteriaResolver memory) {
        resolver.identifier = identifier;
        return resolver;
    }

    /**
     * @dev Sets the criteriaProof of a CriteriaResolver.
     *
     * @param resolver      the CriteriaResolver to set the criteriaProof of
     * @param criteriaProof the criteriaProof to set
     *
     * @return _resolver the CriteriaResolver with the criteriaProof set
     */
    function withCriteriaProof(
        CriteriaResolver memory resolver,
        bytes32[] memory criteriaProof
    ) internal pure returns (CriteriaResolver memory) {
        // todo: consider copying?
        resolver.criteriaProof = criteriaProof;
        return resolver;
    }
}
