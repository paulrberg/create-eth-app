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
import "./interfaces/ICollateralErc20.sol";

// This contract handles the specific ERC20 implementation details of managing a loan.
contract CollateralErc20 is ICollateralErc20, Collateral {
    // The underlying asset for this ERC20 collateral
    address public underlyingContract;

    uint public underlyingContractDecimals;

    constructor(
        address _owner,
        ICollateralManager _manager,
        address _resolver,
        bytes32 _collateralKey,
        uint _minCratio,
        uint _minCollateral,
        address _underlyingContract,
        uint _underlyingDecimals
    ) public Collateral(_owner, _manager, _resolver, _collateralKey, _minCratio, _minCollateral) {
        underlyingContract = _underlyingContract;

        underlyingContractDecimals = _underlyingDecimals;
    }

    function open(
        uint collateral,
        uint amount,
        bytes32 currency
    ) external returns (uint id) {
        require(collateral <= IERC20(underlyingContract).allowance(msg.sender, address(this)), "Allowance not high enough");

        // only transfer the actual collateral
        IERC20(underlyingContract).safeTransferFrom(msg.sender, address(this), collateral);

        // scale up before entering the system.
        uint scaledCollateral = scaleUpCollateral(collateral);

        id = _open(scaledCollateral, amount, currency, false);
    }

    function close(uint id) external returns (uint amount, uint collateral) {
        (amount, collateral) = _close(msg.sender, id);

        // scale down before transferring back.
        uint scaledCollateral = scaleDownCollateral(collateral);

        IERC20(underlyingContract).safeTransfer(msg.sender, scaledCollateral);
    }

    function deposit(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint principal, uint collateral) {
        require(amount <= IERC20(underlyingContract).allowance(msg.sender, address(this)), "Allowance not high enough");

        IERC20(underlyingContract).safeTransferFrom(msg.sender, address(this), amount);

        // scale up before entering the system.
        uint scaledAmount = scaleUpCollateral(amount);

        (principal, collateral) = _deposit(borrower, id, scaledAmount);
    }

    function withdraw(uint id, uint amount) external returns (uint principal, uint collateral) {
        // scale up before entering the system.
        uint scaledAmount = scaleUpCollateral(amount);

        (principal, collateral) = _withdraw(id, scaledAmount);

        // scale down before transferring back.
        uint scaledWithdraw = scaleDownCollateral(collateral);

        IERC20(underlyingContract).safeTransfer(msg.sender, scaledWithdraw);
    }

    function repay(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint principal, uint collateral) {
        (principal, collateral) = _repay(borrower, msg.sender, id, amount);
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

        // scale down before transferring back.
        uint scaledCollateral = scaleDownCollateral(collateralLiquidated);

        IERC20(underlyingContract).safeTransfer(msg.sender, scaledCollateral);
    }

    function scaleUpCollateral(uint collateral) public view returns (uint scaledUp) {
        uint conversionFactor = 10**uint(SafeMath.sub(18, underlyingContractDecimals));

        scaledUp = uint(uint(collateral).mul(conversionFactor));
    }

    function scaleDownCollateral(uint collateral) public view returns (uint scaledDown) {
        uint conversionFactor = 10**uint(SafeMath.sub(18, underlyingContractDecimals));

        scaledDown = collateral.div(conversionFactor);
    }
}
