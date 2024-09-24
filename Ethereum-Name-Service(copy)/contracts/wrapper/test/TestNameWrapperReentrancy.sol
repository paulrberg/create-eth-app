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

import "../INameWrapper.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "Ethereum-Name-Service/@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract TestNameWrapperReentrancy is ERC165, IERC1155Receiver {
    INameWrapper nameWrapper;
    address owner;
    bytes32 parentNode;
    bytes32 labelHash;
    uint256 tokenId;

    constructor(
        address _owner,
        INameWrapper _nameWrapper,
        bytes32 _parentNode,
        bytes32 _labelHash
    ) {
        owner = _owner;
        nameWrapper = _nameWrapper;
        parentNode = _parentNode;
        labelHash = _labelHash;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256 _id,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        tokenId = _id;
        nameWrapper.unwrap(parentNode, labelHash, owner);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function claimToOwner() public {
        nameWrapper.safeTransferFrom(address(this), owner, tokenId, 1, "");
    }
}
