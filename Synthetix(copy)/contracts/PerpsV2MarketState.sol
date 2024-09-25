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

// Inheritance
import "./interfaces/IPerpsV2MarketBaseTypes.sol";
import "./PerpsV2MarketStateLegacyR1.sol";
import "./Owned.sol";
import "./StateShared.sol";

// Libraries
import "./AddressSetLib.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketState
// solhint-disable-next-line max-states-count
contract PerpsV2MarketState is Owned, StateShared, IPerpsV2MarketBaseTypes {
    using AddressSetLib for AddressSetLib.AddressSet;

    // Legacy state link
    bool public initialized;
    uint public legacyFundinSequenceOffset;
    PerpsV2MarketStateLegacyR1 public legacyState;
    bool private _legacyContractExists;
    mapping(address => bool) internal _positionMigrated;
    mapping(address => bool) internal _delayedOrderMigrated;

    // The market identifier in the perpsV2 system (manager + settings). Multiple markets can co-exist
    // for the same asset in order to allow migrations.
    bytes32 public marketKey;

    // The asset being traded in this market. This should be a valid key into the ExchangeRates contract.
    bytes32 public baseAsset;

    // The total number of base units in long and short positions.
    uint128 public marketSize;

    /*
     * The net position in base units of the whole market.
     * When this is positive, longs outweigh shorts. When it is negative, shorts outweigh longs.
     */
    int128 public marketSkew;

    /*
     * This holds the value: sum_{p in positions}{p.margin - p.size * (p.lastPrice + fundingSequence[p.lastFundingIndex])}
     * Then marketSkew * (price + _nextFundingEntry()) + _entryDebtCorrection yields the total system debt,
     * which is equivalent to the sum of remaining margins in all positions.
     */
    int128 internal _entryDebtCorrection;

    /*
     * The funding sequence allows constant-time calculation of the funding owed to a given position.
     * Each entry in the sequence holds the net funding accumulated per base unit since the market was created.
     * Then to obtain the net funding over a particular interval, subtract the start point's sequence entry
     * from the end point's sequence entry.
     * Positions contain the funding sequence entry at the time they were confirmed; so to compute
     * the net funding on a given position, obtain from this sequence the net funding per base unit
     * since the position was confirmed and multiply it by the position size.
     */
    uint32 public fundingLastRecomputed;
    int128[] internal _fundingSequence;

    /*
     * The funding rate last time it was recomputed. The market funding rate floats and requires the previously
     * calculated funding rate, time, and current market conditions to derive the next.
     */
    int128 public fundingRateLastRecomputed;

    /*
     * Each user's position. Multiple positions can always be merged, so each user has
     * only have one position at a time.
     */
    mapping(address => Position) internal _positions;

    // The set of all addresses (positions) .
    AddressSetLib.AddressSet internal _positionAddresses;

    // The set of all addresses (delayedOrders) .
    AddressSetLib.AddressSet internal _delayedOrderAddresses;

    // This increments for each position; zero reflects a position that does not exist.
    uint64 internal _nextPositionId = 1;

    /// @dev Holds a mapping of accounts to orders. Only one order per account is supported
    mapping(address => DelayedOrder) internal _delayedOrders;

    /// @dev Holds a mapping of accounts to flagger address to flag an account. Only one order per account is supported
    mapping(address => address) public positionFlagger;
    AddressSetLib.AddressSet internal _flaggedAddresses;

    constructor(
        address _owner,
        address[] memory _associatedContracts,
        bytes32 _baseAsset,
        bytes32 _marketKey,
        address _legacyState
    ) public Owned(_owner) StateShared(_associatedContracts) {
        baseAsset = _baseAsset;
        marketKey = _marketKey;

        // Set legacyState
        if (_legacyState != address(0)) {
            legacyState = PerpsV2MarketStateLegacyR1(_legacyState);
            _legacyContractExists = true;
            // Confirm same asset/market key
            // Passing the marketKey as parameter and confirming with the legacy allows for double check the intended market is configured
            require(
                baseAsset == legacyState.baseAsset() && marketKey == legacyState.marketKey(),
                "Invalid legacy state baseAsset or marketKey"
            );
        }
    }

    /*
     * Links this State contract with the legacy one fixing the latest state on the previous contract.
     * This function should be called with the market paused to prevent any issue.
     * Note: It's not called on constructor to allow separation of deployment and
     * setup/linking and reduce downtime.
     */
    function linkOrInitializeState() external onlyOwner {
        require(!initialized, "State already initialized");

        if (_legacyContractExists) {
            // copy atomic values
            marketSize = legacyState.marketSize();
            marketSkew = legacyState.marketSkew();
            _entryDebtCorrection = legacyState.entryDebtCorrection();
            _nextPositionId = legacyState.nextPositionId();
            fundingLastRecomputed = legacyState.fundingLastRecomputed();
            fundingRateLastRecomputed = legacyState.fundingRateLastRecomputed();
            uint legacyFundingSequenceLength = legacyState.fundingSequenceLength() - 1;

            // link fundingSequence
            // initialize the _fundingSequence array
            _fundingSequence.push(legacyState.fundingSequence(legacyFundingSequenceLength));
            // get fundingSequence offset
            legacyFundinSequenceOffset = legacyFundingSequenceLength;
        } else {
            // Initialise the funding sequence with 0 initially accrued, so that the first usable funding index is 1.
            _fundingSequence.push(0);
            fundingRateLastRecomputed = 0;
        }

        // set legacyConfigured
        initialized = true;
        // emit event
        emit MarketStateInitialized(marketKey, _legacyContractExists, address(legacyState), legacyFundinSequenceOffset);
    }

    function entryDebtCorrection() external view returns (int128) {
        return _entryDebtCorrection;
    }

    function nextPositionId() external view returns (uint64) {
        return _nextPositionId;
    }

    function fundingSequence(uint index) external view returns (int128) {
        if (_legacyContractExists && index < legacyFundinSequenceOffset) {
            return legacyState.fundingSequence(index);
        }

        return _fundingSequence[index - legacyFundinSequenceOffset];
    }

    function fundingSequenceLength() external view returns (uint) {
        return legacyFundinSequenceOffset + _fundingSequence.length;
    }

    function isFlagged(address account) external view returns (bool) {
        return positionFlagger[account] != address(0);
    }

    function positions(address account) external view returns (Position memory) {
        // If it doesn't exist here check legacy
        if (_legacyContractExists && !_positionMigrated[account] && _positions[account].id == 0) {
            (uint64 id, uint64 lastFundingIndex, uint128 margin, uint128 lastPrice, int128 size) =
                legacyState.positions(account);

            return Position(id, lastFundingIndex, margin, lastPrice, size);
        }

        return _positions[account];
    }

    function delayedOrders(address account) external view returns (DelayedOrder memory) {
        // If it doesn't exist here check legacy
        if (_legacyContractExists && !_delayedOrderMigrated[account] && _delayedOrders[account].sizeDelta == 0) {
            (
                bool isOffchain,
                int128 sizeDelta,
                uint128 desiredFillPrice,
                uint128 targetRoundId,
                uint128 commitDeposit,
                uint128 keeperDeposit,
                uint256 executableAtTime,
                uint256 intentionTime,
                bytes32 trackingCode
            ) = legacyState.delayedOrders(account);
            return
                DelayedOrder(
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

        return _delayedOrders[account];
    }

    /*
     * helper function for migration and analytics. Not linked to legacy state
     */
    function getPositionAddressesPage(uint index, uint pageSize)
        external
        view
        onlyAssociatedContracts
        returns (address[] memory)
    {
        return _positionAddresses.getPage(index, pageSize);
    }

    /*
     * helper function for migration and analytics. Not linked to legacy state
     */
    function getDelayedOrderAddressesPage(uint index, uint pageSize) external view returns (address[] memory) {
        return _delayedOrderAddresses.getPage(index, pageSize);
    }

    /*
     * helper function for migration and analytics. Not linked to legacy state
     */
    function getFlaggedAddressesPage(uint index, uint pageSize) external view returns (address[] memory) {
        return _flaggedAddresses.getPage(index, pageSize);
    }

    /*
     * helper function for migration and analytics. Not linked to legacy state
     */
    function getPositionAddressesLength() external view returns (uint) {
        return _positionAddresses.elements.length;
    }

    /*
     * helper function for migration and analytics. Not linked to legacy state
     */
    function getDelayedOrderAddressesLength() external view returns (uint) {
        return _delayedOrderAddresses.elements.length;
    }

    /*
     * helper function for migration and analytics. Not linked to legacy state
     */
    function getFlaggedAddressesLength() external view returns (uint) {
        return _flaggedAddresses.elements.length;
    }

    function setMarketKey(bytes32 _marketKey) external onlyIfInitialized onlyAssociatedContracts {
        require(marketKey == bytes32(0) || _marketKey == marketKey, "Cannot change market key");
        marketKey = _marketKey;
    }

    function setBaseAsset(bytes32 _baseAsset) external onlyIfInitialized onlyAssociatedContracts {
        require(baseAsset == bytes32(0) || _baseAsset == baseAsset, "Cannot change base asset");
        baseAsset = _baseAsset;
    }

    function setMarketSize(uint128 _marketSize) external onlyIfInitialized onlyAssociatedContracts {
        marketSize = _marketSize;
    }

    function setEntryDebtCorrection(int128 entryDebtCorrection) external onlyIfInitialized onlyAssociatedContracts {
        _entryDebtCorrection = entryDebtCorrection;
    }

    function setNextPositionId(uint64 nextPositionId) external onlyIfInitialized onlyAssociatedContracts {
        _nextPositionId = nextPositionId;
    }

    function setMarketSkew(int128 _marketSkew) external onlyIfInitialized onlyAssociatedContracts {
        marketSkew = _marketSkew;
    }

    function setFundingLastRecomputed(uint32 lastRecomputed) external onlyIfInitialized onlyAssociatedContracts {
        fundingLastRecomputed = lastRecomputed;
    }

    function pushFundingSequence(int128 fundingSequence) external onlyIfInitialized onlyAssociatedContracts {
        _fundingSequence.push(fundingSequence);
    }

    // TODO: Perform this update when maxFundingVelocity and skewScale are modified.
    function setFundingRateLastRecomputed(int128 _fundingRateLastRecomputed)
        external
        onlyIfInitialized
        onlyAssociatedContracts
    {
        fundingRateLastRecomputed = _fundingRateLastRecomputed;
    }

    /**
     * @notice Set the position of a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param id position id.
     * @param lastFundingIndex position lastFundingIndex.
     * @param margin position margin.
     * @param lastPrice position lastPrice.
     * @param size position size.
     */
    function updatePosition(
        address account,
        uint64 id,
        uint64 lastFundingIndex,
        uint128 margin,
        uint128 lastPrice,
        int128 size
    ) external onlyIfInitialized onlyAssociatedContracts {
        if (_legacyContractExists && !_positionMigrated[account]) {
            // Delete (if needed) from legacy state
            legacyState.deletePosition(account);

            // flag as already migrated
            _positionMigrated[account] = true;
        }

        _positions[account] = Position(id, lastFundingIndex, margin, lastPrice, size);
        _positionAddresses.add(account);
    }

    /**
     * @notice Store a delayed order at the specified account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param sizeDelta Difference in position to pass to modifyPosition
     * @param desiredFillPrice Desired fill price as usd used on fillPrice at execution
     * @param targetRoundId Price oracle roundId using which price this order needs to executed
     * @param commitDeposit The commitDeposit paid upon submitting that needs to be refunded if order succeeds
     * @param keeperDeposit The keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
     * @param executableAtTime The timestamp at which this order is executable at
     * @param isOffchain Flag indicating if the order is offchain
     * @param trackingCode Tracking code to emit on execution for volume source fee sharing
     */
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
    ) external onlyIfInitialized onlyAssociatedContracts {
        if (_legacyContractExists && !_delayedOrderMigrated[account]) {
            // Delete (if needed) from legacy state
            legacyState.deleteDelayedOrder(account);

            // flag as already migrated
            _delayedOrderMigrated[account] = true;
        }

        _delayedOrders[account] = DelayedOrder(
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
        _delayedOrderAddresses.add(account);
    }

    /**
     * @notice Delete the position of a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose position should be deleted.
     */
    function deletePosition(address account) external onlyIfInitialized onlyAssociatedContracts {
        delete _positions[account];
        if (_positionAddresses.contains(account)) {
            _positionAddresses.remove(account);
        }

        if (_legacyContractExists && !_positionMigrated[account]) {
            legacyState.deletePosition(account);

            // flag as already migrated
            _positionMigrated[account] = true;
        }
    }

    function deleteDelayedOrder(address account) external onlyIfInitialized onlyAssociatedContracts {
        delete _delayedOrders[account];
        if (_delayedOrderAddresses.contains(account)) {
            _delayedOrderAddresses.remove(account);
        }

        // attempt to delete on legacy
        if (_legacyContractExists && !_delayedOrderMigrated[account]) {
            legacyState.deleteDelayedOrder(account);

            // flag as already migrated
            _delayedOrderMigrated[account] = true;
        }
    }

    function flag(address account, address flagger) external onlyIfInitialized onlyAssociatedContracts {
        positionFlagger[account] = flagger;
        _flaggedAddresses.add(account);
    }

    function unflag(address account) external onlyIfInitialized onlyAssociatedContracts {
        delete positionFlagger[account];
        if (_flaggedAddresses.contains(account)) {
            _flaggedAddresses.remove(account);
        }
    }

    modifier onlyIfInitialized() {
        require(initialized, "State not initialized");
        _;
    }

    /* ========== EVENTS ========== */

    event MarketStateInitialized(
        bytes32 indexed marketKey,
        bool legacyContractExists,
        address legacyState,
        uint legacyFundinSequenceOffset
    );
}
