/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier:ISC
pragma solidity 0.8.16;

// Inherited
import "../../synthetix/Owned.sol";

// Interfaces
import "../../OptionMarket.sol";

/**
 * @title BasicOptionMarketWrapper
 */
contract BasicOptionMarketWrapper is Owned {
  struct OptionMarketContracts {
    IERC20 quoteAsset;
    IERC20 baseAsset;
    OptionToken optionToken;
  }

  mapping(OptionMarket => OptionMarketContracts) public marketContracts;

  constructor() Owned() {}

  function updateMarket(OptionMarket optionMarket, OptionMarketContracts memory _marketContracts) external onlyOwner {
    marketContracts[optionMarket] = _marketContracts;

    marketContracts[optionMarket].quoteAsset.approve(address(optionMarket), type(uint).max);
    marketContracts[optionMarket].baseAsset.approve(address(optionMarket), type(uint).max);
  }

  function openPosition(
    OptionMarket optionMarket,
    OptionMarket.TradeInputParameters memory params,
    uint extraCollateral
  ) external returns (OptionMarket.Result memory result) {
    OptionMarketContracts memory c = marketContracts[optionMarket];

    if (params.positionId != 0) {
      c.optionToken.transferFrom(msg.sender, address(this), params.positionId);
    }

    _takeExtraCollateral(c, params.optionType, extraCollateral);

    result = optionMarket.openPosition(params);

    _returnExcessFunds(c);

    c.optionToken.transferFrom(address(this), msg.sender, result.positionId);
  }

  function closePosition(
    OptionMarket optionMarket,
    OptionMarket.TradeInputParameters memory params,
    uint extraCollateral
  ) external returns (OptionMarket.Result memory result) {
    OptionMarketContracts memory c = marketContracts[optionMarket];

    if (params.positionId != 0) {
      c.optionToken.transferFrom(msg.sender, address(this), params.positionId);
    }

    _takeExtraCollateral(c, params.optionType, extraCollateral);

    result = optionMarket.closePosition(params);

    _returnExcessFunds(c);

    if (c.optionToken.getPositionState(result.positionId) == OptionToken.PositionState.ACTIVE) {
      c.optionToken.transferFrom(address(this), msg.sender, params.positionId);
    }
  }

  function forceClosePosition(
    OptionMarket optionMarket,
    OptionMarket.TradeInputParameters memory params,
    uint extraCollateral
  ) external returns (OptionMarket.Result memory result) {
    OptionMarketContracts memory c = marketContracts[optionMarket];

    if (params.positionId != 0) {
      c.optionToken.transferFrom(msg.sender, address(this), params.positionId);
    }

    _takeExtraCollateral(c, params.optionType, extraCollateral);

    result = optionMarket.forceClosePosition(params);

    _returnExcessFunds(c);

    if (c.optionToken.getPositionState(result.positionId) == OptionToken.PositionState.ACTIVE) {
      c.optionToken.transferFrom(address(this), msg.sender, params.positionId);
    }
  }

  function _takeExtraCollateral(
    OptionMarketContracts memory c,
    OptionMarket.OptionType optionType,
    uint extraCollateral
  ) internal {
    if (!_isLong(optionType)) {
      if (extraCollateral != 0) {
        if (_isBaseCollateral(optionType)) {
          require(c.baseAsset.transferFrom(msg.sender, address(this), extraCollateral), "takeExtraCollat: base xfer f");
        } else {
          require(
            c.quoteAsset.transferFrom(msg.sender, address(this), extraCollateral),
            "takeExtraCollat: !base xfer f"
          );
        }
      }
    }
  }

  function _returnExcessFunds(OptionMarketContracts memory c) internal {
    uint quoteBal = c.quoteAsset.balanceOf(address(this));
    if (quoteBal > 0) {
      require(c.quoteAsset.transfer(msg.sender, quoteBal), "_returnExcessFunds: quote xfer f");
    }
    uint baseBal = c.baseAsset.balanceOf(address(this));
    if (baseBal > 0) {
      require(c.baseAsset.transfer(msg.sender, baseBal), "_returnExcessFunds: base xfer f");
    }
  }

  function _isLong(OptionMarket.OptionType optionType) internal pure returns (bool) {
    return (optionType < OptionMarket.OptionType.SHORT_CALL_BASE);
  }

  function _isCall(OptionMarket.OptionType optionType) internal pure returns (bool) {
    return (optionType != OptionMarket.OptionType.SHORT_PUT_QUOTE && optionType != OptionMarket.OptionType.LONG_PUT);
  }

  function _isBaseCollateral(OptionMarket.OptionType optionType) internal pure returns (bool) {
    return (optionType == OptionMarket.OptionType.SHORT_CALL_BASE);
  }
}
