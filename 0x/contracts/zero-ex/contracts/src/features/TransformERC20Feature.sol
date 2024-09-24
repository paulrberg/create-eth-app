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

import "0x/contracts/erc20/src/IERC20Token.sol";
import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibBytesV06.sol";
import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinTokenSpender.sol";
import "../migrations/LibMigrate.sol";
import "../external/IFlashWallet.sol";
import "../external/FlashWallet.sol";
import "../storage/LibTransformERC20Storage.sol";
import "../transformers/IERC20Transformer.sol";
import "../transformers/LibERC20Transformer.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ITransformERC20Feature.sol";

/// @dev Feature to composably transform between ERC20 tokens.
contract TransformERC20Feature is IFeature, ITransformERC20Feature, FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Stack vars for `_transformERC20Private()`.
    struct TransformERC20PrivateState {
        IFlashWallet wallet;
        address transformerDeployer;
        uint256 recipientOutputTokenBalanceBefore;
        uint256 recipientOutputTokenBalanceAfter;
    }

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "TransformERC20";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 4, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @param transformerDeployer The trusted deployer for transformers.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate(address transformerDeployer) external returns (bytes4 success) {
        _registerFeatureFunction(this.getTransformerDeployer.selector);
        _registerFeatureFunction(this.createTransformWallet.selector);
        _registerFeatureFunction(this.getTransformWallet.selector);
        _registerFeatureFunction(this.setTransformerDeployer.selector);
        _registerFeatureFunction(this.setQuoteSigner.selector);
        _registerFeatureFunction(this.getQuoteSigner.selector);
        _registerFeatureFunction(this.transformERC20.selector);
        _registerFeatureFunction(this._transformERC20.selector);
        if (this.getTransformWallet() == IFlashWallet(address(0))) {
            // Create the transform wallet if it doesn't exist.
            this.createTransformWallet();
        }
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the trusted deployer for transformers.
    function setTransformerDeployer(address transformerDeployer) external override onlyOwner {
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        emit TransformerDeployerUpdated(transformerDeployer);
    }

    /// @dev Replace the optional signer for `transformERC20()` calldata.
    ///      Only callable by the owner.
    /// @param quoteSigner The address of the new calldata signer.
    function setQuoteSigner(address quoteSigner) external override onlyOwner {
        LibTransformERC20Storage.getStorage().quoteSigner = quoteSigner;
        emit QuoteSignerUpdated(quoteSigner);
    }

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer() public view override returns (address deployer) {
        return LibTransformERC20Storage.getStorage().transformerDeployer;
    }

    /// @dev Return the optional signer for `transformERC20()` calldata.
    /// @return signer The signer address.
    function getQuoteSigner() public view override returns (address signer) {
        return LibTransformERC20Storage.getStorage().quoteSigner;
    }

    /// @dev Deploy a new wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///      Only callable by the owner.
    /// @return wallet The new wallet instance.
    function createTransformWallet() public override onlyOwner returns (IFlashWallet wallet) {
        wallet = new FlashWallet();
        LibTransformERC20Storage.getStorage().wallet = wallet;
    }

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    ///        If set to `uint256(-1)`, the entire spendable balance of the taker
    ///        will be solt.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed. If set to zero,
    ///        the minimum output token transfer will not be asserted.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    ) public payable override returns (uint256 outputTokenAmount) {
        return
            _transformERC20Private(
                TransformERC20Args({
                    taker: msg.sender,
                    inputToken: inputToken,
                    outputToken: outputToken,
                    inputTokenAmount: inputTokenAmount,
                    minOutputTokenAmount: minOutputTokenAmount,
                    transformations: transformations,
                    useSelfBalance: false,
                    recipient: msg.sender
                })
            );
    }

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(
        TransformERC20Args memory args
    ) public payable virtual override onlySelf returns (uint256 outputTokenAmount) {
        return _transformERC20Private(args);
    }

    /// @dev Private version of `transformERC20()`.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20Private(TransformERC20Args memory args) private returns (uint256 outputTokenAmount) {
        // If the input token amount is -1 and we are not selling ETH,
        // transform the taker's entire spendable balance.
        if (!args.useSelfBalance && args.inputTokenAmount == uint256(-1)) {
            if (LibERC20Transformer.isTokenETH(args.inputToken)) {
                // We can't pull more ETH from the taker, so we just set the
                // input token amount to the value attached to the call.
                args.inputTokenAmount = msg.value;
            } else {
                args.inputTokenAmount = _getSpendableERC20BalanceOf(args.inputToken, args.taker);
            }
        }

        TransformERC20PrivateState memory state;
        state.wallet = getTransformWallet();
        state.transformerDeployer = getTransformerDeployer();

        // Remember the initial output token balance of the recipient.
        state.recipientOutputTokenBalanceBefore = LibERC20Transformer.getTokenBalanceOf(
            args.outputToken,
            args.recipient
        );

        // Pull input tokens from the taker to the wallet and transfer attached ETH.
        _transferInputTokensAndAttachedEth(args, address(state.wallet));

        {
            // Perform transformations.
            for (uint256 i = 0; i < args.transformations.length; ++i) {
                _executeTransformation(
                    state.wallet,
                    args.transformations[i],
                    state.transformerDeployer,
                    args.recipient
                );
            }
            // Transfer output tokens from wallet to recipient
            outputTokenAmount = _executeOutputTokenTransfer(args.outputToken, state.wallet, args.recipient);
        }

        // Compute how much output token has been transferred to the recipient.
        state.recipientOutputTokenBalanceAfter = LibERC20Transformer.getTokenBalanceOf(
            args.outputToken,
            args.recipient
        );
        if (state.recipientOutputTokenBalanceAfter < state.recipientOutputTokenBalanceBefore) {
            LibTransformERC20RichErrors
                .NegativeTransformERC20OutputError(
                    address(args.outputToken),
                    state.recipientOutputTokenBalanceBefore - state.recipientOutputTokenBalanceAfter
                )
                .rrevert();
        }
        outputTokenAmount = LibSafeMathV06.min256(
            outputTokenAmount,
            state.recipientOutputTokenBalanceAfter.safeSub(state.recipientOutputTokenBalanceBefore)
        );
        // Ensure enough output token has been sent to the taker.
        if (outputTokenAmount < args.minOutputTokenAmount) {
            LibTransformERC20RichErrors
                .IncompleteTransformERC20Error(address(args.outputToken), outputTokenAmount, args.minOutputTokenAmount)
                .rrevert();
        }

        // Emit an event.
        emit TransformedERC20(
            args.taker,
            address(args.inputToken),
            address(args.outputToken),
            args.inputTokenAmount,
            outputTokenAmount
        );
    }

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet() public view override returns (IFlashWallet wallet) {
        return LibTransformERC20Storage.getStorage().wallet;
    }

    /// @dev Transfer input tokens and any attached ETH to `to`
    /// @param args A `TransformERC20Args` struct.
    /// @param to The recipient of tokens and ETH.
    function _transferInputTokensAndAttachedEth(TransformERC20Args memory args, address payable to) private {
        if (LibERC20Transformer.isTokenETH(args.inputToken) && msg.value < args.inputTokenAmount) {
            // Token is ETH, so the caller must attach enough ETH to the call.
            LibTransformERC20RichErrors.InsufficientEthAttachedError(msg.value, args.inputTokenAmount).rrevert();
        }

        // Transfer any attached ETH.
        if (msg.value != 0) {
            to.transfer(msg.value);
        }

        // Transfer input tokens.
        if (!LibERC20Transformer.isTokenETH(args.inputToken)) {
            if (args.useSelfBalance) {
                // Use EP balance input token.
                _transferERC20Tokens(args.inputToken, to, args.inputTokenAmount);
            } else {
                // Pull ERC20 tokens from taker.
                _transferERC20TokensFrom(args.inputToken, args.taker, to, args.inputTokenAmount);
            }
        }
    }

    /// @dev Executs a transformer in the context of `wallet`.
    /// @param wallet The wallet instance.
    /// @param transformation The transformation.
    /// @param transformerDeployer The address of the transformer deployer.
    /// @param recipient The recipient address.
    function _executeTransformation(
        IFlashWallet wallet,
        Transformation memory transformation,
        address transformerDeployer,
        address payable recipient
    ) private {
        // Derive the transformer address from the deployment nonce.
        address payable transformer = LibERC20Transformer.getDeployedAddress(
            transformerDeployer,
            transformation.deploymentNonce
        );
        // Call `transformer.transform()` as the wallet.
        bytes memory resultData = wallet.executeDelegateCall(
            // The call target.
            transformer,
            // Call data.
            abi.encodeWithSelector(
                IERC20Transformer.transform.selector,
                IERC20Transformer.TransformContext({
                    sender: msg.sender,
                    recipient: recipient,
                    data: transformation.data
                })
            )
        );
        // Ensure the transformer returned the magic bytes.
        if (resultData.length != 32 || abi.decode(resultData, (bytes4)) != LibERC20Transformer.TRANSFORMER_SUCCESS) {
            LibTransformERC20RichErrors.TransformerFailedError(transformer, transformation.data, resultData).rrevert();
        }
    }

    function _executeOutputTokenTransfer(
        IERC20Token outputToken,
        IFlashWallet wallet,
        address payable recipient
    ) private returns (uint256 transferAmount) {
        transferAmount = LibERC20Transformer.getTokenBalanceOf(outputToken, address(wallet));
        if (LibERC20Transformer.isTokenETH(outputToken)) {
            wallet.executeCall(recipient, "", transferAmount);
        } else {
            bytes memory resultData = wallet.executeCall(
                payable(address(outputToken)),
                abi.encodeWithSelector(IERC20Token.transfer.selector, recipient, transferAmount),
                0
            );
            if (resultData.length == 0) {
                // If we get back 0 returndata, this may be a non-standard ERC-20 that
                // does not return a boolean. Check that it at least contains code.
                uint256 size;
                assembly {
                    size := extcodesize(outputToken)
                }
                require(size > 0, "invalid token address, contains no code");
            } else if (resultData.length >= 32) {
                // If we get back at least 32 bytes, we know the target address
                // contains code, and we assume it is a token that returned a boolean
                // success value, which must be true.
                uint256 result = LibBytesV06.readUint256(resultData, 0);
                if (result != 1) {
                    LibRichErrorsV06.rrevert(resultData);
                }
            } else {
                // If 0 < returndatasize < 32, the target is a contract, but not a
                // valid token.
                LibRichErrorsV06.rrevert(resultData);
            }
        }
    }
}
