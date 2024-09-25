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

// What do you expect...
// solhint-disable max-states-count

import { CFAv1Forwarder } from "./CFAv1Forwarder.sol";
import { IDAv1Forwarder } from "./IDAv1Forwarder.sol";
import { ISuperfluid, ISuperfluidToken, Superfluid } from "../superfluid/Superfluid.sol";
import { TestGovernance } from "./TestGovernance.sol";
import { ConstantFlowAgreementV1 } from "../agreements/ConstantFlowAgreementV1.sol";
import { ConstantOutflowNFT, IConstantOutflowNFT } from "../superfluid/ConstantOutflowNFT.sol";
import { ConstantInflowNFT, IConstantInflowNFT } from "../superfluid/ConstantInflowNFT.sol";
import { InstantDistributionAgreementV1 } from "../agreements/InstantDistributionAgreementV1.sol";
import { SuperTokenFactory } from "../superfluid/SuperTokenFactory.sol";
import { TestToken } from "./TestToken.sol";
import { PureSuperToken } from "../tokens/PureSuperToken.sol";
import { SETHProxy } from "../tokens/SETH.sol";
import { ISuperToken, SuperToken } from "../superfluid/SuperToken.sol";
import { TestResolver } from "./TestResolver.sol";
import { SuperfluidLoader } from "./SuperfluidLoader.sol";
import { UUPSProxy } from "../upgradability/UUPSProxy.sol";
import { BatchLiquidator } from "./BatchLiquidator.sol";
import { TOGA } from "./TOGA.sol";
import { CFAv1Library } from "../apps/CFAv1Library.sol";
import { IDAv1Library } from "../apps/IDAv1Library.sol";
import { IResolver } from "../interfaces/utils/IResolver.sol";

