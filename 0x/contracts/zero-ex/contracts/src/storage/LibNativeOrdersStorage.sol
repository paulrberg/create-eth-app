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

import "./LibStorage.sol";

/// @dev Storage helpers for `NativeOrdersFeature`.
library LibNativeOrdersStorage {
    /// @dev Storage bucket for this feature.
    struct Storage {
        // How much taker token has been filled in order.
        // The lower `uint128` is the taker token fill amount.
        // The high bit will be `1` if the order was directly cancelled.
        mapping(bytes32 => uint256) orderHashToTakerTokenFilledAmount;
        // The minimum valid order salt for a given maker and order pair (maker, taker) for limit orders.
        // solhint-disable-next-line max-line-length
        mapping(address => mapping(address => mapping(address => uint256))) limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt;
        // The minimum valid order salt for a given maker and order pair (maker, taker) for RFQ orders.
        // solhint-disable-next-line max-line-length
        mapping(address => mapping(address => mapping(address => uint256))) rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt;
        // For a given order origin, which tx.origin addresses are allowed to fill the order.
        mapping(address => mapping(address => bool)) originRegistry;
        // For a given maker address, which addresses are allowed to
        // sign on its behalf.
        mapping(address => mapping(address => bool)) orderSignerRegistry;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.NativeOrders);
        // Dip into assembly to change the slot pointed to by the local variable `stor`.
        // solhint-disable-next-line max-line-length
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor_slot := storageSlot
        }
    }
}
