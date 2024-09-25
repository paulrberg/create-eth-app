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

library LibMetaTransactionsRichErrors {
    function InvalidMetaTransactionsArrayLengthsError(
        uint256 mtxCount,
        uint256 signatureCount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidMetaTransactionsArrayLengthsError(uint256,uint256)")),
                mtxCount,
                signatureCount
            );
    }

    function MetaTransactionUnsupportedFunctionError(
        bytes32 mtxHash,
        bytes4 selector
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionUnsupportedFunctionError(bytes32,bytes4)")),
                mtxHash,
                selector
            );
    }

    function MetaTransactionWrongSenderError(
        bytes32 mtxHash,
        address sender,
        address expectedSender
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionWrongSenderError(bytes32,address,address)")),
                mtxHash,
                sender,
                expectedSender
            );
    }

    function MetaTransactionExpiredError(
        bytes32 mtxHash,
        uint256 time,
        uint256 expirationTime
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionExpiredError(bytes32,uint256,uint256)")),
                mtxHash,
                time,
                expirationTime
            );
    }

    function MetaTransactionGasPriceError(
        bytes32 mtxHash,
        uint256 gasPrice,
        uint256 minGasPrice,
        uint256 maxGasPrice
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionGasPriceError(bytes32,uint256,uint256,uint256)")),
                mtxHash,
                gasPrice,
                minGasPrice,
                maxGasPrice
            );
    }

    function MetaTransactionInsufficientEthError(
        bytes32 mtxHash,
        uint256 ethBalance,
        uint256 ethRequired
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionInsufficientEthError(bytes32,uint256,uint256)")),
                mtxHash,
                ethBalance,
                ethRequired
            );
    }

    function MetaTransactionInvalidSignatureError(
        bytes32 mtxHash,
        bytes memory signature,
        bytes memory errData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionInvalidSignatureError(bytes32,bytes,bytes)")),
                mtxHash,
                signature,
                errData
            );
    }

    function MetaTransactionAlreadyExecutedError(
        bytes32 mtxHash,
        uint256 executedBlockNumber
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionAlreadyExecutedError(bytes32,uint256)")),
                mtxHash,
                executedBlockNumber
            );
    }

    function MetaTransactionCallFailedError(
        bytes32 mtxHash,
        bytes memory callData,
        bytes memory returnData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("MetaTransactionCallFailedError(bytes32,bytes,bytes)")),
                mtxHash,
                callData,
                returnData
            );
    }
}
