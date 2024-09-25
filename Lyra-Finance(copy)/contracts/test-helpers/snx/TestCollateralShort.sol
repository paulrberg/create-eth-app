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

import "../../synthetix/Owned.sol";
import "../TestERC20SetDecimals.sol";
import "../../interfaces/ICollateralShort.sol";
import "../../interfaces/IExchangeRates.sol";
import "../../synthetix/DecimalMath.sol";
import "./../SynthetixAdapter.sol";
import "../../libraries/ConvertDecimals.sol";

contract TestCollateralShort is ICollateralShort, Owned {
  using DecimalMath for uint;

  uint public override minCratio = (12 * DecimalMath.UNIT) / 10;
  uint public override minCollateral = 1000 * DecimalMath.UNIT;
  uint public override issueFeeRate = (5 * DecimalMath.UNIT) / 1000; // 0.5%

  SynthetixAdapter internal synthetixAdapter;
  TestERC20SetDecimals internal quoteAsset;

  mapping(bytes32 => TestERC20SetDecimals) public baseAssets;
  mapping(bytes32 => address) public markets;

  uint internal nextLoanId = 1;
  mapping(uint => Loan) public override loans;

  bool public initialized = false;

  constructor() Owned() {}

  function init(SynthetixAdapter _synthetixAdapter, TestERC20SetDecimals _quoteAsset) external {
    require(!initialized, "already initialized");
    synthetixAdapter = _synthetixAdapter;
    quoteAsset = _quoteAsset;
    initialized = true;
  }

  function addBaseAsset(bytes32 ticker, TestERC20SetDecimals baseAsset, address market) external onlyOwner {
    require(market != address(0), "market cannot be 0");
    require(baseAsset != TestERC20SetDecimals(address(0)), "baseAsset cannot be 0");
    baseAssets[ticker] = baseAsset;
    markets[ticker] = market;
  }

  function open(uint collateral, uint amount, bytes32 currency) external override returns (uint id) {
    Loan memory loan = Loan({
      id: nextLoanId++,
      account: msg.sender,
      collateral: collateral,
      currency: currency,
      amount: amount,
      short: true,
      accruedInterest: 0,
      interestIndex: 1,
      lastInteraction: block.timestamp
    });
    uint price = synthetixAdapter.getSpotPriceForMarket(markets[currency], BaseExchangeAdapter.PriceType.REFERENCE);

    require(collateral >= minCollateral, "must provide more than minCollateral");
    require(price.multiplyDecimal(loan.amount) < loan.collateral.multiplyDecimal(minCratio), "not enough collateral");

    quoteAsset.mint(
      msg.sender,
      price.multiplyDecimal(loan.amount).multiplyDecimalRound(DecimalMath.UNIT - issueFeeRate)
    );

    collateral = ConvertDecimals.convertFrom18(collateral, quoteAsset.decimals());

    quoteAsset.burn(msg.sender, collateral);

    loans[loan.id] = loan;

    return loan.id;
  }

  function draw(uint id, uint amount) external override returns (uint, uint) {
    Loan storage loan = loans[id];
    _isLoanOpen(loan.interestIndex);
    require(loan.account == msg.sender, "draw: loan.account mismatch");
    uint price = synthetixAdapter.getSpotPriceForMarket(
      markets[loan.currency],
      BaseExchangeAdapter.PriceType.REFERENCE
    );

    loan.amount += amount;
    quoteAsset.mint(msg.sender, price.multiplyDecimal(amount).multiplyDecimalRound(DecimalMath.UNIT - issueFeeRate));
    require(price.multiplyDecimal(loan.amount) < loan.collateral.multiplyDecimal(minCratio), "not enough collateral");

    return (loan.amount, loan.collateral);
  }

  function repay(
    address, // account
    uint id,
    uint amount
  ) external override returns (uint, uint) {
    Loan storage loan = loans[id];
    _isLoanOpen(loan.interestIndex);
    uint price = synthetixAdapter.getSpotPriceForMarket(
      markets[loan.currency],
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    TestERC20SetDecimals baseAsset = baseAssets[loan.currency];

    // Burning user's baseAsset
    baseAsset.burn(msg.sender, amount);
    loan.amount = loan.amount - amount;

    require(price.multiplyDecimal(loan.amount) < loan.collateral.multiplyDecimal(minCratio), "not enough collateral");

    return (loan.amount, loan.collateral);
  }

  function repayWithCollateral(uint id, uint amount) external override returns (uint, uint) {
    Loan storage loan = loans[id];
    _isLoanOpen(loan.interestIndex);
    require(loan.account == msg.sender, "only loan account");
    uint price = synthetixAdapter.getSpotPriceForMarket(
      markets[loan.currency],
      BaseExchangeAdapter.PriceType.REFERENCE
    );

    // Converting and burning user's collateral

    // Not perfect, but represents a larger loss than just the simple conversion
    loan.collateral =
      loan.collateral -
      price.multiplyDecimal(amount).divideDecimalRound(DecimalMath.UNIT - issueFeeRate);
    loan.amount = loan.amount - amount;

    // Roughly estimate accrued interest as a portion of issueFeeRate. Does not account for amount < true accrued interest
    uint mockAccruedInterest = amount.multiplyDecimal(issueFeeRate).multiplyDecimal((50 * DecimalMath.UNIT) / 100); // 50%
    uint repaidAmount = amount + mockAccruedInterest;

    // shouldn't be checking cRatio when loan is being reduced
    // require(price.multiplyDecimal(loan.amount) <= loan.collateral.multiplyDecimal(minCratio), "not enough collateral");

    return (repaidAmount, loan.collateral);
  }

  function deposit(
    address, // borrower
    uint id,
    uint amount
  ) external override returns (uint, uint) {
    quoteAsset.burn(msg.sender, amount);
    Loan storage loan = loans[id];
    _isLoanOpen(loan.interestIndex);
    loan.collateral += amount;

    return (loan.amount, loan.collateral);
  }

  function withdraw(uint id, uint amount) external override returns (uint, uint) {
    Loan storage loan = loans[id];
    _isLoanOpen(loan.interestIndex);
    require(loan.account == msg.sender, "withdraw: loan.account mismatch");

    loan.collateral = loan.collateral - amount;
    quoteAsset.mint(msg.sender, amount);

    uint price = synthetixAdapter.getSpotPriceForMarket(
      markets[loan.currency],
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    require(
      price.multiplyDecimal(loan.amount) <= loan.collateral.multiplyDecimal(minCratio),
      "withdrawing drops ratio too much"
    );

    return (loan.amount, loan.collateral);
  }

  function getShortAndCollateral(
    address, // account
    uint id
  ) external view override returns (uint, uint) {
    Loan memory loan = loans[id];
    return (loan.amount, loan.collateral);
  }

  // Methods for testing

  function createTestEmptyLoanForAccount(address account) external onlyOwner {
    Loan memory loan = Loan({
      id: nextLoanId++,
      account: account,
      collateral: 0,
      currency: "",
      amount: 0,
      short: true,
      accruedInterest: 0,
      interestIndex: 1,
      lastInteraction: block.timestamp
    });

    loans[loan.id] = loan;
  }

  function _recordLoanAsClosed(Loan storage loan) internal {
    loan.amount = 0;
    loan.collateral = 0;
    loan.accruedInterest = 0;
    loan.interestIndex = 0;
    loan.lastInteraction = block.timestamp;
  }

  function testForceClose(uint id) external onlyOwner {
    _recordLoanAsClosed(loans[id]);
  }

  function _isLoanOpen(uint interestIndex) internal pure {
    require(interestIndex != 0, "Loan is closed");
  }
}
