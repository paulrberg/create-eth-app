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
contract Migration_CaphOptimismStep5 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0xac3F9a2753f185731324907E6802395d59Bb62a2
    PerpsV2MarketState public constant perpsv2marketstatedydxperp_i =
        PerpsV2MarketState(0xac3F9a2753f185731324907E6802395d59Bb62a2);
    // https://explorer.optimism.io/address/0xA1c26b1ff002993dD1fd43c0f662C5d93cC5B66E
    PerpsV2MarketState public constant perpsv2marketstatedydxperplegacy_i =
        PerpsV2MarketState(0xA1c26b1ff002993dD1fd43c0f662C5d93cC5B66E);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x139F94E4f0e1101c1464a321CBA815c34d58B5D9
    ProxyPerpsV2 public constant perpsv2proxydydxperp_i = ProxyPerpsV2(0x139F94E4f0e1101c1464a321CBA815c34d58B5D9);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x733a69D080B10Bc897452eF783020cdFe012974A
    PerpsV2MarketState public constant perpsv2marketstategbpperp_i =
        PerpsV2MarketState(0x733a69D080B10Bc897452eF783020cdFe012974A);
    // https://explorer.optimism.io/address/0x4E1F44E48D2E87E279d25EEd88ced1Ec7f51438e
    PerpsV2MarketState public constant perpsv2marketstategbpperplegacy_i =
        PerpsV2MarketState(0x4E1F44E48D2E87E279d25EEd88ced1Ec7f51438e);
    // https://explorer.optimism.io/address/0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49
    ProxyPerpsV2 public constant perpsv2proxygbpperp_i = ProxyPerpsV2(0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatedydxperp_i);
        contracts[2] = address(perpsv2marketstatedydxperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxydydxperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstategbpperp_i);
        contracts[8] = address(perpsv2marketstategbpperplegacy_i);
        contracts[9] = address(perpsv2proxygbpperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstatedydxperp_i.linkOrInitializeState();
        perpsv2marketstatedydxperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxydydxperp_i.addRoute(0xa126d601, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x5c8011c3, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x2af64bd3, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, true);
        perpsv2proxydydxperp_i.addRoute(0xd67bdd25, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, true);
        perpsv2proxydydxperp_i.addRoute(0x4ad4914b, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x32f05103, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0xec556889, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, true);
        perpsv2proxydydxperp_i.addRoute(0x4eb985cc, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0xbc67f832, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x97107d6d, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x88a3c848, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x5a1cbd2b, 0xB766E4F63da917d3D289b1d52ba5Ac3829e7c679, false);
        perpsv2proxydydxperp_i.addRoute(0x909bc379, 0xAbA508B0F09fb7ff9a3fe129c09BC87a00B0ddeC, false);
        perpsv2proxydydxperp_i.addRoute(0x3c92b8ec, 0xAbA508B0F09fb7ff9a3fe129c09BC87a00B0ddeC, false);
        perpsv2proxydydxperp_i.addRoute(0x7498a0f0, 0xAbA508B0F09fb7ff9a3fe129c09BC87a00B0ddeC, false);
        perpsv2proxydydxperp_i.addRoute(0xc5a4b07a, 0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60, false);
        perpsv2proxydydxperp_i.addRoute(0xed44a2db, 0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60, false);
        perpsv2proxydydxperp_i.addRoute(0x09461cfe, 0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60, false);
        perpsv2proxydydxperp_i.addRoute(0x787d6c30, 0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60, false);
        perpsv2proxydydxperp_i.addRoute(0xa1c35a35, 0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60, false);
        perpsv2proxydydxperp_i.addRoute(0x85f05ab5, 0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60, false);
        perpsv2proxydydxperp_i.addRoute(0xc70b41e9, 0xE6aC817Cfdd83073aec079cD9EBb9c35479b7665, false);
        perpsv2proxydydxperp_i.addRoute(0xdcce5806, 0xE6aC817Cfdd83073aec079cD9EBb9c35479b7665, false);
        perpsv2proxydydxperp_i.addRoute(0xa8300afb, 0xE6aC817Cfdd83073aec079cD9EBb9c35479b7665, false);
        perpsv2proxydydxperp_i.addRoute(0xdfa723cc, 0xE6aC817Cfdd83073aec079cD9EBb9c35479b7665, false);
        perpsv2proxydydxperp_i.addRoute(0x785cdeec, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x1bf556d0, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xd24378eb, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xcdf456e1, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xb9f4ff55, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x3aef4d0b, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xb74e3806, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xc8b809aa, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xea9f9aa7, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x27b9a236, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xe44c84c2, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x41108cf2, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xcded0cea, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xfef48a99, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xc8023af4, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x964db90c, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xe8c63470, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xd7103a46, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xeb56105d, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x5fc890c2, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x2b58ecef, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xb895daab, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x4dd9d7e9, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x55f57510, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xea1d5478, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0xb111dfac, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x9cfbf4e4, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        perpsv2proxydydxperp_i.addRoute(0x917e77f5, 0x2e26D4beC1464409c154f653A238cE5BAAA00198, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sDYDXPERP", 2500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sDYDXPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sDYDXPERP", 5000000000000000);
        perpsv2marketstategbpperp_i.linkOrInitializeState();
        perpsv2marketstategbpperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxygbpperp_i.addRoute(0xa126d601, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x5c8011c3, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x2af64bd3, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, true);
        perpsv2proxygbpperp_i.addRoute(0xd67bdd25, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, true);
        perpsv2proxygbpperp_i.addRoute(0x4ad4914b, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x32f05103, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0xec556889, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, true);
        perpsv2proxygbpperp_i.addRoute(0x4eb985cc, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0xbc67f832, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x97107d6d, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x88a3c848, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x5a1cbd2b, 0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B, false);
        perpsv2proxygbpperp_i.addRoute(0x909bc379, 0x77769c01168011f26a39B71C9c7bA0607752E9ff, false);
        perpsv2proxygbpperp_i.addRoute(0x3c92b8ec, 0x77769c01168011f26a39B71C9c7bA0607752E9ff, false);
        perpsv2proxygbpperp_i.addRoute(0x7498a0f0, 0x77769c01168011f26a39B71C9c7bA0607752E9ff, false);
        perpsv2proxygbpperp_i.addRoute(0xc5a4b07a, 0xc8590aEb1484e642f7321bd0586B6DB3165a862C, false);
        perpsv2proxygbpperp_i.addRoute(0xed44a2db, 0xc8590aEb1484e642f7321bd0586B6DB3165a862C, false);
        perpsv2proxygbpperp_i.addRoute(0x09461cfe, 0xc8590aEb1484e642f7321bd0586B6DB3165a862C, false);
        perpsv2proxygbpperp_i.addRoute(0x787d6c30, 0xc8590aEb1484e642f7321bd0586B6DB3165a862C, false);
        perpsv2proxygbpperp_i.addRoute(0xa1c35a35, 0xc8590aEb1484e642f7321bd0586B6DB3165a862C, false);
        perpsv2proxygbpperp_i.addRoute(0x85f05ab5, 0xc8590aEb1484e642f7321bd0586B6DB3165a862C, false);
        perpsv2proxygbpperp_i.addRoute(0xc70b41e9, 0xD3d59d4b8B504Ea6e49c5788Fe1BC7505c6f61EA, false);
        perpsv2proxygbpperp_i.addRoute(0xdcce5806, 0xD3d59d4b8B504Ea6e49c5788Fe1BC7505c6f61EA, false);
        perpsv2proxygbpperp_i.addRoute(0xa8300afb, 0xD3d59d4b8B504Ea6e49c5788Fe1BC7505c6f61EA, false);
        perpsv2proxygbpperp_i.addRoute(0xdfa723cc, 0xD3d59d4b8B504Ea6e49c5788Fe1BC7505c6f61EA, false);
        perpsv2proxygbpperp_i.addRoute(0x785cdeec, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x1bf556d0, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xd24378eb, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xcdf456e1, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xb9f4ff55, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x3aef4d0b, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xb74e3806, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xc8b809aa, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xea9f9aa7, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x27b9a236, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xe44c84c2, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x41108cf2, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xcded0cea, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xfef48a99, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xc8023af4, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x964db90c, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xe8c63470, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xd7103a46, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xeb56105d, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x5fc890c2, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x2b58ecef, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xb895daab, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x4dd9d7e9, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x55f57510, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xea1d5478, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0xb111dfac, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x9cfbf4e4, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        perpsv2proxygbpperp_i.addRoute(0x917e77f5, 0x3f30190416EBdE7F50749cf3579Af1beeF2E7Fa8, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sGBPPERP", 300000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sGBPPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sGBPPERP", 600000000000000);
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

    function perpsv2marketstatedydxperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatedydxperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstatedydxperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0xac3F9a2753f185731324907E6802395d59Bb62a2
        );
        perpsv2marketstatedydxperplegacy_i.addAssociatedContracts(
            perpsv2marketstatedydxperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0xdFaEBe6A2B2BDAc52aC2E172e0175988d7472c60
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0xE6aC817Cfdd83073aec079cD9EBb9c35479b7665
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x139F94E4f0e1101c1464a321CBA815c34d58B5D9
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstategbpperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstategbpperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstategbpperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x733a69D080B10Bc897452eF783020cdFe012974A
        );
        perpsv2marketstategbpperplegacy_i.addAssociatedContracts(
            perpsv2marketstategbpperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0xc8590aEb1484e642f7321bd0586B6DB3165a862C
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0xD3d59d4b8B504Ea6e49c5788Fe1BC7505c6f61EA
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
