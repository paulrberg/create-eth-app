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

import "0x/contracts/erc20/src/IEtherToken.sol";
import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibBytesV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibMetaTransactionsRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinReentrancyGuard.sol";
import "../fixins/FixinTokenSpender.sol";
import "../fixins/FixinEIP712.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibMetaTransactionsV2Storage.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IMetaTransactionsFeatureV2.sol";
import "./interfaces/IMultiplexFeature.sol";
import "./interfaces/INativeOrdersFeature.sol";
import "./interfaces/ITransformERC20Feature.sol";
import "./libs/LibSignature.sol";

/// @dev MetaTransactions feature.
contract MetaTransactionsFeatureV2 is
    IFeature,
    IMetaTransactionsFeatureV2,
    FixinCommon,
    FixinReentrancyGuard,
    FixinEIP712,
    FixinTokenSpender
{
    using LibBytesV06 for bytes;
    using LibRichErrorsV06 for bytes;

    /// @dev Describes the state of a meta transaction.
    struct ExecuteState {
        // Sender of the meta-transaction.
        address sender;
        // Hash of the meta-transaction data.
        bytes32 hash;
        // The meta-transaction data.
        MetaTransactionDataV2 mtx;
        // The meta-transaction signature (by `mtx.signer`).
        LibSignature.Signature signature;
        // The selector of the function being called.
        bytes4 selector;
        // The ETH balance of this contract before performing the call.
        uint256 selfBalance;
        // The block number at which the meta-transaction was executed.
        uint256 executedBlockNumber;
    }

    /// @dev Arguments for a `TransformERC20.transformERC20()` call.
    struct ExternalTransformERC20Args {
        IERC20Token inputToken;
        IERC20Token outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        ITransformERC20Feature.Transformation[] transformations;
    }

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "MetaTransactionsV2";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev EIP712 typehash of the `MetaTransactionData` struct.
    bytes32 public immutable MTX_EIP712_TYPEHASH =
        keccak256(
            "MetaTransactionDataV2("
            "address signer,"
            "address sender,"
            "uint256 expirationTimeSeconds,"
            "uint256 salt,"
            "bytes callData,"
            "address feeToken,"
            "MetaTransactionFeeData[] fees"
            ")"
            "MetaTransactionFeeData("
            "address recipient,"
            "uint256 amount"
            ")"
        );
    bytes32 public immutable MTX_FEE_TYPEHASH =
        keccak256(
            "MetaTransactionFeeData("
            "address recipient,"
            "uint256 amount"
            ")"
        );

    /// @dev The WETH token contract.
    IEtherToken private immutable WETH;

    /// @dev Ensures that the ETH balance of `this` does not go below the
    ///      initial ETH balance before the call (excluding ETH attached to the call).
    modifier doesNotReduceEthBalance() {
        uint256 initialBalance = address(this).balance;
        _;
        require(initialBalance <= address(this).balance, "MetaTransactionsFeatureV2/ETH_LEAK");
    }

    constructor(address zeroExAddress, IEtherToken weth) public FixinCommon() FixinEIP712(zeroExAddress) {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.executeMetaTransactionV2.selector);
        _registerFeatureFunction(this.batchExecuteMetaTransactionsV2.selector);
        _registerFeatureFunction(this.getMetaTransactionV2ExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionV2HashExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionV2Hash.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Execute a single meta-transaction.
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function executeMetaTransactionV2(
        MetaTransactionDataV2 memory mtx,
        LibSignature.Signature memory signature
    ) public override nonReentrant(REENTRANCY_MTX) doesNotReduceEthBalance returns (bytes memory returnResult) {
        ExecuteState memory state;
        state.sender = msg.sender;
        state.mtx = mtx;
        state.hash = getMetaTransactionV2Hash(mtx);
        state.signature = signature;

        returnResult = _executeMetaTransactionPrivate(state);
    }

    /// @dev Execute multiple meta-transactions.
    /// @param mtxs The meta-transactions.
    /// @param signatures The signature by each respective `mtx.signer`.
    /// @return returnResults The ABI-encoded results of the underlying calls.
    function batchExecuteMetaTransactionsV2(
        MetaTransactionDataV2[] memory mtxs,
        LibSignature.Signature[] memory signatures
    ) public override nonReentrant(REENTRANCY_MTX) doesNotReduceEthBalance returns (bytes[] memory returnResults) {
        if (mtxs.length != signatures.length) {
            LibMetaTransactionsRichErrors
                .InvalidMetaTransactionsArrayLengthsError(mtxs.length, signatures.length)
                .rrevert();
        }
        returnResults = new bytes[](mtxs.length);
        for (uint256 i = 0; i < mtxs.length; ++i) {
            ExecuteState memory state;
            state.sender = msg.sender;
            state.mtx = mtxs[i];
            state.hash = getMetaTransactionV2Hash(mtxs[i]);
            state.signature = signatures[i];

            returnResults[i] = _executeMetaTransactionPrivate(state);
        }
    }

    /// @dev Get the block at which a meta-transaction has been executed.
    /// @param mtx The meta-transaction.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionV2ExecutedBlock(
        MetaTransactionDataV2 memory mtx
    ) public view override returns (uint256 blockNumber) {
        return getMetaTransactionV2HashExecutedBlock(getMetaTransactionV2Hash(mtx));
    }

    /// @dev Get the block at which a meta-transaction hash has been executed.
    /// @param mtxHash The meta-transaction hash.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionV2HashExecutedBlock(bytes32 mtxHash) public view override returns (uint256 blockNumber) {
        return LibMetaTransactionsV2Storage.getStorage().mtxHashToExecutedBlockNumber[mtxHash];
    }

    /// @dev Get the EIP712 hash of a meta-transaction.
    /// @param mtx The meta-transaction.
    /// @return mtxHash The EIP712 hash of `mtx`.
    function getMetaTransactionV2Hash(MetaTransactionDataV2 memory mtx) public view override returns (bytes32 mtxHash) {
        bytes32[] memory feeHashes = new bytes32[](mtx.fees.length);
        for (uint256 i = 0; i < mtx.fees.length; ++i) {
            feeHashes[i] = keccak256(abi.encode(MTX_FEE_TYPEHASH, mtx.fees[i]));
        }

        return
            _getEIP712Hash(
                keccak256(
                    abi.encode(
                        MTX_EIP712_TYPEHASH,
                        mtx.signer,
                        mtx.sender,
                        mtx.expirationTimeSeconds,
                        mtx.salt,
                        keccak256(mtx.callData),
                        mtx.feeToken,
                        keccak256(abi.encodePacked(feeHashes))
                    )
                )
            );
    }

    /// @dev Execute a meta-transaction by `sender`. Low-level, hidden variant.
    /// @param state The `ExecuteState` for this metatransaction, with `sender`,
    ///              `hash`, `mtx`, and `signature` fields filled.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function _executeMetaTransactionPrivate(ExecuteState memory state) private returns (bytes memory returnResult) {
        _validateMetaTransaction(state);

        // Mark the transaction executed by storing the block at which it was executed.
        // Currently the block number just indicates that the mtx was executed and
        // serves no other purpose from within this contract.
        LibMetaTransactionsV2Storage.getStorage().mtxHashToExecutedBlockNumber[state.hash] = block.number;

        // Pay the fees to the fee recipients.
        for (uint256 i = 0; i < state.mtx.fees.length; ++i) {
            _transferERC20TokensFrom(
                state.mtx.feeToken,
                state.mtx.signer,
                state.mtx.fees[i].recipient,
                state.mtx.fees[i].amount
            );
        }

        // Execute the call based on the selector.
        state.selector = state.mtx.callData.readBytes4(0);
        if (state.selector == ITransformERC20Feature.transformERC20.selector) {
            returnResult = _executeTransformERC20Call(state);
        } else if (state.selector == INativeOrdersFeature.fillLimitOrder.selector) {
            returnResult = _executeFillLimitOrderCall(state);
        } else if (state.selector == INativeOrdersFeature.fillRfqOrder.selector) {
            returnResult = _executeFillRfqOrderCall(state);
        } else if (state.selector == IMultiplexFeature.multiplexBatchSellTokenForToken.selector) {
            returnResult = _executeMultiplexBatchSellTokenForTokenCall(state);
        } else if (state.selector == IMultiplexFeature.multiplexBatchSellTokenForEth.selector) {
            returnResult = _executeMultiplexBatchSellTokenForEthCall(state);
        } else if (state.selector == IMultiplexFeature.multiplexMultiHopSellTokenForToken.selector) {
            returnResult = _executeMultiplexMultiHopSellTokenForTokenCall(state);
        } else if (state.selector == IMultiplexFeature.multiplexMultiHopSellTokenForEth.selector) {
            returnResult = _executeMultiplexMultiHopSellTokenForEthCall(state);
        } else {
            LibMetaTransactionsRichErrors.MetaTransactionUnsupportedFunctionError(state.hash, state.selector).rrevert();
        }
        emit MetaTransactionExecuted(state.hash, state.selector, state.mtx.signer, state.mtx.sender);
    }

    /// @dev Validate that a meta-transaction is executable.
    function _validateMetaTransaction(ExecuteState memory state) private view {
        // Must be from the required sender, if set.
        if (state.mtx.sender != address(0) && state.mtx.sender != state.sender) {
            LibMetaTransactionsRichErrors
                .MetaTransactionWrongSenderError(state.hash, state.sender, state.mtx.sender)
                .rrevert();
        }
        // Must not be expired.
        if (state.mtx.expirationTimeSeconds <= block.timestamp) {
            LibMetaTransactionsRichErrors
                .MetaTransactionExpiredError(state.hash, block.timestamp, state.mtx.expirationTimeSeconds)
                .rrevert();
        }

        if (LibSignature.getSignerOfHash(state.hash, state.signature) != state.mtx.signer) {
            LibSignatureRichErrors
                .SignatureValidationError(
                    LibSignatureRichErrors.SignatureValidationErrorCodes.WRONG_SIGNER,
                    state.hash,
                    state.mtx.signer,
                    // TODO: Remove this field from SignatureValidationError
                    //       when rich reverts are part of the protocol repo.
                    ""
                )
                .rrevert();
        }
        // Transaction must not have been already executed.
        state.executedBlockNumber = LibMetaTransactionsV2Storage.getStorage().mtxHashToExecutedBlockNumber[state.hash];
        if (state.executedBlockNumber != 0) {
            LibMetaTransactionsRichErrors
                .MetaTransactionAlreadyExecutedError(state.hash, state.executedBlockNumber)
                .rrevert();
        }
    }

    /// @dev Execute a `ITransformERC20Feature.transformERC20()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `ITransformERC20Feature._transformERC20()` variant, where we can override
    ///      the taker address.
    function _executeTransformERC20Call(ExecuteState memory state) private returns (bytes memory returnResult) {
        // HACK(dorothy-zbornak): `abi.decode()` with the individual args
        // will cause a stack overflow. But we can prefix the call data with an
        // offset to transform it into the encoding for the equivalent single struct arg,
        // since decoding a single struct arg consumes far less stack space than
        // decoding multiple struct args.

        // Where the encoding for multiple args (with the selector ommitted)
        // would typically look like:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | inputToken               |       0 |
        // | outputToken              |      32 |
        // | inputTokenAmount         |      64 |
        // | minOutputTokenAmount     |      96 |
        // | transformations (offset) |     128 | = 32
        // | transformations (data)   |     160 |

        // We will ABI-decode a single struct arg copy with the layout:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | (arg 1 offset)           |       0 | = 32
        // | inputToken               |      32 |
        // | outputToken              |      64 |
        // | inputTokenAmount         |      96 |
        // | minOutputTokenAmount     |     128 |
        // | transformations (offset) |     160 | = 32
        // | transformations (data)   |     192 |

        ExternalTransformERC20Args memory args;
        {
            bytes memory encodedStructArgs = new bytes(state.mtx.callData.length - 4 + 32);
            // Copy the args data from the original, after the new struct offset prefix.
            bytes memory fromCallData = state.mtx.callData;
            assert(fromCallData.length >= 160);
            uint256 fromMem;
            uint256 toMem;
            assembly {
                // Prefix the calldata with a struct offset,
                // which points to just one word over.
                mstore(add(encodedStructArgs, 32), 32)
                // Copy everything after the selector.
                fromMem := add(fromCallData, 36)
                // Start copying after the struct offset.
                toMem := add(encodedStructArgs, 64)
            }
            LibBytesV06.memCopy(toMem, fromMem, fromCallData.length - 4);
            // Decode call args for `ITransformERC20Feature.transformERC20()` as a struct.
            args = abi.decode(encodedStructArgs, (ExternalTransformERC20Args));
        }
        // Call `ITransformERC20Feature._transformERC20()` (internal variant).
        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    ITransformERC20Feature._transformERC20.selector,
                    ITransformERC20Feature.TransformERC20Args({
                        taker: state.mtx.signer, // taker is mtx signer
                        inputToken: args.inputToken,
                        outputToken: args.outputToken,
                        inputTokenAmount: args.inputTokenAmount,
                        minOutputTokenAmount: args.minOutputTokenAmount,
                        transformations: args.transformations,
                        useSelfBalance: false,
                        recipient: state.mtx.signer
                    })
                )
            );
    }

    /// @dev Extract arguments from call data by copying everything after the
    ///      4-byte selector into a new byte array.
    /// @param callData The call data from which arguments are to be extracted.
    /// @return args The extracted arguments as a byte array.
    function _extractArgumentsFromCallData(bytes memory callData) private pure returns (bytes memory args) {
        args = new bytes(callData.length - 4);
        uint256 fromMem;
        uint256 toMem;

        assembly {
            fromMem := add(callData, 36) // skip length and 4-byte selector
            toMem := add(args, 32) // write after length prefix
        }

        LibBytesV06.memCopy(toMem, fromMem, args.length);

        return args;
    }

    /// @dev Execute a `INativeOrdersFeature.fillLimitOrder()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `INativeOrdersFeature._fillLimitOrder()` variant, where we can override
    ///      the taker address.
    function _executeFillLimitOrderCall(ExecuteState memory state) private returns (bytes memory returnResult) {
        LibNativeOrder.LimitOrder memory order;
        LibSignature.Signature memory signature;
        uint128 takerTokenFillAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (order, signature, takerTokenFillAmount) = abi.decode(
            args,
            (LibNativeOrder.LimitOrder, LibSignature.Signature, uint128)
        );

        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    INativeOrdersFeature._fillLimitOrder.selector,
                    order,
                    signature,
                    takerTokenFillAmount,
                    state.mtx.signer, // taker is mtx signer
                    msg.sender
                )
            );
    }

    /// @dev Execute a `INativeOrdersFeature.fillRfqOrder()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `INativeOrdersFeature._fillRfqOrder()` variant, where we can override
    ///      the taker address.
    function _executeFillRfqOrderCall(ExecuteState memory state) private returns (bytes memory returnResult) {
        LibNativeOrder.RfqOrder memory order;
        LibSignature.Signature memory signature;
        uint128 takerTokenFillAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (order, signature, takerTokenFillAmount) = abi.decode(
            args,
            (LibNativeOrder.RfqOrder, LibSignature.Signature, uint128)
        );

        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    INativeOrdersFeature._fillRfqOrder.selector,
                    order,
                    signature,
                    takerTokenFillAmount,
                    state.mtx.signer, // taker is mtx signer
                    false,
                    state.mtx.signer
                )
            );
    }

    /// @dev Execute a `IMultiplexFeature.multiplexBatchSellTokenForToken()` meta-transaction
    ///      call by decoding the call args and translating the call to the internal
    ///      `IMultiplexFeature._multiplexBatchSell()` variant, where we can override the
    ///      payer address.
    function _executeMultiplexBatchSellTokenForTokenCall(
        ExecuteState memory state
    ) private returns (bytes memory returnResult) {
        IERC20Token inputToken;
        IERC20Token outputToken;
        IMultiplexFeature.BatchSellSubcall[] memory calls;
        uint256 sellAmount;
        uint256 minBuyAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (inputToken, outputToken, calls, sellAmount, minBuyAmount) = abi.decode(
            args,
            (IERC20Token, IERC20Token, IMultiplexFeature.BatchSellSubcall[], uint256, uint256)
        );

        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    IMultiplexFeature._multiplexBatchSell.selector,
                    IMultiplexFeature.BatchSellParams({
                        inputToken: inputToken,
                        outputToken: outputToken,
                        sellAmount: sellAmount,
                        calls: calls,
                        useSelfBalance: false,
                        recipient: state.mtx.signer,
                        payer: state.mtx.signer
                    }),
                    minBuyAmount
                )
            );
    }

    /// @dev Execute a `IMultiplexFeature.multiplexBatchSellTokenForEth()` meta-transaction
    ///      call by decoding the call args and translating the call to the internal
    ///      `IMultiplexFeature._multiplexBatchSellTokenForEth()` variant, where we can override the
    ///      payer address.
    function _executeMultiplexBatchSellTokenForEthCall(
        ExecuteState memory state
    ) private returns (bytes memory returnResult) {
        IERC20Token inputToken;
        IMultiplexFeature.BatchSellSubcall[] memory calls;
        uint256 sellAmount;
        uint256 minBuyAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (inputToken, calls, sellAmount, minBuyAmount) = abi.decode(
            args,
            (IERC20Token, IMultiplexFeature.BatchSellSubcall[], uint256, uint256)
        );

        returnResult = _callSelf(
            state.hash,
            abi.encodeWithSelector(
                IMultiplexFeature._multiplexBatchSell.selector,
                IMultiplexFeature.BatchSellParams({
                    inputToken: inputToken,
                    outputToken: IERC20Token(WETH),
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: address(this),
                    payer: state.mtx.signer
                }),
                minBuyAmount
            )
        );

        // Unwrap and transfer WETH
        uint256 boughtAmount = abi.decode(returnResult, (uint256));
        WETH.withdraw(boughtAmount);
        _transferEth(state.mtx.signer, boughtAmount);
    }

    /// @dev Execute a `IMultiplexFeature.multiplexMultiHopSellTokenForToken()` meta-transaction
    ///      call by decoding the call args and translating the call to the internal
    ///      `IMultiplexFeature._multiplexMultiHopSell()` variant, where we can override the
    ///      payer address.
    function _executeMultiplexMultiHopSellTokenForTokenCall(
        ExecuteState memory state
    ) private returns (bytes memory returnResult) {
        address[] memory tokens;
        IMultiplexFeature.MultiHopSellSubcall[] memory calls;
        uint256 sellAmount;
        uint256 minBuyAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (tokens, calls, sellAmount, minBuyAmount) = abi.decode(
            args,
            (address[], IMultiplexFeature.MultiHopSellSubcall[], uint256, uint256)
        );

        return
            _callSelf(
                state.hash,
                abi.encodeWithSelector(
                    IMultiplexFeature._multiplexMultiHopSell.selector,
                    IMultiplexFeature.MultiHopSellParams({
                        tokens: tokens,
                        sellAmount: sellAmount,
                        calls: calls,
                        useSelfBalance: false,
                        recipient: state.mtx.signer,
                        payer: state.mtx.signer
                    }),
                    minBuyAmount
                )
            );
    }

    /// @dev Execute a `IMultiplexFeature.multiplexMultiHopSellTokenForEth()` meta-transaction
    ///      call by decoding the call args and translating the call to the internal
    ///      `IMultiplexFeature._multiplexMultiHopSellTokenForEth()` variant, where we can override the
    ///      payer address.
    function _executeMultiplexMultiHopSellTokenForEthCall(
        ExecuteState memory state
    ) private returns (bytes memory returnResult) {
        address[] memory tokens;
        IMultiplexFeature.MultiHopSellSubcall[] memory calls;
        uint256 sellAmount;
        uint256 minBuyAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (tokens, calls, sellAmount, minBuyAmount) = abi.decode(
            args,
            (address[], IMultiplexFeature.MultiHopSellSubcall[], uint256, uint256)
        );

        require(
            tokens[tokens.length - 1] == address(WETH),
            "MetaTransactionsFeature::multiplexMultiHopSellTokenForEth/NOT_WETH"
        );

        returnResult = _callSelf(
            state.hash,
            abi.encodeWithSelector(
                IMultiplexFeature._multiplexMultiHopSell.selector,
                IMultiplexFeature.MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: address(this),
                    payer: state.mtx.signer
                }),
                minBuyAmount
            )
        );

        // Unwrap and transfer WETH
        uint256 boughtAmount = abi.decode(returnResult, (uint256));
        WETH.withdraw(boughtAmount);
        _transferEth(state.mtx.signer, boughtAmount);
    }

    /// @dev Make an arbitrary internal, meta-transaction call.
    ///      Warning: Do not let unadulterated `callData` into this function.
    function _callSelf(bytes32 hash, bytes memory callData) private returns (bytes memory returnResult) {
        bool success;
        (success, returnResult) = address(this).call(callData);
        if (!success) {
            LibMetaTransactionsRichErrors.MetaTransactionCallFailedError(hash, callData, returnResult).rrevert();
        }
    }
}
