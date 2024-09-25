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
pragma solidity ^0.8.10;

import { ERC721 } from "OpenSea-Seaport/@rari-capital/solmate/src/tokens/ERC721.sol";
import { ERC2981 } from "./ERC2981.sol";

contract TestERC721Fee is ERC721, ERC2981 {
    /// @notice When set to false, `royaltyInfo` reverts
    bool creatorFeeEnabled = false;
    /// @notice Below the min transaction price, `royaltyInfo` reverts
    uint256 minTransactionPrice = 0;

    constructor() ERC721("Fee", "FEE") {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function burn(uint256 id) external {
        _burn(id);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view override returns (address, uint256) {
        if (!creatorFeeEnabled) {
            revert("creator fee disabled");
        }
        if (_salePrice < minTransactionPrice) {
            revert("sale price too low");
        }

        return (
            0x000000000000000000000000000000000000fEE2,
            (_salePrice * (creatorFeeEnabled ? 250 : 0)) / 10000
        ); // 2.5% fee to 0xFEE2
    }

    function setCreatorFeeEnabled(bool enabled) public {
        creatorFeeEnabled = enabled;
    }

    function setMinTransactionPrice(uint256 minTransactionPrice_) public {
        minTransactionPrice = minTransactionPrice_;
    }
}
