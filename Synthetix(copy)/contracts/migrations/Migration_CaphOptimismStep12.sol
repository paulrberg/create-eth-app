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
contract Migration_CaphOptimismStep12 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0xC02AF29944301c8FbA606a7dF8ef446dc103238C
    PerpsV2MarketState public constant perpsv2marketstateavaxperp_i =
        PerpsV2MarketState(0xC02AF29944301c8FbA606a7dF8ef446dc103238C);
    // https://explorer.optimism.io/address/0x3d368332c5E5c454f179f36e716b7cfA09906454
    PerpsV2MarketState public constant perpsv2marketstateavaxperplegacy_i =
        PerpsV2MarketState(0x3d368332c5E5c454f179f36e716b7cfA09906454);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D
    ProxyPerpsV2 public constant perpsv2proxyavaxperp_i = ProxyPerpsV2(0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x6393113A43A4A88b9F3D53b4b21e7feEb5d3D821
    PerpsV2MarketState public constant perpsv2marketstatearbperp_i =
        PerpsV2MarketState(0x6393113A43A4A88b9F3D53b4b21e7feEb5d3D821);
    // https://explorer.optimism.io/address/0xa31717145C27bb37868829E92A3601014768d145
    PerpsV2MarketState public constant perpsv2marketstatearbperplegacy_i =
        PerpsV2MarketState(0xa31717145C27bb37868829E92A3601014768d145);
    // https://explorer.optimism.io/address/0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e
    ProxyPerpsV2 public constant perpsv2proxyarbperp_i = ProxyPerpsV2(0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstateavaxperp_i);
        contracts[2] = address(perpsv2marketstateavaxperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxyavaxperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstatearbperp_i);
        contracts[8] = address(perpsv2marketstatearbperplegacy_i);
        contracts[9] = address(perpsv2proxyarbperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstateavaxperp_i.linkOrInitializeState();
        perpsv2marketstateavaxperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxyavaxperp_i.addRoute(0xa126d601, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x5c8011c3, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x2af64bd3, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, true);
        perpsv2proxyavaxperp_i.addRoute(0xd67bdd25, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, true);
        perpsv2proxyavaxperp_i.addRoute(0x4ad4914b, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x32f05103, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0xec556889, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, true);
        perpsv2proxyavaxperp_i.addRoute(0x4eb985cc, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0xbc67f832, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x97107d6d, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x88a3c848, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x5a1cbd2b, 0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0, false);
        perpsv2proxyavaxperp_i.addRoute(0x909bc379, 0x7d109dB6D68bC03BfbA4e5f129922fEc300Ab7Fe, false);
        perpsv2proxyavaxperp_i.addRoute(0x3c92b8ec, 0x7d109dB6D68bC03BfbA4e5f129922fEc300Ab7Fe, false);
        perpsv2proxyavaxperp_i.addRoute(0x7498a0f0, 0x7d109dB6D68bC03BfbA4e5f129922fEc300Ab7Fe, false);
        perpsv2proxyavaxperp_i.addRoute(0xc5a4b07a, 0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428, false);
        perpsv2proxyavaxperp_i.addRoute(0xed44a2db, 0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428, false);
        perpsv2proxyavaxperp_i.addRoute(0x09461cfe, 0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428, false);
        perpsv2proxyavaxperp_i.addRoute(0x787d6c30, 0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428, false);
        perpsv2proxyavaxperp_i.addRoute(0xa1c35a35, 0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428, false);
        perpsv2proxyavaxperp_i.addRoute(0x85f05ab5, 0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428, false);
        perpsv2proxyavaxperp_i.addRoute(0xc70b41e9, 0xC56a0198c08c3610980340660C39f6D6C7Ea765a, false);
        perpsv2proxyavaxperp_i.addRoute(0xdcce5806, 0xC56a0198c08c3610980340660C39f6D6C7Ea765a, false);
        perpsv2proxyavaxperp_i.addRoute(0xa8300afb, 0xC56a0198c08c3610980340660C39f6D6C7Ea765a, false);
        perpsv2proxyavaxperp_i.addRoute(0xdfa723cc, 0xC56a0198c08c3610980340660C39f6D6C7Ea765a, false);
        perpsv2proxyavaxperp_i.addRoute(0x785cdeec, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x1bf556d0, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xd24378eb, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xcdf456e1, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xb9f4ff55, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x3aef4d0b, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xb74e3806, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xc8b809aa, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xea9f9aa7, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x27b9a236, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xe44c84c2, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x41108cf2, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xcded0cea, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xfef48a99, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xc8023af4, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x964db90c, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xe8c63470, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xd7103a46, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xeb56105d, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x5fc890c2, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x2b58ecef, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xb895daab, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x4dd9d7e9, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x55f57510, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xea1d5478, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0xb111dfac, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x9cfbf4e4, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        perpsv2proxyavaxperp_i.addRoute(0x917e77f5, 0xBb1250d0D96a22CF62ee12AEcC2FA684F3Ca04E8, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sAVAXPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sAVAXPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sAVAXPERP", 4000000000000000);
        perpsv2marketstatearbperp_i.linkOrInitializeState();
        perpsv2marketstatearbperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyarbperp_i.addRoute(0xa126d601, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x5c8011c3, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x2af64bd3, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, true);
        perpsv2proxyarbperp_i.addRoute(0xd67bdd25, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, true);
        perpsv2proxyarbperp_i.addRoute(0x4ad4914b, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x32f05103, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0xec556889, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, true);
        perpsv2proxyarbperp_i.addRoute(0x4eb985cc, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0xbc67f832, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x97107d6d, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x88a3c848, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x5a1cbd2b, 0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb, false);
        perpsv2proxyarbperp_i.addRoute(0x909bc379, 0xa1Dea0c759Eb44e9aD9697E3c50E8dF8d19a402e, false);
        perpsv2proxyarbperp_i.addRoute(0x3c92b8ec, 0xa1Dea0c759Eb44e9aD9697E3c50E8dF8d19a402e, false);
        perpsv2proxyarbperp_i.addRoute(0x7498a0f0, 0xa1Dea0c759Eb44e9aD9697E3c50E8dF8d19a402e, false);
        perpsv2proxyarbperp_i.addRoute(0xc5a4b07a, 0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd, false);
        perpsv2proxyarbperp_i.addRoute(0xed44a2db, 0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd, false);
        perpsv2proxyarbperp_i.addRoute(0x09461cfe, 0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd, false);
        perpsv2proxyarbperp_i.addRoute(0x787d6c30, 0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd, false);
        perpsv2proxyarbperp_i.addRoute(0xa1c35a35, 0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd, false);
        perpsv2proxyarbperp_i.addRoute(0x85f05ab5, 0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd, false);
        perpsv2proxyarbperp_i.addRoute(0xc70b41e9, 0x31Ec26dE77aA4c859b7a15A37D2Fc9EB61289C14, false);
        perpsv2proxyarbperp_i.addRoute(0xdcce5806, 0x31Ec26dE77aA4c859b7a15A37D2Fc9EB61289C14, false);
        perpsv2proxyarbperp_i.addRoute(0xa8300afb, 0x31Ec26dE77aA4c859b7a15A37D2Fc9EB61289C14, false);
        perpsv2proxyarbperp_i.addRoute(0xdfa723cc, 0x31Ec26dE77aA4c859b7a15A37D2Fc9EB61289C14, false);
        perpsv2proxyarbperp_i.addRoute(0x785cdeec, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x1bf556d0, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xd24378eb, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xcdf456e1, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xb9f4ff55, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x3aef4d0b, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xb74e3806, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xc8b809aa, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xea9f9aa7, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x27b9a236, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xe44c84c2, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x41108cf2, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xcded0cea, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xfef48a99, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xc8023af4, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x964db90c, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xe8c63470, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xd7103a46, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xeb56105d, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x5fc890c2, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x2b58ecef, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xb895daab, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x4dd9d7e9, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x55f57510, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xea1d5478, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0xb111dfac, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x9cfbf4e4, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        perpsv2proxyarbperp_i.addRoute(0x917e77f5, 0x23b2558318E4955DfC3402567E22B1FF102DB3DD, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sARBPERP", 1600000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sARBPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sARBPERP", 3200000000000000);
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

    function perpsv2marketstateavaxperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateavaxperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstateavaxperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0xC02AF29944301c8FbA606a7dF8ef446dc103238C
        );
        perpsv2marketstateavaxperplegacy_i.addAssociatedContracts(
            perpsv2marketstateavaxperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0x9D6Db4d562D670a987b5D9e07Db71bab33Eb1428
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0xC56a0198c08c3610980340660C39f6D6C7Ea765a
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstatearbperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstatearbperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstatearbperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x6393113A43A4A88b9F3D53b4b21e7feEb5d3D821
        );
        perpsv2marketstatearbperplegacy_i.addAssociatedContracts(
            perpsv2marketstatearbperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x99ae21FeB485A89252B9bFB394E6Eb8c736436Bd
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x31Ec26dE77aA4c859b7a15A37D2Fc9EB61289C14
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
