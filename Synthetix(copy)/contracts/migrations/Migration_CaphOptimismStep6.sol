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
contract Migration_CaphOptimismStep6 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x089af032687993426A628184cb3D0610d2cda6F2
    PerpsV2MarketState public constant perpsv2marketstateapeperp_i =
        PerpsV2MarketState(0x089af032687993426A628184cb3D0610d2cda6F2);
    // https://explorer.optimism.io/address/0xDaA88C67eBA3a95715d678557A4F42e26cd01F1A
    PerpsV2MarketState public constant perpsv2marketstateapeperplegacy_i =
        PerpsV2MarketState(0xDaA88C67eBA3a95715d678557A4F42e26cd01F1A);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886
    ProxyPerpsV2 public constant perpsv2proxyapeperp_i = ProxyPerpsV2(0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x1951c6b2D9DD9A3CF10aaC5e79A7EcA0a5300BB5
    PerpsV2MarketState public constant perpsv2marketstateftmperp_i =
        PerpsV2MarketState(0x1951c6b2D9DD9A3CF10aaC5e79A7EcA0a5300BB5);
    // https://explorer.optimism.io/address/0xe76DF4d2554C74B746c5A1Df8EAA4eA8F657916d
    PerpsV2MarketState public constant perpsv2marketstateftmperplegacy_i =
        PerpsV2MarketState(0xe76DF4d2554C74B746c5A1Df8EAA4eA8F657916d);
    // https://explorer.optimism.io/address/0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4
    ProxyPerpsV2 public constant perpsv2proxyftmperp_i = ProxyPerpsV2(0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstateapeperp_i);
        contracts[2] = address(perpsv2marketstateapeperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxyapeperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateftmperp_i);
        contracts[8] = address(perpsv2marketstateftmperplegacy_i);
        contracts[9] = address(perpsv2proxyftmperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstateapeperp_i.linkOrInitializeState();
        perpsv2marketstateapeperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxyapeperp_i.addRoute(0xa126d601, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x5c8011c3, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x2af64bd3, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, true);
        perpsv2proxyapeperp_i.addRoute(0xd67bdd25, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, true);
        perpsv2proxyapeperp_i.addRoute(0x4ad4914b, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x32f05103, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0xec556889, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, true);
        perpsv2proxyapeperp_i.addRoute(0x4eb985cc, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0xbc67f832, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x97107d6d, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x88a3c848, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x5a1cbd2b, 0xF9e5FafA7B744d75F10ffe24fb2A7f7FF40e6033, false);
        perpsv2proxyapeperp_i.addRoute(0x909bc379, 0x9074b2389baaC5Ea4Fa9d1b1D37589142888697f, false);
        perpsv2proxyapeperp_i.addRoute(0x3c92b8ec, 0x9074b2389baaC5Ea4Fa9d1b1D37589142888697f, false);
        perpsv2proxyapeperp_i.addRoute(0x7498a0f0, 0x9074b2389baaC5Ea4Fa9d1b1D37589142888697f, false);
        perpsv2proxyapeperp_i.addRoute(0xc5a4b07a, 0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213, false);
        perpsv2proxyapeperp_i.addRoute(0xed44a2db, 0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213, false);
        perpsv2proxyapeperp_i.addRoute(0x09461cfe, 0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213, false);
        perpsv2proxyapeperp_i.addRoute(0x787d6c30, 0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213, false);
        perpsv2proxyapeperp_i.addRoute(0xa1c35a35, 0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213, false);
        perpsv2proxyapeperp_i.addRoute(0x85f05ab5, 0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213, false);
        perpsv2proxyapeperp_i.addRoute(0xc70b41e9, 0xdDeB6cb0D6050C9221D037Aa099a2D11C443548a, false);
        perpsv2proxyapeperp_i.addRoute(0xdcce5806, 0xdDeB6cb0D6050C9221D037Aa099a2D11C443548a, false);
        perpsv2proxyapeperp_i.addRoute(0xa8300afb, 0xdDeB6cb0D6050C9221D037Aa099a2D11C443548a, false);
        perpsv2proxyapeperp_i.addRoute(0xdfa723cc, 0xdDeB6cb0D6050C9221D037Aa099a2D11C443548a, false);
        perpsv2proxyapeperp_i.addRoute(0x785cdeec, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x1bf556d0, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xd24378eb, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xcdf456e1, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xb9f4ff55, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x3aef4d0b, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xb74e3806, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xc8b809aa, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xea9f9aa7, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x27b9a236, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xe44c84c2, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x41108cf2, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xcded0cea, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xfef48a99, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xc8023af4, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x964db90c, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xe8c63470, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xd7103a46, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xeb56105d, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x5fc890c2, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x2b58ecef, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xb895daab, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x4dd9d7e9, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x55f57510, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xea1d5478, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0xb111dfac, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x9cfbf4e4, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        perpsv2proxyapeperp_i.addRoute(0x917e77f5, 0x2891452e2068Ac9471E3610e956510C46B4EffE5, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sAPEPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sAPEPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sAPEPERP", 4000000000000000);
        perpsv2marketstateftmperp_i.linkOrInitializeState();
        perpsv2marketstateftmperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyftmperp_i.addRoute(0xa126d601, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x5c8011c3, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x2af64bd3, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, true);
        perpsv2proxyftmperp_i.addRoute(0xd67bdd25, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, true);
        perpsv2proxyftmperp_i.addRoute(0x4ad4914b, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x32f05103, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0xec556889, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, true);
        perpsv2proxyftmperp_i.addRoute(0x4eb985cc, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0xbc67f832, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x97107d6d, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x88a3c848, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x5a1cbd2b, 0x43C5F53fFd4F909AeD9b51C562eBf1D762c2b496, false);
        perpsv2proxyftmperp_i.addRoute(0x909bc379, 0xA6808A69b3CA50CB2E4a41A51f8979FFaB2D2db2, false);
        perpsv2proxyftmperp_i.addRoute(0x3c92b8ec, 0xA6808A69b3CA50CB2E4a41A51f8979FFaB2D2db2, false);
        perpsv2proxyftmperp_i.addRoute(0x7498a0f0, 0xA6808A69b3CA50CB2E4a41A51f8979FFaB2D2db2, false);
        perpsv2proxyftmperp_i.addRoute(0xc5a4b07a, 0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a, false);
        perpsv2proxyftmperp_i.addRoute(0xed44a2db, 0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a, false);
        perpsv2proxyftmperp_i.addRoute(0x09461cfe, 0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a, false);
        perpsv2proxyftmperp_i.addRoute(0x787d6c30, 0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a, false);
        perpsv2proxyftmperp_i.addRoute(0xa1c35a35, 0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a, false);
        perpsv2proxyftmperp_i.addRoute(0x85f05ab5, 0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a, false);
        perpsv2proxyftmperp_i.addRoute(0xc70b41e9, 0x50197701bd09f8DBDd6716b1b9080574819a3776, false);
        perpsv2proxyftmperp_i.addRoute(0xdcce5806, 0x50197701bd09f8DBDd6716b1b9080574819a3776, false);
        perpsv2proxyftmperp_i.addRoute(0xa8300afb, 0x50197701bd09f8DBDd6716b1b9080574819a3776, false);
        perpsv2proxyftmperp_i.addRoute(0xdfa723cc, 0x50197701bd09f8DBDd6716b1b9080574819a3776, false);
        perpsv2proxyftmperp_i.addRoute(0x785cdeec, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x1bf556d0, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xd24378eb, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xcdf456e1, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xb9f4ff55, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x3aef4d0b, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xb74e3806, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xc8b809aa, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xea9f9aa7, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x27b9a236, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xe44c84c2, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x41108cf2, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xcded0cea, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xfef48a99, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xc8023af4, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x964db90c, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xe8c63470, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xd7103a46, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xeb56105d, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x5fc890c2, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x2b58ecef, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xb895daab, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x4dd9d7e9, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x55f57510, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xea1d5478, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0xb111dfac, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x9cfbf4e4, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        perpsv2proxyftmperp_i.addRoute(0x917e77f5, 0xab0d9E3FF817faa88F4bBC783CFA6D55E5f10F3E, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sFTMPERP", 2500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sFTMPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sFTMPERP", 5000000000000000);
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

    function perpsv2marketstateapeperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateapeperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstateapeperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x089af032687993426A628184cb3D0610d2cda6F2
        );
        perpsv2marketstateapeperplegacy_i.addAssociatedContracts(
            perpsv2marketstateapeperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0x3Cf1BE829C5eE73630482D2E92bF9461Adf1b213
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0xdDeB6cb0D6050C9221D037Aa099a2D11C443548a
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x5B6BeB79E959Aac2659bEE60fE0D0885468BF886
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstateftmperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstateftmperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstateftmperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x1951c6b2D9DD9A3CF10aaC5e79A7EcA0a5300BB5
        );
        perpsv2marketstateftmperplegacy_i.addAssociatedContracts(
            perpsv2marketstateftmperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x88b7BD7A245F2fB597de88a6EDA0CAEe047f607a
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x50197701bd09f8DBDd6716b1b9080574819a3776
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0xC18f85A6DD3Bcd0516a1CA08d3B1f0A4E191A2C4
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
