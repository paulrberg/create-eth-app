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

interface IPlatypusRouter {
    function swapTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut, uint256 haircut);
}

contract MixinPlatypus {
    using LibERC20TokenV06 for IERC20Token;
    using LibSafeMathV06 for uint256;

    function _tradePlatypus(
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) public returns (uint256 boughtAmount) {
        IPlatypusRouter router;
        address _router;
        address[] memory _pool;
        IERC20Token[] memory path;
        address[] memory _path;

        {
            (_router, _pool, _path) = abi.decode(bridgeData, (address, address[], address[]));

            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        //connect to the ptp router
        router = IPlatypusRouter(_router);

        require(path.length >= 2, "MixinPlatypus/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinPlatypus/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");
        // Grant the Platypus router an allowance to sell the first token.
        path[0].approveIfBelow(address(router), sellAmount);

        //keep track of the previous balance to confirm amount out
        uint256 beforeBalance = buyToken.balanceOf(address(this));

        router.swapTokensForTokens(
            // Convert to `buyToken` along this path.
            _path,
            // pool to swap on
            _pool,
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            0,
            // Recipient is `this`.
            address(this),
            block.timestamp + 1
        );
        //calculate the buy amount from the tokens we recieved
        boughtAmount = buyToken.balanceOf(address(this)).safeSub(beforeBalance);
        return boughtAmount;
    }
}
