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

import "0x/contracts/erc20/src/IEtherToken.sol";
import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinProtocolFees.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";
import "../../vendor/v3/IStaking.sol";

/// @dev Mixin for protocol fee utility functions.
abstract contract NativeOrdersProtocolFees is FixinProtocolFees {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    constructor(
        IEtherToken weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    ) internal FixinProtocolFees(weth, staking, feeCollectorController, protocolFeeMultiplier) {}

    /// @dev Transfers protocol fees from the `FeeCollector` pools into
    ///      the staking contract.
    /// @param poolIds Staking pool IDs
    function transferProtocolFeesForPools(bytes32[] calldata poolIds) external {
        for (uint256 i = 0; i < poolIds.length; ++i) {
            _transferFeesForPool(poolIds[i]);
        }
    }

    /// @dev Get the protocol fee multiplier. This should be multiplied by the
    ///      gas price to arrive at the required protocol fee to fill a native order.
    /// @return multiplier The protocol fee multiplier.
    function getProtocolFeeMultiplier() external view returns (uint32 multiplier) {
        return PROTOCOL_FEE_MULTIPLIER;
    }
}
