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

// Inheritance
import "./Owned.sol";
import "./MixinFuturesMarketSettings.sol";

// Internal references
import "./interfaces/IFuturesMarketSettings.sol";
import "./interfaces/IFuturesMarketManager.sol";
import "./interfaces/IFuturesMarket.sol";

// https://docs.synthetix.io/contracts/source/contracts/FuturesMarketSettings
contract FuturesMarketSettings is Owned, MixinFuturesMarketSettings, IFuturesMarketSettings {
    /* ========== CONSTANTS ========== */

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 internal constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinFuturesMarketSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinFuturesMarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }

    /* ---------- Getters ---------- */

    /*
     * The fee charged when opening a position on the heavy side of a futures market.
     */
    function takerFee(bytes32 _marketKey) external view returns (uint) {
        return _takerFee(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a futures market.
     */
    function makerFee(bytes32 _marketKey) public view returns (uint) {
        return _makerFee(_marketKey);
    }

    /*
     * The fee charged when opening a position on the heavy side of a futures market using next price mechanism.
     */
    function takerFeeNextPrice(bytes32 _marketKey) external view returns (uint) {
        return _takerFeeNextPrice(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a futures market using next price mechanism.
     */
    function makerFeeNextPrice(bytes32 _marketKey) public view returns (uint) {
        return _makerFeeNextPrice(_marketKey);
    }

    /*
     * The number of price update rounds during which confirming next-price is allowed
     */
    function nextPriceConfirmWindow(bytes32 _marketKey) public view returns (uint) {
        return _nextPriceConfirmWindow(_marketKey);
    }

    /*
     * The maximum allowable leverage in a market.
     */
    function maxLeverage(bytes32 _marketKey) public view returns (uint) {
        return _maxLeverage(_marketKey);
    }

    /*
     * The maximum allowable notional value on each side of a market.
     */
    function maxMarketValueUSD(bytes32 _marketKey) public view returns (uint) {
        return _maxMarketValueUSD(_marketKey);
    }

    /*
     * The maximum theoretical funding rate per day charged by a market.
     */
    function maxFundingRate(bytes32 _marketKey) public view returns (uint) {
        return _maxFundingRate(_marketKey);
    }

    /*
     * The skew level at which the max funding rate will be charged.
     */
    function skewScaleUSD(bytes32 _marketKey) public view returns (uint) {
        return _skewScaleUSD(_marketKey);
    }

    function parameters(bytes32 _marketKey)
        external
        view
        returns (
            uint takerFee,
            uint makerFee,
            uint takerFeeNextPrice,
            uint makerFeeNextPrice,
            uint nextPriceConfirmWindow,
            uint maxLeverage,
            uint maxMarketValueUSD,
            uint maxFundingRate,
            uint skewScaleUSD
        )
    {
        takerFee = _takerFee(_marketKey);
        makerFee = _makerFee(_marketKey);
        takerFeeNextPrice = _takerFeeNextPrice(_marketKey);
        makerFeeNextPrice = _makerFeeNextPrice(_marketKey);
        nextPriceConfirmWindow = _nextPriceConfirmWindow(_marketKey);
        maxLeverage = _maxLeverage(_marketKey);
        maxMarketValueUSD = _maxMarketValueUSD(_marketKey);
        maxFundingRate = _maxFundingRate(_marketKey);
        skewScaleUSD = _skewScaleUSD(_marketKey);
    }

    /*
     * The minimum amount of sUSD paid to a liquidator when they successfully liquidate a position.
     * This quantity must be no greater than `minInitialMargin`.
     */
    function minKeeperFee() external view returns (uint) {
        return _minKeeperFee();
    }

    /*
     * Liquidation fee basis points paid to liquidator.
     * Use together with minKeeperFee() to calculate the actual fee paid.
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

    function setTakerFeeNextPrice(bytes32 _marketKey, uint _takerFeeNextPrice) public onlyOwner {
        require(_takerFeeNextPrice <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE_NEXT_PRICE, _takerFeeNextPrice);
    }

    function setMakerFeeNextPrice(bytes32 _marketKey, uint _makerFeeNextPrice) public onlyOwner {
        require(_makerFeeNextPrice <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE_NEXT_PRICE, _makerFeeNextPrice);
    }

    function setNextPriceConfirmWindow(bytes32 _marketKey, uint _nextPriceConfirmWindow) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW, _nextPriceConfirmWindow);
    }

    function setMaxLeverage(bytes32 _marketKey, uint _maxLeverage) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_LEVERAGE, _maxLeverage);
    }

    function setMaxMarketValueUSD(bytes32 _marketKey, uint _maxMarketValueUSD) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_MARKET_VALUE, _maxMarketValueUSD);
    }

    // Before altering parameters relevant to funding rates, outstanding funding on the underlying market
    // must be recomputed, otherwise already-accrued but unrealised funding in the market can change.

    function _recomputeFunding(bytes32 _marketKey) internal {
        IFuturesMarket market = IFuturesMarket(_futuresMarketManager().marketForKey(_marketKey));
        if (market.marketSize() > 0) {
            // only recompute funding when market has positions, this check is important for initial setup
            market.recomputeFunding();
        }
    }

    function setMaxFundingRate(bytes32 _marketKey, uint _maxFundingRate) public onlyOwner {
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MAX_FUNDING_RATE, _maxFundingRate);
    }

    function setSkewScaleUSD(bytes32 _marketKey, uint _skewScaleUSD) public onlyOwner {
        require(_skewScaleUSD > 0, "cannot set skew scale 0");
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MIN_SKEW_SCALE, _skewScaleUSD);
    }

    function setParameters(
        bytes32 _marketKey,
        uint _takerFee,
        uint _makerFee,
        uint _takerFeeNextPrice,
        uint _makerFeeNextPrice,
        uint _nextPriceConfirmWindow,
        uint _maxLeverage,
        uint _maxMarketValueUSD,
        uint _maxFundingRate,
        uint _skewScaleUSD
    ) external onlyOwner {
        _recomputeFunding(_marketKey);
        setTakerFee(_marketKey, _takerFee);
        setMakerFee(_marketKey, _makerFee);
        setTakerFeeNextPrice(_marketKey, _takerFeeNextPrice);
        setMakerFeeNextPrice(_marketKey, _makerFeeNextPrice);
        setNextPriceConfirmWindow(_marketKey, _nextPriceConfirmWindow);
        setMaxLeverage(_marketKey, _maxLeverage);
        setMaxMarketValueUSD(_marketKey, _maxMarketValueUSD);
        setMaxFundingRate(_marketKey, _maxFundingRate);
        setSkewScaleUSD(_marketKey, _skewScaleUSD);
    }

    function setMinKeeperFee(uint _sUSD) external onlyOwner {
        require(_sUSD <= _minInitialMargin(), "min margin < liquidation fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE, _sUSD);
        emit MinKeeperFeeUpdated(_sUSD);
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
    event MinKeeperFeeUpdated(uint sUSD);
    event LiquidationFeeRatioUpdated(uint bps);
    event LiquidationBufferRatioUpdated(uint bps);
    event MinInitialMarginUpdated(uint minMargin);
}
