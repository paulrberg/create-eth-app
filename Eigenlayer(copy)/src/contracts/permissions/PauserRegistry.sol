/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Eigenlayer?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "../interfaces/IPauserRegistry.sol";

/**
 * @title Defines pauser & unpauser roles + modifiers to be used elsewhere.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 */
contract PauserRegistry is IPauserRegistry {
    /// @notice Mapping of addresses to whether they hold the pauser role.
    mapping(address => bool) public isPauser;

    /// @notice Unique address that holds the unpauser role. Capable of changing *both* the pauser and unpauser addresses.
    address public unpauser;

    event PauserStatusChanged(address pauser, bool canPause);

    event UnpauserChanged(address previousUnpauser, address newUnpauser);

    modifier onlyUnpauser() {
        require(msg.sender == unpauser, "msg.sender is not permissioned as unpauser");
        _;
    }

    constructor(address[] memory _pausers, address _unpauser) {
        for(uint256 i = 0; i < _pausers.length; i++) {
            _setIsPauser(_pausers[i], true);
        }
        _setUnpauser(_unpauser);
    }

    /// @notice Sets new pauser - only callable by unpauser, as the unpauser is expected to be kept more secure, e.g. being a multisig with a higher threshold
    /// @param newPauser Address to be added/removed as pauser
    /// @param canPause Whether the address should be added or removed as pauser
    function setIsPauser(address newPauser, bool canPause) external onlyUnpauser {
        _setIsPauser(newPauser, canPause);
    }

    /// @notice Sets new unpauser - only callable by unpauser, as the unpauser is expected to be kept more secure, e.g. being a multisig with a higher threshold
    function setUnpauser(address newUnpauser) external onlyUnpauser {
        _setUnpauser(newUnpauser);
    }

    function _setIsPauser(address pauser, bool canPause) internal {
        require(pauser != address(0), "PauserRegistry._setPauser: zero address input");
        isPauser[pauser] = canPause;
        emit PauserStatusChanged(pauser, canPause);
    }

    function _setUnpauser(address newUnpauser) internal {
        require(newUnpauser != address(0), "PauserRegistry._setUnpauser: zero address input");
        emit UnpauserChanged(unpauser, newUnpauser);
        unpauser = newUnpauser;
    }
}
