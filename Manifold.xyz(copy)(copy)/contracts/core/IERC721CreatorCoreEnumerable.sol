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

import "./IERC721CreatorCore.sol";

/**
 * @dev Core ERC721 creator interface (with enumerable api's)
 */
interface IERC721CreatorCoreEnumerable is IERC721CreatorCore {

    /*
     * @dev gets the total number of tokens created by the extension (unburned)
     */
    function totalSupplyExtension(address extension) external view returns (uint256);

    /*
     * @dev gets tokenId of an extension by index. 
     * Iterate over this to get the full list of tokens of a given extension
     */
    function tokenByIndexExtension(address extension, uint256 index) external view returns (uint256);

    /*
     * @dev get balance of owner for an extension
     */
   function balanceOfExtension(address extension, address owner) external view returns (uint256 balance);

   /*
    * @dev Returns a token ID owned by `owner` at a given `index` of its token list for a given extension
    */
   function tokenOfOwnerByIndexExtension(address extension, address owner, uint256 index) external view returns (uint256 tokenId);

    /*
     * @dev gets the total number of tokens created with no extension
     */
    function totalSupplyBase() external view returns (uint256);

    /*
     * @dev gets tokenId of the root creator contract by index. 
     * Iterate over this to get the full list of tokens with no extension.
     */
    function tokenByIndexBase(uint256 index) external view returns (uint256);

    /*
     * @dev get balance of owner for tokens with no extension
     */
    function balanceOfBase(address owner) external view returns (uint256 balance);

    /*
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list for tokens with no extension
     */
    function tokenOfOwnerByIndexBase(address owner, uint256 index) external view returns (uint256 tokenId);

}
