/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IProtocolFeeController} from "../interfaces/IProtocolFeeController.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {PoolKey} from "../types/PoolKey.sol";

contract ProtocolFeeControllerTest is IProtocolFeeController {
    using PoolIdLibrary for PoolKey;

    mapping(PoolId => uint24) public protocolFee;

    function protocolFeeForPool(PoolKey memory key) external view returns (uint24) {
        return protocolFee[key.toId()];
    }

    // for tests to set pool protocol fees
    function setProtocolFeeForPool(PoolId id, uint24 fee) external {
        protocolFee[id] = fee;
    }
}

/// @notice Reverts on call
contract RevertingProtocolFeeControllerTest is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external pure returns (uint24) {
        revert();
    }
}

/// @notice Returns an out of bounds protocol fee
contract OutOfBoundsProtocolFeeControllerTest is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external pure returns (uint24) {
        // set both protocol fees to 1001, which is greater than MAX_PROTOCOL_FEE
        return (1001 << 12) | 1001;
    }
}

/// @notice Return a value that overflows a uint24
contract OverflowProtocolFeeControllerTest is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external pure returns (uint24) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0xFFFFAAA001)
            return(ptr, 0x20)
        }
    }
}

/// @notice Returns data that is larger than a word
contract InvalidReturnSizeProtocolFeeControllerTest is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external view returns (uint24) {
        address a = address(this);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, a)
            mstore(add(ptr, 0x20), a)
            return(ptr, 0x20)
        }
    }
}
