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

import "Manifold.xyz/@openzeppelin/contracts/utils/Strings.sol";
import "Manifold.xyz/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721CreatorCore.sol";
import "./IERC721CreatorCoreEnumerable.sol";

/**
 * @dev Core ERC721 creator implementation (with enumerable api's)
 */
abstract contract ERC721CreatorCoreEnumerable is ERC721CreatorCore, IERC721CreatorCoreEnumerable {

    // For enumerating tokens for a given extension
    mapping (address => uint256) private _extensionBalances;
    mapping (address => mapping(uint256 => uint256)) private _extensionTokens;
    mapping (uint256 => uint256) private _extensionTokensIndex;

    // For enumerating an extension's tokens for an owner
    mapping (address => mapping(address => uint256)) private _extensionBalancesByOwner;
    mapping (address => mapping(address => mapping(uint256 => uint256))) private _extensionTokensByOwner;
    mapping (uint256 => uint256) private _extensionTokensIndexByOwner;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCoreEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC721CreatorCoreEnumerable-totalSupplyExtension}.
     */
    function totalSupplyExtension(address extension) public view virtual override returns (uint256) {
        requireNonBlacklist(extension);
        return _extensionBalances[extension];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-tokenByIndexExtension}.
     */
    function tokenByIndexExtension(address extension, uint256 index) external view virtual override returns (uint256) {
        requireNonBlacklist(extension);
        require(index < totalSupplyExtension(extension), "ERC721Creator: Index out of bounds");
        return _extensionTokens[extension][index];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-balanceOfExtension}.
     */
    function balanceOfExtension(address extension, address owner) public view virtual override returns (uint256) {
        requireNonBlacklist(extension);
        return _extensionBalancesByOwner[extension][owner];
    }

    /*
     * @dev See {IERC721CreatorCoreEnumerable-tokenOfOwnerByIndexExtension}.
     */
    function tokenOfOwnerByIndexExtension(address extension, address owner, uint256 index) external view virtual override returns (uint256) {
        requireNonBlacklist(extension);
        require(index < balanceOfExtension(extension, owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[extension][owner][index];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-totalSupplyBase}.
     */
    function totalSupplyBase() public view virtual override returns (uint256) {
        return _extensionBalances[address(0)];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-tokenByIndexBase}.
     */
    function tokenByIndexBase(uint256 index) external view virtual override returns (uint256) {
        require(index < totalSupplyBase(), "ERC721Creator: Index out of bounds");
        return _extensionTokens[address(0)][index];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-balanceOfBase}.
     */
    function balanceOfBase(address owner) public view virtual override returns (uint256) {
        return _extensionBalancesByOwner[address(0)][owner];
    }

    /*
     * @dev See {IERC721CreatorCoreEnumerable-tokenOfOwnerByIndexBase}.
     */
    function tokenOfOwnerByIndexBase(address owner, uint256 index) external view virtual override returns (uint256) {
        require(index < balanceOfBase(owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[address(0)][owner][index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId, address tokenExtension_) private {
        // Add to extension token tracking by owner
        uint256 lengthByOwner = balanceOfExtension(tokenExtension_, to);
        _extensionTokensByOwner[tokenExtension_][to][lengthByOwner] = tokenId;
        _extensionTokensIndexByOwner[tokenId] = lengthByOwner;
        _extensionBalancesByOwner[tokenExtension_][to] += 1;        
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId, address tokenExtension_) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndexByOwner = balanceOfExtension(tokenExtension_, from) - 1;
        uint256 tokenIndexByOwner = _extensionTokensIndexByOwner[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndexByOwner != lastTokenIndexByOwner) {
            uint256 lastTokenIdByOwner = _extensionTokensByOwner[tokenExtension_][from][lastTokenIndexByOwner];

            _extensionTokensByOwner[tokenExtension_][from][tokenIndexByOwner] = lastTokenIdByOwner; // Move the last token to the slot of the to-delete token
            _extensionTokensIndexByOwner[lastTokenIdByOwner] = tokenIndexByOwner; // Update the moved token's index
        }
        _extensionBalancesByOwner[tokenExtension_][from] -= 1;

        // This also deletes the contents at the last position of the array
        delete _extensionTokensIndexByOwner[tokenId];
        delete _extensionTokensByOwner[tokenExtension_][from][lastTokenIndexByOwner];
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint96 data) internal virtual {
        if (from != address(0) && to != address(0) && from != to) {
            address tokenExtension_ = _indexToExtension[uint16(data)];
            _removeTokenFromOwnerEnumeration(from, tokenId, tokenExtension_);
            _addTokenToOwnerEnumeration(to, tokenId, tokenExtension_);
        }
    }

    function _preMintBase(address to, uint256 tokenId) internal virtual override {
        // Add to extension token tracking
        uint256 length = totalSupplyBase();
        _extensionTokens[address(0)][length] = tokenId;
        _extensionTokensIndex[tokenId] = length;
        ++_extensionBalances[address(0)];

        _addTokenToOwnerEnumeration(to, tokenId, address(0));
    }

    function _preMintExtension(address to, uint256 tokenId) internal virtual override {
        // Add to extension token tracking
        uint256 length = totalSupplyExtension(msg.sender);
        _extensionTokens[msg.sender][length] = tokenId;
        _extensionTokensIndex[tokenId] = length;
        ++_extensionBalances[msg.sender];

        _addTokenToOwnerEnumeration(to, tokenId, msg.sender);
    }
    
    function _postBurn(address owner, uint256 tokenId, address extension) internal override(ERC721CreatorCore) virtual {
        /*************************************************
         *  START: Remove from extension token tracking
         *************************************************/

        uint256 lastTokenIndex = totalSupplyExtension(extension) - 1;
        uint256 tokenIndex = _extensionTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _extensionTokens[extension][lastTokenIndex];

            _extensionTokens[extension][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _extensionTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _extensionBalances[extension] -= 1;

        // This also deletes the contents at the last position of the array
        delete _extensionTokensIndex[tokenId];
        delete _extensionTokens[extension][lastTokenIndex];

        /*************************************************
         * END
         *************************************************/


        /********************************************************
         *  START: Remove from extension token tracking by owner
         ********************************************************/
         _removeTokenFromOwnerEnumeration(owner, tokenId, extension);

        /********************************************************
         *  END
         ********************************************************/
         
         ERC721CreatorCore._postBurn(owner, tokenId, extension);
    }

}