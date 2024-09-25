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

// Inheritance
import "./Owned.sol";
import "./MixinPerpsV2MarketSettings.sol";

// Internal references
import "./interfaces/IPerpsV2MarketSettings.sol";
import "./interfaces/IFuturesMarketManager.sol";
import "./interfaces/IPerpsV2MarketViews.sol";
import "./interfaces/IPerpsV2Market.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketSettings
contract PerpsV2MarketSettings is Owned, MixinPerpsV2MarketSettings, IPerpsV2MarketSettings {
    /* ========== CONSTANTS ========== */

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 internal constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinPerpsV2MarketSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinPerpsV2MarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }

    /* ---------- Getters ---------- */

    /*
     * The fee charged when opening a position on the heavy side of a perpsV2 market.
     */
    function takerFee(bytes32 _marketKey) external view returns (uint) {
        return _takerFee(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a perpsV2 market.
     */
    function makerFee(bytes32 _marketKey) public view returns (uint) {
        return _makerFee(_marketKey);
    }

    /*
     * The fee charged as commit fee if set. It will override the default calculation if this value is larger than  zero.
     */
    function overrideCommitFee(bytes32 _marketKey) external view returns (uint) {
        return _parameter(_marketKey, PARAMETER_OVERRIDE_COMMIT_FEE);
    }

    /*
     * The fee charged when opening a position on the heavy side of a perpsV2 market using delayed order mechanism.
     */
    function takerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint) {
        return _takerFeeDelayedOrder(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a perpsV2 market using delayed order mechanism.
     */
    function makerFeeDelayedOrder(bytes32 _marketKey) public view returns (uint) {
        return _makerFeeDelayedOrder(_marketKey);
    }

    /*
     * The fee charged when opening a position on the heavy side of a perpsV2 market using offchain delayed order mechanism.
     */
    function takerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint) {
        return _takerFeeOffchainDelayedOrder(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a perpsV2 market using offchain delayed order mechanism.
     */
    function makerFeeOffchainDelayedOrder(bytes32 _marketKey) public view returns (uint) {
        return _makerFeeOffchainDelayedOrder(_marketKey);
    }

    /*
     * The number of price update rounds during which confirming next-price is allowed
     */
    function nextPriceConfirmWindow(bytes32 _marketKey) public view returns (uint) {
        return _nextPriceConfirmWindow(_marketKey);
    }

    /*
     * The amount of time in seconds which confirming delayed orders is allow
     */
    function delayedOrderConfirmWindow(bytes32 _marketKey) public view returns (uint) {
        return _delayedOrderConfirmWindow(_marketKey);
    }

    /*
     * The amount of time in seconds which confirming delayed orders is allow
     */
    function offchainDelayedOrderMinAge(bytes32 _marketKey) public view returns (uint) {
        return _offchainDelayedOrderMinAge(_marketKey);
    }

    /*
     * The amount of time in seconds which confirming delayed orders is allow
     */
    function offchainDelayedOrderMaxAge(bytes32 _marketKey) public view returns (uint) {
        return _offchainDelayedOrderMaxAge(_marketKey);
    }

    /*
     * The maximum allowable leverage in a market.
     */
    function maxLeverage(bytes32 _marketKey) public view returns (uint) {
        return _maxLeverage(_marketKey);
    }

    /*
     * The maximum allowable value (base asset) on each side of a market.
     */
    function maxMarketValue(bytes32 _marketKey) public view returns (uint) {
        return _maxMarketValue(_marketKey);
    }

    /*
     * The skew level at which the max funding velocity will be charged.
     */
    function skewScale(bytes32 _marketKey) public view returns (uint) {
        return _skewScale(_marketKey);
    }

    /*
     * The maximum theoretical funding velocity per day charged by a market.
     */
    function maxFundingVelocity(bytes32 _marketKey) public view returns (uint) {
        return _maxFundingVelocity(_marketKey);
    }

    /*
     * The off-chain delayed order lower bound whereby the desired delta must be greater than or equal to.
     */
    function minDelayTimeDelta(bytes32 _marketKey) public view returns (uint) {
        return _minDelayTimeDelta(_marketKey);
    }

    /*
     * The off-chain delayed order upper bound whereby the desired delta must be greater than or equal to.
     */
    function maxDelayTimeDelta(bytes32 _marketKey) public view returns (uint) {
        return _maxDelayTimeDelta(_marketKey);
    }

    /*
     * The off-chain delayed order market key, used to pause and resume offchain markets.
     */
    function offchainMarketKey(bytes32 _marketKey) public view returns (bytes32) {
        return _offchainMarketKey(_marketKey);
    }

    /*
     * The max divergence between onchain and offchain prices for an offchain delayed order execution.
     */
    function offchainPriceDivergence(bytes32 _marketKey) public view returns (uint) {
        return _offchainPriceDivergence(_marketKey);
    }

    /*
     * The liquidation premium multiplier applied when calculating the liquidation premium margin.
     */
    function liquidationPremiumMultiplier(bytes32 _marketKey) public view returns (uint) {
        return _liquidationPremiumMultiplier(_marketKey);
    }

    function parameters(bytes32 _marketKey) external view returns (Parameters memory) {
        return
            Parameters(
                _takerFee(_marketKey),
                _makerFee(_marketKey),
                _overrideCommitFee(_marketKey),
                _takerFeeDelayedOrder(_marketKey),
                _makerFeeDelayedOrder(_marketKey),
                _takerFeeOffchainDelayedOrder(_marketKey),
                _makerFeeOffchainDelayedOrder(_marketKey),
                _maxLeverage(_marketKey),
                _maxMarketValue(_marketKey),
                _maxFundingVelocity(_marketKey),
                _skewScale(_marketKey),
                _nextPriceConfirmWindow(_marketKey),
                _delayedOrderConfirmWindow(_marketKey),
                _minDelayTimeDelta(_marketKey),
                _maxDelayTimeDelta(_marketKey),
                _offchainDelayedOrderMinAge(_marketKey),
                _offchainDelayedOrderMaxAge(_marketKey),
                _offchainMarketKey(_marketKey),
                _offchainPriceDivergence(_marketKey),
                _liquidationPremiumMultiplier(_marketKey)
            );
    }

    /*
     * The minimum amount of sUSD paid to a liquidator when they successfully liquidate a position.
     * This quantity must be no greater than `minInitialMargin`.
     */
    function minKeeperFee() external view returns (uint) {
        return _minKeeperFee();
    }

    /*
     * The maximum amount of sUSD paid to a liquidator when they successfully liquidate a position.
     */
    function maxKeeperFee() external view returns (uint) {
        return _maxKeeperFee();
    }

    /*
     * Liquidation fee basis points paid to liquidator.
     * Use together with minKeeperFee() and maxKeeperFee() to calculate the actual fee paid.
     */
    function liquidationFeeRatio() external view returns (uint) {
        return _liquidationFeeRatio();
    }

    /*
     * Liquidation price buffer in basis points to prevent negative margin on liquidation.
     */
    function liquidationBufferRatio() external view returns (uint) {
        return _liquidationBufferRatio();
    }

    /*
     * The minimum margin required to open a position.
     * This quantity must be no less than `minKeeperFee`.
     */
    function minInitialMargin() external view returns (uint) {
        return _minInitialMargin();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Setters --------- */

    function _setParameter(
        bytes32 _marketKey,
        bytes32 key,
        uint value
    ) internal {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)), value);
        emit ParameterUpdated(_marketKey, key, value);
    }

    function setTakerFee(bytes32 _marketKey, uint _takerFee) public onlyOwner {
        require(_takerFee <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE, _takerFee);
    }

    function setMakerFee(bytes32 _marketKey, uint _makerFee) public onlyOwner {
        require(_makerFee <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE, _makerFee);
    }

    function setOverrideCommitFee(bytes32 _marketKey, uint _overrideCommitFee) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OVERRIDE_COMMIT_FEE, _overrideCommitFee);
    }

    function setTakerFeeDelayedOrder(bytes32 _marketKey, uint _takerFeeDelayedOrder) public onlyOwner {
        require(_takerFeeDelayedOrder <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE_DELAYED_ORDER, _takerFeeDelayedOrder);
    }

    function setMakerFeeDelayedOrder(bytes32 _marketKey, uint _makerFeeDelayedOrder) public onlyOwner {
        require(_makerFeeDelayedOrder <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE_DELAYED_ORDER, _makerFeeDelayedOrder);
    }

    function setTakerFeeOffchainDelayedOrder(bytes32 _marketKey, uint _takerFeeOffchainDelayedOrder) public onlyOwner {
        require(_takerFeeOffchainDelayedOrder <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE_OFFCHAIN_DELAYED_ORDER, _takerFeeOffchainDelayedOrder);
    }

    function setMakerFeeOffchainDelayedOrder(bytes32 _marketKey, uint _makerFeeOffchainDelayedOrder) public onlyOwner {
        require(_makerFeeOffchainDelayedOrder <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE_OFFCHAIN_DELAYED_ORDER, _makerFeeOffchainDelayedOrder);
    }

    function setNextPriceConfirmWindow(bytes32 _marketKey, uint _nextPriceConfirmWindow) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW, _nextPriceConfirmWindow);
    }

    function setDelayedOrderConfirmWindow(bytes32 _marketKey, uint _delayedOrderConfirmWindow) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_DELAYED_ORDER_CONFIRM_WINDOW, _delayedOrderConfirmWindow);
    }

    function setOffchainDelayedOrderMinAge(bytes32 _marketKey, uint _offchainDelayedOrderMinAge) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MIN_AGE, _offchainDelayedOrderMinAge);
    }

    function setOffchainDelayedOrderMaxAge(bytes32 _marketKey, uint _offchainDelayedOrderMaxAge) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MAX_AGE, _offchainDelayedOrderMaxAge);
    }

    function setMaxLeverage(bytes32 _marketKey, uint _maxLeverage) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_LEVERAGE, _maxLeverage);
    }

    function setMaxMarketValue(bytes32 _marketKey, uint _maxMarketValue) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_MARKET_VALUE, _maxMarketValue);
    }

    // Before altering parameters relevant to funding rates, outstanding funding on the underlying market
    // must be recomputed, otherwise already-accrued but unrealised funding in the market can change.

    function _recomputeFunding(bytes32 _marketKey) internal {
        address marketAddress = _futuresMarketManager().marketForKey(_marketKey);

        IPerpsV2MarketViews marketView = IPerpsV2MarketViews(marketAddress);
        if (marketView.marketSize() > 0) {
            IPerpsV2Market market = IPerpsV2Market(marketAddress);
            // only recompute funding when market has positions, this check is important for initial setup
            market.recomputeFunding();
        }
    }

    function setMaxFundingVelocity(bytes32 _marketKey, uint _maxFundingVelocity) public onlyOwner {
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MAX_FUNDING_VELOCITY, _maxFundingVelocity);
    }

    function setSkewScale(bytes32 _marketKey, uint _skewScale) public onlyOwner {
        require(_skewScale > 0, "cannot set skew scale 0");
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MIN_SKEW_SCALE, _skewScale);
    }

    function setMinDelayTimeDelta(bytes32 _marketKey, uint _minDelayTimeDelta) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MIN_DELAY_TIME_DELTA, _minDelayTimeDelta);
    }

    function setMaxDelayTimeDelta(bytes32 _marketKey, uint _maxDelayTimeDelta) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_DELAY_TIME_DELTA, _maxDelayTimeDelta);
    }

    function setOffchainMarketKey(bytes32 _marketKey, bytes32 _offchainMarketKey) public onlyOwner {
        _flexibleStorage().setBytes32Value(
            SETTING_CONTRACT_NAME,
            keccak256(abi.encodePacked(_marketKey, PARAMETER_OFFCHAIN_MARKET_KEY)),
            _offchainMarketKey
        );
        emit ParameterUpdatedBytes32(_marketKey, PARAMETER_OFFCHAIN_MARKET_KEY, _offchainMarketKey);
    }

    /*
     * The max divergence between onchain and offchain prices for an offchain delayed order execution.
     */
    function setOffchainPriceDivergence(bytes32 _marketKey, uint _offchainPriceDivergence) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OFFCHAIN_PRICE_DIVERGENCE, _offchainPriceDivergence);
    }

    function setLiquidationPremiumMultiplier(bytes32 _marketKey, uint _liquidationPremiumMultiplier) public onlyOwner {
        require(_liquidationPremiumMultiplier > 0, "cannot set liquidation premium multiplier 0");
        _setParameter(_marketKey, PARAMETER_LIQUIDATION_PREMIUM_MULTIPLIER, _liquidationPremiumMultiplier);
    }

    function setParameters(bytes32 _marketKey, Parameters calldata _parameters) external onlyOwner {
        _recomputeFunding(_marketKey);
        setTakerFee(_marketKey, _parameters.takerFee);
        setMakerFee(_marketKey, _parameters.makerFee);
        setOverrideCommitFee(_marketKey, _parameters.overrideCommitFee);
        setMaxLeverage(_marketKey, _parameters.maxLeverage);
        setMaxMarketValue(_marketKey, _parameters.maxMarketValue);
        setMaxFundingVelocity(_marketKey, _parameters.maxFundingVelocity);
        setSkewScale(_marketKey, _parameters.skewScale);
        setTakerFeeDelayedOrder(_marketKey, _parameters.takerFeeDelayedOrder);
        setMakerFeeDelayedOrder(_marketKey, _parameters.makerFeeDelayedOrder);
        setNextPriceConfirmWindow(_marketKey, _parameters.nextPriceConfirmWindow);
        setDelayedOrderConfirmWindow(_marketKey, _parameters.delayedOrderConfirmWindow);
        setMinDelayTimeDelta(_marketKey, _parameters.minDelayTimeDelta);
        setMaxDelayTimeDelta(_marketKey, _parameters.maxDelayTimeDelta);
        setTakerFeeOffchainDelayedOrder(_marketKey, _parameters.takerFeeOffchainDelayedOrder);
        setMakerFeeOffchainDelayedOrder(_marketKey, _parameters.makerFeeOffchainDelayedOrder);
        setOffchainDelayedOrderMinAge(_marketKey, _parameters.offchainDelayedOrderMinAge);
        setOffchainDelayedOrderMaxAge(_marketKey, _parameters.offchainDelayedOrderMaxAge);
        setOffchainMarketKey(_marketKey, _parameters.offchainMarketKey);
        setOffchainPriceDivergence(_marketKey, _parameters.offchainPriceDivergence);
        setLiquidationPremiumMultiplier(_marketKey, _parameters.liquidationPremiumMultiplier);
    }

    function setMinKeeperFee(uint _sUSD) external onlyOwner {
        require(_sUSD <= _minInitialMargin(), "min margin < liquidation fee");
        if (_maxKeeperFee() > 0) {
            // only check if already set
            require(_sUSD <= _maxKeeperFee(), "max fee < min fee");
        }
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE, _sUSD);
        emit MinKeeperFeeUpdated(_sUSD);
    }

    function setMaxKeeperFee(uint _sUSD) external onlyOwner {
        require(_sUSD >= _minKeeperFee(), "max fee < min fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MAX_KEEPER_FEE, _sUSD);
        emit MaxKeeperFeeUpdated(_sUSD);
    }

    function setLiquidationFeeRatio(uint _ratio) external onlyOwner {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO, _ratio);
        emit LiquidationFeeRatioUpdated(_ratio);
    }

    function setLiquidationBufferRatio(uint _ratio) external onlyOwner {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_BUFFER_RATIO, _ratio);
        emit LiquidationBufferRatioUpdated(_ratio);
    }

    function setMinInitialMargin(uint _minMargin) external onlyOwner {
        require(_minKeeperFee() <= _minMargin, "min margin < liquidation fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN, _minMargin);
        emit MinInitialMarginUpdated(_minMargin);
    }

    /* ========== EVENTS ========== */

    event ParameterUpdated(bytes32 indexed marketKey, bytes32 indexed parameter, uint value);
    event ParameterUpdatedBytes32(bytes32 indexed marketKey, bytes32 indexed parameter, bytes32 value);
    event MinKeeperFeeUpdated(uint sUSD);
    event MaxKeeperFeeUpdated(uint sUSD);
    event LiquidationFeeRatioUpdated(uint bps);
    event LiquidationBufferRatioUpdated(uint bps);
    event MinInitialMarginUpdated(uint minMargin);
}
