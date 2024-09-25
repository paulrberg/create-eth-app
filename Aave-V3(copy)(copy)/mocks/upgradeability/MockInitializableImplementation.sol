/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Aave-V3?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VersionedInitializable} from '../../protocol/libraries/aave-upgradeability/VersionedInitializable.sol';

contract MockInitializableImple is VersionedInitializable {
  uint256 public value;
  string public text;
  uint256[] public values;

  uint256 public constant REVISION = 1;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize(uint256 val, string memory txt, uint256[] memory vals) external initializer {
    value = val;
    text = txt;
    values = vals;
  }

  function setValue(uint256 newValue) public {
    value = newValue;
  }

  function setValueViaProxy(uint256 newValue) public {
    value = newValue;
  }
}

contract MockInitializableImpleV2 is VersionedInitializable {
  uint256 public value;
  string public text;
  uint256[] public values;

  uint256 public constant REVISION = 2;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize(uint256 val, string memory txt, uint256[] memory vals) public initializer {
    value = val;
    text = txt;
    values = vals;
  }

  function setValue(uint256 newValue) public {
    value = newValue;
  }

  function setValueViaProxy(uint256 newValue) public {
    value = newValue;
  }
}

contract MockInitializableFromConstructorImple is VersionedInitializable {
  uint256 public value;

  uint256 public constant REVISION = 2;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  constructor(uint256 val) {
    initialize(val);
  }

  function initialize(uint256 val) public initializer {
    value = val;
  }
}

contract MockReentrantInitializableImple is VersionedInitializable {
  uint256 public value;

  uint256 public constant REVISION = 2;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize(uint256 val) public initializer {
    value = val;
    if (value < 2) {
      initialize(value + 1);
    }
  }
}
