/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Reenterer {
    bool public isPrepared;
    address public target;
    uint256 public msgValue;
    bytes public callData;

    event Reentered(bytes returnData);

    function prepare(
        address targetToUse,
        uint256 msgValueToUse,
        bytes calldata callDataToUse
    ) external {
        target = targetToUse;
        msgValue = msgValueToUse;
        callData = callDataToUse;
        isPrepared = true;
    }

    receive() external payable {
        if (isPrepared) {
            (bool success, bytes memory returnData) = target.call{
                value: msgValue
            }(callData);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            emit Reentered(returnData);

            isPrepared = false;
        }
    }

    function execute(address to, uint256 value, bytes memory data) external {
        (bool success, ) = payable(to).call{ value: value }(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
