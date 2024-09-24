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

library LibTransformERC20RichErrors {
    function InsufficientEthAttachedError(uint256 ethAttached, uint256 ethNeeded) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientEthAttachedError(uint256,uint256)")),
                ethAttached,
                ethNeeded
            );
    }

    function IncompleteTransformERC20Error(
        address outputToken,
        uint256 outputTokenAmount,
        uint256 minOutputTokenAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IncompleteTransformERC20Error(address,uint256,uint256)")),
                outputToken,
                outputTokenAmount,
                minOutputTokenAmount
            );
    }

    function NegativeTransformERC20OutputError(
        address outputToken,
        uint256 outputTokenLostAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("NegativeTransformERC20OutputError(address,uint256)")),
                outputToken,
                outputTokenLostAmount
            );
    }

    function TransformerFailedError(
        address transformer,
        bytes memory transformerData,
        bytes memory resultData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("TransformerFailedError(address,bytes,bytes)")),
                transformer,
                transformerData,
                resultData
            );
    }

    // Common Transformer errors ///////////////////////////////////////////////

    function OnlyCallableByDeployerError(address caller, address deployer) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(bytes4(keccak256("OnlyCallableByDeployerError(address,address)")), caller, deployer);
    }

    function InvalidExecutionContextError(
        address actualContext,
        address expectedContext
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidExecutionContextError(address,address)")),
                actualContext,
                expectedContext
            );
    }

    enum InvalidTransformDataErrorCode {
        INVALID_TOKENS,
        INVALID_ARRAY_LENGTH
    }

    function InvalidTransformDataError(
        InvalidTransformDataErrorCode errorCode,
        bytes memory transformData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InvalidTransformDataError(uint8,bytes)")),
                errorCode,
                transformData
            );
    }

    // FillQuoteTransformer errors /////////////////////////////////////////////

    function IncompleteFillSellQuoteError(
        address sellToken,
        uint256 soldAmount,
        uint256 sellAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IncompleteFillSellQuoteError(address,uint256,uint256)")),
                sellToken,
                soldAmount,
                sellAmount
            );
    }

    function IncompleteFillBuyQuoteError(
        address buyToken,
        uint256 boughtAmount,
        uint256 buyAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IncompleteFillBuyQuoteError(address,uint256,uint256)")),
                buyToken,
                boughtAmount,
                buyAmount
            );
    }

    function InsufficientTakerTokenError(
        uint256 tokenBalance,
        uint256 tokensNeeded
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientTakerTokenError(uint256,uint256)")),
                tokenBalance,
                tokensNeeded
            );
    }

    function InsufficientProtocolFeeError(uint256 ethBalance, uint256 ethNeeded) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("InsufficientProtocolFeeError(uint256,uint256)")),
                ethBalance,
                ethNeeded
            );
    }

    function InvalidERC20AssetDataError(bytes memory assetData) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidERC20AssetDataError(bytes)")), assetData);
    }

    function InvalidTakerFeeTokenError(address token) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidTakerFeeTokenError(address)")), token);
    }
}
