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

import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinEIP712.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/INativeOrdersFeature.sol";
import "../libs/LibNativeOrder.sol";

abstract contract MultiplexRfq is FixinEIP712 {
    using LibSafeMathV06 for uint256;

    event ExpiredRfqOrder(bytes32 orderHash, address maker, uint64 expiry);

    function _batchSellRfqOrder(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Decode the RFQ order and signature.
        (LibNativeOrder.RfqOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.RfqOrder, LibSignature.Signature)
        );
        // Pre-emptively check if the order is expired.
        if (order.expiry <= uint64(block.timestamp)) {
            bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getRfqOrderStructHash(order));
            emit ExpiredRfqOrder(orderHash, order.maker, order.expiry);
            return;
        }
        // Validate tokens.
        require(
            order.takerToken == params.inputToken && order.makerToken == params.outputToken,
            "MultiplexRfq::_batchSellRfqOrder/RFQ_ORDER_INVALID_TOKENS"
        );
        // Try filling the RFQ order. Swallows reverts.
        try
            INativeOrdersFeature(address(this))._fillRfqOrder(
                order,
                signature,
                sellAmount.safeDowncastToUint128(),
                params.payer,
                params.useSelfBalance,
                params.recipient
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(takerTokenFilledAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(makerTokenFilledAmount);
        } catch {}
    }
}
