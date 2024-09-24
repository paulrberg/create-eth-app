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
import "../vendor/v3/IStaking.sol";
import "./FeeCollector.sol";
import "./LibFeeCollector.sol";

/// @dev A contract that manages `FeeCollector` contracts.
contract FeeCollectorController {
    /// @dev Hash of the fee collector init code.
    bytes32 public immutable FEE_COLLECTOR_INIT_CODE_HASH;
    /// @dev The WETH contract.
    IEtherToken private immutable WETH;
    /// @dev The staking contract.
    IStaking private immutable STAKING;

    constructor(IEtherToken weth, IStaking staking) public {
        FEE_COLLECTOR_INIT_CODE_HASH = keccak256(type(FeeCollector).creationCode);
        WETH = weth;
        STAKING = staking;
    }

    /// @dev Deploy (if needed) a `FeeCollector` contract for `poolId`
    ///      and wrap its ETH into WETH. Anyone may call this.
    /// @param poolId The pool ID associated with the staking pool.
    /// @return feeCollector The `FeeCollector` contract instance.
    function prepareFeeCollectorToPayFees(bytes32 poolId) external returns (FeeCollector feeCollector) {
        feeCollector = getFeeCollector(poolId);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(feeCollector)
        }

        if (codeSize == 0) {
            // Create and initialize the contract if necessary.
            new FeeCollector{salt: bytes32(poolId)}();
            feeCollector.initialize(WETH, STAKING, poolId);
        }

        if (address(feeCollector).balance > 1) {
            feeCollector.convertToWeth(WETH);
        }

        return feeCollector;
    }

    /// @dev Get the `FeeCollector` contract for a given pool ID. The contract
    ///      will not actually exist until `prepareFeeCollectorToPayFees()`
    ///      has been called once.
    /// @param poolId The pool ID associated with the staking pool.
    /// @return feeCollector The `FeeCollector` contract instance.
    function getFeeCollector(bytes32 poolId) public view returns (FeeCollector feeCollector) {
        return
            FeeCollector(LibFeeCollector.getFeeCollectorAddress(address(this), FEE_COLLECTOR_INIT_CODE_HASH, poolId));
    }
}
