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
import "./Collateral.sol";

contract CollateralShort is Collateral {
    constructor(
        address _owner,
        ICollateralManager _manager,
        address _resolver,
        bytes32 _collateralKey,
        uint _minCratio,
        uint _minCollateral
    ) public Collateral(_owner, _manager, _resolver, _collateralKey, _minCratio, _minCollateral) {}

    function open(
        uint collateral,
        uint amount,
        bytes32 currency
    ) external returns (uint id) {
        // Transfer from will throw if they didn't set the allowance
        IERC20(address(_synthsUSD())).transferFrom(msg.sender, address(this), collateral);

        id = _open(collateral, amount, currency, true);
    }

    function close(uint id) external returns (uint amount, uint collateral) {
        (amount, collateral) = _close(msg.sender, id);

        IERC20(address(_synthsUSD())).transfer(msg.sender, collateral);
    }

    function deposit(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint principal, uint collateral) {
        require(amount <= IERC20(address(_synthsUSD())).allowance(msg.sender, address(this)), "Allowance too low");

        IERC20(address(_synthsUSD())).transferFrom(msg.sender, address(this), amount);

        (principal, collateral) = _deposit(borrower, id, amount);
    }

    function withdraw(uint id, uint amount) external returns (uint principal, uint collateral) {
        (principal, collateral) = _withdraw(id, amount);

        IERC20(address(_synthsUSD())).transfer(msg.sender, amount);
    }

    function repay(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint principal, uint collateral) {
        (principal, collateral) = _repay(borrower, msg.sender, id, amount);
    }

    function closeWithCollateral(uint id) external returns (uint amount, uint collateral) {
        (amount, collateral) = _closeWithCollateral(msg.sender, id);

        if (collateral > 0) {
            IERC20(address(_synthsUSD())).transfer(msg.sender, collateral);
        }
    }

    function repayWithCollateral(uint id, uint amount) external returns (uint principal, uint collateral) {
        (principal, collateral) = _repayWithCollateral(msg.sender, id, amount);
    }

    // Needed for Lyra.
    function getShortAndCollateral(
        address, /* borrower */
        uint id
    ) external view returns (uint principal, uint collateral) {
        Loan memory loan = loans[id];
        return (loan.amount, loan.collateral);
    }

    function draw(uint id, uint amount) external returns (uint principal, uint collateral) {
        (principal, collateral) = _draw(id, amount);
    }

    function liquidate(
        address borrower,
        uint id,
        uint amount
    ) external {
        uint collateralLiquidated = _liquidate(borrower, id, amount);

        IERC20(address(_synthsUSD())).transfer(msg.sender, collateralLiquidated);
    }

    function _repayWithCollateral(
        address borrower,
        uint id,
        uint payment
    ) internal rateIsValid issuanceIsActive returns (uint amount, uint collateral) {
        // 0. Get the loan to repay and accrue interest.
        Loan storage loan = _getLoanAndAccrueInterest(id, borrower);

        // 1. Check loan is open and last interaction time.
        _checkLoanAvailable(loan);

        // 2. Use the payment to cover accrued interest and reduce debt.
        // The returned amounts are the interests paid and the principal component used to reduce debt only.
        require(payment <= loan.amount.add(loan.accruedInterest), "Payment too high");
        _processPayment(loan, payment);

        // 3. Get the equivalent payment amount in sUSD, and also distinguish
        // the fee that would be charged for both principal and interest.
        (uint expectedAmount, uint exchangeFee, ) = _exchanger().getAmountsForExchange(payment, loan.currency, sUSD);
        uint paymentSUSD = expectedAmount.add(exchangeFee);

        // 4. Reduce the collateral by the equivalent (total) payment amount in sUSD,
        // but add the fee instead of deducting it.
        uint collateralToRemove = paymentSUSD.add(exchangeFee);
        loan.collateral = loan.collateral.sub(collateralToRemove);

        // 5. Pay exchange fees.
        _payFees(exchangeFee, sUSD);

        // 6. Burn sUSD held in the contract.
        _synthsUSD().burn(address(this), collateralToRemove);

        // 7. Update the last interaction time.
        loan.lastInteraction = block.timestamp;

        // 8. Emit the event for the collateral repayment.
        emit LoanRepaymentMade(borrower, borrower, id, payment, loan.amount);

        // 9. Return the amount repaid and the remaining collateral.
        return (payment, loan.collateral);
    }

    function _closeWithCollateral(address borrower, uint id) internal returns (uint amount, uint collateral) {
        // 0. Get the loan to repay and accrue interest.
        Loan storage loan = _getLoanAndAccrueInterest(id, borrower);

        // 1. Repay the loan with its collateral.
        uint amountToRepay = loan.amount.add(loan.accruedInterest);
        (amount, collateral) = _repayWithCollateral(borrower, id, amountToRepay);

        // 2. Record loan as closed.
        _recordLoanAsClosed(loan);

        // 3. Emit the event for the loan closed by repayment.
        emit LoanClosedByRepayment(borrower, id, amount, collateral);

        // 4. Explicitely return the values.
        return (amount, collateral);
    }
}
