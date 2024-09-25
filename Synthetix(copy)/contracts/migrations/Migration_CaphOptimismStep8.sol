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

import "../BaseMigration.sol";
import "../SystemStatus.sol";
import "../PerpsV2MarketState.sol";
import "../PerpsV2ExchangeRate.sol";
import "../ProxyPerpsV2.sol";
import "../FuturesMarketManager.sol";
import "../PerpsV2MarketSettings.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_CaphOptimismStep8 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x28E1CE29aCdFe1E74e6fA18591E1D5481D2085a1
    PerpsV2MarketState public constant perpsv2marketstatexagperp_i =
        PerpsV2MarketState(0x28E1CE29aCdFe1E74e6fA18591E1D5481D2085a1);
    // https://explorer.optimism.io/address/0x90276BA2Ac35D2BE30588b5019CF257f80b89E71
    PerpsV2MarketState public constant perpsv2marketstatexagperplegacy_i =
        PerpsV2MarketState(0x90276BA2Ac35D2BE30588b5019CF257f80b89E71);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xdcB8438c979fA030581314e5A5Df42bbFEd744a0
    ProxyPerpsV2 public constant perpsv2proxyxagperp_i = ProxyPerpsV2(0xdcB8438c979fA030581314e5A5Df42bbFEd744a0);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x4eD08210706F5b74584cC7F03b38d800DC27936B
    PerpsV2MarketState public constant perpsv2marketstateeurperp_i =
        PerpsV2MarketState(0x4eD08210706F5b74584cC7F03b38d800DC27936B);
    // https://explorer.optimism.io/address/0x0E48C8662e98f576e84d0ccDb146538269653225
    PerpsV2MarketState public constant perpsv2marketstateeurperplegacy_i =
        PerpsV2MarketState(0x0E48C8662e98f576e84d0ccDb146538269653225);
    // https://explorer.optimism.io/address/0x87AE62c5720DAB812BDacba66cc24839440048d1
    ProxyPerpsV2 public constant perpsv2proxyeurperp_i = ProxyPerpsV2(0x87AE62c5720DAB812BDacba66cc24839440048d1);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatexagperp_i);
        contracts[2] = address(perpsv2marketstatexagperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxyxagperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateeurperp_i);
        contracts[8] = address(perpsv2marketstateeurperplegacy_i);
        contracts[9] = address(perpsv2proxyeurperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstatexagperp_i.linkOrInitializeState();
        perpsv2marketstatexagperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxyxagperp_i.addRoute(0xa126d601, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x5c8011c3, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x2af64bd3, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, true);
        perpsv2proxyxagperp_i.addRoute(0xd67bdd25, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, true);
        perpsv2proxyxagperp_i.addRoute(0x4ad4914b, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x32f05103, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0xec556889, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, true);
        perpsv2proxyxagperp_i.addRoute(0x4eb985cc, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0xbc67f832, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x97107d6d, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x88a3c848, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x5a1cbd2b, 0x00751b4cceF0800bB4FA33B685363D4cFf1A981E, false);
        perpsv2proxyxagperp_i.addRoute(0x909bc379, 0x35BFC780c232171B5830A76632a70821c1A1b087, false);
        perpsv2proxyxagperp_i.addRoute(0x3c92b8ec, 0x35BFC780c232171B5830A76632a70821c1A1b087, false);
        perpsv2proxyxagperp_i.addRoute(0x7498a0f0, 0x35BFC780c232171B5830A76632a70821c1A1b087, false);
        perpsv2proxyxagperp_i.addRoute(0xc5a4b07a, 0xF40E46c74CA3E72d8dC490493FA9499999C6256E, false);
        perpsv2proxyxagperp_i.addRoute(0xed44a2db, 0xF40E46c74CA3E72d8dC490493FA9499999C6256E, false);
        perpsv2proxyxagperp_i.addRoute(0x09461cfe, 0xF40E46c74CA3E72d8dC490493FA9499999C6256E, false);
        perpsv2proxyxagperp_i.addRoute(0x787d6c30, 0xF40E46c74CA3E72d8dC490493FA9499999C6256E, false);
        perpsv2proxyxagperp_i.addRoute(0xa1c35a35, 0xF40E46c74CA3E72d8dC490493FA9499999C6256E, false);
        perpsv2proxyxagperp_i.addRoute(0x85f05ab5, 0xF40E46c74CA3E72d8dC490493FA9499999C6256E, false);
        perpsv2proxyxagperp_i.addRoute(0xc70b41e9, 0x546Ee4A4299dC3d3b64D6a889759E04aCef6B92D, false);
        perpsv2proxyxagperp_i.addRoute(0xdcce5806, 0x546Ee4A4299dC3d3b64D6a889759E04aCef6B92D, false);
        perpsv2proxyxagperp_i.addRoute(0xa8300afb, 0x546Ee4A4299dC3d3b64D6a889759E04aCef6B92D, false);
        perpsv2proxyxagperp_i.addRoute(0xdfa723cc, 0x546Ee4A4299dC3d3b64D6a889759E04aCef6B92D, false);
        perpsv2proxyxagperp_i.addRoute(0x785cdeec, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x1bf556d0, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xd24378eb, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xcdf456e1, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xb9f4ff55, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x3aef4d0b, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xb74e3806, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xc8b809aa, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xea9f9aa7, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x27b9a236, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xe44c84c2, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x41108cf2, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xcded0cea, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xfef48a99, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xc8023af4, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x964db90c, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xe8c63470, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xd7103a46, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xeb56105d, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x5fc890c2, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x2b58ecef, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xb895daab, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x4dd9d7e9, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x55f57510, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xea1d5478, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0xb111dfac, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x9cfbf4e4, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        perpsv2proxyxagperp_i.addRoute(0x917e77f5, 0x9BdC86302479112e61f3BA7761dC704f7044D304, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sXAGPERP", 300000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sXAGPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sXAGPERP", 600000000000000);
        perpsv2marketstateeurperp_i.linkOrInitializeState();
        perpsv2marketstateeurperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyeurperp_i.addRoute(0xa126d601, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x5c8011c3, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x2af64bd3, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, true);
        perpsv2proxyeurperp_i.addRoute(0xd67bdd25, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, true);
        perpsv2proxyeurperp_i.addRoute(0x4ad4914b, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x32f05103, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0xec556889, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, true);
        perpsv2proxyeurperp_i.addRoute(0x4eb985cc, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0xbc67f832, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x97107d6d, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x88a3c848, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x5a1cbd2b, 0x4673A25b84097df253a6ff9c314f11ca60Bf8C05, false);
        perpsv2proxyeurperp_i.addRoute(0x909bc379, 0xD9E7D2CC5EF478c8E6535D1F416F0c3AD477b78E, false);
        perpsv2proxyeurperp_i.addRoute(0x3c92b8ec, 0xD9E7D2CC5EF478c8E6535D1F416F0c3AD477b78E, false);
        perpsv2proxyeurperp_i.addRoute(0x7498a0f0, 0xD9E7D2CC5EF478c8E6535D1F416F0c3AD477b78E, false);
        perpsv2proxyeurperp_i.addRoute(0xc5a4b07a, 0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224, false);
        perpsv2proxyeurperp_i.addRoute(0xed44a2db, 0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224, false);
        perpsv2proxyeurperp_i.addRoute(0x09461cfe, 0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224, false);
        perpsv2proxyeurperp_i.addRoute(0x787d6c30, 0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224, false);
        perpsv2proxyeurperp_i.addRoute(0xa1c35a35, 0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224, false);
        perpsv2proxyeurperp_i.addRoute(0x85f05ab5, 0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224, false);
        perpsv2proxyeurperp_i.addRoute(0xc70b41e9, 0xEAacaDa91015c11D43bD788F09B2d54decfdc2e8, false);
        perpsv2proxyeurperp_i.addRoute(0xdcce5806, 0xEAacaDa91015c11D43bD788F09B2d54decfdc2e8, false);
        perpsv2proxyeurperp_i.addRoute(0xa8300afb, 0xEAacaDa91015c11D43bD788F09B2d54decfdc2e8, false);
        perpsv2proxyeurperp_i.addRoute(0xdfa723cc, 0xEAacaDa91015c11D43bD788F09B2d54decfdc2e8, false);
        perpsv2proxyeurperp_i.addRoute(0x785cdeec, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x1bf556d0, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xd24378eb, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xcdf456e1, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xb9f4ff55, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x3aef4d0b, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xb74e3806, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xc8b809aa, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xea9f9aa7, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x27b9a236, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xe44c84c2, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x41108cf2, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xcded0cea, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xfef48a99, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xc8023af4, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x964db90c, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xe8c63470, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xd7103a46, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xeb56105d, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x5fc890c2, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x2b58ecef, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xb895daab, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x4dd9d7e9, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x55f57510, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xea1d5478, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0xb111dfac, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x9cfbf4e4, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        perpsv2proxyeurperp_i.addRoute(0x917e77f5, 0x5Ade35CEdDEd082BDB27A94e2A20aC327a67172e, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sEURPERP", 300000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sEURPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sEURPERP", 600000000000000);
        systemstatus_i.updateAccessControl("Futures", address(this), false, false);

        // NOMINATE OWNERSHIP back to owner for aforementioned contracts
        nominateAll();
    }

    function acceptAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            Owned(contracts[i]).acceptOwnership();
        }
    }

    function nominateAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            returnOwnership(contracts[i]);
        }
    }

    function perpsv2marketstatexagperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatexagperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstatexagperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x28E1CE29aCdFe1E74e6fA18591E1D5481D2085a1
        );
        perpsv2marketstatexagperplegacy_i.addAssociatedContracts(
            perpsv2marketstatexagperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0xF40E46c74CA3E72d8dC490493FA9499999C6256E
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0x546Ee4A4299dC3d3b64D6a889759E04aCef6B92D
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0xdcB8438c979fA030581314e5A5Df42bbFEd744a0
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstateeurperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstateeurperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstateeurperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x4eD08210706F5b74584cC7F03b38d800DC27936B
        );
        perpsv2marketstateeurperplegacy_i.addAssociatedContracts(
            perpsv2marketstateeurperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x4BA1bdbc15281775a8437EAcdbAF8fbfD3A6a224
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0xEAacaDa91015c11D43bD788F09B2d54decfdc2e8
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x87AE62c5720DAB812BDacba66cc24839440048d1
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
