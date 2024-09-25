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
contract Migration_CaphOptimismStep11 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x435e6e499610B6De3510F0Cb047D3575C7bca6E1
    PerpsV2MarketState public constant perpsv2marketstatesolperp_i =
        PerpsV2MarketState(0x435e6e499610B6De3510F0Cb047D3575C7bca6E1);
    // https://explorer.optimism.io/address/0x5da48D842542eF497ad68FAEd3480b3B1609Afe5
    PerpsV2MarketState public constant perpsv2marketstatesolperplegacy_i =
        PerpsV2MarketState(0x5da48D842542eF497ad68FAEd3480b3B1609Afe5);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D
    ProxyPerpsV2 public constant perpsv2proxysolperp_i = ProxyPerpsV2(0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xc564040630d6929070D85DF237FDf60F6bfE4b5F
    PerpsV2MarketState public constant perpsv2marketstatexauperp_i =
        PerpsV2MarketState(0xc564040630d6929070D85DF237FDf60F6bfE4b5F);
    // https://explorer.optimism.io/address/0x58e7da4Ee20f1De44F59D3Dd2640D5D844e443cF
    PerpsV2MarketState public constant perpsv2marketstatexauperplegacy_i =
        PerpsV2MarketState(0x58e7da4Ee20f1De44F59D3Dd2640D5D844e443cF);
    // https://explorer.optimism.io/address/0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A
    ProxyPerpsV2 public constant perpsv2proxyxauperp_i = ProxyPerpsV2(0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatesolperp_i);
        contracts[2] = address(perpsv2marketstatesolperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxysolperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstatexauperp_i);
        contracts[8] = address(perpsv2marketstatexauperplegacy_i);
        contracts[9] = address(perpsv2proxyxauperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstatesolperp_i.linkOrInitializeState();
        perpsv2marketstatesolperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxysolperp_i.addRoute(0xa126d601, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x5c8011c3, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x2af64bd3, 0xF715727ab8458C5792961a1EB944f97A67289A61, true);
        perpsv2proxysolperp_i.addRoute(0xd67bdd25, 0xF715727ab8458C5792961a1EB944f97A67289A61, true);
        perpsv2proxysolperp_i.addRoute(0x4ad4914b, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x32f05103, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0xec556889, 0xF715727ab8458C5792961a1EB944f97A67289A61, true);
        perpsv2proxysolperp_i.addRoute(0x4eb985cc, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0xbc67f832, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x97107d6d, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x88a3c848, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x5a1cbd2b, 0xF715727ab8458C5792961a1EB944f97A67289A61, false);
        perpsv2proxysolperp_i.addRoute(0x909bc379, 0x5c59426a609398A9753522E840F422faEDE70A5A, false);
        perpsv2proxysolperp_i.addRoute(0x3c92b8ec, 0x5c59426a609398A9753522E840F422faEDE70A5A, false);
        perpsv2proxysolperp_i.addRoute(0x7498a0f0, 0x5c59426a609398A9753522E840F422faEDE70A5A, false);
        perpsv2proxysolperp_i.addRoute(0xc5a4b07a, 0xA5BAff7D9928AE32C5e1ff441e4575951CB01111, false);
        perpsv2proxysolperp_i.addRoute(0xed44a2db, 0xA5BAff7D9928AE32C5e1ff441e4575951CB01111, false);
        perpsv2proxysolperp_i.addRoute(0x09461cfe, 0xA5BAff7D9928AE32C5e1ff441e4575951CB01111, false);
        perpsv2proxysolperp_i.addRoute(0x787d6c30, 0xA5BAff7D9928AE32C5e1ff441e4575951CB01111, false);
        perpsv2proxysolperp_i.addRoute(0xa1c35a35, 0xA5BAff7D9928AE32C5e1ff441e4575951CB01111, false);
        perpsv2proxysolperp_i.addRoute(0x85f05ab5, 0xA5BAff7D9928AE32C5e1ff441e4575951CB01111, false);
        perpsv2proxysolperp_i.addRoute(0xc70b41e9, 0x9A90C6FA8828baCD5B9eDD513F77bA7e4528C7E8, false);
        perpsv2proxysolperp_i.addRoute(0xdcce5806, 0x9A90C6FA8828baCD5B9eDD513F77bA7e4528C7E8, false);
        perpsv2proxysolperp_i.addRoute(0xa8300afb, 0x9A90C6FA8828baCD5B9eDD513F77bA7e4528C7E8, false);
        perpsv2proxysolperp_i.addRoute(0xdfa723cc, 0x9A90C6FA8828baCD5B9eDD513F77bA7e4528C7E8, false);
        perpsv2proxysolperp_i.addRoute(0x785cdeec, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x1bf556d0, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xd24378eb, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xcdf456e1, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xb9f4ff55, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x3aef4d0b, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xb74e3806, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xc8b809aa, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xea9f9aa7, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x27b9a236, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xe44c84c2, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x41108cf2, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xcded0cea, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xfef48a99, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xc8023af4, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x964db90c, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xe8c63470, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xd7103a46, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xeb56105d, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x5fc890c2, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x2b58ecef, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xb895daab, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x4dd9d7e9, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x55f57510, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xea1d5478, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0xb111dfac, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x9cfbf4e4, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        perpsv2proxysolperp_i.addRoute(0x917e77f5, 0xFaf84737Dae0DA0c093BC172e32FB845016Df642, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sSOLPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sSOLPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sSOLPERP", 4000000000000000);
        perpsv2marketstatexauperp_i.linkOrInitializeState();
        perpsv2marketstatexauperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyxauperp_i.addRoute(0xa126d601, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x5c8011c3, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x2af64bd3, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, true);
        perpsv2proxyxauperp_i.addRoute(0xd67bdd25, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, true);
        perpsv2proxyxauperp_i.addRoute(0x4ad4914b, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x32f05103, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0xec556889, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, true);
        perpsv2proxyxauperp_i.addRoute(0x4eb985cc, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0xbc67f832, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x97107d6d, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x88a3c848, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x5a1cbd2b, 0x9bb2fEaB8fDe79e48234C2d3Ea3F2568d08C42E2, false);
        perpsv2proxyxauperp_i.addRoute(0x909bc379, 0xa95e89d93A7432A2Ce9453ec4E264940a96B364b, false);
        perpsv2proxyxauperp_i.addRoute(0x3c92b8ec, 0xa95e89d93A7432A2Ce9453ec4E264940a96B364b, false);
        perpsv2proxyxauperp_i.addRoute(0x7498a0f0, 0xa95e89d93A7432A2Ce9453ec4E264940a96B364b, false);
        perpsv2proxyxauperp_i.addRoute(0xc5a4b07a, 0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6, false);
        perpsv2proxyxauperp_i.addRoute(0xed44a2db, 0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6, false);
        perpsv2proxyxauperp_i.addRoute(0x09461cfe, 0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6, false);
        perpsv2proxyxauperp_i.addRoute(0x787d6c30, 0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6, false);
        perpsv2proxyxauperp_i.addRoute(0xa1c35a35, 0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6, false);
        perpsv2proxyxauperp_i.addRoute(0x85f05ab5, 0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6, false);
        perpsv2proxyxauperp_i.addRoute(0xc70b41e9, 0x1a83bBccFaB68A8bF901c298c5dB5ACb8a2C7b05, false);
        perpsv2proxyxauperp_i.addRoute(0xdcce5806, 0x1a83bBccFaB68A8bF901c298c5dB5ACb8a2C7b05, false);
        perpsv2proxyxauperp_i.addRoute(0xa8300afb, 0x1a83bBccFaB68A8bF901c298c5dB5ACb8a2C7b05, false);
        perpsv2proxyxauperp_i.addRoute(0xdfa723cc, 0x1a83bBccFaB68A8bF901c298c5dB5ACb8a2C7b05, false);
        perpsv2proxyxauperp_i.addRoute(0x785cdeec, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x1bf556d0, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xd24378eb, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xcdf456e1, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xb9f4ff55, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x3aef4d0b, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xb74e3806, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xc8b809aa, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xea9f9aa7, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x27b9a236, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xe44c84c2, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x41108cf2, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xcded0cea, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xfef48a99, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xc8023af4, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x964db90c, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xe8c63470, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xd7103a46, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xeb56105d, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x5fc890c2, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x2b58ecef, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xb895daab, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x4dd9d7e9, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x55f57510, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xea1d5478, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0xb111dfac, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x9cfbf4e4, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        perpsv2proxyxauperp_i.addRoute(0x917e77f5, 0x9A3Ecffd8Cb317685EF0Df7B4aF5C4c9d1aF53eC, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sXAUPERP", 300000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sXAUPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sXAUPERP", 600000000000000);
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

    function perpsv2marketstatesolperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatesolperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstatesolperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x435e6e499610B6De3510F0Cb047D3575C7bca6E1
        );
        perpsv2marketstatesolperplegacy_i.addAssociatedContracts(
            perpsv2marketstatesolperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0xA5BAff7D9928AE32C5e1ff441e4575951CB01111
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0x9A90C6FA8828baCD5B9eDD513F77bA7e4528C7E8
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x0EA09D97b4084d859328ec4bF8eBCF9ecCA26F1D
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstatexauperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstatexauperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstatexauperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0xc564040630d6929070D85DF237FDf60F6bfE4b5F
        );
        perpsv2marketstatexauperplegacy_i.addAssociatedContracts(
            perpsv2marketstatexauperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x76c6C768ac45F0a3d266FF3e73257937Fc962FE6
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x1a83bBccFaB68A8bF901c298c5dB5ACb8a2C7b05
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x549dbDFfbd47bD5639f9348eBE82E63e2f9F777A
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