/// @title Superfluid Framework Deployment Steps
/// @author Superfluid
/// @notice A contract which splits framework deployment into steps.
/// @dev This was necessary because of the contract size limit of the deployed contract
/// which is an issue when deploying the original framework with Hardhat.
/// https://github.com/NomicFoundation/hardhat/issues/3404#issuecomment-1346849400
contract SuperfluidFrameworkDeploymentSteps {
    bool public constant DEFAULT_NON_UPGRADEABLE = false;
    bool public constant DEFAULT_APP_WHITELISTING_ENABLED = false;
    address public constant DEFAULT_REWARD_ADDRESS = address(69);
    uint256 public constant DEFAULT_LIQUIDATION_PERIOD = 4 hours;
    uint256 public constant DEFAULT_PATRICIAN_PERIOD = 30 minutes;
    uint256 public constant DEFAULT_TOGA_MIN_BOND_DURATION = 1 weeks;
    // TODO we blame solidity that does not suppor this yet
    // solhint-disable-next-line var-name-mixedcase
    address[] public DEFAULT_TRUSTED_FORWARDERS = new address[](0);

    string public constant RESOLVER_BASE_SUPER_TOKEN_KEY = "supertokens.test.";
    string public constant RESOLVER_BASE_TOKEN_KEY = "tokens.test.";

    struct Framework {
        TestGovernance governance;
        Superfluid host;
        ConstantFlowAgreementV1 cfa;
        CFAv1Library.InitData cfaLib;
        InstantDistributionAgreementV1 ida;
        IDAv1Library.InitData idaLib;
        SuperTokenFactory superTokenFactory;
        ISuperToken superTokenLogic;
        ConstantOutflowNFT constantOutflowNFT;
        ConstantInflowNFT constantInflowNFT;
        TestResolver resolver;
        SuperfluidLoader superfluidLoader;
        CFAv1Forwarder cfaV1Forwarder;
        IDAv1Forwarder idaV1Forwarder;
        TOGA toga;
    }

    uint8 private currentStep;

    // Core Contracts
    TestGovernance internal testGovernance;
    Superfluid internal host;

    // Agreement Contracts
    ConstantFlowAgreementV1 internal cfaV1;
    ConstantFlowAgreementV1 internal cfaV1Logic;
    InstantDistributionAgreementV1 internal idaV1;
    InstantDistributionAgreementV1 internal idaV1Logic;

    // SuperToken-related Contracts
    ConstantOutflowNFT internal constantOutflowNFTLogic;
    ConstantInflowNFT internal constantInflowNFTLogic;
    ConstantOutflowNFT internal constantOutflowNFT;
    ConstantInflowNFT internal constantInflowNFT;
    ISuperToken internal superTokenLogic;
    SuperTokenFactory internal superTokenFactory;
    SuperTokenFactory internal superTokenFactoryLogic;

    // Peripheral Contracts
    TestResolver internal testResolver;
    SuperfluidLoader internal superfluidLoader;
    CFAv1Forwarder internal cfaV1Forwarder;
    IDAv1Forwarder internal idaV1Forwarder;
    BatchLiquidator internal batchLiquidator;
    TOGA internal toga;

    function _deployGovernance(address newOwner) internal {
        // Deploy TestGovernance. Needs initialization later.
        testGovernance = SuperfluidGovDeployerLibrary.deployTestGovernance();

        SuperfluidGovDeployerLibrary.transferOwnership(testGovernance, newOwner);
    }

    function _deployHost(bool nonUpgradable, bool appWhiteListingEnabled) internal {
        host = SuperfluidHostDeployerLibrary.deploySuperfluidHost(nonUpgradable, appWhiteListingEnabled);
    }

    function _initializeHost() internal {
        host.initialize(testGovernance);
    }

    function _initializeGovernance(
        address defaultRewardAddress,
        uint256 defaultLiquidationPeriod,
        uint256 defaultPatricianPeriod,
        address[] memory defaultTrustedForwarders
    ) internal {
        testGovernance.initialize(
            host, defaultRewardAddress, defaultLiquidationPeriod, defaultPatricianPeriod, defaultTrustedForwarders
        );
    }

    function _deployHostAndInitializeHostAndGovernance(bool nonUpgradable, bool appWhiteListingEnabled) internal {
        // Deploy Host
        _deployHost(nonUpgradable, appWhiteListingEnabled);

        _initializeHost();

        _initializeGovernance(
            DEFAULT_REWARD_ADDRESS, DEFAULT_LIQUIDATION_PERIOD, DEFAULT_PATRICIAN_PERIOD, DEFAULT_TRUSTED_FORWARDERS
        );
    }

    function _deployCFAv1() internal {
        cfaV1Logic = SuperfluidCFAv1DeployerLibrary.deployConstantFlowAgreementV1(host);
    }

    function _deployIDAv1() internal {
        idaV1Logic = SuperfluidIDAv1DeployerLibrary.deployInstantDistributionAgreementV1(host);
    }

    function _deployAgreements() internal {
        _deployCFAv1();
        _deployIDAv1();
    }

    function _deployAgreementsAndRegister() internal {
        _deployAgreements();
        _registerAgreements();
    }

    function _registerAgreements() internal {
        // we set the canonical address based on host.getAgreementClass() because
        // in the upgradeable case, we create a new proxy contract in the function
        // and set it as the canonical agreement.
        testGovernance.registerAgreementClass(host, address(cfaV1Logic));
        cfaV1 = ConstantFlowAgreementV1(address(host.getAgreementClass(cfaV1Logic.agreementType())));
        testGovernance.registerAgreementClass(host, address(idaV1Logic));
        idaV1 = InstantDistributionAgreementV1(address(host.getAgreementClass(idaV1Logic.agreementType())));
    }

    function _deployCFAv1Forwarder() internal {
        cfaV1Forwarder = CFAv1ForwarderDeployerLibrary.deployCFAv1Forwarder(host);
    }

    function _enableCFAv1ForwarderAsTrustedForwarder() internal {
        testGovernance.enableTrustedForwarder(host, ISuperfluidToken(address(0)), address(cfaV1Forwarder));
    }

    function _deployCFAv1ForwarderAndEnable() internal {
        _deployCFAv1Forwarder();
        _enableCFAv1ForwarderAsTrustedForwarder();
    }

    function _deployIDAv1Forwarder() internal {
        idaV1Forwarder = IDAv1ForwarderDeployerLibrary.deployIDAv1Forwarder(host);
    }

    function _enableIDAv1ForwarderAsTrustedForwarder() internal {
        testGovernance.enableTrustedForwarder(host, ISuperfluidToken(address(0)), address(idaV1Forwarder));
    }

    function _deployIDAv1ForwarderAndEnable() internal {
        _deployIDAv1Forwarder();
        _enableIDAv1ForwarderAsTrustedForwarder();
    }

    function _deployNFTProxyAndLogicAndInitialize() internal {
        // Deploy canonical Constant Outflow NFT proxy contract
        UUPSProxy constantOutflowNFTProxy = ProxyDeployerLibrary.deployUUPSProxy();

        // Deploy canonical Constant Outflow NFT proxy contract
        UUPSProxy constantInflowNFTProxy = ProxyDeployerLibrary.deployUUPSProxy();

        // Deploy canonical Constant Outflow NFT logic contract
        constantOutflowNFTLogic = SuperfluidNFTLogicDeployerLibrary.deployConstantOutflowNFT(
            host, IConstantInflowNFT(address(constantInflowNFTProxy))
        );

        // Initialize Constant Outflow NFT logic contract
        constantOutflowNFTLogic.castrate();

        // Deploy canonical Constant Inflow NFT logic contract
        constantInflowNFTLogic = SuperfluidNFTLogicDeployerLibrary.deployConstantInflowNFT(
            host, IConstantOutflowNFT(address(constantOutflowNFTProxy))
        );

        // Initialize Constant Inflow NFT logic contract
        constantInflowNFTLogic.castrate();

        // Initialize COFNFT proxy contract
        constantOutflowNFTProxy.initializeProxy(address(constantOutflowNFTLogic));

        // Initialize CIFNFT proxy contract
        constantInflowNFTProxy.initializeProxy(address(constantInflowNFTLogic));

        // // Initialize COFNFT proxy contract
        IConstantOutflowNFT(address(constantOutflowNFTProxy)).initialize("Constant Outflow NFT", "COF");

        // // Initialize CIFNFT proxy contract
        IConstantInflowNFT(address(constantInflowNFTProxy)).initialize("Constant Inflow NFT", "CIF");

        constantOutflowNFT = ConstantOutflowNFT(address(constantOutflowNFTProxy));
        constantInflowNFT = ConstantInflowNFT(address(constantInflowNFTProxy));
    }

    function _deploySuperTokenLogicAndSuperTokenFactoryAndUpdateContracts() internal {
        _deploySuperTokenLogicAndSuperTokenFactory();
        _setSuperTokenFactoryInHost();
    }

    function _deploySuperTokenLogicAndSuperTokenFactory() internal {
        _deploySuperTokenLogic();
        _deploySuperTokenFactory();
    }

    function _deploySuperTokenLogic() internal {
        // Deploy canonical SuperToken logic contract
        superTokenLogic = SuperToken(
            SuperTokenDeployerLibrary.deploySuperTokenLogic(
                host, IConstantOutflowNFT(address(constantOutflowNFT)), IConstantInflowNFT(address(constantInflowNFT))
            )
        );
    }

    function _deploySuperTokenFactory() internal {
        superTokenFactoryLogic = SuperfluidPeripheryDeployerLibrary.deploySuperTokenFactory(
            host, superTokenLogic, constantOutflowNFTLogic, constantInflowNFTLogic
        );
    }

    function _setSuperTokenFactoryInHost() internal {
        // 'Update' code with Governance and register SuperTokenFactory with Superfluid
        testGovernance.updateContracts(host, address(0), new address[](0), address(superTokenFactoryLogic));

        // we set the canonical address based on host.getSuperTokenFactory() because
        // in the upgradeable case, we create a new proxy contract in the function
        // and set it as the canonical supertokenfactory.
        superTokenFactory = SuperTokenFactory(address(host.getSuperTokenFactory()));
    }

    function _deployTestResolver(address resolverAdmin) internal {
        testResolver = SuperfluidPeripheryDeployerLibrary.deployTestResolver(resolverAdmin);
    }

    function _deploySuperfluidLoader() internal {
        superfluidLoader = SuperfluidLoaderDeployerLibrary.deploySuperfluidLoader(testResolver);
    }

    function _deployTestResolverAndSuperfluidLoaderAndSet(address resolverAdmin) internal {
        _deployTestResolver(resolverAdmin);
        _deploySuperfluidLoader();

        _setAddressesInResolver();
    }

    function _setAddressesInResolver() internal {
        // Register Governance with Resolver
        testResolver.set("TestGovernance.test", address(testGovernance));

        // Register Superfluid with Resolver
        testResolver.set("Superfluid.test", address(host));

        // Register SuperfluidLoader with Resolver
        testResolver.set("SuperfluidLoader-v1", address(superfluidLoader));

        // Register CFAv1Forwarder with Resolver
        testResolver.set("CFAv1Forwarder", address(cfaV1Forwarder));

        // Register IDAv1Forwarder with Resolver
        testResolver.set("IDAv1Forwarder", address(idaV1Forwarder));
    }

    function _deployBatchLiquidator() internal {
        batchLiquidator = new BatchLiquidator(address(host), address(cfaV1));
    }

    function _deployTOGA(uint256 minBondDuration) internal virtual {
        toga = new TOGA(host, minBondDuration);
    }

    /// @notice Fetches the framework contracts
    function getFramework() external view returns (Framework memory sf) {
        sf = Framework({
            governance: testGovernance,
            host: host,
            cfa: cfaV1,
            cfaLib: CFAv1Library.InitData(host, cfaV1),
            ida: idaV1,
            idaLib: IDAv1Library.InitData(host, idaV1),
            superTokenFactory: superTokenFactory,
            superTokenLogic: superTokenLogic,
            constantOutflowNFT: constantOutflowNFT,
            constantInflowNFT: constantInflowNFT,
            resolver: testResolver,
            superfluidLoader: superfluidLoader,
            cfaV1Forwarder: cfaV1Forwarder,
            idaV1Forwarder: idaV1Forwarder,
            toga: toga
        });
        return sf;
    }

    /// @notice Transfer ownership of the TestGovernance contract
    /// @dev This function allows you to transfer ownership of TestGovernance when testing
    /// @param newOwner the new owner of the TestGovernance contract
    function transferOwnership(address newOwner) public {
        testGovernance.transferOwnership(newOwner);
    }

    function _getNumSteps() internal pure returns (uint8) {
        return 8;
    }

    function _executeStep(uint8 step) internal {
        if (step != currentStep) revert("Incorrect step");

        if (step == 0) {
            // Deploy Superfluid Governance
            _deployGovernance(address(this));
        } else if (step == 1) {
            // Deploy Superfluid Host
            _deployHostAndInitializeHostAndGovernance(true, false);
        } else if (step == 2) {
            // Deploy Superfluid CFA, IDA, GDA
            _deployAgreementsAndRegister();
        } else if (step == 3) {
            // Deploy CFAv1Forwarder
            _deployCFAv1ForwarderAndEnable();

            // Deploy IDAv1Forwarder
            _deployIDAv1ForwarderAndEnable();

            // Deploy GDAv1Forwarder
            // TODO
            // solhint-disable-next-line no-empty-blocks
        } else if (step == 4) {
            // Deploy SuperfluidPool
            // Initialize GDA with SuperfluidPool beacon
        } else if (step == 5) {
            // Deploy Superfluid NFTs (Proxy and Logic contracts)
            _deployNFTProxyAndLogicAndInitialize();
        } else if (step == 6) {
            // Deploy SuperToken Logic
            // Deploy SuperToken Factory
            _deploySuperTokenLogicAndSuperTokenFactoryAndUpdateContracts();
        } else if (step == 7) {
            // Deploy TestResolver
            // Deploy SuperfluidLoader and make SuperfluidFrameworkDpeloyer an admin for the TestResolver
            // Set TestGovernance, Superfluid, SuperfluidLoader and CFAv1Forwarder in TestResolver
            _deployTestResolverAndSuperfluidLoaderAndSet(address(this));
            // Make SuperfluidFrameworkDeployer deployer an admin for the TestResolver as well
            testResolver.addAdmin(msg.sender);
        } else {
            revert("Invalid step");
        }

        currentStep++;
    }
}

