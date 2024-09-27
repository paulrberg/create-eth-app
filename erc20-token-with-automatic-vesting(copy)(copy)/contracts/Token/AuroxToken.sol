/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/erc20-token-with-automatic-vesting?utm=code
  */
  
  pragma solidity 0.7.4;

import "erc20-token-with-automatic-vesting/openzeppelin-solidity/contracts/access/Ownable.sol";
import "erc20-token-with-automatic-vesting/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./TokenVesting.sol";
import "./IAuroxToken.sol";

// Ignoring the 19 states declaration for simpler deployment for the Aurox guys
contract AuroxToken is IAuroxToken, ERC20, Ownable {
    TokenVesting public reservesVestingContract;
    TokenVesting public teamRewardVestingContract;

    uint256 private uniSwapTransferAmount = 450000 ether;

    uint256 private teamUnvestedTransferAmount = 20000 ether;

    uint256 private teamVestedTransferAmount = 130000 ether;

    uint256 private reservesTransferAmount = 100000 ether;

    uint256 private exchangeListingTransferAmount = 50000 ether;

    uint256 private rewardsFundsTransferAmount = 250000 ether;

    constructor(
        address uniSwapAddress,
        address teamRewardAddress,
        address exchangeListingReserve,
        address reservesAddress
    ) public ERC20("Aurox Token", "URUS") {
        // Mint the supply to the ERC20 address
        _mint(_msgSender(), 1000000 ether);

        // Transfer the amounts
        transferAmounts(
            uniSwapAddress,
            teamRewardAddress,
            exchangeListingReserve
        );

        // Create the vesting contracts
        createVestingContracts(reservesAddress, teamRewardAddress);

        // Transfer amounts to vesting contracts
        transferVestingAmounts();
    }

    // Expose a new function to update the allowance of a new contract
    function setAllowance(address allowanceAddress)
        external
        override
        onlyOwner()
    {
        _approve(address(this), allowanceAddress, 650000 ether);
    }

    function transferAmounts(
        address uniSwapAddress,
        address teamRewardAddress,
        address exchangeListingReserve
    ) private {
        // Transfer all the amounts to the addresses
        // UniSwap
         transfer(uniSwapAddress, uniSwapTransferAmount);
        // // Team Reward
         transfer(teamRewardAddress, teamUnvestedTransferAmount);
        // // Exchange Listing
         transfer(exchangeListingReserve, exchangeListingTransferAmount);
        // // Transfer for initial public funds amount
         transfer(address(this), rewardsFundsTransferAmount);
    }

    function createVestingContracts(
        address reservesAddress,
        address teamRewardAddress
    ) private {
        // Start vesting now
        // Distribute linearly over 1 year
        reservesVestingContract = new TokenVesting(
            reservesAddress,
            block.timestamp + 183 days,
            0,
            365 days,
            false
        );
        // Distribute rewards over 1 yr
        teamRewardVestingContract = new TokenVesting(
            teamRewardAddress,
            block.timestamp + 365 days,
            0,
            730 days,
            false
        );
    }

    function transferVestingAmounts() private {
        // Transfer into the team reward contract
        transfer(address(teamRewardVestingContract), teamVestedTransferAmount);

        transfer(address(reservesVestingContract), reservesTransferAmount);
    }
}
