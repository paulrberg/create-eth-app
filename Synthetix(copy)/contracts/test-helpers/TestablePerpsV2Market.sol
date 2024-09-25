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

import "../PerpsV2MarketProxyable.sol";
import "../interfaces/IPerpsV2MarketBaseTypes.sol";

contract TestablePerpsV2Market is PerpsV2MarketProxyable {
    int private constant _UNIT = int(10**uint(18));

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketProxyable(_proxy, _marketState, _owner, _resolver) {}

    function entryDebtCorrection() external view returns (int) {
        return marketState.entryDebtCorrection();
    }

    function proportionalSkew() external view returns (int) {
        return _proportionalSkew();
    }

    /*
     * The maximum size in base units of an order on each side of the market that will not exceed the max market value.
     */
    function maxOrderSizes()
        external
        view
        returns (
            uint long,
            uint short,
            bool invalid
        )
    {
        (, invalid) = _assetPrice();
        int sizeLimit = int(_maxMarketValue(_marketKey()));

        int size = int(marketState.marketSize());
        int skew = marketState.marketSkew();
        (uint longSize, uint shortSize) = (_abs(size.add(skew).div(2)), _abs(size.sub(skew).div(2)));

        long = uint(sizeLimit.sub(_min(int(longSize), sizeLimit)));
        short = uint(sizeLimit.sub(_min(int(shortSize), sizeLimit)));
        return (long, short, invalid);
    }

    /**
     * The minimal margin at which liquidation can happen. Is the sum of liquidationBuffer and liquidationFee.
     * Reverts if position size is 0.
     * @param account address of the position account
     * @return lMargin liquidation margin to maintain in sUSD fixed point decimal units
     */
    function liquidationMargin(address account) external view returns (uint lMargin) {
        (uint price, ) = _assetPrice();
        require(marketState.positions(account).size != 0, "0 size position"); // reverts because otherwise minKeeperFee is returned
        return _liquidationMargin(int(marketState.positions(account).size), price);
    }

    /*
     * Equivalent to the position's notional value divided by its remaining margin.
     */
    function currentLeverage(address account) external view returns (int leverage, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        Position memory position = marketState.positions(account);
        uint remainingMargin_ = _remainingMargin(position, price);
        return (_currentLeverage(position, price, remainingMargin_), isInvalid);
    }

    /*
     * @dev Give the fillPrice given `sizeDelta` and optional `basePrice` with metadata
     *
     * @param sizeDelta size of the position to derive fillPrice
     * @param priceImpactDelta used to compute the desiredPrice given basically slippage/price impact delta
     * @param assetPrice optional asset price if not provided get on-chain price
     */
    function fillPriceWithMeta(
        int sizeDelta,
        uint priceImpactDelta,
        uint assetPrice
    )
        external
        view
        returns (
            uint,
            uint,
            bool
        )
    {
        uint price = assetPrice;
        bool invalid;
        if (assetPrice == 0) {
            (price, invalid) = _assetPrice();
        }

        uint fillPrice = _fillPrice(sizeDelta, price);
        uint desiredFillPrice =
            fillPrice.multiplyDecimal(sizeDelta > 0 ? uint(_UNIT) + priceImpactDelta : uint(_UNIT) - priceImpactDelta);
        return (fillPrice, desiredFillPrice, invalid);
    }

    /* @dev Given an account, find the associated position and return the netFundingPerUnit. */
    function netFundingPerUnit(address account) external view returns (int) {
        (uint price, ) = _assetPrice();
        return _netFundingPerUnit(marketState.positions(account).lastFundingIndex, price);
    }
}
