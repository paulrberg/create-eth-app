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

import "../interfaces/ISynthetix.sol";

contract MockExchanger {
    uint256 private _mockReclaimAmount;
    uint256 private _mockRefundAmount;
    uint256 private _mockNumEntries;
    uint256 private _mockMaxSecsLeft;

    ISynthetix public synthetix;

    constructor(ISynthetix _synthetix) public {
        synthetix = _synthetix;
    }

    // Mock settle function
    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint numEntriesSettled
        )
    {
        if (_mockReclaimAmount > 0) {
            synthetix.synths(currencyKey).burn(from, _mockReclaimAmount);
        }

        if (_mockRefundAmount > 0) {
            synthetix.synths(currencyKey).issue(from, _mockRefundAmount);
        }

        _mockMaxSecsLeft = 0;

        return (_mockReclaimAmount, _mockRefundAmount, _mockNumEntries);
    }

    // silence compiler warnings for args
    function maxSecsLeftInWaitingPeriod(
        address, /* account */
        bytes32 /* currencyKey */
    ) public view returns (uint) {
        return _mockMaxSecsLeft;
    }

    // silence compiler warnings for args
    function settlementOwing(
        address, /* account */
        bytes32 /* currencyKey */
    )
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return (_mockReclaimAmount, _mockRefundAmount, _mockNumEntries);
    }

    // silence compiler warnings for args
    function hasWaitingPeriodOrSettlementOwing(
        address, /* account */
        bytes32 /* currencyKey */
    ) external view returns (bool) {
        if (_mockMaxSecsLeft > 0) {
            return true;
        }

        if (_mockReclaimAmount > 0 || _mockRefundAmount > 0) {
            return true;
        }

        return false;
    }

    function setReclaim(uint256 _reclaimAmount) external {
        _mockReclaimAmount = _reclaimAmount;
    }

    function setRefund(uint256 _refundAmount) external {
        _mockRefundAmount = _refundAmount;
    }

    function setNumEntries(uint256 _numEntries) external {
        _mockNumEntries = _numEntries;
    }

    function setMaxSecsLeft(uint _maxSecsLeft) external {
        _mockMaxSecsLeft = _maxSecsLeft;
    }
}
