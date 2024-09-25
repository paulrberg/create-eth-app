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
import "../FuturesMarketManager.sol";
import "../AddressResolver.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_CaphOptimismStep1 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C
    AddressResolver public constant addressresolver_i = AddressResolver(0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    address public constant new_FuturesMarketManager_contract = 0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463;
    // https://explorer.optimism.io/address/0x58e6227510F83d3F45B339F2f7A05a699fDEE6D4
    address public constant new_PerpsV2MarketData_contract = 0x58e6227510F83d3F45B339F2f7A05a699fDEE6D4;
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    address public constant new_PerpsV2ExchangeRate_contract = 0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04;
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    address public constant new_PerpsV2MarketSettings_contract = 0x649F44CAC3276557D03223Dbf6395Af65b11c11c;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](2);
        contracts[0] = address(futuresmarketmanager_i);
        contracts[1] = address(addressresolver_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        futuresmarketmanager_addMarkets_0();
        futuresmarketmanager_addProxiedMarkets_1();
        futuresmarketmanager_addProxiedMarkets_2();
        futuresmarketmanager_addProxiedMarkets_3();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_4();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_5();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 1;
        addressresolver_rebuildCaches_6();

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

    function futuresmarketmanager_addMarkets_0() internal {
        address[] memory futuresmarketmanager_addMarkets_marketsToAdd_0_0 = new address[](18);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[0] = address(0xEe8804d8Ad10b0C3aD1Bd57AC3737242aD24bB95);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[1] = address(0xf86048DFf23cF130107dfB4e6386f574231a5C65);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[2] = address(0x1228c7D8BBc5bC53DB181bD7B1fcE765aa83bF8A);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[3] = address(0xcF853f7f8F78B2B801095b66F8ba9c5f04dB1640);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[4] = address(0x4ff54624D5FB61C34c634c3314Ed3BfE4dBB665a);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[5] = address(0x001b7876F567f0b3A639332Ed1e363839c6d85e2);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[6] = address(0x5Af0072617F7f2AEB0e314e2faD1DE0231Ba97cD);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[7] = address(0xbCB2D435045E16B059b2130b28BE70b5cA47bFE5);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[8] = address(0x4434f56ddBdE28fab08C4AE71970a06B300F8881);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[9] = address(0xb147C69BEe211F57290a6cde9d1BAbfD0DCF3Ea3);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[10] = address(0xad44873632840144fFC97b2D1de716f6E2cF0366);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[11] = address(0xFe00395ec846240dc693e92AB2Dd720F94765Aa3);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[12] = address(0x10305C1854d6DB8A1060dF60bDF8A8B2981249Cf);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[13] = address(0x4Aa0dabd22BC0894975324Bec293443c8538bD08);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[14] = address(0x9F1C2f0071Bc3b31447AEda9fA3A68d651eB4632);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[15] = address(0x3Ed04CEfF4c91872F19b1da35740C0Be9CA21558);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[16] = address(0x9f231dBE53D460f359B2B8CC47574493caA5B7Bf);
        futuresmarketmanager_addMarkets_marketsToAdd_0_0[17] = address(0xd325B17d5C9C3f2B6853A760afCF81945b0184d3);
        futuresmarketmanager_i.addMarkets(futuresmarketmanager_addMarkets_marketsToAdd_0_0);
    }

    function futuresmarketmanager_addProxiedMarkets_1() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0 = new address[](10);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[0] = address(0x2B3bb4c683BFc5239B029131EEf3B1d214478d93);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[1] = address(0x59b007E9ea8F89b069c43F8f45834d30853e3699);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[2] = address(0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[3] = address(0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[4] = address(0xc203A12F298CE73E44F7d45A4f59a43DBfFe204D);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[5] = address(0x5374761526175B59f1E583246E20639909E189cE);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[6] = address(0x4308427C463CAEAaB50FFf98a9deC569C31E4E87);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[7] = address(0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[8] = address(0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0[9] = address(0x139F94E4f0e1101c1464a321CBA815c34d58B5D9);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_1_0);
    }

    function futuresmarketmanager_addProxiedMarkets_2() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0 = new address[](10);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[0] = address(0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[1] = address(0x442b69937a0daf9D46439a71567fABE6Cb69FBaf);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[2] = address(0x98cCbC721cc05E28a125943D69039B39BE6A21e9);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[3] = address(0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[4] = address(0xdcB8438c979fA030581314e5A5Df42bbFEd744a0);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[5] = address(0x87AE62c5720DAB812BDacba66cc24839440048d1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[6] = address(0xbB16C7B3244DFA1a6BF83Fcce3EE4560837763CD);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[7] = address(0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[8] = address(0x27665271210aCff4Fab08AD9Bb657E91866471F0);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0[9] = address(0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_2_0);
    }

    function futuresmarketmanager_addProxiedMarkets_3() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_3_0 = new address[](4);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_3_0[0] = address(0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_3_0[1] = address(0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_3_0[2] = address(0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_3_0[3] = address(0x509072A5aE4a87AC89Fc8D64D94aDCb44Bd4b88e);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_3_0);
    }

    function addressresolver_importAddresses_4() internal {
        bytes32[] memory addressresolver_importAddresses_names_4_0 = new bytes32[](4);
        addressresolver_importAddresses_names_4_0[0] = bytes32("PerpsV2MarketData");
        addressresolver_importAddresses_names_4_0[1] = bytes32("FuturesMarketManager");
        addressresolver_importAddresses_names_4_0[2] = bytes32("PerpsV2MarketSettings");
        addressresolver_importAddresses_names_4_0[3] = bytes32("PerpsV2ExchangeRate");
        address[] memory addressresolver_importAddresses_destinations_4_1 = new address[](4);
        addressresolver_importAddresses_destinations_4_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_importAddresses_destinations_4_1[1] = address(new_FuturesMarketManager_contract);
        addressresolver_importAddresses_destinations_4_1[2] = address(new_PerpsV2MarketSettings_contract);
        addressresolver_importAddresses_destinations_4_1[3] = address(new_PerpsV2ExchangeRate_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_4_0,
            addressresolver_importAddresses_destinations_4_1
        );
    }

    function addressresolver_importAddresses_5() internal {
        bytes32[] memory addressresolver_importAddresses_names_5_0 = new bytes32[](4);
        addressresolver_importAddresses_names_5_0[0] = bytes32("FuturesMarketManager");
        addressresolver_importAddresses_names_5_0[1] = bytes32("PerpsV2MarketData");
        addressresolver_importAddresses_names_5_0[2] = bytes32("PerpsV2ExchangeRate");
        addressresolver_importAddresses_names_5_0[3] = bytes32("PerpsV2MarketSettings");
        address[] memory addressresolver_importAddresses_destinations_5_1 = new address[](4);
        addressresolver_importAddresses_destinations_5_1[0] = address(new_FuturesMarketManager_contract);
        addressresolver_importAddresses_destinations_5_1[1] = address(new_PerpsV2MarketData_contract);
        addressresolver_importAddresses_destinations_5_1[2] = address(new_PerpsV2ExchangeRate_contract);
        addressresolver_importAddresses_destinations_5_1[3] = address(new_PerpsV2MarketSettings_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_5_0,
            addressresolver_importAddresses_destinations_5_1
        );
    }

    function addressresolver_rebuildCaches_6() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_6_0 = new MixinResolver[](10);
        addressresolver_rebuildCaches_destinations_6_0[0] = MixinResolver(0xf9FE3607e6d19D8dC690DD976061a91D4A0db30B);
        addressresolver_rebuildCaches_destinations_6_0[1] = MixinResolver(0x17628A557d1Fc88D1c35989dcBAC3f3e275E2d2B);
        addressresolver_rebuildCaches_destinations_6_0[2] = MixinResolver(0xDfA2d3a0d32F870D87f8A0d7AA6b9CdEB7bc5AdB);
        addressresolver_rebuildCaches_destinations_6_0[3] = MixinResolver(0xe9dceA0136FEFC76c4E639Ec60CCE70482E2aCF7);
        addressresolver_rebuildCaches_destinations_6_0[4] = MixinResolver(0x421DEF861D623F7123dfE0878D86E9576cbb3975);
        addressresolver_rebuildCaches_destinations_6_0[5] = MixinResolver(0xdEdb0b04AFF1525bb4B6167F00e61601690c1fF2);
        addressresolver_rebuildCaches_destinations_6_0[6] = MixinResolver(0x34c2360ffe5D21542f76e991FFD104f281D4B3fb);
        addressresolver_rebuildCaches_destinations_6_0[7] = MixinResolver(new_PerpsV2MarketSettings_contract);
        addressresolver_rebuildCaches_destinations_6_0[8] = MixinResolver(new_FuturesMarketManager_contract);
        addressresolver_rebuildCaches_destinations_6_0[9] = MixinResolver(new_PerpsV2ExchangeRate_contract);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_6_0);
    }
}
