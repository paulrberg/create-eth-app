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
  
  // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestERC1155Revert {
    function safeTransferFrom(
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes calldata /* data */
    ) public pure {
        revert(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        );
    }

    function safeBatchTransferFrom(
        address /* from */,
        address /* to */,
        uint256[] memory /* ids */,
        uint256[] memory /* values */,
        bytes memory /* data */
    ) public pure {
        revert("Some ERC1155 revert message for batch transfers");
    }

    function getRevertData() public pure returns (bytes memory) {
        assembly {
            mstore(0x40, 0)
            mstore(0, shl(20, 1))
            mstore(add(0x20, shl(20, 1)), 1)
            return(0, add(0x20, shl(20, 1)))
        }
    }
}
