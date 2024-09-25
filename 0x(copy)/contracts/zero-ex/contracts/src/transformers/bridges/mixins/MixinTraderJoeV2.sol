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

import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/erc20/src/IERC20Token.sol";
import "../IBridgeAdapter.sol";

interface ILBRouter {
    /**
     * @dev This enum represents the version of the pair requested
     * - V1: Joe V1 pair
     * - V2: LB pair V2. Also called legacyPair
     * - V2_1: LB pair V2.1 (current version)
     */
    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20Token[] tokenPath;
    }

    /**
     * @notice Swaps exact tokens for tokens while performing safety checks
     * @param amountIn The amount of token to send
     * @param amountOutMin The min amount of token to receive
     * @param path The path of the swap
     * @param to The address of the recipient
     * @param deadline The deadline of the tx
     * @return amountOut Output amount of the swap
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

contract MixinTraderJoeV2 {
    using LibERC20TokenV06 for IERC20Token;

    function _tradeTraderJoeV2(
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        ILBRouter router;
        IERC20Token[] memory tokenPath;
        uint256[] memory pairBinSteps;
        ILBRouter.Version[] memory versions;
        {
            address[] memory _tokenPath;
            (router, _tokenPath, pairBinSteps, versions) = abi.decode(
                bridgeData,
                (ILBRouter, address[], uint256[], ILBRouter.Version[])
            );
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                tokenPath := _tokenPath
            }
        }

        require(tokenPath.length >= 2, "MixinTraderJoeV2/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(
            tokenPath.length == pairBinSteps.length + 1,
            "MixinTraderJoeV2/PAIR_BIN_STEPS_LENGTH_MUST_BE_ONE_LESS_THAN_TOKEN_PATH_LENGTH"
        );
        require(
            versions.length == pairBinSteps.length,
            "MixinTraderJoeV2/VERSIONS_LENGTH_MUST_BE_EQUAL_TO_PAIR_BIN_STEPS_LENGTH"
        );
        require(
            tokenPath[tokenPath.length - 1] == buyToken,
            "MixinTraderJoeV2/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN"
        );
        // Grant the Trader Joe V2 router an allowance to sell the first token.
        tokenPath[0].approveIfBelow(address(router), sellAmount);

        ILBRouter.Path memory path = ILBRouter.Path({
            pairBinSteps: pairBinSteps,
            versions: versions,
            tokenPath: tokenPath
        });
        boughtAmount = router.swapExactTokensForTokens(sellAmount, 1, path, address(this), block.timestamp);
    }
}
