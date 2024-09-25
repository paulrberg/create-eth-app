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
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { IERC20Metadata } from "SuperFluid/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "SuperFluid/@openzeppelin/contracts/access/Ownable.sol";
import {
    ISuperTokenFactory,
    ISuperToken
} from "../interfaces/superfluid/ISuperTokenFactory.sol";
import { ISuperfluid, IConstantOutflowNFT, IConstantInflowNFT } from "../interfaces/superfluid/ISuperfluid.sol";
import { UUPSProxy } from "../upgradability/UUPSProxy.sol";
import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";
import { FullUpgradableSuperTokenProxy } from "./FullUpgradableSuperTokenProxy.sol";

abstract contract SuperTokenFactoryBase is
    UUPSProxiable,
    ISuperTokenFactory
{
    struct InitializeData {
        address underlyingToken;
        address superToken;
    }

    /**************************************************************************
    * Immutable Variables
    **************************************************************************/

    // solhint-disable-next-line var-name-mixedcase
    ISuperToken immutable public _SUPER_TOKEN_LOGIC;

    ISuperfluid immutable internal _host;

    // solhint-disable-next-line var-name-mixedcase
    IConstantOutflowNFT immutable public CONSTANT_OUTFLOW_NFT_LOGIC;

    // solhint-disable-next-line var-name-mixedcase
    IConstantInflowNFT immutable public CONSTANT_INFLOW_NFT_LOGIC;

    /**************************************************************************
    * Storage Variables
    **************************************************************************/

    /* WARNING: NEVER RE-ORDER VARIABLES! Including the base contracts.
        Always double-check that new
        variables are added APPEND-ONLY. Re-ordering variables can
        permanently BREAK the deployed proxy contract. */

    // @dev This is the old SuperToken logic contract that is no longer used
    // It is kept here for backwards compatibility due to the fact that we cannot
    // change the storage layout of the contract
    ISuperToken internal _superTokenLogicDeprecated;

    /// @notice A mapping from underlying token addresses to canonical wrapper super token addresses
    /// @dev Reasoning: (1) provide backwards compatibility for existing listed wrapper super tokens
    /// @dev (2) prevent address retrieval issues if we ever choose to modify the bytecode of the UUPSProxy contract
    /// @dev NOTE: address(0) key points to the NativeAssetSuperToken on the network.
    mapping(address => address) internal _canonicalWrapperSuperTokens;

    /// NOTE: Whenever modifying the storage layout here it is important to update the validateStorageLayout
    /// function in its respective mock contract to ensure that it doesn't break anything or lead to unexpected
    /// behaviors/layout when upgrading

    error SUPER_TOKEN_FACTORY_ONLY_GOVERNANCE_OWNER();

    constructor(
        ISuperfluid host,
        ISuperToken superTokenLogic,
        IConstantOutflowNFT constantOutflowNFTLogic,
        IConstantInflowNFT constantInflowNFTLogic
    ) {
        _host = host;

        // SuperToken logic is now deployed prior to new factory logic deployment
        // and passed in as a parameter to SuperTokenFactory constructor
        _SUPER_TOKEN_LOGIC = superTokenLogic;

        // this is optional - allow to fail in order to not force re-deployment
        // solhint-disable-next-line no-empty-blocks
        try UUPSProxiable(address(_SUPER_TOKEN_LOGIC)).castrate() {}
        // solhint-disable-next-line no-empty-blocks
        catch {}

        CONSTANT_OUTFLOW_NFT_LOGIC = constantOutflowNFTLogic;

        CONSTANT_INFLOW_NFT_LOGIC = constantInflowNFTLogic;

        // emit SuperTokenLogicCreated event
        // note that creation here means the setting of the super token logic contract
        // as the canonical super token logic for the Superfluid framework and not the
        // actual contract creation
        emit SuperTokenLogicCreated(_SUPER_TOKEN_LOGIC);
    }

    /// @inheritdoc ISuperTokenFactory
    function getHost()
       external view
       override(ISuperTokenFactory)
       returns(address host)
    {
       return address(_host);
    }

    /**************************************************************************
    * UUPSProxiable
    **************************************************************************/
    /// @inheritdoc ISuperTokenFactory
    function initialize()
        external
        override
        initializer // OpenZeppelin Initializable
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.superfluid-finance.contracts.SuperTokenFactory.implementation");
    }

    /// @notice Updates the logic contract for the SuperTokenFactory
    /// @dev This function updates the logic contract for the SuperTokenFactory
    /// @param newAddress the new address of the SuperTokenFactory logic contract
    function updateCode(address newAddress) external override {
        if (msg.sender != address(_host)) {
            revert SUPER_TOKEN_FACTORY_ONLY_HOST();
        }
        _updateCodeAddress(newAddress);

        // Upgrade the Flow NFT logic contracts on the canonical proxies
        // We only do this if the new logic contracts passed in updating the SuperTokenFactory
        // are different from the current logic contracts
        SuperTokenFactory newFactory = SuperTokenFactory(newAddress);
        address newConstantOutflowLogic = address(newFactory.CONSTANT_OUTFLOW_NFT_LOGIC());
        address newConstantInflowLogic = address(newFactory.CONSTANT_INFLOW_NFT_LOGIC());

        if (address(CONSTANT_OUTFLOW_NFT_LOGIC) != newConstantOutflowLogic) {
            UUPSProxiable(address(_SUPER_TOKEN_LOGIC.CONSTANT_OUTFLOW_NFT())).updateCode(newConstantOutflowLogic);
        }

        if (address(CONSTANT_INFLOW_NFT_LOGIC) != newConstantInflowLogic) {
            UUPSProxiable(address(_SUPER_TOKEN_LOGIC.CONSTANT_INFLOW_NFT())).updateCode(newConstantInflowLogic);
        }
    }

    /**************************************************************************
    * ISuperTokenFactory
    **************************************************************************/
    /// @inheritdoc ISuperTokenFactory
    function getSuperTokenLogic()
        external view override
        returns (ISuperToken)
    {
        return _SUPER_TOKEN_LOGIC;
    }

    /// @inheritdoc ISuperTokenFactory
    function createCanonicalERC20Wrapper(IERC20Metadata _underlyingToken)
        external
        returns (ISuperToken)
    {
        // we use this to check if we have initialized the _canonicalWrapperSuperTokens mapping
        // @note we must set this during initialization
        if (_canonicalWrapperSuperTokens[address(0)] == address(0)) {
            revert SUPER_TOKEN_FACTORY_UNINITIALIZED();
        }

        address underlyingTokenAddress = address(_underlyingToken);
        address canonicalSuperTokenAddress = _canonicalWrapperSuperTokens[
                underlyingTokenAddress
            ];

        // if the canonical super token address exists, revert with custom error
        if (canonicalSuperTokenAddress != address(0)) {
            revert SUPER_TOKEN_FACTORY_ALREADY_EXISTS();
        }

        // use create2 to deterministically create the proxy contract for the wrapper super token
        bytes32 salt = keccak256(abi.encode(underlyingTokenAddress));
        UUPSProxy proxy = new UUPSProxy{ salt: salt }();

        // NOTE: address(proxy) is equivalent to address(superToken)
        _canonicalWrapperSuperTokens[underlyingTokenAddress] = address(
            proxy
        );

        // set the implementation/logic contract address for the newly deployed proxy
        proxy.initializeProxy(address(_SUPER_TOKEN_LOGIC));

        // cast it as the same type as the logic contract
        ISuperToken superToken = ISuperToken(address(proxy));

        // get underlying token info
        uint8 underlyingDecimals = _underlyingToken.decimals();
        string memory underlyingName = _underlyingToken.name();
        string memory underlyingSymbol = _underlyingToken.symbol();
        // initialize the contract (proxy constructor)
        superToken.initialize(
            _underlyingToken,
            underlyingDecimals,
            string.concat("Super ", underlyingName),
            string.concat(underlyingSymbol, "x")
        );

        emit SuperTokenCreated(superToken);

        return superToken;
    }

    function createERC20Wrapper(
        IERC20Metadata underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol,
        address admin
    ) public override returns (ISuperToken superToken) {
        if (address(underlyingToken) == address(0)) {
            revert SUPER_TOKEN_FACTORY_ZERO_ADDRESS();
        }

        if (upgradability == Upgradability.NON_UPGRADABLE) {
            revert SUPER_TOKEN_FACTORY_NON_UPGRADEABLE_IS_DEPRECATED();
        } else if (upgradability == Upgradability.SEMI_UPGRADABLE) {
            UUPSProxy proxy = new UUPSProxy();
            // initialize the wrapper
            proxy.initializeProxy(address(_SUPER_TOKEN_LOGIC));
            superToken = ISuperToken(address(proxy));
        } else /* if (type == Upgradability.FULL_UPGRADABLE) */ {
            FullUpgradableSuperTokenProxy proxy = new FullUpgradableSuperTokenProxy();
            proxy.initialize();
            superToken = ISuperToken(address(proxy));
        }

        // initialize the token
        superToken.initializeWithAdmin(
            underlyingToken,
            underlyingDecimals,
            name,
            symbol,
            admin
        );

        emit SuperTokenCreated(superToken);
    }

    /// @inheritdoc ISuperTokenFactory
    function createERC20Wrapper(
        IERC20Metadata underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external override
        returns (ISuperToken superToken)
    {
        return createERC20Wrapper(
            underlyingToken,
            underlyingDecimals,
            upgradability,
            name,
            symbol,
            address(0)
        );
    }

    /// @inheritdoc ISuperTokenFactory
    function createERC20Wrapper(
        IERC20Metadata underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol,
        address admin
    )
        external override
        returns (ISuperToken superToken)
    {
        return createERC20Wrapper(
            underlyingToken,
            underlyingToken.decimals(),
            upgradability,
            name,
            symbol,
            admin
        );
    }

    /// @inheritdoc ISuperTokenFactory
    function createERC20Wrapper(
        IERC20Metadata underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external override
        returns (ISuperToken superToken)
    {
        return createERC20Wrapper(
            underlyingToken,
            underlyingToken.decimals(),
            upgradability,
            name,
            symbol,
            address(0)
        );
    }

    /// @inheritdoc ISuperTokenFactory
    function initializeCustomSuperToken(
        address customSuperTokenProxy
    )
        external override
    {
        // odd solidity stuff..
        // NOTE payable necessary because UUPSProxy has a payable fallback function
        address payable a = payable(address(uint160(customSuperTokenProxy)));
        UUPSProxy(a).initializeProxy(address(_SUPER_TOKEN_LOGIC));

        emit CustomSuperTokenCreated(ISuperToken(customSuperTokenProxy));
    }

    /// @inheritdoc ISuperTokenFactory
    function computeCanonicalERC20WrapperAddress(address _underlyingToken)
        external
        view
        returns (address superTokenAddress, bool isDeployed)
    {
        address existingAddress = _canonicalWrapperSuperTokens[
            _underlyingToken
        ];

        if (existingAddress != address(0)) {
            superTokenAddress = existingAddress;
            isDeployed = true;
        } else {
            bytes memory bytecode = type(UUPSProxy).creationCode;
            superTokenAddress = address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                keccak256(abi.encode(_underlyingToken)),
                                keccak256(bytecode)
                            )
                        )
                    )
                )
            );
            isDeployed = false;
        }
    }

    /// @inheritdoc ISuperTokenFactory
    function getCanonicalERC20Wrapper(address _underlyingTokenAddress)
        external
        view
        returns (address superTokenAddress)
    {
        superTokenAddress = _canonicalWrapperSuperTokens[
            _underlyingTokenAddress
        ];
    }

    /// @notice Initializes list of canonical wrapper super tokens.
    /// @dev Note that this should also be kind of a throwaway function which will be executed only once.
    /// @param _data an array of canonical wrappper super tokens to be set
    function initializeCanonicalWrapperSuperTokens(
        InitializeData[] calldata _data
    ) external virtual  {
        Ownable gov = Ownable(address(_host.getGovernance()));
        if (msg.sender != gov.owner()) revert SUPER_TOKEN_FACTORY_ONLY_GOVERNANCE_OWNER();

        // once the list has been set, it cannot be reset
        // @note this means that we must set the 0 address (Native Asset Super Token) when we call this the first time
        if (_canonicalWrapperSuperTokens[address(0)] != address(0)) {
            revert SUPER_TOKEN_FACTORY_ALREADY_EXISTS();
        }

        // initialize mapping
        for (uint256 i = 0; i < _data.length; i++) {
            _canonicalWrapperSuperTokens[_data[i].underlyingToken] = _data[i]
                .superToken;
        }
    }
}

contract SuperTokenFactory is SuperTokenFactoryBase
{
    /* WARNING: NEVER RE-ORDER VARIABLES! Including the base contracts.
        Always double-check that new
        variables are added APPEND-ONLY. Re-ordering variables can
        permanently BREAK the deployed proxy contract. */

    constructor(
        ISuperfluid host,
        ISuperToken superTokenLogic,
        IConstantOutflowNFT constantOutflowNFTLogic,
        IConstantInflowNFT constantInflowNFTLogic
    )
        SuperTokenFactoryBase(
            host,
            superTokenLogic,
            constantOutflowNFTLogic,
            constantInflowNFTLogic
        )
    // solhint-disable-next-line no-empty-blocks
    {}
}
