/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

import "../Bytes32SetLib.sol";

contract TestableBytes32Set {
    using Bytes32SetLib for Bytes32SetLib.Bytes32Set;

    Bytes32SetLib.Bytes32Set internal set;

    function contains(bytes32 candidate) public view returns (bool) {
        return set.contains(candidate);
    }

    function getPage(uint index, uint pageSize) public view returns (bytes32[] memory) {
        return set.getPage(index, pageSize);
    }

    function add(bytes32 element) public {
        set.add(element);
    }

    function remove(bytes32 element) public {
        set.remove(element);
    }

    function size() public view returns (uint) {
        return set.elements.length;
    }

    function element(uint index) public view returns (bytes32) {
        return set.elements[index];
    }

    function index(bytes32 element) public view returns (uint) {
        return set.indices[element];
    }
}
