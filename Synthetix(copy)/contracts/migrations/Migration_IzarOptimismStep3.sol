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
contract Migration_IzarOptimismStep3 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C
    AddressResolver public constant addressresolver_i = AddressResolver(0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C);
    // https://explorer.optimism.io/address/0x82f962aF60e6627d3ea5Db5Fd7e1a57f7E1Ef2B8
    PerpsV2MarketState public constant perpsv2marketstatematicperp_i =
        PerpsV2MarketState(0x82f962aF60e6627d3ea5Db5Fd7e1a57f7E1Ef2B8);
    // https://explorer.optimism.io/address/0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042
    ProxyPerpsV2 public constant perpsv2proxymaticperp_i = ProxyPerpsV2(0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0xac3F9a2753f185731324907E6802395d59Bb62a2
    PerpsV2MarketState public constant perpsv2marketstatedydxperp_i =
        PerpsV2MarketState(0xac3F9a2753f185731324907E6802395d59Bb62a2);
    // https://explorer.optimism.io/address/0x139F94E4f0e1101c1464a321CBA815c34d58B5D9
    ProxyPerpsV2 public constant perpsv2proxydydxperp_i = ProxyPerpsV2(0x139F94E4f0e1101c1464a321CBA815c34d58B5D9);
    // https://explorer.optimism.io/address/0x3DfBB7D0770e6Eb77fBEc89C0840E9A0f29C76Ff
    PerpsV2MarketState public constant perpsv2marketstatebnbperp_i =
        PerpsV2MarketState(0x3DfBB7D0770e6Eb77fBEc89C0840E9A0f29C76Ff);
    // https://explorer.optimism.io/address/0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25
    ProxyPerpsV2 public constant perpsv2proxybnbperp_i = ProxyPerpsV2(0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25);
    // https://explorer.optimism.io/address/0xBdD0D09f73AC6f8Ef59A71baab283C12dcab06fA
    PerpsV2MarketState public constant perpsv2marketstateopperp_i =
        PerpsV2MarketState(0xBdD0D09f73AC6f8Ef59A71baab283C12dcab06fA);
    // https://explorer.optimism.io/address/0x442b69937a0daf9D46439a71567fABE6Cb69FBaf
    ProxyPerpsV2 public constant perpsv2proxyopperp_i = ProxyPerpsV2(0x442b69937a0daf9D46439a71567fABE6Cb69FBaf);
    // https://explorer.optimism.io/address/0xc564040630d6929070D85DF237FDf60F6bfE4b5F
    PerpsV2MarketState public constant perpsv2marketstatexauperp_i =
        PerpsV2MarketState(0xc564040630d6929070D85DF237FDf60F6bfE4b5F);
    // https://explorer.optimism.io/address/0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A
    ProxyPerpsV2 public constant perpsv2proxyxauperp_i = ProxyPerpsV2(0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A);
    // https://explorer.optimism.io/address/0x1951c6b2D9DD9A3CF10aaC5e79A7EcA0a5300BB5
    PerpsV2MarketState public constant perpsv2marketstateftmperp_i =
        PerpsV2MarketState(0x1951c6b2D9DD9A3CF10aaC5e79A7EcA0a5300BB5);
    // https://explorer.optimism.io/address/0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4
    ProxyPerpsV2 public constant perpsv2proxyftmperp_i = ProxyPerpsV2(0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4);
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
        contracts[1] = address(perpsv2marketstatematicperp_i);
        contracts[2] = address(perpsv2proxymaticperp_i);
        contracts[3] = address(futuresmarketmanager_i);
        contracts[4] = address(perpsv2marketstatedydxperp_i);
        contracts[5] = address(perpsv2proxydydxperp_i);
        contracts[6] = address(perpsv2marketstatebnbperp_i);
        contracts[7] = address(perpsv2proxybnbperp_i);
        contracts[8] = address(perpsv2marketstateopperp_i);
        contracts[9] = address(perpsv2proxyopperp_i);
        contracts[10] = address(perpsv2marketstatexauperp_i);
        contracts[11] = address(perpsv2proxyxauperp_i);
        contracts[12] = address(perpsv2marketstateftmperp_i);
        contracts[13] = address(perpsv2proxyftmperp_i);
        contracts[14] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        perpsv2marketstatematicperp_removeAssociatedContracts_1();
        perpsv2marketstatematicperp_addAssociatedContracts_2();
        perpsv2proxymaticperp_i.removeRoute(0x2af64bd3);
        perpsv2proxymaticperp_i.removeRoute(0xd67bdd25);
        perpsv2proxymaticperp_i.removeRoute(0xec556889);
        perpsv2proxymaticperp_i.removeRoute(0xbc67f832);
        perpsv2proxymaticperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketMATICPERP.closePosition;
        perpsv2proxymaticperp_i.addRoute(0xa126d601, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketMATICPERP.closePositionWithTracking;
        perpsv2proxymaticperp_i.addRoute(0x5c8011c3, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketMATICPERP.modifyPosition;
        perpsv2proxymaticperp_i.addRoute(0x4ad4914b, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketMATICPERP.modifyPositionWithTracking;
        perpsv2proxymaticperp_i.addRoute(0x32f05103, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketMATICPERP.recomputeFunding;
        perpsv2proxymaticperp_i.addRoute(0x4eb985cc, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketMATICPERP.transferMargin;
        perpsv2proxymaticperp_i.addRoute(0x88a3c848, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketMATICPERP.withdrawAllMargin;
        perpsv2proxymaticperp_i.addRoute(0x5a1cbd2b, 0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA, false);
        // Add route to PerpsV2MarketLiquidateMATICPERP.flagPosition;
        perpsv2proxymaticperp_i.addRoute(0x909bc379, 0xe37858391bC66B1B8838a7459e59A802642284Fa, false);
        // Add route to PerpsV2MarketLiquidateMATICPERP.forceLiquidatePosition;
        perpsv2proxymaticperp_i.addRoute(0x3c92b8ec, 0xe37858391bC66B1B8838a7459e59A802642284Fa, false);
        // Add route to PerpsV2MarketLiquidateMATICPERP.liquidatePosition;
        perpsv2proxymaticperp_i.addRoute(0x7498a0f0, 0xe37858391bC66B1B8838a7459e59A802642284Fa, false);
        futuresmarketmanager_updateMarketsImplementations_18();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_19();
        perpsv2marketstatedydxperp_removeAssociatedContracts_20();
        perpsv2marketstatedydxperp_addAssociatedContracts_21();
        perpsv2proxydydxperp_i.removeRoute(0x2af64bd3);
        perpsv2proxydydxperp_i.removeRoute(0xd67bdd25);
        perpsv2proxydydxperp_i.removeRoute(0xec556889);
        perpsv2proxydydxperp_i.removeRoute(0xbc67f832);
        perpsv2proxydydxperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketDYDXPERP.closePosition;
        perpsv2proxydydxperp_i.addRoute(0xa126d601, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketDYDXPERP.closePositionWithTracking;
        perpsv2proxydydxperp_i.addRoute(0x5c8011c3, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketDYDXPERP.modifyPosition;
        perpsv2proxydydxperp_i.addRoute(0x4ad4914b, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketDYDXPERP.modifyPositionWithTracking;
        perpsv2proxydydxperp_i.addRoute(0x32f05103, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketDYDXPERP.recomputeFunding;
        perpsv2proxydydxperp_i.addRoute(0x4eb985cc, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketDYDXPERP.transferMargin;
        perpsv2proxydydxperp_i.addRoute(0x88a3c848, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketDYDXPERP.withdrawAllMargin;
        perpsv2proxydydxperp_i.addRoute(0x5a1cbd2b, 0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2, false);
        // Add route to PerpsV2MarketLiquidateDYDXPERP.flagPosition;
        perpsv2proxydydxperp_i.addRoute(0x909bc379, 0x1f6B92EB7aA3dacA3DcCBaD74928827CF003f9A4, false);
        // Add route to PerpsV2MarketLiquidateDYDXPERP.forceLiquidatePosition;
        perpsv2proxydydxperp_i.addRoute(0x3c92b8ec, 0x1f6B92EB7aA3dacA3DcCBaD74928827CF003f9A4, false);
        // Add route to PerpsV2MarketLiquidateDYDXPERP.liquidatePosition;
        perpsv2proxydydxperp_i.addRoute(0x7498a0f0, 0x1f6B92EB7aA3dacA3DcCBaD74928827CF003f9A4, false);
        futuresmarketmanager_updateMarketsImplementations_37();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_38();
        perpsv2marketstatebnbperp_removeAssociatedContracts_39();
        perpsv2marketstatebnbperp_addAssociatedContracts_40();
        perpsv2proxybnbperp_i.removeRoute(0x2af64bd3);
        perpsv2proxybnbperp_i.removeRoute(0xd67bdd25);
        perpsv2proxybnbperp_i.removeRoute(0xec556889);
        perpsv2proxybnbperp_i.removeRoute(0xbc67f832);
        perpsv2proxybnbperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketBNBPERP.closePosition;
        perpsv2proxybnbperp_i.addRoute(0xa126d601, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketBNBPERP.closePositionWithTracking;
        perpsv2proxybnbperp_i.addRoute(0x5c8011c3, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketBNBPERP.modifyPosition;
        perpsv2proxybnbperp_i.addRoute(0x4ad4914b, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketBNBPERP.modifyPositionWithTracking;
        perpsv2proxybnbperp_i.addRoute(0x32f05103, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketBNBPERP.recomputeFunding;
        perpsv2proxybnbperp_i.addRoute(0x4eb985cc, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketBNBPERP.transferMargin;
        perpsv2proxybnbperp_i.addRoute(0x88a3c848, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketBNBPERP.withdrawAllMargin;
        perpsv2proxybnbperp_i.addRoute(0x5a1cbd2b, 0xf4Aa6bF149873Cb965061f845407091eF9f50722, false);
        // Add route to PerpsV2MarketLiquidateBNBPERP.flagPosition;
        perpsv2proxybnbperp_i.addRoute(0x909bc379, 0xE7C25f3E803C7eb5a08d0332D0c28417241d5462, false);
        // Add route to PerpsV2MarketLiquidateBNBPERP.forceLiquidatePosition;
        perpsv2proxybnbperp_i.addRoute(0x3c92b8ec, 0xE7C25f3E803C7eb5a08d0332D0c28417241d5462, false);
        // Add route to PerpsV2MarketLiquidateBNBPERP.liquidatePosition;
        perpsv2proxybnbperp_i.addRoute(0x7498a0f0, 0xE7C25f3E803C7eb5a08d0332D0c28417241d5462, false);
        futuresmarketmanager_updateMarketsImplementations_56();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_57();
        perpsv2marketstateopperp_removeAssociatedContracts_58();
        perpsv2marketstateopperp_addAssociatedContracts_59();
        perpsv2proxyopperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyopperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyopperp_i.removeRoute(0xec556889);
        perpsv2proxyopperp_i.removeRoute(0xbc67f832);
        perpsv2proxyopperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketOPPERP.closePosition;
        perpsv2proxyopperp_i.addRoute(0xa126d601, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketOPPERP.closePositionWithTracking;
        perpsv2proxyopperp_i.addRoute(0x5c8011c3, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketOPPERP.modifyPosition;
        perpsv2proxyopperp_i.addRoute(0x4ad4914b, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketOPPERP.modifyPositionWithTracking;
        perpsv2proxyopperp_i.addRoute(0x32f05103, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketOPPERP.recomputeFunding;
        perpsv2proxyopperp_i.addRoute(0x4eb985cc, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketOPPERP.transferMargin;
        perpsv2proxyopperp_i.addRoute(0x88a3c848, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketOPPERP.withdrawAllMargin;
        perpsv2proxyopperp_i.addRoute(0x5a1cbd2b, 0x102AFf35C746B44a639A1cE344A1461306835e86, false);
        // Add route to PerpsV2MarketLiquidateOPPERP.flagPosition;
        perpsv2proxyopperp_i.addRoute(0x909bc379, 0xE9Dc2C1008b1322c21c1Fb45CD101f1b7A0C9f73, false);
        // Add route to PerpsV2MarketLiquidateOPPERP.forceLiquidatePosition;
        perpsv2proxyopperp_i.addRoute(0x3c92b8ec, 0xE9Dc2C1008b1322c21c1Fb45CD101f1b7A0C9f73, false);
        // Add route to PerpsV2MarketLiquidateOPPERP.liquidatePosition;
        perpsv2proxyopperp_i.addRoute(0x7498a0f0, 0xE9Dc2C1008b1322c21c1Fb45CD101f1b7A0C9f73, false);
        futuresmarketmanager_updateMarketsImplementations_75();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_76();
        perpsv2marketstatexauperp_removeAssociatedContracts_77();
        perpsv2marketstatexauperp_addAssociatedContracts_78();
        perpsv2proxyxauperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyxauperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyxauperp_i.removeRoute(0xec556889);
        perpsv2proxyxauperp_i.removeRoute(0xbc67f832);
        perpsv2proxyxauperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketXAUPERP.closePosition;
        perpsv2proxyxauperp_i.addRoute(0xa126d601, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketXAUPERP.closePositionWithTracking;
        perpsv2proxyxauperp_i.addRoute(0x5c8011c3, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketXAUPERP.modifyPosition;
        perpsv2proxyxauperp_i.addRoute(0x4ad4914b, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketXAUPERP.modifyPositionWithTracking;
        perpsv2proxyxauperp_i.addRoute(0x32f05103, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketXAUPERP.recomputeFunding;
        perpsv2proxyxauperp_i.addRoute(0x4eb985cc, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketXAUPERP.transferMargin;
        perpsv2proxyxauperp_i.addRoute(0x88a3c848, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketXAUPERP.withdrawAllMargin;
        perpsv2proxyxauperp_i.addRoute(0x5a1cbd2b, 0xd6A06A8c73265e471639bd953D24832bBcd548fd, false);
        // Add route to PerpsV2MarketLiquidateXAUPERP.flagPosition;
        perpsv2proxyxauperp_i.addRoute(0x909bc379, 0x2493291196F02794465b89Ef50F80C60fa8d0E89, false);
        // Add route to PerpsV2MarketLiquidateXAUPERP.forceLiquidatePosition;
        perpsv2proxyxauperp_i.addRoute(0x3c92b8ec, 0x2493291196F02794465b89Ef50F80C60fa8d0E89, false);
        // Add route to PerpsV2MarketLiquidateXAUPERP.liquidatePosition;
        perpsv2proxyxauperp_i.addRoute(0x7498a0f0, 0x2493291196F02794465b89Ef50F80C60fa8d0E89, false);
        futuresmarketmanager_updateMarketsImplementations_94();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_95();
        perpsv2marketstateftmperp_removeAssociatedContracts_96();
        perpsv2marketstateftmperp_addAssociatedContracts_97();
        perpsv2proxyftmperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyftmperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyftmperp_i.removeRoute(0xec556889);
        perpsv2proxyftmperp_i.removeRoute(0xbc67f832);
        perpsv2proxyftmperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketFTMPERP.closePosition;
        perpsv2proxyftmperp_i.addRoute(0xa126d601, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketFTMPERP.closePositionWithTracking;
        perpsv2proxyftmperp_i.addRoute(0x5c8011c3, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketFTMPERP.modifyPosition;
        perpsv2proxyftmperp_i.addRoute(0x4ad4914b, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketFTMPERP.modifyPositionWithTracking;
        perpsv2proxyftmperp_i.addRoute(0x32f05103, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketFTMPERP.recomputeFunding;
        perpsv2proxyftmperp_i.addRoute(0x4eb985cc, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketFTMPERP.transferMargin;
        perpsv2proxyftmperp_i.addRoute(0x88a3c848, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketFTMPERP.withdrawAllMargin;
        perpsv2proxyftmperp_i.addRoute(0x5a1cbd2b, 0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE, false);
        // Add route to PerpsV2MarketLiquidateFTMPERP.flagPosition;
        perpsv2proxyftmperp_i.addRoute(0x909bc379, 0x6680180094DF2421A9c5140b207f95759C9080Dc, false);
        // Add route to PerpsV2MarketLiquidateFTMPERP.forceLiquidatePosition;
        perpsv2proxyftmperp_i.addRoute(0x3c92b8ec, 0x6680180094DF2421A9c5140b207f95759C9080Dc, false);
        // Add route to PerpsV2MarketLiquidateFTMPERP.liquidatePosition;
        perpsv2proxyftmperp_i.addRoute(0x7498a0f0, 0x6680180094DF2421A9c5140b207f95759C9080Dc, false);
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

    function perpsv2marketstatematicperp_removeAssociatedContracts_1() internal {
        address[] memory perpsv2marketstatematicperp_removeAssociatedContracts_associatedContracts_1_0 = new address[](2);
        perpsv2marketstatematicperp_removeAssociatedContracts_associatedContracts_1_0[0] = address(
            0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943
        );
        perpsv2marketstatematicperp_removeAssociatedContracts_associatedContracts_1_0[1] = address(
            0x0d9A83b625d9793371bF4777De4F24f57f4527e1
        );
        perpsv2marketstatematicperp_i.removeAssociatedContracts(
            perpsv2marketstatematicperp_removeAssociatedContracts_associatedContracts_1_0
        );
    }

    function perpsv2marketstatematicperp_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatematicperp_addAssociatedContracts_associatedContracts_2_0 = new address[](2);
        perpsv2marketstatematicperp_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x496B1C5EEf77E6Ea7Ff98bB22b5ec01Dd4CFdeDA
        );
        perpsv2marketstatematicperp_addAssociatedContracts_associatedContracts_2_0[1] = address(
            0xe37858391bC66B1B8838a7459e59A802642284Fa
        );
        perpsv2marketstatematicperp_i.addAssociatedContracts(
            perpsv2marketstatematicperp_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_18() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0[0] = address(
            0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042
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

    function perpsv2marketstatedydxperp_removeAssociatedContracts_20() internal {
        address[] memory perpsv2marketstatedydxperp_removeAssociatedContracts_associatedContracts_20_0 = new address[](2);
        perpsv2marketstatedydxperp_removeAssociatedContracts_associatedContracts_20_0[0] = address(
            0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679
        );
        perpsv2marketstatedydxperp_removeAssociatedContracts_associatedContracts_20_0[1] = address(
            0xAbA508B0F09fb7ff9a3fe129c09BC87a00B0ddeC
        );
        perpsv2marketstatedydxperp_i.removeAssociatedContracts(
            perpsv2marketstatedydxperp_removeAssociatedContracts_associatedContracts_20_0
        );
    }

    function perpsv2marketstatedydxperp_addAssociatedContracts_21() internal {
        address[] memory perpsv2marketstatedydxperp_addAssociatedContracts_associatedContracts_21_0 = new address[](2);
        perpsv2marketstatedydxperp_addAssociatedContracts_associatedContracts_21_0[0] = address(
            0x65Df3Ec0d5fd06a2f29C68e7894804b496945ef2
        );
        perpsv2marketstatedydxperp_addAssociatedContracts_associatedContracts_21_0[1] = address(
            0x1f6B92EB7aA3dacA3DcCBaD74928827CF003f9A4
        );
        perpsv2marketstatedydxperp_i.addAssociatedContracts(
            perpsv2marketstatedydxperp_addAssociatedContracts_associatedContracts_21_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_37() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0[0] = address(
            0x139F94E4f0e1101c1464a321CBA815c34d58B5D9
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

    function perpsv2marketstatebnbperp_removeAssociatedContracts_39() internal {
        address[] memory perpsv2marketstatebnbperp_removeAssociatedContracts_associatedContracts_39_0 = new address[](2);
        perpsv2marketstatebnbperp_removeAssociatedContracts_associatedContracts_39_0[0] = address(
            0xBccaC7cbc37aa2De510863647197D584F55AE46b
        );
        perpsv2marketstatebnbperp_removeAssociatedContracts_associatedContracts_39_0[1] = address(
            0x7C5FbeBDfE7659BEe68A4Aa284575a21055651eA
        );
        perpsv2marketstatebnbperp_i.removeAssociatedContracts(
            perpsv2marketstatebnbperp_removeAssociatedContracts_associatedContracts_39_0
        );
    }

    function perpsv2marketstatebnbperp_addAssociatedContracts_40() internal {
        address[] memory perpsv2marketstatebnbperp_addAssociatedContracts_associatedContracts_40_0 = new address[](2);
        perpsv2marketstatebnbperp_addAssociatedContracts_associatedContracts_40_0[0] = address(
            0xf4Aa6bF149873Cb965061f845407091eF9f50722
        );
        perpsv2marketstatebnbperp_addAssociatedContracts_associatedContracts_40_0[1] = address(
            0xE7C25f3E803C7eb5a08d0332D0c28417241d5462
        );
        perpsv2marketstatebnbperp_i.addAssociatedContracts(
            perpsv2marketstatebnbperp_addAssociatedContracts_associatedContracts_40_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_56() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0[0] = address(
            0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25
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

    function perpsv2marketstateopperp_removeAssociatedContracts_58() internal {
        address[] memory perpsv2marketstateopperp_removeAssociatedContracts_associatedContracts_58_0 = new address[](2);
        perpsv2marketstateopperp_removeAssociatedContracts_associatedContracts_58_0[0] = address(
            0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0
        );
        perpsv2marketstateopperp_removeAssociatedContracts_associatedContracts_58_0[1] = address(
            0xdD28261FC65c4Ed29b9D11aac0F44079cfCA4F32
        );
        perpsv2marketstateopperp_i.removeAssociatedContracts(
            perpsv2marketstateopperp_removeAssociatedContracts_associatedContracts_58_0
        );
    }

    function perpsv2marketstateopperp_addAssociatedContracts_59() internal {
        address[] memory perpsv2marketstateopperp_addAssociatedContracts_associatedContracts_59_0 = new address[](2);
        perpsv2marketstateopperp_addAssociatedContracts_associatedContracts_59_0[0] = address(
            0x102AFf35C746B44a639A1cE344A1461306835e86
        );
        perpsv2marketstateopperp_addAssociatedContracts_associatedContracts_59_0[1] = address(
            0xE9Dc2C1008b1322c21c1Fb45CD101f1b7A0C9f73
        );
        perpsv2marketstateopperp_i.addAssociatedContracts(
            perpsv2marketstateopperp_addAssociatedContracts_associatedContracts_59_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_75() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0[0] = address(
            0x442b69937a0daf9D46439a71567fABE6Cb69FBaf
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

    function perpsv2marketstatexauperp_removeAssociatedContracts_77() internal {
        address[] memory perpsv2marketstatexauperp_removeAssociatedContracts_associatedContracts_77_0 = new address[](2);
        perpsv2marketstatexauperp_removeAssociatedContracts_associatedContracts_77_0[0] = address(
            0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2
        );
        perpsv2marketstatexauperp_removeAssociatedContracts_associatedContracts_77_0[1] = address(
            0xa95e89d93A7432A2Ce9453ec4E264940a96B364b
        );
        perpsv2marketstatexauperp_i.removeAssociatedContracts(
            perpsv2marketstatexauperp_removeAssociatedContracts_associatedContracts_77_0
        );
    }

    function perpsv2marketstatexauperp_addAssociatedContracts_78() internal {
        address[] memory perpsv2marketstatexauperp_addAssociatedContracts_associatedContracts_78_0 = new address[](2);
        perpsv2marketstatexauperp_addAssociatedContracts_associatedContracts_78_0[0] = address(
            0xd6A06A8c73265e471639bd953D24832bBcd548fd
        );
        perpsv2marketstatexauperp_addAssociatedContracts_associatedContracts_78_0[1] = address(
            0x2493291196F02794465b89Ef50F80C60fa8d0E89
        );
        perpsv2marketstatexauperp_i.addAssociatedContracts(
            perpsv2marketstatexauperp_addAssociatedContracts_associatedContracts_78_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_94() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0[0] = address(
            0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A
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

    function perpsv2marketstateftmperp_removeAssociatedContracts_96() internal {
        address[] memory perpsv2marketstateftmperp_removeAssociatedContracts_associatedContracts_96_0 = new address[](2);
        perpsv2marketstateftmperp_removeAssociatedContracts_associatedContracts_96_0[0] = address(
            0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496
        );
        perpsv2marketstateftmperp_removeAssociatedContracts_associatedContracts_96_0[1] = address(
            0xA6808A69b3CA50CB2E4a41A51f8979FFaB2D2db2
        );
        perpsv2marketstateftmperp_i.removeAssociatedContracts(
            perpsv2marketstateftmperp_removeAssociatedContracts_associatedContracts_96_0
        );
    }

    function perpsv2marketstateftmperp_addAssociatedContracts_97() internal {
        address[] memory perpsv2marketstateftmperp_addAssociatedContracts_associatedContracts_97_0 = new address[](2);
        perpsv2marketstateftmperp_addAssociatedContracts_associatedContracts_97_0[0] = address(
            0x1454ba0f1c5Fcb401cfe72E028114FEE022990EE
        );
        perpsv2marketstateftmperp_addAssociatedContracts_associatedContracts_97_0[1] = address(
            0x6680180094DF2421A9c5140b207f95759C9080Dc
        );
        perpsv2marketstateftmperp_i.addAssociatedContracts(
            perpsv2marketstateftmperp_addAssociatedContracts_associatedContracts_97_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_113() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0[0] = address(
            0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4
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
