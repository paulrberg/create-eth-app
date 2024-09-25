/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Inherited
import "../synthetix/Owned.sol";

/**
 * @title BaseGovernanceWrapper
 * @author Lyra
 * @dev Base contract for managing access to exchange functions.
 */
contract BaseGovernanceWrapper is Owned {
  address public riskCouncil;

  constructor() Owned() {}

  function setRiskCouncil(address _riskCouncil) external onlyOwner {
    if (address(0) == _riskCouncil) {
      revert("Zero address");
    }

    riskCouncil = _riskCouncil;
    emit BGW_RiskCouncilSet(riskCouncil);
  }

  /// @notice Allow owner to replace the owner of any arbitrary contract; a manual override.
  function forceChangeOwner(Owned ownedContract, address replacementOwner) external onlyOwner {
    ownedContract.nominateNewOwner(replacementOwner);
    emit BGW_ForceChangeOwner(address(ownedContract), replacementOwner);
  }

  ////////////
  // Access //
  ////////////
  function _onlyRiskCouncilOrOwner() internal view {
    if (msg.sender != owner && msg.sender != riskCouncil) {
      revert BGW_OnlyOwnerOrRiskCouncil(msg.sender, owner, riskCouncil);
    }
  }

  modifier onlyRiskCouncilOrOwner() {
    _onlyRiskCouncilOrOwner();
    _;
  }

  ////////////
  // Events //
  ////////////
  event BGW_RiskCouncilSet(address newRiskCouncil);
  event BGW_ForceChangeOwner(address indexed ownedContract, address replcementOwner);

  ////////////
  // Errors //
  ////////////

  error BGW_OnlyOwnerOrRiskCouncil(address caller, address owner, address riskCouncil);
}
