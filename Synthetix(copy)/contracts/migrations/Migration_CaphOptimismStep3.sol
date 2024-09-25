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
contract Migration_CaphOptimismStep3 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);
    // https://explorer.optimism.io/address/0x3773dfbbc894bfa9DF22855FCec1D1572eFC5e0a
    PerpsV2MarketState public constant perpsv2marketstateaaveperp_i =
        PerpsV2MarketState(0x3773dfbbc894bfa9DF22855FCec1D1572eFC5e0a);
    // https://explorer.optimism.io/address/0x9821CC43096b3F35744423C9B029854064dfe9Ab
    PerpsV2MarketState public constant perpsv2marketstateaaveperplegacy_i =
        PerpsV2MarketState(0x9821CC43096b3F35744423C9B029854064dfe9Ab);
    // https://explorer.optimism.io/address/0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04
    PerpsV2ExchangeRate public constant perpsv2exchangerate_i =
        PerpsV2ExchangeRate(0x2C15259D4886e2C0946f9aB7a5E389c86b3c3b04);
    // https://explorer.optimism.io/address/0x5374761526175B59f1E583246E20639909E189cE
    ProxyPerpsV2 public constant perpsv2proxyaaveperp_i = ProxyPerpsV2(0x5374761526175B59f1E583246E20639909E189cE);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x649F44CAC3276557D03223Dbf6395Af65b11c11c
    PerpsV2MarketSettings public constant perpsv2marketsettings_i =
        PerpsV2MarketSettings(0x649F44CAC3276557D03223Dbf6395Af65b11c11c);
    // https://explorer.optimism.io/address/0xECc8A6Af92d825ACC5B871993FC83d86CCEd5a19
    PerpsV2MarketState public constant perpsv2marketstateflowperp_i =
        PerpsV2MarketState(0xECc8A6Af92d825ACC5B871993FC83d86CCEd5a19);
    // https://explorer.optimism.io/address/0x49700Eb35841E9CD637B3352A26B7d685aDaFD94
    PerpsV2MarketState public constant perpsv2marketstateflowperplegacy_i =
        PerpsV2MarketState(0x49700Eb35841E9CD637B3352A26B7d685aDaFD94);
    // https://explorer.optimism.io/address/0x27665271210aCff4Fab08AD9Bb657E91866471F0
    ProxyPerpsV2 public constant perpsv2proxyflowperp_i = ProxyPerpsV2(0x27665271210aCff4Fab08AD9Bb657E91866471F0);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0] = address(systemstatus_i);
        contracts[1] = address(perpsv2marketstateaaveperp_i);
        contracts[2] = address(perpsv2marketstateaaveperplegacy_i);
        contracts[3] = address(perpsv2exchangerate_i);
        contracts[4] = address(perpsv2proxyaaveperp_i);
        contracts[5] = address(futuresmarketmanager_i);
        contracts[6] = address(perpsv2marketsettings_i);
        contracts[7] = address(perpsv2marketstateflowperp_i);
        contracts[8] = address(perpsv2marketstateflowperplegacy_i);
        contracts[9] = address(perpsv2proxyflowperp_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        systemstatus_i.updateAccessControl("Futures", address(this), true, true);
        perpsv2marketstateaaveperp_i.linkOrInitializeState();
        perpsv2marketstateaaveperplegacy_addAssociatedContracts_2();
        perpsv2exchangerate_addAssociatedContracts_3();
        perpsv2proxyaaveperp_i.addRoute(0xa126d601, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x5c8011c3, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x2af64bd3, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, true);
        perpsv2proxyaaveperp_i.addRoute(0xd67bdd25, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, true);
        perpsv2proxyaaveperp_i.addRoute(0x4ad4914b, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x32f05103, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0xec556889, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, true);
        perpsv2proxyaaveperp_i.addRoute(0x4eb985cc, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0xbc67f832, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x97107d6d, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x88a3c848, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x5a1cbd2b, 0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7, false);
        perpsv2proxyaaveperp_i.addRoute(0x909bc379, 0x34830e0959FdEebB0F3C8c463AFE064f210DbDDf, false);
        perpsv2proxyaaveperp_i.addRoute(0x3c92b8ec, 0x34830e0959FdEebB0F3C8c463AFE064f210DbDDf, false);
        perpsv2proxyaaveperp_i.addRoute(0x7498a0f0, 0x34830e0959FdEebB0F3C8c463AFE064f210DbDDf, false);
        perpsv2proxyaaveperp_i.addRoute(0xc5a4b07a, 0xc4786C4484C06bD463f124EBeF2175f67759EA1A, false);
        perpsv2proxyaaveperp_i.addRoute(0xed44a2db, 0xc4786C4484C06bD463f124EBeF2175f67759EA1A, false);
        perpsv2proxyaaveperp_i.addRoute(0x09461cfe, 0xc4786C4484C06bD463f124EBeF2175f67759EA1A, false);
        perpsv2proxyaaveperp_i.addRoute(0x787d6c30, 0xc4786C4484C06bD463f124EBeF2175f67759EA1A, false);
        perpsv2proxyaaveperp_i.addRoute(0xa1c35a35, 0xc4786C4484C06bD463f124EBeF2175f67759EA1A, false);
        perpsv2proxyaaveperp_i.addRoute(0x85f05ab5, 0xc4786C4484C06bD463f124EBeF2175f67759EA1A, false);
        perpsv2proxyaaveperp_i.addRoute(0xc70b41e9, 0xf73fA296DF4C46b7182B14AC7862f6E08Da84150, false);
        perpsv2proxyaaveperp_i.addRoute(0xdcce5806, 0xf73fA296DF4C46b7182B14AC7862f6E08Da84150, false);
        perpsv2proxyaaveperp_i.addRoute(0xa8300afb, 0xf73fA296DF4C46b7182B14AC7862f6E08Da84150, false);
        perpsv2proxyaaveperp_i.addRoute(0xdfa723cc, 0xf73fA296DF4C46b7182B14AC7862f6E08Da84150, false);
        perpsv2proxyaaveperp_i.addRoute(0x785cdeec, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x1bf556d0, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xd24378eb, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xcdf456e1, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xb9f4ff55, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x3aef4d0b, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xb74e3806, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xc8b809aa, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xea9f9aa7, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x27b9a236, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xe44c84c2, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x41108cf2, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xcded0cea, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xfef48a99, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xc8023af4, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x964db90c, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xe8c63470, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xd7103a46, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xeb56105d, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x5fc890c2, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x2b58ecef, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xb895daab, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x4dd9d7e9, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x55f57510, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xea1d5478, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0xb111dfac, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x9cfbf4e4, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        perpsv2proxyaaveperp_i.addRoute(0x917e77f5, 0x619676Df5C402D0eb008104e9a658C1F65DBF702, true);
        futuresmarketmanager_updateMarketsImplementations_57();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sAAVEPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sAAVEPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sAAVEPERP", 4000000000000000);
        perpsv2marketstateflowperp_i.linkOrInitializeState();
        perpsv2marketstateflowperplegacy_addAssociatedContracts_62();
        perpsv2exchangerate_addAssociatedContracts_63();
        perpsv2proxyflowperp_i.addRoute(0xa126d601, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x5c8011c3, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x2af64bd3, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, true);
        perpsv2proxyflowperp_i.addRoute(0xd67bdd25, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, true);
        perpsv2proxyflowperp_i.addRoute(0x4ad4914b, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x32f05103, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0xec556889, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, true);
        perpsv2proxyflowperp_i.addRoute(0x4eb985cc, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0xbc67f832, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x97107d6d, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x88a3c848, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x5a1cbd2b, 0x16f7332ECEC126F8Bcd791887D6c576F35525f2B, false);
        perpsv2proxyflowperp_i.addRoute(0x909bc379, 0x773098F036FcfFC88Cd5d347821ea2f8312CC12F, false);
        perpsv2proxyflowperp_i.addRoute(0x3c92b8ec, 0x773098F036FcfFC88Cd5d347821ea2f8312CC12F, false);
        perpsv2proxyflowperp_i.addRoute(0x7498a0f0, 0x773098F036FcfFC88Cd5d347821ea2f8312CC12F, false);
        perpsv2proxyflowperp_i.addRoute(0xc5a4b07a, 0x81b5c28e3905233bc4B96B182160593779d2CB83, false);
        perpsv2proxyflowperp_i.addRoute(0xed44a2db, 0x81b5c28e3905233bc4B96B182160593779d2CB83, false);
        perpsv2proxyflowperp_i.addRoute(0x09461cfe, 0x81b5c28e3905233bc4B96B182160593779d2CB83, false);
        perpsv2proxyflowperp_i.addRoute(0x787d6c30, 0x81b5c28e3905233bc4B96B182160593779d2CB83, false);
        perpsv2proxyflowperp_i.addRoute(0xa1c35a35, 0x81b5c28e3905233bc4B96B182160593779d2CB83, false);
        perpsv2proxyflowperp_i.addRoute(0x85f05ab5, 0x81b5c28e3905233bc4B96B182160593779d2CB83, false);
        perpsv2proxyflowperp_i.addRoute(0xc70b41e9, 0x19BA5013824a45Ee0F9E4738c8618d40bA11234a, false);
        perpsv2proxyflowperp_i.addRoute(0xdcce5806, 0x19BA5013824a45Ee0F9E4738c8618d40bA11234a, false);
        perpsv2proxyflowperp_i.addRoute(0xa8300afb, 0x19BA5013824a45Ee0F9E4738c8618d40bA11234a, false);
        perpsv2proxyflowperp_i.addRoute(0xdfa723cc, 0x19BA5013824a45Ee0F9E4738c8618d40bA11234a, false);
        perpsv2proxyflowperp_i.addRoute(0x785cdeec, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x1bf556d0, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xd24378eb, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xcdf456e1, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xb9f4ff55, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x3aef4d0b, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xb74e3806, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xc8b809aa, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xea9f9aa7, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x27b9a236, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xe44c84c2, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x41108cf2, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xcded0cea, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xfef48a99, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xc8023af4, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x964db90c, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xe8c63470, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xd7103a46, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xeb56105d, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x5fc890c2, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x2b58ecef, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xb895daab, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x4dd9d7e9, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x55f57510, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xea1d5478, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0xb111dfac, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x9cfbf4e4, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        perpsv2proxyflowperp_i.addRoute(0x917e77f5, 0x73d8fD1dC5E38cEF6754Fc5009015CaaEE218461, true);
        futuresmarketmanager_updateMarketsImplementations_117();
        perpsv2marketsettings_i.setMaxLiquidationDelta("sFLOWPERP", 2000000000000000);
        perpsv2marketsettings_i.setLiquidationBufferRatio("sFLOWPERP", 10000000000000000);
        perpsv2marketsettings_i.setMaxPD("sFLOWPERP", 4000000000000000);
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

    function perpsv2marketstateaaveperplegacy_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateaaveperplegacy_addAssociatedContracts_associatedContracts_2_0 = new address[](1);
        perpsv2marketstateaaveperplegacy_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x3773dfbbc894bfa9DF22855FCec1D1572eFC5e0a
        );
        perpsv2marketstateaaveperplegacy_i.addAssociatedContracts(
            perpsv2marketstateaaveperplegacy_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_3() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[0] = address(
            0xc4786C4484C06bD463f124EBeF2175f67759EA1A
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0[1] = address(
            0xf73fA296DF4C46b7182B14AC7862f6E08Da84150
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_3_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_57() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0[0] = address(
            0x5374761526175B59f1E583246E20639909E189cE
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_57_0
        );
    }

    function perpsv2marketstateflowperplegacy_addAssociatedContracts_62() internal {
        address[] memory perpsv2marketstateflowperplegacy_addAssociatedContracts_associatedContracts_62_0 = new address[](1);
        perpsv2marketstateflowperplegacy_addAssociatedContracts_associatedContracts_62_0[0] = address(
            0xECc8A6Af92d825ACC5B871993FC83d86CCEd5a19
        );
        perpsv2marketstateflowperplegacy_i.addAssociatedContracts(
            perpsv2marketstateflowperplegacy_addAssociatedContracts_associatedContracts_62_0
        );
    }

    function perpsv2exchangerate_addAssociatedContracts_63() internal {
        address[] memory perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0 = new address[](2);
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[0] = address(
            0x81b5c28e3905233bc4B96B182160593779d2CB83
        );
        perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0[1] = address(
            0x19BA5013824a45Ee0F9E4738c8618d40bA11234a
        );
        perpsv2exchangerate_i.addAssociatedContracts(perpsv2exchangerate_addAssociatedContracts_associatedContracts_63_0);
    }

    function futuresmarketmanager_updateMarketsImplementations_117() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0[0] = address(
            0x27665271210aCff4Fab08AD9Bb657E91866471F0
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_117_0
        );
    }
}
