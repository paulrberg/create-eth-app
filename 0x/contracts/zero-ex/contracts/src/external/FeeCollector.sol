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
import "0x/contracts/utils/contracts/src/v06/AuthorizableV06.sol";
import "../vendor/v3/IStaking.sol";

/// @dev The collector contract for protocol fees
contract FeeCollector is AuthorizableV06 {
    /// @dev Allow ether transfers to the collector.
    receive() external payable {}

    constructor() public {
        _addAuthorizedAddress(msg.sender);
    }

    /// @dev   Approve the staking contract and join a pool. Only an authority
    ///        can call this.
    /// @param weth The WETH contract.
    /// @param staking The staking contract.
    /// @param poolId The pool ID this contract is collecting fees for.
    function initialize(IEtherToken weth, IStaking staking, bytes32 poolId) external onlyAuthorized {
        weth.approve(address(staking), type(uint256).max);
        staking.joinStakingPoolAsMaker(poolId);
    }

    /// @dev Convert all held ether to WETH. Only an authority can call this.
    /// @param weth The WETH contract.
    function convertToWeth(IEtherToken weth) external onlyAuthorized {
        if (address(this).balance > 0) {
            weth.deposit{value: address(this).balance}();
        }
    }
}
