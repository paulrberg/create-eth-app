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
contract Migration_DschubbaOptimismStep2 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xf5826f24805c162c696b79ba31ebC6FB8003d475
    PerpsV2MarketState public constant perpsv2marketstateltcperp_i =
        PerpsV2MarketState(0xf5826f24805c162c696b79ba31ebC6FB8003d475);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xAe3D1b55CBFFc11693257FB5Dc41DE32F1E9EC7A
    PerpsV2MarketState public constant perpsv2marketstateadaperp_i =
        PerpsV2MarketState(0xAe3D1b55CBFFc11693257FB5Dc41DE32F1E9EC7A);
    // https://explorer.optimism.io/address/0x71FD2f49f289d75D0C1E108c97Fcb2a4c54Ab424
    PerpsV2MarketState public constant perpsv2marketstatefilperp_i =
        PerpsV2MarketState(0x71FD2f49f289d75D0C1E108c97Fcb2a4c54Ab424);
    // https://explorer.optimism.io/address/0x9f564ffB60945DEc03fB8DdEF491465Dd9b4C9Fb
    PerpsV2MarketState public constant perpsv2marketstategmxperp_i =
        PerpsV2MarketState(0x9f564ffB60945DEc03fB8DdEF491465Dd9b4C9Fb);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](8);
        contracts[0] = address(perpsv2marketstateltcperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(perpsv2marketstateadaperp_i);
        contracts[5] = address(perpsv2marketstatefilperp_i);
        contracts[6] = address(perpsv2marketstategmxperp_i);
        contracts[7] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        perpsv2marketstateltcperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sLTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sLTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sLTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sLTCPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sLTCPERP", 800000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sLTCPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sLTCPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sLTCPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sLTCPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sLTCPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sLTCPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sLTCPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sLTCPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sLTCPERP", 45000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sLTCPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sLTCPERP", 1650000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sLTCPERP", "ocLTCPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sLTCPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sLTCPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sLTCPERP", 1000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sLTCPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sLTCPERP", 2000000000000000);
        perpsv2marketstateadaperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_26();
        futuresmarketmanager_addProxiedMarkets_27();
        perpsv2marketsettings_i.setTakerFee("sADAPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sADAPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sADAPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sADAPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sADAPERP", 800000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sADAPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sADAPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sADAPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sADAPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sADAPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sADAPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sADAPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sADAPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sADAPERP", 7500000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sADAPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sADAPERP", 290000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sADAPERP", "ocADAPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sADAPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sADAPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sADAPERP", 1000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sADAPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sADAPERP", 2000000000000000);
        perpsv2marketstatefilperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_51();
        futuresmarketmanager_addProxiedMarkets_52();
        perpsv2marketsettings_i.setTakerFee("sFILPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sFILPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sFILPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sFILPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sFILPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sFILPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sFILPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sFILPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sFILPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sFILPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sFILPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sFILPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sFILPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sFILPERP", 225000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sFILPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sFILPERP", 11300000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sFILPERP", "ocFILPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sFILPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sFILPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sFILPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sFILPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sFILPERP", 2400000000000000);
        perpsv2marketstategmxperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_76();
        futuresmarketmanager_addProxiedMarkets_77();
        perpsv2marketsettings_i.setTakerFee("sGMXPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sGMXPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sGMXPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sGMXPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sGMXPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sGMXPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sGMXPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sGMXPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sGMXPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sGMXPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sGMXPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sGMXPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sGMXPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sGMXPERP", 7000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sGMXPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sGMXPERP", 75000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sGMXPERP", "ocGMXPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sGMXPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sGMXPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sGMXPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sGMXPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sGMXPERP", 2400000000000000);

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
            0x7733b88Bf971b9c77cC3C1B64a2Ef4fC06b08017
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0x869d17fd46F76f0e439bec2992f2D45B40253f88
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0xB25529266D9677E9171BEaf333a0deA506c5F99A);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_26() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0[0] = address(
            0x59798C3ec713213C274Bd8827642DAF2A798181e
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0[1] = address(
            0x18970122d688B97023Edc44DA27A51230dC6799c
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0);
    }

    function futuresmarketmanager_addProxiedMarkets_27() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0[0] = address(0xF9DD29D2Fd9B38Cd90E390C797F1B7E0523f43A9);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_51() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0[0] = address(
            0x6F910A87565c581e101FBba25fE5B2570181794C
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0[1] = address(
            0x530F4A84e99eF78A5C2A4E64Cd5d126b40c99242
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0);
    }

    function futuresmarketmanager_addProxiedMarkets_52() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0[0] = address(0x2C5E2148bF3409659967FE3684fd999A76171235);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_76() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0[0] = address(
            0x9053e51047BA7f0141f3d1F23AC7Ec6861bf9Fba
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0[1] = address(
            0x3382A15bd1956e908a1EF2D027F92b2Bfc84558c
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0);
    }

    function futuresmarketmanager_addProxiedMarkets_77() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0[0] = address(0x33d4613639603c845e61A02cd3D2A78BE7d513dc);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0);
    }
}
