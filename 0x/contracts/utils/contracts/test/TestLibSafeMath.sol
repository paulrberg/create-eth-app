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
  
  /*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "../src/LibSafeMath.sol";

contract TestLibSafeMath {
    using LibSafeMath for uint256;

    function externalSafeMul(uint256 a, uint256 b) external pure returns (uint256) {
        return a.safeMul(b);
    }

    function externalSafeDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return a.safeDiv(b);
    }

    function externalSafeSub(uint256 a, uint256 b) external pure returns (uint256) {
        return a.safeSub(b);
    }

    function externalSafeAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return a.safeAdd(b);
    }

    function externalMaxUint256(uint256 a, uint256 b) external pure returns (uint256) {
        return a.max256(b);
    }

    function externalMinUint256(uint256 a, uint256 b) external pure returns (uint256) {
        return a.min256(b);
    }
}
