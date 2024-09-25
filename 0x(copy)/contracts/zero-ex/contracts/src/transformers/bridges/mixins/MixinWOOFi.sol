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

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/erc20/src/IERC20Token.sol";
import "0x/contracts/erc20/src/IEtherToken.sol";
import "../IBridgeAdapter.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";

/// @dev WooFI pool interface.
interface IWooPP {
    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be 0)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external payable returns (uint256 realToAmount);
}

contract MixinWOOFi {
    using LibERC20TokenV06 for IERC20Token;
    using LibERC20TokenV06 for IEtherToken;
    using LibSafeMathV06 for uint256;

    // solhint-disable-next-line const-name-snakecase
    address constant rebateAddress = 0xBfdcBB4C05843163F491C24f9c0019c510786304;

    function _tradeWOOFi(
        IERC20Token sellToken,
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) public returns (uint256 boughtAmount) {
        IWooPP _router = abi.decode(bridgeData, (IWooPP));
        uint256 beforeBalance = buyToken.balanceOf(address(this));

        sellToken.approveIfBelow(address(_router), sellAmount);

        boughtAmount = _router.swap(address(sellToken), address(buyToken), sellAmount, 0, address(this), rebateAddress);
    }
}
