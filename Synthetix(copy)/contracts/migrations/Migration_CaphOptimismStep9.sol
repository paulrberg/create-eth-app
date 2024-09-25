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
import "../ProxyPerpsV2.sol";
import "../FuturesMarketManager.sol";
import "../PerpsV2MarketSettings.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_CaphOptimismStep9 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x82f962aF60e6627d3ea5Db5Fd7e1a57f7E1Ef2B8
    PerpsV2MarketState public constant perpsv2marketstatematicperp_i =
        PerpsV2MarketState(0x82f962aF60e6627d3ea5Db5Fd7e1a57f7E1Ef2B8);
    // https://explorer.optimism.io/address/0xfC99d08D8ff69e31095E7372620369Fa92c82960
    PerpsV2MarketState public constant perpsv2marketstatematicperplegacy_i =
        PerpsV2MarketState(0xfC99d08D8ff69e31095E7372620369Fa92c82960);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042
    ProxyPerpsV2 public constant perpsv2proxymaticperp_i = ProxyPerpsV2(0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x0A0A22189c8732cA089D6fB6709e65140a446a41
    PerpsV2MarketState public constant perpsv2marketstatedogeperp_i =
        PerpsV2MarketState(0x0A0A22189c8732cA089D6fB6709e65140a446a41);
    // https://explorer.optimism.io/address/0xd6fe35B896FaE8b22AA6E47bE2752CF87eB1FcaC
    PerpsV2MarketState public constant perpsv2marketstatedogeperplegacy_i =
        PerpsV2MarketState(0xd6fe35B896FaE8b22AA6E47bE2752CF87eB1FcaC);
    // https://explorer.optimism.io/address/0x98cCbC721cc05E28a125943D69039B39BE6A21e9
    ProxyPerpsV2 public constant perpsv2proxydogeperp_i = ProxyPerpsV2(0x98cCbC721cc05E28a125943D69039B39BE6A21e9);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatematicperp_i);
        contracts[2] = address(perpsv2marketstatematicperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxymaticperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstatedogeperp_i);
        contracts[8] = address(perpsv2marketstatedogeperplegacy_i);
        contracts[9] = address(perpsv2proxydogeperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstatematicperp_i.linkOrInitializeState();
        perpsv2marketstatematicperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxymaticperp_i.addRoute(0xa126d601, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x5c8011c3, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x2af64bd3, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, true);
        perpsv2proxymaticperp_i.addRoute(0xd67bdd25, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, true);
        perpsv2proxymaticperp_i.addRoute(0x4ad4914b, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x32f05103, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0xec556889, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, true);
        perpsv2proxymaticperp_i.addRoute(0x4eb985cc, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0xbc67f832, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x97107d6d, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x88a3c848, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x5a1cbd2b, 0xC703B8d6a2F6c9F9Fd3b92Bc38F3ED716461d943, false);
        perpsv2proxymaticperp_i.addRoute(0x909bc379, 0x0d9A83b625d9793371bF4777De4F24f57f4527e1, false);
        perpsv2proxymaticperp_i.addRoute(0x3c92b8ec, 0x0d9A83b625d9793371bF4777De4F24f57f4527e1, false);
        perpsv2proxymaticperp_i.addRoute(0x7498a0f0, 0x0d9A83b625d9793371bF4777De4F24f57f4527e1, false);
        perpsv2proxymaticperp_i.addRoute(0xc5a4b07a, 0x7F059E5FAA4972B098C7539A6721c596BDc942de, false);
        perpsv2proxymaticperp_i.addRoute(0xed44a2db, 0x7F059E5FAA4972B098C7539A6721c596BDc942de, false);
        perpsv2proxymaticperp_i.addRoute(0x09461cfe, 0x7F059E5FAA4972B098C7539A6721c596BDc942de, false);
        perpsv2proxymaticperp_i.addRoute(0x787d6c30, 0x7F059E5FAA4972B098C7539A6721c596BDc942de, false);
        perpsv2proxymaticperp_i.addRoute(0xa1c35a35, 0x7F059E5FAA4972B098C7539A6721c596BDc942de, false);
        perpsv2proxymaticperp_i.addRoute(0x85f05ab5, 0x7F059E5FAA4972B098C7539A6721c596BDc942de, false);
        perpsv2proxymaticperp_i.addRoute(0xc70b41e9, 0x8e1B638EF5E796504BE87fB81943e613875EcabE, false);
        perpsv2proxymaticperp_i.addRoute(0xdcce5806, 0x8e1B638EF5E796504BE87fB81943e613875EcabE, false);
        perpsv2proxymaticperp_i.addRoute(0xa8300afb, 0x8e1B638EF5E796504BE87fB81943e613875EcabE, false);
        perpsv2proxymaticperp_i.addRoute(0xdfa723cc, 0x8e1B638EF5E796504BE87fB81943e613875EcabE, false);
        perpsv2proxymaticperp_i.addRoute(0x785cdeec, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x1bf556d0, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xd24378eb, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xcdf456e1, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xb9f4ff55, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x3aef4d0b, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xb74e3806, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xc8b809aa, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xea9f9aa7, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x27b9a236, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xe44c84c2, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x41108cf2, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xcded0cea, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xfef48a99, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xc8023af4, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x964db90c, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xe8c63470, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xd7103a46, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xeb56105d, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x5fc890c2, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x2b58ecef, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xb895daab, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x4dd9d7e9, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x55f57510, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xea1d5478, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0xb111dfac, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x9cfbf4e4, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        perpsv2proxymaticperp_i.addRoute(0x917e77f5, 0x2F94942764C997e777F7Ded68679a5eCC6B7514c, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sMATICPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sMATICPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sMATICPERP", 4000000000000000);
        perpsv2marketstatedogeperp_i.linkOrInitializeState();
        perpsv2marketstatedogeperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxydogeperp_i.addRoute(0xa126d601, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x5c8011c3, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x2af64bd3, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, true);
        perpsv2proxydogeperp_i.addRoute(0xd67bdd25, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, true);
        perpsv2proxydogeperp_i.addRoute(0x4ad4914b, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x32f05103, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0xec556889, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, true);
        perpsv2proxydogeperp_i.addRoute(0x4eb985cc, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0xbc67f832, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x97107d6d, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x88a3c848, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x5a1cbd2b, 0x8F1C7653e0d29CDc1a1F1220EeCC7dB1BB82cdc2, false);
        perpsv2proxydogeperp_i.addRoute(0x909bc379, 0xf2425A167bFD229e64D9e28258013cA959e9991A, false);
        perpsv2proxydogeperp_i.addRoute(0x3c92b8ec, 0xf2425A167bFD229e64D9e28258013cA959e9991A, false);
        perpsv2proxydogeperp_i.addRoute(0x7498a0f0, 0xf2425A167bFD229e64D9e28258013cA959e9991A, false);
        perpsv2proxydogeperp_i.addRoute(0xc5a4b07a, 0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc, false);
        perpsv2proxydogeperp_i.addRoute(0xed44a2db, 0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc, false);
        perpsv2proxydogeperp_i.addRoute(0x09461cfe, 0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc, false);
        perpsv2proxydogeperp_i.addRoute(0x787d6c30, 0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc, false);
        perpsv2proxydogeperp_i.addRoute(0xa1c35a35, 0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc, false);
        perpsv2proxydogeperp_i.addRoute(0x85f05ab5, 0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc, false);
        perpsv2proxydogeperp_i.addRoute(0xc70b41e9, 0x374f2D3353bd664a2B25508df4a3b58939999E1B, false);
        perpsv2proxydogeperp_i.addRoute(0xdcce5806, 0x374f2D3353bd664a2B25508df4a3b58939999E1B, false);
        perpsv2proxydogeperp_i.addRoute(0xa8300afb, 0x374f2D3353bd664a2B25508df4a3b58939999E1B, false);
        perpsv2proxydogeperp_i.addRoute(0xdfa723cc, 0x374f2D3353bd664a2B25508df4a3b58939999E1B, false);
        perpsv2proxydogeperp_i.addRoute(0x785cdeec, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x1bf556d0, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xd24378eb, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xcdf456e1, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xb9f4ff55, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x3aef4d0b, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xb74e3806, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xc8b809aa, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xea9f9aa7, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x27b9a236, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xe44c84c2, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x41108cf2, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xcded0cea, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xfef48a99, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xc8023af4, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x964db90c, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xe8c63470, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xd7103a46, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xeb56105d, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x5fc890c2, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x2b58ecef, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xb895daab, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x4dd9d7e9, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x55f57510, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xea1d5478, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0xb111dfac, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x9cfbf4e4, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        perpsv2proxydogeperp_i.addRoute(0x917e77f5, 0x9c79C19FF4d1a6531D9a4F91e96534F5D002dF8B, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sDOGEPERP", 2500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sDOGEPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sDOGEPERP", 5000000000000000);
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

    function perpsv2marketstatematicperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatematicperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstatematicperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x82f962aF60e6627d3ea5Db5Fd7e1a57f7E1Ef2B8
        );
        perpsv2marketstatematicperplegacy_i.addAssociatedContracts(
            perpsv2marketstatematicperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0x7F059E5FAA4972B098C7539A6721c596BDc942de
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0x8e1B638EF5E796504BE87fB81943e613875EcabE
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x074B8F19fc91d6B2eb51143E1f186Ca0DDB88042
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstatedogeperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstatedogeperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstatedogeperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x0A0A22189c8732cA089D6fB6709e65140a446a41
        );
        perpsv2marketstatedogeperplegacy_i.addAssociatedContracts(
            perpsv2marketstatedogeperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x128d0Eb5E26Cf95128AA9aC395f88dcE705AedAc
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x374f2D3353bd664a2B25508df4a3b58939999E1B
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x98cCbC721cc05E28a125943D69039B39BE6A21e9
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
