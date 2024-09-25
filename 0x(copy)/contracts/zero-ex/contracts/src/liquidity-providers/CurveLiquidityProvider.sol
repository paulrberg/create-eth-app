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

import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/erc20/src/IERC20Token.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../transformers/LibERC20Transformer.sol";
import "../vendor/ILiquidityProvider.sol";

contract CurveLiquidityProvider is ILiquidityProvider {
    using LibERC20TokenV06 for IERC20Token;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    struct CurveData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    /// @dev This contract must be payable because takers can transfer funds
    ///      in prior to calling the swap function.
    receive() external payable {}

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
    ) external override returns (uint256 boughtAmount) {
        require(
            !LibERC20Transformer.isTokenETH(inputToken) && !LibERC20Transformer.isTokenETH(outputToken),
            "CurveLiquidityProvider/INVALID_ARGS"
        );
        boughtAmount = _executeSwap(
            inputToken,
            outputToken,
            minBuyAmount,
            abi.decode(auxiliaryData, (CurveData)),
            recipient
        );
        // Every pool contract currently checks this but why not.
        require(boughtAmount >= minBuyAmount, "CurveLiquidityProvider/UNDERBOUGHT");
        outputToken.compatTransfer(recipient, boughtAmount);
    }

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
    ) external payable override returns (uint256 boughtAmount) {
        require(!LibERC20Transformer.isTokenETH(outputToken), "CurveLiquidityProvider/INVALID_ARGS");
        boughtAmount = _executeSwap(
            LibERC20Transformer.ETH_TOKEN,
            outputToken,
            minBuyAmount,
            abi.decode(auxiliaryData, (CurveData)),
            recipient
        );
        // Every pool contract currently checks this but why not.
        require(boughtAmount >= minBuyAmount, "CurveLiquidityProvider/UNDERBOUGHT");
        outputToken.compatTransfer(recipient, boughtAmount);
    }

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
    ) external override returns (uint256 boughtAmount) {
        require(!LibERC20Transformer.isTokenETH(inputToken), "CurveLiquidityProvider/INVALID_ARGS");
        boughtAmount = _executeSwap(
            inputToken,
            LibERC20Transformer.ETH_TOKEN,
            minBuyAmount,
            abi.decode(auxiliaryData, (CurveData)),
            recipient
        );
        // Every pool contract currently checks this but why not.
        require(boughtAmount >= minBuyAmount, "CurveLiquidityProvider/UNDERBOUGHT");
        recipient.transfer(boughtAmount);
    }

    /// @dev Quotes the amount of `outputToken` that would be obtained by
    ///      selling `sellAmount` of `inputToken`.
    function getSellQuote(
        IERC20Token /* inputToken */,
        IERC20Token /* outputToken */,
        uint256 /* sellAmount */
    ) external view override returns (uint256) {
        revert("CurveLiquidityProvider/NOT_IMPLEMENTED");
    }

    /// @dev Perform the swap against the curve pool. Handles any combination of
    ///      tokens
    function _executeSwap(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 minBuyAmount,
        CurveData memory data,
        address recipient // Only used to log event.
    ) private returns (uint256 boughtAmount) {
        uint256 sellAmount = LibERC20Transformer.getTokenBalanceOf(inputToken, address(this));
        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            inputToken.approveIfBelow(data.curveAddress, sellAmount);
        }

        (bool success, bytes memory resultData) = data.curveAddress.call{
            value: LibERC20Transformer.isTokenETH(inputToken) ? sellAmount : 0
        }(
            abi.encodeWithSelector(
                data.exchangeFunctionSelector,
                data.fromCoinIdx,
                data.toCoinIdx,
                // dx
                sellAmount,
                // min dy
                minBuyAmount
            )
        );
        if (!success) {
            resultData.rrevert();
        }
        if (resultData.length == 32) {
            // Pool returned a boughtAmount
            boughtAmount = abi.decode(resultData, (uint256));
        } else {
            // Not all pool contracts return a `boughtAmount`, so we return
            // our balance of the output token if it wasn't returned.
            boughtAmount = LibERC20Transformer.getTokenBalanceOf(outputToken, address(this));
        }

        emit LiquidityProviderFill(
            inputToken,
            outputToken,
            sellAmount,
            boughtAmount,
            bytes32("Curve"),
            address(data.curveAddress),
            msg.sender,
            recipient
        );
    }
}
