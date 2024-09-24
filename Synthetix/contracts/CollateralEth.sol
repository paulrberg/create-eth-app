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
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICollateralEth.sol";

// This contract handles the payable aspects of eth loans.
contract CollateralEth is Collateral, ICollateralEth, ReentrancyGuard {
    mapping(address => uint) public pendingWithdrawals;

    constructor(
        address _owner,
        ICollateralManager _manager,
        address _resolver,
        bytes32 _collateralKey,
        uint _minCratio,
        uint _minCollateral
    ) public Collateral(_owner, _manager, _resolver, _collateralKey, _minCratio, _minCollateral) {}

    function open(uint amount, bytes32 currency) external payable returns (uint id) {
        id = _open(msg.value, amount, currency, false);
    }

    function close(uint id) external returns (uint amount, uint collateral) {
        (amount, collateral) = _close(msg.sender, id);

        pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(collateral);
    }

    function deposit(address borrower, uint id) external payable returns (uint principal, uint collateral) {
        (principal, collateral) = _deposit(borrower, id, msg.value);
    }

    function withdraw(uint id, uint amount) external returns (uint principal, uint collateral) {
        (principal, collateral) = _withdraw(id, amount);

        pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(amount);
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

        pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(collateralLiquidated);
    }

    function claim(uint amount) external nonReentrant {
        // If they try to withdraw more than their total balance, it will fail on the safe sub.
        pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].sub(amount);

        // solhint-disable avoid-low-level-calls
        (bool success, ) = msg.sender.call.value(amount)("");
        require(success, "Transfer failed");
    }
}
