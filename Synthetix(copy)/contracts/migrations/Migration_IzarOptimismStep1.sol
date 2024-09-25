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
import "../PerpsV2MarketState.sol";
import "../ProxyPerpsV2.sol";
import "../FuturesMarketManager.sol";
import "../SystemStatus.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_IzarOptimismStep1 is BaseMigration {
    // https://explorer.optimism.io/address/0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;
    address public constant OWNER = 0x6d4a64C57612841c2C6745dB2a4E4db34F002D20;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://explorer.optimism.io/address/0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C
    AddressResolver public constant addressresolver_i = AddressResolver(0x95A6a3f44a70172E7d50a9e28c85Dfd712756B8C);
    // https://explorer.optimism.io/address/0x3773dfbbc894bfa9DF22855FCec1D1572eFC5e0a
    PerpsV2MarketState public constant perpsv2marketstateaaveperp_i =
        PerpsV2MarketState(0x3773dfbbc894bfa9DF22855FCec1D1572eFC5e0a);
    // https://explorer.optimism.io/address/0x5374761526175B59f1E583246E20639909E189cE
    ProxyPerpsV2 public constant perpsv2proxyaaveperp_i = ProxyPerpsV2(0x5374761526175B59f1E583246E20639909E189cE);
    // https://explorer.optimism.io/address/0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463
    FuturesMarketManager public constant futuresmarketmanager_i =
        FuturesMarketManager(0xd30bdFd7e7a65fE109D5dE1D4e95F3B800FB7463);
    // https://explorer.optimism.io/address/0x28E1CE29aCdFe1E74e6fA18591E1D5481D2085a1
    PerpsV2MarketState public constant perpsv2marketstatexagperp_i =
        PerpsV2MarketState(0x28E1CE29aCdFe1E74e6fA18591E1D5481D2085a1);
    // https://explorer.optimism.io/address/0xdcB8438c979fA030581314e5A5Df42bbFEd744a0
    ProxyPerpsV2 public constant perpsv2proxyxagperp_i = ProxyPerpsV2(0xdcB8438c979fA030581314e5A5Df42bbFEd744a0);
    // https://explorer.optimism.io/address/0xECc8A6Af92d825ACC5B871993FC83d86CCEd5a19
    PerpsV2MarketState public constant perpsv2marketstateflowperp_i =
        PerpsV2MarketState(0xECc8A6Af92d825ACC5B871993FC83d86CCEd5a19);
    // https://explorer.optimism.io/address/0x27665271210aCff4Fab08AD9Bb657E91866471F0
    ProxyPerpsV2 public constant perpsv2proxyflowperp_i = ProxyPerpsV2(0x27665271210aCff4Fab08AD9Bb657E91866471F0);
    // https://explorer.optimism.io/address/0x779f424d3B3A617beB4a0DB1C21D5505De297a8A
    PerpsV2MarketState public constant perpsv2marketstatenearperp_i =
        PerpsV2MarketState(0x779f424d3B3A617beB4a0DB1C21D5505De297a8A);
    // https://explorer.optimism.io/address/0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe
    ProxyPerpsV2 public constant perpsv2proxynearperp_i = ProxyPerpsV2(0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe);
    // https://explorer.optimism.io/address/0x6d62aA1535C7C33D7f6592562f091D193E180c57
    PerpsV2MarketState public constant perpsv2marketstateaudperp_i =
        PerpsV2MarketState(0x6d62aA1535C7C33D7f6592562f091D193E180c57);
    // https://explorer.optimism.io/address/0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99
    ProxyPerpsV2 public constant perpsv2proxyaudperp_i = ProxyPerpsV2(0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99);
    // https://explorer.optimism.io/address/0x733a69D080B10Bc897452eF783020cdFe012974A
    PerpsV2MarketState public constant perpsv2marketstategbpperp_i =
        PerpsV2MarketState(0x733a69D080B10Bc897452eF783020cdFe012974A);
    // https://explorer.optimism.io/address/0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49
    ProxyPerpsV2 public constant perpsv2proxygbpperp_i = ProxyPerpsV2(0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49);
    // https://explorer.optimism.io/address/0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD
    SystemStatus public constant systemstatus_i = SystemStatus(0xE8c41bE1A167314ABAF2423b72Bf8da826943FFD);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://explorer.optimism.io/address/0x340B5d664834113735730Ad4aFb3760219Ad9112
    address public constant new_PerpsV2MarketData_contract = 0x340B5d664834113735730Ad4aFb3760219Ad9112;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](15);
        contracts[0] = address(addressresolver_i);
        contracts[1] = address(perpsv2marketstateaaveperp_i);
        contracts[2] = address(perpsv2proxyaaveperp_i);
        contracts[3] = address(futuresmarketmanager_i);
        contracts[4] = address(perpsv2marketstatexagperp_i);
        contracts[5] = address(perpsv2proxyxagperp_i);
        contracts[6] = address(perpsv2marketstateflowperp_i);
        contracts[7] = address(perpsv2proxyflowperp_i);
        contracts[8] = address(perpsv2marketstatenearperp_i);
        contracts[9] = address(perpsv2proxynearperp_i);
        contracts[10] = address(perpsv2marketstateaudperp_i);
        contracts[11] = address(perpsv2proxyaudperp_i);
        contracts[12] = address(perpsv2marketstategbpperp_i);
        contracts[13] = address(perpsv2proxygbpperp_i);
        contracts[14] = address(systemstatus_i);
    }

    function migrate() external onlyOwner {
        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        perpsv2marketstateaaveperp_removeAssociatedContracts_1();
        perpsv2marketstateaaveperp_addAssociatedContracts_2();
        perpsv2proxyaaveperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyaaveperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyaaveperp_i.removeRoute(0xec556889);
        perpsv2proxyaaveperp_i.removeRoute(0xbc67f832);
        perpsv2proxyaaveperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketAAVEPERP.closePosition;
        perpsv2proxyaaveperp_i.addRoute(0xa126d601, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketAAVEPERP.closePositionWithTracking;
        perpsv2proxyaaveperp_i.addRoute(0x5c8011c3, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketAAVEPERP.modifyPosition;
        perpsv2proxyaaveperp_i.addRoute(0x4ad4914b, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketAAVEPERP.modifyPositionWithTracking;
        perpsv2proxyaaveperp_i.addRoute(0x32f05103, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketAAVEPERP.recomputeFunding;
        perpsv2proxyaaveperp_i.addRoute(0x4eb985cc, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketAAVEPERP.transferMargin;
        perpsv2proxyaaveperp_i.addRoute(0x88a3c848, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketAAVEPERP.withdrawAllMargin;
        perpsv2proxyaaveperp_i.addRoute(0x5a1cbd2b, 0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119, false);
        // Add route to PerpsV2MarketLiquidateAAVEPERP.flagPosition;
        perpsv2proxyaaveperp_i.addRoute(0x909bc379, 0xFCce7f97100C0Bdd63c3d53ce0Ac35bE1F900a5e, false);
        // Add route to PerpsV2MarketLiquidateAAVEPERP.forceLiquidatePosition;
        perpsv2proxyaaveperp_i.addRoute(0x3c92b8ec, 0xFCce7f97100C0Bdd63c3d53ce0Ac35bE1F900a5e, false);
        // Add route to PerpsV2MarketLiquidateAAVEPERP.liquidatePosition;
        perpsv2proxyaaveperp_i.addRoute(0x7498a0f0, 0xFCce7f97100C0Bdd63c3d53ce0Ac35bE1F900a5e, false);
        futuresmarketmanager_updateMarketsImplementations_18();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_19();
        perpsv2marketstatexagperp_removeAssociatedContracts_20();
        perpsv2marketstatexagperp_addAssociatedContracts_21();
        perpsv2proxyxagperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyxagperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyxagperp_i.removeRoute(0xec556889);
        perpsv2proxyxagperp_i.removeRoute(0xbc67f832);
        perpsv2proxyxagperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketXAGPERP.closePosition;
        perpsv2proxyxagperp_i.addRoute(0xa126d601, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketXAGPERP.closePositionWithTracking;
        perpsv2proxyxagperp_i.addRoute(0x5c8011c3, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketXAGPERP.modifyPosition;
        perpsv2proxyxagperp_i.addRoute(0x4ad4914b, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketXAGPERP.modifyPositionWithTracking;
        perpsv2proxyxagperp_i.addRoute(0x32f05103, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketXAGPERP.recomputeFunding;
        perpsv2proxyxagperp_i.addRoute(0x4eb985cc, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketXAGPERP.transferMargin;
        perpsv2proxyxagperp_i.addRoute(0x88a3c848, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketXAGPERP.withdrawAllMargin;
        perpsv2proxyxagperp_i.addRoute(0x5a1cbd2b, 0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3, false);
        // Add route to PerpsV2MarketLiquidateXAGPERP.flagPosition;
        perpsv2proxyxagperp_i.addRoute(0x909bc379, 0x35B9D048d4CB99bB34d59fBF962E86B8Ee44760F, false);
        // Add route to PerpsV2MarketLiquidateXAGPERP.forceLiquidatePosition;
        perpsv2proxyxagperp_i.addRoute(0x3c92b8ec, 0x35B9D048d4CB99bB34d59fBF962E86B8Ee44760F, false);
        // Add route to PerpsV2MarketLiquidateXAGPERP.liquidatePosition;
        perpsv2proxyxagperp_i.addRoute(0x7498a0f0, 0x35B9D048d4CB99bB34d59fBF962E86B8Ee44760F, false);
        futuresmarketmanager_updateMarketsImplementations_37();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_38();
        perpsv2marketstateflowperp_removeAssociatedContracts_39();
        perpsv2marketstateflowperp_addAssociatedContracts_40();
        perpsv2proxyflowperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyflowperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyflowperp_i.removeRoute(0xec556889);
        perpsv2proxyflowperp_i.removeRoute(0xbc67f832);
        perpsv2proxyflowperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketFLOWPERP.closePosition;
        perpsv2proxyflowperp_i.addRoute(0xa126d601, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketFLOWPERP.closePositionWithTracking;
        perpsv2proxyflowperp_i.addRoute(0x5c8011c3, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketFLOWPERP.modifyPosition;
        perpsv2proxyflowperp_i.addRoute(0x4ad4914b, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketFLOWPERP.modifyPositionWithTracking;
        perpsv2proxyflowperp_i.addRoute(0x32f05103, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketFLOWPERP.recomputeFunding;
        perpsv2proxyflowperp_i.addRoute(0x4eb985cc, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketFLOWPERP.transferMargin;
        perpsv2proxyflowperp_i.addRoute(0x88a3c848, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketFLOWPERP.withdrawAllMargin;
        perpsv2proxyflowperp_i.addRoute(0x5a1cbd2b, 0x661c2479BffE01eB99EeC9169149BaA5DAbeB883, false);
        // Add route to PerpsV2MarketLiquidateFLOWPERP.flagPosition;
        perpsv2proxyflowperp_i.addRoute(0x909bc379, 0xdACBFD99Bb915739B58ac9312c78A23ACbACB6Db, false);
        // Add route to PerpsV2MarketLiquidateFLOWPERP.forceLiquidatePosition;
        perpsv2proxyflowperp_i.addRoute(0x3c92b8ec, 0xdACBFD99Bb915739B58ac9312c78A23ACbACB6Db, false);
        // Add route to PerpsV2MarketLiquidateFLOWPERP.liquidatePosition;
        perpsv2proxyflowperp_i.addRoute(0x7498a0f0, 0xdACBFD99Bb915739B58ac9312c78A23ACbACB6Db, false);
        futuresmarketmanager_updateMarketsImplementations_56();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_57();
        perpsv2marketstatenearperp_removeAssociatedContracts_58();
        perpsv2marketstatenearperp_addAssociatedContracts_59();
        perpsv2proxynearperp_i.removeRoute(0x2af64bd3);
        perpsv2proxynearperp_i.removeRoute(0xd67bdd25);
        perpsv2proxynearperp_i.removeRoute(0xec556889);
        perpsv2proxynearperp_i.removeRoute(0xbc67f832);
        perpsv2proxynearperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketNEARPERP.closePosition;
        perpsv2proxynearperp_i.addRoute(0xa126d601, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketNEARPERP.closePositionWithTracking;
        perpsv2proxynearperp_i.addRoute(0x5c8011c3, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketNEARPERP.modifyPosition;
        perpsv2proxynearperp_i.addRoute(0x4ad4914b, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketNEARPERP.modifyPositionWithTracking;
        perpsv2proxynearperp_i.addRoute(0x32f05103, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketNEARPERP.recomputeFunding;
        perpsv2proxynearperp_i.addRoute(0x4eb985cc, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketNEARPERP.transferMargin;
        perpsv2proxynearperp_i.addRoute(0x88a3c848, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketNEARPERP.withdrawAllMargin;
        perpsv2proxynearperp_i.addRoute(0x5a1cbd2b, 0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56, false);
        // Add route to PerpsV2MarketLiquidateNEARPERP.flagPosition;
        perpsv2proxynearperp_i.addRoute(0x909bc379, 0x767F446FbD3F2e5c91292D9FA51a44102a89117d, false);
        // Add route to PerpsV2MarketLiquidateNEARPERP.forceLiquidatePosition;
        perpsv2proxynearperp_i.addRoute(0x3c92b8ec, 0x767F446FbD3F2e5c91292D9FA51a44102a89117d, false);
        // Add route to PerpsV2MarketLiquidateNEARPERP.liquidatePosition;
        perpsv2proxynearperp_i.addRoute(0x7498a0f0, 0x767F446FbD3F2e5c91292D9FA51a44102a89117d, false);
        futuresmarketmanager_updateMarketsImplementations_75();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_76();
        perpsv2marketstateaudperp_removeAssociatedContracts_77();
        perpsv2marketstateaudperp_addAssociatedContracts_78();
        perpsv2proxyaudperp_i.removeRoute(0x2af64bd3);
        perpsv2proxyaudperp_i.removeRoute(0xd67bdd25);
        perpsv2proxyaudperp_i.removeRoute(0xec556889);
        perpsv2proxyaudperp_i.removeRoute(0xbc67f832);
        perpsv2proxyaudperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketAUDPERP.closePosition;
        perpsv2proxyaudperp_i.addRoute(0xa126d601, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketAUDPERP.closePositionWithTracking;
        perpsv2proxyaudperp_i.addRoute(0x5c8011c3, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketAUDPERP.modifyPosition;
        perpsv2proxyaudperp_i.addRoute(0x4ad4914b, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketAUDPERP.modifyPositionWithTracking;
        perpsv2proxyaudperp_i.addRoute(0x32f05103, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketAUDPERP.recomputeFunding;
        perpsv2proxyaudperp_i.addRoute(0x4eb985cc, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketAUDPERP.transferMargin;
        perpsv2proxyaudperp_i.addRoute(0x88a3c848, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketAUDPERP.withdrawAllMargin;
        perpsv2proxyaudperp_i.addRoute(0x5a1cbd2b, 0xAF89069dC03d65C1b3091D770a8D3b4D02126849, false);
        // Add route to PerpsV2MarketLiquidateAUDPERP.flagPosition;
        perpsv2proxyaudperp_i.addRoute(0x909bc379, 0xd1b73C8251acf068ea03A42177bD1E3F610F9fB4, false);
        // Add route to PerpsV2MarketLiquidateAUDPERP.forceLiquidatePosition;
        perpsv2proxyaudperp_i.addRoute(0x3c92b8ec, 0xd1b73C8251acf068ea03A42177bD1E3F610F9fB4, false);
        // Add route to PerpsV2MarketLiquidateAUDPERP.liquidatePosition;
        perpsv2proxyaudperp_i.addRoute(0x7498a0f0, 0xd1b73C8251acf068ea03A42177bD1E3F610F9fB4, false);
        futuresmarketmanager_updateMarketsImplementations_94();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_95();
        perpsv2marketstategbpperp_removeAssociatedContracts_96();
        perpsv2marketstategbpperp_addAssociatedContracts_97();
        perpsv2proxygbpperp_i.removeRoute(0x2af64bd3);
        perpsv2proxygbpperp_i.removeRoute(0xd67bdd25);
        perpsv2proxygbpperp_i.removeRoute(0xec556889);
        perpsv2proxygbpperp_i.removeRoute(0xbc67f832);
        perpsv2proxygbpperp_i.removeRoute(0x97107d6d);
        // Add route to PerpsV2MarketGBPPERP.closePosition;
        perpsv2proxygbpperp_i.addRoute(0xa126d601, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketGBPPERP.closePositionWithTracking;
        perpsv2proxygbpperp_i.addRoute(0x5c8011c3, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketGBPPERP.modifyPosition;
        perpsv2proxygbpperp_i.addRoute(0x4ad4914b, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketGBPPERP.modifyPositionWithTracking;
        perpsv2proxygbpperp_i.addRoute(0x32f05103, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketGBPPERP.recomputeFunding;
        perpsv2proxygbpperp_i.addRoute(0x4eb985cc, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketGBPPERP.transferMargin;
        perpsv2proxygbpperp_i.addRoute(0x88a3c848, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketGBPPERP.withdrawAllMargin;
        perpsv2proxygbpperp_i.addRoute(0x5a1cbd2b, 0x7690Af487c06674785daEF91EF6576464B46D249, false);
        // Add route to PerpsV2MarketLiquidateGBPPERP.flagPosition;
        perpsv2proxygbpperp_i.addRoute(0x909bc379, 0x6cb4EEcE70eF0eB8E7f81f4A0dE0FB1521E77F74, false);
        // Add route to PerpsV2MarketLiquidateGBPPERP.forceLiquidatePosition;
        perpsv2proxygbpperp_i.addRoute(0x3c92b8ec, 0x6cb4EEcE70eF0eB8E7f81f4A0dE0FB1521E77F74, false);
        // Add route to PerpsV2MarketLiquidateGBPPERP.liquidatePosition;
        perpsv2proxygbpperp_i.addRoute(0x7498a0f0, 0x6cb4EEcE70eF0eB8E7f81f4A0dE0FB1521E77F74, false);
        futuresmarketmanager_updateMarketsImplementations_113();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_114();
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_116();

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
        bytes32[] memory addressresolver_importAddresses_names_0_0 = new bytes32[](1);
        addressresolver_importAddresses_names_0_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_0_1 = new address[](1);
        addressresolver_importAddresses_destinations_0_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_0_0,
            addressresolver_importAddresses_destinations_0_1
        );
    }

    function perpsv2marketstateaaveperp_removeAssociatedContracts_1() internal {
        address[] memory perpsv2marketstateaaveperp_removeAssociatedContracts_associatedContracts_1_0 = new address[](2);
        perpsv2marketstateaaveperp_removeAssociatedContracts_associatedContracts_1_0[0] = address(
            0xB6E1BAb2E6349942aB472eF5C9456019b85dD5C7
        );
        perpsv2marketstateaaveperp_removeAssociatedContracts_associatedContracts_1_0[1] = address(
            0x34830e0959FdEebB0F3C8c463AFE064f210DbDDf
        );
        perpsv2marketstateaaveperp_i.removeAssociatedContracts(
            perpsv2marketstateaaveperp_removeAssociatedContracts_associatedContracts_1_0
        );
    }

    function perpsv2marketstateaaveperp_addAssociatedContracts_2() internal {
        address[] memory perpsv2marketstateaaveperp_addAssociatedContracts_associatedContracts_2_0 = new address[](2);
        perpsv2marketstateaaveperp_addAssociatedContracts_associatedContracts_2_0[0] = address(
            0x42AAa33a13bDac31D8B9e04D9d5Db7F9FC8C0119
        );
        perpsv2marketstateaaveperp_addAssociatedContracts_associatedContracts_2_0[1] = address(
            0xFCce7f97100C0Bdd63c3d53ce0Ac35bE1F900a5e
        );
        perpsv2marketstateaaveperp_i.addAssociatedContracts(
            perpsv2marketstateaaveperp_addAssociatedContracts_associatedContracts_2_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_18() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0[0] = address(
            0x5374761526175B59f1E583246E20639909E189cE
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_18_0
        );
    }

    function addressresolver_importAddresses_19() internal {
        bytes32[] memory addressresolver_importAddresses_names_19_0 = new bytes32[](1);
        addressresolver_importAddresses_names_19_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_19_1 = new address[](1);
        addressresolver_importAddresses_destinations_19_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_19_0,
            addressresolver_importAddresses_destinations_19_1
        );
    }

    function perpsv2marketstatexagperp_removeAssociatedContracts_20() internal {
        address[] memory perpsv2marketstatexagperp_removeAssociatedContracts_associatedContracts_20_0 = new address[](2);
        perpsv2marketstatexagperp_removeAssociatedContracts_associatedContracts_20_0[0] = address(
            0x00751b4cceF0800bB4FA33B685363D4cFf1A981E
        );
        perpsv2marketstatexagperp_removeAssociatedContracts_associatedContracts_20_0[1] = address(
            0x35BFC780c232171B5830A76632a70821c1A1b087
        );
        perpsv2marketstatexagperp_i.removeAssociatedContracts(
            perpsv2marketstatexagperp_removeAssociatedContracts_associatedContracts_20_0
        );
    }

    function perpsv2marketstatexagperp_addAssociatedContracts_21() internal {
        address[] memory perpsv2marketstatexagperp_addAssociatedContracts_associatedContracts_21_0 = new address[](2);
        perpsv2marketstatexagperp_addAssociatedContracts_associatedContracts_21_0[0] = address(
            0xe0D10647D92749Da9bd5c250dF2EEF2e4110a8c3
        );
        perpsv2marketstatexagperp_addAssociatedContracts_associatedContracts_21_0[1] = address(
            0x35B9D048d4CB99bB34d59fBF962E86B8Ee44760F
        );
        perpsv2marketstatexagperp_i.addAssociatedContracts(
            perpsv2marketstatexagperp_addAssociatedContracts_associatedContracts_21_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_37() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0[0] = address(
            0xdcB8438c979fA030581314e5A5Df42bbFEd744a0
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_37_0
        );
    }

    function addressresolver_importAddresses_38() internal {
        bytes32[] memory addressresolver_importAddresses_names_38_0 = new bytes32[](1);
        addressresolver_importAddresses_names_38_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_38_1 = new address[](1);
        addressresolver_importAddresses_destinations_38_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_38_0,
            addressresolver_importAddresses_destinations_38_1
        );
    }

    function perpsv2marketstateflowperp_removeAssociatedContracts_39() internal {
        address[] memory perpsv2marketstateflowperp_removeAssociatedContracts_associatedContracts_39_0 = new address[](2);
        perpsv2marketstateflowperp_removeAssociatedContracts_associatedContracts_39_0[0] = address(
            0x16f7332ECEC126F8Bcd791887D6c576F35525f2B
        );
        perpsv2marketstateflowperp_removeAssociatedContracts_associatedContracts_39_0[1] = address(
            0x773098F036FcfFC88Cd5d347821ea2f8312CC12F
        );
        perpsv2marketstateflowperp_i.removeAssociatedContracts(
            perpsv2marketstateflowperp_removeAssociatedContracts_associatedContracts_39_0
        );
    }

    function perpsv2marketstateflowperp_addAssociatedContracts_40() internal {
        address[] memory perpsv2marketstateflowperp_addAssociatedContracts_associatedContracts_40_0 = new address[](2);
        perpsv2marketstateflowperp_addAssociatedContracts_associatedContracts_40_0[0] = address(
            0x661c2479BffE01eB99EeC9169149BaA5DAbeB883
        );
        perpsv2marketstateflowperp_addAssociatedContracts_associatedContracts_40_0[1] = address(
            0xdACBFD99Bb915739B58ac9312c78A23ACbACB6Db
        );
        perpsv2marketstateflowperp_i.addAssociatedContracts(
            perpsv2marketstateflowperp_addAssociatedContracts_associatedContracts_40_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_56() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0[0] = address(
            0x27665271210aCff4Fab08AD9Bb657E91866471F0
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_56_0
        );
    }

    function addressresolver_importAddresses_57() internal {
        bytes32[] memory addressresolver_importAddresses_names_57_0 = new bytes32[](1);
        addressresolver_importAddresses_names_57_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_57_1 = new address[](1);
        addressresolver_importAddresses_destinations_57_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_57_0,
            addressresolver_importAddresses_destinations_57_1
        );
    }

    function perpsv2marketstatenearperp_removeAssociatedContracts_58() internal {
        address[] memory perpsv2marketstatenearperp_removeAssociatedContracts_associatedContracts_58_0 = new address[](2);
        perpsv2marketstatenearperp_removeAssociatedContracts_associatedContracts_58_0[0] = address(
            0xB9AbecE4Fcd56E2e3EE63fC9f60dC8A825379193
        );
        perpsv2marketstatenearperp_removeAssociatedContracts_associatedContracts_58_0[1] = address(
            0x40542FEa068ED07247645581C04EfA1f83Ff04E5
        );
        perpsv2marketstatenearperp_i.removeAssociatedContracts(
            perpsv2marketstatenearperp_removeAssociatedContracts_associatedContracts_58_0
        );
    }

    function perpsv2marketstatenearperp_addAssociatedContracts_59() internal {
        address[] memory perpsv2marketstatenearperp_addAssociatedContracts_associatedContracts_59_0 = new address[](2);
        perpsv2marketstatenearperp_addAssociatedContracts_associatedContracts_59_0[0] = address(
            0x4df6E29C07c51e5e7F7a98aB90547861Aba42B56
        );
        perpsv2marketstatenearperp_addAssociatedContracts_associatedContracts_59_0[1] = address(
            0x767F446FbD3F2e5c91292D9FA51a44102a89117d
        );
        perpsv2marketstatenearperp_i.addAssociatedContracts(
            perpsv2marketstatenearperp_addAssociatedContracts_associatedContracts_59_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_75() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0[0] = address(
            0xC8fCd6fB4D15dD7C455373297dEF375a08942eCe
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_75_0
        );
    }

    function addressresolver_importAddresses_76() internal {
        bytes32[] memory addressresolver_importAddresses_names_76_0 = new bytes32[](1);
        addressresolver_importAddresses_names_76_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_76_1 = new address[](1);
        addressresolver_importAddresses_destinations_76_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_76_0,
            addressresolver_importAddresses_destinations_76_1
        );
    }

    function perpsv2marketstateaudperp_removeAssociatedContracts_77() internal {
        address[] memory perpsv2marketstateaudperp_removeAssociatedContracts_associatedContracts_77_0 = new address[](2);
        perpsv2marketstateaudperp_removeAssociatedContracts_associatedContracts_77_0[0] = address(
            0xb153f06077aF9448C53c7102760e59836a27Ed27
        );
        perpsv2marketstateaudperp_removeAssociatedContracts_associatedContracts_77_0[1] = address(
            0x0B6364488E14568A125440F3C42aD59698fb9E38
        );
        perpsv2marketstateaudperp_i.removeAssociatedContracts(
            perpsv2marketstateaudperp_removeAssociatedContracts_associatedContracts_77_0
        );
    }

    function perpsv2marketstateaudperp_addAssociatedContracts_78() internal {
        address[] memory perpsv2marketstateaudperp_addAssociatedContracts_associatedContracts_78_0 = new address[](2);
        perpsv2marketstateaudperp_addAssociatedContracts_associatedContracts_78_0[0] = address(
            0xAF89069dC03d65C1b3091D770a8D3b4D02126849
        );
        perpsv2marketstateaudperp_addAssociatedContracts_associatedContracts_78_0[1] = address(
            0xd1b73C8251acf068ea03A42177bD1E3F610F9fB4
        );
        perpsv2marketstateaudperp_i.addAssociatedContracts(
            perpsv2marketstateaudperp_addAssociatedContracts_associatedContracts_78_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_94() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0[0] = address(
            0x9De146b5663b82F44E5052dEDe2aA3Fd4CBcDC99
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_94_0
        );
    }

    function addressresolver_importAddresses_95() internal {
        bytes32[] memory addressresolver_importAddresses_names_95_0 = new bytes32[](1);
        addressresolver_importAddresses_names_95_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_95_1 = new address[](1);
        addressresolver_importAddresses_destinations_95_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_95_0,
            addressresolver_importAddresses_destinations_95_1
        );
    }

    function perpsv2marketstategbpperp_removeAssociatedContracts_96() internal {
        address[] memory perpsv2marketstategbpperp_removeAssociatedContracts_associatedContracts_96_0 = new address[](2);
        perpsv2marketstategbpperp_removeAssociatedContracts_associatedContracts_96_0[0] = address(
            0x2a837135a1F18EEEa18E3bfb16265550Bf705b4B
        );
        perpsv2marketstategbpperp_removeAssociatedContracts_associatedContracts_96_0[1] = address(
            0x77769c01168011f26a39B71C9c7bA0607752E9ff
        );
        perpsv2marketstategbpperp_i.removeAssociatedContracts(
            perpsv2marketstategbpperp_removeAssociatedContracts_associatedContracts_96_0
        );
    }

    function perpsv2marketstategbpperp_addAssociatedContracts_97() internal {
        address[] memory perpsv2marketstategbpperp_addAssociatedContracts_associatedContracts_97_0 = new address[](2);
        perpsv2marketstategbpperp_addAssociatedContracts_associatedContracts_97_0[0] = address(
            0x7690Af487c06674785daEF91EF6576464B46D249
        );
        perpsv2marketstategbpperp_addAssociatedContracts_associatedContracts_97_0[1] = address(
            0x6cb4EEcE70eF0eB8E7f81f4A0dE0FB1521E77F74
        );
        perpsv2marketstategbpperp_i.addAssociatedContracts(
            perpsv2marketstategbpperp_addAssociatedContracts_associatedContracts_97_0
        );
    }

    function futuresmarketmanager_updateMarketsImplementations_113() internal {
        address[] memory futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0 = new address[](1);
        futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0[0] = address(
            0x1dAd8808D8aC58a0df912aDC4b215ca3B93D6C49
        );
        futuresmarketmanager_i.updateMarketsImplementations(
            futuresmarketmanager_updateMarketsImplementations_marketsToUpdate_113_0
        );
    }

    function addressresolver_importAddresses_114() internal {
        bytes32[] memory addressresolver_importAddresses_names_114_0 = new bytes32[](1);
        addressresolver_importAddresses_names_114_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_114_1 = new address[](1);
        addressresolver_importAddresses_destinations_114_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_114_0,
            addressresolver_importAddresses_destinations_114_1
        );
    }

    function addressresolver_importAddresses_116() internal {
        bytes32[] memory addressresolver_importAddresses_names_116_0 = new bytes32[](1);
        addressresolver_importAddresses_names_116_0[0] = bytes32("PerpsV2MarketData");
        address[] memory addressresolver_importAddresses_destinations_116_1 = new address[](1);
        addressresolver_importAddresses_destinations_116_1[0] = address(new_PerpsV2MarketData_contract);
        addressresolver_i.importAddresses(
            addressresolver_importAddresses_names_116_0,
            addressresolver_importAddresses_destinations_116_1
        );
    }
}
