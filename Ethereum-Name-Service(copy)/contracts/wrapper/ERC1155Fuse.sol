/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  //SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "Ethereum-Name-Service/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/utils/Address.sol";

/* This contract is a variation on ERC1155 with the additions of _setData, getData and _beforeTransfer and ownerOf. _setData and getData allows the use of the other 96 bits next to the address of the owner for extra data. We use this to store 'fuses' that control permissions that can be burnt. 32 bits are used for the fuses themselves and 64 bits are used for the expiry of the name. When a name has expired, its fuses will be be set back to 0 */

abstract contract ERC1155Fuse is ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    mapping(uint256 => uint256) public _tokens;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    /**************************************************************************
     * ERC721 methods
     *************************************************************************/

    function ownerOf(uint256 id) public view virtual returns (address) {
        (address owner, , ) = getData(id);
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        address owner = ownerOf(id);
        if (owner == account) {
            return 1;
        }
        return 0;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Returns the Name's owner address and fuses
     */
    function getData(
        uint256 tokenId
    ) public view virtual returns (address owner, uint32 fuses, uint64 expiry) {
        uint256 t = _tokens[tokenId];
        owner = address(uint160(t));
        expiry = uint64(t >> 192);
        fuses = uint32(t >> 160);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );

        _transfer(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved"
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            (address oldOwner, uint32 fuses, uint64 expiry) = getData(id);

            _beforeTransfer(id, fuses, expiry);

            require(
                amount == 1 && oldOwner == from,
                "ERC1155: insufficient balance for transfer"
            );
            _setData(id, to, fuses, expiry);
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**************************************************************************
     * Internal/private methods
     *************************************************************************/

    /**
     * @dev Sets the Name's owner address and fuses
     */
    function _setData(
        uint256 tokenId,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal virtual {
        _tokens[tokenId] =
            uint256(uint160(owner)) |
            (uint256(fuses) << 160) |
            (uint256(expiry) << 192);
    }

    function _beforeTransfer(
        uint256 id,
        uint32 fuses,
        uint64 expiry
    ) internal virtual;

    function _clearOwnerAndFuses(
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal virtual returns (address, uint32);

    function _mint(
        bytes32 node,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal virtual {
        uint256 tokenId = uint256(node);
        (address oldOwner, uint32 oldFuses, uint64 oldExpiry) = getData(
            uint256(node)
        );

        uint32 parentControlledFuses = (uint32(type(uint16).max) << 16) &
            oldFuses;

        if (oldExpiry > expiry) {
            expiry = oldExpiry;
        }

        if (oldExpiry >= block.timestamp) {
            fuses = fuses | parentControlledFuses;
        }

        require(oldOwner == address(0), "ERC1155: mint of existing token");
        require(owner != address(0), "ERC1155: mint to the zero address");
        require(
            owner != address(this),
            "ERC1155: newOwner cannot be the NameWrapper contract"
        );

        _setData(tokenId, owner, fuses, expiry);
        emit TransferSingle(msg.sender, address(0x0), owner, tokenId, 1);
        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            owner,
            tokenId,
            1,
            ""
        );
    }

    function _burn(uint256 tokenId) internal virtual {
        (address oldOwner, uint32 fuses, uint64 expiry) = ERC1155Fuse.getData(
            tokenId
        );
        (, fuses) = _clearOwnerAndFuses(oldOwner, fuses, expiry);
        // Clear approvals
        delete _tokenApprovals[tokenId];
        // Fuses and expiry are kept on burn
        _setData(tokenId, address(0x0), fuses, expiry);
        emit TransferSingle(msg.sender, oldOwner, address(0x0), tokenId, 1);
    }

    function _transfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        (address oldOwner, uint32 fuses, uint64 expiry) = getData(id);

        _beforeTransfer(id, fuses, expiry);

        require(
            amount == 1 && oldOwner == from,
            "ERC1155: insufficient balance for transfer"
        );

        if (oldOwner == to) {
            return;
        }

        _setData(id, to, fuses, expiry);

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    /* ERC721 internal functions */

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
}
