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

interface ISynthetix {
    // Ethereum Mainnet
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint256 minAmount
    ) external returns (uint256 amountReceived);

    // Optimism
    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);
}

contract MixinSynthetix {
    // solhint-disable-next-line const-name-snakecase
    address private constant rewardAddress = 0x5C80239D97E1eB216b5c3D8fBa5DE5Be5d38e4C9;
    // solhint-disable-next-line const-name-snakecase
    bytes32 constant trackingCode = 0x3058000000000000000000000000000000000000000000000000000000000000;

    function _tradeSynthetix(uint256 sellAmount, bytes memory bridgeData) public returns (uint256 boughtAmount) {
        (ISynthetix synthetix, bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) = abi.decode(
            bridgeData,
            (ISynthetix, bytes32, bytes32)
        );

        boughtAmount = exchange(synthetix, sourceCurrencyKey, destinationCurrencyKey, sellAmount);
    }

    function exchange(
        ISynthetix synthetix,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey,
        uint256 sellAmount
    ) internal returns (uint256 boughtAmount) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if (chainId == 1) {
            boughtAmount = synthetix.exchangeAtomically(
                sourceCurrencyKey,
                sellAmount,
                destinationCurrencyKey,
                trackingCode,
                0
            );
        } else {
            boughtAmount = synthetix.exchangeWithTracking(
                sourceCurrencyKey,
                sellAmount,
                destinationCurrencyKey,
                rewardAddress,
                trackingCode
            );
        }
    }
}
