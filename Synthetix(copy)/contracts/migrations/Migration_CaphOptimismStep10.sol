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
contract Migration_CaphOptimismStep10 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0xEed3618dd59163CC6849758F07fA9369823aa710
    PerpsV2MarketState public constant perpsv2marketstatelinkperp_i =
        PerpsV2MarketState(0xEed3618dd59163CC6849758F07fA9369823aa710);
    // https://explorer.optimism.io/address/0x49dC714eaD0cc585eBaC8A412098914a2CE7B7B2
    PerpsV2MarketState public constant perpsv2marketstatelinkperplegacy_i =
        PerpsV2MarketState(0x49dC714eaD0cc585eBaC8A412098914a2CE7B7B2);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A
    ProxyPerpsV2 public constant perpsv2proxylinkperp_i = ProxyPerpsV2(0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xBdD0D09f73AC6f8Ef59A71baab283C12dcab06fA
    PerpsV2MarketState public constant perpsv2marketstateopperp_i =
        PerpsV2MarketState(0xBdD0D09f73AC6f8Ef59A71baab283C12dcab06fA);
    // https://explorer.optimism.io/address/0xa26c97A0c9788e937986ee6276f3762c20C06ef5
    PerpsV2MarketState public constant perpsv2marketstateopperplegacy_i =
        PerpsV2MarketState(0xa26c97A0c9788e937986ee6276f3762c20C06ef5);
    // https://explorer.optimism.io/address/0x442b69937a0daf9D46439a71567fABE6Cb69FBaf
    ProxyPerpsV2 public constant perpsv2proxyopperp_i = ProxyPerpsV2(0x442b69937a0daf9D46439a71567fABE6Cb69FBaf);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstatelinkperp_i);
        contracts[2] = address(perpsv2marketstatelinkperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxylinkperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateopperp_i);
        contracts[8] = address(perpsv2marketstateopperplegacy_i);
        contracts[9] = address(perpsv2proxyopperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstatelinkperp_i.linkOrInitializeState();
        perpsv2marketstatelinkperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxylinkperp_i.addRoute(0xa126d601, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x5c8011c3, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x2af64bd3, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, true);
        perpsv2proxylinkperp_i.addRoute(0xd67bdd25, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, true);
        perpsv2proxylinkperp_i.addRoute(0x4ad4914b, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x32f05103, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0xec556889, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, true);
        perpsv2proxylinkperp_i.addRoute(0x4eb985cc, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0xbc67f832, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x97107d6d, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x88a3c848, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x5a1cbd2b, 0xD86e7B02cbaCb63eF6E91915205F7b122b8a8C3a, false);
        perpsv2proxylinkperp_i.addRoute(0x909bc379, 0x360Bc3aCB4fEA8112D8Ac20CE1E93b9B70C3d85a, false);
        perpsv2proxylinkperp_i.addRoute(0x3c92b8ec, 0x360Bc3aCB4fEA8112D8Ac20CE1E93b9B70C3d85a, false);
        perpsv2proxylinkperp_i.addRoute(0x7498a0f0, 0x360Bc3aCB4fEA8112D8Ac20CE1E93b9B70C3d85a, false);
        perpsv2proxylinkperp_i.addRoute(0xc5a4b07a, 0x560F562be696BaEfA0029c954cC69352bfb33e41, false);
        perpsv2proxylinkperp_i.addRoute(0xed44a2db, 0x560F562be696BaEfA0029c954cC69352bfb33e41, false);
        perpsv2proxylinkperp_i.addRoute(0x09461cfe, 0x560F562be696BaEfA0029c954cC69352bfb33e41, false);
        perpsv2proxylinkperp_i.addRoute(0x787d6c30, 0x560F562be696BaEfA0029c954cC69352bfb33e41, false);
        perpsv2proxylinkperp_i.addRoute(0xa1c35a35, 0x560F562be696BaEfA0029c954cC69352bfb33e41, false);
        perpsv2proxylinkperp_i.addRoute(0x85f05ab5, 0x560F562be696BaEfA0029c954cC69352bfb33e41, false);
        perpsv2proxylinkperp_i.addRoute(0xc70b41e9, 0xd3f1BDdC7F25eAfDB939d6B4f62Cb9d5b19d346F, false);
        perpsv2proxylinkperp_i.addRoute(0xdcce5806, 0xd3f1BDdC7F25eAfDB939d6B4f62Cb9d5b19d346F, false);
        perpsv2proxylinkperp_i.addRoute(0xa8300afb, 0xd3f1BDdC7F25eAfDB939d6B4f62Cb9d5b19d346F, false);
        perpsv2proxylinkperp_i.addRoute(0xdfa723cc, 0xd3f1BDdC7F25eAfDB939d6B4f62Cb9d5b19d346F, false);
        perpsv2proxylinkperp_i.addRoute(0x785cdeec, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x1bf556d0, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xd24378eb, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xcdf456e1, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xb9f4ff55, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x3aef4d0b, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xb74e3806, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xc8b809aa, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xea9f9aa7, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x27b9a236, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xe44c84c2, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x41108cf2, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xcded0cea, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xfef48a99, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xc8023af4, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x964db90c, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xe8c63470, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xd7103a46, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xeb56105d, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x5fc890c2, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x2b58ecef, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xb895daab, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x4dd9d7e9, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x55f57510, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xea1d5478, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0xb111dfac, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x9cfbf4e4, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        perpsv2proxylinkperp_i.addRoute(0x917e77f5, 0x2903C913BBbac9fBb6c4A080210cEd9EeC1f66a6, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sLINKPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sLINKPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sLINKPERP", 4000000000000000);
        perpsv2marketstateopperp_i.linkOrInitializeState();
        perpsv2marketstateopperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyopperp_i.addRoute(0xa126d601, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x5c8011c3, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x2af64bd3, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, true);
        perpsv2proxyopperp_i.addRoute(0xd67bdd25, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, true);
        perpsv2proxyopperp_i.addRoute(0x4ad4914b, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x32f05103, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0xec556889, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, true);
        perpsv2proxyopperp_i.addRoute(0x4eb985cc, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0xbc67f832, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x97107d6d, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x88a3c848, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x5a1cbd2b, 0x939d077817dFB5a6F87C89c4792842Ce91c7e5A0, false);
        perpsv2proxyopperp_i.addRoute(0x909bc379, 0xdD28261FC65c4Ed29b9D11aac0F44079cfCA4F32, false);
        perpsv2proxyopperp_i.addRoute(0x3c92b8ec, 0xdD28261FC65c4Ed29b9D11aac0F44079cfCA4F32, false);
        perpsv2proxyopperp_i.addRoute(0x7498a0f0, 0xdD28261FC65c4Ed29b9D11aac0F44079cfCA4F32, false);
        perpsv2proxyopperp_i.addRoute(0xc5a4b07a, 0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22, false);
        perpsv2proxyopperp_i.addRoute(0xed44a2db, 0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22, false);
        perpsv2proxyopperp_i.addRoute(0x09461cfe, 0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22, false);
        perpsv2proxyopperp_i.addRoute(0x787d6c30, 0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22, false);
        perpsv2proxyopperp_i.addRoute(0xa1c35a35, 0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22, false);
        perpsv2proxyopperp_i.addRoute(0x85f05ab5, 0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22, false);
        perpsv2proxyopperp_i.addRoute(0xc70b41e9, 0xbF1E06FaCb51B8A9223F266F303a88d3Dfc46226, false);
        perpsv2proxyopperp_i.addRoute(0xdcce5806, 0xbF1E06FaCb51B8A9223F266F303a88d3Dfc46226, false);
        perpsv2proxyopperp_i.addRoute(0xa8300afb, 0xbF1E06FaCb51B8A9223F266F303a88d3Dfc46226, false);
        perpsv2proxyopperp_i.addRoute(0xdfa723cc, 0xbF1E06FaCb51B8A9223F266F303a88d3Dfc46226, false);
        perpsv2proxyopperp_i.addRoute(0x785cdeec, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x1bf556d0, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xd24378eb, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xcdf456e1, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xb9f4ff55, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x3aef4d0b, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xb74e3806, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xc8b809aa, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xea9f9aa7, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x27b9a236, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xe44c84c2, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x41108cf2, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xcded0cea, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xfef48a99, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xc8023af4, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x964db90c, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xe8c63470, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xd7103a46, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xeb56105d, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x5fc890c2, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x2b58ecef, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xb895daab, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x4dd9d7e9, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x55f57510, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xea1d5478, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0xb111dfac, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x9cfbf4e4, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        perpsv2proxyopperp_i.addRoute(0x917e77f5, 0x2fffEBeD35931abD9014A39AE41fa26D511E31F4, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sOPPERP", 2500000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sOPPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sOPPERP", 5000000000000000);
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

    function perpsv2marketstatelinkperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstatelinkperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstatelinkperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0xEed3618dd59163CC6849758F07fA9369823aa710
        );
        perpsv2marketstatelinkperplegacy_i.addAssociatedContracts(
            perpsv2marketstatelinkperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0x560F562be696BaEfA0029c954cC69352bfb33e41
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0xd3f1BDdC7F25eAfDB939d6B4f62Cb9d5b19d346F
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x31A1659Ca00F617E86Dc765B6494Afe70a5A9c1A
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstateopperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstateopperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstateopperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0xBdD0D09f73AC6f8Ef59A71baab283C12dcab06fA
        );
        perpsv2marketstateopperplegacy_i.addAssociatedContracts(
            perpsv2marketstateopperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0xF9F70F783BE3ee6ebde9504BA0AC0730151b0a22
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0xbF1E06FaCb51B8A9223F266F303a88d3Dfc46226
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x442b69937a0daf9D46439a71567fABE6Cb69FBaf
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
