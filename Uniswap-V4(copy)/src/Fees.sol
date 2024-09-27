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
  
  // SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.24;

import {Ownable} from "Uniswap-V4/@openzeppelin/contracts/access/Ownable.sol";

import {Currency} from "./types/Currency.sol";
import {IProtocolFeeController} from "./interfaces/IProtocolFeeController.sol";
import {IFees} from "./interfaces/IFees.sol";
import {PoolKey} from "./types/PoolKey.sol";
import {IVault} from "./interfaces/IVault.sol";

abstract contract Fees is IFees, Ownable {
    uint8 public constant MIN_PROTOCOL_FEE_DENOMINATOR = 4;

    mapping(Currency currency => uint256) public protocolFeesAccrued;

    IProtocolFeeController public protocolFeeController;
    IVault public immutable vault;

    uint256 private immutable controllerGasLimit;

    constructor(IVault _vault, uint256 _controllerGasLimit) {
        vault = _vault;
        controllerGasLimit = _controllerGasLimit;
    }

    /// @notice Fetch the protocol fee for a given pool, returning false if the call fails or the returned fee is invalid.
    /// @dev to prevent an invalid protocol fee controller from blocking pools from being initialized
    ///      the success of this function is NOT checked on initialize and if the call fails, the protocol fee is set to 0.
    /// @dev the success of this function must be checked when called in setProtocolFee
    function _fetchProtocolFee(PoolKey memory key) internal returns (bool success, uint16 protocolFee) {
        if (address(protocolFeeController) != address(0)) {
            // note that EIP-150 mandates that calls requesting more than 63/64ths of remaining gas
            // will be allotted no more than this amount, so controllerGasLimit must be set with this
            // in mind.
            if (gasleft() < controllerGasLimit) revert ProtocolFeeCannotBeFetched();

            (bool _success, bytes memory _data) = address(protocolFeeController).call{gas: controllerGasLimit}(
                abi.encodeWithSelector(IProtocolFeeController.protocolFeeForPool.selector, key)
            );
            // Ensure that the return data fits within a word
            if (!_success || _data.length > 32) return (false, 0);

            uint256 returnData;
            assembly {
                returnData := mload(add(_data, 0x20))
            }
            // Ensure return data does not overflow a uint16 and that the underlying fees are within bounds.
            (success, protocolFee) = returnData == uint16(returnData) && _isFeeWithinBounds(uint16(returnData))
                ? (true, uint16(returnData))
                : (false, 0);
        }
    }

    /// @dev the lower 8 bits for fee0 and upper 8 bits for fee1
    function _isFeeWithinBounds(uint16 fee) internal pure returns (bool) {
        if (fee != 0) {
            uint16 fee0 = fee % 256;
            uint16 fee1 = fee >> 8;
            // The fee is specified as a denominator so it cannot be LESS than the MIN_PROTOCOL_FEE_DENOMINATOR (unless it is 0).
            if (
                (fee0 != 0 && fee0 < MIN_PROTOCOL_FEE_DENOMINATOR) || (fee1 != 0 && fee1 < MIN_PROTOCOL_FEE_DENOMINATOR)
            ) {
                return false;
            }
        }
        return true;
    }

    function setProtocolFeeController(IProtocolFeeController controller) external onlyOwner {
        protocolFeeController = controller;
        emit ProtocolFeeControllerUpdated(address(controller));
    }

    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        override
        returns (uint256 amountCollected)
    {
        if (msg.sender != owner() && msg.sender != address(protocolFeeController)) revert InvalidProtocolFeeCollector();

        amountCollected = (amount == 0) ? protocolFeesAccrued[currency] : amount;
        protocolFeesAccrued[currency] -= amountCollected;
        vault.collectFee(currency, amountCollected, recipient);
    }
}
