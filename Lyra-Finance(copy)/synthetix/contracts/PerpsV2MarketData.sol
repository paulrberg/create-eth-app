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
  
  pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Internal references
import "./interfaces/IFuturesMarketManager.sol";
import "./interfaces/IPerpsV2MarketViews.sol";
import "./interfaces/IPerpsV2MarketBaseTypes.sol";
import "./interfaces/IPerpsV2MarketSettings.sol";
import "./interfaces/IAddressResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketData
// A utility contract to allow the front end to query market data in a single call.
contract PerpsV2MarketData {
    /* ========== TYPES ========== */

    struct FuturesGlobals {
        uint minInitialMargin;
        uint liquidationFeeRatio;
        uint liquidationBufferRatio;
        uint minKeeperFee;
        uint maxKeeperFee;
    }

    struct MarketSummary {
        address market;
        bytes32 asset;
        bytes32 key;
        uint maxLeverage;
        uint price;
        uint marketSize;
        int marketSkew;
        uint marketDebt;
        int currentFundingRate;
        int currentFundingVelocity;
        FeeRates feeRates;
    }

    struct MarketLimits {
        uint maxLeverage;
        uint maxMarketValue;
    }

    struct Sides {
        uint long;
        uint short;
    }

    struct MarketSizeDetails {
        uint marketSize;
        PerpsV2MarketData.Sides sides;
        uint marketDebt;
        int marketSkew;
    }

    struct PriceDetails {
        uint price;
        bool invalid;
    }

    struct FundingParameters {
        uint maxFundingVelocity;
        uint skewScale;
    }

    struct FeeRates {
        uint takerFee;
        uint makerFee;
        uint takerFeeDelayedOrder;
        uint makerFeeDelayedOrder;
        uint takerFeeOffchainDelayedOrder;
        uint makerFeeOffchainDelayedOrder;
        uint overrideCommitFee;
    }

    struct FundingDetails {
        int currentFundingRate;
        int unrecordedFunding;
        uint fundingLastRecomputed;
    }

    struct MarketData {
        address market;
        bytes32 baseAsset;
        bytes32 marketKey;
        PerpsV2MarketData.FeeRates feeRates;
        PerpsV2MarketData.MarketLimits limits;
        PerpsV2MarketData.FundingParameters fundingParameters;
        PerpsV2MarketData.MarketSizeDetails marketSizeDetails;
        PerpsV2MarketData.PriceDetails priceDetails;
    }

    struct PositionData {
        IPerpsV2MarketBaseTypes.Position position;
        int notionalValue;
        int profitLoss;
        int accruedFunding;
        uint remainingMargin;
        uint accessibleMargin;
        uint liquidationPrice;
        bool canLiquidatePosition;
    }

    /* ========== STORAGE VARIABLES ========== */

    IAddressResolver public resolverProxy;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _resolverProxy) public {
        resolverProxy = _resolverProxy;
    }

    /* ========== VIEWS ========== */

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return
            IFuturesMarketManager(
                resolverProxy.requireAndGetAddress("FuturesMarketManager", "Missing FuturesMarketManager Address")
            );
    }

    function _perpsV2MarketSettings() internal view returns (IPerpsV2MarketSettings) {
        return
            IPerpsV2MarketSettings(
                resolverProxy.requireAndGetAddress("PerpsV2MarketSettings", "Missing PerpsV2MarketSettings Address")
            );
    }

    function globals() external view returns (FuturesGlobals memory) {
        IPerpsV2MarketSettings settings = _perpsV2MarketSettings();
        return
            FuturesGlobals({
                minInitialMargin: settings.minInitialMargin(),
                liquidationFeeRatio: settings.liquidationFeeRatio(),
                liquidationBufferRatio: settings.liquidationBufferRatio(),
                minKeeperFee: settings.minKeeperFee(),
                maxKeeperFee: settings.maxKeeperFee()
            });
    }

    function parameters(bytes32 marketKey) external view returns (IPerpsV2MarketSettings.Parameters memory) {
        return _parameters(marketKey);
    }

    function _parameters(bytes32 marketKey) internal view returns (IPerpsV2MarketSettings.Parameters memory) {
        return _perpsV2MarketSettings().parameters(marketKey);
    }

    function _marketSummaries(address[] memory markets) internal view returns (MarketSummary[] memory) {
        uint numMarkets = markets.length;
        MarketSummary[] memory summaries = new MarketSummary[](numMarkets);
        for (uint i; i < numMarkets; i++) {
            IPerpsV2MarketViews market = IPerpsV2MarketViews(markets[i]);
            bytes32 marketKey = market.marketKey();
            bytes32 baseAsset = market.baseAsset();
            IPerpsV2MarketSettings.Parameters memory params = _parameters(marketKey);

            (uint price, ) = market.assetPrice();
            (uint debt, ) = market.marketDebt();

            summaries[i] = MarketSummary(
                address(market),
                baseAsset,
                marketKey,
                params.maxLeverage,
                price,
                market.marketSize(),
                market.marketSkew(),
                debt,
                market.currentFundingRate(),
                market.currentFundingVelocity(),
                FeeRates(
                    params.takerFee,
                    params.makerFee,
                    params.takerFeeDelayedOrder,
                    params.makerFeeDelayedOrder,
                    params.takerFeeOffchainDelayedOrder,
                    params.makerFeeOffchainDelayedOrder,
                    params.overrideCommitFee
                )
            );
        }

        return summaries;
    }

    function marketSummaries(address[] calldata markets) external view returns (MarketSummary[] memory) {
        return _marketSummaries(markets);
    }

    function marketSummariesForKeys(bytes32[] calldata marketKeys) external view returns (MarketSummary[] memory) {
        return _marketSummaries(_futuresMarketManager().marketsForKeys(marketKeys));
    }

    function allMarketSummaries() external view returns (MarketSummary[] memory) {
        return _marketSummaries(_futuresMarketManager().allMarkets());
    }

    function allProxiedMarketSummaries() external view returns (MarketSummary[] memory) {
        return _marketSummaries(_futuresMarketManager().allMarkets(true));
    }

    function _fundingParameters(IPerpsV2MarketSettings.Parameters memory params)
        internal
        pure
        returns (FundingParameters memory)
    {
        return FundingParameters(params.maxFundingVelocity, params.skewScale);
    }

    function _marketSizes(IPerpsV2MarketViews market) internal view returns (Sides memory) {
        (uint long, uint short) = market.marketSizes();
        return Sides(long, short);
    }

    function _marketDetails(IPerpsV2MarketViews market) internal view returns (MarketData memory) {
        (uint price, bool invalid) = market.assetPrice();
        (uint marketDebt, ) = market.marketDebt();
        bytes32 baseAsset = market.baseAsset();
        bytes32 marketKey = market.marketKey();

        IPerpsV2MarketSettings.Parameters memory params = _parameters(marketKey);

        return
            MarketData(
                address(market),
                baseAsset,
                marketKey,
                FeeRates(
                    params.takerFee,
                    params.makerFee,
                    params.takerFeeDelayedOrder,
                    params.makerFeeDelayedOrder,
                    params.takerFeeOffchainDelayedOrder,
                    params.makerFeeOffchainDelayedOrder,
                    params.overrideCommitFee
                ),
                MarketLimits(params.maxLeverage, params.maxMarketValue),
                _fundingParameters(params),
                MarketSizeDetails(market.marketSize(), _marketSizes(market), marketDebt, market.marketSkew()),
                PriceDetails(price, invalid)
            );
    }

    function marketDetails(IPerpsV2MarketViews market) external view returns (MarketData memory) {
        return _marketDetails(market);
    }

    function marketDetailsForKey(bytes32 marketKey) external view returns (MarketData memory) {
        return _marketDetails(IPerpsV2MarketViews(_futuresMarketManager().marketForKey(marketKey)));
    }

    function _position(IPerpsV2MarketViews market, address account)
        internal
        view
        returns (IPerpsV2MarketBaseTypes.Position memory)
    {
        return market.positions(account);
    }

    function _notionalValue(IPerpsV2MarketViews market, address account) internal view returns (int) {
        (int value, ) = market.notionalValue(account);
        return value;
    }

    function _profitLoss(IPerpsV2MarketViews market, address account) internal view returns (int) {
        (int value, ) = market.profitLoss(account);
        return value;
    }

    function _accruedFunding(IPerpsV2MarketViews market, address account) internal view returns (int) {
        (int value, ) = market.accruedFunding(account);
        return value;
    }

    function _remainingMargin(IPerpsV2MarketViews market, address account) internal view returns (uint) {
        (uint value, ) = market.remainingMargin(account);
        return value;
    }

    function _accessibleMargin(IPerpsV2MarketViews market, address account) internal view returns (uint) {
        (uint value, ) = market.accessibleMargin(account);
        return value;
    }

    function _liquidationPrice(IPerpsV2MarketViews market, address account) internal view returns (uint) {
        (uint liquidationPrice, ) = market.liquidationPrice(account);
        return liquidationPrice;
    }

    function _positionDetails(IPerpsV2MarketViews market, address account) internal view returns (PositionData memory) {
        return
            PositionData(
                _position(market, account),
                _notionalValue(market, account),
                _profitLoss(market, account),
                _accruedFunding(market, account),
                _remainingMargin(market, account),
                _accessibleMargin(market, account),
                _liquidationPrice(market, account),
                market.canLiquidate(account)
            );
    }

    function positionDetails(IPerpsV2MarketViews market, address account) external view returns (PositionData memory) {
        return _positionDetails(market, account);
    }

    function positionDetailsForMarketKey(bytes32 marketKey, address account) external view returns (PositionData memory) {
        return _positionDetails(IPerpsV2MarketViews(_futuresMarketManager().marketForKey(marketKey)), account);
    }
}
