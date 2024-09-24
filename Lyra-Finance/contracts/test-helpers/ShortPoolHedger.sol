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

//
//  ___    _____     _   _  _____  _____     ___    ___    _   _  _  ___    _       _
// (  _`\ (  _  )   ( ) ( )(  _  )(_   _)   |  _`\ (  _`\ ( ) ( )(_)(  _`\ ( )  _  ( )
// | | ) || ( ) |   | `\| || ( ) |  | |     | (_) )| (_(_)| | | || || (_(_)| | ( ) | |
// | | | )| | | |   | , ` || | | |  | |     | ,  / |  _)_ | | | || ||  _)_ | | | | | |
// | |_) || (_) |   | |`\ || (_) |  | |     | |\ \ | (_( )| \_/ || || (_( )| (_/ \_) |
// (____/'(_____)   (_) (_)(_____)  (_)     (_) (_)(____/'`\___/'(_)(____/'`\___x___/'
//

pragma solidity 0.8.16;

// Libraries
import "../synthetix/DecimalMath.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/utils/math/SafeCast.sol";
import "../libraries/ConvertDecimals.sol";

// Inherited
import "../synthetix/Owned.sol";
import "../libraries/SimpleInitializable.sol";
import "../libraries/PoolHedger.sol";
import "Lyra-Finance/openzeppelin-contracts-4.4.1/security/ReentrancyGuard.sol";

// Interfaces
import "../LiquidityPool.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/ICollateralShort.sol";
import "./SynthetixAdapter.sol";
import "../OptionMarket.sol";
import "../OptionGreekCache.sol";

/**
 * @title PoolHedger
 * @author Lyra
 * @dev Uses the delta hedging funds from the LiquidityPool to hedge option deltas, so LPs are minimally exposed to
 * movements in the underlying asset price.
 */
