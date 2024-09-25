/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import { IERC20Metadata } from "SuperFluid/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SuperfluidFrameworkDeploymentSteps, TokenDeployerLibrary } from "./SuperfluidFrameworkDeploymentSteps.sol";
import { ISuperTokenFactory } from "../superfluid/SuperTokenFactory.sol";
import { SuperToken } from "../superfluid/SuperToken.sol";
import { TestToken } from "./TestToken.sol";
import { ISETH } from "../interfaces/tokens/ISETH.sol";
import { IPureSuperToken } from "../interfaces/tokens/IPureSuperToken.sol";
import { PureSuperToken } from "../tokens/PureSuperToken.sol";
import { SETHProxy } from "../tokens/SETH.sol";

/// @title Superfluid Framework Deployer
/// @dev This deployer should only be used for local testing environments.
/// NOTE: ERC1820 must be deployed as a prerequisite to using this contract.
contract SuperfluidFrameworkDeployer is SuperfluidFrameworkDeploymentSteps {
    struct TestFrameworkConfigs {
        // Whether the protocol is not upgradeable
        // Default: false
        bool nonUpgradeable;
        // Whether app whitelisting is required
        // Default: false
        bool appWhitelistingEnabled;
        // Trusted forwarders that can forward batch calls on your behalf via the Host
        // Default: []
        address[] trustedForwarders;
        // The default address to receive patrician period liquidation rewards (TOGA if unset/address(0))
        // Default: address(69)
        address defaultRewardAddress;
        // The multiplier against the flow rate which determines the buffer required for flow creation
        // Buffer = flowRate * liquidationPeriod
        // Default: 4 hours
        uint256 liquidationPeriod;
        // The amount of time where a liquidation results in a reward for the defaultRewardAddress
        // Default: 30 minutes
        uint256 patricianPeriod;
        // The minimum amount of time that a user must bond their tokens in TOGA for
        // Default: 1 week
        uint256 minBondDuration;
    }

    error DEPLOY_AGREEMENTS_REQUIRES_DEPLOY_CORE();
    error DEPLOY_PERIPHERALS_REQUIRES_DEPLOY_CORE();
    error DEPLOY_PERIPHERALS_REQUIRES_DEPLOY_AGREEMENTS();
    error DEPLOY_SUPER_TOKEN_CONTRACTS_REQUIRES_DEPLOY_CORE();
    error DEPLOY_SUPER_TOKEN_REQUIRES_1820();
    error DEPLOY_SUPER_TOKEN_REQUIRES_DEPLOY_SUPER_TOKEN_CONTRACTS();
    error DEPLOY_TOGA_REQUIRES_1820();
    error RESOLVER_LIST_REQUIRES_DEPLOY_PERIPHERALS();

    /// @notice Deploys the Superfluid Framework (Test)
    /// @dev This uses default configurations for the framework.
    /// NOTE: ERC1820 must be deployed as a prerequisite before calling this function.
    function deployTestFramework() external {
        // Default Configs
        TestFrameworkConfigs memory configs = TestFrameworkConfigs({
            nonUpgradeable: DEFAULT_NON_UPGRADEABLE,
            appWhitelistingEnabled: DEFAULT_APP_WHITELISTING_ENABLED,
            trustedForwarders: DEFAULT_TRUSTED_FORWARDERS,
            defaultRewardAddress: DEFAULT_REWARD_ADDRESS,
            liquidationPeriod: DEFAULT_LIQUIDATION_PERIOD,
            patricianPeriod: DEFAULT_PATRICIAN_PERIOD,
            minBondDuration: DEFAULT_TOGA_MIN_BOND_DURATION
        });

        _deployTestFramework(configs);
    }

    function _deployTestFramework(TestFrameworkConfigs memory configs) internal {
        // Deploy Host and Governance
        _deployCoreContracts(configs);

        // Initialize Host with Governance address
        _initializeHost();

        // Initialize Governance with Host address and Configs
        _initializeGovernance(
            configs.defaultRewardAddress, configs.liquidationPeriod, configs.patricianPeriod, configs.trustedForwarders
        );

        // Deploy CFAv1 and IDAv1
        _deployAgreementContracts();

        // Register the agreements with governance
        _registerAgreements();

        // Deploy NFT Proxy and Logic, SuperToken Logic, SuperTokenFactory Proxy and Logic contracts
        _deploySuperTokenContracts();

        // Set SuperTokenFactory as the canonical contract
        _setSuperTokenFactoryInHost();

        // Deploy Resolver, SuperfluidLoaderV1, CFAv1Forwarder, TOGA, BatchLiquidator contracts
        _deployPeripheralContracts(configs);

        // Enable the CFAv1Forwarder as a trusted forwarder via Governance
        _enableCFAv1ForwarderAsTrustedForwarder();

        // Enable the IDAv1Forwarder as a trusted forwarder via Governance
        _enableIDAv1ForwarderAsTrustedForwarder();

        // Set TestGovernance, Superfluid, SuperfluidLoader and CFAv1Forwarder addresses in Resolver
        _setAddressesInResolver();
    }

    /// @notice Deploys the core Superfluid contracts
    /// @dev Host and Governance
    function deployCoreContracts() public {
        TestFrameworkConfigs memory configs;
        configs.nonUpgradeable = true;
        configs.appWhitelistingEnabled = false;

        _deployCoreContracts(configs);
    }

    /// @notice Deploys the core Superfluid contracts w/ Configs
    /// @dev Host and Governance
    /// @param configs the configurations for the framework
    function deployCoreContracts(TestFrameworkConfigs memory configs) public {
        _deployCoreContracts(configs);
    }

    function _deployCoreContracts(TestFrameworkConfigs memory configs) internal {
        _deployGovernance(address(this));
        _deployHost(configs.nonUpgradeable, configs.appWhitelistingEnabled);
    }

    /// @notice Deploys the Superfluid agreement contracts
    /// @dev Deploys Superfluid agreement contracts
    /// NOTE: This requires the core contracts to be deployed first.
    function deployAgreementContracts() public {
        _deployAgreementContracts();
    }

    function _deployAgreementContracts() internal {
        if (address(host) == address(0)) revert DEPLOY_AGREEMENTS_REQUIRES_DEPLOY_CORE();

        _deployCFAv1();
        _deployIDAv1();
    }

    /// @notice Deploys all SuperToken-related contracts
    /// @dev Deploys NFT Proxy and Logic, SuperToken Logic, SuperTokenFactory Proxy and Logic contracts
    function deploySuperTokenContracts() public {
        _deploySuperTokenContracts();
    }

    function _deploySuperTokenContracts() internal {
        if (address(host) == address(0)) revert DEPLOY_SUPER_TOKEN_CONTRACTS_REQUIRES_DEPLOY_CORE();

        _deployNFTProxyAndLogicAndInitialize();
        _deploySuperTokenLogic();
        _deploySuperTokenFactory();
    }

    /// @notice Deploys an ERC20 and a Wrapper Super Token for the ERC20 and lists both in the resolver
    /// @dev SuperToken name and symbol format: `Super ${_underlyingSymbol}` and `${_underlyingSymbol}x`, respectively
    /// @param _underlyingName The underlying token name
    /// @param _underlyingSymbol The token symbol
    /// @param _decimals The token decimals
    /// @param _mintLimit The mint limit of the underlying token
    /// @param _admin The admin address for the Super Token
    /// @return underlyingToken and superToken
    function deployWrapperSuperToken(
        string calldata _underlyingName,
        string calldata _underlyingSymbol,
        uint8 _decimals,
        uint256 _mintLimit,
        address _admin
    )
        external
        requiresSuperTokenFactory
        deploySuperTokenRequires1820
        returns (TestToken underlyingToken, SuperToken superToken)
    {
        return _deployWrapperSuperToken(_underlyingName, _underlyingSymbol, _decimals, _mintLimit, _admin);
    }

    /// @notice Deploys an ERC20 and a Wrapper Super Token for the ERC20 and lists both in the resolver
    /// @dev SuperToken name and symbol format: `Super ${_underlyingSymbol}` and `${_underlyingSymbol}x`, respectively
    /// @param _underlyingName The underlying token name
    /// @param _underlyingSymbol The token symbol
    /// @param _decimals The token decimals
    /// @param _mintLimit The mint limit of the underlying token
    /// @return underlyingToken and superToken
    function deployWrapperSuperToken(
        string calldata _underlyingName,
        string calldata _underlyingSymbol,
        uint8 _decimals,
        uint256 _mintLimit
    )
        external
        requiresSuperTokenFactory
        deploySuperTokenRequires1820
        returns (TestToken underlyingToken, SuperToken superToken)
    {
        return _deployWrapperSuperToken(_underlyingName, _underlyingSymbol, _decimals, _mintLimit, address(0));
    }

    /// @notice Deploys a Native Asset Super Token and lists it in the resolver
    /// @dev e.g. ETHx, MATICx, AVAXx, etc. The underlying is the Native Asset.
    /// @param _name The token name
    /// @param _symbol The super token symbol
    /// @return nativeAssetSuperToken
    function deployNativeAssetSuperToken(string calldata _name, string calldata _symbol)
        external
        requiresSuperTokenFactory
        deploySuperTokenRequires1820
        returns (ISETH nativeAssetSuperToken)
    {
        SETHProxy sethProxy = TokenDeployerLibrary.deploySETHProxy();
        nativeAssetSuperToken = ISETH(address(sethProxy));
        superTokenFactory.initializeCustomSuperToken(address(sethProxy));
        nativeAssetSuperToken.initialize(IERC20(address(0)), 18, _name, _symbol);

        string memory superTokenKey = string.concat(RESOLVER_BASE_SUPER_TOKEN_KEY, _symbol);
        _handleResolverList(true, superTokenKey, address(nativeAssetSuperToken));
    }

    /// @notice Deploys a Pure Super Token and lists it in the resolver
    /// @dev We specify the initial supply (because non-downgradeable) on creation and send it to the deployer
    /// @param _name The token name
    /// @param _symbol The token symbol
    /// @param _initialSupply The initial token supply of the pure super token
    /// @return pureSuperToken
    function deployPureSuperToken(string calldata _name, string calldata _symbol, uint256 _initialSupply)
        external
        requiresSuperTokenFactory
        deploySuperTokenRequires1820
        returns (IPureSuperToken pureSuperToken)
    {
        PureSuperToken pureSuperTokenProxy = TokenDeployerLibrary.deployPureSuperToken();
        superTokenFactory.initializeCustomSuperToken(address(pureSuperTokenProxy));
        pureSuperTokenProxy.initialize(_name, _symbol, _initialSupply);

        pureSuperToken = IPureSuperToken(address(pureSuperTokenProxy));

        _handleResolverList(true, string.concat(RESOLVER_BASE_SUPER_TOKEN_KEY, _symbol), address(pureSuperToken));

        // transfer initial supply to deployer
        pureSuperToken.transfer(msg.sender, _initialSupply);
    }

    function _handleResolverList(bool _listOnResolver, string memory _resolverKey, address _superTokenAddress)
        internal
        requiresResolver
    {
        if (_listOnResolver) {
            testResolver.set(_resolverKey, address(_superTokenAddress));
        }
    }

    function _deployWrapperSuperToken(
        string calldata _underlyingName,
        string calldata _underlyingSymbol,
        uint8 _decimals,
        uint256 _mintLimit,
        address _admin
    ) internal returns (TestToken underlyingToken, SuperToken superToken) {
        underlyingToken =
            TokenDeployerLibrary.deployTestToken(_underlyingName, _underlyingSymbol, _decimals, _mintLimit);

        string memory superTokenSymbol = string.concat(_underlyingSymbol, "x");

        superToken = SuperToken(
            address(
                superTokenFactory.createERC20Wrapper(
                    IERC20Metadata(address(underlyingToken)),
                    underlyingToken.decimals(),
                    ISuperTokenFactory.Upgradability.SEMI_UPGRADABLE,
                    string.concat("Super ", _underlyingSymbol),
                    superTokenSymbol,
                    _admin
                )
            )
        );

        // list underlying token in resolver
        string memory underlyingTokenKey = string.concat(RESOLVER_BASE_TOKEN_KEY, underlyingToken.symbol());
        _handleResolverList(true, underlyingTokenKey, address(underlyingToken));

        // list super token in resolver
        string memory superTokenKey = string.concat(RESOLVER_BASE_SUPER_TOKEN_KEY, superToken.symbol());
        _handleResolverList(true, superTokenKey, address(superToken));
    }

    /// @notice Deploys all peripheral Superfluid contracts
    /// @dev Deploys Resolver, SuperfluidLoaderV1, CFAv1Forwarder, TOGA, BatchLiquidator contracts
    function deployPeripheralContracts() public {
        TestFrameworkConfigs memory configs;
        configs.minBondDuration = DEFAULT_TOGA_MIN_BOND_DURATION;

        _deployPeripheralContracts(configs);
    }

    /// @notice Deploys all peripheral Superfluid contracts with configs
    /// @dev Deploys Resolver, SuperfluidLoaderV1, CFAv1Forwarder, TOGA, BatchLiquidator contracts
    function deployPeripheralContracts(TestFrameworkConfigs memory configs) public {
        _deployPeripheralContracts(configs);
    }

    function _deployPeripheralContracts(TestFrameworkConfigs memory configs) internal {
        if (address(host) == address(0)) revert DEPLOY_PERIPHERALS_REQUIRES_DEPLOY_CORE();

        _deployTestResolver(address(this));
        _deploySuperfluidLoader();

        // Set the deployer of this contract as an admin of the resolver
        // So that they can add other admins and set addresses
        testResolver.addAdmin(msg.sender);

        _deployCFAv1Forwarder();
        _deployIDAv1Forwarder();
        _deployTOGA(configs.minBondDuration);

        if (address(cfaV1) == address(0)) revert DEPLOY_PERIPHERALS_REQUIRES_DEPLOY_AGREEMENTS();
        _deployBatchLiquidator();
    }

    function _deployTOGA(uint256 _minBondDuration) internal override deployTogaRequires1820 {
        super._deployTOGA(_minBondDuration);
    }

    //// JS-Specific Functions ////
    function getNumSteps() external pure returns (uint8) {
        return _getNumSteps();
    }

    function executeStep(uint8 step) external {
        _executeStep(step);
    }

    function _is1820Deployed() internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24)
        }
        return codeSize != 0;
    }

    modifier requiresResolver() {
        if (address(testResolver) == address(0)) revert RESOLVER_LIST_REQUIRES_DEPLOY_PERIPHERALS();
        _;
    }

    modifier requiresSuperTokenFactory() {
        if (address(superTokenFactory) == address(0)) revert DEPLOY_SUPER_TOKEN_REQUIRES_DEPLOY_SUPER_TOKEN_CONTRACTS();
        _;
    }

    modifier deploySuperTokenRequires1820() {
        if (!_is1820Deployed()) revert DEPLOY_SUPER_TOKEN_REQUIRES_1820();
        _;
    }

    modifier deployTogaRequires1820() {
        if (!_is1820Deployed()) revert DEPLOY_TOGA_REQUIRES_1820();
        _;
    }
}
