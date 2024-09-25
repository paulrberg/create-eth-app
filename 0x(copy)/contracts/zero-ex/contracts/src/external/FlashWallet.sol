/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/0x?utm=code
  */
  
  // SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/utils/contracts/src/v06/errors/LibOwnableRichErrorsV06.sol";
import "../errors/LibWalletRichErrors.sol";
import "./IFlashWallet.sol";

/// @dev A contract that can execute arbitrary calls from its owner.
contract FlashWallet is IFlashWallet {
    using LibRichErrorsV06 for bytes;

    /// @dev Store the owner/deployer as an immutable to make this contract stateless.
    address public immutable override owner;

    constructor() public {
        // The deployer is the owner.
        owner = msg.sender;
    }

    /// @dev Allows only the (immutable) owner to call a function.
    modifier onlyOwner() virtual {
        if (msg.sender != owner) {
            LibOwnableRichErrorsV06.OnlyOwnerError(msg.sender, owner).rrevert();
        }
        _;
    }

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    ) external payable override onlyOwner returns (bytes memory resultData) {
        bool success;
        (success, resultData) = target.call{value: value}(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteCallFailedError(address(this), target, callData, value, resultData)
                .rrevert();
        }
    }

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    ) external payable override onlyOwner returns (bytes memory resultData) {
        bool success;
        (success, resultData) = target.delegatecall(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteDelegateCallFailedError(address(this), target, callData, resultData)
                .rrevert();
        }
    }

    /// @dev Allows this contract to receive ether.
    receive() external payable override {}

    /// @dev Signal support for receiving ERC1155 tokens.
    /// @param interfaceID The interface ID, as per ERC-165 rules.
    /// @return hasSupport `true` if this contract supports an ERC-165 interface.
    function supportsInterface(bytes4 interfaceID) external pure returns (bool hasSupport) {
        return
            interfaceID == this.supportsInterface.selector ||
            interfaceID == this.onERC1155Received.selector ^ this.onERC1155BatchReceived.selector ||
            interfaceID == this.tokenFallback.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(
        address, // operator,
        address, // from,
        uint256, // id,
        uint256, // value,
        bytes calldata //data
    ) external pure returns (bytes4 success) {
        return this.onERC1155Received.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    function onERC1155BatchReceived(
        address, // operator,
        address, // from,
        uint256[] calldata, // ids,
        uint256[] calldata, // values,
        bytes calldata // data
    ) external pure returns (bytes4 success) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @dev Allows this contract to receive ERC223 tokens.
    function tokenFallback(
        address, // from,
        uint256, // value,
        bytes calldata // value
    ) external pure {}
}
