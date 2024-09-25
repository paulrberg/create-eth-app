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
import "../AddressResolver.sol";
import "../PerpsV2MarketState.sol";
import "../ProxyPerpsV2.sol";
import "../FuturesMarketManager.sol";
import "../SystemStatus.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_IzarOptimismStep2 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C
    AddressResolver public constant addressresolver_i = AddressResolver(0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C);
    // https://explorer.optimism.io/address/0x0db1B224C5203fA22CFdFA3F92519D150ad86612
    PerpsV2MarketState public constant perpsv2marketstateuniperp_i =
        PerpsV2MarketState(0x0db1B224C5203fA22CFdFA3F92519D150ad86612);
    // https://explorer.optimism.io/address/0x4308427C463CAEAaB50FFf98a9deC569C31E4E87
    ProxyPerpsV2 public constant perpsv2proxyuniperp_i = ProxyPerpsV2(0x4308427C463CAEAaB50FFf98a9deC569C31E4E87);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x089af032687993426A628184cb3D0610d2cda6F2
    PerpsV2MarketState public constant perpsv2marketstateapeperp_i =
        PerpsV2MarketState(0x089af032687993426A628184cb3D0610d2cda6F2);
    // https://explorer.optimism.io/address/0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886
    ProxyPerpsV2 public constant perpsv2proxyapeperp_i = ProxyPerpsV2(0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886);
    // https://explorer.optimism.io/address/0x0A0A22189c8732cA089D6fB6709e65140a446a41
    PerpsV2MarketState public constant perpsv2marketstatedogeperp_i =
        PerpsV2MarketState(0x0A0A22189c8732cA089D6fB6709e65140a446a41);
    // https://explorer.optimism.io/address/0x98cCbC721cc05E28a125943D69039B39BE6A21e9
    ProxyPerpsV2 public constant perpsv2proxydogeperp_i = ProxyPerpsV2(0x98cCbC721cc05E28a125943D69039B39BE6A21e9);
    // https://explorer.optimism.io/address/0x4eD08210706F5b74584cC7F03b38d800DC27936B
    PerpsV2MarketState public constant perpsv2marketstateeurperp_i =
        PerpsV2MarketState(0x4eD08210706F5b74584cC7F03b38d800DC27936B);
    // https://explorer.optimism.io/address/0x87AE62c5720DAB812BDacba66cc24839440048d1
    ProxyPerpsV2 public constant perpsv2proxyeurperp_i = ProxyPerpsV2(0x87AE62c5720DAB812BDacba66cc24839440048d1);
    // https://explorer.optimism.io/address/0xe46Ef097d2CF6FF95Ad172d5da0E65A0dE9e2468
    PerpsV2MarketState public constant perpsv2marketstateatomperp_i =
        PerpsV2MarketState(0xe46Ef097d2CF6FF95Ad172d5da0E65A0dE9e2468);
    // https://explorer.optimism.io/address/0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD
    ProxyPerpsV2 public constant perpsv2proxyatomperp_i = ProxyPerpsV2(0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD);
    // https://explorer.optimism.io/address/0xcfdC039BDB8E4b578857b759f27D6BAa2617EDD3
    PerpsV2MarketState public constant perpsv2marketstateaxsperp_i =
        PerpsV2MarketState(0xcfdC039BDB8E4b578857b759f27D6BAa2617EDD3);
    // https://explorer.optimism.io/address/0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1
    ProxyPerpsV2 public constant perpsv2proxyaxsperp_i = ProxyPerpsV2(0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://explorer.optimism.io/address/0x340B5d664834113735730Ad4aFb3760219Ad9112
    address public constant new_PerpsV2MarketData_contract = 0x340B5d664834113735730Ad4aFb3760219Ad9112;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](15);
        contracts[0] = address(addressresolver_i);
        contracts[1] = address(perpsv2marketstateuniperp_i);
        contracts[2] = address(perpsv2proxyuniperp_i);
        contracts[3] = address(futuresmarketmanager_i);
        contracts[4] = address(perpsv2marketstateapeperp_i);
        contracts[5] = address(perpsv2proxyapeperp_i);
        contracts[6] = address(perpsv2marketstatedogeperp_i);
        contracts[7] = address(perpsv2proxydogeperp_i);
        contracts[8] = address(perpsv2marketstateeurperp_i);
        contracts[9] = address(perpsv2proxyeurperp_i);
        contracts[10] = address(perpsv2marketstateatomperp_i);
        contracts[11] = address(perpsv2proxyatomperp_i);
        contracts[12] = address(perpsv2marketstateaxsperp_i);
        contracts[13] = address(perpsv2proxyaxsperp_i);
        contracts[14] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        perpsv2marketstateuniperp_removeAssociatedContracts_1();
        perpsv2marketstateuniperp_addAssociatedContracts_2();
        perpsv2proxyuniperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyuniperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyuniperp_i.removeRoute(0xec556889);
        perpsv2proxyuniperp_i.removeRoute(0xbc67f832);
        perpsv2proxyuniperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketUNIPERP.closePosition;
        perpsv2proxyuniperp_i.addRoute(0xa126d601, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketUNIPERP.closePositionWithTracking;
        perpsv2proxyuniperp_i.addRoute(0x5c8011c3, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketUNIPERP.modifyPosition;
        perpsv2proxyuniperp_i.addRoute(0x4ad4914b, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketUNIPERP.modifyPositionWithTracking;
        perpsv2proxyuniperp_i.addRoute(0x32f05103, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketUNIPERP.recomputeFunding;
        perpsv2proxyuniperp_i.addRoute(0x4eb985cc, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketUNIPERP.transferMargin;
        perpsv2proxyuniperp_i.addRoute(0x88a3c848, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketUNIPERP.withdrawAllMargin;
        perpsv2proxyuniperp_i.addRoute(0x5a1cbd2b, 0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb, false);
        // Add route to PerpsV2MarketLiquidateUNIPERP.flagPosition;
        perpsv2proxyuniperp_i.addRoute(0x909bc379, 0xB63bEF5ccC5e9316961CDCD54129743AE8455Bc4, false);
        // Add route to PerpsV2MarketLiquidateUNIPERP.forceLiquidatePosition;
        perpsv2proxyuniperp_i.addRoute(0x3c92b8ec, 0xB63bEF5ccC5e9316961CDCD54129743AE8455Bc4, false);
        // Add route to PerpsV2MarketLiquidateUNIPERP.liquidatePosition;
        perpsv2proxyuniperp_i.addRoute(0x7498a0f0, 0xB63bEF5ccC5e9316961CDCD54129743AE8455Bc4, false);
        futuresmarketmanager_updateMarketsImplementations_18();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_19();
        perpsv2marketstateapeperp_removeAssociatedContracts_20();
        perpsv2marketstateapeperp_addAssociatedContracts_21();
        perpsv2proxyapeperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyapeperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyapeperp_i.removeRoute(0xec556889);
        perpsv2proxyapeperp_i.removeRoute(0xbc67f832);
        perpsv2proxyapeperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketAPEPERP.closePosition;
        perpsv2proxyapeperp_i.addRoute(0xa126d601, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketAPEPERP.closePositionWithTracking;
        perpsv2proxyapeperp_i.addRoute(0x5c8011c3, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketAPEPERP.modifyPosition;
        perpsv2proxyapeperp_i.addRoute(0x4ad4914b, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketAPEPERP.modifyPositionWithTracking;
        perpsv2proxyapeperp_i.addRoute(0x32f05103, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketAPEPERP.recomputeFunding;
        perpsv2proxyapeperp_i.addRoute(0x4eb985cc, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketAPEPERP.transferMargin;
        perpsv2proxyapeperp_i.addRoute(0x88a3c848, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketAPEPERP.withdrawAllMargin;
        perpsv2proxyapeperp_i.addRoute(0x5a1cbd2b, 0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C, false);
        // Add route to PerpsV2MarketLiquidateAPEPERP.flagPosition;
        perpsv2proxyapeperp_i.addRoute(0x909bc379, 0x0b1E9543c3Cda15d431DCdc94724F3FF3caDAc1F, false);
        // Add route to PerpsV2MarketLiquidateAPEPERP.forceLiquidatePosition;
        perpsv2proxyapeperp_i.addRoute(0x3c92b8ec, 0x0b1E9543c3Cda15d431DCdc94724F3FF3caDAc1F, false);
        // Add route to PerpsV2MarketLiquidateAPEPERP.liquidatePosition;
        perpsv2proxyapeperp_i.addRoute(0x7498a0f0, 0x0b1E9543c3Cda15d431DCdc94724F3FF3caDAc1F, false);
        futuresmarketmanager_updateMarketsImplementations_37();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_38();
        perpsv2marketstatedogeperp_removeAssociatedContracts_39();
        perpsv2marketstatedogeperp_addAssociatedContracts_40();
        perpsv2proxydogeperp_i.removeRoute(0x2af64bd3);
        perpsv2proxydogeperp_i.removeRoute(0xd67bdd25);
        perpsv2proxydogeperp_i.removeRoute(0xec556889);
        perpsv2proxydogeperp_i.removeRoute(0xbc67f832);
        perpsv2proxydogeperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketDOGEPERP.closePosition;
        perpsv2proxydogeperp_i.addRoute(0xa126d601, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketDOGEPERP.closePositionWithTracking;
        perpsv2proxydogeperp_i.addRoute(0x5c8011c3, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketDOGEPERP.modifyPosition;
        perpsv2proxydogeperp_i.addRoute(0x4ad4914b, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketDOGEPERP.modifyPositionWithTracking;
        perpsv2proxydogeperp_i.addRoute(0x32f05103, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketDOGEPERP.recomputeFunding;
        perpsv2proxydogeperp_i.addRoute(0x4eb985cc, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketDOGEPERP.transferMargin;
        perpsv2proxydogeperp_i.addRoute(0x88a3c848, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketDOGEPERP.withdrawAllMargin;
        perpsv2proxydogeperp_i.addRoute(0x5a1cbd2b, 0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b, false);
        // Add route to PerpsV2MarketLiquidateDOGEPERP.flagPosition;
        perpsv2proxydogeperp_i.addRoute(0x909bc379, 0x277EFAFCCB3683Fd0DD5facCa8f37E3130D359Fb, false);
        // Add route to PerpsV2MarketLiquidateDOGEPERP.forceLiquidatePosition;
        perpsv2proxydogeperp_i.addRoute(0x3c92b8ec, 0x277EFAFCCB3683Fd0DD5facCa8f37E3130D359Fb, false);
        // Add route to PerpsV2MarketLiquidateDOGEPERP.liquidatePosition;
        perpsv2proxydogeperp_i.addRoute(0x7498a0f0, 0x277EFAFCCB3683Fd0DD5facCa8f37E3130D359Fb, false);
        futuresmarketmanager_updateMarketsImplementations_56();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_57();
        perpsv2marketstateeurperp_removeAssociatedContracts_58();
        perpsv2marketstateeurperp_addAssociatedContracts_59();
        perpsv2proxyeurperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyeurperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyeurperp_i.removeRoute(0xec556889);
        perpsv2proxyeurperp_i.removeRoute(0xbc67f832);
        perpsv2proxyeurperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketEURPERP.closePosition;
        perpsv2proxyeurperp_i.addRoute(0xa126d601, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketEURPERP.closePositionWithTracking;
        perpsv2proxyeurperp_i.addRoute(0x5c8011c3, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketEURPERP.modifyPosition;
        perpsv2proxyeurperp_i.addRoute(0x4ad4914b, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketEURPERP.modifyPositionWithTracking;
        perpsv2proxyeurperp_i.addRoute(0x32f05103, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketEURPERP.recomputeFunding;
        perpsv2proxyeurperp_i.addRoute(0x4eb985cc, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketEURPERP.transferMargin;
        perpsv2proxyeurperp_i.addRoute(0x88a3c848, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketEURPERP.withdrawAllMargin;
        perpsv2proxyeurperp_i.addRoute(0x5a1cbd2b, 0xcE8Bcb110101D6cDe21d6c76bD799261385AA950, false);
        // Add route to PerpsV2MarketLiquidateEURPERP.flagPosition;
        perpsv2proxyeurperp_i.addRoute(0x909bc379, 0x2A77E3382e205D586CA6E4C9F8D7dc6E6bB2054d, false);
        // Add route to PerpsV2MarketLiquidateEURPERP.forceLiquidatePosition;
        perpsv2proxyeurperp_i.addRoute(0x3c92b8ec, 0x2A77E3382e205D586CA6E4C9F8D7dc6E6bB2054d, false);
        // Add route to PerpsV2MarketLiquidateEURPERP.liquidatePosition;
        perpsv2proxyeurperp_i.addRoute(0x7498a0f0, 0x2A77E3382e205D586CA6E4C9F8D7dc6E6bB2054d, false);
        futuresmarketmanager_updateMarketsImplementations_75();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_76();
        perpsv2marketstateatomperp_removeAssociatedContracts_77();
        perpsv2marketstateatomperp_addAssociatedContracts_78();
        perpsv2proxyatomperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyatomperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyatomperp_i.removeRoute(0xec556889);
        perpsv2proxyatomperp_i.removeRoute(0xbc67f832);
        perpsv2proxyatomperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketATOMPERP.closePosition;
        perpsv2proxyatomperp_i.addRoute(0xa126d601, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketATOMPERP.closePositionWithTracking;
        perpsv2proxyatomperp_i.addRoute(0x5c8011c3, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketATOMPERP.modifyPosition;
        perpsv2proxyatomperp_i.addRoute(0x4ad4914b, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketATOMPERP.modifyPositionWithTracking;
        perpsv2proxyatomperp_i.addRoute(0x32f05103, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketATOMPERP.recomputeFunding;
        perpsv2proxyatomperp_i.addRoute(0x4eb985cc, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketATOMPERP.transferMargin;
        perpsv2proxyatomperp_i.addRoute(0x88a3c848, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketATOMPERP.withdrawAllMargin;
        perpsv2proxyatomperp_i.addRoute(0x5a1cbd2b, 0x9597494F1675F1D62Edb03dee40D84828EF5B295, false);
        // Add route to PerpsV2MarketLiquidateATOMPERP.flagPosition;
        perpsv2proxyatomperp_i.addRoute(0x909bc379, 0xCc60342649c58A9D5a5293030CCBc230b1231127, false);
        // Add route to PerpsV2MarketLiquidateATOMPERP.forceLiquidatePosition;
        perpsv2proxyatomperp_i.addRoute(0x3c92b8ec, 0xCc60342649c58A9D5a5293030CCBc230b1231127, false);
        // Add route to PerpsV2MarketLiquidateATOMPERP.liquidatePosition;
        perpsv2proxyatomperp_i.addRoute(0x7498a0f0, 0xCc60342649c58A9D5a5293030CCBc230b1231127, false);
        futuresmarketmanager_updateMarketsImplementations_94();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_95();
        perpsv2marketstateaxsperp_removeAssociatedContracts_96();
        perpsv2marketstateaxsperp_addAssociatedContracts_97();
        perpsv2proxyaxsperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyaxsperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyaxsperp_i.removeRoute(0xec556889);
        perpsv2proxyaxsperp_i.removeRoute(0xbc67f832);
        perpsv2proxyaxsperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketAXSPERP.closePosition;
        perpsv2proxyaxsperp_i.addRoute(0xa126d601, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketAXSPERP.closePositionWithTracking;
        perpsv2proxyaxsperp_i.addRoute(0x5c8011c3, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketAXSPERP.modifyPosition;
        perpsv2proxyaxsperp_i.addRoute(0x4ad4914b, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketAXSPERP.modifyPositionWithTracking;
        perpsv2proxyaxsperp_i.addRoute(0x32f05103, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketAXSPERP.recomputeFunding;
        perpsv2proxyaxsperp_i.addRoute(0x4eb985cc, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketAXSPERP.transferMargin;
        perpsv2proxyaxsperp_i.addRoute(0x88a3c848, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketAXSPERP.withdrawAllMargin;
        perpsv2proxyaxsperp_i.addRoute(0x5a1cbd2b, 0x4eB7Ce307DE597F854124D018ec9edE0A8D57931, false);
        // Add route to PerpsV2MarketLiquidateAXSPERP.flagPosition;
        perpsv2proxyaxsperp_i.addRoute(0x909bc379, 0x73d3c278BE973624AEA70ef89C61113E55317AB6, false);
        // Add route to PerpsV2MarketLiquidateAXSPERP.forceLiquidatePosition;
        perpsv2proxyaxsperp_i.addRoute(0x3c92b8ec, 0x73d3c278BE973624AEA70ef89C61113E55317AB6, false);
        // Add route to PerpsV2MarketLiquidateAXSPERP.liquidatePosition;
        perpsv2proxyaxsperp_i.addRoute(0x7498a0f0, 0x73d3c278BE973624AEA70ef89C61113E55317AB6, false);
        futuresmarketmanager_updateMarketsImplementations_113();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_114();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_116();

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

    function addressresolver_importAddresses_0() internal {
        bytes32[] memory addressresolver_importAddresses_names_0_0 = new bytes32[](1);
        addressresolver_importAddresses_names_0_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_0_1 = new address[](1);
        addressresolver_importAddresses_destinations_0_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_0_0,
            addressresolver_importAddresses_destinations_0_1
        );
    }

    function perpsv2marketstateuniperp_removeAssociatedContracts_1() internal {
        address[] memory perpsv2marketstateuniperp_removeAssociatedContracts_associatedContracts_1_0 = new address[](2);
        perpsv2marketstateuniperp_removeAssociatedContracts_associatedContracts_1_0[0] = address(
            0x0A7B5CAabA3FFC775a0ab83544400005622F62D5
        );
        perpsv2marketstateuniperp_removeAssociatedContracts_associatedContracts_1_0[1] = address(
            0xa71E06546F0278dA6C4732e8b885378Fc0781FE8
        );
        perpsv2marketstateuniperp_i.removeAssociatedContracts(
            perpsv2marketstateuniperp_removeAssociatedContracts_associatedContracts_1_0
        );
    }

    function perpsv2marketstateuniperp_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateuniperp_addAssociatedContracts_associatedContracts_2_0 = new address[](2);
        perpsv2marketstateuniperp_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0xd5ea02e6324693BaCbDE3E63a3C72E5a227a4dDb
        );
        perpsv2marketstateuniperp_addAssociatedContracts_associatedContracts_2_0[1] = address(
            0xB63bEF5ccC5e9316961CDCD54129743AE8455Bc4
        );
        perpsv2marketstateuniperp_i.addAssociatedContracts(
            perpsv2marketstateuniperp_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_18() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0[0] = address(
            0x4308427C463CAEAaB50FFf98a9deC569C31E4E87
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0
        );
    }

    function addressresolver_importAddresses_19() internal {
        bytes32[] memory addressresolver_importAddresses_names_19_0 = new bytes32[](1);
        addressresolver_importAddresses_names_19_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_19_1 = new address[](1);
        addressresolver_importAddresses_destinations_19_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_19_0,
            addressresolver_importAddresses_destinations_19_1
        );
    }

    function perpsv2marketstateapeperp_removeAssociatedContracts_20() internal {
        address[] memory perpsv2marketstateapeperp_removeAssociatedContracts_associatedContracts_20_0 = new address[](2);
        perpsv2marketstateapeperp_removeAssociatedContracts_associatedContracts_20_0[0] = address(
            0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033
        );
        perpsv2marketstateapeperp_removeAssociatedContracts_associatedContracts_20_0[1] = address(
            0x9074b2389baaC5Ea4Fa9d1b1D37589142888697f
        );
        perpsv2marketstateapeperp_i.removeAssociatedContracts(
            perpsv2marketstateapeperp_removeAssociatedContracts_associatedContracts_20_0
        );
    }

    function perpsv2marketstateapeperp_addAssociatedContracts_21() internal {
        address[] memory perpsv2marketstateapeperp_addAssociatedContracts_associatedContracts_21_0 = new address[](2);
        perpsv2marketstateapeperp_addAssociatedContracts_associatedContracts_21_0[0] = address(
            0x74Eb1E2EfaDDde923f92F31c209a788475A20A1C
        );
        perpsv2marketstateapeperp_addAssociatedContracts_associatedContracts_21_0[1] = address(
            0x0b1E9543c3Cda15d431DCdc94724F3FF3caDAc1F
        );
        perpsv2marketstateapeperp_i.addAssociatedContracts(
            perpsv2marketstateapeperp_addAssociatedContracts_associatedContracts_21_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_37() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0[0] = address(
            0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0
        );
    }

    function addressresolver_importAddresses_38() internal {
        bytes32[] memory addressresolver_importAddresses_names_38_0 = new bytes32[](1);
        addressresolver_importAddresses_names_38_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_38_1 = new address[](1);
        addressresolver_importAddresses_destinations_38_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_38_0,
            addressresolver_importAddresses_destinations_38_1
        );
    }

    function perpsv2marketstatedogeperp_removeAssociatedContracts_39() internal {
        address[] memory perpsv2marketstatedogeperp_removeAssociatedContracts_associatedContracts_39_0 = new address[](2);
        perpsv2marketstatedogeperp_removeAssociatedContracts_associatedContracts_39_0[0] = address(
            0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2
        );
        perpsv2marketstatedogeperp_removeAssociatedContracts_associatedContracts_39_0[1] = address(
            0xf2425A167bFD229e64D9e28258013cA959e9991A
        );
        perpsv2marketstatedogeperp_i.removeAssociatedContracts(
            perpsv2marketstatedogeperp_removeAssociatedContracts_associatedContracts_39_0
        );
    }

    function perpsv2marketstatedogeperp_addAssociatedContracts_40() internal {
        address[] memory perpsv2marketstatedogeperp_addAssociatedContracts_associatedContracts_40_0 = new address[](2);
        perpsv2marketstatedogeperp_addAssociatedContracts_associatedContracts_40_0[0] = address(
            0xdcf2D2C4949D6358bF05cfd88dAE83276cf7552b
        );
        perpsv2marketstatedogeperp_addAssociatedContracts_associatedContracts_40_0[1] = address(
            0x277EFAFCCB3683Fd0DD5facCa8f37E3130D359Fb
        );
        perpsv2marketstatedogeperp_i.addAssociatedContracts(
            perpsv2marketstatedogeperp_addAssociatedContracts_associatedContracts_40_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_56() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0[0] = address(
            0x98cCbC721cc05E28a125943D69039B39BE6A21e9
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0
        );
    }

    function addressresolver_importAddresses_57() internal {
        bytes32[] memory addressresolver_importAddresses_names_57_0 = new bytes32[](1);
        addressresolver_importAddresses_names_57_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_57_1 = new address[](1);
        addressresolver_importAddresses_destinations_57_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_57_0,
            addressresolver_importAddresses_destinations_57_1
        );
    }

    function perpsv2marketstateeurperp_removeAssociatedContracts_58() internal {
        address[] memory perpsv2marketstateeurperp_removeAssociatedContracts_associatedContracts_58_0 = new address[](2);
        perpsv2marketstateeurperp_removeAssociatedContracts_associatedContracts_58_0[0] = address(
            0x4673A25b84097df253a6ff9c314f11ca60Bf8C05
        );
        perpsv2marketstateeurperp_removeAssociatedContracts_associatedContracts_58_0[1] = address(
            0xD9E7D2CC5EF478c8E6535D1F416F0c3AD477b78E
        );
        perpsv2marketstateeurperp_i.removeAssociatedContracts(
            perpsv2marketstateeurperp_removeAssociatedContracts_associatedContracts_58_0
        );
    }

    function perpsv2marketstateeurperp_addAssociatedContracts_59() internal {
        address[] memory perpsv2marketstateeurperp_addAssociatedContracts_associatedContracts_59_0 = new address[](2);
        perpsv2marketstateeurperp_addAssociatedContracts_associatedContracts_59_0[0] = address(
            0xcE8Bcb110101D6cDe21d6c76bD799261385AA950
        );
        perpsv2marketstateeurperp_addAssociatedContracts_associatedContracts_59_0[1] = address(
            0x2A77E3382e205D586CA6E4C9F8D7dc6E6bB2054d
        );
        perpsv2marketstateeurperp_i.addAssociatedContracts(
            perpsv2marketstateeurperp_addAssociatedContracts_associatedContracts_59_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_75() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0[0] = address(
            0x87AE62c5720DAB812BDacba66cc24839440048d1
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0
        );
    }

    function addressresolver_importAddresses_76() internal {
        bytes32[] memory addressresolver_importAddresses_names_76_0 = new bytes32[](1);
        addressresolver_importAddresses_names_76_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_76_1 = new address[](1);
        addressresolver_importAddresses_destinations_76_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_76_0,
            addressresolver_importAddresses_destinations_76_1
        );
    }

    function perpsv2marketstateatomperp_removeAssociatedContracts_77() internal {
        address[] memory perpsv2marketstateatomperp_removeAssociatedContracts_associatedContracts_77_0 = new address[](2);
        perpsv2marketstateatomperp_removeAssociatedContracts_associatedContracts_77_0[0] = address(
            0xF5F5821b1236d7624A6c009190B4Dd7f54Bb18d2
        );
        perpsv2marketstateatomperp_removeAssociatedContracts_associatedContracts_77_0[1] = address(
            0x8f765028e9701462c07ef83312cFFD3a5b9A6652
        );
        perpsv2marketstateatomperp_i.removeAssociatedContracts(
            perpsv2marketstateatomperp_removeAssociatedContracts_associatedContracts_77_0
        );
    }

    function perpsv2marketstateatomperp_addAssociatedContracts_78() internal {
        address[] memory perpsv2marketstateatomperp_addAssociatedContracts_associatedContracts_78_0 = new address[](2);
        perpsv2marketstateatomperp_addAssociatedContracts_associatedContracts_78_0[0] = address(
            0x9597494F1675F1D62Edb03dee40D84828EF5B295
        );
        perpsv2marketstateatomperp_addAssociatedContracts_associatedContracts_78_0[1] = address(
            0xCc60342649c58A9D5a5293030CCBc230b1231127
        );
        perpsv2marketstateatomperp_i.addAssociatedContracts(
            perpsv2marketstateatomperp_addAssociatedContracts_associatedContracts_78_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_94() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0[0] = address(
            0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0
        );
    }

    function addressresolver_importAddresses_95() internal {
        bytes32[] memory addressresolver_importAddresses_names_95_0 = new bytes32[](1);
        addressresolver_importAddresses_names_95_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_95_1 = new address[](1);
        addressresolver_importAddresses_destinations_95_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_95_0,
            addressresolver_importAddresses_destinations_95_1
        );
    }

    function perpsv2marketstateaxsperp_removeAssociatedContracts_96() internal {
        address[] memory perpsv2marketstateaxsperp_removeAssociatedContracts_associatedContracts_96_0 = new address[](2);
        perpsv2marketstateaxsperp_removeAssociatedContracts_associatedContracts_96_0[0] = address(
            0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c
        );
        perpsv2marketstateaxsperp_removeAssociatedContracts_associatedContracts_96_0[1] = address(
            0x08c2c8d7175C5766a8aFCd1f7B69a6D999e21824
        );
        perpsv2marketstateaxsperp_i.removeAssociatedContracts(
            perpsv2marketstateaxsperp_removeAssociatedContracts_associatedContracts_96_0
        );
    }

    function perpsv2marketstateaxsperp_addAssociatedContracts_97() internal {
        address[] memory perpsv2marketstateaxsperp_addAssociatedContracts_associatedContracts_97_0 = new address[](2);
        perpsv2marketstateaxsperp_addAssociatedContracts_associatedContracts_97_0[0] = address(
            0x4eB7Ce307DE597F854124D018ec9edE0A8D57931
        );
        perpsv2marketstateaxsperp_addAssociatedContracts_associatedContracts_97_0[1] = address(
            0x73d3c278BE973624AEA70ef89C61113E55317AB6
        );
        perpsv2marketstateaxsperp_i.addAssociatedContracts(
            perpsv2marketstateaxsperp_addAssociatedContracts_associatedContracts_97_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_113() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0[0] = address(
            0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0
        );
    }

    function addressresolver_importAddresses_114() internal {
        bytes32[] memory addressresolver_importAddresses_names_114_0 = new bytes32[](1);
        addressresolver_importAddresses_names_114_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_114_1 = new address[](1);
        addressresolver_importAddresses_destinations_114_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_114_0,
            addressresolver_importAddresses_destinations_114_1
        );
    }

    function addressresolver_importAddresses_116() internal {
        bytes32[] memory addressresolver_importAddresses_names_116_0 = new bytes32[](1);
        addressresolver_importAddresses_names_116_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_116_1 = new address[](1);
        addressresolver_importAddresses_destinations_116_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_116_0,
            addressresolver_importAddresses_destinations_116_1
        );
    }
}
