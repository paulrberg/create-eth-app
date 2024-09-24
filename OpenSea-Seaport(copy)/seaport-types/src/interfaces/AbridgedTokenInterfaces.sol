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

/**
 * @title ERC20Interface
 * @notice Contains the minimum interfaces needed to interact with ERC20s.
 */
interface ERC20Interface {
    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from  The address of the owner.
     * @param to    The address of the recipient.
     * @param value The amount of tokens to transfer.
     *
     * @return success True if the transfer was successful.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool success);

    /**
     * @dev Allows an operator to approve a spender to transfer tokens on behalf
     *      of a user.
     *
     * @param spender The address of the spender.
     * @param value   The amount of tokens to approve.
     *
     * @return success True if the approval was successful.
     */
    function approve(address spender, uint256 value) external returns (bool success);

    /**
     * @dev Returns the balance of a user.
     *
     * @param account The address of the user.
     *
     * @return balance The balance of the user.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount which spender is still allowed to withdraw
     *      from owner.
     *
     * @param owner   The address of the owner.
     * @param spender The address of the spender.
     *
     * @return remaining The amount of tokens that the spender is allowed to
     *                   transfer on behalf of the owner.
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

/**
 * @title ERC721Interface
 * @notice Contains the minimum interfaces needed to interact with ERC721s.
 */
interface ERC721Interface {
    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from    The address of the owner.
     * @param to      The address of the recipient.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Allows an owner to approve an operator to transfer all tokens on a
     *      contract on behalf of the owner.
     *
     * @param to       The address of the operator.
     * @param approved Whether the operator is approved.
     */
    function setApprovalForAll(address to, bool approved) external;

    /**
     * @dev Returns the account approved for tokenId token
     *
     * @param tokenId The tokenId to query the approval of.
     *
     * @return operator The approved account of the tokenId.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns whether an operator is allowed to manage all of
     *      the assets of owner.
     *
     * @param owner    The address of the owner.
     * @param operator The address of the operator.
     *
     * @return approved True if the operator is approved by the owner.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Returns the owner of a given token ID.
     *
     * @param tokenId The token ID.
     *
     * @return owner The owner of the token.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * @title ERC1155Interface
 * @notice Contains the minimum interfaces needed to interact with ERC1155s.
 */
interface ERC1155Interface {
    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from   The address of the owner.
     * @param to     The address of the recipient.
     * @param id     The ID of the token(s) to transfer.
     * @param amount The amount of tokens to transfer.
     * @param data   Additional data.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from    The address of the owner.
     * @param to      The address of the recipient.
     * @param ids     The IDs of the token(s) to transfer.
     * @param amounts The amounts of tokens to transfer.
     * @param data    Additional data.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @dev Allows an owner to approve an operator to transfer all tokens on a
     *      contract on behalf of the owner.
     *
     * @param to       The address of the operator.
     * @param approved Whether the operator is approved.
     */
    function setApprovalForAll(address to, bool approved) external;

    /**
     * @dev Returns the amount of token type id owned by account.
     *
     * @param account The address of the account.
     * @param id      The id of the token.
     *
     * @return balance The amount of tokens of type id owned by account.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns true if operator is approved to transfer account's tokens.
     *
     * @param account  The address of the account.
     * @param operator The address of the operator.
     *
     * @return approved True if the operator is approved to transfer account's
     *                  tokens.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);
}
