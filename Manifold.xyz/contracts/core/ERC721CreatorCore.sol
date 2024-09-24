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

import "Manifold.xyz/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/ERC721/IERC721CreatorExtensionApproveTransfer.sol";
import "../extensions/ERC721/IERC721CreatorExtensionBurnable.sol";
import "../permissions/ERC721/IERC721CreatorMintPermissions.sol";
import "./IERC721CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC721 creator implementation
 */
abstract contract ERC721CreatorCore is CreatorCore, IERC721CreatorCore {

    uint256 constant public VERSION = 3;

    bytes4 private constant _ERC721_CREATOR_CORE_V1 = 0x9088c207;

    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered extensions data
    mapping (address => bool) internal _extensionApproveTransfers;
    mapping (address => address) internal _extensionPermissions;

    // For tracking extension indices
    uint16 private _extensionCounter;
    mapping (address => uint16) internal _extensionToIndex;    
    mapping (uint16 => address) internal _indexToExtension;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCore).interfaceId || interfaceId == _ERC721_CREATOR_CORE_V1 || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {CreatorCore-_setApproveTransferExtension}
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal override {
        if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionApproveTransfer).interfaceId)) {
            _extensionApproveTransfers[extension] = enabled;
            emit ExtensionApproveTransferUpdated(extension, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "CreatorCore: Invalid extension");
        require(permissions == address(0) || ERC165Checker.supportsInterface(permissions, type(IERC721CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * If mint permissions have been set for an extension (extensions can mint by default),
     * check if an extension can mint via the permission contract's approveMint function.
     */
    function _checkMintPermissions(address to, uint256 tokenId) internal {
        if (_extensionPermissions[msg.sender] != address(0)) {
            IERC721CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenId);
        }
    }

    /**
     * Override for pre mint actions
     */
    function _preMintBase(address, uint256) internal virtual {}

    
    /**
     * Override for pre mint actions for _mintExtension
     */
    function _preMintExtension(address, uint256) internal virtual {}

    /**
     * Post-burning callback and metadata cleanup
     */
    function _postBurn(address owner, uint256 tokenId, address extension) internal virtual {
        // Callback to originating extension if needed
        if (extension != address(0)) {
           if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionBurnable).interfaceId)) {
               IERC721CreatorExtensionBurnable(extension).onBurn(owner, tokenId);
           }
        }
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        } 
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256 tokenId) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        _approveTransfer(from, to, tokenId, _tokenExtension(tokenId));
    }

    function _approveTransfer(address from, address to, uint256 tokenId, uint16 extensionIndex) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        _approveTransfer(from, to, tokenId, _indexToExtension[extensionIndex]);
    }

    function _approveTransfer(address from, address to, uint256 tokenId, address extension) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        if (extension != address(0) && _extensionApproveTransfers[extension]) {
            require(IERC721CreatorExtensionApproveTransfer(extension).approveTransfer(msg.sender, from, to, tokenId), "Extension approval failure");
        } else if (_approveTransferBase != address(0)) {
           require(IERC721CreatorExtensionApproveTransfer(_approveTransferBase).approveTransfer(msg.sender, from, to, tokenId), "Extension approval failure");
        }
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal override {
        require(_extensionCounter < 0xFFFF, "Too many extensions");
        if (_extensionToIndex[extension] == 0) {
            ++_extensionCounter;
            _extensionToIndex[extension] = _extensionCounter;
            _indexToExtension[_extensionCounter] = extension;
        }
        super._registerExtension(extension, baseURI, baseURIIdentical);
    }
}