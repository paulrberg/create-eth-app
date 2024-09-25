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
import "../IBridgeAdapter.sol";

interface IUniswapExchangeFactory {
    /// @dev Get the exchange for a token.
    /// @param token The token contract.
    function getExchange(IERC20Token token) external view returns (IUniswapExchange exchange);
}

interface IUniswapExchange {
    /// @dev Buys at least `minTokensBought` tokens with ETH and transfer them
    ///      to `recipient`.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @return tokensBought Amount of tokens bought.
    function ethToTokenTransferInput(
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokensBought);

    /// @dev Buys at least `minEthBought` ETH with tokens.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minEthBought The minimum amount of ETH to buy.
    /// @param deadline Time when this order expires.
    /// @return ethBought Amount of tokens bought.
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    ) external returns (uint256 ethBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token
    ///      and transfer them to `recipient`.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @param buyToken The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        IERC20Token buyToken
    ) external returns (uint256 tokensBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param buyToken The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        IERC20Token buyToken
    ) external returns (uint256 tokensBought);
}

contract MixinUniswap {
    using LibERC20TokenV06 for IERC20Token;

    /// @dev Mainnet address of the WETH contract.
    IEtherToken private immutable WETH;

    constructor(IEtherToken weth) public {
        WETH = weth;
    }

    //·solhint-disable-next-line·function-max-lines
    function _tradeUniswap(
        IERC20Token sellToken,
        IERC20Token buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        IUniswapExchangeFactory exchangeFactory = abi.decode(bridgeData, (IUniswapExchangeFactory));

        // Get the exchange for the token pair.
        IUniswapExchange exchange = _getUniswapExchangeForTokenPair(exchangeFactory, sellToken, buyToken);

        // Convert from WETH to a token.
        if (sellToken == WETH) {
            // Unwrap the WETH.
            WETH.withdraw(sellAmount);
            // Buy as much of `buyToken` token with ETH as possible
            boughtAmount = exchange.ethToTokenTransferInput{value: sellAmount}(
                // Minimum buy amount.
                1,
                // Expires after this block.
                block.timestamp,
                // Recipient is `this`.
                address(this)
            );

            // Convert from a token to WETH.
        } else if (buyToken == WETH) {
            // Grant the exchange an allowance.
            sellToken.approveIfBelow(address(exchange), sellAmount);
            // Buy as much ETH with `sellToken` token as possible.
            boughtAmount = exchange.tokenToEthSwapInput(
                // Sell all tokens we hold.
                sellAmount,
                // Minimum buy amount.
                1,
                // Expires after this block.
                block.timestamp
            );
            // Wrap the ETH.
            WETH.deposit{value: boughtAmount}();
            // Convert from one token to another.
        } else {
            // Grant the exchange an allowance.
            sellToken.approveIfBelow(address(exchange), sellAmount);
            // Buy as much `buyToken` token with `sellToken` token
            boughtAmount = exchange.tokenToTokenSwapInput(
                // Sell all tokens we hold.
                sellAmount,
                // Minimum buy amount.
                1,
                // Must buy at least 1 intermediate wei of ETH.
                1,
                // Expires after this block.
                block.timestamp,
                // Convert to `buyToken`.
                buyToken
            );
        }

        return boughtAmount;
    }

    /// @dev Retrieves the uniswap exchange for a given token pair.
    ///      In the case of a WETH-token exchange, this will be the non-WETH token.
    ///      In th ecase of a token-token exchange, this will be the first token.
    /// @param exchangeFactory The exchange factory.
    /// @param sellToken The address of the token we are converting from.
    /// @param buyToken The address of the token we are converting to.
    /// @return exchange The uniswap exchange.
    function _getUniswapExchangeForTokenPair(
        IUniswapExchangeFactory exchangeFactory,
        IERC20Token sellToken,
        IERC20Token buyToken
    ) private view returns (IUniswapExchange exchange) {
        // Whichever isn't WETH is the exchange token.
        exchange = sellToken == WETH ? exchangeFactory.getExchange(buyToken) : exchangeFactory.getExchange(sellToken);
        require(address(exchange) != address(0), "MixinUniswap/NO_EXCHANGE");
    }
}
