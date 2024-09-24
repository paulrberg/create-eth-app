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

// Empty contract for ether collateral placeholder for OVM
// https://docs.synthetix.io/contracts/source/contracts/emptyethercollateral

import "./interfaces/IFuturesMarketManager.sol";

contract EmptyFuturesMarketManager is IFuturesMarketManager {
    bytes32 public constant CONTRACT_NAME = "EmptyFuturesMarketManager";

    function markets(uint index, uint pageSize) external view returns (address[] memory) {
        index;
        pageSize;
        address[] memory _markets;
        return _markets;
    }

    function markets(
        uint index,
        uint pageSize,
        bool proxiedMarkets
    ) external view returns (address[] memory) {
        index;
        pageSize;
        proxiedMarkets;
        address[] memory _markets;
        return _markets;
    }

    function numMarkets() external view returns (uint) {
        return 0;
    }

    function numMarkets(bool proxiedMarkets) external view returns (uint) {
        proxiedMarkets;
        return 0;
    }

    function allMarkets() external view returns (address[] memory) {
        address[] memory _markets;
        return _markets;
    }

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory) {
        proxiedMarkets;
        address[] memory _markets;
        return _markets;
    }

    function marketForKey(bytes32 marketKey) external view returns (address) {
        marketKey;
        return address(0);
    }

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory) {
        marketKeys;
        address[] memory _markets;
        return _markets;
    }

    function totalDebt() external view returns (uint debt, bool isInvalid) {
        return (0, false);
    }

    function isEndorsed(address account) external view returns (bool) {
        account;
        return false;
    }

    function allEndorsedAddresses() external view returns (address[] memory) {
        address[] memory _endorsedAddresses;
        return _endorsedAddresses;
    }

    function addEndorsedAddresses(address[] calldata addresses) external {
        addresses;
    }

    function removeEndorsedAddresses(address[] calldata addresses) external {
        addresses;
    }
}
