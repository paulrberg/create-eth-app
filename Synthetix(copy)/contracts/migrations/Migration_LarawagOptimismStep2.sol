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
contract Migration_LarawagOptimismStep2 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x0Ea666319f4f0eAa7f16711f2fe7F4B159957f48
    PerpsV2MarketState public constant perpsv2marketstatexrpperp_i =
        PerpsV2MarketState(0x0Ea666319f4f0eAa7f16711f2fe7F4B159957f48);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xCF33a35F0f2095ABdD0C81dbde3A1cD37bE0c5cC
    PerpsV2MarketState public constant perpsv2marketstatedotperp_i =
        PerpsV2MarketState(0xCF33a35F0f2095ABdD0C81dbde3A1cD37bE0c5cC);
    // https://explorer.optimism.io/address/0x52cCa59bFa0228F41Ab69558F5f2EE3739323c02
    PerpsV2MarketState public constant perpsv2marketstatetrxperp_i =
        PerpsV2MarketState(0x52cCa59bFa0228F41Ab69558F5f2EE3739323c02);
    // https://explorer.optimism.io/address/0x94a1D572baE06A31C029D4C26e1fA705f54286ef
    PerpsV2MarketState public constant perpsv2marketstateflokiperp_i =
        PerpsV2MarketState(0x94a1D572baE06A31C029D4C26e1fA705f54286ef);
    // https://explorer.optimism.io/address/0x4C35c27fF8F0dD039B4C4F0D670f2D58f6215c9C
    PerpsV2MarketState public constant perpsv2marketstateinjperp_i =
        PerpsV2MarketState(0x4C35c27fF8F0dD039B4C4F0D670f2D58f6215c9C);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](9);
        contracts[0] = address(perpsv2marketstatexrpperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(perpsv2marketstatedotperp_i);
        contracts[5] = address(perpsv2marketstatetrxperp_i);
        contracts[6] = address(perpsv2marketstateflokiperp_i);
        contracts[7] = address(perpsv2marketstateinjperp_i);
        contracts[8] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        perpsv2marketstatexrpperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sXRPPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sXRPPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sXRPPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sXRPPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sXRPPERP", 800000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sXRPPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sXRPPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sXRPPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sXRPPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sXRPPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sXRPPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sXRPPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sXRPPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sXRPPERP", 10000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sXRPPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sXRPPERP", 750000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sXRPPERP", "ocXRPPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sXRPPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sXRPPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sXRPPERP", 1000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sXRPPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sXRPPERP", 2000000000000000);

        perpsv2marketstatedotperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_26();
        futuresmarketmanager_addProxiedMarkets_27();
        perpsv2marketsettings_i.setTakerFee("sDOTPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sDOTPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sDOTPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sDOTPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sDOTPERP", 800000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sDOTPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sDOTPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sDOTPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sDOTPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sDOTPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sDOTPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sDOTPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sDOTPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sDOTPERP", 300000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sDOTPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sDOTPERP", 30000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sDOTPERP", "ocDOTPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sDOTPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sDOTPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sDOTPERP", 1000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sDOTPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sDOTPERP", 2000000000000000);

        perpsv2marketstatetrxperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_51();
        futuresmarketmanager_addProxiedMarkets_52();
        perpsv2marketsettings_i.setTakerFee("sTRXPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sTRXPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sTRXPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sTRXPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sTRXPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sTRXPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sTRXPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sTRXPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sTRXPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sTRXPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sTRXPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sTRXPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sTRXPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sTRXPERP", 15000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sTRXPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sTRXPERP", 1000000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sTRXPERP", "ocTRXPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sTRXPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sTRXPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sTRXPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sTRXPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sTRXPERP", 2400000000000000);

        perpsv2marketstateflokiperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_76();
        futuresmarketmanager_addProxiedMarkets_77();
        perpsv2marketsettings_i.setTakerFee("sFLOKIPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sFLOKIPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sFLOKIPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sFLOKIPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sFLOKIPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sFLOKIPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sFLOKIPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sFLOKIPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sFLOKIPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sFLOKIPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sFLOKIPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sFLOKIPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sFLOKIPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sFLOKIPERP", 10000000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sFLOKIPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sFLOKIPERP", 200000000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sFLOKIPERP", "ocFLOKIPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sFLOKIPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sFLOKIPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sFLOKIPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sFLOKIPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sFLOKIPERP", 2400000000000000);

        perpsv2marketstateinjperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_101();
        futuresmarketmanager_addProxiedMarkets_102();
        perpsv2marketsettings_i.setTakerFee("sINJPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sINJPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sINJPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sINJPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sINJPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sINJPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sINJPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sINJPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sINJPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sINJPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sINJPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sINJPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sINJPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sINJPERP", 200000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sINJPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sINJPERP", 6275000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sINJPERP", "ocINJPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sINJPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sINJPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sINJPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sINJPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sINJPERP", 2400000000000000);

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
            0x7F4B56A8Fe268666d95e64F16A96bBDCfB89DF54
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0x28bDE5C67624B2eF7Fa27C9C9B0678fE3009913e
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0x6110DF298B411a46d6edce72f5CAca9Ad826C1De);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_26() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0[0] = address(
            0x4d178B91a3B16a124d2A90d944dB8C70A334FBdA
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0[1] = address(
            0x5C4fD006f3dC9C6a2259B2fb82CfD500056978ec
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0);
    }

    function futuresmarketmanager_addProxiedMarkets_27() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0[0] = address(0x8B9B5f94aac2316f048025B3cBe442386E85984b);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_51() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0[0] = address(
            0xc254F4A4Bc16218eD30A3D674d8fae3f25B6Af5d
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0[1] = address(
            0xC20e63aB2F1303079a6cC31013534e3989CFC8dc
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0);
    }

    function futuresmarketmanager_addProxiedMarkets_52() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0[0] = address(0x031A448F59111000b96F016c37e9c71e57845096);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_76() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0[0] = address(
            0x3FCC706dd9ab9Ac3DAF6f205AbE26712ddcBbd3E
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0[1] = address(
            0xF52Df12Dd62731a11180403212EE67cb5F4d6345
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0);
    }

    function futuresmarketmanager_addProxiedMarkets_77() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0[0] = address(0x5ed8D0946b59d015f5A60039922b870537d43689);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_101() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_101_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_101_0[0] = address(
            0x0cDFdbF84Ac56D54657d3895602BB2982fD1EFE4
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_101_0[1] = address(
            0x53bAd7c8cE47Fa070e5BB25adea796409E0e8058
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_101_0);
    }

    function futuresmarketmanager_addProxiedMarkets_102() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_102_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_102_0[0] = address(0x852210F0616aC226A486ad3387DBF990e690116A);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_102_0);
    }
}
