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
import "../interfaces/IOtcOrdersFeature.sol";
import "../libs/LibNativeOrder.sol";

abstract contract MultiplexOtc is FixinEIP712 {
    using LibSafeMathV06 for uint256;

    event ExpiredOtcOrder(bytes32 orderHash, address maker, uint64 expiry);

    function _batchSellOtcOrder(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Decode the Otc order and signature.
        (LibNativeOrder.OtcOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.OtcOrder, LibSignature.Signature)
        );
        // Validate tokens.
        require(
            order.takerToken == params.inputToken && order.makerToken == params.outputToken,
            "MultiplexOtc::_batchSellOtcOrder/OTC_ORDER_INVALID_TOKENS"
        );
        // Pre-emptively check if the order is expired.
        uint64 expiry = uint64(order.expiryAndNonce >> 192);
        if (expiry <= uint64(block.timestamp)) {
            bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getOtcOrderStructHash(order));
            emit ExpiredOtcOrder(orderHash, order.maker, expiry);
            return;
        }
        // Try filling the Otc order. Swallows reverts.
        try
            IOtcOrdersFeature(address(this))._fillOtcOrder(
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

    function _multiHopSellOtcOrder(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        // Decode the Otc order, and signature.
        (LibNativeOrder.OtcOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.OtcOrder, LibSignature.Signature)
        );
        //Make sure that the otc orders maker and taker tokens match the fill sequence in params.tokens[]
        require(
            address(order.takerToken) == params.tokens[state.hopIndex] &&
                address(order.makerToken) == params.tokens[state.hopIndex + 1],
            "MultiplexOtcOrder::_multiHopSellOtcOrder/INVALID_TOKENS"
        );
        // Try filling the Otc order. Bubble up reverts.
        (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) = IOtcOrdersFeature(address(this))
            ._fillOtcOrder(
                order,
                signature,
                state.outputTokenAmount.safeDowncastToUint128(),
                state.from,
                params.useSelfBalance,
                state.to
            );
        //store the bought amount for the next hop
        state.outputTokenAmount = makerTokenFilledAmount;
    }
}
