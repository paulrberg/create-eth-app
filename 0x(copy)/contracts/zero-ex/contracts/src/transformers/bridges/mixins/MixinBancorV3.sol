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
import "0x/contracts/erc20/src/IEtherToken.sol";

/*
    BancorV3
*/
interface IBancorV3 {
    /**
     * @dev performs a trade by providing the source amount and returns the target amount and the associated fee
     *
     * requirements:
     *
     * - the caller must be the network contract
     */
    function tradeBySourceAmount(
        address sourceToken,
        address targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable returns (uint256 amount);
}

contract MixinBancorV3 {
    using LibERC20TokenV06 for IERC20Token;

    IERC20Token public constant BANCORV3_ETH_ADDRESS = IERC20Token(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IEtherToken private immutable WETH;

    constructor(IEtherToken weth) public {
        WETH = weth;
    }

    function _tradeBancorV3(
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 amountOut) {
        IBancorV3 router;
        IERC20Token[] memory path;
        address[] memory _path;
        uint256 payableAmount = 0;

        {
            (router, _path) = abi.decode(bridgeData, (IBancorV3, address[]));
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(path.length >= 2, "MixinBancorV3/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == buyToken, "MixinBancorV3/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        //swap WETH->ETH as Bancor only deals in ETH
        if (_path[0] == address(WETH)) {
            //withdraw the sell amount of WETH for ETH
            WETH.withdraw(sellAmount);
            payableAmount = sellAmount;
            // set _path[0] to the ETH address if WETH is our buy token
            _path[0] = address(BANCORV3_ETH_ADDRESS);
        } else {
            // Grant the BancorV3 router an allowance to sell the first token.
            path[0].approveIfBelow(address(router), sellAmount);
        }

        // if we are buying WETH we need to swap to ETH and deposit into WETH after the swap
        if (_path[1] == address(WETH)) {
            _path[1] = address(BANCORV3_ETH_ADDRESS);
        }

        uint256 amountOut = router.tradeBySourceAmount{value: payableAmount}(
            _path[0],
            _path[1],
            // Sell all tokens we hold.
            sellAmount,
            // Minimum buy amount.
            1,
            //deadline
            block.timestamp + 1,
            // address of the mixin
            address(this)
        );

        // if we want to return WETH deposit the ETH amount we sold
        if (buyToken == WETH) {
            WETH.deposit{value: amountOut}();
        }

        return amountOut;
    }
}
