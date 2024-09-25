/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { UUPSProxy } from "../upgradability/UUPSProxy.sol";
import { Ownable } from "SuperFluid/@openzeppelin/contracts/access/Ownable.sol";
import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";
import { SuperfluidGovernanceBase } from "./SuperfluidGovernanceBase.sol";
import { ISuperfluid } from "../interfaces/superfluid/ISuperfluid.sol";

/**
 * @title A proxy for governance which is both ownable and upgradable
 * @author Superfluid
 * IMPORTANT! Make sure the inheritance order remains in sync with the logic contract (Ownable first)!
 */
// solhint-disable-next-line no-empty-blocks
contract SuperfluidGovernanceIIProxy is Ownable, UUPSProxy { }

contract SuperfluidGovernanceII is
    Ownable,
    UUPSProxiable,
    SuperfluidGovernanceBase
{
    error SF_GOV_II_ONLY_OWNER();
    function _requireAuthorised() private view {
        if (owner() != _msgSender()) revert SF_GOV_II_ONLY_OWNER();
    }

    /**************************************************************************
    * UUPSProxiable
    **************************************************************************/

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.superfluid-finance.contracts.SuperfluidGovernanceII.implementation");
    }

    function updateCode(address newAddress)
        external override
    {
        _requireAuthorised();
        _updateCodeAddress(newAddress);
    }

    /**************************************************************************
    * SuperfluidGovernanceBase
    **************************************************************************/

    function _requireAuthorised(ISuperfluid /*host*/)
        internal view override
    {
        _requireAuthorised();
    }
}
