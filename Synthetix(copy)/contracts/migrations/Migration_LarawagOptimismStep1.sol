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
contract Migration_LarawagOptimismStep1 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x2365D3e91E585c974c28a5B82d6AA266F68a44Ad
    PerpsV2MarketState public constant perpsv2marketstatepepeperp_i =
        PerpsV2MarketState(0x2365D3e91E585c974c28a5B82d6AA266F68a44Ad);
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
    // https://explorer.optimism.io/address/0x2cCaf0500142F8E563fF361C3b34AbEe16B6205d
    PerpsV2MarketState public constant perpsv2marketstatesuiperp_i =
        PerpsV2MarketState(0x2cCaf0500142F8E563fF361C3b34AbEe16B6205d);
    // https://explorer.optimism.io/address/0x6aCC3519d10E46E5a228615c9d4B57CC0113A212
    PerpsV2MarketState public constant perpsv2marketstateblurperp_i =
        PerpsV2MarketState(0x6aCC3519d10E46E5a228615c9d4B57CC0113A212);
    // https://explorer.optimism.io/address/0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2
    ExchangeRates public constant exchangerates_i = ExchangeRates(0x913bd76F7E1572CC8278CeF2D6b06e2140ca9Ce2);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](8);
        contracts[0] = address(perpsv2marketstatepepeperp_i);
        contracts[1] = address(perpsv2exchangerate_i);
        contracts[2] = address(futuresmarketmanager_i);
        contracts[3] = address(perpsv2marketsettings_i);
        contracts[4] = address(systemstatus_i);
        contracts[5] = address(perpsv2marketstatesuiperp_i);
        contracts[6] = address(perpsv2marketstateblurperp_i);
        contracts[7] = address(exchangerates_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Add migration contract permission to pause
        systemstatus_i.updateAccessControl("Futures", address(this), true, false);

        // Preemptive pause all new marktes
        // SIP-2014
        systemstatus_i.suspendFuturesMarket("sPEPEPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocPEPEPERP", 80);
        systemstatus_i.suspendFuturesMarket("sSUIPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocSUIPERP", 80);
        systemstatus_i.suspendFuturesMarket("sBLURPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocBLURPERP", 80);

        // SIP-2015
        systemstatus_i.suspendFuturesMarket("sXRPPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocXRPPERP", 80);
        systemstatus_i.suspendFuturesMarket("sDOTPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocDOTPERP", 80);
        systemstatus_i.suspendFuturesMarket("sTRXPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocTRXPERP", 80);
        systemstatus_i.suspendFuturesMarket("sFLOKIPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocFLOKIPERP", 80);
        systemstatus_i.suspendFuturesMarket("sINJPERP", 80);
        systemstatus_i.suspendFuturesMarket("ocINJPERP", 80);

        perpsv2marketstatepepeperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_1();
        futuresmarketmanager_addProxiedMarkets_2();
        perpsv2marketsettings_i.setTakerFee("sPEPEPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sPEPEPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sPEPEPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sPEPEPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sPEPEPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sPEPEPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sPEPEPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sPEPEPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sPEPEPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sPEPEPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sPEPEPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sPEPEPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sPEPEPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sPEPEPERP", 600000000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sPEPEPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sPEPEPERP", 37000000000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sPEPEPERP", "ocPEPEPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sPEPEPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sPEPEPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sPEPEPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sPEPEPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sPEPEPERP", 2400000000000000);

        perpsv2marketstatesuiperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_28();
        futuresmarketmanager_addProxiedMarkets_29();
        perpsv2marketsettings_i.setTakerFee("sSUIPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sSUIPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sSUIPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sSUIPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sSUIPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sSUIPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sSUIPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sSUIPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sSUIPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sSUIPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sSUIPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sSUIPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sSUIPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sSUIPERP", 1000000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sSUIPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sSUIPERP", 60000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sSUIPERP", "ocSUIPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sSUIPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sSUIPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sSUIPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sSUIPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sSUIPERP", 2400000000000000);

        perpsv2marketstateblurperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_55();
        futuresmarketmanager_addProxiedMarkets_56();
        perpsv2marketsettings_i.setTakerFee("sBLURPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFee("sBLURPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeDelayedOrder("sBLURPERP", 300000000000000000);
        perpsv2marketsettings_i.setMakerFeeDelayedOrder("sBLURPERP", 300000000000000000);
        perpsv2marketsettings_i.setTakerFeeOffchainDelayedOrder("sBLURPERP", 1000000000000000);
        perpsv2marketsettings_i.setMakerFeeOffchainDelayedOrder("sBLURPERP", 200000000000000);
        perpsv2marketsettings_i.setNextPriceConfirmWindow("sBLURPERP", 2);
        perpsv2marketsettings_i.setDelayedOrderConfirmWindow("sBLURPERP", 120);
        perpsv2marketsettings_i.setMinDelayTimeDelta("sBLURPERP", 60);
        perpsv2marketsettings_i.setMaxDelayTimeDelta("sBLURPERP", 6000);
        perpsv2marketsettings_i.setOffchainDelayedOrderMinAge("sBLURPERP", 15);
        perpsv2marketsettings_i.setOffchainDelayedOrderMaxAge("sBLURPERP", 120);
        perpsv2marketsettings_i.setMaxLeverage("sBLURPERP", 27500000000000000000);
        perpsv2marketsettings_i.setMaxMarketValue("sBLURPERP", 1750000000000000000000000);
        perpsv2marketsettings_i.setMaxFundingVelocity("sBLURPERP", 9000000000000000000);
        perpsv2marketsettings_i.setSkewScale("sBLURPERP", 17000000000000000000000000);
        perpsv2marketsettings_i.setOffchainMarketKey("sBLURPERP", "ocBLURPERP");
        perpsv2marketsettings_i.setOffchainPriceDivergence("sBLURPERP", 20000000000000000);
        perpsv2marketsettings_i.setLiquidationPremiumMultiplier("sBLURPERP", 3000000000000000000);
        perpsv2marketsettings_i.setMaxLiquidationDelta("sBLURPERP", 1200000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sBLURPERP", 12500000000000000);
        perpsv2marketsettings_i.setMaxPD("sBLURPERP", 2400000000000000);

        // Ensure the ExchangeRates contract has the standalone feed for PEPE;
        exchangerates_i.addAggregator("PEPE", 0x64Ecf089a6594Be781908D5a26FC8fA6CB08A2C7);
        // Ensure the ExchangeRates contract has the standalone feed for SUI;
        exchangerates_i.addAggregator("SUI", 0xEaf1a9fe242aa9928faedc6CE7e09aD4875f7133);
        // Ensure the ExchangeRates contract has the standalone feed for BLUR;
        exchangerates_i.addAggregator("BLUR", 0x517C2557c29F7c53Aa5F97a1DAE465E0d5C174AA);
        // Ensure the ExchangeRates contract has the standalone feed for XRP;
        exchangerates_i.addAggregator("XRP", 0x8788F0DBDa7678244Ac7FF09d963d7696D56A8a0);
        // Ensure the ExchangeRates contract has the standalone feed for DOT;
        exchangerates_i.addAggregator("DOT", 0x28e67BAeEB5dE7A788f3Dde6CF6ee491369Bb3Fa);
        // Ensure the ExchangeRates contract has the standalone feed for TRX;
        exchangerates_i.addAggregator("TRX", 0x0E09921cf7801A5aD47B892C8727593275625a9f);
        // Ensure the ExchangeRates contract has the standalone feed for FLOKI;
        exchangerates_i.addAggregator("FLOKI", 0x34E0E85CeEc6be6146c4f0115769a29a9539222e);
        // Ensure the ExchangeRates contract has the standalone feed for INJ;
        exchangerates_i.addAggregator("INJ", 0x90CC16F5493894eff84a5Fedd1dcE297d174fEEf);
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for PEPE;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "PEPE",
            0xd69731a2e74ac1ce884fc3890f7ee324b6deb66147055249568869ed700882e4
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for SUI;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "SUI",
            0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for BLUR;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "BLUR",
            0x856aac602516addee497edf6f50d39e8c95ae5fb0da1ed434a8c2ab9c3e877e9
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for XRP;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "XRP",
            0xec5d399846a9209f3fe5881d70aae9268c94339ff9817e8d18ff19fa05eea1c8
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for DOT;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "DOT",
            0xca3eed9b267293f6595901c734c7525ce8ef49adafe8284606ceb307afa2ca5b
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for TRX;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "TRX",
            0x67aed5a24fdad045475e7195c98a98aea119c763f272d4523f5bac93a4f33c2b
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for FLOKI;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "FLOKI",
            0x6b1381ce7e874dc5410b197ac8348162c0dd6c0d4c9cd6322672d6c2b1d58293
        );
        // Ensure the PerpsV2ExchangeRate contract has the off-chain feed Id for INJ;
        perpsv2exchangerate_i.setOffchainPriceFeedId(
            "INJ",
            0x7a5bc1d2b56ad029048cd63964b3ad2776eadf812edc1a43a31406cb54bff592
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

    function perpsv2exchangerate_addAssociatedContracts_1() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[0] = address(
            0x41aE759b8e75f4EE544cD08B4369e5F4719561FE
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0[1] = address(
            0xe9e46a7323d54af1550B931c8bD6F8615f079379
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0x3D3f34416f60f77A0a6cC8e32abe45D32A7497cb);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_28() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0[0] = address(
            0x700EDD66fB75516427C793f5Fe376f6fe1aCc932
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0[1] = address(
            0xA2C0843c8cb9f29Fa40fc0ffd2B4995A0f05C15c
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_28_0);
    }

    function futuresmarketmanager_addProxiedMarkets_29() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0[0] = address(0x09F9d7aaa6Bef9598c3b676c0E19C9786Aa566a8);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_29_0);
    }

    function perpsv2exchangerate_addAssociatedContracts_55() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0[0] = address(
            0xFf82e4012816CC01093565C6d2EE2Af83f3cb3Ae
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0[1] = address(
            0x2214cD24c13D7B36432C66e73984Bc44D479CD51
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_55_0);
    }

    function futuresmarketmanager_addProxiedMarkets_56() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0[0] = address(0xa1Ace9ce6862e865937939005b1a6c5aC938A11F);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_56_0);
    }
}
