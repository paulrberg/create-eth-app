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
pragma solidity ^0.8.24;

import {IProtocolFeeController} from "../../interfaces/IProtocolFeeController.sol";
import {PoolId, PoolIdLibrary} from "../../types/PoolId.sol";
import {PoolKey} from "../../types/PoolKey.sol";

/**
 * @dev A MockProtocolFeeController meant to test Fees functionality
 */
contract MockProtocolFeeController is IProtocolFeeController {
    using PoolIdLibrary for PoolKey;

    mapping(PoolId id => uint16 fee) public protocolFee;

    function setProtocolFeeForPool(PoolKey memory key, uint16 fee) public {
        PoolId id = key.toId();
        protocolFee[id] = fee;
    }

    function protocolFeeForPool(PoolKey memory key) external view returns (uint16) {
        PoolId id = key.toId();
        return protocolFee[id];
    }
}

/// @notice Reverts on call
contract RevertingMockProtocolFeeController is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external pure returns (uint16) {
        revert();
    }
}

/// @notice Returns an out of bounds protocol fee
contract OutOfBoundsMockProtocolFeeController is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external pure returns (uint16) {
        // set swap fee to 1, which is less than MIN_PROTOCOL_FEE_DENOMINATOR
        return 0x0001;
    }
}

/// @notice Return a value that overflows a uint16
contract OverflowMockProtocolFeeController is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external pure returns (uint16) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0xFFFFAAA001)
            return(ptr, 0x20)
        }
    }
}

/// @notice Returns data that is larger than a word
contract InvalidReturnSizeMockProtocolFeeController is IProtocolFeeController {
    function protocolFeeForPool(PoolKey memory /* key */ ) external view returns (uint16) {
        address a = address(this);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, a)
            mstore(add(ptr, 0x20), a)
            return(ptr, 0x40)
        }
    }
}
