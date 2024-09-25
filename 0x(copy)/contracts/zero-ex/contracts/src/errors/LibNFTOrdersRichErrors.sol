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

library LibNFTOrdersRichErrors {
    function OverspentEthError(uint256 ethSpent, uint256 ethAvailable) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OverspentEthError(uint256,uint256)")), ethSpent, ethAvailable);
    }

    function InsufficientEthError(uint256 ethAvailable, uint256 orderAmount) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientEthError(uint256,uint256)")),
                ethAvailable,
                orderAmount
            );
    }

    function ERC721TokenMismatchError(address token1, address token2) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ERC721TokenMismatchError(address,address)")), token1, token2);
    }

    function ERC1155TokenMismatchError(address token1, address token2) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ERC1155TokenMismatchError(address,address)")), token1, token2);
    }

    function ERC20TokenMismatchError(address token1, address token2) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("ERC20TokenMismatchError(address,address)")), token1, token2);
    }

    function NegativeSpreadError(uint256 sellOrderAmount, uint256 buyOrderAmount) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("NegativeSpreadError(uint256,uint256)")),
                sellOrderAmount,
                buyOrderAmount
            );
    }

    function SellOrderFeesExceedSpreadError(
        uint256 sellOrderFees,
        uint256 spread
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("SellOrderFeesExceedSpreadError(uint256,uint256)")),
                sellOrderFees,
                spread
            );
    }

    function OnlyTakerError(address sender, address taker) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyTakerError(address,address)")), sender, taker);
    }

    function InvalidSignerError(address maker, address signer) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidSignerError(address,address)")), maker, signer);
    }

    function OrderNotFillableError(
        address maker,
        uint256 nonce,
        uint8 orderStatus
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableError(address,uint256,uint8)")),
                maker,
                nonce,
                orderStatus
            );
    }

    function TokenIdMismatchError(uint256 tokenId, uint256 orderTokenId) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(bytes4(keccak256("TokenIdMismatchError(uint256,uint256)")), tokenId, orderTokenId);
    }

    function PropertyValidationFailedError(
        address propertyValidator,
        address token,
        uint256 tokenId,
        bytes memory propertyData,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("PropertyValidationFailedError(address,address,uint256,bytes,bytes)")),
                propertyValidator,
                token,
                tokenId,
                propertyData,
                errorData
            );
    }

    function ExceedsRemainingOrderAmount(
        uint128 remainingOrderAmount,
        uint128 fillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("ExceedsRemainingOrderAmount(uint128,uint128)")),
                remainingOrderAmount,
                fillAmount
            );
    }
}
