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

import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/INativeOrdersFeature.sol";
import "./native_orders/NativeOrdersSettlement.sol";

/// @dev Feature for interacting with limit and RFQ orders.
contract NativeOrdersFeature is IFeature, NativeOrdersSettlement {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "LimitOrders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 3, 0);

    constructor(
        address zeroExAddress,
        IEtherToken weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    ) public NativeOrdersSettlement(zeroExAddress, weth, staking, feeCollectorController, protocolFeeMultiplier) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.transferProtocolFeesForPools.selector);
        _registerFeatureFunction(this.fillLimitOrder.selector);
        _registerFeatureFunction(this.fillRfqOrder.selector);
        _registerFeatureFunction(this.fillOrKillLimitOrder.selector);
        _registerFeatureFunction(this.fillOrKillRfqOrder.selector);
        _registerFeatureFunction(this._fillLimitOrder.selector);
        _registerFeatureFunction(this._fillRfqOrder.selector);
        _registerFeatureFunction(this.cancelLimitOrder.selector);
        _registerFeatureFunction(this.cancelRfqOrder.selector);
        _registerFeatureFunction(this.batchCancelLimitOrders.selector);
        _registerFeatureFunction(this.batchCancelRfqOrders.selector);
        _registerFeatureFunction(this.cancelPairLimitOrders.selector);
        _registerFeatureFunction(this.cancelPairLimitOrdersWithSigner.selector);
        _registerFeatureFunction(this.batchCancelPairLimitOrders.selector);
        _registerFeatureFunction(this.batchCancelPairLimitOrdersWithSigner.selector);
        _registerFeatureFunction(this.cancelPairRfqOrders.selector);
        _registerFeatureFunction(this.cancelPairRfqOrdersWithSigner.selector);
        _registerFeatureFunction(this.batchCancelPairRfqOrders.selector);
        _registerFeatureFunction(this.batchCancelPairRfqOrdersWithSigner.selector);
        _registerFeatureFunction(this.getLimitOrderInfo.selector);
        _registerFeatureFunction(this.getRfqOrderInfo.selector);
        _registerFeatureFunction(this.getLimitOrderHash.selector);
        _registerFeatureFunction(this.getRfqOrderHash.selector);
        _registerFeatureFunction(this.getProtocolFeeMultiplier.selector);
        _registerFeatureFunction(this.registerAllowedRfqOrigins.selector);
        _registerFeatureFunction(this.getLimitOrderRelevantState.selector);
        _registerFeatureFunction(this.getRfqOrderRelevantState.selector);
        _registerFeatureFunction(this.batchGetLimitOrderRelevantStates.selector);
        _registerFeatureFunction(this.batchGetRfqOrderRelevantStates.selector);
        _registerFeatureFunction(this.registerAllowedOrderSigner.selector);
        _registerFeatureFunction(this.isValidOrderSigner.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }
}
