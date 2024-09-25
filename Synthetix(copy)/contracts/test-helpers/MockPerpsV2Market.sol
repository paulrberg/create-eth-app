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
pragma experimental ABIEncoderV2;

interface IPerpsV2MarketManagerInternal {
    function issueSUSD(address account, uint amount) external;

    function burnSUSD(address account, uint amount) external;

    function payFee(uint amount) external;

    function payFee(uint amount, bytes32 trackingCode) external;
}

contract MockPerpsV2Market {
    bytes32 public baseAsset;
    bytes32 public marketKey;
    uint public debt;
    bool public invalid;
    IPerpsV2MarketManagerInternal public manager;

    constructor(
        IPerpsV2MarketManagerInternal _manager,
        bytes32 _baseAsset,
        bytes32 _marketKey,
        uint _debt,
        bool _invalid
    ) public {
        manager = _manager;
        baseAsset = _baseAsset;
        marketKey = _marketKey;
        debt = _debt;
        invalid = _invalid;
    }

    function setManager(IPerpsV2MarketManagerInternal _manager) external {
        manager = _manager;
    }

    function setBaseAsset(bytes32 _baseAsset) external {
        baseAsset = _baseAsset;
    }

    function setMarketKey(bytes32 _marketKey) external {
        marketKey = _marketKey;
    }

    function setMarketDebt(uint _debt) external {
        debt = _debt;
    }

    function setInvalid(bool _invalid) external {
        invalid = _invalid;
    }

    function marketDebt() external view returns (uint _debt, bool _invalid) {
        return (debt, invalid);
    }

    function issueSUSD(address account, uint amount) external {
        manager.issueSUSD(account, amount);
    }

    function burnSUSD(address account, uint amount) external {
        manager.burnSUSD(account, amount);
    }

    function payFee(uint amount) external {
        manager.payFee(amount);
    }

    function payFee(uint amount, bytes32 trackingCode) external {
        manager.payFee(amount, trackingCode);
    }
}
