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
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../IBridgeAdapter.sol";

/*
    UniswapV2
*/
interface IGmxRouter {
    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by
    /// the path. The first element of path is the input token, the last is the output token, and any intermediate
    /// elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param _path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses
    /// must exist and have liquidity.
    /// @param _amountIn The amount of input tokens to send.
    /// @param _minOut The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param _receiver Recipient of the output tokens.
    function swap(address[] calldata _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

contract MixinGMX {
    using LibERC20TokenV06 for IERC20Token;
    using LibSafeMathV06 for uint256;

    function _tradeGMX(
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) public returns (uint256 boughtAmount) {
        address _router;
        address reader;
        address vault;
        address[] memory _path;
        IGmxRouter router;
        IERC20Token[] memory path;

        {
            //decode the bridge data
            (_router, reader, vault, _path) = abi.decode(bridgeData, (address, address, address, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinGMX/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinGMX/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        //connect to the GMX router
        router = IGmxRouter(_router);

        // Grant the GMX router an allowance to sell the first token.
        path[0].approveIfBelow(address(router), sellAmount);

        //track the balance to know how much we bought
        uint256 beforeBalance = buyToken.balanceOf(address(this));
        router.swap(
            // Convert to `buyToken` along this path.
            _path,
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            0,
            // Recipient is `this`.
            address(this)
        );

        //calculate the difference in balance from preswap->postswap to find how many tokens out
        boughtAmount = buyToken.balanceOf(address(this)).safeSub(beforeBalance);

        return boughtAmount;
    }
}
