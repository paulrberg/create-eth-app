/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/Azuki-ERC721A-NFT-Sale?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Azuki-ERC721A-NFT-Sale/@openzeppelin/contracts/access/Ownable.sol";
import "Azuki-ERC721A-NFT-Sale/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ERC721A.sol";

/**
 * @title NFT Sale with bulk mint discount
 * @author Breakthrough Labs Inc.
 * @notice NFT, Sale, ERC721, ERC721A, Limited
 * @custom:version 1.0.8
 * @custom:address 14
 * @custom:default-precision 0
 * @custom:simple-description An NFT with built in sale that provides bulk minting discounts.
 * The sale includes a per wallet limit to ensure a large number of users are able to purchase NFTs.
 * When minting multiple NFTs, gas costs are reduced compared to a normal NFT contract.
 * @dev ERC721A NFT with the following features:
 *
 *  - Built-in sale with an adjustable price.
 *  - Wallets can only buy a limited number of NFTs during the sale.
 *  - Reserve function for the owner to mint free NFTs.
 *  - Fixed maximum supply.
 *  - Reduced Gas costs when minting many NFTs at the same time.
 *
 */

contract LimitedERC721A is ERC721A, Ownable {
    bool public saleIsActive = true;
    string private _baseURIextended;

    uint256 public immutable MAX_SUPPLY;
    /// @custom:precision 18
    uint256 public currentPrice;
    uint256 public walletLimit;

    /**
     * @param _name NFT Name
     * @param _symbol NFT Symbol
     * @param _uri Token URI used for metadata
     * @param limit Wallet Limit
     * @param price Initial Price | precision:18
     * @param maxSupply Maximum # of NFTs
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 limit,
        uint256 price,
        uint256 maxSupply
    ) payable ERC721A(_name, _symbol) {
        _baseURIextended = _uri;
        currentPrice = price;
        walletLimit = limit;
        MAX_SUPPLY = maxSupply;
    }

    /**
     * @dev An external method for users to purchase and mint NFTs. Requires that the sale
     * is active, that the minted NFTs will not exceed the `MAX_SUPPLY`, and that a
     * sufficient payable value is sent.
     * @param amount The number of NFTs to mint.
     */
    function mint(uint256 amount) external payable {
        uint256 ts = totalSupply();
        uint256 minted = _numberMinted(msg.sender);

        require(saleIsActive, "Sale must be active to mint tokens");
        require(amount + minted <= walletLimit, "Exceeds wallet limit");
        require(ts + amount <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            currentPrice * amount == msg.value,
            "Value sent is not correct"
        );

        _safeMint(msg.sender, amount);
    }

    /**
     * @dev A way for the owner to reserve a specifc number of NFTs without having to
     * interact with the sale.
     * @param to The address to send reserved NFTs to.
     * @param amount The number of NFTs to reserve.
     */
    function reserve(address to, uint256 amount) external onlyOwner {
        uint256 ts = totalSupply();
        require(ts + amount <= MAX_SUPPLY, "Purchase would exceed max tokens");
        _safeMint(to, amount);
    }

    /**
     * @dev A way for the owner to withdraw all proceeds from the sale.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Sets whether or not the NFT sale is active.
     * @param isActive Whether or not the sale will be active.
     */
    function setSaleIsActive(bool isActive) external onlyOwner {
        saleIsActive = isActive;
    }

    /**
     * @dev Sets the price of each NFT during the initial sale.
     * @param price The price of each NFT during the initial sale | precision:18
     */
    function setCurrentPrice(uint256 price) external onlyOwner {
        currentPrice = price;
    }

    /**
     * @dev Sets the maximum number of NFTs that can be sold to a specific address.
     * @param limit The maximum number of NFTs that be bought by a wallet.
     */
    function setWalletLimit(uint256 limit) external onlyOwner {
        walletLimit = limit;
    }

    /**
     * @dev Updates the baseURI that will be used to retrieve NFT metadata.
     * @param baseURI_ The baseURI to be used.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}
