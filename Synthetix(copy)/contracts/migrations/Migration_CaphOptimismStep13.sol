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
contract Migration_CaphOptimismStep13 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x6aBC19F21D5Ce23abf392329Ef7B118c7b5F2AA8
    PerpsV2MarketState public constant perpsv2marketstateethperp_i =
        PerpsV2MarketState(0x6aBC19F21D5Ce23abf392329Ef7B118c7b5F2AA8);
    // https://explorer.optimism.io/address/0x038dC05D68ED32F23e6856c0D44b0696B325bfC8
    PerpsV2MarketState public constant perpsv2marketstateethperplegacy_i =
        PerpsV2MarketState(0x038dC05D68ED32F23e6856c0D44b0696B325bfC8);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x2B3bb4c683BFc5239B029131EEf3B1d214478d93
    ProxyPerpsV2 public constant perpsv2proxyethperp_i = ProxyPerpsV2(0x2B3bb4c683BFc5239B029131EEf3B1d214478d93);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x68287419FcFA1c186515E99a35FF3c970B3B3C66
    PerpsV2MarketState public constant perpsv2marketstatebtcperp_i =
        PerpsV2MarketState(0x68287419FcFA1c186515E99a35FF3c970B3B3C66);
    // https://explorer.optimism.io/address/0xFEAF9e0A57e626f72E1a5fff507D7A2d9A9F0EE9
    PerpsV2MarketState public constant perpsv2marketstatebtcperplegacy_i =
        PerpsV2MarketState(0xFEAF9e0A57e626f72E1a5fff507D7A2d9A9F0EE9);
    // https://explorer.optimism.io/address/0x59b007E9ea8F89b069c43F8f45834d30853e3699
    ProxyPerpsV2 public constant perpsv2proxybtcperp_i = ProxyPerpsV2(0x59b007E9ea8F89b069c43F8f45834d30853e3699);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstateethperp_i);
        contracts[2] = address(perpsv2marketstateethperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxyethperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstatebtcperp_i);
        contracts[8] = address(perpsv2marketstatebtcperplegacy_i);
        contracts[9] = address(perpsv2proxybtcperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstateethperp_i.linkOrInitializeState();
        perpsv2marketstateethperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxyethperp_i.addRoute(0xa126d601, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x5c8011c3, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x2af64bd3, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, true);
        perpsv2proxyethperp_i.addRoute(0xd67bdd25, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, true);
        perpsv2proxyethperp_i.addRoute(0x4ad4914b, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x32f05103, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0xec556889, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, true);
        perpsv2proxyethperp_i.addRoute(0x4eb985cc, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0xbc67f832, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x97107d6d, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x88a3c848, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x5a1cbd2b, 0xf1B530F3dEfD144A024A958D4Ae37d138615D91D, false);
        perpsv2proxyethperp_i.addRoute(0x909bc379, 0x248aB8Ac4BDb4ef401cCAD33B5fd7fB82Eb31eD2, false);
        perpsv2proxyethperp_i.addRoute(0x3c92b8ec, 0x248aB8Ac4BDb4ef401cCAD33B5fd7fB82Eb31eD2, false);
        perpsv2proxyethperp_i.addRoute(0x7498a0f0, 0x248aB8Ac4BDb4ef401cCAD33B5fd7fB82Eb31eD2, false);
        perpsv2proxyethperp_i.addRoute(0xc5a4b07a, 0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF, false);
        perpsv2proxyethperp_i.addRoute(0xed44a2db, 0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF, false);
        perpsv2proxyethperp_i.addRoute(0x09461cfe, 0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF, false);
        perpsv2proxyethperp_i.addRoute(0x787d6c30, 0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF, false);
        perpsv2proxyethperp_i.addRoute(0xa1c35a35, 0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF, false);
        perpsv2proxyethperp_i.addRoute(0x85f05ab5, 0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF, false);
        perpsv2proxyethperp_i.addRoute(0xc70b41e9, 0x2227af48ec971E3C786f3E06064CbA455724d6ba, false);
        perpsv2proxyethperp_i.addRoute(0xdcce5806, 0x2227af48ec971E3C786f3E06064CbA455724d6ba, false);
        perpsv2proxyethperp_i.addRoute(0xa8300afb, 0x2227af48ec971E3C786f3E06064CbA455724d6ba, false);
        perpsv2proxyethperp_i.addRoute(0xdfa723cc, 0x2227af48ec971E3C786f3E06064CbA455724d6ba, false);
        perpsv2proxyethperp_i.addRoute(0x785cdeec, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x1bf556d0, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xd24378eb, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xcdf456e1, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xb9f4ff55, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x3aef4d0b, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xb74e3806, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xc8b809aa, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xea9f9aa7, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x27b9a236, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xe44c84c2, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x41108cf2, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xcded0cea, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xfef48a99, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xc8023af4, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x964db90c, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xe8c63470, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xd7103a46, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xeb56105d, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x5fc890c2, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x2b58ecef, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xb895daab, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x4dd9d7e9, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x55f57510, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xea1d5478, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0xb111dfac, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x9cfbf4e4, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        perpsv2proxyethperp_i.addRoute(0x917e77f5, 0x989D359dBF9C531aE6C305c37AC37220b8Dd99Eb, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sETHPERP", 1500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sETHPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sETHPERP", 3000000000000000);
        perpsv2marketstatebtcperp_i.linkOrInitializeState();
        perpsv2marketstatebtcperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxybtcperp_i.addRoute(0xa126d601, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x5c8011c3, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x2af64bd3, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, true);
        perpsv2proxybtcperp_i.addRoute(0xd67bdd25, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, true);
        perpsv2proxybtcperp_i.addRoute(0x4ad4914b, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x32f05103, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0xec556889, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, true);
        perpsv2proxybtcperp_i.addRoute(0x4eb985cc, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0xbc67f832, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x97107d6d, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x88a3c848, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x5a1cbd2b, 0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6, false);
        perpsv2proxybtcperp_i.addRoute(0x909bc379, 0x802E609928a2Fc12e587766C078F341BAD8c4D4F, false);
        perpsv2proxybtcperp_i.addRoute(0x3c92b8ec, 0x802E609928a2Fc12e587766C078F341BAD8c4D4F, false);
        perpsv2proxybtcperp_i.addRoute(0x7498a0f0, 0x802E609928a2Fc12e587766C078F341BAD8c4D4F, false);
        perpsv2proxybtcperp_i.addRoute(0xc5a4b07a, 0x527b99E3d31F71D2414CC2dbAbE0d527f9160926, false);
        perpsv2proxybtcperp_i.addRoute(0xed44a2db, 0x527b99E3d31F71D2414CC2dbAbE0d527f9160926, false);
        perpsv2proxybtcperp_i.addRoute(0x09461cfe, 0x527b99E3d31F71D2414CC2dbAbE0d527f9160926, false);
        perpsv2proxybtcperp_i.addRoute(0x787d6c30, 0x527b99E3d31F71D2414CC2dbAbE0d527f9160926, false);
        perpsv2proxybtcperp_i.addRoute(0xa1c35a35, 0x527b99E3d31F71D2414CC2dbAbE0d527f9160926, false);
        perpsv2proxybtcperp_i.addRoute(0x85f05ab5, 0x527b99E3d31F71D2414CC2dbAbE0d527f9160926, false);
        perpsv2proxybtcperp_i.addRoute(0xc70b41e9, 0x33C8daF48c691C54897070C3621fdecC249C7202, false);
        perpsv2proxybtcperp_i.addRoute(0xdcce5806, 0x33C8daF48c691C54897070C3621fdecC249C7202, false);
        perpsv2proxybtcperp_i.addRoute(0xa8300afb, 0x33C8daF48c691C54897070C3621fdecC249C7202, false);
        perpsv2proxybtcperp_i.addRoute(0xdfa723cc, 0x33C8daF48c691C54897070C3621fdecC249C7202, false);
        perpsv2proxybtcperp_i.addRoute(0x785cdeec, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x1bf556d0, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xd24378eb, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xcdf456e1, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xb9f4ff55, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x3aef4d0b, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xb74e3806, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xc8b809aa, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xea9f9aa7, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x27b9a236, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xe44c84c2, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x41108cf2, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xcded0cea, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xfef48a99, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xc8023af4, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x964db90c, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xe8c63470, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xd7103a46, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xeb56105d, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x5fc890c2, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x2b58ecef, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xb895daab, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x4dd9d7e9, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x55f57510, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xea1d5478, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0xb111dfac, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x9cfbf4e4, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        perpsv2proxybtcperp_i.addRoute(0x917e77f5, 0xE662e0aF5fCaBe78aaaF4cFF0a13ca69512Fc481, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sBTCPERP", 1500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sBTCPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sBTCPERP", 3000000000000000);
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

    function perpsv2marketstateethperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateethperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstateethperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x6aBC19F21D5Ce23abf392329Ef7B118c7b5F2AA8
        );
        perpsv2marketstateethperplegacy_i.addAssociatedContracts(
            perpsv2marketstateethperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0x3ADA6D040314676B1e8A4BC1a0a16060b42A00eF
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0x2227af48ec971E3C786f3E06064CbA455724d6ba
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x2B3bb4c683BFc5239B029131EEf3B1d214478d93
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstatebtcperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstatebtcperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstatebtcperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x68287419FcFA1c186515E99a35FF3c970B3B3C66
        );
        perpsv2marketstatebtcperplegacy_i.addAssociatedContracts(
            perpsv2marketstatebtcperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x527b99E3d31F71D2414CC2dbAbE0d527f9160926
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x33C8daF48c691C54897070C3621fdecC249C7202
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x59b007E9ea8F89b069c43F8f45834d30853e3699
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
