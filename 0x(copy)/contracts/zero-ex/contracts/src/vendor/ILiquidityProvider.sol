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

import "0x/contracts/erc20/src/IERC20Token.sol";

interface ILiquidityProvider {
    /// @dev An optional event an LP can emit for each fill against a source.
    /// @param inputToken The input token.
    /// @param outputToken The output token.
    /// @param inputTokenAmount How much input token was sold.
    /// @param outputTokenAmount How much output token was bought.
    /// @param sourceId A bytes32 encoded ascii source ID. E.g., `bytes32('Curve')`/
    /// @param sourceAddress An optional address associated with the source (e.g, a curve pool).
    /// @param sourceId A bytes32 encoded ascii source ID. E.g., `bytes32('Curve')`/
    /// @param sourceAddress An optional address associated with the source (e.g, a curve pool).
    /// @param sender The caller of the LP.
    /// @param recipient The recipient of the output tokens.
    event LiquidityProviderFill(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        bytes32 sourceId,
        address sourceAddress,
        address sender,
        address recipient
    );

    /// @dev Trades `inputToken` for `outputToken`. The amount of `inputToken`
    ///      to sell must be transferred to the contract prior to calling this
    ///      function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellTokenForToken(
        IERC20Token inputToken,
        IERC20Token outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external returns (uint256 boughtAmount);

    /// @dev Trades ETH for token. ETH must either be attached to this function
    ///      call or sent to the contract prior to calling this function to
    ///      trigger the trade.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellEthForToken(
        IERC20Token outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable returns (uint256 boughtAmount);

    /// @dev Trades token for ETH. The token must be sent to the contract prior
    ///      to calling this function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of ETH bought.
    function sellTokenForEth(
        IERC20Token inputToken,
        address payable recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external returns (uint256 boughtAmount);

    /// @dev Quotes the amount of `outputToken` that would be obtained by
    ///      selling `sellAmount` of `inputToken`.
    /// @param inputToken Address of the taker token (what to sell). Use
    ///        the wETH address if selling ETH.
    /// @param outputToken Address of the maker token (what to buy). Use
    ///        the wETH address if buying ETH.
    /// @param sellAmount Amount of `inputToken` to sell.
    /// @return outputTokenAmount Amount of `outputToken` that would be obtained.
    function getSellQuote(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 sellAmount
    ) external view returns (uint256 outputTokenAmount);
}
