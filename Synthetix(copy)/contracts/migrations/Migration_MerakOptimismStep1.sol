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
import "../FuturesMarketManager.sol";
import "../PerpsV2MarketSettings.sol";
import "../ExchangeRates.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_MerakOptimismStep1 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x777A913412D576532120ac1d266d4C908e584DB2
    PerpsV2MarketState public constant perpsv2marketstatestethperp_i =
        PerpsV2MarketState(0x777A913412D576532120ac1d266d4C908e584DB2);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2
    ExchangeRates public constant exchangerates_i = ExchangeRates(0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](6);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatestethperp_i);
        contracts[2] = address(perpsv2exchangerate_i);
        contracts[3] = address(futuresmarketmanager_i);
        contracts[4] = address(perpsv2marketsettings_i);
        contracts[5] = address(exchangerates_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Add migration contract permission to pause
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);

        perpsv2marketstatestethperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_42();
        futuresmarketmanager_addProxiedMarkets_43();
        perpsv2marketsettings_i.setTakerFee("sSTETHPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sSTETHPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sSTETHPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sSTETHPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sSTETHPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sSTETHPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sSTETHPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sSTETHPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sSTETHPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sSTETHPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sSTETHPERP", 4);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sSTETHPERP", 60);
        perpsv2marketsettings_i.setMaxLeverage("sSTETHPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sSTETHPERP", 200000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sSTETHPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sSTETHPERP", 6275000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sSTETHPERP", "ocSTETHPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sSTETHPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sSTETHPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sSTETHPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sSTETHPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sSTETHPERP", 2400000000000000);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sSTETHPERP", 80);
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("ocSTETHPERP", 80);
        // Ensure the ExchangeRates contract has the standalone feed for STETH;
        exchangerates_i.addAggregator("STETH", 0x41878779a388585509657CE5Fb95a80050502186);
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for STETH;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "STETH",
            0x846ae1bdb6300b817cee5fdee2a6da192775030db5615b94a465f53bd40850b5
        );

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

    function perpsv2exchangerate_addAssociatedContracts_42() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_42_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_42_0[0] = address(
            0x9B0071d4Ee4a078dbdD5100799D8eA700A6dA709
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_42_0[1] = address(
            0x02e85b8dD638a5FabD9D67802A92721D2e18fc6d
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_42_0);
    }

    function futuresmarketmanager_addProxiedMarkets_43() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_43_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_43_0[0] = address(0xD91Db82733987513286B81e7115091d96730b62A);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_43_0);
    }
}
