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
  
  //SPDX-License-Identifier: ISC

pragma solidity 0.8.16;

// Libraries
import "./synthetix/DecimalMath.sol";
import "./libraries/ConvertDecimals.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/utils/math/SafeCast.sol";

// Inherited
import "./synthetix/Owned.sol";
import "./libraries/SimpleInitializable.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/security/ReentrancyGuard.sol";

// Interfaces
import "./interfaces/IERC20Decimals.sol";
import "./LiquidityToken.sol";
import "./OptionGreekCache.sol";
import "./OptionMarket.sol";
import "./ShortCollateral.sol";
import "./libraries/PoolHedger.sol";
import "./BaseExchangeAdapter.sol";

/**
 * @title LiquidityPool
 * @author Lyra
 * @dev Holds funds from LPs, which are used for the following purposes:
 * 1. Collateralizing options sold by the OptionMarket.
 * 2. Buying options from users.
 * 3. Delta hedging the LPs.
 * 4. Storing funds for expired in the money options.
 */
contract LiquidityPool is Owned, SimpleInitializable, ReentrancyGuard {
  using DecimalMath for uint;

  struct Collateral {
    // This is the total amount of puts * strike
    uint quote;
    // This is the total amount of calls
    uint base;
  }

  /// These values are all in quoteAsset amounts.
  struct Liquidity {
    // Amount of liquidity available for option collateral and premiums
    uint freeLiquidity;
    // Amount of liquidity available for withdrawals - different to freeLiquidity
    uint burnableLiquidity;
    // Amount of liquidity reserved for long options sold to traders
    uint reservedCollatLiquidity;
    // Portion of liquidity reserved for delta hedging (quote outstanding)
    uint pendingDeltaLiquidity;
    // Current value of delta hedge
    uint usedDeltaLiquidity;
    // Net asset value, including everything and netOptionValue
    uint NAV;
    // longs scaled down by this factor in a contract adjustment event
    uint longScaleFactor;
  }

  struct QueuedDeposit {
    uint id;
    // Who will receive the LiquidityToken minted for this deposit after the wait time
    address beneficiary;
    // The amount of quoteAsset deposited to be converted to LiquidityToken after wait time
    uint amountLiquidity;
    // The amount of LiquidityToken minted. Will equal to 0 if not processed
    uint mintedTokens;
    uint depositInitiatedTime;
  }

  struct QueuedWithdrawal {
    uint id;
    // Who will receive the quoteAsset returned after burning the LiquidityToken
    address beneficiary;
    // The amount of LiquidityToken being burnt after the wait time
    uint amountTokens;
    // The amount of quote transferred. Will equal to 0 if process not started
    uint quoteSent;
    uint withdrawInitiatedTime;
  }

  struct LiquidityPoolParameters {
    // The minimum amount of quoteAsset for a deposit, or the amount of LiquidityToken for a withdrawal
    uint minDepositWithdraw;
    // Time between initiating a deposit and when it can be processed
    uint depositDelay;
    // Time between initiating a withdrawal and when it can be processed
    uint withdrawalDelay;
    // Fee charged on withdrawn funds
    uint withdrawalFee;
    // The address of the "guardian"
    address guardianMultisig;
    // Length of time a deposit/withdrawal since initiation for before a guardian can force process their transaction
    uint guardianDelay;
    // Percentage of liquidity that can be used in a contract adjustment event
    uint adjustmentNetScalingFactor;
    // Scale amount of long call collateral held by the LP
    uint callCollatScalingFactor;
    // Scale amount of long put collateral held by the LP
    uint putCollatScalingFactor;
  }

  struct CircuitBreakerParameters {
    // Percentage of NAV below which the liquidity CB fires
    uint liquidityCBThreshold;
    // Length of time after the liq. CB stops firing during which deposits/withdrawals are still blocked
    uint liquidityCBTimeout;
    // Difference between the spot and GWAV baseline IVs after which point the vol CB will fire
    uint ivVarianceCBThreshold;
    // Difference between the spot and GWAV skew ratios after which point the vol CB will fire
    uint skewVarianceCBThreshold;
    // Length of time after the (base) vol. CB stops firing during which deposits/withdrawals are still blocked
    uint ivVarianceCBTimeout;
    // Length of time after the (skew) vol. CB stops firing during which deposits/withdrawals are still blocked
    uint skewVarianceCBTimeout;
    // When a new board is listed, block deposits/withdrawals
    uint boardSettlementCBTimeout;
    // Timeout on deposits and withdrawals in a contract adjustment event
    uint contractAdjustmentCBTimeout;
  }

  BaseExchangeAdapter internal exchangeAdapter;
  OptionMarket internal optionMarket;
  LiquidityToken internal liquidityToken;
  ShortCollateral internal shortCollateral;
  OptionGreekCache internal greekCache;
  PoolHedger public poolHedger;
  IERC20Decimals public quoteAsset;
  IERC20Decimals internal baseAsset;

  mapping(uint => QueuedDeposit) public queuedDeposits;
  /// @dev The total amount of quoteAsset pending deposit (that hasn't entered the pool)
  uint public totalQueuedDeposits = 0;

  /// @dev The next queue item that needs to be processed
  uint public queuedDepositHead = 1;
  uint public nextQueuedDepositId = 1;

  mapping(uint => QueuedWithdrawal) public queuedWithdrawals;
  uint public totalQueuedWithdrawals = 0;

  /// @dev The next queue item that needs to be processed
  uint public queuedWithdrawalHead = 1;
  uint public nextQueuedWithdrawalId = 1;

  /// @dev Parameters relating to depositing and withdrawing from the Lyra LP
  LiquidityPoolParameters public lpParams;
  /// @dev Parameters relating to circuit breakers
  CircuitBreakerParameters public cbParams;

  // timestamp for when deposits/withdrawals will be available to deposit/withdraw
  // This checks if liquidity is all used - adds 3 days to block.timestamp if it is
  // This also checks if vol variance is high - adds 12 hrs to block.timestamp if it is
  uint public CBTimestamp = 0;

  ////
  // Other Variables
  ////
  /// @dev Amount of collateral locked for outstanding calls and puts sold to users
  Collateral public lockedCollateral;
  /// @dev Total amount of quoteAsset reserved for all settled options that have yet to be paid out
  uint public totalOutstandingSettlements;
  /// @dev Total value not transferred to this contract for all shorts that didn't have enough collateral after expiry
  uint public insolventSettlementAmount;
  /// @dev Total value not transferred to this contract for all liquidations that didn't have enough collateral when liquidated
  uint public liquidationInsolventAmount;

  /// @dev Quote amount that's protected for LPs in case of AMM insolvencies
  uint public protectedQuote;

  ///////////
  // Setup //
  ///////////

  constructor() Owned() {}

  /// @dev Initialise important addresses for the contract
  function init(
    BaseExchangeAdapter _exchangeAdapter,
    OptionMarket _optionMarket,
    LiquidityToken _liquidityToken,
    OptionGreekCache _greekCache,
    PoolHedger _poolHedger,
    ShortCollateral _shortCollateral,
    IERC20Decimals _quoteAsset,
    IERC20Decimals _baseAsset
  ) external onlyOwner initializer {
    exchangeAdapter = _exchangeAdapter;
    optionMarket = _optionMarket;
    liquidityToken = _liquidityToken;
    greekCache = _greekCache;
    shortCollateral = _shortCollateral;
    poolHedger = _poolHedger;
    quoteAsset = _quoteAsset;
    baseAsset = _baseAsset;
  }

  ///////////
  // Admin //
  ///////////

  /// @notice set `LiquidityPoolParameteres`
  function setLiquidityPoolParameters(LiquidityPoolParameters memory _lpParams) external onlyOwner {
    if (
      !(_lpParams.depositDelay < 365 days &&
        _lpParams.withdrawalDelay < 365 days &&
        _lpParams.withdrawalFee < 2e17 &&
        _lpParams.guardianDelay < 365 days)
    ) {
      revert InvalidLiquidityPoolParameters(address(this), _lpParams);
    }

    lpParams = _lpParams;

    emit LiquidityPoolParametersUpdated(lpParams);
  }

  /// @notice set `LiquidityPoolParameteres`
  function setCircuitBreakerParameters(CircuitBreakerParameters memory _cbParams) external onlyOwner {
    if (
      !(_cbParams.liquidityCBThreshold < DecimalMath.UNIT &&
        _cbParams.liquidityCBTimeout < 60 days &&
        _cbParams.ivVarianceCBTimeout < 60 days &&
        _cbParams.skewVarianceCBTimeout < 60 days &&
        _cbParams.boardSettlementCBTimeout < 10 days)
    ) {
      revert InvalidCircuitBreakerParameters(address(this), _cbParams);
    }

    cbParams = _cbParams;

    emit CircuitBreakerParametersUpdated(cbParams);
  }

  /// @dev Swap out current PoolHedger with a new contract
  function setPoolHedger(PoolHedger newPoolHedger) external onlyOwner {
    poolHedger = newPoolHedger;
    emit PoolHedgerUpdated(poolHedger);
  }

  /// @notice Allow incorrectly sent funds to be recovered
  function recoverFunds(IERC20Decimals token, address recipient) external onlyOwner {
    if (token == quoteAsset || token == baseAsset) {
      revert CannotRecoverQuoteBase(address(this));
    }
    token.transfer(recipient, token.balanceOf(address(this)));
  }

  //////////////////////////////
  // Deposits and Withdrawals //
  //////////////////////////////

  /**
   * @notice LP will send sUSD into the contract in return for LiquidityToken (representative of their share of the entire pool)
   *         to be given either instantly (if no live boards) or after the delay period passes (including CBs).
   *         This action is not reversible.
   *
   * @param beneficiary will receive the LiquidityToken after the deposit is processed
   * @param amountQuote is the amount of sUSD the LP is depositing
   */
  function initiateDeposit(address beneficiary, uint amountQuote) external nonReentrant {
    uint realQuote = amountQuote;

    // Convert to 18 dp for LP token minting
    amountQuote = ConvertDecimals.convertTo18(amountQuote, quoteAsset.decimals());

    if (beneficiary == address(0)) {
      revert InvalidBeneficiaryAddress(address(this), beneficiary);
    }
    if (amountQuote < lpParams.minDepositWithdraw) {
      revert MinimumDepositNotMet(address(this), amountQuote, lpParams.minDepositWithdraw);
    }
    // getLiquidity will also make deposits pause when the market/global system is paused
    Liquidity memory liquidity = getLiquidity();
    if (optionMarket.getNumLiveBoards() == 0) {
      uint tokenPrice = _getTokenPrice(liquidity.NAV, getTotalTokenSupply());

      uint amountTokens = amountQuote.divideDecimal(tokenPrice);
      liquidityToken.mint(beneficiary, amountTokens);

      // guaranteed to have long scaling factor of 1 when liv boards == 0
      protectedQuote = (liquidity.NAV + amountQuote).multiplyDecimal(
        DecimalMath.UNIT - lpParams.adjustmentNetScalingFactor
      );

      emit DepositProcessed(msg.sender, beneficiary, 0, amountQuote, tokenPrice, amountTokens, block.timestamp);
    } else {
      QueuedDeposit storage newDeposit = queuedDeposits[nextQueuedDepositId];

      newDeposit.id = nextQueuedDepositId++;
      newDeposit.beneficiary = beneficiary;
      newDeposit.amountLiquidity = amountQuote;
      newDeposit.depositInitiatedTime = block.timestamp;

      totalQueuedDeposits += amountQuote;

      emit DepositQueued(msg.sender, beneficiary, newDeposit.id, amountQuote, totalQueuedDeposits, block.timestamp);
    }

    if (!quoteAsset.transferFrom(msg.sender, address(this), realQuote)) {
      revert QuoteTransferFailed(address(this), msg.sender, address(this), realQuote);
    }
  }

  /**
   * @notice LP instantly burns LiquidityToken, signalling they wish to withdraw
   *         their share of the pool in exchange for quote, to be processed instantly (if no live boards)
   *         or after the delay period passes (including CBs).
   *         This action is not reversible.
   *
   *
   * @param beneficiary will receive
   * @param amountLiquidityToken: is the amount of LiquidityToken the LP is withdrawing
   */
  function initiateWithdraw(address beneficiary, uint amountLiquidityToken) external nonReentrant {
    if (beneficiary == address(0)) {
      revert InvalidBeneficiaryAddress(address(this), beneficiary);
    }

    Liquidity memory liquidity = getLiquidity();
    uint tokenPrice = _getTokenPrice(liquidity.NAV, getTotalTokenSupply());
    uint withdrawalValue = amountLiquidityToken.multiplyDecimal(tokenPrice);

    if (withdrawalValue < lpParams.minDepositWithdraw && amountLiquidityToken < lpParams.minDepositWithdraw) {
      revert MinimumWithdrawNotMet(address(this), withdrawalValue, lpParams.minDepositWithdraw);
    }

    if (optionMarket.getNumLiveBoards() == 0 && liquidity.longScaleFactor == DecimalMath.UNIT) {
      _transferQuote(beneficiary, withdrawalValue);

      protectedQuote = (liquidity.NAV - withdrawalValue).multiplyDecimal(
        DecimalMath.UNIT - lpParams.adjustmentNetScalingFactor
      );

      // quoteReceived in the event is in 18dp
      emit WithdrawProcessed(
        msg.sender,
        beneficiary,
        0,
        amountLiquidityToken,
        tokenPrice,
        withdrawalValue,
        totalQueuedWithdrawals,
        block.timestamp
      );
    } else {
      QueuedWithdrawal storage newWithdrawal = queuedWithdrawals[nextQueuedWithdrawalId];

      newWithdrawal.id = nextQueuedWithdrawalId++;
      newWithdrawal.beneficiary = beneficiary;
      newWithdrawal.amountTokens = amountLiquidityToken;
      newWithdrawal.withdrawInitiatedTime = block.timestamp;

      totalQueuedWithdrawals += amountLiquidityToken;

      emit WithdrawQueued(
        msg.sender,
        beneficiary,
        newWithdrawal.id,
        amountLiquidityToken,
        totalQueuedWithdrawals,
        block.timestamp
      );
    }
    liquidityToken.burn(msg.sender, amountLiquidityToken);
  }

  /// @param limit number of deposit tickets to process in a single transaction to avoid gas limit soft-locks
  function processDepositQueue(uint limit) external nonReentrant {
    Liquidity memory liquidity = _getLiquidityAndUpdateCB();
    uint tokenPrice = _getTokenPrice(liquidity.NAV, getTotalTokenSupply());
    uint processedDeposits;

    for (uint i = 0; i < limit; ++i) {
      QueuedDeposit storage current = queuedDeposits[queuedDepositHead];
      if (!_canProcess(current.depositInitiatedTime, lpParams.depositDelay, queuedDepositHead)) {
        break;
      }

      uint amountTokens = current.amountLiquidity.divideDecimal(tokenPrice);
      liquidityToken.mint(current.beneficiary, amountTokens);
      current.mintedTokens = amountTokens;
      processedDeposits += current.amountLiquidity;

      emit DepositProcessed(
        msg.sender,
        current.beneficiary,
        queuedDepositHead,
        current.amountLiquidity,
        tokenPrice,
        amountTokens,
        block.timestamp
      );
      current.amountLiquidity = 0;

      queuedDepositHead++;
    }

    // only update if deposit processed to avoid changes when CB's are firing
    if (processedDeposits != 0) {
      totalQueuedDeposits -= processedDeposits;

      protectedQuote = (liquidity.NAV + processedDeposits).multiplyDecimal(
        DecimalMath.UNIT - lpParams.adjustmentNetScalingFactor
      );
    }
  }

  /// @param limit number of withdrawal tickets to process in a single transaction to avoid gas limit soft-locks
  function processWithdrawalQueue(uint limit) external nonReentrant {
    uint oldQueuedWithdrawals = totalQueuedWithdrawals;
    for (uint i = 0; i < limit; ++i) {
      (uint totalTokensBurnable, uint tokenPriceWithFee) = _getBurnableTokensAndAddFee();

      QueuedWithdrawal storage current = queuedWithdrawals[queuedWithdrawalHead];

      if (!_canProcess(current.withdrawInitiatedTime, lpParams.withdrawalDelay, queuedWithdrawalHead)) {
        break;
      }

      if (totalTokensBurnable == 0) {
        break;
      }

      uint burnAmount = current.amountTokens;
      if (burnAmount > totalTokensBurnable) {
        burnAmount = totalTokensBurnable;
      }

      current.amountTokens -= burnAmount;
      totalQueuedWithdrawals -= burnAmount;

      uint quoteAmount = burnAmount.multiplyDecimal(tokenPriceWithFee);
      if (_tryTransferQuote(current.beneficiary, quoteAmount)) {
        // success
        current.quoteSent += quoteAmount;
      } else {
        // On unknown failure reason, return LP tokens and continue
        totalQueuedWithdrawals -= current.amountTokens;
        uint returnAmount = current.amountTokens + burnAmount;
        liquidityToken.mint(current.beneficiary, returnAmount);
        current.amountTokens = 0;
        emit WithdrawReverted(
          msg.sender,
          current.beneficiary,
          queuedWithdrawalHead,
          tokenPriceWithFee,
          totalQueuedWithdrawals,
          block.timestamp,
          returnAmount
        );
        queuedWithdrawalHead++;
        continue;
      }

      if (current.amountTokens > 0) {
        emit WithdrawPartiallyProcessed(
          msg.sender,
          current.beneficiary,
          queuedWithdrawalHead,
          burnAmount,
          tokenPriceWithFee,
          quoteAmount,
          totalQueuedWithdrawals,
          block.timestamp
        );
        break;
      }
      emit WithdrawProcessed(
        msg.sender,
        current.beneficiary,
        queuedWithdrawalHead,
        burnAmount,
        tokenPriceWithFee,
        quoteAmount,
        totalQueuedWithdrawals,
        block.timestamp
      );
      queuedWithdrawalHead++;
    }

    // only update if withdrawal processed to avoid changes when CB's are firing
    // getLiquidity() called again to account for withdrawal fee
    if (oldQueuedWithdrawals > totalQueuedWithdrawals) {
      Liquidity memory liquidity = getLiquidity();
      protectedQuote = liquidity.NAV.multiplyDecimal(DecimalMath.UNIT - lpParams.adjustmentNetScalingFactor);
    }
  }

  /// @dev Checks if deposit/withdrawal ticket can be processed
  function _canProcess(uint initiatedTime, uint minimumDelay, uint entryId) internal returns (bool) {
    bool validEntry = initiatedTime != 0;
    // bypass circuit breaker and stale checks if the guardian is calling and their delay has passed
    bool guardianBypass = msg.sender == lpParams.guardianMultisig &&
      initiatedTime + lpParams.guardianDelay < block.timestamp;
    // if minimum delay or circuit breaker timeout hasn't passed, we can't process
    bool delaysExpired = initiatedTime + minimumDelay < block.timestamp && CBTimestamp < block.timestamp;

    // cannot process if greekCache stale
    uint spotPrice = exchangeAdapter.getSpotPriceForMarket(
      address(optionMarket),
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    bool isStale = greekCache.isGlobalCacheStale(spotPrice);

    emit CheckingCanProcess(entryId, !isStale, validEntry, guardianBypass, delaysExpired);

    return validEntry && ((!isStale && delaysExpired) || guardianBypass);
  }

  function _getBurnableTokensAndAddFee() internal returns (uint burnableTokens, uint tokenPriceWithFee) {
    (uint tokenPrice, uint burnableLiquidity) = _getTokenPriceAndBurnableLiquidity();
    tokenPriceWithFee = (optionMarket.getNumLiveBoards() != 0)
      ? tokenPrice.multiplyDecimal(DecimalMath.UNIT - lpParams.withdrawalFee)
      : tokenPrice;

    return (burnableLiquidity.divideDecimal(tokenPriceWithFee), tokenPriceWithFee);
  }

  function _getTokenPriceAndBurnableLiquidity() internal returns (uint tokenPrice, uint burnableLiquidity) {
    Liquidity memory liquidity = _getLiquidityAndUpdateCB();
    uint totalTokenSupply = getTotalTokenSupply();
    tokenPrice = _getTokenPrice(liquidity.NAV, totalTokenSupply);

    return (tokenPrice, liquidity.burnableLiquidity);
  }

  //////////////////////
  // Circuit Breakers //
  //////////////////////

  /// @notice Checks the ivVariance, skewVariance, and liquidity circuit breakers and triggers if necessary
  function updateCBs() external nonReentrant {
    _getLiquidityAndUpdateCB();
  }

  function _updateCBs(
    Liquidity memory liquidity,
    uint maxIvVariance,
    uint maxSkewVariance,
    int optionValueDebt
  ) internal {
    // don't trigger CBs if pool has no open options
    if (liquidity.reservedCollatLiquidity == 0 && optionValueDebt == 0) {
      return;
    }

    uint timeToAdd = 0;

    // if NAV == 0, openAmount will be zero too and _updateCB() won't be called.
    uint freeLiquidityPercent = liquidity.freeLiquidity.divideDecimal(liquidity.NAV);

    bool ivVarianceThresholdCrossed = maxIvVariance > cbParams.ivVarianceCBThreshold;
    bool skewVarianceThresholdCrossed = maxSkewVariance > cbParams.skewVarianceCBThreshold;
    bool liquidityThresholdCrossed = freeLiquidityPercent < cbParams.liquidityCBThreshold;
    bool contractAdjustmentEvent = liquidity.longScaleFactor != DecimalMath.UNIT;

    if (ivVarianceThresholdCrossed) {
      timeToAdd = cbParams.ivVarianceCBTimeout;
    }

    if (skewVarianceThresholdCrossed && cbParams.skewVarianceCBTimeout > timeToAdd) {
      timeToAdd = cbParams.skewVarianceCBTimeout;
    }

    if (liquidityThresholdCrossed && cbParams.liquidityCBTimeout > timeToAdd) {
      timeToAdd = cbParams.liquidityCBTimeout;
    }

    if (contractAdjustmentEvent && cbParams.contractAdjustmentCBTimeout > timeToAdd) {
      timeToAdd = cbParams.contractAdjustmentCBTimeout;
    }

    if (timeToAdd > 0 && CBTimestamp < block.timestamp + timeToAdd) {
      CBTimestamp = block.timestamp + timeToAdd;
      emit CircuitBreakerUpdated(
        CBTimestamp,
        ivVarianceThresholdCrossed,
        skewVarianceThresholdCrossed,
        liquidityThresholdCrossed,
        contractAdjustmentEvent
      );
    }
  }

  ///////////////////////
  // Only OptionMarket //
  ///////////////////////

  /**
   * @notice Locks quote as collateral when the AMM sells a put option.
   *
   * @param amount The amount of quote to lock.
   * @param freeLiquidity The amount of free collateral that can be locked.
   */
  function lockPutCollateral(uint amount, uint freeLiquidity, uint strikeId) external onlyOptionMarket {
    if (amount.multiplyDecimal(lpParams.putCollatScalingFactor) > freeLiquidity) {
      revert LockingMoreQuoteThanIsFree(address(this), amount, freeLiquidity, lockedCollateral);
    }

    _checkCanHedge(amount, true, strikeId);

    lockedCollateral.quote += amount;
    emit PutCollateralLocked(amount, lockedCollateral.quote);
  }

  /**
   * @notice Locks quote as collateral when the AMM sells a call option.
   *
   * @param amount The amount of quote to lock.
   */
  function lockCallCollateral(
    uint amount,
    uint spotPrice,
    uint freeLiquidity,
    uint strikeId
  ) external onlyOptionMarket {
    _checkCanHedge(amount, false, strikeId);

    if (amount.multiplyDecimal(spotPrice).multiplyDecimal(lpParams.callCollatScalingFactor) > freeLiquidity) {
      revert LockingMoreQuoteThanIsFree(
        address(this),
        amount.multiplyDecimal(spotPrice),
        freeLiquidity,
        lockedCollateral
      );
    }
    lockedCollateral.base += amount;
    emit CallCollateralLocked(amount, lockedCollateral.base);
  }

  /**
   * @notice Frees quote collateral when user closes a long put
   *         and sends them the option premium
   *
   * @param amountQuoteFreed The amount of quote to free.
   */
  function freePutCollateralAndSendPremium(
    uint amountQuoteFreed,
    address recipient,
    uint totalCost,
    uint reservedFee,
    uint longScaleFactor
  ) external onlyOptionMarket {
    _freePutCollateral(amountQuoteFreed);
    _sendPremium(recipient, totalCost.multiplyDecimal(longScaleFactor), reservedFee);
  }

  /**
   * @notice Frees/exchange base collateral when user closes a long call
   *         and sends the option premium to the user
   *
   * @param amountBase The amount of base to free and exchange.
   */
  function freeCallCollateralAndSendPremium(
    uint amountBase,
    address recipient,
    uint totalCost,
    uint reservedFee,
    uint longScaleFactor
  ) external onlyOptionMarket {
    _freeCallCollateral(amountBase);
    _sendPremium(recipient, totalCost.multiplyDecimal(longScaleFactor), reservedFee);
  }

  /**
   * @notice Sends premium user selling an option to the pool.
   * @dev The caller must be the OptionMarket.
   *
   * @param recipient The address of the recipient.
   * @param amountContracts The number of contracts sold to AMM.
   * @param premium The amount to transfer to the user.
   * @param freeLiquidity The amount of free collateral liquidity.
   * @param reservedFee The amount collected by the OptionMarket.
   */
  function sendShortPremium(
    address recipient,
    uint amountContracts,
    uint premium,
    uint freeLiquidity,
    uint reservedFee,
    bool isCall,
    uint strikeId
  ) external onlyOptionMarket {
    if (premium + reservedFee > freeLiquidity) {
      revert SendPremiumNotEnoughCollateral(address(this), premium, reservedFee, freeLiquidity);
    }

    // only blocks opening new positions if cannot hedge
    // Since this is opening a short, pool delta exposure is the same direction as if it were a call
    // (user opens a short call, the pool acquires on a long call)
    _checkCanHedge(amountContracts, isCall, strikeId);
    _sendPremium(recipient, premium, reservedFee);
  }

  /**
   * @notice Manages collateral at the time of board liquidation, also converting base received from shortCollateral.
   *
   * @param insolventSettlements amount of AMM profits not paid by shortCollateral due to user insolvencies.
   * @param amountQuoteFreed amount of AMM long put quote collateral that can be freed, including ITM profits.
   * @param amountQuoteReserved amount of AMM quote reserved for long call/put ITM profits.
   * @param amountBaseFreed amount of AMM long call base collateral that can be freed, including ITM profits.
   */
  function boardSettlement(
    uint insolventSettlements,
    uint amountQuoteFreed,
    uint amountQuoteReserved,
    uint amountBaseFreed
  ) external onlyOptionMarket returns (uint) {
    // Update circuit breaker whenever a board is settled, to pause deposits/withdrawals
    // This allows keepers some time to settle insolvent positions
    if (block.timestamp + cbParams.boardSettlementCBTimeout > CBTimestamp) {
      CBTimestamp = block.timestamp + cbParams.boardSettlementCBTimeout;
      emit BoardSettlementCircuitBreakerUpdated(CBTimestamp);
    }

    insolventSettlementAmount += insolventSettlements;

    _freePutCollateral(amountQuoteFreed);
    _freeCallCollateral(amountBaseFreed);

    // If amountQuoteReserved > available liquidity, amountQuoteReserved is scaled down to an available amount
    Liquidity memory liquidity = getLiquidity(); // calculates total pool value and potential scaling

    totalOutstandingSettlements += amountQuoteReserved.multiplyDecimal(liquidity.longScaleFactor);

    emit BoardSettlement(insolventSettlementAmount, amountQuoteReserved, totalOutstandingSettlements);

    if (address(poolHedger) != address(0)) {
      poolHedger.resetInteractionDelay();
    }
    return liquidity.longScaleFactor;
  }

  /**
   * @notice Frees quote when the AMM buys back/settles a put from the user.
   * @param amountQuote The amount of quote to free.
   */
  function _freePutCollateral(uint amountQuote) internal {
    // In case of rounding errors
    amountQuote = amountQuote > lockedCollateral.quote ? lockedCollateral.quote : amountQuote;
    lockedCollateral.quote -= amountQuote;
    emit PutCollateralFreed(amountQuote, lockedCollateral.quote);
  }

  /**
   * @notice Frees quote when the AMM buys back/settles a call from the user.
   * @param amountBase The amount of base to free.
   */

  function _freeCallCollateral(uint amountBase) internal {
    // In case of rounding errors
    amountBase = amountBase > lockedCollateral.base ? lockedCollateral.base : amountBase;
    lockedCollateral.base -= amountBase;
    emit CallCollateralFreed(amountBase, lockedCollateral.base);
  }

  /**
   * @notice Sends the premium to a user who is closing a long or opening a short.
   * @dev The caller must be the OptionMarket.
   *
   * @param recipient The address of the recipient.
   * @param recipientAmount The amount to transfer to the recipient.
   * @param optionMarketPortion The fee to transfer to the optionMarket.
   */
  function _sendPremium(address recipient, uint recipientAmount, uint optionMarketPortion) internal {
    _transferQuote(recipient, recipientAmount);
    _transferQuote(address(optionMarket), optionMarketPortion);

    emit PremiumTransferred(recipient, recipientAmount, optionMarketPortion);
  }

  //////////////////////////
  // Only ShortCollateral //
  //////////////////////////

  /**
   * @notice Transfers long option settlement profits to `user`.
   * @dev The caller must be the ShortCollateral.
   *
   * @param user The address of the user to send the quote.
   * @param amount The amount of quote to send.
   */
  function sendSettlementValue(address user, uint amount) external onlyShortCollateral {
    // To prevent any potential rounding errors
    if (amount > totalOutstandingSettlements) {
      amount = totalOutstandingSettlements;
    }
    totalOutstandingSettlements -= amount;
    _transferQuote(user, amount);

    emit OutstandingSettlementSent(user, amount, totalOutstandingSettlements);
  }

  /**
   * @notice Claims AMM profits that were not paid during boardSettlement() due to
   * total quote insolvencies > total solvent quote collateral.
   * @dev The caller must be ShortCollateral.
   *
   * @param amountQuote The amount of quote to send to the LiquidityPool.
   */
  function reclaimInsolventQuote(uint amountQuote) external onlyShortCollateral {
    Liquidity memory liquidity = getLiquidity();
    if (amountQuote > liquidity.freeLiquidity) {
      revert NotEnoughFreeToReclaimInsolvency(address(this), amountQuote, liquidity);
    }
    _transferQuote(address(shortCollateral), amountQuote);

    insolventSettlementAmount += amountQuote;

    emit InsolventSettlementAmountUpdated(amountQuote, insolventSettlementAmount);
  }

  /**
   * @notice Claims AMM profits that were not paid during boardSettlement() due to
   * total base insolvencies > total solvent base collateral.
   * @dev The caller must be ShortCollateral.
   *
   * @param amountBase The amount of base to send to the LiquidityPool.
   */
  function reclaimInsolventBase(uint amountBase) external onlyShortCollateral {
    Liquidity memory liquidity = getLiquidity();

    uint freeLiq = ConvertDecimals.convertFrom18(liquidity.freeLiquidity, quoteAsset.decimals());

    if (!quoteAsset.approve(address(exchangeAdapter), freeLiq)) {
      revert QuoteApprovalFailure(address(this), address(exchangeAdapter), freeLiq);
    }

    // Assume the inputs and outputs of exchangeAdapter are always 1e18
    (uint quoteSpent, ) = exchangeAdapter.exchangeToExactBaseWithLimit(
      address(optionMarket),
      amountBase,
      liquidity.freeLiquidity
    );
    insolventSettlementAmount += quoteSpent;

    // It is better for the contract to revert if there is not enough here (due to rounding) to keep accounting in
    // ShortCollateral correct. baseAsset can be donated (sent) to this contract to allow this to pass.
    uint realBase = ConvertDecimals.convertFrom18(amountBase, baseAsset.decimals());
    if (realBase > 0 && !baseAsset.transfer(address(shortCollateral), realBase)) {
      revert BaseTransferFailed(address(this), address(this), address(shortCollateral), realBase);
    }

    emit InsolventSettlementAmountUpdated(quoteSpent, insolventSettlementAmount);
  }

  //////////////////////////////
  // Getting Pool Token Value //
  //////////////////////////////

  /// @dev Get total number of oustanding LiquidityToken
  function getTotalTokenSupply() public view returns (uint) {
    return liquidityToken.totalSupply() + totalQueuedWithdrawals;
  }

  /**
   * @notice Get current pool token price and check if market conditions warrant an accurate token price
   *
   * @return tokenPrice price of token
   * @return isStale has global cache not been updated in a long time (if stale, greeks may be inaccurate)
   * @return circuitBreakerExpiry expiry timestamp of the CircuitBreaker (if not expired, greeks may be inaccurate)
   */
  function getTokenPriceWithCheck() external view returns (uint tokenPrice, bool isStale, uint circuitBreakerExpiry) {
    tokenPrice = getTokenPrice();
    uint spotPrice = exchangeAdapter.getSpotPriceForMarket(
      address(optionMarket),
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    isStale = greekCache.isGlobalCacheStale(spotPrice);
    return (tokenPrice, isStale, CBTimestamp);
  }

  /// @dev Get current pool token price without market condition check
  function getTokenPrice() public view returns (uint) {
    Liquidity memory liquidity = getLiquidity();
    return _getTokenPrice(liquidity.NAV, getTotalTokenSupply());
  }

  function _getTokenPrice(uint totalPoolValue, uint totalTokenSupply) internal pure returns (uint) {
    if (totalTokenSupply == 0) {
      return DecimalMath.UNIT;
    }
    return totalPoolValue.divideDecimal(totalTokenSupply);
  }

  ////////////////////////////
  // Getting Pool Liquidity //
  ////////////////////////////

  /**
   * @notice Same return as `getCurrentLiquidity()` but with manual spot price
   */
  function getLiquidity() public view returns (Liquidity memory) {
    uint spotPrice = exchangeAdapter.getSpotPriceForMarket(
      address(optionMarket),
      BaseExchangeAdapter.PriceType.REFERENCE
    );

    // if cache is stale, pendingDelta may be inaccurate
    (uint pendingDelta, uint usedDelta) = _getPoolHedgerLiquidity(spotPrice);
    int optionValueDebt = greekCache.getGlobalOptionValue();
    (uint totalPoolValue, uint longScaleFactor) = _getTotalPoolValueQuote(spotPrice, usedDelta, optionValueDebt);
    uint tokenPrice = _getTokenPrice(totalPoolValue, getTotalTokenSupply());

    Liquidity memory liquidity = _getLiquidity(
      spotPrice,
      totalPoolValue,
      tokenPrice.multiplyDecimal(totalQueuedWithdrawals),
      usedDelta,
      pendingDelta,
      longScaleFactor
    );

    return liquidity;
  }

  function _getLiquidityAndUpdateCB() internal returns (Liquidity memory liquidity) {
    liquidity = getLiquidity();

    // update Circuit Breakers
    OptionGreekCache.GlobalCache memory globalCache = greekCache.getGlobalCache();
    _updateCBs(liquidity, globalCache.maxIvVariance, globalCache.maxSkewVariance, globalCache.netGreeks.netOptionValue);
  }

  /// @dev Gets the current NAV
  function getTotalPoolValueQuote() external view returns (uint totalPoolValue) {
    Liquidity memory liquidity = getLiquidity();
    return liquidity.NAV;
  }

  function _getTotalPoolValueQuote(
    uint basePrice,
    uint usedDeltaLiquidity,
    int optionValueDebt
  ) internal view returns (uint, uint) {
    int totalAssetValue = SafeCast.toInt256(
      ConvertDecimals.convertTo18(quoteAsset.balanceOf(address(this)), quoteAsset.decimals()) +
        ConvertDecimals.convertTo18(baseAsset.balanceOf(address(this)), baseAsset.decimals()).multiplyDecimal(basePrice)
    ) +
      SafeCast.toInt256(usedDeltaLiquidity) -
      SafeCast.toInt256(totalOutstandingSettlements + totalQueuedDeposits);

    if (totalAssetValue < 0) {
      revert NegativeTotalAssetValue(address(this), totalAssetValue);
    }

    // If debt is negative we can simply return TAV - (-debt)
    // availableAssetValue here is +'ve and optionValueDebt is -'ve so we can safely return uint
    if (optionValueDebt < 0) {
      return (SafeCast.toUint256(totalAssetValue - optionValueDebt), DecimalMath.UNIT);
    }

    // ensure a percentage of the pool's NAV is always protected from AMM's insolvency
    int availableAssetValue = totalAssetValue - int(protectedQuote);
    uint longScaleFactor = DecimalMath.UNIT;

    // in extreme situations, if the TAV < reserved cash, set long options to worthless
    if (availableAssetValue < 0) {
      return (SafeCast.toUint256(totalAssetValue), 0);
    }

    // NOTE: the longScaleFactor is calculated using the total option debt however only the long debts are scaled down
    // when paid out. Therefore the asset value affected is less than the real amount.
    if (availableAssetValue < optionValueDebt) {
      // both guaranteed to be positive
      longScaleFactor = SafeCast.toUint256(availableAssetValue).divideDecimal(SafeCast.toUint256(optionValueDebt));
    }

    return (
      SafeCast.toUint256(totalAssetValue) - SafeCast.toUint256(optionValueDebt).multiplyDecimal(longScaleFactor),
      longScaleFactor
    );
  }

  function _getLiquidity(
    uint basePrice,
    uint totalPoolValue,
    uint reservedTokenValue,
    uint usedDelta,
    uint pendingDelta,
    uint longScaleFactor
  ) internal view returns (Liquidity memory) {
    Liquidity memory liquidity = Liquidity(0, 0, 0, 0, 0, 0, 0);
    liquidity.NAV = totalPoolValue;
    liquidity.usedDeltaLiquidity = usedDelta;

    uint usedQuote = totalOutstandingSettlements + totalQueuedDeposits;
    uint totalQuote = ConvertDecimals.convertTo18(quoteAsset.balanceOf(address(this)), quoteAsset.decimals());
    uint availableQuote = totalQuote > usedQuote ? totalQuote - usedQuote : 0;

    liquidity.pendingDeltaLiquidity = pendingDelta > availableQuote ? availableQuote : pendingDelta;
    availableQuote -= liquidity.pendingDeltaLiquidity;

    // Only reserve lockedColleratal x scalingFactor which unlocks more liquidity
    // No longer need to lock one ETH worth of quote per call sold
    uint reservedCollatLiquidity = lockedCollateral.quote.multiplyDecimal(lpParams.putCollatScalingFactor) +
      lockedCollateral.base.multiplyDecimal(basePrice).multiplyDecimal(lpParams.callCollatScalingFactor);
    liquidity.reservedCollatLiquidity = availableQuote > reservedCollatLiquidity
      ? reservedCollatLiquidity
      : availableQuote;

    availableQuote -= liquidity.reservedCollatLiquidity;
    liquidity.freeLiquidity = availableQuote > reservedTokenValue ? availableQuote - reservedTokenValue : 0;
    liquidity.burnableLiquidity = availableQuote;
    liquidity.longScaleFactor = longScaleFactor;

    return liquidity;
  }

  /////////////////////
  // Exchanging Base //
  /////////////////////

  /// @notice Will exchange any base balance for quote
  function exchangeBase() public nonReentrant {
    uint currentBaseBalance = baseAsset.balanceOf(address(this));
    if (currentBaseBalance > 0) {
      if (!baseAsset.approve(address(exchangeAdapter), currentBaseBalance)) {
        revert BaseApprovalFailure(address(this), address(exchangeAdapter), currentBaseBalance);
      }
      currentBaseBalance = ConvertDecimals.convertTo18(currentBaseBalance, baseAsset.decimals());
      uint quoteReceived = exchangeAdapter.exchangeFromExactBase(address(optionMarket), currentBaseBalance);
      emit BaseSold(currentBaseBalance, quoteReceived);
    }
  }

  //////////
  // Misc //
  //////////

  /// @notice returns the LiquidityPoolParameters struct
  function getLpParams() external view returns (LiquidityPoolParameters memory) {
    return lpParams;
  }

  /// @notice returns the CircuitBreakerParameters struct
  function getCBParams() external view returns (CircuitBreakerParameters memory) {
    return cbParams;
  }

  /// @notice updates `liquidationInsolventAmount` if liquidated position is insolveny
  function updateLiquidationInsolvency(uint insolvencyAmountInQuote) external onlyOptionMarket {
    liquidationInsolventAmount += insolvencyAmountInQuote;
  }

  /**
   * @dev get the total amount of quote used and pending for delta hedging
   *
   * @return pendingDeltaLiquidity The amount of liquidity reserved for delta hedging that hasn't occured yet
   * @return usedDeltaLiquidity The value of the current hedge position (long value OR collateral - short debt)
   */
  function _getPoolHedgerLiquidity(
    uint basePrice
  ) internal view returns (uint pendingDeltaLiquidity, uint usedDeltaLiquidity) {
    if (address(poolHedger) != address(0)) {
      return poolHedger.getHedgingLiquidity(basePrice);
    }
    return (0, 0);
  }

  function _checkCanHedge(uint amountOptions, bool increasesPoolDelta, uint strikeId) internal view {
    if (address(poolHedger) == address(0)) {
      return;
    }
    if (!poolHedger.canHedge(amountOptions, increasesPoolDelta, strikeId)) {
      revert UnableToHedgeDelta(address(this), amountOptions, increasesPoolDelta, strikeId);
    }
  }

  /**
   * @notice Sends quote to the PoolHedger.
   * @dev Transfer amount up to `pendingLiquidity + freeLiquidity`.
   * The hedger must determine what to do with the amount received.
   *
   * @param amount The amount requested by the PoolHedger.
   */
  function transferQuoteToHedge(uint amount) external onlyPoolHedger returns (uint) {
    Liquidity memory liquidity = getLiquidity();

    uint available = liquidity.pendingDeltaLiquidity + liquidity.freeLiquidity;

    amount = amount > available ? available : amount;

    _transferQuote(address(poolHedger), amount);
    emit QuoteTransferredToPoolHedger(amount);

    return amount;
  }

  function _transferQuote(address to, uint amount) internal {
    amount = ConvertDecimals.convertFrom18(amount, quoteAsset.decimals());
    if (amount > 0) {
      if (!quoteAsset.transfer(to, amount)) {
        revert QuoteTransferFailed(address(this), address(this), to, amount);
      }
    }
  }

  function _tryTransferQuote(address to, uint amount) internal returns (bool success) {
    amount = ConvertDecimals.convertFrom18(amount, quoteAsset.decimals());
    if (amount > 0) {
      try quoteAsset.transfer(to, amount) returns (bool res) {
        return res;
      } catch {
        return false;
      }
    }
    return true;
  }

  ///////////////
  // Modifiers //
  ///////////////

  modifier onlyPoolHedger() {
    if (msg.sender != address(poolHedger)) {
      revert OnlyPoolHedger(address(this), msg.sender, address(poolHedger));
    }
    _;
  }

  modifier onlyOptionMarket() {
    if (msg.sender != address(optionMarket)) {
      revert OnlyOptionMarket(address(this), msg.sender, address(optionMarket));
    }
    _;
  }

  modifier onlyShortCollateral() {
    if (msg.sender != address(shortCollateral)) {
      revert OnlyShortCollateral(address(this), msg.sender, address(shortCollateral));
    }
    _;
  }

  ////////////
  // Events //
  ////////////

  /// @dev Emitted whenever the pool parameters are updated
  event LiquidityPoolParametersUpdated(LiquidityPoolParameters lpParams);

  /// @dev Emitted whenever the circuit breaker parameters are updated
  event CircuitBreakerParametersUpdated(CircuitBreakerParameters cbParams);

  /// @dev Emitted whenever the poolHedger address is modified
  event PoolHedgerUpdated(PoolHedger poolHedger);

  /// @dev Emitted when AMM put collateral is locked.
  event PutCollateralLocked(uint quoteLocked, uint lockedCollateralQuote);

  /// @dev Emitted when quote is freed.
  event PutCollateralFreed(uint quoteFreed, uint lockedCollateralQuote);

  /// @dev Emitted when AMM call collateral is locked.
  event CallCollateralLocked(uint baseLocked, uint lockedCollateralBase);

  /// @dev Emitted when base is freed.
  event CallCollateralFreed(uint baseFreed, uint lockedCollateralBase);

  /// @dev Emitted when a board is settled.
  event BoardSettlement(uint insolventSettlementAmount, uint amountQuoteReserved, uint totalOutstandingSettlements);

  /// @dev Emitted when reserved quote is sent.
  event OutstandingSettlementSent(address indexed user, uint amount, uint totalOutstandingSettlements);

  /// @dev Emitted whenever quote is exchanged for base
  event BasePurchased(uint quoteSpent, uint baseReceived);

  /// @dev Emitted whenever base is exchanged for quote
  event BaseSold(uint amountBase, uint quoteReceived);

  /// @dev Emitted whenever premium is sent to a trader closing their position
  event PremiumTransferred(address indexed recipient, uint recipientPortion, uint optionMarketPortion);

  /// @dev Emitted whenever quote is sent to the PoolHedger
  event QuoteTransferredToPoolHedger(uint amountQuote);

  /// @dev Emitted whenever the insolvent settlement amount is updated (settlement and excess)
  event InsolventSettlementAmountUpdated(uint amountQuoteAdded, uint totalInsolventSettlementAmount);

  /// @dev Emitted whenever a user deposits and enters the queue.
  event DepositQueued(
    address indexed depositor,
    address indexed beneficiary,
    uint indexed depositQueueId,
    uint amountDeposited,
    uint totalQueuedDeposits,
    uint timestamp
  );

  /// @dev Emitted whenever a deposit gets processed. Note, can be processed without being queued.
  ///  QueueId of 0 indicates it was not queued.
  event DepositProcessed(
    address indexed caller,
    address indexed beneficiary,
    uint indexed depositQueueId,
    uint amountDeposited,
    uint tokenPrice,
    uint tokensReceived,
    uint timestamp
  );

  /// @dev Emitted whenever a deposit gets processed. Note, can be processed without being queued.
  ///  QueueId of 0 indicates it was not queued.
  event WithdrawProcessed(
    address indexed caller,
    address indexed beneficiary,
    uint indexed withdrawalQueueId,
    uint amountWithdrawn,
    uint tokenPrice,
    uint quoteReceived,
    uint totalQueuedWithdrawals,
    uint timestamp
  );
  event WithdrawPartiallyProcessed(
    address indexed caller,
    address indexed beneficiary,
    uint indexed withdrawalQueueId,
    uint amountWithdrawn,
    uint tokenPrice,
    uint quoteReceived,
    uint totalQueuedWithdrawals,
    uint timestamp
  );
  event WithdrawReverted(
    address indexed caller,
    address indexed beneficiary,
    uint indexed withdrawalQueueId,
    uint tokenPrice,
    uint totalQueuedWithdrawals,
    uint timestamp,
    uint tokensReturned
  );
  event WithdrawQueued(
    address indexed withdrawer,
    address indexed beneficiary,
    uint indexed withdrawalQueueId,
    uint amountWithdrawn,
    uint totalQueuedWithdrawals,
    uint timestamp
  );

  /// @dev Emitted whenever the CB timestamp is updated
  event CircuitBreakerUpdated(
    uint newTimestamp,
    bool ivVarianceThresholdCrossed,
    bool skewVarianceThresholdCrossed,
    bool liquidityThresholdCrossed,
    bool contractAdjustmentEvent
  );

  /// @dev Emitted whenever the CB timestamp is updated from a board settlement
  event BoardSettlementCircuitBreakerUpdated(uint newTimestamp);

  /// @dev Emitted whenever a queue item is checked for the ability to be processed
  event CheckingCanProcess(uint entryId, bool boardNotStale, bool validEntry, bool guardianBypass, bool delaysExpired);

  ////////////
  // Errors //
  ////////////
  // Admin
  error InvalidLiquidityPoolParameters(address thrower, LiquidityPoolParameters lpParams);
  error InvalidCircuitBreakerParameters(address thrower, CircuitBreakerParameters cbParams);
  error CannotRecoverQuoteBase(address thrower);

  // Deposits and withdrawals
  error InvalidBeneficiaryAddress(address thrower, address beneficiary);
  error MinimumDepositNotMet(address thrower, uint amountQuote, uint minDeposit);
  error MinimumWithdrawNotMet(address thrower, uint amountQuote, uint minWithdraw);

  // Liquidity and accounting
  error LockingMoreQuoteThanIsFree(address thrower, uint quoteToLock, uint freeLiquidity, Collateral lockedCollateral);
  error SendPremiumNotEnoughCollateral(address thrower, uint premium, uint reservedFee, uint freeLiquidity);
  error NotEnoughFreeToReclaimInsolvency(address thrower, uint amountQuote, Liquidity liquidity);
  error OptionValueDebtExceedsTotalAssets(address thrower, int totalAssetValue, int optionValueDebt);
  error NegativeTotalAssetValue(address thrower, int totalAssetValue);

  // Access
  error OnlyPoolHedger(address thrower, address caller, address poolHedger);
  error OnlyOptionMarket(address thrower, address caller, address optionMarket);
  error OnlyShortCollateral(address thrower, address caller, address poolHedger);

  // Token transfers
  error QuoteTransferFailed(address thrower, address from, address to, uint realAmount);
  error BaseTransferFailed(address thrower, address from, address to, uint realAmount);
  error QuoteApprovalFailure(address thrower, address approvee, uint amount);
  error BaseApprovalFailure(address thrower, address approvee, uint amount);

  // @dev Emmitted whenever a position can not be opened as the hedger is unable to hedge
  error UnableToHedgeDelta(address thrower, uint amountOptions, bool increasesDelta, uint strikeId);
}
