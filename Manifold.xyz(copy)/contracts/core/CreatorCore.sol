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

import "Manifold.xyz/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "Manifold.xyz/@openzeppelin/contracts/utils/Strings.sol";
import "Manifold.xyz/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "Manifold.xyz/@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "Manifold.xyz/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "Manifold.xyz/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../extensions/ICreatorExtensionTokenURI.sol";
import "../extensions/ICreatorExtensionRoyalties.sol";

import "./ICreatorCore.sol";

/**
 * @dev Core creator implementation
 */
abstract contract CreatorCore is ReentrancyGuard, ICreatorCore, ERC165 {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressUpgradeable for address;

    uint256 internal _tokenCount = 0;

    // Base approve transfers address location
    address internal _approveTransferBase;

    // Track registered extensions data
    EnumerableSet.AddressSet internal _extensions;
    EnumerableSet.AddressSet internal _blacklistedExtensions;

    // The baseURI for a given extension
    mapping (address => string) private _extensionBaseURI;
    mapping (address => bool) private _extensionBaseURIIdentical;

    // The prefix for any tokens with a uri configured
    mapping (address => string) private _extensionURIPrefix;

    // Mapping for individual token URIs
    mapping (uint256 => string) internal _tokenURIs;

    // Royalty configurations
    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }
    mapping (address => RoyaltyConfig[]) internal _extensionRoyalty;
    mapping (uint256 => RoyaltyConfig[]) internal _tokenRoyalty;

    bytes4 private constant _CREATOR_CORE_V1 = 0x28f10a21;

    /**
     * External interface identifiers for royalties
     */

    /**
     *  @dev CreatorCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorCore).interfaceId || interfaceId == _CREATOR_CORE_V1 || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    function requireExtension() internal view {
        require(_extensions.contains(msg.sender), "Must be registered extension");
    }

    /**
     * @dev Only allows non-blacklisted extensions
     */
    function requireNonBlacklist(address extension) internal view {
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }   

    /**
     * @dev See {ICreatorCore-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory extensions) {
        extensions = new address[](_extensions.length());
        for (uint i; i < _extensions.length();) {
            extensions[i] = _extensions.at(i);
            unchecked { ++i; }
        }
        return extensions;
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal virtual {
        require(extension != address(this) && extension.isContract(), "Invalid");
        emit ExtensionRegistered(extension, msg.sender);
        _extensionBaseURI[extension] = baseURI;
        _extensionBaseURIIdentical[extension] = baseURIIdentical;
        _extensions.add(extension);
        _setApproveTransferExtension(extension, true);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override {
        requireExtension();
        _setApproveTransferExtension(msg.sender, enabled);
    }

    /**
     * @dev Set whether or not tokens minted by the extension defers transfer approvals to the extension
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal virtual;

    /**
     * @dev Unregister an extension
     */
    function _unregisterExtension(address extension) internal {
        emit ExtensionUnregistered(extension, msg.sender);
        _extensions.remove(extension);
    }

    /**
     * @dev Blacklist an extension
     */
    function _blacklistExtension(address extension) internal {
       require(extension != address(0) && extension != address(this), "Cannot blacklist yourself");
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
       if (!_blacklistedExtensions.contains(extension)) {
           emit ExtensionBlacklisted(extension, msg.sender);
           _blacklistedExtensions.add(extension);
       }
    }

    /**
     * @dev Set base token uri for an extension
     */
    function _setBaseTokenURIExtension(string calldata uri, bool identical) internal {
        _extensionBaseURI[msg.sender] = uri;
        _extensionBaseURIIdentical[msg.sender] = identical;
    }

    /**
     * @dev Set token uri prefix for an extension
     */
    function _setTokenURIPrefixExtension(string calldata prefix) internal {
        _extensionURIPrefix[msg.sender] = prefix;
    }

    /**
     * @dev Set token uri for a token of an extension
     */
    function _setTokenURIExtension(uint256 tokenId, string calldata uri) internal {
        require(_tokenExtension(tokenId) == msg.sender, "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Set base token uri for tokens with no extension
     */
    function _setBaseTokenURI(string calldata uri) internal {
        _extensionBaseURI[address(0)] = uri;
    }

    /**
     * @dev Set token uri prefix for tokens with no extension
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _extensionURIPrefix[address(0)] = prefix;
    }


    /**
     * @dev Set token uri for a token with no extension
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        require(tokenId > 0 && tokenId <= _tokenCount && _tokenExtension(tokenId) == address(0), "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Retrieve a token's URI
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(tokenId > 0 && tokenId <= _tokenCount, "Invalid token");

        address extension = _tokenExtension(tokenId);
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            if (bytes(_extensionURIPrefix[extension]).length != 0) {
                return string(abi.encodePacked(_extensionURIPrefix[extension], _tokenURIs[tokenId]));
            }
            return _tokenURIs[tokenId];
        }

        if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionTokenURI).interfaceId)) {
            return ICreatorExtensionTokenURI(extension).tokenURI(address(this), tokenId);
        }

        if (!_extensionBaseURIIdentical[extension]) {
            return string(abi.encodePacked(_extensionBaseURI[extension], tokenId.toString()));
        } else {
            return _extensionBaseURI[extension];
        }
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] memory receivers, uint256[] memory bps) {

        // Get token level royalties
        RoyaltyConfig[] memory royalties = _tokenRoyalty[tokenId];
        if (royalties.length == 0) {
            // Get extension specific royalties
            address extension = _tokenExtension(tokenId);
            if (extension != address(0)) {
                if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionRoyalties).interfaceId)) {
                    (receivers, bps) = ICreatorExtensionRoyalties(extension).getRoyalties(address(this), tokenId);
                    // Extension override exists, just return that
                    if (receivers.length > 0) return (receivers, bps);
                }
                royalties = _extensionRoyalty[extension];
            }
        }
        if (royalties.length == 0) {
            // Get the default royalty
            royalties = _extensionRoyalty[address(0)];
        }
        
        if (royalties.length > 0) {
            receivers = new address payable[](royalties.length);
            bps = new uint256[](royalties.length);
            for (uint i; i < royalties.length;) {
                receivers[i] = royalties[i].receiver;
                bps[i] = royalties[i].bps;
                unchecked { ++i; }
            }
        }
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] memory recievers) {
        (recievers, ) = _getRoyalties(tokenId);
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] memory bps) {
        (, bps) = _getRoyalties(tokenId);
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount){
        (address payable[] memory receivers, uint256[] memory bps) = _getRoyalties(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");
        
        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], bps[0]*value/10000);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
       _checkRoyalties(receivers, basisPoints);
        delete _tokenRoyalty[tokenId];
        _setRoyalties(receivers, basisPoints, _tokenRoyalty[tokenId]);
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        _checkRoyalties(receivers, basisPoints);
        delete _extensionRoyalty[extension];
        _setRoyalties(receivers, basisPoints, _extensionRoyalty[extension]);
        if (extension == address(0)) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit ExtensionRoyaltiesUpdated(extension, receivers, basisPoints);
        }
    }

    /**
     * Helper function to check that royalties provided are valid
     */
    function _checkRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) private pure {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i; i < basisPoints.length;) {
            totalBasisPoints += basisPoints[i];
            unchecked { ++i; }
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }

    /**
     * Helper function to set royalties
     */
    function _setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints, RoyaltyConfig[] storage royalties) private {
        for (uint i; i < basisPoints.length;) {
            royalties.push(
                RoyaltyConfig(
                    {
                        receiver: receivers[i],
                        bps: uint16(basisPoints[i])
                    }
                )
            );
            unchecked { ++i; }
        }
    }

    /**
     * @dev Set the base contract's approve transfer contract location
     */
    function _setApproveTransferBase(address extension) internal {
        _approveTransferBase = extension;
        emit ApproveTransferUpdated(extension);
    }

    /**
     * @dev See {ICreatorCore-getApproveTransfer}.
     */
    function getApproveTransfer() external view override returns (address) {
        return _approveTransferBase;
    }

    /**
     * @dev Get the extension for the given token
     */
    function _tokenExtension(uint256 tokenId) internal virtual view returns(address);
}
