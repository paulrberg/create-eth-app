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

import "./interfaces/ICollateralManager.sol";

contract EmptyCollateralManager is ICollateralManager {
    // Manager information
    function hasCollateral(address) external view returns (bool) {
        return false;
    }

    function isSynthManaged(bytes32) external view returns (bool) {
        return false;
    }

    // State information
    function long(bytes32) external view returns (uint amount) {
        return 0;
    }

    function short(bytes32) external view returns (uint amount) {
        return 0;
    }

    function totalLong() external view returns (uint susdValue, bool anyRateIsInvalid) {
        return (0, false);
    }

    function totalShort() external view returns (uint susdValue, bool anyRateIsInvalid) {
        return (0, false);
    }

    function getBorrowRate() external view returns (uint borrowRate, bool anyRateIsInvalid) {
        return (0, false);
    }

    function getShortRate(bytes32) external view returns (uint shortRate, bool rateIsInvalid) {
        return (0, false);
    }

    function getRatesAndTime(uint)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        )
    {
        return (0, 0, 0, 0);
    }

    function getShortRatesAndTime(bytes32, uint)
        external
        view
        returns (
            uint entryRate,
            uint lastRate,
            uint lastUpdated,
            uint newIndex
        )
    {
        return (0, 0, 0, 0);
    }

    function exceedsDebtLimit(uint, bytes32) external view returns (bool canIssue, bool anyRateIsInvalid) {
        return (false, false);
    }

    function areSynthsAndCurrenciesSet(bytes32[] calldata, bytes32[] calldata) external view returns (bool) {
        return false;
    }

    function areShortableSynthsSet(bytes32[] calldata, bytes32[] calldata) external view returns (bool) {
        return false;
    }

    // Loans
    function getNewLoanId() external returns (uint id) {
        return 0;
    }

    // Manager mutative
    function addCollaterals(address[] calldata) external {}

    function removeCollaterals(address[] calldata) external {}

    function addSynths(bytes32[] calldata, bytes32[] calldata) external {}

    function removeSynths(bytes32[] calldata, bytes32[] calldata) external {}

    function addShortableSynths(bytes32[2][] calldata, bytes32[] calldata) external {}

    function removeShortableSynths(bytes32[] calldata) external {}

    // State mutative
    function updateBorrowRates(uint) external {}

    function updateShortRates(bytes32, uint) external {}

    function incrementLongs(bytes32, uint) external {}

    function decrementLongs(bytes32, uint) external {}

    function incrementShorts(bytes32, uint) external {}

    function decrementShorts(bytes32, uint) external {}
}