contract ShortPoolHedger is PoolHedger, Owned, SimpleInitializable, ReentrancyGuard {
  using DecimalMath for uint;

  bytes32 private constant CONTRACT_COLLATERAL_SHORT = "CollateralShort";

  SynthetixAdapter internal synthetixAdapter;
  OptionMarket internal optionMarket;
  OptionGreekCache internal optionGreekCache;
  IERC20Decimals internal quoteAsset;
  IERC20Decimals internal baseAsset;

  ICollateralShort public collateralShort;

  /// @dev The ID of our short that is opened when we open short account.
  uint public shortId;
  uint public shortBuffer;

  uint public deltaThresold = 100; // initial delta threshold.

  ///////////
  // Setup //
  ///////////

  constructor() Owned() {}

  /**
   * @dev Initialize the contract.
   *
   * @param _synthetixAdapter SynthetixAdapter address
   * @param _optionMarket OptionMarket address
   * @param _liquidityPool LiquidityPool address
   * @param _quoteAsset Quote asset address
   * @param _baseAsset Base asset address
   */
  function init(
    SynthetixAdapter _synthetixAdapter,
    OptionMarket _optionMarket,
    OptionGreekCache _optionGreekCache,
    LiquidityPool _liquidityPool,
    IERC20Decimals _quoteAsset,
    IERC20Decimals _baseAsset
  ) external onlyOwner initializer {
    synthetixAdapter = _synthetixAdapter;
    optionMarket = _optionMarket;
    optionGreekCache = _optionGreekCache;
    liquidityPool = _liquidityPool;
    quoteAsset = _quoteAsset;
    baseAsset = _baseAsset;

    synthetixAdapter.delegateApprovals().approveExchangeOnBehalf(address(synthetixAdapter));
    collateralShort = ICollateralShort(synthetixAdapter.addressResolver().getAddress(CONTRACT_COLLATERAL_SHORT));
  }

  ///////////
  // Admin //
  ///////////

  /**
   * @dev Update pool hedger parameters.
   */
  function setPoolHedgerParams(PoolHedgerParameters memory _poolHedgerParams) external onlyOwner {
    _setPoolHedgerParams(_poolHedgerParams);
  }

  /// @dev update the shortBuffer of the contract. 1.0 (1e18) means collateral equal to debt, which would get the
  ///  contract liquidated. 2.0 would be considered very safe.
  function setShortBuffer(uint _shortBuffer) external onlyOwner {
    if (_shortBuffer < DecimalMath.UNIT) {
      revert InvalidShortBuffer(address(this), _shortBuffer);
    }
    shortBuffer = _shortBuffer;
    emit ShortBufferSet(shortBuffer);
  }

  /// @dev update the collateralShort address based on the synthetix addressResolver
  function updateCollateralShortAddress() external {
    collateralShort = ICollateralShort(synthetixAdapter.addressResolver().getAddress(CONTRACT_COLLATERAL_SHORT));
    emit ShortCollateralSet(collateralShort);
  }

  /// @dev In case of an update to the synthetix contract that revokes the approval
  function updateDelegateApproval() external onlyOwner {
    synthetixAdapter.delegateApprovals().approveExchangeOnBehalf(address(synthetixAdapter));
  }

  function canHedge(uint, bool, uint) external view virtual override returns (bool) {
    return true;
  }

  ///////////////////
  // Opening Short //
  ///////////////////
  /**
   * @notice Opens/reopens short account if the old one was closed or liquidated.
   * @dev opens short account with min colalteral and 0 amount
   */
  function openShortAccount() external nonReentrant {
    SynthetixAdapter.ExchangeParams memory exchangeParams = synthetixAdapter.getExchangeParams(address(optionMarket));

    (, , , , , , , uint interestIndex, ) = collateralShort.loans(shortId);
    // Cannot open a new short if the old one is still open
    if (interestIndex != 0) {
      revert ShortAccountAlreadyOpen(address(this), shortId);
    }

    _openShortAccount(exchangeParams);
  }

  /**
   * @dev Opens new short account with min collateral and 0 amount.
   *
   * @param exchangeParams The ExchangeParams.
   */
  function _openShortAccount(SynthetixAdapter.ExchangeParams memory exchangeParams) internal {
    uint minCollateral = collateralShort.minCollateral();

    if (!quoteAsset.approve(address(collateralShort), type(uint).max)) {
      revert QuoteApprovalFailure(address(this), address(collateralShort), type(uint).max);
    }

    // Open a short with min collateral and 0 amount, to get a static Id for this contract to use.
    liquidityPool.transferQuoteToHedge(minCollateral);

    uint currentBalance = ConvertDecimals.convertTo18(quoteAsset.balanceOf(address(this)), quoteAsset.decimals());
    if (currentBalance < minCollateral) {
      revert NotEnoughQuoteForMinCollateral(address(this), currentBalance, minCollateral);
    }

    // This will revert if the LP did not provide enough quote
    shortId = collateralShort.open(minCollateral, 0, exchangeParams.baseKey);
    _sendAllQuoteToLP();
    emit OpenedShortAccount(shortId);
    emit ShortSetTo(0, 0, 0, minCollateral);
  }

  /////////////
  // Getters //
  /////////////

  /**
   * @dev Returns short balance and collateral owned by this contract.
   */
  function getShortPosition() public view returns (uint shortBalance, uint collateral) {
    if (shortId == 0) {
      return (0, 0);
    }
    return collateralShort.getShortAndCollateral(address(this), shortId);
  }

  /**
   * @dev Returns the current hedged netDelta position.
   */
  function getCurrentHedgedNetDelta() external view override returns (int) {
    uint longBalance = baseAsset.balanceOf(address(this));
    (uint shortBalance, ) = getShortPosition();

    return SafeCast.toInt256(longBalance) - SafeCast.toInt256(shortBalance);
  }

  /// @notice Returns pending delta hedge liquidity and used delta hedge liquidity
  /// @dev include funds potentially transferred to the contract
  function getHedgingLiquidity(
    uint spotPrice
  ) external view override returns (uint pendingDeltaLiquidity, uint usedDeltaLiquidity) {
    // Get capped expected hedge
    int expectedHedge = getCappedExpectedHedge();

    // Get current hedge
    (uint shortBalance, uint shortCollateral) = getShortPosition();
    uint longBalance = baseAsset.balanceOf(address(this));
    uint totalBal = shortBalance + longBalance;

    // Include both long and short, to deal with "donations"
    usedDeltaLiquidity += longBalance.multiplyDecimal(spotPrice);

    uint shortOwed = shortBalance.multiplyDecimal(spotPrice);
    if (shortCollateral > shortOwed) {
      usedDeltaLiquidity += shortCollateral - shortOwed;
    }

    // Estimate value of desired hedge
    if (expectedHedge > 0) {
      if (Math.abs(expectedHedge) > totalBal) {
        pendingDeltaLiquidity = (Math.abs(expectedHedge) - totalBal).multiplyDecimal(spotPrice);
      }
    } else if (expectedHedge < 0) {
      if (Math.abs(expectedHedge) > totalBal) {
        pendingDeltaLiquidity = (Math.abs(expectedHedge) - totalBal).multiplyDecimal(spotPrice).multiplyDecimal(
          shortBuffer
        );
      }
    }
  }

  //////////////
  // External //
  //////////////

  /**
   * @dev Retrieves the netDelta from the OptionGreekCache and updates the hedge position based off base
   *      asset balance of the liquidityPool minus netDelta (from OptionGreekCache)
   */
  function hedgeDelta() external payable override nonReentrant {
    // Subtract the baseAsset balance from netDelta, to account for the variance from collateral held by LP.
    int expectedHedge = getCappedExpectedHedge();

    // Bypass interactionDelay if we want to set netDelta to 0
    if (expectedHedge != 0 && poolHedgerParams.interactionDelay != 0) {
      if (lastInteraction + poolHedgerParams.interactionDelay > block.timestamp) {
        revert InteractionDelayNotExpired(
          address(this),
          lastInteraction,
          poolHedgerParams.interactionDelay,
          block.timestamp
        );
      }
    }

    _hedgeDelta(expectedHedge);
  }

  /**
   * @dev Updates the collateral held in the short to prevent liquidations and
   * return excess collateral without checking/triggering the interaction delay.
   */
  function updateCollateral() external payable override nonReentrant {
    uint spotPrice = synthetixAdapter.getSpotPriceForMarket(
      address(optionMarket),
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    (uint shortBalance, uint startCollateral) = getShortPosition();

    // do not change shortBalance
    uint newCollateral = _updateCollateral(spotPrice, shortBalance, startCollateral);
    _sendAllQuoteToLP();
    emit ShortSetTo(shortBalance, shortBalance, startCollateral, newCollateral);
  }

  //////////////
  // Internal //
  //////////////

  /**
   * @dev Updates the hedge position. This may need to be called several times as it will only do one step at a time
   * I.e. to go from a long position to asho
   *
   * @param expectedHedge The expected final hedge value.
   */
  function _hedgeDelta(int expectedHedge) internal {
    SynthetixAdapter.ExchangeParams memory exchangeParams = synthetixAdapter.getExchangeParams(address(optionMarket));
    uint longBalance = baseAsset.balanceOf(address(this));
    (uint shortBalance, uint collateral) = getShortPosition();

    int oldHedge = longBalance != 0 ? SafeCast.toInt256(longBalance) : -SafeCast.toInt256(shortBalance);
    int newHedge = _updatePosition(exchangeParams, longBalance, shortBalance, collateral, expectedHedge);

    emit PositionUpdated(oldHedge, newHedge, expectedHedge);

    if (newHedge != 0 && newHedge != oldHedge) {
      lastInteraction = block.timestamp;
    }

    // All proceeds should be sent back to the LP
    _sendAllQuoteToLP();
  }

  /**
   * @dev Updates the hedge contract based off a new netDelta.
   *
   * @param exchangeParams Globals related to exchanging synths
   * @param longBalance The current long base balance of the PoolHedger
   * @param shortBalance The current short balance of the PoolHedger
   * @param collateral The current quote collateral for shorts of the PoolHedger
   * @param expectedHedge The amount of baseAsset exposure needed to hedge delta risk.
   */
  function _updatePosition(
    SynthetixAdapter.ExchangeParams memory exchangeParams,
    uint longBalance,
    uint shortBalance,
    uint collateral,
    int expectedHedge
  ) internal returns (int) {
    if (expectedHedge >= 0) {
      // we need to be net long the asset.
      uint expectedLong = uint(expectedHedge);
      // if we have any short open, close it all.
      if (shortBalance > 0 || collateral > 0) {
        _setShortTo(exchangeParams.spotPrice, 0, shortBalance, collateral);
      }

      if (expectedLong > longBalance) {
        // Must buy baseAsset
        return SafeCast.toInt256(_increaseLong(exchangeParams, expectedLong - longBalance, longBalance));
      } else if (expectedLong < longBalance) {
        // Must sell baseAsset
        return SafeCast.toInt256(_decreaseLong(longBalance - expectedLong, longBalance));
      } else {
        // longBalance == expectedLong
        return SafeCast.toInt256(longBalance);
      }
    } else {
      // we need to be net short the asset.
      uint expectedShort = uint(-expectedHedge);
      // if we have any of the spot left, sell it all.
      if (longBalance > 0) {
        _decreaseLong(longBalance, longBalance);
      }

      return -SafeCast.toInt256(_setShortTo(exchangeParams.spotPrice, expectedShort, shortBalance, collateral));
    }
  }

  /**
   * @dev Increases the long exposure of the hedge contract.
   *
   * @param exchangeParams The ExchangeParams.
   * @param amount The amount of baseAsset to purchase.
   */
  function _increaseLong(
    SynthetixAdapter.ExchangeParams memory exchangeParams,
    uint amount,
    uint currentBalance
  ) internal returns (uint newBalance) {
    uint base = amount.divideDecimal(DecimalMath.UNIT - exchangeParams.quoteBaseFeeRate);
    uint purchaseAmount = base.multiplyDecimal(exchangeParams.spotPrice);
    uint receivedQuote = liquidityPool.transferQuoteToHedge(purchaseAmount);

    // We buy as much as is possible with the quote given
    if (receivedQuote < purchaseAmount) {
      purchaseAmount = receivedQuote;
    }
    // buy the base asset.
    quoteAsset.approve(address(synthetixAdapter), purchaseAmount);
    synthetixAdapter.exchangeFromExactQuote(address(optionMarket), purchaseAmount);
    newBalance = baseAsset.balanceOf(address(this));
    emit LongSetTo(currentBalance, newBalance);
  }

  /**
   * @dev Decreases the long exposure of the hedge contract.
   *
   * @param amount The amount of baseAsset to sell.
   */
  function _decreaseLong(uint amount, uint currentBalance) internal returns (uint newBalance) {
    baseAsset.approve(address(synthetixAdapter), amount);
    // assumption here is that we have enough to sell, will throw if not
    synthetixAdapter.exchangeFromExactBase(address(optionMarket), amount);
    newBalance = baseAsset.balanceOf(address(this));
    emit LongSetTo(currentBalance, newBalance);
  }

  /**
   * @dev Increases or decreases short to get to this amount of shorted baseAsset at the shortBuffer ratio. Note,
   * hedge() may have to be called a second time to re-balance collateral after calling `repayWithCollateral`. As that
   * disregards the desired ratio.
   *
   * @param spotPrice The spot price of the base asset.
   * @param desiredShort The desired short balance.
   * @param startShort Trusted value for current short amount, in base.
   * @param startCollateral Trusted value for current amount of collateral, in quote.
   */

  function _setShortTo(
    uint spotPrice,
    uint desiredShort,
    uint startShort,
    uint startCollateral
  ) internal returns (uint newShort) {
    uint newCollateral;
    if (startShort <= desiredShort) {
      newCollateral = _updateCollateral(spotPrice, desiredShort, startCollateral);
      newCollateral = ConvertDecimals.convertFrom18(newCollateral, quoteAsset.decimals());
      uint maxPossibleShort = newCollateral.divideDecimal(spotPrice).divideDecimal(shortBuffer);

      if (maxPossibleShort > startShort) {
        collateralShort.draw(
          shortId,
          ConvertDecimals.convertFrom18(maxPossibleShort - startShort, quoteAsset.decimals())
        );
      } else if (maxPossibleShort < startShort) {
        collateralShort.repayWithCollateral(
          shortId,
          ConvertDecimals.convertFrom18(startShort - maxPossibleShort, quoteAsset.decimals())
        );
      } else {
        newShort = startShort;
      }
      (newShort, ) = getShortPosition();
    } else {
      collateralShort.repayWithCollateral(
        shortId,
        ConvertDecimals.convertFrom18(startShort - desiredShort, quoteAsset.decimals())
      );
      (newShort, newCollateral) = getShortPosition();

      newCollateral = _updateCollateral(spotPrice, newShort, newCollateral);
    }

    emit ShortSetTo(startShort, newShort, startCollateral, newCollateral);
    return newShort;
  }

  function _updateCollateral(
    uint spotPrice,
    uint shortBalance,
    uint startCollateral
  ) internal returns (uint newCollateral) {
    uint desiredCollateral = shortBalance.multiplyDecimal(spotPrice).multiplyDecimal(shortBuffer);
    startCollateral = ConvertDecimals.convertFrom18(startCollateral, quoteAsset.decimals());
    if (startCollateral < desiredCollateral) {
      uint received = liquidityPool.transferQuoteToHedge(desiredCollateral - startCollateral);
      if (received > 0) {
        collateralShort.deposit(address(this), shortId, received);
      }
    } else if (startCollateral > desiredCollateral) {
      collateralShort.withdraw(
        shortId,
        ConvertDecimals.convertFrom18(startCollateral - desiredCollateral, quoteAsset.decimals())
      );
    }
    (, newCollateral) = getShortPosition();
  }

  /**
   * @dev Calculates the expected delta hedge that hedger must perform and
   * adjusts the result down to the hedgeCap param if needed.
   */
  function getCappedExpectedHedge() public view override returns (int cappedExpectedHedge) {
    // Update any stale boards to get an accurate netDelta value
    // LPs only hold quote as collateral
    int expectedHedge = optionGreekCache.getGlobalNetDelta();

    bool exceedsCap = Math.abs(expectedHedge) > poolHedgerParams.hedgeCap;

    // Cap expected hedge
    if (expectedHedge < 0 && exceedsCap) {
      cappedExpectedHedge = -SafeCast.toInt256(poolHedgerParams.hedgeCap);
    } else if (expectedHedge >= 0 && exceedsCap) {
      cappedExpectedHedge = SafeCast.toInt256(poolHedgerParams.hedgeCap);
    } else {
      cappedExpectedHedge = expectedHedge;
    }
  }

  /**
   * @dev Sends all quote asset deposited in this contract to the `LiquidityPool`.
   */
  function _sendAllQuoteToLP() internal {
    uint quoteBal = quoteAsset.balanceOf(address(this));
    if (!quoteAsset.transfer(address(liquidityPool), quoteBal)) {
      revert QuoteTransferFailed(address(this), address(this), address(liquidityPool), quoteBal);
    }
    emit QuoteReturnedToLP(quoteBal);
  }

  /**
   * @dev Returns the poolHedgerParams and shortBuffer in a single call
   */
  function getPoolHedgerSettings()
    external
    view
    returns (PoolHedgerParameters memory _poolHedgerParams, uint _shortBuffer)
  {
    return (poolHedgerParams, shortBuffer);
  }

  ////////////
  // Events //
  ////////////
  /**
   * @dev Emitted when the collateralShort address is updated
   */
  event ShortCollateralSet(ICollateralShort collateralShort);
  /**
   * @dev Emitted when pool hedger parameters are updated.
   */
  event ShortBufferSet(uint newShortBuffer);
  /**
   * @dev Emitted when the short is initialized.
   */
  event OpenedShortAccount(uint shortId);
  /**
   * @dev Emitted when the hedge position is updated.
   */
  event PositionUpdated(int oldNetDelta, int currentNetDelta, int expectedNetDelta);
  /**
   * @dev Emitted when the long exposure of the hedge contract is adjusted.
   */
  event LongSetTo(uint oldAmount, uint newAmount);
  /**
   * @dev Emitted when short or short collateral is adjusted.
   */
  event ShortSetTo(uint oldShort, uint newShort, uint oldCollateral, uint newCollateral);
  /**
   * @dev Emitted when proceeds of the short are sent back to the LP.
   */
  event QuoteReturnedToLP(uint amountQuote);

  ////////////
  // Errors //
  ////////////
  // Admin
  error InvalidShortBuffer(address thrower, uint newShortBuffer);

  // Initialising Short
  error ShortAccountAlreadyOpen(address thrower, uint shortId);
  error NotEnoughQuoteForMinCollateral(address thrower, uint quoteReceived, uint minCollateral);

  // Hedging
  error InteractionDelayNotExpired(address thrower, uint lastInteraction, uint interactionDelta, uint currentTime);

  // Token transfers
  error QuoteApprovalFailure(address thrower, address approvee, uint amount);
  error QuoteTransferFailed(address thrower, address from, address to, uint amount);
}
