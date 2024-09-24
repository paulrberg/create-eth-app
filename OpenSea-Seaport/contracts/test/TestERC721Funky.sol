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

/**
 * @notice TestERC721Funky is an ERC721 that implements ERC2981 with an incorrect return type.
 */
contract TestERC721Funky is ERC721("TestERC721Funky", "TST721FUNKY") {
    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function burn(uint256 id) external {
        _burn(id);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "tokenURI";
    }

    function royaltyInfo(uint256, uint256) public pure returns (address) {
        return (0x000000000000000000000000000000000000fEE2); // 2.5% fee to 0xFEE2
    }
}
