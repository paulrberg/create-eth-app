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

import "../src/ReentrancyGuard.sol";

contract TestReentrancyGuard is ReentrancyGuard {
    /// @dev Exposes the nonReentrant modifier publicly.
    /// @param shouldBeAttacked True if the contract should be attacked.
    /// @return True if successful.
    function guarded(bool shouldBeAttacked) external nonReentrant returns (bool) {
        if (shouldBeAttacked) {
            return this.exploitive();
        } else {
            return this.nonExploitive();
        }
    }

    /// @dev This is a function that will reenter the current contract.
    /// @return True if successful.
    function exploitive() external returns (bool) {
        return this.guarded(true);
    }

    /// @dev This is a function that will not reenter the current contract.
    /// @return True if successful.
    function nonExploitive() external pure returns (bool) {
        return true;
    }
}
