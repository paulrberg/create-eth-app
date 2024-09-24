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

import "./ERC721Creator.sol";
import "./core/ERC721CreatorCoreEnumerable.sol";
import "./token/ERC721/ERC721Enumerable.sol";

/**
 * @dev ERC721Creator implementation (with enumerable api's)
 */
contract ERC721CreatorEnumerable is ERC721Creator, ERC721CreatorCoreEnumerable, ERC721Enumerable {

    constructor (string memory _name, string memory _symbol) ERC721Creator(_name, _symbol) {
    }
        
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Creator, ERC721CreatorCoreEnumerable, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721CreatorCoreEnumerable).interfaceId || ERC721Creator.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint96 data) internal virtual override(ERC721Enumerable, ERC721Creator, ERC721CreatorCoreEnumerable) {
        _approveTransfer(from, to, tokenId, uint16(data));
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId, data);
    }

    function _preMintBase(address to, uint256 tokenId) internal virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._preMintBase(to, tokenId);
    }

    function _preMintExtension(address to, uint256 tokenId) internal virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._preMintExtension(to, tokenId);
    }

    function _postBurn(address owner, uint256 tokenId, address extension) internal virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._postBurn(owner, tokenId, extension);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Creator, IERC721Metadata) returns (string memory) {
        return ERC721Creator.tokenURI(tokenId);
    }
}