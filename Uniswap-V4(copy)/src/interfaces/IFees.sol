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
  
  //SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "../types/Currency.sol";
import {IProtocolFeeController} from "./IProtocolFeeController.sol";

interface IFees {
    /// @notice Thrown when the protocol fee denominator is less than 4. Also thrown when the static or dynamic fee on a pool exceeds the upper limit.
    error FeeTooLarge();
    /// @notice Thrown when an attempt to update pool swap fee but the pool does not have dynamic fee.
    error FeeNotDynamic();
    /// @notice Thrown when not enough gas is provided to look up the protocol fee
    error ProtocolFeeCannotBeFetched();
    /// @notice Thrown when user not authorized to collect protocol fee
    error InvalidProtocolFeeCollector();
    /// @notice Thrown when the call to fetch the protocol fee reverts or returns invalid data.
    error ProtocolFeeControllerCallFailedOrInvalidResult();

    event ProtocolFeeControllerUpdated(address protocolFeeController);

    /// @notice Returns the minimum denominator for the protocol fee, which restricts it to a maximum of 25%
    function MIN_PROTOCOL_FEE_DENOMINATOR() external view returns (uint8);

    /// @notice Given a currency address, returns the protocol fees accrued in that currency
    function protocolFeesAccrued(Currency) external view returns (uint256);

    /// @notice Update the protocol fee controller, called by the owner
    function setProtocolFeeController(IProtocolFeeController controller) external;

    /// @notice Collects the protocol fee accrued in the given currency, called by the owner or the protocol fee controller
    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        returns (uint256 amountCollected);
}
