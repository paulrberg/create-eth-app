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
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IFundRecoveryFeature.sol";
import "../transformers/LibERC20Transformer.sol";

contract FundRecoveryFeature is IFeature, IFundRecoveryFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "FundRecoveryFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.transferTrappedTokensTo.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Recovers ERC20 tokens or ETH from the 0x Exchange Proxy contract
    /// @param erc20 ERC20 Token Address. (You can also pass in `0xeeeee...` to indicate ETH)
    /// @param amountOut Amount of tokens to withdraw.
    /// @param recipientWallet Recipient wallet address.
    function transferTrappedTokensTo(
        IERC20Token erc20,
        uint256 amountOut,
        address payable recipientWallet
    ) external override onlyOwner {
        if (amountOut == uint256(-1)) {
            amountOut = LibERC20Transformer.getTokenBalanceOf(erc20, address(this));
        }
        LibERC20Transformer.transformerTransfer(erc20, recipientWallet, amountOut);
    }
}
