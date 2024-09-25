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
contract Migration_CaphOptimismStep4 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x779f424d3B3A617beB4a0DB1C21D5505De297a8A
    PerpsV2MarketState public constant perpsv2marketstatenearperp_i =
        PerpsV2MarketState(0x779f424d3B3A617beB4a0DB1C21D5505De297a8A);
    // https://explorer.optimism.io/address/0xea53A19B50C51881C0734a7169Fe9C6E44A09cf9
    PerpsV2MarketState public constant perpsv2marketstatenearperplegacy_i =
        PerpsV2MarketState(0xea53A19B50C51881C0734a7169Fe9C6E44A09cf9);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe
    ProxyPerpsV2 public constant perpsv2proxynearperp_i = ProxyPerpsV2(0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0x6d62aA1535C7C33D7f6592562f091D193E180c57
    PerpsV2MarketState public constant perpsv2marketstateaudperp_i =
        PerpsV2MarketState(0x6d62aA1535C7C33D7f6592562f091D193E180c57);
    // https://explorer.optimism.io/address/0x973dE36Bb8022942e2658D5d129CbDdCF105a470
    PerpsV2MarketState public constant perpsv2marketstateaudperplegacy_i =
        PerpsV2MarketState(0x973dE36Bb8022942e2658D5d129CbDdCF105a470);
    // https://explorer.optimism.io/address/0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99
    ProxyPerpsV2 public constant perpsv2proxyaudperp_i = ProxyPerpsV2(0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatenearperp_i);
        contracts[2] = address(perpsv2marketstatenearperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxynearperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateaudperp_i);
        contracts[8] = address(perpsv2marketstateaudperplegacy_i);
        contracts[9] = address(perpsv2proxyaudperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstatenearperp_i.linkOrInitializeState();
        perpsv2marketstatenearperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxynearperp_i.addRoute(0xa126d601, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x5c8011c3, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x2af64bd3, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, true);
        perpsv2proxynearperp_i.addRoute(0xd67bdd25, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, true);
        perpsv2proxynearperp_i.addRoute(0x4ad4914b, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x32f05103, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0xec556889, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, true);
        perpsv2proxynearperp_i.addRoute(0x4eb985cc, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0xbc67f832, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x97107d6d, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x88a3c848, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x5a1cbd2b, 0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193, false);
        perpsv2proxynearperp_i.addRoute(0x909bc379, 0x40542FEa068ED07247645581C04EfA1f83Ff04E5, false);
        perpsv2proxynearperp_i.addRoute(0x3c92b8ec, 0x40542FEa068ED07247645581C04EfA1f83Ff04E5, false);
        perpsv2proxynearperp_i.addRoute(0x7498a0f0, 0x40542FEa068ED07247645581C04EfA1f83Ff04E5, false);
        perpsv2proxynearperp_i.addRoute(0xc5a4b07a, 0x699c039c9E21d49B8c38768619942dfaB6E8E38d, false);
        perpsv2proxynearperp_i.addRoute(0xed44a2db, 0x699c039c9E21d49B8c38768619942dfaB6E8E38d, false);
        perpsv2proxynearperp_i.addRoute(0x09461cfe, 0x699c039c9E21d49B8c38768619942dfaB6E8E38d, false);
        perpsv2proxynearperp_i.addRoute(0x787d6c30, 0x699c039c9E21d49B8c38768619942dfaB6E8E38d, false);
        perpsv2proxynearperp_i.addRoute(0xa1c35a35, 0x699c039c9E21d49B8c38768619942dfaB6E8E38d, false);
        perpsv2proxynearperp_i.addRoute(0x85f05ab5, 0x699c039c9E21d49B8c38768619942dfaB6E8E38d, false);
        perpsv2proxynearperp_i.addRoute(0xc70b41e9, 0x3403A3430e4a62577e70fB48e070268D84a8F910, false);
        perpsv2proxynearperp_i.addRoute(0xdcce5806, 0x3403A3430e4a62577e70fB48e070268D84a8F910, false);
        perpsv2proxynearperp_i.addRoute(0xa8300afb, 0x3403A3430e4a62577e70fB48e070268D84a8F910, false);
        perpsv2proxynearperp_i.addRoute(0xdfa723cc, 0x3403A3430e4a62577e70fB48e070268D84a8F910, false);
        perpsv2proxynearperp_i.addRoute(0x785cdeec, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x1bf556d0, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xd24378eb, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xcdf456e1, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xb9f4ff55, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x3aef4d0b, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xb74e3806, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xc8b809aa, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xea9f9aa7, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x27b9a236, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xe44c84c2, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x41108cf2, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xcded0cea, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xfef48a99, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xc8023af4, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x964db90c, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xe8c63470, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xd7103a46, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xeb56105d, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x5fc890c2, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x2b58ecef, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xb895daab, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x4dd9d7e9, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x55f57510, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xea1d5478, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0xb111dfac, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x9cfbf4e4, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        perpsv2proxynearperp_i.addRoute(0x917e77f5, 0xC314CFB9C5706f316F3916543aD2F3e4c3aa2d02, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sNEARPERP", 2500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sNEARPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sNEARPERP", 5000000000000000);
        perpsv2marketstateaudperp_i.linkOrInitializeState();
        perpsv2marketstateaudperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyaudperp_i.addRoute(0xa126d601, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x5c8011c3, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x2af64bd3, 0xb153f06077aF9448C53c7102760e59836a27Ed27, true);
        perpsv2proxyaudperp_i.addRoute(0xd67bdd25, 0xb153f06077aF9448C53c7102760e59836a27Ed27, true);
        perpsv2proxyaudperp_i.addRoute(0x4ad4914b, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x32f05103, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0xec556889, 0xb153f06077aF9448C53c7102760e59836a27Ed27, true);
        perpsv2proxyaudperp_i.addRoute(0x4eb985cc, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0xbc67f832, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x97107d6d, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x88a3c848, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x5a1cbd2b, 0xb153f06077aF9448C53c7102760e59836a27Ed27, false);
        perpsv2proxyaudperp_i.addRoute(0x909bc379, 0x0B6364488E14568A125440F3C42aD59698fb9E38, false);
        perpsv2proxyaudperp_i.addRoute(0x3c92b8ec, 0x0B6364488E14568A125440F3C42aD59698fb9E38, false);
        perpsv2proxyaudperp_i.addRoute(0x7498a0f0, 0x0B6364488E14568A125440F3C42aD59698fb9E38, false);
        perpsv2proxyaudperp_i.addRoute(0xc5a4b07a, 0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2, false);
        perpsv2proxyaudperp_i.addRoute(0xed44a2db, 0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2, false);
        perpsv2proxyaudperp_i.addRoute(0x09461cfe, 0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2, false);
        perpsv2proxyaudperp_i.addRoute(0x787d6c30, 0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2, false);
        perpsv2proxyaudperp_i.addRoute(0xa1c35a35, 0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2, false);
        perpsv2proxyaudperp_i.addRoute(0x85f05ab5, 0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2, false);
        perpsv2proxyaudperp_i.addRoute(0xc70b41e9, 0x0D8121E17b74e537286304c7804a5bC592A7964f, false);
        perpsv2proxyaudperp_i.addRoute(0xdcce5806, 0x0D8121E17b74e537286304c7804a5bC592A7964f, false);
        perpsv2proxyaudperp_i.addRoute(0xa8300afb, 0x0D8121E17b74e537286304c7804a5bC592A7964f, false);
        perpsv2proxyaudperp_i.addRoute(0xdfa723cc, 0x0D8121E17b74e537286304c7804a5bC592A7964f, false);
        perpsv2proxyaudperp_i.addRoute(0x785cdeec, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x1bf556d0, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xd24378eb, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xcdf456e1, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xb9f4ff55, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x3aef4d0b, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xb74e3806, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xc8b809aa, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xea9f9aa7, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x27b9a236, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xe44c84c2, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x41108cf2, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xcded0cea, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xfef48a99, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xc8023af4, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x964db90c, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xe8c63470, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xd7103a46, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xeb56105d, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x5fc890c2, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x2b58ecef, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xb895daab, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x4dd9d7e9, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x55f57510, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xea1d5478, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0xb111dfac, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x9cfbf4e4, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        perpsv2proxyaudperp_i.addRoute(0x917e77f5, 0x7D0256E0936103b32AAD59E80257B59E988E75e2, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sAUDPERP", 300000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sAUDPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sAUDPERP", 600000000000000);
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

    function perpsv2marketstatenearperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatenearperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstatenearperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x779f424d3B3A617beB4a0DB1C21D5505De297a8A
        );
        perpsv2marketstatenearperplegacy_i.addAssociatedContracts(
            perpsv2marketstatenearperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0x699c039c9E21d49B8c38768619942dfaB6E8E38d
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0x3403A3430e4a62577e70fB48e070268D84a8F910
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstateaudperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstateaudperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstateaudperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0x6d62aA1535C7C33D7f6592562f091D193E180c57
        );
        perpsv2marketstateaudperplegacy_i.addAssociatedContracts(
            perpsv2marketstateaudperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x010a2f40B3b09FdBc60cb06f1b7F1a2A757d0eF2
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x0D8121E17b74e537286304c7804a5bC592A7964f
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