//// External Libraries ////

/// @title SuperfluidGovDeployerLibrary
/// @author Superfluid
/// @notice An external library that deploys the Superfluid TestGovernance contract with additional functions
/// @dev This library is used for testing purposes only, not deployments to test OR production networks
library SuperfluidGovDeployerLibrary {
    /// @notice deploys the Superfluid TestGovernance Contract
    /// @return newly deployed TestGovernance contract
    function deployTestGovernance() external returns (TestGovernance) {
        return new TestGovernance();
    }

    /// @notice transfers ownership of _gov to _newOwner
    /// @dev _gov must be deployed from this contract
    /// @param _gov address of the TestGovernance contract
    /// @param _newOwner the new owner of the governance contract
    function transferOwnership(TestGovernance _gov, address _newOwner) external {
        _gov.transferOwnership(_newOwner);
    }
}

/// @title SuperfluidHostDeployerLibrary
/// @author Superfluid
/// @notice An external library that deploys the Superfluid Host contract with additional functions.
/// @dev This library is used for testing purposes only, not deployments to test OR production networks
library SuperfluidHostDeployerLibrary {
    /// @notice Deploys the Superfluid Host Contract
    /// @param _nonUpgradable whether the hsot contract is upgradeable or not
    /// @param _appWhiteListingEnabled whether app white listing is enabled
    /// @return Superfluid newly deployed Superfluid Host contract
    function deploySuperfluidHost(bool _nonUpgradable, bool _appWhiteListingEnabled) external returns (Superfluid) {
        return new Superfluid(_nonUpgradable, _appWhiteListingEnabled);
    }
}

