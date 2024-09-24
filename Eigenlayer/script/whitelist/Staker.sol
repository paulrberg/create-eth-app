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

import "../../src/contracts/interfaces/IStrategyManager.sol";
import "../../src/contracts/interfaces/IStrategy.sol";
import "../../src/contracts/interfaces/IDelegationManager.sol";

import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "Eigenlayer/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "Eigenlayer/lib/forge-std/src/Test.sol";

contract Staker is Ownable {
    
    constructor(
        IStrategy strategy, 
        IStrategyManager strategyManager,
        IDelegationManager delegation,
        IERC20 token, 
        uint256 amount, 
        address operator
    ) Ownable() {
        token.approve(address(strategyManager), type(uint256).max);
        strategyManager.depositIntoStrategy(strategy, token, amount);
        IDelegationManager.SignatureWithExpiry memory signatureWithExpiry;
        delegation.delegateTo(operator, signatureWithExpiry, bytes32(0));
    }
    
    function callAddress(address implementation, bytes memory data) external onlyOwner returns(bytes memory) {
        uint256 length = data.length;
        bytes memory returndata;  
        assembly{
            let result := call(
                gas(),
                implementation,
                callvalue(),
                add(data, 32),
                length,
                0,
                0
            )
            mstore(returndata, returndatasize())
            returndatacopy(add(returndata, 32), 0, returndatasize())
        }


        return returndata;

    }

}