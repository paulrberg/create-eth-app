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
import "../PerpsV2MarketState.sol";
import "../PerpsV2ExchangeRate.sol";
import "../FuturesMarketManager.sol";
import "../PerpsV2MarketSettings.sol";
import "../SystemStatus.sol";
import "../ExchangeRates.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_DschubbaOptimismStep1 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x1d46c117E7e9A5dd242724a1952911ECe78e0831
    PerpsV2MarketState public constant perpsv2marketstateldoperp_i =
        PerpsV2MarketState(0x1d46c117E7e9A5dd242724a1952911ECe78e0831);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2
    ExchangeRates public constant exchangerates_i = ExchangeRates(0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](6);
        contracts[0] = address(perpsv2marketstateldoperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(systemstatus_i);
        contracts[5] = address(exchangerates_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Add migration contract permission to pause
        systemstatus_i.updateAccessControl("Futures", address(this), true, false);
        // Preemptive pause all new marktes
        systemstatus_i.suspendFuturesMarket("sLDOPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocLDOPERP", 80);
        systemstatus_i.suspendFuturesMarket("sADAPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocADAPERP", 80);
        systemstatus_i.suspendFuturesMarket("sGMXPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocGMXPERP", 80);
        systemstatus_i.suspendFuturesMarket("sFILPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocFILPERP", 80);
        systemstatus_i.suspendFuturesMarket("sLTCPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocLTCPERP", 80);
        systemstatus_i.suspendFuturesMarket("sBCHPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocBCHPERP", 80);
        systemstatus_i.suspendFuturesMarket("sSHIBPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocSHIBPERP", 80);
        systemstatus_i.suspendFuturesMarket("sCRVPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocCRVPERP", 80);
        systemstatus_i.suspendFuturesMarket("sAPTPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocAPTPERP", 80);

        perpsv2marketstateldoperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sLDOPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sLDOPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sLDOPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sLDOPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sLDOPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sLDOPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sLDOPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sLDOPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sLDOPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sLDOPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sLDOPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sLDOPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sLDOPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sLDOPERP", 200000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sLDOPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sLDOPERP", 19000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sLDOPERP", "ocLDOPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sLDOPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sLDOPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sLDOPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sLDOPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sLDOPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sLDOPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocLDOPERP", 80);
        // Ensure the ExchangeRates contract has the standalone feed for APT;
        exchangerates_i.addAggregator("APT", 0x48f2EcF0Bd180239AEF474a9da945F2e2d41daA3);
        // Ensure the ExchangeRates contract has the standalone feed for LDO;
        exchangerates_i.addAggregator("LDO", 0x221618871470f78D8a3391d35B77dFb3C0fbc383);
        // Ensure the ExchangeRates contract has the standalone feed for ADA;
        exchangerates_i.addAggregator("ADA", 0x43dEa17DeE1ca50c6266acb59b32659E44D3ee5D);
        // Ensure the ExchangeRates contract has the standalone feed for GMX;
        exchangerates_i.addAggregator("GMX", 0x62f42f70ba85De1086476bB6BADE926d0E0b8a4C);
        // Ensure the ExchangeRates contract has the standalone feed for FIL;
        exchangerates_i.addAggregator("FIL", 0x66F61FEe824c1dF059BccCC5F21ca39e083EefDf);
        // Ensure the ExchangeRates contract has the standalone feed for LTC;
        exchangerates_i.addAggregator("LTC", 0x45954efBD01f5A12428A09E4C38b8434C3dD4Ac3);
        // Ensure the ExchangeRates contract has the standalone feed for BCH;
        exchangerates_i.addAggregator("BCH", 0x33E047119359161288bcB143e0C15467C7151d4c);
        // Ensure the ExchangeRates contract has the standalone feed for SHIB;
        exchangerates_i.addAggregator("SHIB", 0xd1e56e7657C0E0d20c0e11C2B6ae0D90932d5665);
        // Ensure the ExchangeRates contract has the standalone feed for CRV;
        exchangerates_i.addAggregator("CRV", 0xbD92C6c284271c227a1e0bF1786F468b539f51D9);
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for APT;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "APT",
            0x03ae4db29ed4ae33d323568895aa00337e658e348b37509f5372ae51f0af00d5
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for LDO;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "LDO",
            0xc63e2a7f37a04e5e614c07238bedb25dcc38927fba8fe890597a593c0b2fa4ad
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for ADA;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "ADA",
            0x2a01deaec9e51a579277b34b122399984d0bbf57e2458a7e42fecd2829867a0d
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for GMX;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "GMX",
            0xb962539d0fcb272a494d65ea56f94851c2bcf8823935da05bd628916e2e9edbf
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for FIL;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "FIL",
            0x150ac9b959aee0051e4091f0ef5216d941f590e1c5e7f91cf7635b5c11628c0e
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for LTC;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "LTC",
            0x6e3f3fa8253588df9326580180233eb791e03b443a3ba7a1d892e73874e19a54
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for BCH;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "BCH",
            0x3dd2b63686a450ec7290df3a1e0b583c0481f651351edfa7636f39aed55cf8a3
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for SHIB;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "SHIB",
            0xf0d57deca57b3da2fe63a493f4c25925fdfd8edf834b20f93e1f84dbd1504d4a
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for CRV;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "CRV",
            0xa19d04ac696c7a6616d291c7e5d1377cc8be437c327b75adb5dc1bad745fcae8
        );

        // Remove permission again
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

    function perpsv2exchangerate_addAssociatedContracts_1() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[0] = address(
            0x6BAD3Be3A7B3853739729833425a8b22737D0dAC
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0x8D08A8A066E9606F854a3C68FcC730e406319996
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0xaa94C874b91ef16C8B56A1c5B2F34E39366bD484);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }
}
