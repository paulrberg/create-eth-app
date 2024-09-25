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
contract Migration_AnkaaOptimismStep1 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xd10cd91683301c8C15eDA40F59e73d1b0BcfECDD
    PerpsV2MarketState public constant perpsv2marketstateethbtcperp_i =
        PerpsV2MarketState(0xd10cd91683301c8C15eDA40F59e73d1b0BcfECDD);
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
    // https://explorer.optimism.io/address/0x04412b2aE241C602Be87Bc1114238d50d08398Fb
    PerpsV2MarketState public constant perpsv2marketstateetcperp_i =
        PerpsV2MarketState(0x04412b2aE241C602Be87Bc1114238d50d08398Fb);
    // https://explorer.optimism.io/address/0xF8dBEf33111A37879f35EE15507769CA927cf9C0
    PerpsV2MarketState public constant perpsv2marketstatecompperp_i =
        PerpsV2MarketState(0xF8dBEf33111A37879f35EE15507769CA927cf9C0);
    // https://explorer.optimism.io/address/0x3d869950817920Eda9fC9A633ab7F06B97444dd7
    PerpsV2MarketState public constant perpsv2marketstatexmrperp_i =
        PerpsV2MarketState(0x3d869950817920Eda9fC9A633ab7F06B97444dd7);
    // https://explorer.optimism.io/address/0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2
    ExchangeRates public constant exchangerates_i = ExchangeRates(0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](9);
        contracts[0] = address(perpsv2marketstateethbtcperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(systemstatus_i);
        contracts[5] = address(perpsv2marketstateetcperp_i);
        contracts[6] = address(perpsv2marketstatecompperp_i);
        contracts[7] = address(perpsv2marketstatexmrperp_i);
        contracts[8] = address(exchangerates_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Add migration contract permission to pause
        systemstatus_i.updateAccessControl("Futures", address(this), true, false);

        perpsv2marketstateethbtcperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sETHBTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sETHBTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sETHBTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sETHBTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sETHBTCPERP", 500000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sETHBTCPERP", 100000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sETHBTCPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sETHBTCPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sETHBTCPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sETHBTCPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sETHBTCPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sETHBTCPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sETHBTCPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sETHBTCPERP", 50000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sETHBTCPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sETHBTCPERP", 1700000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sETHBTCPERP", "ocETHBTCPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sETHBTCPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sETHBTCPERP", 1562500000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sETHBTCPERP", 600000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sETHBTCPERP", 7500000000000000);
        perpsv2marketsettings_i.setMaxPD("sETHBTCPERP", 1200000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sETHBTCPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocETHBTCPERP", 80);
        perpsv2marketstateetcperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_28();
        futuresmarketmanager_addProxiedMarkets_29();
        perpsv2marketsettings_i.setTakerFee("sETCPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sETCPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sETCPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sETCPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sETCPERP", 800000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sETCPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sETCPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sETCPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sETCPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sETCPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sETCPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sETCPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sETCPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sETCPERP", 55000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sETCPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sETCPERP", 4000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sETCPERP", "ocETCPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sETCPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sETCPERP", 1562500000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sETCPERP", 1000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sETCPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sETCPERP", 2000000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sETCPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocETCPERP", 80);
        perpsv2marketstatecompperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_55();
        futuresmarketmanager_addProxiedMarkets_56();
        perpsv2marketsettings_i.setTakerFee("sCOMPPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sCOMPPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sCOMPPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sCOMPPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sCOMPPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sCOMPPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sCOMPPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sCOMPPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sCOMPPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sCOMPPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sCOMPPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sCOMPPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sCOMPPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sCOMPPERP", 15000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sCOMPPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sCOMPPERP", 860000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sCOMPPERP", "ocCOMPPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sCOMPPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sCOMPPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sCOMPPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sCOMPPERP", 15000000000000000);
        perpsv2marketsettings_i.setMaxPD("sCOMPPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sCOMPPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocCOMPPERP", 80);
        perpsv2marketstatexmrperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_82();
        futuresmarketmanager_addProxiedMarkets_83();
        perpsv2marketsettings_i.setTakerFee("sXMRPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sXMRPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sXMRPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sXMRPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sXMRPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sXMRPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sXMRPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sXMRPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sXMRPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sXMRPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sXMRPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sXMRPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sXMRPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sXMRPERP", 5000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sXMRPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sXMRPERP", 255000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sXMRPERP", "ocXMRPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sXMRPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sXMRPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sXMRPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sXMRPERP", 15000000000000000);
        perpsv2marketsettings_i.setMaxPD("sXMRPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sXMRPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocXMRPERP", 80);
        // Remove permission to migration contract
        systemstatus_i.updateAccessControl("Futures", address(this), false, false);
        // Ensure the ExchangeRates contract has the standalone feed for MAV;
        exchangerates_i.addAggregator("MAV", 0x51E06250C8E46c8E5DE41ac8B917a47D706128C2);
        // Ensure the ExchangeRates contract has the standalone feed for ETHBTC;
        exchangerates_i.addAggregator("ETHBTC", 0xe4b9bcD7d0AA917f19019165EB89BdbbF36d2cBe);
        // Ensure the ExchangeRates contract has the standalone feed for ETC;
        exchangerates_i.addAggregator("ETC", 0xb7B9A39CC63f856b90B364911CC324dC46aC1770);
        // Ensure the ExchangeRates contract has the standalone feed for COMP;
        exchangerates_i.addAggregator("COMP", 0xe1011160d78a80E2eEBD60C228EEf7af4Dfcd4d7);
        // Ensure the ExchangeRates contract has the standalone feed for MKR;
        exchangerates_i.addAggregator("MKR", 0x607b417DF51e0E1ed3A12fDb7FC0e8307ED250F3);
        // Ensure the ExchangeRates contract has the standalone feed for RPL;
        exchangerates_i.addAggregator("RPL", 0xADE082c91A6AeCC86fC11704a830e933e1b382eA);
        // Ensure the ExchangeRates contract has the standalone feed for YFI;
        exchangerates_i.addAggregator("YFI", 0x5cdC797acCBf57EE2363Fed9701262Abc87a232e);
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for MAV;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "MAV",
            0x5b131ede5d017511cf5280b9ebf20708af299266a033752b64180c4201363b11
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for ETHBTC;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "ETHBTC",
            0xc96458d393fe9deb7a7d63a0ac41e2898a67a7750dbd166673279e06c868df0a
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for ETC;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "ETC",
            0x7f5cc8d963fc5b3d2ae41fe5685ada89fd4f14b435f8050f28c7fd409f40c2d8
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for COMP;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "COMP",
            0x4a8e42861cabc5ecb50996f92e7cfa2bce3fd0a2423b0c44c9b423fb2bd25478
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for YFI;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "YFI",
            0x425f4b198ab2504936886c1e93511bb6720fbcf2045a4f3c0723bb213846022f
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for MKR;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "MKR",
            0x9375299e31c0deb9c6bc378e6329aab44cb48ec655552a70d4b9050346a30378
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for RPL;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "RPL",
            0x24f94ac0fd8638e3fc41aab2e4df933e63f763351b640bf336a6ec70651c4503
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for XMR;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "XMR",
            0x46b8cc9347f04391764a0361e0b17c3ba394b001e7c304f7650f6376e37c321d
        );

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
            0x978D4b5438D3E4EDf4f03682e5A53b48E56604c5
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0xb16a8B06318C78c274f3BBc5CC5C9191B0d0c1A3
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0xD5FcCd43205CEF11FbaF9b38dF15ADbe1B186869);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_28() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0[0] = address(
            0xAD35498D97f3b1a0B99de42da7Ad81c91156BA77
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0[1] = address(
            0x98d601E04527a0acBB603BaD845D9b7B8840de1c
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0);
    }

    function futuresmarketmanager_addProxiedMarkets_29() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0[0] = address(0x4bF3C1Af0FaA689e3A808e6Ad7a8d89d07BB9EC7);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_55() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0[0] = address(
            0x6172289961007908442a0437891DcD966F368563
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0[1] = address(
            0x9f3be6Be18E8D0613f87c86A0b1875B74f404A11
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0);
    }

    function futuresmarketmanager_addProxiedMarkets_56() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0[0] = address(0xb7059Ed9950f2D9fDc0155fC0D79e63d4441e806);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_82() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0[0] = address(
            0x239847700D9134cEEAEC306DAA40b569CEe1D5a0
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0[1] = address(
            0x926b1148DaFe298ff7Fdc2d01Ae1bC3Fa3b4FAE4
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0);
    }

    function futuresmarketmanager_addProxiedMarkets_83() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_83_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_83_0[0] = address(0x2ea06E73083f1b3314Fa090eaE4a5F70eb058F2e);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_83_0);
    }
}
