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

import "0x/@openzeppelin/contracts/governance/Governor.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "0x/@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

import "./IZeroExVotes.sol";
import "./SecurityCouncil.sol";

contract ZeroExTreasuryGovernor is
    SecurityCouncil,
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    constructor(
        IVotes votes,
        TimelockController _timelock,
        address _securityCouncil
    )
        Governor("ZeroExTreasuryGovernor")
        GovernorSettings(14400 /* 2 days */, 50400 /* 7 days */, 250000e18)
        GovernorVotes(votes)
        GovernorVotesQuorumFraction(10)
        GovernorTimelockControl(_timelock)
    {
        securityCouncil = _securityCouncil;
    }

    /**
     * @dev Returns the "quadratic" quorum for a block number, in terms of number of votes:
     * `quadratic total supply * numerator / denominator`
     */
    function quorum(
        uint256 blockNumber
    ) public view override(IGovernor, GovernorVotesQuorumFraction) returns (uint256) {
        IZeroExVotes votes = IZeroExVotes(address(token));
        return (votes.getPastQuadraticTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    /**
     * Overwritten GovernorVotes implementation
     * Read the quadratic voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override(Governor, GovernorVotes) returns (uint256) {
        return IZeroExVotes(address(token)).getPastQuadraticVotes(account, blockNumber);
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

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public override onlySecurityCouncil {
        _cancel(targets, values, calldatas, descriptionHash);
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
