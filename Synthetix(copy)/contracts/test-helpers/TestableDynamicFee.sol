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
// Libraries
import "../Exchanger.sol";

contract TestableDynamicFee is Exchanger {
    constructor(address _owner, address _resolver) public Exchanger(_owner, _resolver) {}

    function thresholdedAbsDeviationRatio(
        uint price,
        uint previousPrice,
        uint threshold
    ) external view returns (uint) {
        return _thresholdedAbsDeviationRatio(price, previousPrice, threshold);
    }

    function dynamicFeeCalculation(
        uint[] calldata prices,
        uint threshold,
        uint weightDecay
    ) external view returns (uint) {
        return _dynamicFeeCalculation(prices, threshold, weightDecay);
    }
}
