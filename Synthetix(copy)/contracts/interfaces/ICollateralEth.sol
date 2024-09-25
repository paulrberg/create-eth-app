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
  
  pragma solidity >=0.4.24;

interface ICollateralEth {
    function open(uint amount, bytes32 currency) external payable returns (uint id);

    function close(uint id) external returns (uint amount, uint collateral);

    function deposit(address borrower, uint id) external payable returns (uint principal, uint collateral);

    function withdraw(uint id, uint amount) external returns (uint principal, uint collateral);

    function repay(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint principal, uint collateral);

    function draw(uint id, uint amount) external returns (uint principal, uint collateral);

    function liquidate(
        address borrower,
        uint id,
        uint amount
    ) external;

    function claim(uint amount) external;
}
