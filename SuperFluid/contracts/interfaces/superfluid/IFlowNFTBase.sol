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

import { IERC721Metadata } from "SuperFluid/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IFlowNFTBase is IERC721Metadata {
    // FlowNFTData struct storage packing:
    // b = bits
    // WORD 1: | superToken      | FREE
    //         | 160b            | 96b
    // WORD 2: | flowSender      | FREE
    //         | 160b            | 96b
    // WORD 3: | flowReceiver    | flowStartDate | FREE
    //         | 160b            | 32b           | 64b
    struct FlowNFTData {
        address superToken;
        address flowSender;
        address flowReceiver;
        uint32 flowStartDate;
    }

    /**************************************************************************
     * Custom Errors
     *************************************************************************/

    error CFA_NFT_APPROVE_CALLER_NOT_OWNER_OR_APPROVED_FOR_ALL();   // 0xa3352582
    error CFA_NFT_APPROVE_TO_CALLER();                              // 0xd3c77329
    error CFA_NFT_APPROVE_TO_CURRENT_OWNER();                       // 0xe4790b25
    error CFA_NFT_INVALID_TOKEN_ID();                               // 0xeab95e3b
    error CFA_NFT_ONLY_SUPER_TOKEN_FACTORY();                       // 0xebb7505b
    error CFA_NFT_TRANSFER_CALLER_NOT_OWNER_OR_APPROVED_FOR_ALL();  // 0x2551d606
    error CFA_NFT_TRANSFER_FROM_INCORRECT_OWNER();                  // 0x5a26c744
    error CFA_NFT_TRANSFER_IS_NOT_ALLOWED();                        // 0xaa747eca
    error CFA_NFT_TRANSFER_TO_ZERO_ADDRESS();                       // 0xde06d21e

    /**************************************************************************
     * Events
     *************************************************************************/

    /// @notice Informs third-party platforms that NFT metadata should be updated
    /// @dev This event comes from https://eips.ethereum.org/EIPS/eip-4906
    /// @param tokenId the id of the token that should have its metadata updated
    event MetadataUpdate(uint256 tokenId);

    /**************************************************************************
     * View
     *************************************************************************/

    /// @notice An external function for querying flow data by `tokenId``
    /// @param tokenId the token id
    /// @return flowData the flow data associated with `tokenId`
    function flowDataByTokenId(
        uint256 tokenId
    ) external view returns (FlowNFTData memory flowData);

    /// @notice An external function for computing the deterministic tokenId
    /// @dev tokenId = uint256(keccak256(abi.encode(block.chainId, superToken, flowSender, flowReceiver)))
    /// @param superToken the super token
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    /// @return tokenId the tokenId
    function getTokenId(
        address superToken,
        address flowSender,
        address flowReceiver
    ) external view returns (uint256);

    /**************************************************************************
     * Write
     *************************************************************************/

    function initialize(
        string memory nftName,
        string memory nftSymbol
    ) external; // initializer;

    function triggerMetadataUpdate(uint256 tokenId) external;
}
