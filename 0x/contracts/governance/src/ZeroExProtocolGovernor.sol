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

import "./SecurityCouncil.sol";
import "./ZeroExTimelock.sol";
import "0x/@openzeppelin/contracts/governance/Governor.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract ZeroExProtocolGovernor is
    SecurityCouncil,
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorTimelockControl
{
    constructor(
        IVotes _votes,
        ZeroExTimelock _timelock,
        address _securityCouncil
    )
        Governor("ZeroExProtocolGovernor")
        GovernorSettings(14400 /* 2 days */, 50400 /* 7 days */, 1000000e18)
        GovernorVotes(_votes)
        GovernorTimelockControl(TimelockController(payable(_timelock)))
    {
        securityCouncil = _securityCouncil;
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 10000000e18;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) securityCouncilAssigned(calldatas) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public override onlySecurityCouncil {
        _cancel(targets, values, calldatas, descriptionHash);
    }

    // Like the GovernorTimelockControl.queue function but without the proposal checks,
    // (as there's effectively no proposal).
    // And also using a delay of 0 as opposed to the minimum delay of the timelock
    function executeRollback(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public onlySecurityCouncil {
        // Execute the batch of rollbacks via the timelock controller
        ZeroExTimelock timelockController = ZeroExTimelock(payable(timelock()));
        timelockController.executeRollbackBatch(targets, values, calldatas, 0, descriptionHash);
    }

    function assignSecurityCouncil(address _securityCouncil) public override onlyGovernance {
        super.assignSecurityCouncil(_securityCouncil);
    }

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public override securityCouncilAssigned(calldatas) returns (uint256) {
        return super.queue(targets, values, calldatas, descriptionHash);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
