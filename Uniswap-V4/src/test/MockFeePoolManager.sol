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

import {IVault} from "../interfaces/IVault.sol";
import {PoolId, PoolIdLibrary} from "../types/PoolId.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {BalanceDelta} from "../types/BalanceDelta.sol";
import {Fees} from "../Fees.sol";
import {FeeLibrary} from "../libraries/FeeLibrary.sol";
import {FixedPointMathLib} from "Uniswap-V4/solmate/utils/FixedPointMathLib.sol";

/**
 * @dev A MockFeePoolManager meant to test Fees functionality
 */
contract MockFeePoolManager is Fees {
    using PoolIdLibrary for PoolKey;
    using FeeLibrary for uint24;
    using FixedPointMathLib for uint256;

    mapping(PoolId poolId => BalanceDelta delta) public balanceDeltaOfPool;
    mapping(PoolId id => Slot0) public pools;

    struct Slot0 {
        uint16 protocolFee;
    }

    constructor(IVault vault, uint256 controllerGasLimit) Fees(vault, controllerGasLimit) {}

    function initialize(PoolKey memory key, bytes calldata) external {
        PoolId id = key.toId();

        (, uint16 protocolFee) = _fetchProtocolFee(key);

        pools[id] = Slot0({protocolFee: protocolFee});
    }

    function swap(PoolKey memory key, uint256 amt0Fee, uint256 amt1Fee)
        public
        returns (uint256 protocolFee0, uint256 protocolFee1)
    {
        return mockAction(key, amt0Fee, amt1Fee, true);
    }

    function withdraw(PoolKey memory key, uint256 amt0Fee, uint256 amt1Fee)
        public
        returns (uint256 protocolFee0, uint256 protocolFee1)
    {
        return mockAction(key, amt0Fee, amt1Fee, false);
    }

    /**
     * @dev mock an anction (swap or withdrawal)
     *
     */
    function mockAction(PoolKey memory key, uint256 amt0Fee, uint256 amt1Fee, bool isSwap)
        public
        returns (uint256 protocolFee0, uint256 protocolFee1)
    {
        PoolId id = key.toId();
        Slot0 memory slot0 = pools[id];

        // Similar to uni-v4 logic (deduct protocolFee portion first)
        uint16 protocolFee = isSwap ? slot0.protocolFee : 0;

        if (protocolFee > 0) {
            if ((protocolFee % 256) > 0) {
                protocolFee0 = amt0Fee / (protocolFee % 256);
                amt0Fee -= protocolFee0;
                protocolFeesAccrued[key.currency0] += protocolFee0;
            }

            if ((protocolFee >> 8) > 0) {
                protocolFee1 = amt1Fee / (protocolFee >> 8);
                amt1Fee -= protocolFee1;
                protocolFeesAccrued[key.currency1] += protocolFee1;
            }
        }
    }

    function getProtocolFee(PoolKey memory key) external view returns (uint16) {
        return pools[key.toId()].protocolFee;
    }
}
