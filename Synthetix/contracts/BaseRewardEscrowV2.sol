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
import "./Owned.sol";
import "./MixinResolver.sol";
import "./RewardEscrowV2Storage.sol";
import "./LimitedSetup.sol";
import "./interfaces/IRewardEscrowV2.sol";

// Libraries
import "./SafeCast.sol";
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIssuer.sol";

// https://docs.synthetix.io/contracts/RewardEscrow
contract BaseRewardEscrowV2 is Owned, IRewardEscrowV2, LimitedSetup(8 weeks), MixinResolver {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* Mapping of nominated address to recieve account merging */
    mapping(address => address) public nominatedReceiver;

    /* Max escrow duration */
    uint public max_duration = 2 * 52 weeks; // Default max 2 years duration

    /* Max account merging duration */
    uint public maxAccountMergingDuration = 4 weeks; // Default 4 weeks is max

    /* ========== ACCOUNT MERGING CONFIGURATION ========== */

    uint public accountMergingDuration = 1 weeks;

    uint public accountMergingStartTime;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_REWARDESCROWV2STORAGE = "RewardEscrowV2Storage";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}

    /* ========== VIEWS ======================= */

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function synthetixERC20() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function state() internal view returns (IRewardEscrowV2Storage) {
        return IRewardEscrowV2Storage(requireAndGetAddress(CONTRACT_REWARDESCROWV2STORAGE));
    }

    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

    /* ========== VIEW FUNCTIONS ========== */

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](4);
        addresses[0] = CONTRACT_SYNTHETIX;
        addresses[1] = CONTRACT_FEEPOOL;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_REWARDESCROWV2STORAGE;
    }

    /// views forwarded from storage contract

    function numVestingEntries(address account) public view returns (uint) {
        return state().numVestingEntries(account);
    }

    function totalEscrowedBalance() public view returns (uint) {
        return state().totalEscrowedBalance();
    }

    function totalEscrowedAccountBalance(address account) public view returns (uint) {
        return state().totalEscrowedAccountBalance(account);
    }

    function totalVestedAccountBalance(address account) external view returns (uint) {
        return state().totalVestedAccountBalance(account);
    }

    function nextEntryId() external view returns (uint) {
        return state().nextEntryId();
    }

    function vestingSchedules(address account, uint256 entryId) public view returns (VestingEntries.VestingEntry memory) {
        return state().vestingSchedules(account, entryId);
    }

    function accountVestingEntryIDs(address account, uint256 index) public view returns (uint) {
        return state().accountVestingEntryIDs(account, index);
    }

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) public view returns (uint) {
        return totalEscrowedAccountBalance(account);
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return The vesting entry object and rate per second emission.
     */
    function getVestingEntry(address account, uint256 entryID) external view returns (uint64 endTime, uint256 escrowAmount) {
        VestingEntries.VestingEntry memory entry = vestingSchedules(account, entryID);
        return (entry.endTime, entry.escrowAmount);
    }

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory) {
        uint256 endIndex = index + pageSize;

        // If index starts after the endIndex return no results
        if (endIndex <= index) {
            return new VestingEntries.VestingEntryWithID[](0);
        }

        // If the page extends past the end of the accountVestingEntryIDs, truncate it.
        if (endIndex > numVestingEntries(account)) {
            endIndex = numVestingEntries(account);
        }

        uint256 n = endIndex - index;
        uint256 entryID;
        VestingEntries.VestingEntry memory entry;
        VestingEntries.VestingEntryWithID[] memory vestingEntries = new VestingEntries.VestingEntryWithID[](n);
        for (uint256 i; i < n; i++) {
            entryID = accountVestingEntryIDs(account, i + index);

            entry = vestingSchedules(account, entryID);

            vestingEntries[i] = VestingEntries.VestingEntryWithID({
                endTime: uint64(entry.endTime),
                escrowAmount: entry.escrowAmount,
                entryID: entryID
            });
        }
        return vestingEntries;
    }

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory) {
        uint256 endIndex = index + pageSize;

        // If the page extends past the end of the accountVestingEntryIDs, truncate it.
        uint numEntries = numVestingEntries(account);
        if (endIndex > numEntries) {
            endIndex = numEntries;
        }
        if (endIndex <= index) {
            return new uint256[](0);
        }

        uint256 n = endIndex - index;
        uint256[] memory page = new uint256[](n);
        for (uint256 i; i < n; i++) {
            page[i] = accountVestingEntryIDs(account, i + index);
        }
        return page;
    }

    function getVestingQuantity(address account, uint256[] calldata entryIDs) external view returns (uint total) {
        VestingEntries.VestingEntry memory entry;
        for (uint i = 0; i < entryIDs.length; i++) {
            entry = vestingSchedules(account, entryIDs[i]);

            /* Skip entry if escrowAmount == 0 */
            if (entry.escrowAmount != 0) {
                uint256 quantity = _claimableAmount(entry);

                /* add quantity to total */
                total = total.add(quantity);
            }
        }
    }

    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint) {
        return _claimableAmount(vestingSchedules(account, entryID));
    }

    function _claimableAmount(VestingEntries.VestingEntry memory _entry) internal view returns (uint256) {
        uint256 quantity;
        if (_entry.escrowAmount != 0) {
            /* Escrow amounts claimable if block.timestamp equal to or after entry endTime */
            quantity = block.timestamp >= _entry.endTime ? _entry.escrowAmount : 0;
        }
        return quantity;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Vest escrowed amounts that are claimable
     * Allows users to vest their vesting entries based on msg.sender
     */
    function vest(uint256[] calldata entryIDs) external {
        // only account can call vest
        address account = msg.sender;

        uint256 total;
        VestingEntries.VestingEntry memory entry;
        uint256 quantity;
        for (uint i = 0; i < entryIDs.length; i++) {
            entry = vestingSchedules(account, entryIDs[i]);

            /* Skip entry if escrowAmount == 0 already vested */
            if (entry.escrowAmount != 0) {
                quantity = _claimableAmount(entry);

                /* update entry to remove escrowAmount */
                if (quantity > 0) {
                    state().setZeroAmount(account, entryIDs[i]);
                }

                /* add quantity to total */
                total = total.add(quantity);
            }
        }

        /* Transfer vested tokens. Will revert if total > totalEscrowedAccountBalance */
        if (total != 0) {
            _subtractAndTransfer(account, account, total);
            // update total vested
            state().updateVestedAccountBalance(account, SafeCast.toInt256(total));
            emit Vested(account, block.timestamp, total);
        }
    }

    /// method for revoking vesting entries regardless of schedule to be used for liquidations
    /// access controlled to only Synthetix contract
    /// @param account: account
    /// @param recipient: account to transfer the revoked tokens to
    /// @param targetAmount: amount of SNX to revoke, when this amount is reached, no more entries are revoked
    /// @param startIndex: index into accountVestingEntryIDs[account] to start iterating from
    function revokeFrom(
        address account,
        address recipient,
        uint targetAmount,
        uint startIndex
    ) external onlySynthetix {
        require(account != address(0), "account not set");
        require(recipient != address(0), "recipient not set");

        // set stored entries to zero
        (uint total, uint endIndex, uint lastEntryTime) =
            state().setZeroAmountUntilTarget(account, startIndex, targetAmount);

        // check total is indeed enough
        // the caller should have checked for the general amount of escrow
        // but only here we check that startIndex results in sufficient amount
        require(total >= targetAmount, "entries sum less than target");

        // if too much was revoked
        if (total > targetAmount) {
            // only take the precise amount needed by adding a new entry with the difference from total
            uint refund = total.sub(targetAmount);
            uint entryID =
                state().addVestingEntry(
                    account,
                    VestingEntries.VestingEntry({endTime: uint64(lastEntryTime), escrowAmount: refund})
                );
            // emit event
            uint duration = lastEntryTime > block.timestamp ? lastEntryTime.sub(block.timestamp) : 0;
            emit VestingEntryCreated(account, block.timestamp, refund, duration, entryID);
        }

        // update the aggregates and move the tokens
        _subtractAndTransfer(account, recipient, targetAmount);

        emit Revoked(account, recipient, targetAmount, startIndex, endIndex);
    }

    /// remove tokens from vesting aggregates and transfer them to recipient
    function _subtractAndTransfer(
        address subtractFrom,
        address transferTo,
        uint256 amount
    ) internal {
        state().updateEscrowAccountBalance(subtractFrom, -SafeCast.toInt256(amount));
        synthetixERC20().transfer(transferTo, amount);
    }

    /**
     * @notice Create an escrow entry to lock SNX for a given duration in seconds
     * @dev This call expects that the depositor (msg.sender) has already approved the Reward escrow contract
     to spend the the amount being escrowed.
     */
    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external {
        require(beneficiary != address(0), "Cannot create escrow with address(0)");

        /* Transfer SNX from msg.sender */
        require(synthetixERC20().transferFrom(msg.sender, address(this), deposit), "token transfer failed");

        /* Append vesting entry for the beneficiary address */
        _appendVestingEntry(beneficiary, deposit, duration);
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successful call to synthetix.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of SNX that will be escrowed.
     * @param duration The duration that SNX will be emitted.
     */
    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external onlyFeePool {
        _appendVestingEntry(account, quantity, duration);
    }

    function _appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) internal {
        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");
        require(duration > 0 && duration <= max_duration, "Cannot escrow with 0 duration OR above max_duration");

        // Add quantity to account's escrowed balance to the total balance
        state().updateEscrowAccountBalance(account, SafeCast.toInt256(quantity));

        /* There must be enough balance in the contract to provide for the vesting entry. */
        require(
            totalEscrowedBalance() <= synthetixERC20().balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        /* Escrow the tokens for duration. */
        uint endTime = block.timestamp + duration;

        // store vesting entry
        uint entryID =
            state().addVestingEntry(
                account,
                VestingEntries.VestingEntry({endTime: uint64(endTime), escrowAmount: quantity})
            );

        emit VestingEntryCreated(account, block.timestamp, quantity, duration, entryID);
    }

    /* ========== ACCOUNT MERGING ========== */

    function accountMergingIsOpen() public view returns (bool) {
        return accountMergingStartTime.add(accountMergingDuration) > block.timestamp;
    }

    function startMergingWindow() external onlyOwner {
        accountMergingStartTime = block.timestamp;
        emit AccountMergingStarted(accountMergingStartTime, accountMergingStartTime.add(accountMergingDuration));
    }

    function setAccountMergingDuration(uint256 duration) external onlyOwner {
        require(duration <= maxAccountMergingDuration, "exceeds max merging duration");
        accountMergingDuration = duration;
        emit AccountMergingDurationUpdated(duration);
    }

    function setMaxAccountMergingWindow(uint256 duration) external onlyOwner {
        maxAccountMergingDuration = duration;
        emit MaxAccountMergingDurationUpdated(duration);
    }

    function setMaxEscrowDuration(uint256 duration) external onlyOwner {
        max_duration = duration;
        emit MaxEscrowDurationUpdated(duration);
    }

    /* Nominate an account to merge escrow and vesting schedule */
    function nominateAccountToMerge(address account) external {
        require(account != msg.sender, "Cannot nominate own account to merge");
        require(accountMergingIsOpen(), "Account merging has ended");
        require(issuer().debtBalanceOf(msg.sender, "sUSD") == 0, "Cannot merge accounts with debt");
        nominatedReceiver[msg.sender] = account;
        emit NominateAccountToMerge(msg.sender, account);
    }

    function mergeAccount(address from, uint256[] calldata entryIDs) external {
        require(accountMergingIsOpen(), "Account merging has ended");
        require(issuer().debtBalanceOf(from, "sUSD") == 0, "Cannot merge accounts with debt");
        require(nominatedReceiver[from] == msg.sender, "Address is not nominated to merge");
        address to = msg.sender;

        uint256 totalEscrowAmountMerged;
        VestingEntries.VestingEntry memory entry;
        for (uint i = 0; i < entryIDs.length; i++) {
            // retrieve entry
            entry = vestingSchedules(from, entryIDs[i]);

            /* ignore vesting entries with zero escrowAmount */
            if (entry.escrowAmount != 0) {
                // set previous entry amount to zero
                state().setZeroAmount(from, entryIDs[i]);

                // append new entry for recipient, the new entry will have new entryID
                state().addVestingEntry(to, entry);

                /* Add the escrowAmount of entry to the totalEscrowAmountMerged */
                totalEscrowAmountMerged = totalEscrowAmountMerged.add(entry.escrowAmount);
            }
        }

        // remove from old account
        state().updateEscrowAccountBalance(from, -SafeCast.toInt256(totalEscrowAmountMerged));
        // add to recipient account
        state().updateEscrowAccountBalance(to, SafeCast.toInt256(totalEscrowAmountMerged));

        emit AccountMerged(from, to, totalEscrowAmountMerged, entryIDs, block.timestamp);
    }

    /* ========== MIGRATION OLD ESCROW ========== */

    function migrateVestingSchedule(address) external {
        _notImplemented();
    }

    function migrateAccountEscrowBalances(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external {
        _notImplemented();
    }

    /* ========== L2 MIGRATION ========== */

    function burnForMigration(address, uint[] calldata) external returns (uint256, VestingEntries.VestingEntry[] memory) {
        _notImplemented();
    }

    function importVestingEntries(
        address,
        uint256,
        VestingEntries.VestingEntry[] calldata
    ) external {
        _notImplemented();
    }

    /* ========== MODIFIERS ========== */
    modifier onlyFeePool() {
        require(msg.sender == address(feePool()), "Only the FeePool can perform this action");
        _;
    }

    modifier onlySynthetix() {
        require(msg.sender == address(synthetixERC20()), "Only Synthetix");
        _;
    }

    /* ========== EVENTS ========== */
    event Vested(address indexed beneficiary, uint time, uint value);
    event VestingEntryCreated(address indexed beneficiary, uint time, uint value, uint duration, uint entryID);
    event MaxEscrowDurationUpdated(uint newDuration);
    event MaxAccountMergingDurationUpdated(uint newDuration);
    event AccountMergingDurationUpdated(uint newDuration);
    event AccountMergingStarted(uint time, uint endTime);
    event AccountMerged(
        address indexed accountToMerge,
        address destinationAddress,
        uint escrowAmountMerged,
        uint[] entryIDs,
        uint time
    );
    event NominateAccountToMerge(address indexed account, address destination);
    event Revoked(address indexed account, address indexed recipient, uint targetAmount, uint startIndex, uint endIndex);
}
