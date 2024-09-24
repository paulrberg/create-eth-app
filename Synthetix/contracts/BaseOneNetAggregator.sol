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

//import "Synthetix/@chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol";

import "./AddressResolver.sol";
import "./interfaces/IDebtCache.sol";
import "./interfaces/ISynthetixDebtShare.sol";
import "./interfaces/AggregatorV2V3Interface.sol";

import "./SafeDecimalMath.sol";

// aggregator which reports the data from the system itself
// useful for testing
contract BaseOneNetAggregator is Owned, AggregatorV2V3Interface {
    using SafeDecimalMath for uint;

    AddressResolver public resolver;

    uint public overrideTimestamp;

    constructor(AddressResolver _resolver) public Owned(msg.sender) {
        resolver = _resolver;
    }

    function setOverrideTimestamp(uint timestamp) public onlyOwner {
        overrideTimestamp = timestamp;

        emit SetOverrideTimestamp(timestamp);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return getRoundData(uint80(latestRound()));
    }

    function latestRound() public view returns (uint256) {
        return 1;
    }

    function decimals() external view returns (uint8) {
        return 0;
    }

    function getAnswer(uint256 _roundId) external view returns (int256 answer) {
        (, answer, , , ) = getRoundData(uint80(_roundId));
    }

    function getTimestamp(uint256 _roundId) external view returns (uint256 timestamp) {
        (, , timestamp, , ) = getRoundData(uint80(_roundId));
    }

    function getRoundData(uint80)
        public
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        );

    event SetOverrideTimestamp(uint timestamp);
}
