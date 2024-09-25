/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/soulbound-nft?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "soulbound-nft/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "soulbound-nft/@openzeppelin/contracts/access/Ownable.sol";
import "soulbound-nft/@openzeppelin/contracts/security/Pausable.sol";
import "soulbound-nft/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title Soulbound NFT
 * @author Breakthrough-Labs Inc.
 * @notice NFT, Soulbound, ERC721
 * @custom:version 1.0.10
 * @custom:address 1285485
 * @custom:default-precision 0
 * @custom:simple-description Soulbound NFT with owner minting.
 * @dev ERC721 Soulbound NFT with the following features:
 *
 *  - Deployer can mint to recipients.
 *  - No transfer capability.
 *
 */

contract SoulboundNFT is ERC721, ERC721Enumerable, Pausable, Ownable {
    string private _baseURIextended;
    uint256 public immutable MAX_SUPPLY;

    /**
     * @param _name NFT Name
     * @param _symbol NFT Symbol
     * @param _uri Token URI used for metadata
     * @param maxSupply Maximum # of NFTs
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 maxSupply
    ) payable ERC721(_name, _symbol) {
        _baseURIextended = _uri;
        MAX_SUPPLY = maxSupply;
        pause();
    }

    /**
     * @dev Pauses the NFT, preventing any transfers. Called by default on a SBT.
     */
    function pause() internal {
        _pause();
    }

    /**
     * @dev An external method for the owner to mint Soulbound NFTs. Requires that the minted NFTs will not exceed the `MAX_SUPPLY`.
     */
    function mint(address to) external onlyOwner{
        uint256 ts = totalSupply();
        require(ts + 1 <= MAX_SUPPLY, "Mint would exceed max supply");
        _safeMint(to, ts);
    }

    /**
     * @dev Updates the baseURI that will be used to retrieve NFT metadata.
     * @param baseURI_ The baseURI to be used.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    // Required Overrides

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(_msgSender() == owner() && paused(), "not owner cannot mint");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

