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

import "../ContractStorage.sol";

contract MockContractStorage is ContractStorage {
    struct SomeEntry {
        uint value;
        bool flag;
    }

    mapping(bytes32 => mapping(bytes32 => SomeEntry)) public entries;

    constructor(address _resolver) public ContractStorage(_resolver) {}

    function getEntry(bytes32 contractName, bytes32 record) external view returns (uint value, bool flag) {
        SomeEntry storage entry = entries[hashes[contractName]][record];
        return (entry.value, entry.flag);
    }

    function persistEntry(
        bytes32 contractName,
        bytes32 record,
        uint value,
        bool flag
    ) external onlyContract(contractName) {
        entries[_memoizeHash(contractName)][record].value = value;
        entries[_memoizeHash(contractName)][record].flag = flag;
    }
}
