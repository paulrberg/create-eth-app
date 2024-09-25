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
contract Migration_DschubbaOptimismStep3 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x91a4F7125A6F7ec14c41d39F0AC681e8e387DA1C
    PerpsV2MarketState public constant perpsv2marketstateaptperp_i =
        PerpsV2MarketState(0x91a4F7125A6F7ec14c41d39F0AC681e8e387DA1C);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xc2c71156d9DDe42F412e83a3E169283Cd70F3E9D
    PerpsV2MarketState public constant perpsv2marketstateshibperp_i =
        PerpsV2MarketState(0xc2c71156d9DDe42F412e83a3E169283Cd70F3E9D);
    // https://explorer.optimism.io/address/0xa664fCA1879C9cA2E6CFeD49C3C855352016E4C5
    PerpsV2MarketState public constant perpsv2marketstatebchperp_i =
        PerpsV2MarketState(0xa664fCA1879C9cA2E6CFeD49C3C855352016E4C5);
    // https://explorer.optimism.io/address/0x5A155c378d66d8EBa2262e744738a76d913E5945
    PerpsV2MarketState public constant perpsv2marketstatecrvperp_i =
        PerpsV2MarketState(0x5A155c378d66d8EBa2262e744738a76d913E5945);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](8);
        contracts[0] = address(perpsv2marketstateaptperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(perpsv2marketstateshibperp_i);
        contracts[5] = address(perpsv2marketstatebchperp_i);
        contracts[6] = address(perpsv2marketstatecrvperp_i);
        contracts[7] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        perpsv2marketstateaptperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sAPTPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sAPTPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sAPTPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sAPTPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sAPTPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sAPTPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sAPTPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sAPTPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sAPTPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sAPTPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sAPTPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sAPTPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sAPTPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sAPTPERP", 125000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sAPTPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sAPTPERP", 8100000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sAPTPERP", "ocAPTPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sAPTPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sAPTPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sAPTPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sAPTPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sAPTPERP", 2400000000000000);
        perpsv2marketstateshibperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_26();
        futuresmarketmanager_addProxiedMarkets_27();
        perpsv2marketsettings_i.setTakerFee("sSHIBPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sSHIBPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sSHIBPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sSHIBPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sSHIBPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sSHIBPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sSHIBPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sSHIBPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sSHIBPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sSHIBPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sSHIBPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sSHIBPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sSHIBPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sSHIBPERP", 75000000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sSHIBPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sSHIBPERP", 6370000000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sSHIBPERP", "ocSHIBPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sSHIBPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sSHIBPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sSHIBPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sSHIBPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sSHIBPERP", 2400000000000000);
        perpsv2marketstatebchperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_51();
        futuresmarketmanager_addProxiedMarkets_52();
        perpsv2marketsettings_i.setTakerFee("sBCHPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sBCHPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sBCHPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sBCHPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sBCHPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sBCHPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sBCHPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sBCHPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sBCHPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sBCHPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sBCHPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sBCHPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sBCHPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sBCHPERP", 6000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sBCHPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sBCHPERP", 340000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sBCHPERP", "ocBCHPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sBCHPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sBCHPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sBCHPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sBCHPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sBCHPERP", 2400000000000000);
        perpsv2marketstatecrvperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_76();
        futuresmarketmanager_addProxiedMarkets_77();
        perpsv2marketsettings_i.setTakerFee("sCRVPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sCRVPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sCRVPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sCRVPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sCRVPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sCRVPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sCRVPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sCRVPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sCRVPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sCRVPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sCRVPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sCRVPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sCRVPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sCRVPERP", 727000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sCRVPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sCRVPERP", 50000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sCRVPERP", "ocCRVPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sCRVPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sCRVPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sCRVPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sCRVPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sCRVPERP", 2400000000000000);

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
            0xD681CF2419bb3F85732412164b6542843E9A64A5
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0xfD9E252Cd1Fa456AaD9fC592608e86FaBcF40F77
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0x9615B6BfFf240c44D3E33d0cd9A11f563a2e8D8B);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_26() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0[0] = address(
            0xf037641c69c1156530c182B970045EBA6289553b
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0[1] = address(
            0x62137897f2b09c588327D80CBbFB9C6018c352Ef
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_26_0);
    }

    function futuresmarketmanager_addProxiedMarkets_27() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0[0] = address(0x69F5F465a46f324Fb7bf3fD7c0D5c00f7165C7Ea);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_27_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_51() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0[0] = address(
            0x9F77aF45F13738Be8D3bb772A86310f4e452aFd4
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0[1] = address(
            0xA14849ad93999d8B184A1d61FbA7B4fFbD24f96C
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_51_0);
    }

    function futuresmarketmanager_addProxiedMarkets_52() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0[0] = address(0x96690aAe7CB7c4A9b5Be5695E94d72827DeCC33f);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_52_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_76() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0[0] = address(
            0x9E3c1F1f5868701A4D8CaA58D61dF2F74aeFe926
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0[1] = address(
            0x53bD23EEd35C00EF09D4Ebd8F71005b0DCC97E1a
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_76_0);
    }

    function futuresmarketmanager_addProxiedMarkets_77() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0[0] = address(0xD5fBf7136B86021eF9d0BE5d798f948DcE9C0deA);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_77_0);
    }
}
