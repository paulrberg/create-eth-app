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

import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/erc20/src/IERC20Token.sol";

interface IBalancerV2BatchSwapVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IERC20Token[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external returns (int256[] memory amounts);
}

contract MixinBalancerV2Batch {
    using LibERC20TokenV06 for IERC20Token;

    struct BalancerV2BatchBridgeData {
        IBalancerV2BatchSwapVault vault;
        IBalancerV2BatchSwapVault.BatchSwapStep[] swapSteps;
        IERC20Token[] assets;
    }

    function _tradeBalancerV2Batch(
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        (
            IBalancerV2BatchSwapVault vault,
            IBalancerV2BatchSwapVault.BatchSwapStep[] memory swapSteps,
            address[] memory assets_
        ) = abi.decode(bridgeData, (IBalancerV2BatchSwapVault, IBalancerV2BatchSwapVault.BatchSwapStep[], address[]));
        IERC20Token[] memory assets;
        assembly {
            assets := assets_
        }

        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        assets[0].approveIfBelow(address(vault), sellAmount);

        swapSteps[0].amount = sellAmount;
        int256[] memory limits = new int256[](assets.length);
        for (uint256 i = 0; i < limits.length; ++i) {
            limits[i] = type(int256).max;
        }

        int256[] memory amounts = vault.batchSwap(
            IBalancerV2BatchSwapVault.SwapKind.GIVEN_IN,
            swapSteps,
            assets,
            IBalancerV2BatchSwapVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            limits,
            block.timestamp + 1
        );
        require(amounts[amounts.length - 1] <= 0, "Unexpected BalancerV2Batch output");
        return uint256(amounts[amounts.length - 1] * -1);
    }
}
