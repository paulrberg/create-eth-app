/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/ChainLink?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "../VRFRequestIDBase.sol";

contract VRFRequestIDBaseTestHelper is VRFRequestIDBase {

  function makeVRFInputSeed_(bytes32 _keyHash, uint256 _userSeed,
                            address _requester, uint256 _nonce)
    public pure returns (uint256) {
      return makeVRFInputSeed(_keyHash, _userSeed, _requester, _nonce);
    }

  function makeRequestId_(
    bytes32 _keyHash, uint256 _vRFInputSeed) public pure returns (bytes32) {
    return makeRequestId(_keyHash, _vRFInputSeed);
  }
}
