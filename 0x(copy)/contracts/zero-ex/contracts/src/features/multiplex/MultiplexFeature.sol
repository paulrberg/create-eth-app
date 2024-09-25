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
import "0x/contracts/erc20/src/IEtherToken.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../external/ILiquidityProviderSandbox.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinEIP712.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IMultiplexFeature.sol";
import "./MultiplexLiquidityProvider.sol";
import "./MultiplexOtc.sol";
import "./MultiplexRfq.sol";
import "./MultiplexTransformERC20.sol";
import "./MultiplexUniswapV2.sol";
import "./MultiplexUniswapV3.sol";

/// @dev This feature enables efficient batch and multi-hop trades
///      using different liquidity sources.
contract MultiplexFeature is
    IFeature,
    IMultiplexFeature,
    FixinCommon,
    MultiplexLiquidityProvider,
    MultiplexOtc,
    MultiplexRfq,
    MultiplexTransformERC20,
    MultiplexUniswapV2,
    MultiplexUniswapV3
{
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "MultiplexFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(2, 0, 0);
    /// @dev The highest bit of a uint256 value.
    uint256 private constant HIGH_BIT = 2 ** 255;
    /// @dev Mask of the lower 255 bits of a uint256 value.
    uint256 private constant LOWER_255_BITS = HIGH_BIT - 1;

    /// @dev The WETH token contract.
    IEtherToken private immutable WETH;

    constructor(
        address zeroExAddress,
        IEtherToken weth,
        ILiquidityProviderSandbox sandbox,
        address uniswapFactory,
        address sushiswapFactory,
        bytes32 uniswapPairInitCodeHash,
        bytes32 sushiswapPairInitCodeHash
    )
        public
        FixinEIP712(zeroExAddress)
        MultiplexLiquidityProvider(sandbox)
        MultiplexUniswapV2(uniswapFactory, sushiswapFactory, uniswapPairInitCodeHash, sushiswapPairInitCodeHash)
    {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.multiplexBatchSellEthForToken.selector);
        _registerFeatureFunction(this.multiplexBatchSellTokenForEth.selector);
        _registerFeatureFunction(this.multiplexBatchSellTokenForToken.selector);
        _registerFeatureFunction(this._multiplexBatchSell.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellEthForToken.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellTokenForEth.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellTokenForToken.selector);
        _registerFeatureFunction(this._multiplexMultiHopSell.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells attached ETH for `outputToken` using the provided
    ///      calls.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the attached ETH.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellEthForToken(
        IERC20Token outputToken,
        BatchSellSubcall[] memory calls,
        uint256 minBuyAmount
    ) public payable override returns (uint256 boughtAmount) {
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        // WETH is now held by this contract,
        // so `useSelfBalance` is true.
        return
            _multiplexBatchSellPrivate(
                BatchSellParams({
                    inputToken: WETH,
                    outputToken: outputToken,
                    sellAmount: msg.value,
                    calls: calls,
                    useSelfBalance: true,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Sells `sellAmount` of the given `inputToken` for ETH
    ///      using the provided calls.
    /// @param inputToken The token to sell.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexBatchSellTokenForEth(
        IERC20Token inputToken,
        BatchSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        // The outputToken is implicitly WETH. The `recipient`
        // of the WETH is set to  this contract, since we
        // must unwrap the WETH and transfer the resulting ETH.
        boughtAmount = _multiplexBatchSellPrivate(
            BatchSellParams({
                inputToken: inputToken,
                outputToken: WETH,
                sellAmount: sellAmount,
                calls: calls,
                useSelfBalance: false,
                recipient: address(this),
                payer: msg.sender
            }),
            minBuyAmount
        );
        // Unwrap WETH.
        WETH.withdraw(boughtAmount);
        // Transfer ETH to `msg.sender`.
        _transferEth(msg.sender, boughtAmount);
    }

    /// @dev Sells `sellAmount` of the given `inputToken` for
    ///      `outputToken` using the provided calls.
    /// @param inputToken The token to sell.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of `outputToken`
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellTokenForToken(
        IERC20Token inputToken,
        IERC20Token outputToken,
        BatchSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexBatchSellPrivate(
                BatchSellParams({
                    inputToken: inputToken,
                    outputToken: outputToken,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Executes a batch sell and checks that at least
    ///      `minBuyAmount` of `outputToken` was bought. Internal variant.
    /// @param params Batch sell parameters.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function _multiplexBatchSell(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) public override onlySelf returns (uint256 boughtAmount) {
        return _multiplexBatchSellPrivate(params, minBuyAmount);
    }

    /// @dev Executes a batch sell and checks that at least
    ///      `minBuyAmount` of `outputToken` was bought.
    /// @param params Batch sell parameters.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function _multiplexBatchSellPrivate(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        // Cache the recipient's initial balance of the output token.
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        // Execute the batch sell.
        BatchSellState memory state = _executeBatchSell(params);
        // Compute the change in balance of the output token.
        uint256 balanceDelta = params.outputToken.balanceOf(params.recipient).safeSub(balanceBefore);
        // Use the minimum of the balanceDelta and the returned bought
        // amount in case of weird tokens and whatnot.
        boughtAmount = LibSafeMathV06.min256(balanceDelta, state.boughtAmount);
        // Enforce `minBuyAmount`.
        require(boughtAmount >= minBuyAmount, "MultiplexFeature::_multiplexBatchSell/UNDERBOUGHT");
    }

    /// @dev Sells attached ETH via the given sequence of tokens
    ///      and calls. `tokens[0]` must be WETH.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellEthForToken(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 minBuyAmount
    ) public payable override returns (uint256 boughtAmount) {
        // First token must be WETH.
        require(tokens[0] == address(WETH), "MultiplexFeature::multiplexMultiHopSellEthForToken/NOT_WETH");
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        // WETH is now held by this contract,
        // so `useSelfBalance` is true.
        return
            _multiplexMultiHopSellPrivate(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: msg.value,
                    calls: calls,
                    useSelfBalance: true,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      for ETH via the given sequence of tokens and calls.
    ///      The last token in `tokens` must be WETH.
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexMultiHopSellTokenForEth(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        // Last token must be WETH.
        require(
            tokens[tokens.length - 1] == address(WETH),
            "MultiplexFeature::multiplexMultiHopSellTokenForEth/NOT_WETH"
        );
        // The `recipient of the WETH is set to  this contract, since
        // we must unwrap the WETH and transfer the resulting ETH.
        boughtAmount = _multiplexMultiHopSellPrivate(
            MultiHopSellParams({
                tokens: tokens,
                sellAmount: sellAmount,
                calls: calls,
                useSelfBalance: false,
                recipient: address(this),
                payer: msg.sender
            }),
            minBuyAmount
        );
        // Unwrap WETH.
        WETH.withdraw(boughtAmount);
        // Transfer ETH to `msg.sender`.
        _transferEth(msg.sender, boughtAmount);
    }

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      via the given sequence of tokens and calls.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellTokenForToken(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexMultiHopSellPrivate(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Executes a multi-hop sell. Internal variant.
    /// @param params Multi-hop sell parameters.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function _multiplexMultiHopSell(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) public override onlySelf returns (uint256 boughtAmount) {
        return _multiplexMultiHopSellPrivate(params, minBuyAmount);
    }

    /// @dev Executes a multi-hop sell and checks that at least
    ///      `minBuyAmount` of output tokens were bought.
    /// @param params Multi-hop sell parameters.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function _multiplexMultiHopSellPrivate(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        // There should be one call/hop between every two tokens
        // in the path.
        // tokens[0]––calls[0]––>tokens[1]––...––calls[n-1]––>tokens[n]
        require(
            params.tokens.length == params.calls.length + 1,
            "MultiplexFeature::_multiplexMultiHopSell/MISMATCHED_ARRAY_LENGTHS"
        );
        // The output token is the last token in the path.
        IERC20Token outputToken = IERC20Token(params.tokens[params.tokens.length - 1]);
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = outputToken.balanceOf(params.recipient);
        // Execute the multi-hop sell.
        MultiHopSellState memory state = _executeMultiHopSell(params);
        // Compute the change in balance of the output token.
        uint256 balanceDelta = outputToken.balanceOf(params.recipient).safeSub(balanceBefore);
        // Use the minimum of the balanceDelta and the returned bought
        // amount in case of weird tokens and whatnot.
        boughtAmount = LibSafeMathV06.min256(balanceDelta, state.outputTokenAmount);
        // Enforce `minBuyAmount`.
        require(boughtAmount >= minBuyAmount, "MultiplexFeature::_multiplexMultiHopSell/UNDERBOUGHT");
    }

    /// @dev Iterates through the constituent calls of a batch
    ///      sell and executes each one, until the full amount
    //       has been sold.
    /// @param params Batch sell parameters.
    /// @return state A struct containing the amounts of `inputToken`
    ///         sold and `outputToken` bought.
    function _executeBatchSell(BatchSellParams memory params) private returns (BatchSellState memory state) {
        // Iterate through the calls and execute each one
        // until the full amount has been sold.
        for (uint256 i = 0; i != params.calls.length; i++) {
            // Check if we've hit our target.
            if (state.soldAmount >= params.sellAmount) {
                break;
            }
            BatchSellSubcall memory subcall = params.calls[i];
            // Compute the input token amount.
            uint256 inputTokenAmount = _normalizeSellAmount(subcall.sellAmount, params.sellAmount, state.soldAmount);
            if (subcall.id == MultiplexSubcall.RFQ) {
                _batchSellRfqOrder(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.OTC) {
                _batchSellOtcOrder(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.UniswapV2) {
                _batchSellUniswapV2(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.UniswapV3) {
                _batchSellUniswapV3(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                _batchSellLiquidityProvider(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.TransformERC20) {
                _batchSellTransformERC20(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.MultiHopSell) {
                _nestedMultiHopSell(state, params, subcall.data, inputTokenAmount);
            } else {
                revert("MultiplexFeature::_executeBatchSell/INVALID_SUBCALL");
            }
        }
        require(state.soldAmount == params.sellAmount, "MultiplexFeature::_executeBatchSell/INCORRECT_AMOUNT_SOLD");
    }

    // This function executes a sequence of fills "hopping" through the
    // path of tokens given by `params.tokens`.
    function _executeMultiHopSell(MultiHopSellParams memory params) private returns (MultiHopSellState memory state) {
        // This variable is used for the input and output amounts of
        // each hop. After the final hop, this will contain the output
        // amount of the multi-hop fill.
        state.outputTokenAmount = params.sellAmount;
        // The first call may expect the input tokens to be held by
        // `payer`, `address(this)`, or some other address.
        // Compute the expected address and transfer the input tokens
        // there if necessary.
        state.from = _computeHopTarget(params, 0);
        // If the input tokens are currently held by `payer` but
        // the first hop expects them elsewhere, perform a `transferFrom`.
        if (!params.useSelfBalance && state.from != params.payer) {
            _transferERC20TokensFrom(IERC20Token(params.tokens[0]), params.payer, state.from, params.sellAmount);
        }
        // If the input tokens are currently held by `address(this)` but
        // the first hop expects them elsewhere, perform a `transfer`.
        if (params.useSelfBalance && state.from != address(this)) {
            _transferERC20Tokens(IERC20Token(params.tokens[0]), state.from, params.sellAmount);
        }
        // Iterate through the calls and execute each one.
        for (state.hopIndex = 0; state.hopIndex != params.calls.length; state.hopIndex++) {
            MultiHopSellSubcall memory subcall = params.calls[state.hopIndex];
            // Compute the recipient of the tokens that will be
            // bought by the current hop.
            state.to = _computeHopTarget(params, state.hopIndex + 1);

            if (subcall.id == MultiplexSubcall.UniswapV2) {
                _multiHopSellUniswapV2(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.UniswapV3) {
                _multiHopSellUniswapV3(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                _multiHopSellLiquidityProvider(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.BatchSell) {
                _nestedBatchSell(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.OTC) {
                _multiHopSellOtcOrder(state, params, subcall.data);
            } else {
                revert("MultiplexFeature::_executeMultiHopSell/INVALID_SUBCALL");
            }
            // The recipient of the current hop will be the source
            // of tokens for the next hop.
            state.from = state.to;
        }
    }

    function _nestedMultiHopSell(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory data,
        uint256 sellAmount
    ) private {
        MultiHopSellParams memory multiHopParams;
        // Decode the tokens and calls for the nested
        // multi-hop sell.
        (multiHopParams.tokens, multiHopParams.calls) = abi.decode(data, (address[], MultiHopSellSubcall[]));
        multiHopParams.sellAmount = sellAmount;
        // If the batch sell is using input tokens held by
        // `address(this)`, then so should the nested
        // multi-hop sell.
        multiHopParams.useSelfBalance = params.useSelfBalance;
        // Likewise, the recipient of the multi-hop sell is
        // equal to the recipient of its containing batch sell.
        multiHopParams.recipient = params.recipient;
        // The payer is the same too.
        multiHopParams.payer = params.payer;
        // Execute the nested multi-hop sell.
        uint256 outputTokenAmount = _executeMultiHopSell(multiHopParams).outputTokenAmount;
        // Increment the sold and bought amounts.
        state.soldAmount = state.soldAmount.safeAdd(sellAmount);
        state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
    }

    function _nestedBatchSell(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory data
    ) private {
        BatchSellParams memory batchSellParams;
        // Decode the calls for the nested batch sell.
        batchSellParams.calls = abi.decode(data, (BatchSellSubcall[]));
        // The input and output tokens of the batch
        // sell are the current and next tokens in
        // `params.tokens`, respectively.
        batchSellParams.inputToken = IERC20Token(params.tokens[state.hopIndex]);
        batchSellParams.outputToken = IERC20Token(params.tokens[state.hopIndex + 1]);
        // The `sellAmount` for the batch sell is the
        // `outputTokenAmount` from the previous hop.
        batchSellParams.sellAmount = state.outputTokenAmount;
        // If the nested batch sell is the first hop
        // and `useSelfBalance` for the containing multi-
        // hop sell is false, the nested batch sell should
        // pull tokens from `payer` (so  `batchSellParams.useSelfBalance`
        // should be false). Otherwise `batchSellParams.useSelfBalance`
        // should be true.
        batchSellParams.useSelfBalance = state.hopIndex > 0 || params.useSelfBalance;
        // `state.to` has been populated with the address
        // that should receive the output tokens of the
        // batch sell.
        batchSellParams.recipient = state.to;
        // payer shound be the same too.
        batchSellParams.payer = params.payer;
        // Execute the nested batch sell.
        state.outputTokenAmount = _executeBatchSell(batchSellParams).boughtAmount;
    }

    // This function computes the "target" address of hop index `i` within
    // a multi-hop sell.
    // If `i == 0`, the target is the address which should hold the input
    // tokens prior to executing `calls[0]`. Otherwise, it is the address
    // that should receive `tokens[i]` upon executing `calls[i-1]`.
    function _computeHopTarget(MultiHopSellParams memory params, uint256 i) private view returns (address target) {
        if (i == params.calls.length) {
            // The last call should send the output tokens to the
            // multi-hop sell recipient.
            target = params.recipient;
        } else {
            MultiHopSellSubcall memory subcall = params.calls[i];
            if (subcall.id == MultiplexSubcall.UniswapV2) {
                // UniswapV2 (and Sushiswap) allow tokens to be
                // transferred into the pair contract before `swap`
                // is called, so we compute the pair contract's address.
                (address[] memory tokens, bool isSushi) = abi.decode(subcall.data, (address[], bool));
                target = _computeUniswapPairAddress(tokens[0], tokens[1], isSushi);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                // Similar to UniswapV2, LiquidityProvider contracts
                // allow tokens to be transferred in before the swap
                // is executed, so we the target is the address encoded
                // in the subcall data.
                (target, ) = abi.decode(subcall.data, (address, bytes));
            } else if (
                subcall.id == MultiplexSubcall.UniswapV3 ||
                subcall.id == MultiplexSubcall.BatchSell ||
                subcall.id == MultiplexSubcall.OTC
            ) {
                // UniswapV3 uses a callback to pull in the tokens being
                // sold to it. The callback implemented in `UniswapV3Feature`
                // can either:
                // - call `transferFrom` to move tokens from `payer` to the
                //   UniswapV3 pool, or
                // - call `transfer` to move tokens from `address(this)` to the
                //   UniswapV3 pool.
                // A nested batch sell is similar, in that it can either:
                // - use tokens from `payer`, or
                // - use tokens held by `address(this)`.

                // Suppose UniswapV3/BatchSell is the first call in the multi-hop
                // path. The input tokens are either held by `payer`,
                // or in the case of `multiplexMultiHopSellEthForToken` WETH is
                // held by `address(this)`. The target is set accordingly.

                // If this is _not_ the first call in the multi-hop path, we
                // are dealing with an "intermediate" token in the multi-hop path,
                // which `payer` may not have an allowance set for. Thus
                // target must be set to `address(this)` for `i > 0`.
                if (i == 0 && !params.useSelfBalance) {
                    target = params.payer;
                } else {
                    target = address(this);
                }
            } else {
                revert("MultiplexFeature::_computeHopTarget/INVALID_SUBCALL");
            }
        }
        require(target != address(0), "MultiplexFeature::_computeHopTarget/TARGET_IS_NULL");
    }

    // If `rawAmount` encodes a proportion of `totalSellAmount`, this function
    // converts it to an absolute quantity. Caps the normalized amount to
    // the remaining sell amount (`totalSellAmount - soldAmount`).
    function _normalizeSellAmount(
        uint256 rawAmount,
        uint256 totalSellAmount,
        uint256 soldAmount
    ) private pure returns (uint256 normalized) {
        if ((rawAmount & HIGH_BIT) == HIGH_BIT) {
            // If the high bit of `rawAmount` is set then the lower 255 bits
            // specify a fraction of `totalSellAmount`.
            return
                LibSafeMathV06.min256(
                    (totalSellAmount * LibSafeMathV06.min256(rawAmount & LOWER_255_BITS, 1e18)) / 1e18,
                    totalSellAmount.safeSub(soldAmount)
                );
        } else {
            return LibSafeMathV06.min256(rawAmount, totalSellAmount.safeSub(soldAmount));
        }
    }
}
