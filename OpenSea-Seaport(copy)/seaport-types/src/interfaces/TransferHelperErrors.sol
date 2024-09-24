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
 * @title TransferHelperErrors
 */
interface TransferHelperErrors {
    /**
     * @dev Revert with an error when attempting to execute transfers with a
     *      NATIVE itemType.
     */
    error InvalidItemType();

    /**
     * @dev Revert with an error when an ERC721 transfer with amount other than
     *      one is attempted.
     *
     * @param amount The amount of the ERC721 tokens to transfer.
     */
    error InvalidERC721TransferAmount(uint256 amount);

    /**
     * @dev Revert with an error when attempting to execute an ERC721 transfer
     *      to an invalid recipient.
     */
    error InvalidERC721Recipient(address recipient);

    /**
     * @dev Revert with an error when a call to an ERC721 receiver reverts with
     *      bytes data.
     */
    error ERC721ReceiverErrorRevertBytes(
        bytes reason,
        address receiver,
        address sender,
        uint256 identifier
    );

    /**
     * @dev Revert with an error when a call to an ERC721 receiver reverts with
     *      string reason.
     */
    error ERC721ReceiverErrorRevertString(
        string reason,
        address receiver,
        address sender,
        uint256 identifier
    );

    /**
     * @dev Revert with an error when an ERC20 token has an invalid identifier.
     */
    error InvalidERC20Identifier();

    /**
     * @dev Revert with an error if the recipient is the zero address.
     */
    error RecipientCannotBeZeroAddress();

    /**
     * @dev Revert with an error when attempting to fill an order referencing an
     *      invalid conduit (i.e. one that has not been deployed).
     */
    error InvalidConduit(bytes32 conduitKey, address conduit);

    /**
     * @dev Revert with an error when a call to a conduit reverts with a
     *      reason string.
     */
    error ConduitErrorRevertString(
        string reason,
        bytes32 conduitKey,
        address conduit
    );

    /**
     * @dev Revert with an error when a call to a conduit reverts with bytes
     *      data.
     */
    error ConduitErrorRevertBytes(
        bytes reason,
        bytes32 conduitKey,
        address conduit
    );
}
