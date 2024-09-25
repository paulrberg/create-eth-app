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
contract Migration_IzarOptimismStep4 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C
    AddressResolver public constant addressresolver_i = AddressResolver(0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C);
    // https://explorer.optimism.io/address/0x6aBC19F21D5Ce23abf392329Ef7B118c7b5F2AA8
    PerpsV2MarketState public constant perpsv2marketstateethperp_i =
        PerpsV2MarketState(0x6aBC19F21D5Ce23abf392329Ef7B118c7b5F2AA8);
    // https://explorer.optimism.io/address/0x2B3bb4c683BFc5239B029131EEf3B1d214478d93
    ProxyPerpsV2 public constant perpsv2proxyethperp_i = ProxyPerpsV2(0x2B3bb4c683BFc5239B029131EEf3B1d214478d93);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x68287419FcFA1c186515E99a35FF3c970B3B3C66
    PerpsV2MarketState public constant perpsv2marketstatebtcperp_i =
        PerpsV2MarketState(0x68287419FcFA1c186515E99a35FF3c970B3B3C66);
    // https://explorer.optimism.io/address/0x59b007E9ea8F89b069c43F8f45834d30853e3699
    ProxyPerpsV2 public constant perpsv2proxybtcperp_i = ProxyPerpsV2(0x59b007E9ea8F89b069c43F8f45834d30853e3699);
    // https://explorer.optimism.io/address/0xEed3618dd59163CC6849758F07fA9369823aa710
    PerpsV2MarketState public constant perpsv2marketstatelinkperp_i =
        PerpsV2MarketState(0xEed3618dd59163CC6849758F07fA9369823aa710);
    // https://explorer.optimism.io/address/0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A
    ProxyPerpsV2 public constant perpsv2proxylinkperp_i = ProxyPerpsV2(0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A);
    // https://explorer.optimism.io/address/0x435e6e499610B6De3510F0Cb047D3575C7bca6E1
    PerpsV2MarketState public constant perpsv2marketstatesolperp_i =
        PerpsV2MarketState(0x435e6e499610B6De3510F0Cb047D3575C7bca6E1);
    // https://explorer.optimism.io/address/0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D
    ProxyPerpsV2 public constant perpsv2proxysolperp_i = ProxyPerpsV2(0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D);
    // https://explorer.optimism.io/address/0xC02AF29944301c8FbA606a7dF8ef446dc103238C
    PerpsV2MarketState public constant perpsv2marketstateavaxperp_i =
        PerpsV2MarketState(0xC02AF29944301c8FbA606a7dF8ef446dc103238C);
    // https://explorer.optimism.io/address/0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D
    ProxyPerpsV2 public constant perpsv2proxyavaxperp_i = ProxyPerpsV2(0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D);
    // https://explorer.optimism.io/address/0x6393113A43A4A88b9F3D53b4b21e7feEb5d3D821
    PerpsV2MarketState public constant perpsv2marketstatearbperp_i =
        PerpsV2MarketState(0x6393113A43A4A88b9F3D53b4b21e7feEb5d3D821);
    // https://explorer.optimism.io/address/0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e
    ProxyPerpsV2 public constant perpsv2proxyarbperp_i = ProxyPerpsV2(0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e);
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
        contracts[1] = address(perpsv2marketstateethperp_i);
        contracts[2] = address(perpsv2proxyethperp_i);
        contracts[3] = address(futuresmarketmanager_i);
        contracts[4] = address(perpsv2marketstatebtcperp_i);
        contracts[5] = address(perpsv2proxybtcperp_i);
        contracts[6] = address(perpsv2marketstatelinkperp_i);
        contracts[7] = address(perpsv2proxylinkperp_i);
        contracts[8] = address(perpsv2marketstatesolperp_i);
        contracts[9] = address(perpsv2proxysolperp_i);
        contracts[10] = address(perpsv2marketstateavaxperp_i);
        contracts[11] = address(perpsv2proxyavaxperp_i);
        contracts[12] = address(perpsv2marketstatearbperp_i);
        contracts[13] = address(perpsv2proxyarbperp_i);
        contracts[14] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        perpsv2marketstateethperp_removeAssociatedContracts_1();
        perpsv2marketstateethperp_addAssociatedContracts_2();
        perpsv2proxyethperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyethperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyethperp_i.removeRoute(0xec556889);
        perpsv2proxyethperp_i.removeRoute(0xbc67f832);
        perpsv2proxyethperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketETHPERP.closePosition;
        perpsv2proxyethperp_i.addRoute(0xa126d601, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketETHPERP.closePositionWithTracking;
        perpsv2proxyethperp_i.addRoute(0x5c8011c3, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketETHPERP.modifyPosition;
        perpsv2proxyethperp_i.addRoute(0x4ad4914b, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketETHPERP.modifyPositionWithTracking;
        perpsv2proxyethperp_i.addRoute(0x32f05103, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketETHPERP.recomputeFunding;
        perpsv2proxyethperp_i.addRoute(0x4eb985cc, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketETHPERP.transferMargin;
        perpsv2proxyethperp_i.addRoute(0x88a3c848, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketETHPERP.withdrawAllMargin;
        perpsv2proxyethperp_i.addRoute(0x5a1cbd2b, 0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD, false);
        // Add route to PerpsV2MarketLiquidateETHPERP.flagPosition;
        perpsv2proxyethperp_i.addRoute(0x909bc379, 0xb474425297945dA2F38423cDAb98f63860412F14, false);
        // Add route to PerpsV2MarketLiquidateETHPERP.forceLiquidatePosition;
        perpsv2proxyethperp_i.addRoute(0x3c92b8ec, 0xb474425297945dA2F38423cDAb98f63860412F14, false);
        // Add route to PerpsV2MarketLiquidateETHPERP.liquidatePosition;
        perpsv2proxyethperp_i.addRoute(0x7498a0f0, 0xb474425297945dA2F38423cDAb98f63860412F14, false);
        futuresmarketmanager_updateMarketsImplementations_18();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_19();
        perpsv2marketstatebtcperp_removeAssociatedContracts_20();
        perpsv2marketstatebtcperp_addAssociatedContracts_21();
        perpsv2proxybtcperp_i.removeRoute(0x2af64bd3);
        perpsv2proxybtcperp_i.removeRoute(0xd67bdd25);
        perpsv2proxybtcperp_i.removeRoute(0xec556889);
        perpsv2proxybtcperp_i.removeRoute(0xbc67f832);
        perpsv2proxybtcperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketBTCPERP.closePosition;
        perpsv2proxybtcperp_i.addRoute(0xa126d601, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketBTCPERP.closePositionWithTracking;
        perpsv2proxybtcperp_i.addRoute(0x5c8011c3, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketBTCPERP.modifyPosition;
        perpsv2proxybtcperp_i.addRoute(0x4ad4914b, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketBTCPERP.modifyPositionWithTracking;
        perpsv2proxybtcperp_i.addRoute(0x32f05103, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketBTCPERP.recomputeFunding;
        perpsv2proxybtcperp_i.addRoute(0x4eb985cc, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketBTCPERP.transferMargin;
        perpsv2proxybtcperp_i.addRoute(0x88a3c848, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketBTCPERP.withdrawAllMargin;
        perpsv2proxybtcperp_i.addRoute(0x5a1cbd2b, 0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d, false);
        // Add route to PerpsV2MarketLiquidateBTCPERP.flagPosition;
        perpsv2proxybtcperp_i.addRoute(0x909bc379, 0x0679e0fa9ecD77e2Bd900555CbE10a5Dd519A5fd, false);
        // Add route to PerpsV2MarketLiquidateBTCPERP.forceLiquidatePosition;
        perpsv2proxybtcperp_i.addRoute(0x3c92b8ec, 0x0679e0fa9ecD77e2Bd900555CbE10a5Dd519A5fd, false);
        // Add route to PerpsV2MarketLiquidateBTCPERP.liquidatePosition;
        perpsv2proxybtcperp_i.addRoute(0x7498a0f0, 0x0679e0fa9ecD77e2Bd900555CbE10a5Dd519A5fd, false);
        futuresmarketmanager_updateMarketsImplementations_37();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_38();
        perpsv2marketstatelinkperp_removeAssociatedContracts_39();
        perpsv2marketstatelinkperp_addAssociatedContracts_40();
        perpsv2proxylinkperp_i.removeRoute(0x2af64bd3);
        perpsv2proxylinkperp_i.removeRoute(0xd67bdd25);
        perpsv2proxylinkperp_i.removeRoute(0xec556889);
        perpsv2proxylinkperp_i.removeRoute(0xbc67f832);
        perpsv2proxylinkperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketLINKPERP.closePosition;
        perpsv2proxylinkperp_i.addRoute(0xa126d601, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLINKPERP.closePositionWithTracking;
        perpsv2proxylinkperp_i.addRoute(0x5c8011c3, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLINKPERP.modifyPosition;
        perpsv2proxylinkperp_i.addRoute(0x4ad4914b, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLINKPERP.modifyPositionWithTracking;
        perpsv2proxylinkperp_i.addRoute(0x32f05103, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLINKPERP.recomputeFunding;
        perpsv2proxylinkperp_i.addRoute(0x4eb985cc, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLINKPERP.transferMargin;
        perpsv2proxylinkperp_i.addRoute(0x88a3c848, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLINKPERP.withdrawAllMargin;
        perpsv2proxylinkperp_i.addRoute(0x5a1cbd2b, 0x885B3fF84a0Fe82eb97A23093421504e42cc8f74, false);
        // Add route to PerpsV2MarketLiquidateLINKPERP.flagPosition;
        perpsv2proxylinkperp_i.addRoute(0x909bc379, 0x7D5bf858398DEa0186988A2BfDCF86aE22dd8612, false);
        // Add route to PerpsV2MarketLiquidateLINKPERP.forceLiquidatePosition;
        perpsv2proxylinkperp_i.addRoute(0x3c92b8ec, 0x7D5bf858398DEa0186988A2BfDCF86aE22dd8612, false);
        // Add route to PerpsV2MarketLiquidateLINKPERP.liquidatePosition;
        perpsv2proxylinkperp_i.addRoute(0x7498a0f0, 0x7D5bf858398DEa0186988A2BfDCF86aE22dd8612, false);
        futuresmarketmanager_updateMarketsImplementations_56();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_57();
        perpsv2marketstatesolperp_removeAssociatedContracts_58();
        perpsv2marketstatesolperp_addAssociatedContracts_59();
        perpsv2proxysolperp_i.removeRoute(0x2af64bd3);
        perpsv2proxysolperp_i.removeRoute(0xd67bdd25);
        perpsv2proxysolperp_i.removeRoute(0xec556889);
        perpsv2proxysolperp_i.removeRoute(0xbc67f832);
        perpsv2proxysolperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketSOLPERP.closePosition;
        perpsv2proxysolperp_i.addRoute(0xa126d601, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketSOLPERP.closePositionWithTracking;
        perpsv2proxysolperp_i.addRoute(0x5c8011c3, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketSOLPERP.modifyPosition;
        perpsv2proxysolperp_i.addRoute(0x4ad4914b, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketSOLPERP.modifyPositionWithTracking;
        perpsv2proxysolperp_i.addRoute(0x32f05103, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketSOLPERP.recomputeFunding;
        perpsv2proxysolperp_i.addRoute(0x4eb985cc, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketSOLPERP.transferMargin;
        perpsv2proxysolperp_i.addRoute(0x88a3c848, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketSOLPERP.withdrawAllMargin;
        perpsv2proxysolperp_i.addRoute(0x5a1cbd2b, 0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E, false);
        // Add route to PerpsV2MarketLiquidateSOLPERP.flagPosition;
        perpsv2proxysolperp_i.addRoute(0x909bc379, 0x80cbc948c5dba55dc829472373e9F20203E13EB2, false);
        // Add route to PerpsV2MarketLiquidateSOLPERP.forceLiquidatePosition;
        perpsv2proxysolperp_i.addRoute(0x3c92b8ec, 0x80cbc948c5dba55dc829472373e9F20203E13EB2, false);
        // Add route to PerpsV2MarketLiquidateSOLPERP.liquidatePosition;
        perpsv2proxysolperp_i.addRoute(0x7498a0f0, 0x80cbc948c5dba55dc829472373e9F20203E13EB2, false);
        futuresmarketmanager_updateMarketsImplementations_75();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_76();
        perpsv2marketstateavaxperp_removeAssociatedContracts_77();
        perpsv2marketstateavaxperp_addAssociatedContracts_78();
        perpsv2proxyavaxperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyavaxperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyavaxperp_i.removeRoute(0xec556889);
        perpsv2proxyavaxperp_i.removeRoute(0xbc67f832);
        perpsv2proxyavaxperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketAVAXPERP.closePosition;
        perpsv2proxyavaxperp_i.addRoute(0xa126d601, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketAVAXPERP.closePositionWithTracking;
        perpsv2proxyavaxperp_i.addRoute(0x5c8011c3, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketAVAXPERP.modifyPosition;
        perpsv2proxyavaxperp_i.addRoute(0x4ad4914b, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketAVAXPERP.modifyPositionWithTracking;
        perpsv2proxyavaxperp_i.addRoute(0x32f05103, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketAVAXPERP.recomputeFunding;
        perpsv2proxyavaxperp_i.addRoute(0x4eb985cc, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketAVAXPERP.transferMargin;
        perpsv2proxyavaxperp_i.addRoute(0x88a3c848, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketAVAXPERP.withdrawAllMargin;
        perpsv2proxyavaxperp_i.addRoute(0x5a1cbd2b, 0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9, false);
        // Add route to PerpsV2MarketLiquidateAVAXPERP.flagPosition;
        perpsv2proxyavaxperp_i.addRoute(0x909bc379, 0xB1ad6dD82d086F31d2143080b0064aBc44cf2b5B, false);
        // Add route to PerpsV2MarketLiquidateAVAXPERP.forceLiquidatePosition;
        perpsv2proxyavaxperp_i.addRoute(0x3c92b8ec, 0xB1ad6dD82d086F31d2143080b0064aBc44cf2b5B, false);
        // Add route to PerpsV2MarketLiquidateAVAXPERP.liquidatePosition;
        perpsv2proxyavaxperp_i.addRoute(0x7498a0f0, 0xB1ad6dD82d086F31d2143080b0064aBc44cf2b5B, false);
        futuresmarketmanager_updateMarketsImplementations_94();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_95();
        perpsv2marketstatearbperp_removeAssociatedContracts_96();
        perpsv2marketstatearbperp_addAssociatedContracts_97();
        perpsv2proxyarbperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyarbperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyarbperp_i.removeRoute(0xec556889);
        perpsv2proxyarbperp_i.removeRoute(0xbc67f832);
        perpsv2proxyarbperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketARBPERP.closePosition;
        perpsv2proxyarbperp_i.addRoute(0xa126d601, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketARBPERP.closePositionWithTracking;
        perpsv2proxyarbperp_i.addRoute(0x5c8011c3, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketARBPERP.modifyPosition;
        perpsv2proxyarbperp_i.addRoute(0x4ad4914b, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketARBPERP.modifyPositionWithTracking;
        perpsv2proxyarbperp_i.addRoute(0x32f05103, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketARBPERP.recomputeFunding;
        perpsv2proxyarbperp_i.addRoute(0x4eb985cc, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketARBPERP.transferMargin;
        perpsv2proxyarbperp_i.addRoute(0x88a3c848, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketARBPERP.withdrawAllMargin;
        perpsv2proxyarbperp_i.addRoute(0x5a1cbd2b, 0x5b37D50F3b7F03884d7cD005CDc7120F5060808c, false);
        // Add route to PerpsV2MarketLiquidateARBPERP.flagPosition;
        perpsv2proxyarbperp_i.addRoute(0x909bc379, 0xeF7F0BC2D93caEaA824EE56592e3C2E9d5Bf0C34, false);
        // Add route to PerpsV2MarketLiquidateARBPERP.forceLiquidatePosition;
        perpsv2proxyarbperp_i.addRoute(0x3c92b8ec, 0xeF7F0BC2D93caEaA824EE56592e3C2E9d5Bf0C34, false);
        // Add route to PerpsV2MarketLiquidateARBPERP.liquidatePosition;
        perpsv2proxyarbperp_i.addRoute(0x7498a0f0, 0xeF7F0BC2D93caEaA824EE56592e3C2E9d5Bf0C34, false);
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

    function perpsv2marketstateethperp_removeAssociatedContracts_1() internal {
        address[] memory perpsv2marketstateethperp_removeAssociatedContracts_associatedContracts_1_0 = new address[](2);
        perpsv2marketstateethperp_removeAssociatedContracts_associatedContracts_1_0[0] = address(
            0xf1B530F3dEfD144A024A958D4Ae37d138615D91D
        );
        perpsv2marketstateethperp_removeAssociatedContracts_associatedContracts_1_0[1] = address(
            0x248aB8Ac4BDb4ef401cCAD33B5fd7fB82Eb31eD2
        );
        perpsv2marketstateethperp_i.removeAssociatedContracts(
            perpsv2marketstateethperp_removeAssociatedContracts_associatedContracts_1_0
        );
    }

    function perpsv2marketstateethperp_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateethperp_addAssociatedContracts_associatedContracts_2_0 = new address[](2);
        perpsv2marketstateethperp_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x7c1560f20907Ed41aC740873FACF9E3Dce4f18DD
        );
        perpsv2marketstateethperp_addAssociatedContracts_associatedContracts_2_0[1] = address(
            0xb474425297945dA2F38423cDAb98f63860412F14
        );
        perpsv2marketstateethperp_i.addAssociatedContracts(
            perpsv2marketstateethperp_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_18() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0[0] = address(
            0x2B3bb4c683BFc5239B029131EEf3B1d214478d93
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

    function perpsv2marketstatebtcperp_removeAssociatedContracts_20() internal {
        address[] memory perpsv2marketstatebtcperp_removeAssociatedContracts_associatedContracts_20_0 = new address[](2);
        perpsv2marketstatebtcperp_removeAssociatedContracts_associatedContracts_20_0[0] = address(
            0x8bE1893E1D29FCf2B966Cdd083efe30DBf78D7f6
        );
        perpsv2marketstatebtcperp_removeAssociatedContracts_associatedContracts_20_0[1] = address(
            0x802E609928a2Fc12e587766C078F341BAD8c4D4F
        );
        perpsv2marketstatebtcperp_i.removeAssociatedContracts(
            perpsv2marketstatebtcperp_removeAssociatedContracts_associatedContracts_20_0
        );
    }

    function perpsv2marketstatebtcperp_addAssociatedContracts_21() internal {
        address[] memory perpsv2marketstatebtcperp_addAssociatedContracts_associatedContracts_21_0 = new address[](2);
        perpsv2marketstatebtcperp_addAssociatedContracts_associatedContracts_21_0[0] = address(
            0x352B138d7F6500fC71A014F3C7eD48B6d99fbe4d
        );
        perpsv2marketstatebtcperp_addAssociatedContracts_associatedContracts_21_0[1] = address(
            0x0679e0fa9ecD77e2Bd900555CbE10a5Dd519A5fd
        );
        perpsv2marketstatebtcperp_i.addAssociatedContracts(
            perpsv2marketstatebtcperp_addAssociatedContracts_associatedContracts_21_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_37() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0[0] = address(
            0x59b007E9ea8F89b069c43F8f45834d30853e3699
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

    function perpsv2marketstatelinkperp_removeAssociatedContracts_39() internal {
        address[] memory perpsv2marketstatelinkperp_removeAssociatedContracts_associatedContracts_39_0 = new address[](2);
        perpsv2marketstatelinkperp_removeAssociatedContracts_associatedContracts_39_0[0] = address(
            0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a
        );
        perpsv2marketstatelinkperp_removeAssociatedContracts_associatedContracts_39_0[1] = address(
            0x360Bc3aCB4fEA8112D8Ac20CE1E93b9B70C3d85a
        );
        perpsv2marketstatelinkperp_i.removeAssociatedContracts(
            perpsv2marketstatelinkperp_removeAssociatedContracts_associatedContracts_39_0
        );
    }

    function perpsv2marketstatelinkperp_addAssociatedContracts_40() internal {
        address[] memory perpsv2marketstatelinkperp_addAssociatedContracts_associatedContracts_40_0 = new address[](2);
        perpsv2marketstatelinkperp_addAssociatedContracts_associatedContracts_40_0[0] = address(
            0x885B3fF84a0Fe82eb97A23093421504e42cc8f74
        );
        perpsv2marketstatelinkperp_addAssociatedContracts_associatedContracts_40_0[1] = address(
            0x7D5bf858398DEa0186988A2BfDCF86aE22dd8612
        );
        perpsv2marketstatelinkperp_i.addAssociatedContracts(
            perpsv2marketstatelinkperp_addAssociatedContracts_associatedContracts_40_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_56() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0[0] = address(
            0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A
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

    function perpsv2marketstatesolperp_removeAssociatedContracts_58() internal {
        address[] memory perpsv2marketstatesolperp_removeAssociatedContracts_associatedContracts_58_0 = new address[](2);
        perpsv2marketstatesolperp_removeAssociatedContracts_associatedContracts_58_0[0] = address(
            0xF715727ab8458C5792961a1EB944f97A67289A61
        );
        perpsv2marketstatesolperp_removeAssociatedContracts_associatedContracts_58_0[1] = address(
            0x5c59426a609398A9753522E840F422faEDE70A5A
        );
        perpsv2marketstatesolperp_i.removeAssociatedContracts(
            perpsv2marketstatesolperp_removeAssociatedContracts_associatedContracts_58_0
        );
    }

    function perpsv2marketstatesolperp_addAssociatedContracts_59() internal {
        address[] memory perpsv2marketstatesolperp_addAssociatedContracts_associatedContracts_59_0 = new address[](2);
        perpsv2marketstatesolperp_addAssociatedContracts_associatedContracts_59_0[0] = address(
            0x00FC152C7Dc2dF709161dcc8bA541eB77E612D4E
        );
        perpsv2marketstatesolperp_addAssociatedContracts_associatedContracts_59_0[1] = address(
            0x80cbc948c5dba55dc829472373e9F20203E13EB2
        );
        perpsv2marketstatesolperp_i.addAssociatedContracts(
            perpsv2marketstatesolperp_addAssociatedContracts_associatedContracts_59_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_75() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0[0] = address(
            0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D
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

    function perpsv2marketstateavaxperp_removeAssociatedContracts_77() internal {
        address[] memory perpsv2marketstateavaxperp_removeAssociatedContracts_associatedContracts_77_0 = new address[](2);
        perpsv2marketstateavaxperp_removeAssociatedContracts_associatedContracts_77_0[0] = address(
            0x3E4EA2A0679Dec8C9040d6538B45425c72bE80D0
        );
        perpsv2marketstateavaxperp_removeAssociatedContracts_associatedContracts_77_0[1] = address(
            0x7d109dB6D68bC03BfbA4e5f129922fEc300Ab7Fe
        );
        perpsv2marketstateavaxperp_i.removeAssociatedContracts(
            perpsv2marketstateavaxperp_removeAssociatedContracts_associatedContracts_77_0
        );
    }

    function perpsv2marketstateavaxperp_addAssociatedContracts_78() internal {
        address[] memory perpsv2marketstateavaxperp_addAssociatedContracts_associatedContracts_78_0 = new address[](2);
        perpsv2marketstateavaxperp_addAssociatedContracts_associatedContracts_78_0[0] = address(
            0xE4bC6Fce51de6198Ac13eDB55E60B5ca67A4d7C9
        );
        perpsv2marketstateavaxperp_addAssociatedContracts_associatedContracts_78_0[1] = address(
            0xB1ad6dD82d086F31d2143080b0064aBc44cf2b5B
        );
        perpsv2marketstateavaxperp_i.addAssociatedContracts(
            perpsv2marketstateavaxperp_addAssociatedContracts_associatedContracts_78_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_94() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0[0] = address(
            0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D
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

    function perpsv2marketstatearbperp_removeAssociatedContracts_96() internal {
        address[] memory perpsv2marketstatearbperp_removeAssociatedContracts_associatedContracts_96_0 = new address[](2);
        perpsv2marketstatearbperp_removeAssociatedContracts_associatedContracts_96_0[0] = address(
            0x69cc4951D587D11577F16ca9B7D0e9D2745b27Cb
        );
        perpsv2marketstatearbperp_removeAssociatedContracts_associatedContracts_96_0[1] = address(
            0xa1Dea0c759Eb44e9aD9697E3c50E8dF8d19a402e
        );
        perpsv2marketstatearbperp_i.removeAssociatedContracts(
            perpsv2marketstatearbperp_removeAssociatedContracts_associatedContracts_96_0
        );
    }

    function perpsv2marketstatearbperp_addAssociatedContracts_97() internal {
        address[] memory perpsv2marketstatearbperp_addAssociatedContracts_associatedContracts_97_0 = new address[](2);
        perpsv2marketstatearbperp_addAssociatedContracts_associatedContracts_97_0[0] = address(
            0x5b37D50F3b7F03884d7cD005CDc7120F5060808c
        );
        perpsv2marketstatearbperp_addAssociatedContracts_associatedContracts_97_0[1] = address(
            0xeF7F0BC2D93caEaA824EE56592e3C2E9d5Bf0C34
        );
        perpsv2marketstatearbperp_i.addAssociatedContracts(
            perpsv2marketstatearbperp_addAssociatedContracts_associatedContracts_97_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_113() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0[0] = address(
            0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e
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
