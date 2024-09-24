/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Manifold.xyz?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "Manifold.xyz/@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "Manifold.xyz/@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../core/ICreatorCore.sol";
import "./ICreatorExtensionBasic.sol";
import "./CreatorExtension.sol";

/**
 * @dev Provides functions to set token uri's
 */
abstract contract CreatorExtensionBasic is AdminControl, CreatorExtension, ICreatorExtensionBasic {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionBasic).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement ICreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri, bool identical) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement CreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURI}.
     */
    function setTokenURI(address creator, uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenIds, uris);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(address creator, string calldata prefix) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIPrefixExtension(prefix);
    }


}