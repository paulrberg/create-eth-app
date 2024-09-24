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
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/ITransformERC20Feature.sol";

abstract contract MultiplexTransformERC20 {
    using LibSafeMathV06 for uint256;

    function _batchSellTransformERC20(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        ITransformERC20Feature.TransformERC20Args memory args;
        // We want the TransformedERC20 event to have
        // `payer` as the taker.
        args.taker = payable(params.payer);
        args.inputToken = params.inputToken;
        args.outputToken = params.outputToken;
        args.inputTokenAmount = sellAmount;
        args.minOutputTokenAmount = 0;
        args.useSelfBalance = params.useSelfBalance;
        args.recipient = payable(params.recipient);
        (args.transformations) = abi.decode(wrappedCallData, (ITransformERC20Feature.Transformation[]));
        // Execute the transformations and swallow reverts.
        try ITransformERC20Feature(address(this))._transformERC20(args) returns (uint256 outputTokenAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
        } catch {}
    }
}
