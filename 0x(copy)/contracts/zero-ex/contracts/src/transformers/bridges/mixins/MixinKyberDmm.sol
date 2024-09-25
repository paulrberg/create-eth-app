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

  Copyright 2021 ZeroEx Intl.

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

import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/erc20/src/IERC20Token.sol";
import "../IBridgeAdapter.sol";

/*
    KyberDmm Router
*/
interface IKyberDmmRouter {
    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by
    /// the path. The first element of path is the input token, the last is the output token, and any intermediate
    /// elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param amountIn The amount of input tokens to send.
    /// @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param pools An array of pool addresses. pools.length must be >= 1.
    /// @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
    /// must exist and have liquidity.
    /// @param to Recipient of the output tokens.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amounts The input token amount and all subsequent output token amounts.
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata pools,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract MixinKyberDmm {
    using LibERC20TokenV06 for IERC20Token;

    function _tradeKyberDmm(
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        address router;
        address[] memory pools;
        address[] memory path;
        (router, pools, path) = abi.decode(bridgeData, (address, address[], address[]));

        require(pools.length >= 1, "MixinKyberDmm/POOLS_LENGTH_MUST_BE_AT_LEAST_ONE");
        require(path.length == pools.length + 1, "MixinKyberDmm/ARRAY_LENGTH_MISMATCH");
        require(
            path[path.length - 1] == address(buyToken),
            "MixinKyberDmm/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN"
        );
        // Grant the KyberDmm router an allowance to sell the first token.
        IERC20Token(path[0]).approveIfBelow(address(router), sellAmount);

        uint256[] memory amounts = IKyberDmmRouter(router).swapExactTokensForTokens(
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            pools,
            // Convert to `buyToken` along this path.
            path,
            // Recipient is `this`.
            address(this),
            // Expires after this block.
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }
}
