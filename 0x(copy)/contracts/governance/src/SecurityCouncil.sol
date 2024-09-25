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
pragma solidity ^0.8.19;

abstract contract SecurityCouncil {
    address public securityCouncil;

    event SecurityCouncilAssigned(address securityCouncil);

    event SecurityCouncilEjected();

    modifier onlySecurityCouncil() {
        _checkSenderIsSecurityCouncil();
        _;
    }

    /**
     * @dev Checks that either a security council is assigned or the payloads array is a council assignment call.
     */
    modifier securityCouncilAssigned(bytes[] memory payloads) {
        if (securityCouncil == address(0) && !_payloadIsAssignSecurityCouncil(payloads)) {
            revert("SecurityCouncil: security council not assigned and this is not an assignment call");
        }
        _;
    }

    /**
     * @dev Assigns new security council.
     */
    function assignSecurityCouncil(address _securityCouncil) public virtual {
        securityCouncil = _securityCouncil;

        emit SecurityCouncilAssigned(securityCouncil);
    }

    /**
     * @dev Ejects the current security council via setting the security council address to 0.
     * Security council is ejected after they either cancel a proposal or execute a protocol rollback.
     */
    function ejectSecurityCouncil() internal {
        securityCouncil = address(0);
        emit SecurityCouncilEjected();
    }

    /**
     * @dev Cancel existing proposal with the submitted `targets`, `values`, `calldatas` and `descriptionHash`.
     */
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual;

    function _payloadIsAssignSecurityCouncil(bytes[] memory payloads) private pure returns (bool) {
        require(payloads.length == 1, "SecurityCouncil: more than 1 transaction in proposal");
        bytes memory payload = payloads[0];
        // Check this is as assignSecurityCouncil(address) transaction
        // function signature for assignSecurityCouncil(address)
        // = bytes4(keccak256("assignSecurityCouncil(address)"))
        // = 0x2761c3cd
        if (bytes4(payload) == bytes4(0x2761c3cd)) return true;
        else return false;
    }

    function _checkSenderIsSecurityCouncil() private view {
        require(msg.sender == securityCouncil, "SecurityCouncil: only security council allowed");
    }
}
