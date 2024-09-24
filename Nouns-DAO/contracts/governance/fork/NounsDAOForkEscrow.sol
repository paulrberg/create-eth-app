/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Nouns-DAO?utm=code
  */
  
  // SPDX-License-Identifier: GPL-3.0

/// @title Escrow contract for Nouns to be used to trigger a fork

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.19;

import { NounsTokenLike } from '../NounsDAOInterfaces.sol';
import { IERC721Receiver } from 'Nouns-DAO/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract NounsDAOForkEscrow is IERC721Receiver {
    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   ERRORS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    error OnlyDAO();
    error OnlyNounsToken();
    error NotOwner();

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   IMMUTABLES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Nouns governance contract
    address public immutable dao;

    /// @notice Nouns token contract
    NounsTokenLike public immutable nounsToken;

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   STORAGE VARIABLES
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Current fork id
    uint32 public forkId;

    /// @notice A mapping of which owner escrowed which token for which fork.
    /// Later used in order to claim tokens in a forked DAO.
    /// @dev forkId => tokenId => owner
    mapping(uint32 => mapping(uint256 => address)) public escrowedTokensByForkId;

    /// @notice Number of tokens in escrow in the current fork contributing to the fork threshold. They can be unescrowed.
    uint256 public numTokensInEscrow;

    constructor(address dao_, address nounsToken_) {
        dao = dao_;
        nounsToken = NounsTokenLike(nounsToken_);
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   MODIFIERS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    modifier onlyDAO() {
        if (msg.sender != dao) {
            revert OnlyDAO();
        }
        _;
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   PUBLIC/EXTERNAL OnlyDAO Txs
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Escrows nouns tokens
     * @dev Can only be called by the Nouns token contract, and initiated by the DAO contract
     * @param operator The address which called the `safeTransferFrom` function, can only be the DAO contract
     * @param from The address which previously owned the token
     * @param tokenId The id of the token being escrowed
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public override returns (bytes4) {
        if (msg.sender != address(nounsToken)) revert OnlyNounsToken();
        if (operator != dao) revert OnlyDAO();

        escrowedTokensByForkId[forkId][tokenId] = from;

        numTokensInEscrow++;

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Unescrows nouns tokens
     * @dev Can only be called by the DAO contract
     * @param owner The address which asks to unescrow, must be the address which escrowed the tokens
     * @param tokenIds The ids of the tokens being unescrowed
     */
    function returnTokensToOwner(address owner, uint256[] calldata tokenIds) external onlyDAO {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (currentOwnerOf(tokenIds[i]) != owner) revert NotOwner();

            nounsToken.transferFrom(address(this), owner, tokenIds[i]);
            escrowedTokensByForkId[forkId][tokenIds[i]] = address(0);
        }

        numTokensInEscrow -= tokenIds.length;
    }

    /**
     * @notice Closes the escrow, and increments the fork id. Once the escrow is closed, all the escrowed tokens
     * can no longer be unescrowed by the owner, but can be withdrawn by the DAO.
     * @dev Can only be called by the DAO contract
     * @return closedForkId The fork id which was closed
     */
    function closeEscrow() external onlyDAO returns (uint32 closedForkId) {
        numTokensInEscrow = 0;

        closedForkId = forkId;

        forkId++;
    }

    /**
     * @notice Withdraws nouns tokens to the DAO
     * @dev Can only be called by the DAO contract
     * @param tokenIds The ids of the tokens being withdrawn
     * @param to The address which will receive the tokens
     */
    function withdrawTokens(uint256[] calldata tokenIds, address to) external onlyDAO {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (currentOwnerOf(tokenIds[i]) != dao) revert NotOwner();

            nounsToken.transferFrom(address(this), to, tokenIds[i]);
        }
    }

    /**
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     *   VIEW FUNCTIONS
     * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /**
     * @notice Returns the number of tokens owned by the DAO, excluding the ones in escrow
     */
    function numTokensOwnedByDAO() external view returns (uint256) {
        return nounsToken.balanceOf(address(this)) - numTokensInEscrow;
    }

    /**
     * @notice Returns the original owner of a token, when it was escrowed
     * @param forkId_ The fork id in which the token was escrowed
     * @param tokenId The id of the token
     * @return The address of the original owner, or address(0) if not found
     */
    function ownerOfEscrowedToken(uint32 forkId_, uint256 tokenId) external view returns (address) {
        return escrowedTokensByForkId[forkId_][tokenId];
    }

    /**
     * @notice Returns the current owner of a token, either the DAO or the account which escrowed it.
     * If the token is currently in an active escrow, the original owner is still the owner.
     * Otherwise, the DAO can withdraw it.
     * @param tokenId The id of the token
     * @return The address of the current owner, either the original owner or the address of the dao
     */
    function currentOwnerOf(uint256 tokenId) public view returns (address) {
        address owner = escrowedTokensByForkId[forkId][tokenId];
        if (owner == address(0)) {
            return dao;
        } else {
            return owner;
        }
    }
}
