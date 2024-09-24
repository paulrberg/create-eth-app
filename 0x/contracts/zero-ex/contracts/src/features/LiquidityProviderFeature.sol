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
import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibLiquidityProviderRichErrors.sol";
import "../external/ILiquidityProviderSandbox.sol";
import "../external/LiquidityProviderSandbox.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinTokenSpender.sol";
import "../migrations/LibMigrate.sol";
import "../transformers/LibERC20Transformer.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ILiquidityProviderFeature.sol";

contract LiquidityProviderFeature is IFeature, ILiquidityProviderFeature, FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "LiquidityProviderFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 4);

    /// @dev The sandbox contract address.
    ILiquidityProviderSandbox public immutable sandbox;

    constructor(LiquidityProviderSandbox sandbox_) public FixinCommon() {
        sandbox = sandbox_;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToLiquidityProvider.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells `sellAmount` of `inputToken` to the liquidity provider
    ///      at the given `provider` address.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param provider The address of the on-chain liquidity provider
    ///        to trade with.
    /// @param recipient The recipient of the bought tokens. If equal to
    ///        address(0), `msg.sender` is assumed to be the recipient.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to
    ///        buy. Reverts if this amount is not satisfied.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellToLiquidityProvider(
        IERC20Token inputToken,
        IERC20Token outputToken,
        ILiquidityProvider provider,
        address recipient,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable override returns (uint256 boughtAmount) {
        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        // Forward all attached ETH to the provider.
        if (msg.value > 0) {
            payable(address(provider)).transfer(msg.value);
        }

        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            // Transfer input ERC20 tokens to the provider.
            _transferERC20TokensFrom(inputToken, msg.sender, address(provider), sellAmount);
        }

        if (LibERC20Transformer.isTokenETH(inputToken)) {
            uint256 balanceBefore = outputToken.balanceOf(recipient);
            sandbox.executeSellEthForToken(provider, outputToken, recipient, minBuyAmount, auxiliaryData);
            boughtAmount = IERC20Token(outputToken).balanceOf(recipient).safeSub(balanceBefore);
        } else if (LibERC20Transformer.isTokenETH(outputToken)) {
            uint256 balanceBefore = recipient.balance;
            sandbox.executeSellTokenForEth(provider, inputToken, recipient, minBuyAmount, auxiliaryData);
            boughtAmount = recipient.balance.safeSub(balanceBefore);
        } else {
            uint256 balanceBefore = outputToken.balanceOf(recipient);
            sandbox.executeSellTokenForToken(provider, inputToken, outputToken, recipient, minBuyAmount, auxiliaryData);
            boughtAmount = outputToken.balanceOf(recipient).safeSub(balanceBefore);
        }

        if (boughtAmount < minBuyAmount) {
            LibLiquidityProviderRichErrors
                .LiquidityProviderIncompleteSellError(
                    address(provider),
                    address(outputToken),
                    address(inputToken),
                    sellAmount,
                    boughtAmount,
                    minBuyAmount
                )
                .rrevert();
        }

        emit LiquidityProviderSwap(inputToken, outputToken, sellAmount, boughtAmount, provider, recipient);
    }
}
