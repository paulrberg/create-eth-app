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

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_AnkaaOptimismStep2 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xf963a0fc0BFc38FEfE08C6062f2AD9A11AfFDEeb
    PerpsV2MarketState public constant perpsv2marketstatemkrperp_i =
        PerpsV2MarketState(0xf963a0fc0BFc38FEfE08C6062f2AD9A11AfFDEeb);
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
    // https://explorer.optimism.io/address/0x2107A107D1043b2c442b8de40d6696C29bD2c5b8
    PerpsV2MarketState public constant perpsv2marketstateyfiperp_i =
        PerpsV2MarketState(0x2107A107D1043b2c442b8de40d6696C29bD2c5b8);
    // https://explorer.optimism.io/address/0xB241aF12256998A0051b93e02027e73CA7E5388d
    PerpsV2MarketState public constant perpsv2marketstatemavperp_i =
        PerpsV2MarketState(0xB241aF12256998A0051b93e02027e73CA7E5388d);
    // https://explorer.optimism.io/address/0xf606E99D6F6a003623eA5764dA119BAEcB2e8C99
    PerpsV2MarketState public constant perpsv2marketstaterplperp_i =
        PerpsV2MarketState(0xf606E99D6F6a003623eA5764dA119BAEcB2e8C99);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](8);
        contracts[0] = address(perpsv2marketstatemkrperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(systemstatus_i);
        contracts[5] = address(perpsv2marketstateyfiperp_i);
        contracts[6] = address(perpsv2marketstatemavperp_i);
        contracts[7] = address(perpsv2marketstaterplperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Add migration contract permission to pause
        systemstatus_i.updateAccessControl("Futures", address(this), true, false);

        perpsv2marketstatemkrperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sMKRPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sMKRPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sMKRPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sMKRPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sMKRPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sMKRPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sMKRPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sMKRPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sMKRPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sMKRPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sMKRPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sMKRPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sMKRPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sMKRPERP", 750000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sMKRPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sMKRPERP", 60000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sMKRPERP", "ocMKRPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sMKRPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sMKRPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sMKRPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sMKRPERP", 15000000000000000);
        perpsv2marketsettings_i.setMaxPD("sMKRPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sMKRPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocMKRPERP", 80);
        perpsv2marketstateyfiperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_28();
        futuresmarketmanager_addProxiedMarkets_29();
        perpsv2marketsettings_i.setTakerFee("sYFIPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sYFIPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sYFIPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sYFIPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sYFIPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sYFIPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sYFIPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sYFIPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sYFIPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sYFIPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sYFIPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sYFIPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sYFIPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sYFIPERP", 75000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sYFIPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sYFIPERP", 2500000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sYFIPERP", "ocYFIPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sYFIPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sYFIPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sYFIPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sYFIPERP", 15000000000000000);
        perpsv2marketsettings_i.setMaxPD("sYFIPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sYFIPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocYFIPERP", 80);
        perpsv2marketstatemavperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_55();
        futuresmarketmanager_addProxiedMarkets_56();
        perpsv2marketsettings_i.setTakerFee("sMAVPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sMAVPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sMAVPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sMAVPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sMAVPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sMAVPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sMAVPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sMAVPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sMAVPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sMAVPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sMAVPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sMAVPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sMAVPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sMAVPERP", 500000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sMAVPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sMAVPERP", 21000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sMAVPERP", "ocMAVPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sMAVPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sMAVPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sMAVPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sMAVPERP", 15000000000000000);
        perpsv2marketsettings_i.setMaxPD("sMAVPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sMAVPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocMAVPERP", 80);
        perpsv2marketstaterplperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_82();
        futuresmarketmanager_addProxiedMarkets_83();
        perpsv2marketsettings_i.setTakerFee("sRPLPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sRPLPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sRPLPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sRPLPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sRPLPERP", 1500000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sRPLPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sRPLPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sRPLPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sRPLPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sRPLPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sRPLPERP", 2);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sRPLPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sRPLPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sRPLPERP", 3000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sRPLPERP", 27000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sRPLPERP", 17500000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sRPLPERP", "ocRPLPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sRPLPERP", 25000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sRPLPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sRPLPERP", 1700000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sRPLPERP", 15000000000000000);
        perpsv2marketsettings_i.setMaxPD("sRPLPERP", 3400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sRPLPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocRPLPERP", 80);
        // Remove permission to migration contract
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
            0xDEbC936c5aDfd1331E5fa4AE76DB7197283342d0
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0xE0d1A14EBC3bc4460fEeB67A45C8198063cCC7c7
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0xf7d9Bd13F877171f6C7f93F71bdf8e380335dc12);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_28() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0[0] = address(
            0xf7AF14838789093ccD01c67cF9Bc5f602501cEd0
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0[1] = address(
            0x7aF6Be46f83d25902cfa49c9e16BEc54893f25cB
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0);
    }

    function futuresmarketmanager_addProxiedMarkets_29() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0[0] = address(0x6940e7C6125a177b052C662189bb27692E88E9Cb);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_55() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0[0] = address(
            0x6A5A1E32216377FC03bFFdC9B33fe29c2f14Ec84
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0[1] = address(
            0xFc6895ff4756985BCa9df2AABB5f31651C591Bef
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0);
    }

    function futuresmarketmanager_addProxiedMarkets_56() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0[0] = address(0x572F816F21F56D47e4c4fA577837bd3f58088676);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_82() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0[0] = address(
            0xc9c64cF6D1CE4b41D087F08EdAa9De23262f1EdA
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0[1] = address(
            0xF0671cF8a1a0b3308e84852308F9624B9eC2e28f
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_82_0);
    }

    function futuresmarketmanager_addProxiedMarkets_83() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_83_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_83_0[0] = address(0xfAD0835dAD2985b25ddab17eace356237589E5C7);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_83_0);
    }
}
