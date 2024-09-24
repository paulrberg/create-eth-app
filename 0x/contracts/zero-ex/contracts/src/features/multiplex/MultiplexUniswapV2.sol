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
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/IUniswapV2Pair.sol";
import "../interfaces/IMultiplexFeature.sol";

abstract contract MultiplexUniswapV2 is FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;

    // address of the UniswapV2Factory contract.
    address private immutable UNISWAP_FACTORY;
    // address of the (Sushiswap) UniswapV2Factory contract.
    address private immutable SUSHISWAP_FACTORY;
    // Init code hash of the UniswapV2Pair contract.
    bytes32 private immutable UNISWAP_PAIR_INIT_CODE_HASH;
    // Init code hash of the (Sushiswap) UniswapV2Pair contract.
    bytes32 private immutable SUSHISWAP_PAIR_INIT_CODE_HASH;

    constructor(
        address uniswapFactory,
        address sushiswapFactory,
        bytes32 uniswapPairInitCodeHash,
        bytes32 sushiswapPairInitCodeHash
    ) internal {
        UNISWAP_FACTORY = uniswapFactory;
        SUSHISWAP_FACTORY = sushiswapFactory;
        UNISWAP_PAIR_INIT_CODE_HASH = uniswapPairInitCodeHash;
        SUSHISWAP_PAIR_INIT_CODE_HASH = sushiswapPairInitCodeHash;
    }

    // A payable external function that we can delegatecall to
    // swallow reverts and roll back the input token transfer.
    function _batchSellUniswapV2External(
        IMultiplexFeature.BatchSellParams calldata params,
        bytes calldata wrappedCallData,
        uint256 sellAmount
    ) external payable returns (uint256 boughtAmount) {
        // Revert is not a delegatecall.
        require(
            address(this) != _implementation,
            "MultiplexLiquidityProvider::_batchSellUniswapV2External/ONLY_DELEGATECALL"
        );

        (address[] memory tokens, bool isSushi) = abi.decode(wrappedCallData, (address[], bool));
        // Validate tokens
        require(
            tokens.length >= 2 &&
                tokens[0] == address(params.inputToken) &&
                tokens[tokens.length - 1] == address(params.outputToken),
            "MultiplexUniswapV2::_batchSellUniswapV2/INVALID_TOKENS"
        );
        // Compute the address of the first Uniswap pair
        // contract that will execute a swap.
        address firstPairAddress = _computeUniswapPairAddress(tokens[0], tokens[1], isSushi);
        // `_sellToUniswapV2` assumes the input tokens have been
        // transferred into the pair contract before it is called,
        // so we transfer the tokens in now (either from `msg.sender`
        // or using the Exchange Proxy's balance).
        if (params.useSelfBalance) {
            _transferERC20Tokens(IERC20Token(tokens[0]), firstPairAddress, sellAmount);
        } else {
            _transferERC20TokensFrom(IERC20Token(tokens[0]), params.payer, firstPairAddress, sellAmount);
        }
        // Execute the Uniswap/Sushiswap trade.
        return _sellToUniswapV2(tokens, sellAmount, isSushi, firstPairAddress, params.recipient);
    }

    function _batchSellUniswapV2(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Swallow reverts
        (bool success, bytes memory resultData) = _implementation.delegatecall(
            abi.encodeWithSelector(this._batchSellUniswapV2External.selector, params, wrappedCallData, sellAmount)
        );
        if (success) {
            // Decode the output token amount on success.
            uint256 boughtAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(boughtAmount);
        }
    }

    function _multiHopSellUniswapV2(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        (address[] memory tokens, bool isSushi) = abi.decode(wrappedCallData, (address[], bool));
        // Validate the tokens
        require(
            tokens.length >= 2 &&
                tokens[0] == params.tokens[state.hopIndex] &&
                tokens[tokens.length - 1] == params.tokens[state.hopIndex + 1],
            "MultiplexUniswapV2::_multiHopSellUniswapV2/INVALID_TOKENS"
        );
        // Execute the Uniswap/Sushiswap trade.
        state.outputTokenAmount = _sellToUniswapV2(tokens, state.outputTokenAmount, isSushi, state.from, state.to);
    }

    function _sellToUniswapV2(
        address[] memory tokens,
        uint256 sellAmount,
        bool isSushi,
        address pairAddress,
        address recipient
    ) private returns (uint256 outputTokenAmount) {
        // Iterate through `tokens` perform a swap against the Uniswap
        // pair contract for each `(tokens[i], tokens[i+1])`.
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            (address inputToken, address outputToken) = (tokens[i], tokens[i + 1]);
            // Compute the output token amount
            outputTokenAmount = _computeUniswapOutputAmount(pairAddress, inputToken, outputToken, sellAmount);
            (uint256 amount0Out, uint256 amount1Out) = inputToken < outputToken
                ? (uint256(0), outputTokenAmount)
                : (outputTokenAmount, uint256(0));
            // The Uniswap pair contract will transfer the output tokens to
            // the next pair contract if there is one, otherwise transfer to
            // `recipient`.
            address to = i < tokens.length - 2
                ? _computeUniswapPairAddress(outputToken, tokens[i + 2], isSushi)
                : recipient;
            // Execute the swap.
            IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, to, new bytes(0));
            // To avoid recomputing the pair address of the next pair, store
            // `to` in `pairAddress`.
            pairAddress = to;
            // The outputTokenAmount
            sellAmount = outputTokenAmount;
        }
    }

    // Computes the Uniswap/Sushiswap pair contract address for the
    // given tokens.
    function _computeUniswapPairAddress(
        address tokenA,
        address tokenB,
        bool isSushi
    ) internal view returns (address pairAddress) {
        // Tokens are lexicographically sorted in the Uniswap contract.
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (isSushi) {
            // Use the Sushiswap factory address and codehash
            return
                address(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                SUSHISWAP_FACTORY,
                                keccak256(abi.encodePacked(token0, token1)),
                                SUSHISWAP_PAIR_INIT_CODE_HASH
                            )
                        )
                    )
                );
        } else {
            // Use the Uniswap factory address and codehash
            return
                address(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                UNISWAP_FACTORY,
                                keccak256(abi.encodePacked(token0, token1)),
                                UNISWAP_PAIR_INIT_CODE_HASH
                            )
                        )
                    )
                );
        }
    }

    // Computes the the amount of output token that would be bought
    // from Uniswap/Sushiswap given the input amount.
    function _computeUniswapOutputAmount(
        address pairAddress,
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) private view returns (uint256 outputAmount) {
        // Input amount should be non-zero.
        require(inputAmount > 0, "MultiplexUniswapV2::_computeUniswapOutputAmount/INSUFFICIENT_INPUT_AMOUNT");
        // Query the reserves of the pair contract.
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        // Reserves must be non-zero.
        require(reserve0 > 0 && reserve1 > 0, "MultiplexUniswapV2::_computeUniswapOutputAmount/INSUFFICIENT_LIQUIDITY");
        // Tokens are lexicographically sorted in the Uniswap contract.
        (uint256 inputReserve, uint256 outputReserve) = inputToken < outputToken
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        // Compute the output amount.
        uint256 inputAmountWithFee = inputAmount.safeMul(997);
        uint256 numerator = inputAmountWithFee.safeMul(outputReserve);
        uint256 denominator = inputReserve.safeMul(1000).safeAdd(inputAmountWithFee);
        return numerator / denominator;
    }
}
