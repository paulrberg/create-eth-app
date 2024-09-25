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
import "../external/FeeCollector.sol";
import "../external/FeeCollectorController.sol";
import "../external/LibFeeCollector.sol";
import "../vendor/v3/IStaking.sol";

/// @dev Helpers for collecting protocol fees.
abstract contract FixinProtocolFees {
    /// @dev The protocol fee multiplier.
    uint32 public immutable PROTOCOL_FEE_MULTIPLIER;
    /// @dev The `FeeCollectorController` contract.
    FeeCollectorController private immutable FEE_COLLECTOR_CONTROLLER;
    /// @dev Hash of the fee collector init code.
    bytes32 private immutable FEE_COLLECTOR_INIT_CODE_HASH;
    /// @dev The WETH token contract.
    IEtherToken private immutable WETH;
    /// @dev The staking contract.
    IStaking private immutable STAKING;

    constructor(
        IEtherToken weth,
        IStaking staking,
        FeeCollectorController feeCollectorController,
        uint32 protocolFeeMultiplier
    ) internal {
        FEE_COLLECTOR_CONTROLLER = feeCollectorController;
        FEE_COLLECTOR_INIT_CODE_HASH = feeCollectorController.FEE_COLLECTOR_INIT_CODE_HASH();
        WETH = weth;
        STAKING = staking;
        PROTOCOL_FEE_MULTIPLIER = protocolFeeMultiplier;
    }

    /// @dev   Collect the specified protocol fee in ETH.
    ///        The fee is stored in a per-pool fee collector contract.
    /// @param poolId The pool ID for which a fee is being collected.
    /// @return ethProtocolFeePaid How much protocol fee was collected in ETH.
    function _collectProtocolFee(bytes32 poolId) internal returns (uint256 ethProtocolFeePaid) {
        uint256 protocolFeePaid = _getSingleProtocolFee();
        if (protocolFeePaid == 0) {
            // Nothing to do.
            return 0;
        }
        FeeCollector feeCollector = _getFeeCollector(poolId);
        (bool success, ) = address(feeCollector).call{value: protocolFeePaid}("");
        require(success, "FixinProtocolFees/ETHER_TRANSFER_FALIED");
        return protocolFeePaid;
    }

    /// @dev Transfer fees for a given pool to the staking contract.
    /// @param poolId Identifies the pool whose fees are being paid.
    function _transferFeesForPool(bytes32 poolId) internal {
        // This will create a FeeCollector contract (if necessary) and wrap
        // fees for the pool ID.
        FeeCollector feeCollector = FEE_COLLECTOR_CONTROLLER.prepareFeeCollectorToPayFees(poolId);
        // All fees in the fee collector should be in WETH now.
        uint256 bal = WETH.balanceOf(address(feeCollector));
        if (bal > 1) {
            // Leave 1 wei behind to avoid high SSTORE cost of zero-->non-zero.
            STAKING.payProtocolFee(address(feeCollector), address(feeCollector), bal - 1);
        }
    }

    /// @dev Compute the CREATE2 address for a fee collector.
    /// @param poolId The fee collector's pool ID.
    function _getFeeCollector(bytes32 poolId) internal view returns (FeeCollector) {
        return
            FeeCollector(
                LibFeeCollector.getFeeCollectorAddress(
                    address(FEE_COLLECTOR_CONTROLLER),
                    FEE_COLLECTOR_INIT_CODE_HASH,
                    poolId
                )
            );
    }

    /// @dev Get the cost of a single protocol fee.
    /// @return protocolFeeAmount The protocol fee amount, in ETH/WETH.
    function _getSingleProtocolFee() internal view returns (uint256 protocolFeeAmount) {
        return uint256(PROTOCOL_FEE_MULTIPLIER) * tx.gasprice;
    }
}