/// @title SuperfluidIDAv1DeployerLibrary
/// @author Superfluid
/// @notice An external library that deploys the Superfluid InstantDistributionAgreementV1 contract.
/// @dev This library is used for testing purposes only, not deployments to test OR production networks
library SuperfluidIDAv1DeployerLibrary {
    /// @notice deploys the Superfluid InstantDistributionAgreementV1 Contract
    /// @param _host Superfluid host address
    /// @return newly deployed InstantDistributionAgreementV1 contract
    function deployInstantDistributionAgreementV1(ISuperfluid _host)
        external
        returns (InstantDistributionAgreementV1)
    {
        return new InstantDistributionAgreementV1(_host);
    }
}

/// @title SuperfluidCFAv1DeployerLibrary
/// @author Superfluid
/// @notice An external library that deploys Superfluid ConstantFlowAgreementV1 contract
/// @dev This library is used for testing purposes only, not deployments to test OR production networks
library SuperfluidCFAv1DeployerLibrary {
    /// @notice deploys ConstantFlowAgreementV1 contract
    /// @param _host address of the Superfluid contract
    /// @return newly deployed ConstantFlowAgreementV1 contract
    function deployConstantFlowAgreementV1(ISuperfluid _host) external returns (ConstantFlowAgreementV1) {
        return new ConstantFlowAgreementV1(_host);
    }
}

