/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import { IFlowNFTBase } from "./IFlowNFTBase.sol";

interface IConstantInflowNFT is IFlowNFTBase {
    /**************************************************************************
     * Custom Errors
     *************************************************************************/
    error CIF_NFT_ONLY_CONSTANT_OUTFLOW(); // 0xe81ef57a

    /**************************************************************************
     * Write Functions
     *************************************************************************/

    /// @notice The mint function emits the "mint" `Transfer` event.
    /// @dev We don't modify storage as this is handled in ConstantOutflowNFT.sol and this function's sole purpose
    /// is to inform clients that search for events.
    /// @param to the flow receiver (inflow NFT receiver)
    /// @param newTokenId the new token id
    function mint(address to, uint256 newTokenId) external;

    /// @notice This burn function emits the "burn" `Transfer` event.
    /// @dev We don't modify storage as this is handled in ConstantOutflowNFT.sol and this function's sole purpose
    /// is to inform clients that search for events.
    /// @param tokenId desired token id to burn
    function burn(uint256 tokenId) external;
}
