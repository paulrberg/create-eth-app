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
import "./Proxyable.sol";
import "./LimitedSetup.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/IFeePool.sol";

// Libraries
import "./SafeDecimalMath.sol";

import "Synthetix/@chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/ISynthetix.sol";
import "./interfaces/ISynthetixDebtShare.sol";
import "./FeePoolEternalStorage.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/IDelegateApprovals.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/ICollateralManager.sol";
import "./interfaces/IEtherWrapper.sol";
import "./interfaces/IFuturesMarketManager.sol";
import "./interfaces/IWrapperFactory.sol";
import "./interfaces/ISynthetixBridgeToOptimism.sol";

// https://docs.synthetix.io/contracts/source/contracts/feepool
contract FeePool is Owned, Proxyable, LimitedSetup, MixinSystemSettings, IFeePool {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    bytes32 public constant CONTRACT_NAME = "FeePool";

    // Where fees are pooled in sUSD.
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    // sUSD currencyKey. Fees stored and paid in sUSD
    bytes32 private sUSD = "sUSD";

    // This struct represents the issuance activity that's happened in a fee period.
    struct FeePeriod {
        uint64 feePeriodId;
        uint64 startTime;
        uint allNetworksSnxBackedDebt;
        uint allNetworksDebtSharesSupply;
        uint feesToDistribute;
        uint feesClaimed;
        uint rewardsToDistribute;
        uint rewardsClaimed;
    }

    // A staker(mintr) can claim from the previous fee period (7 days) only.
    // Fee Periods stored and managed from [0], such that [0] is always
    // the current active fee period which is not claimable until the
    // public function closeCurrentFeePeriod() is called closing the
    // current weeks collected fees. [1] is last weeks feeperiod
    uint8 public constant FEE_PERIOD_LENGTH = 2;

    FeePeriod[FEE_PERIOD_LENGTH] private _recentFeePeriods;
    uint256 private _currentFeePeriod;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_SYNTHETIXDEBTSHARE = "SynthetixDebtShare";
    bytes32 private constant CONTRACT_FEEPOOLETERNALSTORAGE = "FeePoolEternalStorage";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_COLLATERALMANAGER = "CollateralManager";
    bytes32 private constant CONTRACT_REWARDSDISTRIBUTION = "RewardsDistribution";
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";
    bytes32 private constant CONTRACT_WRAPPER_FACTORY = "WrapperFactory";

    bytes32 private constant CONTRACT_SYNTHETIX_BRIDGE_TO_OPTIMISM = "SynthetixBridgeToOptimism";
    bytes32 private constant CONTRACT_SYNTHETIX_BRIDGE_TO_BASE = "SynthetixBridgeToBase";

    bytes32 private constant CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS = "ext:AggregatorIssuedSynths";
    bytes32 private constant CONTRACT_EXT_AGGREGATOR_DEBT_RATIO = "ext:AggregatorDebtRatio";

    /* ========== ETERNAL STORAGE CONSTANTS ========== */

    bytes32 private constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    constructor(
        address payable _proxy,
        address _owner,
        address _resolver
    ) public Owned(_owner) Proxyable(_proxy) LimitedSetup(3 weeks) MixinSystemSettings(_resolver) {
        // Set our initial fee period
        _recentFeePeriodsStorage(0).feePeriodId = 1;
        _recentFeePeriodsStorage(0).startTime = uint64(block.timestamp);
    }

    /* ========== VIEWS ========== */
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](14);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_SYNTHETIXDEBTSHARE;
        newAddresses[2] = CONTRACT_FEEPOOLETERNALSTORAGE;
        newAddresses[3] = CONTRACT_EXCHANGER;
        newAddresses[4] = CONTRACT_ISSUER;
        newAddresses[5] = CONTRACT_REWARDESCROW_V2;
        newAddresses[6] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[7] = CONTRACT_REWARDSDISTRIBUTION;
        newAddresses[8] = CONTRACT_COLLATERALMANAGER;
        newAddresses[9] = CONTRACT_WRAPPER_FACTORY;
        newAddresses[10] = CONTRACT_ETHER_WRAPPER;
        newAddresses[11] = CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS;
        newAddresses[12] = CONTRACT_EXT_AGGREGATOR_DEBT_RATIO;
        newAddresses[13] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function synthetixDebtShare() internal view returns (ISynthetixDebtShare) {
        return ISynthetixDebtShare(requireAndGetAddress(CONTRACT_SYNTHETIXDEBTSHARE));
    }

    function feePoolEternalStorage() internal view returns (FeePoolEternalStorage) {
        return FeePoolEternalStorage(requireAndGetAddress(CONTRACT_FEEPOOLETERNALSTORAGE));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function collateralManager() internal view returns (ICollateralManager) {
        return ICollateralManager(requireAndGetAddress(CONTRACT_COLLATERALMANAGER));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }

    function delegateApprovals() internal view returns (IDelegateApprovals) {
        return IDelegateApprovals(requireAndGetAddress(CONTRACT_DELEGATEAPPROVALS));
    }

    function rewardsDistribution() internal view returns (IRewardsDistribution) {
        return IRewardsDistribution(requireAndGetAddress(CONTRACT_REWARDSDISTRIBUTION));
    }

    function etherWrapper() internal view returns (IEtherWrapper) {
        return IEtherWrapper(requireAndGetAddress(CONTRACT_ETHER_WRAPPER));
    }

    function futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }

    function wrapperFactory() internal view returns (IWrapperFactory) {
        return IWrapperFactory(requireAndGetAddress(CONTRACT_WRAPPER_FACTORY));
    }

    function issuanceRatio() external view returns (uint) {
        return getIssuanceRatio();
    }

    function feePeriodDuration() external view returns (uint) {
        return getFeePeriodDuration();
    }

    function targetThreshold() external view returns (uint) {
        return getTargetThreshold();
    }

    function allNetworksSnxBackedDebt() public view returns (uint256 debt, uint256 updatedAt) {
        (, int256 rawData, , uint timestamp, ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS)).latestRoundData();

        debt = uint(rawData);
        updatedAt = timestamp;
    }

    function allNetworksDebtSharesSupply() public view returns (uint256 sharesSupply, uint256 updatedAt) {
        (, int256 rawIssuedSynths, , uint issuedSynthsUpdatedAt, ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_ISSUED_SYNTHS)).latestRoundData();

        (, int256 rawRatio, , uint ratioUpdatedAt, ) =
            AggregatorV2V3Interface(requireAndGetAddress(CONTRACT_EXT_AGGREGATOR_DEBT_RATIO)).latestRoundData();

        uint debt = uint(rawIssuedSynths);
        sharesSupply = rawRatio == 0 ? 0 : debt.divideDecimalRoundPrecise(uint(rawRatio));
        updatedAt = issuedSynthsUpdatedAt < ratioUpdatedAt ? issuedSynthsUpdatedAt : ratioUpdatedAt;
    }

    function recentFeePeriods(uint index)
        external
        view
        returns (
            uint64 feePeriodId,
            uint64 unused, // required post 185 for api compatibility
            uint64 startTime,
            uint feesToDistribute,
            uint feesClaimed,
            uint rewardsToDistribute,
            uint rewardsClaimed
        )
    {
        FeePeriod memory feePeriod = _recentFeePeriodsStorage(index);
        return (
            feePeriod.feePeriodId,
            0,
            feePeriod.startTime,
            feePeriod.feesToDistribute,
            feePeriod.feesClaimed,
            feePeriod.rewardsToDistribute,
            feePeriod.rewardsClaimed
        );
    }

    function _recentFeePeriodsStorage(uint index) internal view returns (FeePeriod storage) {
        return _recentFeePeriods[(_currentFeePeriod + index) % FEE_PERIOD_LENGTH];
    }

    /**
     * @notice The Exchanger contract informs us when fees are paid.
     * @param amount susd amount in fees being paid.
     */
    function recordFeePaid(uint amount) external onlyInternalContracts {
        // Keep track off fees in sUSD in the open fee pool period.
        _recentFeePeriodsStorage(0).feesToDistribute = _recentFeePeriodsStorage(0).feesToDistribute.add(amount);
    }

    /**
     * @notice The RewardsDistribution contract informs us how many SNX rewards are sent to RewardEscrow to be claimed.
     */
    function setRewardsToDistribute(uint amount) external optionalProxy {
        require(messageSender == address(rewardsDistribution()), "RewardsDistribution only");
        // Add the amount of SNX rewards to distribute on top of any rolling unclaimed amount
        _recentFeePeriodsStorage(0).rewardsToDistribute = _recentFeePeriodsStorage(0).rewardsToDistribute.add(amount);
    }

    /**
     * @notice Close the current fee period and start a new one.
     */
    function closeCurrentFeePeriod() external issuanceActive {
        require(getFeePeriodDuration() > 0, "Fee Period Duration not set");
        require(_recentFeePeriodsStorage(0).startTime <= (now - getFeePeriodDuration()), "Too early to close fee period");

        // get current oracle values
        (uint snxBackedDebt, ) = allNetworksSnxBackedDebt();
        (uint debtSharesSupply, ) = allNetworksDebtSharesSupply();

        // close on this chain
        _closeSecondary(snxBackedDebt, debtSharesSupply);

        // inform other chain of the chosen values
        ISynthetixBridgeToOptimism(
            resolver.requireAndGetAddress(
                CONTRACT_SYNTHETIX_BRIDGE_TO_OPTIMISM,
                "Missing contract: SynthetixBridgeToOptimism"
            )
        )
            .closeFeePeriod(snxBackedDebt, debtSharesSupply);
    }

    function closeSecondary(uint allNetworksSnxBackedDebt, uint allNetworksDebtSharesSupply) external onlyRelayer {
        _closeSecondary(allNetworksSnxBackedDebt, allNetworksDebtSharesSupply);
    }

    /**
     * @notice Close the current fee period and start a new one.
     */
    function _closeSecondary(uint allNetworksSnxBackedDebt, uint allNetworksDebtSharesSupply) internal {
        etherWrapper().distributeFees();
        wrapperFactory().distributeFees();

        // before closing the current fee period, set the recorded snxBackedDebt and debtSharesSupply
        _recentFeePeriodsStorage(0).allNetworksDebtSharesSupply = allNetworksDebtSharesSupply;
        _recentFeePeriodsStorage(0).allNetworksSnxBackedDebt = allNetworksSnxBackedDebt;

        // Note:  periodClosing is the current period & periodToRollover is the last open claimable period
        FeePeriod storage periodClosing = _recentFeePeriodsStorage(0);
        FeePeriod storage periodToRollover = _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 1);

        // Any unclaimed fees from the last period in the array roll back one period.
        // Because of the subtraction here, they're effectively proportionally redistributed to those who
        // have already claimed from the old period, available in the new period.
        // The subtraction is important so we don't create a ticking time bomb of an ever growing
        // number of fees that can never decrease and will eventually overflow at the end of the fee pool.
        _recentFeePeriodsStorage(0).feesToDistribute = periodToRollover
            .feesToDistribute
            .sub(periodToRollover.feesClaimed)
            .add(periodClosing.feesToDistribute);
        _recentFeePeriodsStorage(0).rewardsToDistribute = periodToRollover
            .rewardsToDistribute
            .sub(periodToRollover.rewardsClaimed)
            .add(periodClosing.rewardsToDistribute);

        // Note: As of SIP-255, all sUSD fee are now automatically burned and are effectively shared amongst stakers in the form of reduced debt.
        if (_recentFeePeriodsStorage(0).feesToDistribute > 0) {
            issuer().burnSynthsWithoutDebt(sUSD, FEE_ADDRESS, _recentFeePeriodsStorage(0).feesToDistribute);

            // Mark the burnt fees as claimed.
            _recentFeePeriodsStorage(0).feesClaimed = _recentFeePeriodsStorage(0).feesToDistribute;
        }

        // Shift the previous fee periods across to make room for the new one.
        _currentFeePeriod = _currentFeePeriod.add(FEE_PERIOD_LENGTH).sub(1).mod(FEE_PERIOD_LENGTH);

        // Clear the first element of the array to make sure we don't have any stale values.
        delete _recentFeePeriods[_currentFeePeriod];

        // Open up the new fee period.
        // periodID is set to the current timestamp for compatibility with other systems taking snapshots on the debt shares
        uint newFeePeriodId = block.timestamp;
        _recentFeePeriodsStorage(0).feePeriodId = uint64(newFeePeriodId);
        _recentFeePeriodsStorage(0).startTime = uint64(block.timestamp);

        // Inform Issuer to start recording for the new fee period
        issuer().setCurrentPeriodId(uint128(newFeePeriodId));

        emitFeePeriodClosed(_recentFeePeriodsStorage(1).feePeriodId);
    }

    /**
     * @notice Claim fees for last period when available or not already withdrawn.
     */
    function claimFees() external issuanceActive optionalProxy returns (bool) {
        return _claimFees(messageSender);
    }

    /**
     * @notice Delegated claimFees(). Call from the deletegated address
     * and the fees will be sent to the claimingForAddress.
     * approveClaimOnBehalf() must be called first to approve the deletage address
     * @param claimingForAddress The account you are claiming fees for
     */
    function claimOnBehalf(address claimingForAddress) external issuanceActive optionalProxy returns (bool) {
        require(delegateApprovals().canClaimFor(claimingForAddress, messageSender), "Not approved to claim on behalf");

        return _claimFees(claimingForAddress);
    }

    /**
     * Note: As of SIP-255, all sUSD fees are burned at the closure of the fee period and are no longer claimable.
     * @notice Send the rewards to claiming address.
     * @param claimingAddress The address to send the rewards to.
     */
    function _claimFees(address claimingAddress) internal returns (bool) {
        uint rewardsPaid = 0;
        uint feesPaid = 0;
        uint availableFees;
        uint availableRewards;

        // Address won't be able to claim fees if it is too far below the target c-ratio.
        // It will need to burn synths then try claiming again.
        (bool feesClaimable, bool anyRateIsInvalid) = _isFeesClaimableAndAnyRatesInvalid(claimingAddress);

        require(feesClaimable, "C-Ratio below penalty threshold");

        require(!anyRateIsInvalid, "A synth or SNX rate is invalid");

        // Get the claimingAddress available fees and rewards
        (availableFees, availableRewards) = feesAvailable(claimingAddress);

        require(
            availableFees > 0 || availableRewards > 0,
            "No fees or rewards available for period, or fees already claimed"
        );

        // Record the address has claimed for this period
        _setLastFeeWithdrawal(claimingAddress, _recentFeePeriodsStorage(1).feePeriodId);

        // Mark the fees as paid since they were already burned.
        feesPaid = availableFees;

        if (availableRewards > 0) {
            // Record the reward payment in our recentFeePeriods
            rewardsPaid = _recordRewardPayment(availableRewards);

            // Send them their rewards
            _payRewards(claimingAddress, rewardsPaid);
        }

        emitFeesClaimed(claimingAddress, feesPaid, rewardsPaid);

        return true;
    }

    /**
     * @notice Admin function to import the FeePeriod data from the previous contract
     */
    function importFeePeriod(
        uint feePeriodIndex,
        uint feePeriodId,
        uint startTime,
        uint feesToDistribute,
        uint feesClaimed,
        uint rewardsToDistribute,
        uint rewardsClaimed
    ) external optionalProxy_onlyOwner onlyDuringSetup {
        require(feePeriodIndex < FEE_PERIOD_LENGTH, "invalid fee period index");

        _recentFeePeriods[feePeriodIndex] = FeePeriod({
            feePeriodId: uint64(feePeriodId),
            startTime: uint64(startTime),
            feesToDistribute: feesToDistribute,
            feesClaimed: feesClaimed,
            rewardsToDistribute: rewardsToDistribute,
            rewardsClaimed: rewardsClaimed,
            allNetworksSnxBackedDebt: 0,
            allNetworksDebtSharesSupply: 0
        });

        // make sure recording is aware of the actual period id
        if (feePeriodIndex == 0) {
            issuer().setCurrentPeriodId(uint128(feePeriodId));
        }
    }

    /**
     * @notice Record the reward payment in our recentFeePeriods.
     * @param snxAmount The amount of SNX tokens.
     */
    function _recordRewardPayment(uint snxAmount) internal returns (uint) {
        // Don't assign to the parameter
        uint remainingToAllocate = snxAmount;

        uint rewardPaid;

        // Start at the oldest period and record the amount, moving to newer periods
        // until we've exhausted the amount.
        // The condition checks for overflow because we're going to 0 with an unsigned int.
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint toDistribute =
                _recentFeePeriodsStorage(i).rewardsToDistribute.sub(_recentFeePeriodsStorage(i).rewardsClaimed);

            if (toDistribute > 0) {
                // Take the smaller of the amount left to claim in the period and the amount we need to allocate
                uint amountInPeriod = toDistribute < remainingToAllocate ? toDistribute : remainingToAllocate;

                _recentFeePeriodsStorage(i).rewardsClaimed = _recentFeePeriodsStorage(i).rewardsClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                rewardPaid = rewardPaid.add(amountInPeriod);

                // No need to continue iterating if we've recorded the whole amount;
                if (remainingToAllocate == 0) return rewardPaid;
            }
        }
        return rewardPaid;
    }

    /**
     * @notice Send the rewards to claiming address - will be locked in rewardEscrow.
     * @param account The address to send the fees to.
     * @param snxAmount The amount of SNX.
     */
    function _payRewards(address account, uint snxAmount) internal notFeeAddress(account) {
        /* Escrow the tokens for 1 year. */
        uint escrowDuration = 52 weeks;

        // Record vesting entry for claiming address and amount
        // SNX already minted to rewardEscrow balance
        rewardEscrowV2().appendVestingEntry(account, snxAmount, escrowDuration);
    }

    /**
     * @notice The total fees available in the system to be withdrawn in sUSD.
     */
    function totalFeesAvailable() external view returns (uint) {
        uint totalFees = 0;

        // Fees in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(_recentFeePeriodsStorage(i).feesToDistribute);
            totalFees = totalFees.sub(_recentFeePeriodsStorage(i).feesClaimed);
        }

        return totalFees;
    }

    /**
     * @notice The total fees that were already burned (i.e. claimed) in the previous fee period [1].
     */
    function totalFeesBurned() external view returns (uint) {
        return _recentFeePeriodsStorage(1).feesClaimed;
    }

    /**
     * @notice The total SNX rewards available in the system to be withdrawn
     */
    function totalRewardsAvailable() external view returns (uint) {
        uint totalRewards = 0;

        // Rewards in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalRewards = totalRewards.add(_recentFeePeriodsStorage(i).rewardsToDistribute);
            totalRewards = totalRewards.sub(_recentFeePeriodsStorage(i).rewardsClaimed);
        }

        return totalRewards;
    }

    /**
     * @notice The fees available to be withdrawn by a specific account, priced in sUSD
     * @dev Returns two amounts, one for fees and one for SNX rewards
     */
    function feesAvailable(address account) public view returns (uint, uint) {
        // Add up the fees
        uint[FEE_PERIOD_LENGTH][2] memory userFees = feesByPeriod(account);

        uint totalFees = 0;
        uint totalRewards = 0;

        // Fees & Rewards in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(userFees[i][0]);
            totalRewards = totalRewards.add(userFees[i][1]);
        }

        // And convert totalFees to sUSD
        // Return totalRewards as is in SNX amount
        return (totalFees, totalRewards);
    }

    /**
     * @notice The total amount of fees burned for a specific account in the previous period [1].
     * Note: Fees in the current fee period [0] are not yet burned.
     */
    function feesBurned(address account) public view returns (uint) {
        uint[FEE_PERIOD_LENGTH][2] memory userFees = feesByPeriod(account);
        return userFees[1][0];
    }

    /**
     * @notice The amount of fees to be burned for an account during the current fee period [0].
     * Note: this returns an approximate value based on the current system rate. Any changes in debt shares may affect the outcome of the final amount.
     * This also does not consider pending fees in the wrappers since they are distributed at fee period close.
     */
    function feesToBurn(address account) public view returns (uint feesFromPeriod) {
        ISynthetixDebtShare sds = synthetixDebtShare();
        uint userOwnershipPercentage = sds.sharePercent(account);
        (feesFromPeriod, ) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage);
        return feesFromPeriod;
    }

    function _isFeesClaimableAndAnyRatesInvalid(address account) internal view returns (bool, bool) {
        // Threshold is calculated from ratio % above the target ratio (issuanceRatio).
        //  0  <  10%:   Claimable
        // 10% > above:  Unable to claim
        (uint ratio, bool anyRateIsInvalid) = issuer().collateralisationRatioAndAnyRatesInvalid(account);
        uint targetRatio = getIssuanceRatio();

        // Claimable if collateral ratio below target ratio
        if (ratio < targetRatio) {
            return (true, anyRateIsInvalid);
        }

        // Calculate the threshold for collateral ratio before fees can't be claimed.
        uint ratio_threshold = targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(getTargetThreshold()));

        // Not claimable if collateral ratio above threshold
        if (ratio > ratio_threshold) {
            return (false, anyRateIsInvalid);
        }

        return (true, anyRateIsInvalid);
    }

    function isFeesClaimable(address account) external view returns (bool feesClaimable) {
        (feesClaimable, ) = _isFeesClaimableAndAnyRatesInvalid(account);
    }

    /**
     * @notice Calculates fees by period for an account, priced in sUSD
     * @param account The address you want to query the fees for
     */
    function feesByPeriod(address account) public view returns (uint[FEE_PERIOD_LENGTH][2] memory results) {
        // What's the user's debt entry index and the debt they owe to the system at current feePeriod
        uint userOwnershipPercentage;
        ISynthetixDebtShare sds = synthetixDebtShare();

        userOwnershipPercentage = sds.sharePercent(account);

        // The [0] fee period is not yet ready to claim, but it is a fee period that they can have
        // fees owing for, so we need to report on it anyway.
        uint feesFromPeriod;
        uint rewardsFromPeriod;
        (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage);

        results[0][0] = feesFromPeriod;
        results[0][1] = rewardsFromPeriod;

        // Retrieve user's last fee claim by periodId
        uint lastFeeWithdrawal = getLastFeeWithdrawal(account);

        // Go through our fee periods from the oldest feePeriod[FEE_PERIOD_LENGTH - 1] and figure out what we owe them.
        // Condition checks for periods > 0
        for (uint i = FEE_PERIOD_LENGTH - 1; i > 0; i--) {
            uint64 periodId = _recentFeePeriodsStorage(i).feePeriodId;
            if (lastFeeWithdrawal < periodId) {
                userOwnershipPercentage = sds.sharePercentOnPeriod(account, uint(periodId));

                (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(i, userOwnershipPercentage);

                results[i][0] = feesFromPeriod;
                results[i][1] = rewardsFromPeriod;
            }
        }
    }

    /**
     * @notice ownershipPercentage is a high precision decimals uint based on
     * wallet's debtPercentage. Gives a precise amount of the feesToDistribute
     * for fees in the period. Precision factor is removed before results are
     * returned.
     * @dev The reported fees owing for the current period [0] are just a
     * running balance until the fee period closes
     */
    function _feesAndRewardsFromPeriod(uint period, uint ownershipPercentage) internal view returns (uint, uint) {
        // If it's zero, they haven't issued, and they have no fees OR rewards.
        if (ownershipPercentage == 0) return (0, 0);

        FeePeriod storage fp = _recentFeePeriodsStorage(period);

        // Calculate their percentage of the fees / rewards in this period
        // This is a high precision integer.
        uint feesFromPeriod = fp.feesToDistribute.multiplyDecimal(ownershipPercentage);

        uint rewardsFromPeriod = fp.rewardsToDistribute.multiplyDecimal(ownershipPercentage);

        return (feesFromPeriod, rewardsFromPeriod);
    }

    function effectiveDebtRatioForPeriod(address account, uint period) external view returns (uint) {
        // if period is not closed yet, or outside of the fee period range, return 0 instead of reverting
        if (period == 0 || period >= FEE_PERIOD_LENGTH) {
            return 0;
        }

        // If the period being checked is uninitialised then return 0. This is only at the start of the system.
        if (_recentFeePeriodsStorage(period - 1).startTime == 0) return 0;

        return synthetixDebtShare().sharePercentOnPeriod(account, uint(_recentFeePeriods[period].feePeriodId));
    }

    /**
     * @notice Get the feePeriodID of the last claim this account made
     * @param _claimingAddress account to check the last fee period ID claim for
     * @return uint of the feePeriodID this account last claimed
     */
    function getLastFeeWithdrawal(address _claimingAddress) public view returns (uint) {
        return feePoolEternalStorage().getUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)));
    }

    /**
     * @notice Calculate the collateral ratio before user is blocked from claiming.
     */
    function getPenaltyThresholdRatio() public view returns (uint) {
        return getIssuanceRatio().multiplyDecimal(SafeDecimalMath.unit().add(getTargetThreshold()));
    }

    /**
     * @notice Set the feePeriodID of the last claim this account made
     * @param _claimingAddress account to set the last feePeriodID claim for
     * @param _feePeriodID the feePeriodID this account claimed fees for
     */
    function _setLastFeeWithdrawal(address _claimingAddress, uint _feePeriodID) internal {
        feePoolEternalStorage().setUIntValue(
            keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)),
            _feePeriodID
        );
    }

    /* ========== Modifiers ========== */

    function _isInternalContract(address account) internal view returns (bool) {
        return
            account == address(exchanger()) ||
            issuer().synthsByAddress(account) != bytes32(0) ||
            collateralManager().hasCollateral(account) ||
            account == address(futuresMarketManager()) ||
            account == address(wrapperFactory()) ||
            account == address(etherWrapper());
    }

    modifier onlyInternalContracts {
        require(_isInternalContract(msg.sender), "Only Internal Contracts");
        _;
    }

    modifier onlyRelayer {
        require(
            msg.sender == address(this) || msg.sender == resolver.getAddress(CONTRACT_SYNTHETIX_BRIDGE_TO_BASE),
            "Only valid relayer can call"
        );
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != FEE_ADDRESS, "Fee address not allowed");
        _;
    }

    modifier issuanceActive() {
        systemStatus().requireIssuanceActive();
        _;
    }

    /* ========== Proxy Events ========== */

    event FeePeriodClosed(uint feePeriodId);
    bytes32 private constant FEEPERIODCLOSED_SIG = keccak256("FeePeriodClosed(uint256)");

    function emitFeePeriodClosed(uint feePeriodId) internal {
        proxy._emit(abi.encode(feePeriodId), 1, FEEPERIODCLOSED_SIG, 0, 0, 0);
    }

    event FeesClaimed(address account, uint sUSDAmount, uint snxRewards);
    bytes32 private constant FEESCLAIMED_SIG = keccak256("FeesClaimed(address,uint256,uint256)");

    function emitFeesClaimed(
        address account,
        uint sUSDAmount,
        uint snxRewards
    ) internal {
        proxy._emit(abi.encode(account, sUSDAmount, snxRewards), 1, FEESCLAIMED_SIG, 0, 0, 0);
    }
}
