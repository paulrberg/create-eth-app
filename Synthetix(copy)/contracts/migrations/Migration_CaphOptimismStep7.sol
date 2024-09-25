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
contract Migration_CaphOptimismStep7 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x0db1B224C5203fA22CFdFA3F92519D150ad86612
    PerpsV2MarketState public constant perpsv2marketstateuniperp_i =
        PerpsV2MarketState(0x0db1B224C5203fA22CFdFA3F92519D150ad86612);
    // https://explorer.optimism.io/address/0xcF4a5F99902887d6CF5A2271cC1f54b5c2321e29
    PerpsV2MarketState public constant perpsv2marketstateuniperplegacy_i =
        PerpsV2MarketState(0xcF4a5F99902887d6CF5A2271cC1f54b5c2321e29);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x4308427C463CAEAaB50FFf98a9deC569C31E4E87
    ProxyPerpsV2 public constant perpsv2proxyuniperp_i = ProxyPerpsV2(0x4308427C463CAEAaB50FFf98a9deC569C31E4E87);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xe46Ef097d2CF6FF95Ad172d5da0E65A0dE9e2468
    PerpsV2MarketState public constant perpsv2marketstateatomperp_i =
        PerpsV2MarketState(0xe46Ef097d2CF6FF95Ad172d5da0E65A0dE9e2468);
    // https://explorer.optimism.io/address/0x91a480Bf2518C037E644fE70F207E66fdAA4d948
    PerpsV2MarketState public constant perpsv2marketstateatomperplegacy_i =
        PerpsV2MarketState(0x91a480Bf2518C037E644fE70F207E66fdAA4d948);
    // https://explorer.optimism.io/address/0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD
    ProxyPerpsV2 public constant perpsv2proxyatomperp_i = ProxyPerpsV2(0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstateuniperp_i);
        contracts[2] = address(perpsv2marketstateuniperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxyuniperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateatomperp_i);
        contracts[8] = address(perpsv2marketstateatomperplegacy_i);
        contracts[9] = address(perpsv2proxyatomperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstateuniperp_i.linkOrInitializeState();
        perpsv2marketstateuniperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxyuniperp_i.addRoute(0xa126d601, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x5c8011c3, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x2af64bd3, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, true);
        perpsv2proxyuniperp_i.addRoute(0xd67bdd25, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, true);
        perpsv2proxyuniperp_i.addRoute(0x4ad4914b, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x32f05103, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0xec556889, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, true);
        perpsv2proxyuniperp_i.addRoute(0x4eb985cc, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0xbc67f832, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x97107d6d, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x88a3c848, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x5a1cbd2b, 0x0A7B5CAabA3FFC775a0ab83544400005622F62D5, false);
        perpsv2proxyuniperp_i.addRoute(0x909bc379, 0xa71E06546F0278dA6C4732e8b885378Fc0781FE8, false);
        perpsv2proxyuniperp_i.addRoute(0x3c92b8ec, 0xa71E06546F0278dA6C4732e8b885378Fc0781FE8, false);
        perpsv2proxyuniperp_i.addRoute(0x7498a0f0, 0xa71E06546F0278dA6C4732e8b885378Fc0781FE8, false);
        perpsv2proxyuniperp_i.addRoute(0xc5a4b07a, 0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428, false);
        perpsv2proxyuniperp_i.addRoute(0xed44a2db, 0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428, false);
        perpsv2proxyuniperp_i.addRoute(0x09461cfe, 0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428, false);
        perpsv2proxyuniperp_i.addRoute(0x787d6c30, 0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428, false);
        perpsv2proxyuniperp_i.addRoute(0xa1c35a35, 0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428, false);
        perpsv2proxyuniperp_i.addRoute(0x85f05ab5, 0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428, false);
        perpsv2proxyuniperp_i.addRoute(0xc70b41e9, 0x418d195155058ABC4A26D59c8A6CE83A7d52288A, false);
        perpsv2proxyuniperp_i.addRoute(0xdcce5806, 0x418d195155058ABC4A26D59c8A6CE83A7d52288A, false);
        perpsv2proxyuniperp_i.addRoute(0xa8300afb, 0x418d195155058ABC4A26D59c8A6CE83A7d52288A, false);
        perpsv2proxyuniperp_i.addRoute(0xdfa723cc, 0x418d195155058ABC4A26D59c8A6CE83A7d52288A, false);
        perpsv2proxyuniperp_i.addRoute(0x785cdeec, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x1bf556d0, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xd24378eb, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xcdf456e1, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xb9f4ff55, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x3aef4d0b, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xb74e3806, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xc8b809aa, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xea9f9aa7, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x27b9a236, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xe44c84c2, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x41108cf2, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xcded0cea, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xfef48a99, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xc8023af4, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x964db90c, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xe8c63470, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xd7103a46, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xeb56105d, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x5fc890c2, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x2b58ecef, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xb895daab, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x4dd9d7e9, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x55f57510, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xea1d5478, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0xb111dfac, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x9cfbf4e4, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        perpsv2proxyuniperp_i.addRoute(0x917e77f5, 0x90efaafEc5B183D09bc5b2cE81E8A12e4c2A6002, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sUNIPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sUNIPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sUNIPERP", 4000000000000000);
        perpsv2marketstateatomperp_i.linkOrInitializeState();
        perpsv2marketstateatomperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyatomperp_i.addRoute(0xa126d601, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x5c8011c3, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x2af64bd3, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, true);
        perpsv2proxyatomperp_i.addRoute(0xd67bdd25, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, true);
        perpsv2proxyatomperp_i.addRoute(0x4ad4914b, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x32f05103, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0xec556889, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, true);
        perpsv2proxyatomperp_i.addRoute(0x4eb985cc, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0xbc67f832, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x97107d6d, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x88a3c848, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x5a1cbd2b, 0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2, false);
        perpsv2proxyatomperp_i.addRoute(0x909bc379, 0x8f765028e9701462c07ef83312cFFD3a5b9A6652, false);
        perpsv2proxyatomperp_i.addRoute(0x3c92b8ec, 0x8f765028e9701462c07ef83312cFFD3a5b9A6652, false);
        perpsv2proxyatomperp_i.addRoute(0x7498a0f0, 0x8f765028e9701462c07ef83312cFFD3a5b9A6652, false);
        perpsv2proxyatomperp_i.addRoute(0xc5a4b07a, 0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9, false);
        perpsv2proxyatomperp_i.addRoute(0xed44a2db, 0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9, false);
        perpsv2proxyatomperp_i.addRoute(0x09461cfe, 0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9, false);
        perpsv2proxyatomperp_i.addRoute(0x787d6c30, 0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9, false);
        perpsv2proxyatomperp_i.addRoute(0xa1c35a35, 0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9, false);
        perpsv2proxyatomperp_i.addRoute(0x85f05ab5, 0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9, false);
        perpsv2proxyatomperp_i.addRoute(0xc70b41e9, 0x76FB9F147d40480b6e030c09CD53fDF912C6178f, false);
        perpsv2proxyatomperp_i.addRoute(0xdcce5806, 0x76FB9F147d40480b6e030c09CD53fDF912C6178f, false);
        perpsv2proxyatomperp_i.addRoute(0xa8300afb, 0x76FB9F147d40480b6e030c09CD53fDF912C6178f, false);
        perpsv2proxyatomperp_i.addRoute(0xdfa723cc, 0x76FB9F147d40480b6e030c09CD53fDF912C6178f, false);
        perpsv2proxyatomperp_i.addRoute(0x785cdeec, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x1bf556d0, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xd24378eb, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xcdf456e1, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xb9f4ff55, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x3aef4d0b, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xb74e3806, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xc8b809aa, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xea9f9aa7, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x27b9a236, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xe44c84c2, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x41108cf2, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xcded0cea, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xfef48a99, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xc8023af4, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x964db90c, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xe8c63470, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xd7103a46, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xeb56105d, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x5fc890c2, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x2b58ecef, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xb895daab, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x4dd9d7e9, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x55f57510, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xea1d5478, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0xb111dfac, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x9cfbf4e4, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        perpsv2proxyatomperp_i.addRoute(0x917e77f5, 0xA92C0142c3239e8e07cbb9f33e4C0dD4Fc19089b, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sATOMPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sATOMPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sATOMPERP", 4000000000000000);
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

    function perpsv2marketstateuniperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateuniperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstateuniperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x0db1B224C5203fA22CFdFA3F92519D150ad86612
        );
        perpsv2marketstateuniperplegacy_i.addAssociatedContracts(
            perpsv2marketstateuniperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0xB0b6b79Fbb09290b0663D6D767FFCEE7EA742428
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0x418d195155058ABC4A26D59c8A6CE83A7d52288A
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x4308427C463CAEAaB50FFf98a9deC569C31E4E87
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstateatomperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstateatomperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstateatomperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0xe46Ef097d2CF6FF95Ad172d5da0E65A0dE9e2468
        );
        perpsv2marketstateatomperplegacy_i.addAssociatedContracts(
            perpsv2marketstateatomperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x2c5fc227AF9100F8d6FC963549De3e3BadA8c3A9
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x76FB9F147d40480b6e030c09CD53fDF912C6178f
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
