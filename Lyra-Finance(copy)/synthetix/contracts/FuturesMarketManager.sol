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
import "./MixinResolver.sol";
import "./interfaces/IFuturesMarketManager.sol";

// Libraries
import "Lyra-Finance/openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./AddressSetLib.sol";

// Internal references
import "./interfaces/ISynth.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IERC20.sol";

// basic views that are expected to be supported by v1 (IFuturesMarket) and v2 (via ProxyPerpsV2)
interface IMarketViews {
    function marketKey() external view returns (bytes32);

    function baseAsset() external view returns (bytes32);

    function marketSize() external view returns (uint128);

    function marketSkew() external view returns (int128);

    function assetPrice() external view returns (uint price, bool invalid);

    function marketDebt() external view returns (uint debt, bool isInvalid);

    function currentFundingRate() external view returns (int fundingRate);

    // v1 does not have a this so we never call it but this is here for v2.
    function currentFundingVelocity() external view returns (int fundingVelocity);

    // only supported by PerpsV2 Markets (and implemented in ProxyPerpsV2)
    function getAllTargets() external view returns (address[] memory);
}

// https://docs.synthetix.io/contracts/source/contracts/FuturesMarketManager
contract FuturesMarketManager is Owned, MixinResolver, IFuturesMarketManager {
    using SafeMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;

    /* ========== STATE VARIABLES ========== */

    AddressSetLib.AddressSet internal _allMarkets;
    AddressSetLib.AddressSet internal _legacyMarkets;
    AddressSetLib.AddressSet internal _proxiedMarkets;
    mapping(bytes32 => address) public marketForKey;

    // PerpsV2 implementations
    AddressSetLib.AddressSet internal _implementations;
    mapping(address => address[]) internal _marketImplementation;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 public constant CONTRACT_NAME = "FuturesMarketManager";

    bytes32 internal constant SUSD = "sUSD";
    bytes32 internal constant CONTRACT_SYNTHSUSD = "SynthsUSD";
    bytes32 internal constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_SYNTHSUSD;
        addresses[1] = CONTRACT_FEEPOOL;
        addresses[2] = CONTRACT_EXCHANGER;
    }

    function _sUSD() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTHSUSD));
    }

    function _feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    /*
     * Returns slices of the list of all markets.
     */
    function markets(uint index, uint pageSize) external view returns (address[] memory) {
        return _allMarkets.getPage(index, pageSize);
    }

    /*
     * Returns slices of the list of all v1 or v2 (proxied) markets.
     */
    function markets(
        uint index,
        uint pageSize,
        bool proxiedMarkets
    ) external view returns (address[] memory) {
        if (proxiedMarkets) {
            return _proxiedMarkets.getPage(index, pageSize);
        } else {
            return _legacyMarkets.getPage(index, pageSize);
        }
    }

    /*
     * The number of proxied + legacy markets known to the manager.
     */
    function numMarkets() external view returns (uint) {
        return _allMarkets.elements.length;
    }

    /*
     * The number of proxied or legacy markets known to the manager.
     */
    function numMarkets(bool proxiedMarkets) external view returns (uint) {
        if (proxiedMarkets) {
            return _proxiedMarkets.elements.length;
        } else {
            return _legacyMarkets.elements.length;
        }
    }

    /*
     * The list of all proxied AND legacy markets.
     */
    function allMarkets() public view returns (address[] memory) {
        return _allMarkets.getPage(0, _allMarkets.elements.length);
    }

    /*
     * The list of all proxied OR legacy markets.
     */
    function allMarkets(bool proxiedMarkets) public view returns (address[] memory) {
        if (proxiedMarkets) {
            return _proxiedMarkets.getPage(0, _proxiedMarkets.elements.length);
        } else {
            return _legacyMarkets.getPage(0, _legacyMarkets.elements.length);
        }
    }

    function _marketsForKeys(bytes32[] memory marketKeys) internal view returns (address[] memory) {
        uint mMarkets = marketKeys.length;
        address[] memory results = new address[](mMarkets);
        for (uint i; i < mMarkets; i++) {
            results[i] = marketForKey[marketKeys[i]];
        }
        return results;
    }

    /*
     * The market addresses for a given set of market key strings.
     */
    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory) {
        return _marketsForKeys(marketKeys);
    }

    /*
     * The accumulated debt contribution of all futures markets.
     */
    function totalDebt() external view returns (uint debt, bool isInvalid) {
        uint total;
        bool anyIsInvalid;
        uint numOfMarkets = _allMarkets.elements.length;
        for (uint i = 0; i < numOfMarkets; i++) {
            (uint marketDebt, bool invalid) = IMarketViews(_allMarkets.elements[i]).marketDebt();
            total = total.add(marketDebt);
            anyIsInvalid = anyIsInvalid || invalid;
        }
        return (total, anyIsInvalid);
    }

    struct MarketSummary {
        address market;
        bytes32 asset;
        bytes32 marketKey;
        uint price;
        uint marketSize;
        int marketSkew;
        uint marketDebt;
        int currentFundingRate;
        int currentFundingVelocity;
        bool priceInvalid;
        bool proxied;
    }

    function _marketSummaries(address[] memory addresses) internal view returns (MarketSummary[] memory) {
        uint nMarkets = addresses.length;
        MarketSummary[] memory summaries = new MarketSummary[](nMarkets);
        for (uint i; i < nMarkets; i++) {
            IMarketViews market = IMarketViews(addresses[i]);
            bytes32 marketKey = market.marketKey();
            bytes32 baseAsset = market.baseAsset();

            (uint price, bool invalid) = market.assetPrice();
            (uint debt, ) = market.marketDebt();

            bool proxied = _proxiedMarkets.contains(addresses[i]);
            summaries[i] = MarketSummary({
                market: address(market),
                asset: baseAsset,
                marketKey: marketKey,
                price: price,
                marketSize: market.marketSize(),
                marketSkew: market.marketSkew(),
                marketDebt: debt,
                currentFundingRate: market.currentFundingRate(),
                currentFundingVelocity: proxied ? market.currentFundingVelocity() : 0, // v1 does not have velocity.
                priceInvalid: invalid,
                proxied: proxied
            });
        }

        return summaries;
    }

    function marketSummaries(address[] calldata addresses) external view returns (MarketSummary[] memory) {
        return _marketSummaries(addresses);
    }

    function marketSummariesForKeys(bytes32[] calldata marketKeys) external view returns (MarketSummary[] memory) {
        return _marketSummaries(_marketsForKeys(marketKeys));
    }

    function allMarketSummaries() external view returns (MarketSummary[] memory) {
        return _marketSummaries(allMarkets());
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _addImplementations(address market) internal {
        address[] memory implementations = IMarketViews(market).getAllTargets();
        for (uint i = 0; i < implementations.length; i++) {
            _implementations.add(implementations[i]);
        }
        _marketImplementation[market] = implementations;
    }

    function _removeImplementations(address market) internal {
        address[] memory implementations = _marketImplementation[market];
        for (uint i = 0; i < implementations.length; i++) {
            if (_implementations.contains(implementations[i])) {
                _implementations.remove(implementations[i]);
            }
        }
        delete _marketImplementation[market];
    }

    /*
     * Add a set of new markets. Reverts if some market key already has a market.
     */
    function addMarkets(address[] calldata marketsToAdd) external onlyOwner {
        uint numOfMarkets = marketsToAdd.length;
        for (uint i; i < numOfMarkets; i++) {
            _addMarket(marketsToAdd[i], false);
        }
    }

    /*
     * Add a set of new markets. Reverts if some market key already has a market.
     */
    function addProxiedMarkets(address[] calldata marketsToAdd) external onlyOwner {
        uint numOfMarkets = marketsToAdd.length;
        for (uint i; i < numOfMarkets; i++) {
            _addMarket(marketsToAdd[i], true);
        }
    }

    /*
     * Add a set of new markets. Reverts if some market key already has a market.
     */
    function _addMarket(address market, bool isProxied) internal onlyOwner {
        require(!_allMarkets.contains(market), "Market already exists");
        bytes32 key = IMarketViews(market).marketKey();
        bytes32 baseAsset = IMarketViews(market).baseAsset();

        require(marketForKey[key] == address(0), "Market already exists for key");
        marketForKey[key] = market;
        _allMarkets.add(market);

        if (isProxied) {
            _proxiedMarkets.add(market);
            // if PerpsV2 market => add implementations
            _addImplementations(market);
        } else {
            _legacyMarkets.add(market);
        }

        // Emit the event
        emit MarketAdded(market, baseAsset, key);
    }

    function _removeMarkets(address[] memory marketsToRemove) internal {
        uint numOfMarkets = marketsToRemove.length;
        for (uint i; i < numOfMarkets; i++) {
            address market = marketsToRemove[i];
            require(market != address(0), "Unknown market");

            bytes32 key = IMarketViews(market).marketKey();
            bytes32 baseAsset = IMarketViews(market).baseAsset();

            require(marketForKey[key] != address(0), "Unknown market");

            // if PerpsV2 market => remove implementations
            if (_proxiedMarkets.contains(market)) {
                _removeImplementations(market);
                _proxiedMarkets.remove(market);
            } else {
                _legacyMarkets.remove(market);
            }

            delete marketForKey[key];
            _allMarkets.remove(market);
            emit MarketRemoved(market, baseAsset, key);
        }
    }

    /*
     * Remove a set of markets. Reverts if any market is not known to the manager.
     */
    function removeMarkets(address[] calldata marketsToRemove) external onlyOwner {
        return _removeMarkets(marketsToRemove);
    }

    /*
     * Remove the markets for a given set of market keys. Reverts if any key has no associated market.
     */
    function removeMarketsByKey(bytes32[] calldata marketKeysToRemove) external onlyOwner {
        _removeMarkets(_marketsForKeys(marketKeysToRemove));
    }

    function updateMarketsImplementations(address[] calldata marketsToUpdate) external onlyOwner {
        uint numOfMarkets = marketsToUpdate.length;
        for (uint i; i < numOfMarkets; i++) {
            address market = marketsToUpdate[i];
            require(market != address(0), "Invalid market");
            require(_allMarkets.contains(market), "Unknown market");

            // Remove old implementations
            _removeImplementations(market);

            // Pull new implementations
            _addImplementations(market);
        }
    }

    /*
     * Allows a market to issue sUSD to an account when it withdraws margin.
     * This function is not callable through the proxy, only underlying contracts interact;
     * it reverts if not called by a known market.
     */
    function issueSUSD(address account, uint amount) external onlyMarketImplementations {
        // No settlement is required to issue synths into the target account.
        _sUSD().issue(account, amount);
    }

    /*
     * Allows a market to burn sUSD from an account when it deposits margin.
     * This function is not callable through the proxy, only underlying contracts interact;
     * it reverts if not called by a known market.
     */
    function burnSUSD(address account, uint amount) external onlyMarketImplementations returns (uint postReclamationAmount) {
        // We'll settle first, in order to ensure the user has sufficient balance.
        // If the settlement reduces the user's balance below the requested amount,
        // the settled remainder will be the resulting deposit.

        // Exchanger.settle ensures synth is active
        ISynth sUSD = _sUSD();
        (uint reclaimed, , ) = _exchanger().settle(account, SUSD);

        uint balanceAfter = amount;
        if (0 < reclaimed) {
            balanceAfter = IERC20(address(sUSD)).balanceOf(account);
        }

        // Reduce the value to burn if balance is insufficient after reclamation
        amount = balanceAfter < amount ? balanceAfter : amount;

        sUSD.burn(account, amount);

        return amount;
    }

    /**
     * Allows markets to issue exchange fees into the fee pool and notify it that this occurred.
     * This function is not callable through the proxy, only underlying contracts interact;
     * it reverts if not called by a known market.
     */
    function payFee(uint amount, bytes32 trackingCode) external onlyMarketImplementations {
        _payFee(amount, trackingCode);
    }

    // backwards compatibility with futures v1
    function payFee(uint amount) external onlyMarketImplementations {
        _payFee(amount, bytes32(0));
    }

    function _payFee(uint amount, bytes32 trackingCode) internal {
        delete trackingCode; // unused for now, will be used SIP 203
        IFeePool pool = _feePool();
        _sUSD().issue(pool.FEE_ADDRESS(), amount);
        pool.recordFeePaid(amount);
    }

    /* ========== MODIFIERS ========== */

    function _requireIsMarketOrImplementation() internal view {
        require(
            _legacyMarkets.contains(msg.sender) || _implementations.contains(msg.sender),
            "Permitted only for market implementations"
        );
    }

    modifier onlyMarketImplementations() {
        _requireIsMarketOrImplementation();
        _;
    }

    /* ========== EVENTS ========== */

    event MarketAdded(address market, bytes32 indexed asset, bytes32 indexed marketKey);

    event MarketRemoved(address market, bytes32 indexed asset, bytes32 indexed marketKey);
}
