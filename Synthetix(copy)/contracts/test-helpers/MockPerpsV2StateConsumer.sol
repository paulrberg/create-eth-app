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

import "../interfaces/IPerpsV2MarketState.sol";

contract MockPerpsV2StateConsumer {
    IPerpsV2MarketState public marketState;

    constructor(address _marketState) public {
        marketState = IPerpsV2MarketState(_marketState);
    }

    function nextPositionId() external view returns (uint64) {
        return marketState.nextPositionId();
    }

    function setMarketKey(bytes32 _marketKey) external {
        marketState.setMarketKey(_marketKey);
    }

    function setBaseAsset(bytes32 _baseAsset) external {
        marketState.setBaseAsset(_baseAsset);
    }

    function setMarketSize(uint128 _marketSize) external {
        marketState.setMarketSize(_marketSize);
    }

    function setEntryDebtCorrection(int128 entryDebtCorrection) external {
        marketState.setEntryDebtCorrection(entryDebtCorrection);
    }

    function setNextPositionId(uint64 nextPositionId) external {
        marketState.setNextPositionId(nextPositionId);
    }

    function setMarketSkew(int128 _marketSkew) external {
        marketState.setMarketSkew(_marketSkew);
    }

    function setFundingLastRecomputed(uint32 lastRecomputed) external {
        marketState.setFundingLastRecomputed(lastRecomputed);
    }

    function pushFundingSequence(int128 _fundingSequence) external {
        marketState.pushFundingSequence(_fundingSequence);
    }

    function setFundingRateLastRecomputed(int128 _fundingRateLastRecomputed) external {
        marketState.setFundingRateLastRecomputed(_fundingRateLastRecomputed);
    }

    function updatePosition(
        address account,
        uint64 id,
        uint64 lastFundingIndex,
        uint128 margin,
        uint128 lastPrice,
        int128 size
    ) external {
        marketState.updatePosition(account, id, lastFundingIndex, margin, lastPrice, size);
    }

    function updateDelayedOrder(
        address account,
        bool isOffchain,
        int128 sizeDelta,
        uint128 desiredFillPrice,
        uint128 targetRoundId,
        uint128 commitDeposit,
        uint128 keeperDeposit,
        uint256 executableAtTime,
        uint256 intentionTime,
        bytes32 trackingCode
    ) external {
        marketState.updateDelayedOrder(
            account,
            isOffchain,
            sizeDelta,
            desiredFillPrice,
            targetRoundId,
            commitDeposit,
            keeperDeposit,
            executableAtTime,
            intentionTime,
            trackingCode
        );
    }

    function deletePosition(address account) external {
        marketState.deletePosition(account);
    }

    function deleteDelayedOrder(address account) external {
        marketState.deleteDelayedOrder(account);
    }

    function getPositionAddressesPage(uint index, uint pageSize) external view returns (address[] memory) {
        return marketState.getPositionAddressesPage(index, pageSize);
    }

    function getDelayedOrderAddressesPage(uint index, uint pageSize) external view returns (address[] memory) {
        return marketState.getDelayedOrderAddressesPage(index, pageSize);
    }

    function getPositionAddressesLength() external view returns (uint) {
        return marketState.getPositionAddressesLength();
    }

    function getDelayedOrderAddressesLength() external view returns (uint) {
        return marketState.getDelayedOrderAddressesLength();
    }
}
