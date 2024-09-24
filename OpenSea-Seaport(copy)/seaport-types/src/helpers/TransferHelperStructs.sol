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
pragma solidity ^0.8.13;

import { ConduitItemType } from "../conduit/lib/ConduitEnums.sol";

/**
 * @dev A TransferHelperItem specifies the itemType (ERC20/ERC721/ERC1155),
 *      token address, token identifier, and amount of the token to be
 *      transferred via the TransferHelper. For ERC20 tokens, identifier
 *      must be 0. For ERC721 tokens, amount must be 1.
 */
struct TransferHelperItem {
    ConduitItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A TransferHelperItemsWithRecipient specifies the tokens to transfer
 *      via the TransferHelper, their intended recipient, and a boolean flag
 *      indicating whether onERC721Received should be called on a recipient
 *      contract.
 */
struct TransferHelperItemsWithRecipient {
    TransferHelperItem[] items;
    address recipient;
    bool validateERC721Receiver;
}