/// @title SuperToken deployer library
/// @author Superfluid
/// @notice This is an external library used to deploy SuperToken logic contracts
library SuperTokenDeployerLibrary {
    /// @notice Deploy a SuperToken logic contract
    /// @param host the address of the host contract
    function deploySuperTokenLogic(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    ) external returns (address) {
        return address(new SuperToken(host, constantOutflowNFT, constantInflowNFT));
    }
}

/// @title SuperfluidPeripheryDeployerLibrary
/// @author Superfluid
/// @notice An external library that deploys Superfluid periphery contracts (Super Token Factory and Test Resolver)
/// @dev This library is used for testing purposes only, not deployments to test OR production networks
library SuperfluidPeripheryDeployerLibrary {
    /// @dev deploys Super Token Factory contract
    /// @param _host address of the Superfluid contract
    /// @param _superTokenLogic address of the Super Token logic contract
    /// @return newly deployed SuperTokenFactory contract
    function deploySuperTokenFactory(
        ISuperfluid _host,
        ISuperToken _superTokenLogic,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    ) external returns (SuperTokenFactory) {
        return new SuperTokenFactory(
                _host,
                _superTokenLogic,
                constantOutflowNFT,
                constantInflowNFT
            );
    }

    /// @dev deploys Test Resolver contract
    /// @param _additionalAdmin address of the additional administrator of the Test Resolver contract
    /// @return newly deployed Test Resolver contract
    function deployTestResolver(address _additionalAdmin) external returns (TestResolver) {
        return new TestResolver(_additionalAdmin);
    }
}

