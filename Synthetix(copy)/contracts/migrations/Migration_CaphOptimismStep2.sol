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
import "../AddressResolver.sol";
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
contract Migration_CaphOptimismStep2 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C
    AddressResolver public constant addressresolver_i = AddressResolver(0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x3DfBB7D0770e6Eb77fBEc89C0840E9A0f29C76Ff
    PerpsV2MarketState public constant perpsv2marketstatebnbperp_i =
        PerpsV2MarketState(0x3DfBB7D0770e6Eb77fBEc89C0840E9A0f29C76Ff);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25
    ProxyPerpsV2 public constant perpsv2proxybnbperp_i = ProxyPerpsV2(0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xcfdC039BDB8E4b578857b759f27D6BAa2617EDD3
    PerpsV2MarketState public constant perpsv2marketstateaxsperp_i =
        PerpsV2MarketState(0xcfdC039BDB8E4b578857b759f27D6BAa2617EDD3);
    // https://explorer.optimism.io/address/0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1
    ProxyPerpsV2 public constant perpsv2proxyaxsperp_i = ProxyPerpsV2(0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    address public constant new_PerpsV2MarketSettings_contract = 0x649F44CAC3276557D03223Dbf6395Af65b11c11c;
    // https://explorer.optimism.io/address/0x58e6227510F83d3F45B339F2f7A05a699fDEE6D4
    address public constant new_PerpsV2MarketData_contract = 0x58e6227510F83d3F45B339F2f7A05a699fDEE6D4;
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    address public constant new_FuturesMarketManager_contract = 0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463;
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    address public constant new_PerpsV2ExchangeRate_contract = 0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](9);
        contracts[0] = address(addressresolver_i);
        contracts[1] = address(systemstatus_i);
        contracts[2] = address(perpsv2marketstatebnbperp_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxybnbperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateaxsperp_i);
        contracts[8] = address(perpsv2proxyaxsperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sBNBPERP", 80);
        perpsv2marketstatebnbperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_4();
        perpsv2proxybnbperp_i.addRoute(0xa126d601, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x5c8011c3, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x2af64bd3, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, true);
        perpsv2proxybnbperp_i.addRoute(0xd67bdd25, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, true);
        perpsv2proxybnbperp_i.addRoute(0x4ad4914b, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x32f05103, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0xec556889, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, true);
        perpsv2proxybnbperp_i.addRoute(0x4eb985cc, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0xbc67f832, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x97107d6d, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x88a3c848, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x5a1cbd2b, 0xBccaC7cbc37aa2De510863647197D584F55AE46b, false);
        perpsv2proxybnbperp_i.addRoute(0x909bc379, 0x7C5FbeBDfE7659BEe68A4Aa284575a21055651eA, false);
        perpsv2proxybnbperp_i.addRoute(0x3c92b8ec, 0x7C5FbeBDfE7659BEe68A4Aa284575a21055651eA, false);
        perpsv2proxybnbperp_i.addRoute(0x7498a0f0, 0x7C5FbeBDfE7659BEe68A4Aa284575a21055651eA, false);
        perpsv2proxybnbperp_i.addRoute(0xc5a4b07a, 0x2ae5608AB3fb3863a713715f3F59216bCAbc5150, false);
        perpsv2proxybnbperp_i.addRoute(0xed44a2db, 0x2ae5608AB3fb3863a713715f3F59216bCAbc5150, false);
        perpsv2proxybnbperp_i.addRoute(0x09461cfe, 0x2ae5608AB3fb3863a713715f3F59216bCAbc5150, false);
        perpsv2proxybnbperp_i.addRoute(0x787d6c30, 0x2ae5608AB3fb3863a713715f3F59216bCAbc5150, false);
        perpsv2proxybnbperp_i.addRoute(0xa1c35a35, 0x2ae5608AB3fb3863a713715f3F59216bCAbc5150, false);
        perpsv2proxybnbperp_i.addRoute(0x85f05ab5, 0x2ae5608AB3fb3863a713715f3F59216bCAbc5150, false);
        perpsv2proxybnbperp_i.addRoute(0xc70b41e9, 0x210BA565130f2aF399fD8435a279b22894e8D096, false);
        perpsv2proxybnbperp_i.addRoute(0xdcce5806, 0x210BA565130f2aF399fD8435a279b22894e8D096, false);
        perpsv2proxybnbperp_i.addRoute(0xa8300afb, 0x210BA565130f2aF399fD8435a279b22894e8D096, false);
        perpsv2proxybnbperp_i.addRoute(0xdfa723cc, 0x210BA565130f2aF399fD8435a279b22894e8D096, false);
        perpsv2proxybnbperp_i.addRoute(0x785cdeec, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x1bf556d0, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xd24378eb, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xcdf456e1, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xb9f4ff55, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x3aef4d0b, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xb74e3806, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xc8b809aa, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xea9f9aa7, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x27b9a236, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xe44c84c2, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x41108cf2, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xcded0cea, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xfef48a99, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xc8023af4, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x964db90c, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xe8c63470, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xd7103a46, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xeb56105d, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x5fc890c2, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x2b58ecef, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xb895daab, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x4dd9d7e9, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x55f57510, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xea1d5478, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0xb111dfac, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x9cfbf4e4, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        perpsv2proxybnbperp_i.addRoute(0x917e77f5, 0xA227c833786E46d53cf9E9a14cFF906477335D91, true);
        futuresmarketmanager_addProxiedMarkets_58();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_59();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sBNBPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sBNBPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sBNBPERP", 4000000000000000);
        systemstatus_i.resumeFuturesMarket("sBNBPERP");
        // Ensure perpsV2 market is paused according to config;
        systemstatus_i.suspendFuturesMarket("sAXSPERP", 80);
        perpsv2marketstateaxsperp_i.linkOrInitializeState();
        perpsv2exchangerate_addAssociatedContracts_66();
        perpsv2proxyaxsperp_i.addRoute(0xa126d601, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x5c8011c3, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x2af64bd3, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, true);
        perpsv2proxyaxsperp_i.addRoute(0xd67bdd25, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, true);
        perpsv2proxyaxsperp_i.addRoute(0x4ad4914b, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x32f05103, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0xec556889, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, true);
        perpsv2proxyaxsperp_i.addRoute(0x4eb985cc, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0xbc67f832, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x97107d6d, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x88a3c848, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x5a1cbd2b, 0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c, false);
        perpsv2proxyaxsperp_i.addRoute(0x909bc379, 0x08c2c8d7175C5766a8aFCd1f7B69a6D999e21824, false);
        perpsv2proxyaxsperp_i.addRoute(0x3c92b8ec, 0x08c2c8d7175C5766a8aFCd1f7B69a6D999e21824, false);
        perpsv2proxyaxsperp_i.addRoute(0x7498a0f0, 0x08c2c8d7175C5766a8aFCd1f7B69a6D999e21824, false);
        perpsv2proxyaxsperp_i.addRoute(0xc5a4b07a, 0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6, false);
        perpsv2proxyaxsperp_i.addRoute(0xed44a2db, 0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6, false);
        perpsv2proxyaxsperp_i.addRoute(0x09461cfe, 0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6, false);
        perpsv2proxyaxsperp_i.addRoute(0x787d6c30, 0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6, false);
        perpsv2proxyaxsperp_i.addRoute(0xa1c35a35, 0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6, false);
        perpsv2proxyaxsperp_i.addRoute(0x85f05ab5, 0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6, false);
        perpsv2proxyaxsperp_i.addRoute(0xc70b41e9, 0x2b8cE8a8ABF039DB01B2ad7F512b9157467eb264, false);
        perpsv2proxyaxsperp_i.addRoute(0xdcce5806, 0x2b8cE8a8ABF039DB01B2ad7F512b9157467eb264, false);
        perpsv2proxyaxsperp_i.addRoute(0xa8300afb, 0x2b8cE8a8ABF039DB01B2ad7F512b9157467eb264, false);
        perpsv2proxyaxsperp_i.addRoute(0xdfa723cc, 0x2b8cE8a8ABF039DB01B2ad7F512b9157467eb264, false);
        perpsv2proxyaxsperp_i.addRoute(0x785cdeec, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x1bf556d0, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xd24378eb, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xcdf456e1, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xb9f4ff55, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x3aef4d0b, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xb74e3806, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xc8b809aa, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xea9f9aa7, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x27b9a236, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xe44c84c2, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x41108cf2, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xcded0cea, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xfef48a99, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xc8023af4, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x964db90c, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xe8c63470, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xd7103a46, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xeb56105d, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x5fc890c2, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x2b58ecef, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xb895daab, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x4dd9d7e9, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x55f57510, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xea1d5478, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0xb111dfac, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x9cfbf4e4, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        perpsv2proxyaxsperp_i.addRoute(0x917e77f5, 0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17, true);
        futuresmarketmanager_addProxiedMarkets_120();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_121();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sAXSPERP", 2500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sAXSPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sAXSPERP", 5000000000000000);
        systemstatus_i.resumeFuturesMarket("sAXSPERP");
        systemstatus_i.updateAccessControl("Futures", address(this), false, false);
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_126();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 1;
        addressresolver_rebuildCaches_127();
        // Set the keeper liquidation fee;
        perpsv2marketsettings_i.setKeeperLiquidationFee(2000000000000000000);

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

    function addressresolver_importAddresses_0() internal {
        bytes32[] memory addressresolver_importAddresses_names_0_0 = new bytes32[](4);
        addressresolver_importAddresses_names_0_0[0] = bytes32("FuturesMarketManager");
        addressresolver_importAddresses_names_0_0[1] = bytes32("PerpsV2MarketData");
        addressresolver_importAddresses_names_0_0[2] = bytes32("PerpsV2MarketSettings");
        addressresolver_importAddresses_names_0_0[3] = bytes32("PerpsV2ExchangeRate");
        address[] memory addressresolver_importAddresses_destinations_0_1 = new address[](4);
        addressresolver_importAddresses_destinations_0_1[0] = address(new_FuturesMarketManager_contract);
        addressresolver_importAddresses_destinations_0_1[1] = address(new_PerpsV2MarketData_contract);
        addressresolver_importAddresses_destinations_0_1[2] = address(new_PerpsV2MarketSettings_contract);
        addressresolver_importAddresses_destinations_0_1[3] = address(new_PerpsV2ExchangeRate_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_0_0,
            addressresolver_importAddresses_destinations_0_1
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_4() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_4_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_4_0[0] = address(
            0x2ae5608AB3fb3863a713715f3F59216bCAbc5150
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_4_0[1] = address(
            0x210BA565130f2aF399fD8435a279b22894e8D096
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_4_0);
    }

    function futuresmarketmanager_addProxiedMarkets_58() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_58_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_58_0[0] = address(0x0940B0A96C5e1ba33AEE331a9f950Bb2a6F2Fb25);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_58_0);
    }

    function addressresolver_importAddresses_59() internal {
        bytes32[] memory addressresolver_importAddresses_names_59_0 = new bytes32[](4);
        addressresolver_importAddresses_names_59_0[0] = bytes32("FuturesMarketManager");
        addressresolver_importAddresses_names_59_0[1] = bytes32("PerpsV2ExchangeRate");
        addressresolver_importAddresses_names_59_0[2] = bytes32("PerpsV2MarketData");
        addressresolver_importAddresses_names_59_0[3] = bytes32("PerpsV2MarketSettings");
        address[] memory addressresolver_importAddresses_destinations_59_1 = new address[](4);
        addressresolver_importAddresses_destinations_59_1[0] = address(new_FuturesMarketManager_contract);
        addressresolver_importAddresses_destinations_59_1[1] = address(new_PerpsV2ExchangeRate_contract);
        addressresolver_importAddresses_destinations_59_1[2] = address(new_PerpsV2MarketData_contract);
        addressresolver_importAddresses_destinations_59_1[3] = address(new_PerpsV2MarketSettings_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_59_0,
            addressresolver_importAddresses_destinations_59_1
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_66() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_66_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_66_0[0] = address(
            0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_66_0[1] = address(
            0x2b8cE8a8ABF039DB01B2ad7F512b9157467eb264
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_66_0);
    }

    function futuresmarketmanager_addProxiedMarkets_120() internal {
        address[] memory futuresmarketmanager_addProxiedMarkets_marketsToAdd_120_0 = new address[](1);
        futuresmarketmanager_addProxiedMarkets_marketsToAdd_120_0[0] = address(0x3a52b21816168dfe35bE99b7C5fc209f17a0aDb1);
        futuresmarketmanager_i.addProxiedMarkets(futuresmarketmanager_addProxiedMarkets_marketsToAdd_120_0);
    }

    function addressresolver_importAddresses_121() internal {
        bytes32[] memory addressresolver_importAddresses_names_121_0 = new bytes32[](4);
        addressresolver_importAddresses_names_121_0[0] = bytes32("FuturesMarketManager");
        addressresolver_importAddresses_names_121_0[1] = bytes32("PerpsV2MarketData");
        addressresolver_importAddresses_names_121_0[2] = bytes32("PerpsV2ExchangeRate");
        addressresolver_importAddresses_names_121_0[3] = bytes32("PerpsV2MarketSettings");
        address[] memory addressresolver_importAddresses_destinations_121_1 = new address[](4);
        addressresolver_importAddresses_destinations_121_1[0] = address(new_FuturesMarketManager_contract);
        addressresolver_importAddresses_destinations_121_1[1] = address(new_PerpsV2MarketData_contract);
        addressresolver_importAddresses_destinations_121_1[2] = address(new_PerpsV2ExchangeRate_contract);
        addressresolver_importAddresses_destinations_121_1[3] = address(new_PerpsV2MarketSettings_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_121_0,
            addressresolver_importAddresses_destinations_121_1
        );
    }

    function addressresolver_importAddresses_126() internal {
        bytes32[] memory addressresolver_importAddresses_names_126_0 = new bytes32[](4);
        addressresolver_importAddresses_names_126_0[0] = bytes32("PerpsV2MarketSettings");
        addressresolver_importAddresses_names_126_0[1] = bytes32("PerpsV2MarketData");
        addressresolver_importAddresses_names_126_0[2] = bytes32("FuturesMarketManager");
        addressresolver_importAddresses_names_126_0[3] = bytes32("PerpsV2ExchangeRate");
        address[] memory addressresolver_importAddresses_destinations_126_1 = new address[](4);
        addressresolver_importAddresses_destinations_126_1[0] = address(new_PerpsV2MarketSettings_contract);
        addressresolver_importAddresses_destinations_126_1[1] = address(new_PerpsV2MarketData_contract);
        addressresolver_importAddresses_destinations_126_1[2] = address(new_FuturesMarketManager_contract);
        addressresolver_importAddresses_destinations_126_1[3] = address(new_PerpsV2ExchangeRate_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_126_0,
            addressresolver_importAddresses_destinations_126_1
        );
    }

    function addressresolver_rebuildCaches_127() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_127_0 = new MixinResolver[](20);
        addressresolver_rebuildCaches_destinations_127_0[0] = MixinResolver(0xBccaC7cbc37aa2De510863647197D584F55AE46b);
        addressresolver_rebuildCaches_destinations_127_0[1] = MixinResolver(0x7C5FbeBDfE7659BEe68A4Aa284575a21055651eA);
        addressresolver_rebuildCaches_destinations_127_0[2] = MixinResolver(0x2ae5608AB3fb3863a713715f3F59216bCAbc5150);
        addressresolver_rebuildCaches_destinations_127_0[3] = MixinResolver(0x210BA565130f2aF399fD8435a279b22894e8D096);
        addressresolver_rebuildCaches_destinations_127_0[4] = MixinResolver(0xA227c833786E46d53cf9E9a14cFF906477335D91);
        addressresolver_rebuildCaches_destinations_127_0[5] = MixinResolver(0xdFa823f131Baa72334eDaB7c4e163a65024C6B3c);
        addressresolver_rebuildCaches_destinations_127_0[6] = MixinResolver(0x08c2c8d7175C5766a8aFCd1f7B69a6D999e21824);
        addressresolver_rebuildCaches_destinations_127_0[7] = MixinResolver(0x6FBcabaa42cE1818f23a0b909dbD9BC7691FC1E6);
        addressresolver_rebuildCaches_destinations_127_0[8] = MixinResolver(0x2b8cE8a8ABF039DB01B2ad7F512b9157467eb264);
        addressresolver_rebuildCaches_destinations_127_0[9] = MixinResolver(0xcaDD53c5fAAe5111c7a0429Ee1f99A695433Fb17);
        addressresolver_rebuildCaches_destinations_127_0[10] = MixinResolver(new_PerpsV2MarketSettings_contract);
        addressresolver_rebuildCaches_destinations_127_0[11] = MixinResolver(0xf9FE3607e6d19D8dC690DD976061a91D4A0db30B);
        addressresolver_rebuildCaches_destinations_127_0[12] = MixinResolver(0x17628A557d1Fc88D1c35989dcBAC3f3e275E2d2B);
        addressresolver_rebuildCaches_destinations_127_0[13] = MixinResolver(0xDfA2d3a0d32F870D87f8A0d7AA6b9CdEB7bc5AdB);
        addressresolver_rebuildCaches_destinations_127_0[14] = MixinResolver(0xe9dceA0136FEFC76c4E639Ec60CCE70482E2aCF7);
        addressresolver_rebuildCaches_destinations_127_0[15] = MixinResolver(0x421DEF861D623F7123dfE0878D86E9576cbb3975);
        addressresolver_rebuildCaches_destinations_127_0[16] = MixinResolver(0xdEdb0b04AFF1525bb4B6167F00e61601690c1fF2);
        addressresolver_rebuildCaches_destinations_127_0[17] = MixinResolver(0x34c2360ffe5D21542f76e991FFD104f281D4B3fb);
        addressresolver_rebuildCaches_destinations_127_0[18] = MixinResolver(new_FuturesMarketManager_contract);
        addressresolver_rebuildCaches_destinations_127_0[19] = MixinResolver(new_PerpsV2ExchangeRate_contract);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_127_0);
    }
}
