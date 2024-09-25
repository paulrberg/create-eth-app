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

import "0x/contracts/erc20/src/IERC20Token.sol";

library BridgeProtocols {
    // A incrementally increasing, append-only list of protocol IDs.
    // We don't use an enum so solidity doesn't throw when we pass in a
    // new protocol ID that hasn't been rolled up yet.
    uint128 internal constant UNKNOWN = 0;
    uint128 internal constant CURVE = 1;
    uint128 internal constant UNISWAPV2 = 2;
    uint128 internal constant UNISWAP = 3;
    uint128 internal constant BALANCER = 4;
    uint128 internal constant KYBER = 5; // Not used: deprecated.
    uint128 internal constant MOONISWAP = 6;
    uint128 internal constant MSTABLE = 7;
    uint128 internal constant OASIS = 8; // Not used: deprecated.
    uint128 internal constant SHELL = 9;
    uint128 internal constant DODO = 10;
    uint128 internal constant DODOV2 = 11;
    uint128 internal constant CRYPTOCOM = 12;
    uint128 internal constant BANCOR = 13;
    uint128 internal constant COFIX = 14; // Not used: deprecated.
    uint128 internal constant NERVE = 15;
    uint128 internal constant MAKERPSM = 16;
    uint128 internal constant BALANCERV2 = 17;
    uint128 internal constant UNISWAPV3 = 18;
    uint128 internal constant KYBERDMM = 19;
    uint128 internal constant CURVEV2 = 20;
    uint128 internal constant LIDO = 21;
    uint128 internal constant CLIPPER = 22; // Not used: Clipper is now using PLP interface
    uint128 internal constant AAVEV2 = 23;
    uint128 internal constant COMPOUND = 24;
    uint128 internal constant BALANCERV2BATCH = 25;
    uint128 internal constant GMX = 26;
    uint128 internal constant PLATYPUS = 27;
    uint128 internal constant BANCORV3 = 28;
    uint128 internal constant SOLIDLY = 29;
    uint128 internal constant SYNTHETIX = 30;
    uint128 internal constant WOOFI = 31;
    uint128 internal constant AAVEV3 = 32;
    uint128 internal constant KYBERELASTIC = 33;
    uint128 internal constant BARTER = 34;
    uint128 internal constant TRADERJOEV2 = 35;
    uint128 internal constant VELODROMEV2 = 36;
    uint128 internal constant MAVERICKV1 = 37;
}
