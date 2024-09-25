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

import "0x/contracts/utils/contracts/src/v06/AuthorizableV06.sol";

/// @dev A contract with a `die()` function.
interface IKillable {
    function die(address payable ethRecipient) external;
}

/// @dev Deployer contract for ERC20 transformers.
///      Only authorities may call `deploy()` and `kill()`.
contract TransformerDeployer is AuthorizableV06 {
    /// @dev Emitted when a contract is deployed via `deploy()`.
    /// @param deployedAddress The address of the deployed contract.
    /// @param nonce The deployment nonce.
    /// @param sender The caller of `deploy()`.
    event Deployed(address deployedAddress, uint256 nonce, address sender);
    /// @dev Emitted when a contract is killed via `kill()`.
    /// @param target The address of the contract being killed..
    /// @param sender The caller of `kill()`.
    event Killed(address target, address sender);

    // @dev The current nonce of this contract.
    uint256 public nonce = 1;
    // @dev Mapping of deployed contract address to deployment nonce.
    mapping(address => uint256) public toDeploymentNonce;

    /// @dev Create this contract and register authorities.
    constructor(address[] memory initialAuthorities) public {
        for (uint256 i = 0; i < initialAuthorities.length; ++i) {
            _addAuthorizedAddress(initialAuthorities[i]);
        }
    }

    /// @dev Deploy a new contract. Only callable by an authority.
    ///      Any attached ETH will also be forwarded.
    function deploy(bytes memory bytecode) public payable onlyAuthorized returns (address deployedAddress) {
        uint256 deploymentNonce = nonce;
        nonce += 1;
        assembly {
            deployedAddress := create(callvalue(), add(bytecode, 32), mload(bytecode))
        }
        require(deployedAddress != address(0), "TransformerDeployer/DEPLOY_FAILED");
        toDeploymentNonce[deployedAddress] = deploymentNonce;
        emit Deployed(deployedAddress, deploymentNonce, msg.sender);
    }

    /// @dev Call `die()` on a contract. Only callable by an authority.
    /// @param target The target contract to call `die()` on.
    /// @param ethRecipient The Recipient of any ETH locked in `target`.
    function kill(IKillable target, address payable ethRecipient) public onlyAuthorized {
        target.die(ethRecipient);
        emit Killed(address(target), msg.sender);
    }
}
