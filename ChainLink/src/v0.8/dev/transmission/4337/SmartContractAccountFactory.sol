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
pragma solidity ^0.8.15;

contract SmartContractAccountFactory {
  event ContractCreated(address scaAddress);

  error DeploymentFailed();

  /// @dev Use create2 to deploy a new Smart Contract Account.
  /// @dev See EIP-1014 for more on CREATE2.
  /// TODO: Return the address of the Smart Contract Account even if it is already
  /// deployed.
  function deploySmartContractAccount(
    bytes32 abiEncodedOwnerAddress,
    bytes memory initCode
  ) external payable returns (address scaAddress) {
    assembly {
      scaAddress := create2(
        0, // value - left at zero here
        add(0x20, initCode), // initialization bytecode
        mload(initCode), // length of initialization bytecode
        abiEncodedOwnerAddress // user-defined nonce to ensure unique SCA addresses
      )
    }
    if (scaAddress == address(0)) {
      revert DeploymentFailed();
    }

    emit ContractCreated(scaAddress);
  }
}
