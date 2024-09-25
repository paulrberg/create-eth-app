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
pragma solidity 0.6.12;

import "Lyra-Finance/gmx/contracts/tokens/Token.sol";
import "Lyra-Finance/gmx/contracts/oracle/PriceFeed.sol";
import "Lyra-Finance/gmx/contracts/core/Vault.sol";
import "Lyra-Finance/gmx/contracts/peripherals/Timelock.sol";
import "Lyra-Finance/gmx/contracts/tokens/USDG.sol";
import "Lyra-Finance/gmx/contracts/core/Router.sol";
import "Lyra-Finance/gmx/contracts/peripherals/Reader.sol";
import "Lyra-Finance/gmx/contracts/core/ShortsTracker.sol";
import "Lyra-Finance/gmx/contracts/core/PositionRouter.sol";
import "Lyra-Finance/gmx/contracts/referrals/ReferralStorage.sol";
import "Lyra-Finance/gmx/contracts/tokens/YieldTracker.sol";
import "Lyra-Finance/gmx/contracts/core/VaultPriceFeed.sol";
import "Lyra-Finance/gmx/contracts/tokens/TimeDistributor.sol";
import "Lyra-Finance/gmx/contracts/oracle/FastPriceFeed.sol";
import "Lyra-Finance/gmx/contracts/oracle/FastPriceEvents.sol";
import "Lyra-Finance/gmx/contracts/core/VaultErrorController.sol";

/**
 * @dev Contract is used to import all the contracts that are needed for integration testing the GMX contracts.
 */
contract GMXCompileImports {
  constructor() public {
    // this is empty
  }
}
