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
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../external/ILiquidityProviderSandbox.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/ILiquidityProvider.sol";
import "../interfaces/IMultiplexFeature.sol";

abstract contract MultiplexLiquidityProvider is FixinCommon, FixinTokenSpender {
    using LibERC20TokenV06 for IERC20Token;
    using LibSafeMathV06 for uint256;

    // Same event fired by LiquidityProviderFeature
    event LiquidityProviderSwap(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        address provider,
        address recipient
    );

    /// @dev The sandbox contract address.
    ILiquidityProviderSandbox private immutable SANDBOX;

    constructor(ILiquidityProviderSandbox sandbox) internal {
        SANDBOX = sandbox;
    }

    // A payable external function that we can delegatecall to
    // swallow reverts and roll back the input token transfer.
    function _batchSellLiquidityProviderExternal(
        IMultiplexFeature.BatchSellParams calldata params,
        bytes calldata wrappedCallData,
        uint256 sellAmount
    ) external payable returns (uint256 boughtAmount) {
        // Revert if not a delegatecall.
        require(
            address(this) != _implementation,
            "MultiplexLiquidityProvider::_batchSellLiquidityProviderExternal/ONLY_DELEGATECALL"
        );

        // Decode the provider address and auxiliary data.
        (address provider, bytes memory auxiliaryData) = abi.decode(wrappedCallData, (address, bytes));

        if (params.useSelfBalance) {
            // If `useSelfBalance` is true, use the input tokens
            // held by `address(this)`.
            _transferERC20Tokens(params.inputToken, provider, sellAmount);
        } else {
            // Otherwise, transfer the input tokens from `msg.sender`.
            _transferERC20TokensFrom(params.inputToken, params.payer, provider, sellAmount);
        }
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        // Execute the swap.
        SANDBOX.executeSellTokenForToken(
            ILiquidityProvider(provider),
            params.inputToken,
            params.outputToken,
            params.recipient,
            0,
            auxiliaryData
        );
        // Compute amount of output token received by the
        // recipient.
        boughtAmount = params.outputToken.balanceOf(params.recipient).safeSub(balanceBefore);

        emit LiquidityProviderSwap(
            address(params.inputToken),
            address(params.outputToken),
            sellAmount,
            boughtAmount,
            provider,
            params.recipient
        );
    }

    function _batchSellLiquidityProvider(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Swallow reverts
        (bool success, bytes memory resultData) = _implementation.delegatecall(
            abi.encodeWithSelector(
                this._batchSellLiquidityProviderExternal.selector,
                params,
                wrappedCallData,
                sellAmount
            )
        );
        if (success) {
            // Decode the output token amount on success.
            uint256 boughtAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(boughtAmount);
        }
    }

    // This function is called after tokens have already been transferred
    // into the liquidity provider contract (in the previous hop).
    function _multiHopSellLiquidityProvider(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        IERC20Token inputToken = IERC20Token(params.tokens[state.hopIndex]);
        IERC20Token outputToken = IERC20Token(params.tokens[state.hopIndex + 1]);
        // Decode the provider address and auxiliary data.
        (address provider, bytes memory auxiliaryData) = abi.decode(wrappedCallData, (address, bytes));
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = outputToken.balanceOf(state.to);
        // Execute the swap.
        SANDBOX.executeSellTokenForToken(
            ILiquidityProvider(provider),
            inputToken,
            outputToken,
            state.to,
            0,
            auxiliaryData
        );
        // The previous `ouputTokenAmount` was effectively the
        // input amount for this call. Cache the value before
        // overwriting it with the new output token amount so
        // that both the input and ouput amounts can be in the
        // `LiquidityProviderSwap` event.
        uint256 sellAmount = state.outputTokenAmount;
        // Compute amount of output token received by the
        // recipient.
        state.outputTokenAmount = outputToken.balanceOf(state.to).safeSub(balanceBefore);

        emit LiquidityProviderSwap(
            address(inputToken),
            address(outputToken),
            sellAmount,
            state.outputTokenAmount,
            provider,
            state.to
        );
    }
}