library CFAv1ForwarderDeployerLibrary {
    /// @notice deploys the Superfluid CFAv1Forwarder contract
    /// @param _host Superfluid host address
    /// @return newly deployed CFAv1Forwarder contract
    function deployCFAv1Forwarder(ISuperfluid _host) external returns (CFAv1Forwarder) {
        return new CFAv1Forwarder(_host);
    }
}

library IDAv1ForwarderDeployerLibrary {
    /// @notice deploys the Superfluid IDAv1Forwarder contract
    /// @param _host Superfluid host address
    /// @return newly deployed IDAv1Forwarder contract
    function deployIDAv1Forwarder(ISuperfluid _host) external returns (IDAv1Forwarder) {
        return new IDAv1Forwarder(_host);
    }
}

library SuperfluidLoaderDeployerLibrary {
    /// @notice deploys the Superfluid SuperfluidLoader contract
    /// @param _resolver Superfluid resolver address
    /// @return newly deployed SuperfluidLoader contract
    function deploySuperfluidLoader(IResolver _resolver) external returns (SuperfluidLoader) {
        return new SuperfluidLoader(_resolver);
    }
}

library SuperfluidNFTLogicDeployerLibrary {
    /// @notice deploys the Superfluid ConstantOutflowNFT contract
    /// @param _host Superfluid host address
    /// @param _constantInflowNFTProxy address of the ConstantInflowNFT proxy contract
    /// @return newly deployed ConstantOutflowNFT contract
    function deployConstantOutflowNFT(ISuperfluid _host, IConstantInflowNFT _constantInflowNFTProxy)
        external
        returns (ConstantOutflowNFT)
    {
        return new ConstantOutflowNFT(_host, _constantInflowNFTProxy);
    }

    /// @notice deploys the Superfluid ConstantInflowNFT contract
    /// @param _host Superfluid host address
    /// @param _constantOutflowNFTProxy address of the ConstantOutflowNFT proxy contract
    /// @return newly deployed ConstantInflowNFT contract
    function deployConstantInflowNFT(ISuperfluid _host, IConstantOutflowNFT _constantOutflowNFTProxy)
        external
        returns (ConstantInflowNFT)
    {
        return new ConstantInflowNFT(_host, _constantOutflowNFTProxy);
    }
}

library ProxyDeployerLibrary {
    function deployUUPSProxy() external returns (UUPSProxy) {
        return new UUPSProxy();
    }
}

library TokenDeployerLibrary {
    function deployTestToken(
        string calldata _underlyingName,
        string calldata _underlyingSymbol,
        uint8 _decimals,
        uint256 _mintLimit
    ) external returns (TestToken) {
        return new TestToken(
            _underlyingName,
            _underlyingSymbol,
            _decimals,
            _mintLimit);
    }

    function deploySETHProxy() external returns (SETHProxy) {
        return new SETHProxy();
    }

    function deployPureSuperToken() external returns (PureSuperToken) {
        return new PureSuperToken();
    }
}
