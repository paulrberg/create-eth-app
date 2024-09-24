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
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibNativeOrdersRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinEIP712.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IBatchFillNativeOrdersFeature.sol";
import "./interfaces/INativeOrdersFeature.sol";
import "./libs/LibNativeOrder.sol";
import "./libs/LibSignature.sol";

/// @dev Feature for batch/market filling limit and RFQ orders.
contract BatchFillNativeOrdersFeature is IFeature, IBatchFillNativeOrdersFeature, FixinCommon, FixinEIP712 {
    using LibSafeMathV06 for uint128;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "BatchFill";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);

    constructor(address zeroExAddress) public FixinEIP712(zeroExAddress) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.batchFillLimitOrders.selector);
        _registerFeatureFunction(this.batchFillRfqOrders.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Fills multiple limit orders.
    /// @param orders Array of limit orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillLimitOrders(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    )
        external
        payable
        override
        returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts)
    {
        require(
            orders.length == signatures.length && orders.length == takerTokenFillAmounts.length,
            "BatchFillNativeOrdersFeature::batchFillLimitOrders/MISMATCHED_ARRAY_LENGTHS"
        );
        takerTokenFilledAmounts = new uint128[](orders.length);
        makerTokenFilledAmounts = new uint128[](orders.length);
        uint256 protocolFee = uint256(INativeOrdersFeature(address(this)).getProtocolFeeMultiplier()).safeMul(
            tx.gasprice
        );
        uint256 ethProtocolFeePaid;
        for (uint256 i = 0; i != orders.length; i++) {
            try
                INativeOrdersFeature(address(this))._fillLimitOrder(
                    orders[i],
                    signatures[i],
                    takerTokenFillAmounts[i],
                    msg.sender,
                    msg.sender
                )
            returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
                // Update amounts filled.
                (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) = (
                    takerTokenFilledAmount,
                    makerTokenFilledAmount
                );
                ethProtocolFeePaid = ethProtocolFeePaid.safeAdd(protocolFee);
            } catch {}

            if (revertIfIncomplete && takerTokenFilledAmounts[i] < takerTokenFillAmounts[i]) {
                bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getLimitOrderStructHash(orders[i]));
                // Did not fill the amount requested.
                LibNativeOrdersRichErrors
                    .BatchFillIncompleteError(orderHash, takerTokenFilledAmounts[i], takerTokenFillAmounts[i])
                    .rrevert();
            }
        }
        LibNativeOrder.refundExcessProtocolFeeToSender(ethProtocolFeePaid);
    }

    /// @dev Fills multiple RFQ orders.
    /// @param orders Array of RFQ orders.
    /// @param signatures Array of signatures corresponding to each order.
    /// @param takerTokenFillAmounts Array of desired amounts to fill each order.
    /// @param revertIfIncomplete If true, reverts if this function fails to
    ///        fill the full fill amount for any individual order.
    /// @return takerTokenFilledAmounts Array of amounts filled, in taker token.
    /// @return makerTokenFilledAmounts Array of amounts filled, in maker token.
    function batchFillRfqOrders(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        uint128[] calldata takerTokenFillAmounts,
        bool revertIfIncomplete
    ) external override returns (uint128[] memory takerTokenFilledAmounts, uint128[] memory makerTokenFilledAmounts) {
        require(
            orders.length == signatures.length && orders.length == takerTokenFillAmounts.length,
            "BatchFillNativeOrdersFeature::batchFillRfqOrders/MISMATCHED_ARRAY_LENGTHS"
        );
        takerTokenFilledAmounts = new uint128[](orders.length);
        makerTokenFilledAmounts = new uint128[](orders.length);
        for (uint256 i = 0; i != orders.length; i++) {
            try
                INativeOrdersFeature(address(this))._fillRfqOrder(
                    orders[i],
                    signatures[i],
                    takerTokenFillAmounts[i],
                    msg.sender,
                    false,
                    msg.sender
                )
            returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
                // Update amounts filled.
                (takerTokenFilledAmounts[i], makerTokenFilledAmounts[i]) = (
                    takerTokenFilledAmount,
                    makerTokenFilledAmount
                );
            } catch {}

            if (revertIfIncomplete && takerTokenFilledAmounts[i] < takerTokenFillAmounts[i]) {
                // Did not fill the amount requested.
                bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getRfqOrderStructHash(orders[i]));
                LibNativeOrdersRichErrors
                    .BatchFillIncompleteError(orderHash, takerTokenFilledAmounts[i], takerTokenFillAmounts[i])
                    .rrevert();
            }
        }
    }
}
