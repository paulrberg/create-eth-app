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

import "Manifold.xyz/@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";

import "./core/ERC721CreatorCore.sol";
import "./token/ERC721/ERC721Upgradeable.sol";

/**
 * @dev ERC721Creator implementation
 */
contract ERC721CreatorImplementation is AdminControlUpgradeable, ERC721Upgradeable, ERC721CreatorCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Initializer
     */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Core, ERC721CreatorCore, AdminControlUpgradeable) returns (bool) {
        return ERC721CreatorCore.supportsInterface(interfaceId) || ERC721Core.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint96 data) internal virtual override {
        _approveTransfer(from, to, tokenId, uint16(data));
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override {
        requireExtension();
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external override {
        requireExtension();
        _setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] calldata tokenIds, string[] calldata uris) external override {
        requireExtension();
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURIExtension(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURI(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBase(to, "", 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to, string calldata uri) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBase(to, uri, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, uint16 count) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += count;

        for (uint i; i < count;) {
            tokenIds[i] = _mintBase(to, "", firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += uris.length;

        for (uint i; i < uris.length;) {
            tokenIds[i] = _mintBase(to, uris[i], firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev Mint token with no extension
     */
    function _mintBase(address to, string memory uri, uint256 tokenId) internal virtual returns(uint256) {
        if (tokenId == 0) {
            ++_tokenCount;
            tokenId = _tokenCount;
        }

        // Call pre mint
        _preMintBase(to, tokenId);

        _safeMint(to, tokenId, 0);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, "", 0, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, string calldata uri) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, uri, 0, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, uint80 data) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, "", data, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](count);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += count;

        for (uint i; i < count;) {
            tokenIds[i] = _mintExtension(to, "", 0, firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] calldata uris) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](uris.length);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += uris.length;

        for (uint i; i < uris.length;) {
            tokenIds[i] = _mintExtension(to, uris[i], 0, firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint80[] calldata data) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](data.length);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += data.length;

        for (uint i; i < data.length;) {
            tokenIds[i] = _mintExtension(to, "", data[i], firstTokenId+i);
            unchecked { ++i; }
        }
    }
    
    /**
     * @dev Mint token via extension
     */
    function _mintExtension(address to, string memory uri, uint80 data, uint256 tokenId) internal virtual returns(uint256) {
        if (tokenId == 0) {
            ++_tokenCount;
            tokenId = _tokenCount;
        }

        _checkMintPermissions(to, tokenId);
        // Call pre mint
        _preMintExtension(to, tokenId);

        _safeMint(to, tokenId, data << 16 | _extensionToIndex[msg.sender]);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address extension) {
        require(_exists(tokenId), "Nonexistent token");
        extension = _tokenExtension(tokenId);
        require(extension != address(0), "No extension for token");
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }

    /**
     * @dev See {IERC721CreatorCore-burn}.
     */
    function burn(uint256 tokenId) public virtual override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
        address owner = ownerOf(tokenId);
        address extension = _tokenExtension(tokenId);
        _burn(tokenId);
        _postBurn(owner, tokenId, extension);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        require(_exists(tokenId), "Nonexistent token");
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransfer}.
     */
    function setApproveTransfer(address extension) external override adminRequired {
        _setApproveTransferBase(extension);
    }

    function _tokenExtension(uint256 tokenId) internal view override returns(address) {
        uint16 extensionIndex = uint16(_tokenData[tokenId].data);
        if (extensionIndex == 0) return address(0);
        return _indexToExtension[extensionIndex];
    }

    /**
     * @dev See {IERC721CreatorCore-tokenData}.
     */
    function tokenData(uint256 tokenId) external view returns (uint80) {
        return uint80(_tokenData[tokenId].data >> 16);
    }
}