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

import {
    ISuperfluid,
    ISuperAgreement,
    ISuperfluidToken,
    ISuperToken,
    ISuperTokenFactory,
    ISuperfluidGovernance,
    SuperfluidGovernanceConfigs
} from "../interfaces/superfluid/ISuperfluid.sol";

import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";


/**
 * @title Base superfluid governance implementation
 * @author Superfluid
 */
abstract contract SuperfluidGovernanceBase is ISuperfluidGovernance
{
    struct Value {
        bool set;
        uint256 value;
    }

    /* WARNING: NEVER RE-ORDER VARIABLES! Including the base contracts.
       Always double-check that new
       variables are added APPEND-ONLY. Re-ordering variables can
       permanently BREAK the deployed proxy contract. */

    // host => superToken => config
    mapping (address => mapping (address => mapping (bytes32 => Value))) internal _configs;
    /// NOTE: Whenever modifying the storage layout here it is important to update the validateStorageLayout
    /// function in its respective mock contract to ensure that it doesn't break anything or lead to unexpected
    /// behaviors/layout when upgrading

    /**************************************************************************
    /* ISuperfluidGovernance interface
    /*************************************************************************/

    function replaceGovernance(
        ISuperfluid host,
        address newGov
    )
        external override
        onlyAuthorized(host)
    {
        host.replaceGovernance(ISuperfluidGovernance(newGov));
    }

    function registerAgreementClass(
        ISuperfluid host,
        address agreementClass
    )
        external override
        onlyAuthorized(host)
    {
        host.registerAgreementClass(ISuperAgreement(agreementClass));
    }

    function updateContracts(
        ISuperfluid host,
        address hostNewLogic,
        address[] calldata agreementClassNewLogics,
        address superTokenFactoryNewLogic
    )
        external override
        onlyAuthorized(host)
    {
        if (hostNewLogic != address(0)) {
            UUPSProxiable(address(host)).updateCode(hostNewLogic);
            UUPSProxiable(address(hostNewLogic)).castrate();
        }
        for (uint i = 0; i < agreementClassNewLogics.length; ++i) {
            host.updateAgreementClass(ISuperAgreement(agreementClassNewLogics[i]));
            UUPSProxiable(address(agreementClassNewLogics[i])).castrate();
        }
        if (superTokenFactoryNewLogic != address(0)) {
            host.updateSuperTokenFactory(ISuperTokenFactory(superTokenFactoryNewLogic));

            // the factory logic can be updated for non-upgradable hosts too,
            // in this case it's used without proxy and already initialized.
            // solhint-disable-next-line no-empty-blocks
            try UUPSProxiable(address(superTokenFactoryNewLogic)).castrate() {}
            // solhint-disable-next-line no-empty-blocks
            catch {}
        }
    }

    function batchUpdateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken[] calldata tokens
    )
        external override
        onlyAuthorized(host)
    {
        for (uint i = 0; i < tokens.length; ++i) {
            host.updateSuperTokenLogic(tokens[i], address(0));
        }
    }

    function batchUpdateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken[] calldata tokens,
        address[] calldata tokenLogics
    )
        external override
        onlyAuthorized(host)
    {
        assert(tokens.length == tokenLogics.length);
        for (uint i = 0; i < tokens.length; ++i) {
            host.updateSuperTokenLogic(tokens[i], tokenLogics[i]);
        }
    }

    function batchUpdateSuperTokenMinimumDeposit(
        ISuperfluid host,
        ISuperToken[] calldata tokens,
        uint256[] calldata minimumDeposits
    ) external {
        assert(tokens.length == minimumDeposits.length);
        for (uint i = 0; i < minimumDeposits.length; ++i) {
            setSuperTokenMinimumDeposit(
                host,
                tokens[i],
                minimumDeposits[i]
            );
        }
    }

    function changeSuperTokenAdmin(ISuperfluid host, ISuperToken token, address newAdmin)
        external
        onlyAuthorized(host)
    {
        host.changeSuperTokenAdmin(token, newAdmin);
    }

    function batchChangeSuperTokenAdmin(ISuperfluid host, ISuperToken[] calldata token, address[] calldata newAdmins)
        external
        onlyAuthorized(host)
    {
        assert(token.length == newAdmins.length);
        for (uint i = 0; i < token.length; ++i) {
            host.changeSuperTokenAdmin(token[i], newAdmins[i]);
        }
    }

    event ConfigChanged(
        ISuperfluid indexed host,
        ISuperfluidToken indexed superToken,
        bytes32 key,
		bool isKeySet,
        uint256 value);

    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        address value
    )
        external override
    {
        _setConfig(host, superToken, key, value);
    }

    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        uint256 value
    )
        external override
    {
        _setConfig(host, superToken, key, value);
    }

    function clearConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    )
        external override
    {
        _clearConfig(host, superToken, key);
    }

    function _setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        address value
    )
        internal
        onlyAuthorized(host)
    {
        emit ConfigChanged(host, superToken, key, true, uint256(uint160(value)));
        _configs[address(host)][address(superToken)][key] = Value(true, uint256(uint160(value)));
    }

    function _setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        uint256 value
    )
        internal
        onlyAuthorized(host)
    {
        emit ConfigChanged(host, superToken, key, true, value);
        _configs[address(host)][address(superToken)][key] = Value(true, value);
    }

    function _clearConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    )
        internal
        onlyAuthorized(host)
    {
        emit ConfigChanged(host, superToken, key, false, 0);
        _configs[address(host)][address(superToken)][key] = Value(false, 0);
    }

    function getConfigAsAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    )
        public view override
        returns(address value)
    {
        Value storage v = _configs[address(host)][address(superToken)][key];
        if (!v.set) {
            // fallback to default config
            v =  _configs[address(host)][address(0)][key];
        }
        return address(uint160(v.value));
    }

    function getConfigAsUint256(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    )
        public view override
        returns(uint256 period)
    {
        Value storage v = _configs[address(host)][address(superToken)][key];
        if (!v.set) {
            // fallback to default config
            v =  _configs[address(host)][address(0)][key];
        }
        return v.value;
    }

    /**************************************************************************
    /* Convenience methods for known Configurations
    /*************************************************************************/

    // Superfluid rewardAddress
    event RewardAddressChanged(
        ISuperfluid indexed host,
        ISuperfluidToken indexed superToken,
        bool isKeySet,
        address rewardAddress);

    function getRewardAddress(
        ISuperfluid host,
        ISuperfluidToken superToken
    )
        external view
        returns (address)
    {
        return getConfigAsAddress(
            host, superToken,
            SuperfluidGovernanceConfigs.SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY);
    }

    function setRewardAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        address rewardAddress
    )
        public
    {
        _setConfig(
            host, superToken,
            SuperfluidGovernanceConfigs.SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY,
            rewardAddress);
        emit RewardAddressChanged(host, superToken, true, rewardAddress);
    }

    function clearRewardAddress(
        ISuperfluid host,
        ISuperfluidToken superToken
    )
        external
    {
        _clearConfig(
            host, superToken,
            SuperfluidGovernanceConfigs.SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY);
        emit RewardAddressChanged(host, superToken, false, address(0));
    }

    // CFAv1 liquidationPeriod (DEPRECATED BY PPPConfigurationChanged)
    event CFAv1LiquidationPeriodChanged(
        ISuperfluid indexed host,
        ISuperfluidToken indexed superToken,
        bool isKeySet,
        uint256 liquidationPeriod);

    // CFAv1 PPPConfiguration - Liquidation Period + Patrician Period
    event PPPConfigurationChanged(
        ISuperfluid indexed host,
        ISuperfluidToken indexed superToken,
        bool isKeySet,
        uint256 liquidationPeriod,
        uint256 patricianPeriod);

    function getPPPConfig(
        ISuperfluid host,
        ISuperfluidToken superToken
    )
        external view
        returns (uint256 liquidationPeriod, uint256 patricianPeriod)
    {
        uint256 pppConfig = getConfigAsUint256(
            host,
            superToken,
            SuperfluidGovernanceConfigs.CFAV1_PPP_CONFIG_KEY
        );
        (liquidationPeriod, patricianPeriod) = SuperfluidGovernanceConfigs.decodePPPConfig(pppConfig);
    }

    function setPPPConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        uint256 liquidationPeriod,
        uint256 patricianPeriod
    )
        public
    {
        if (liquidationPeriod <= patricianPeriod
            || liquidationPeriod >= type(uint32).max
            || patricianPeriod >= type(uint32).max
        ) {
            revert SF_GOV_INVALID_LIQUIDATION_OR_PATRICIAN_PERIOD();
        }
        uint256 value = (uint256(liquidationPeriod) << 32) | uint256(patricianPeriod);
        _setConfig(
            host,
            superToken,
            SuperfluidGovernanceConfigs.CFAV1_PPP_CONFIG_KEY,
            value
        );
        emit PPPConfigurationChanged(host, superToken, true, liquidationPeriod, patricianPeriod);
    }

    function clearPPPConfig(
        ISuperfluid host,
        ISuperfluidToken superToken
    )
        external
    {
        _clearConfig(host, superToken, SuperfluidGovernanceConfigs.CFAV1_PPP_CONFIG_KEY);
        emit PPPConfigurationChanged(host, superToken, false, 0, 0);
    }

    // CFAv1 minimum deposit
    event SuperTokenMinimumDepositChanged(
        ISuperfluid indexed host,
        ISuperfluidToken indexed superToken,
        bool isKeySet,
        uint256 minimumDeposit
    );

    function getSuperTokenMinimumDeposit(
        ISuperfluid host,
        ISuperfluidToken superToken
    )
        external view
        returns (uint256 value)
    {
        return getConfigAsUint256(host, superToken,
            SuperfluidGovernanceConfigs.SUPERTOKEN_MINIMUM_DEPOSIT_KEY);
    }

    function setSuperTokenMinimumDeposit(
        ISuperfluid host,
        ISuperfluidToken superToken,
        uint256 value
    )
        public
    {
        _setConfig(host, superToken, SuperfluidGovernanceConfigs.SUPERTOKEN_MINIMUM_DEPOSIT_KEY, value);
        emit SuperTokenMinimumDepositChanged(host, superToken, true, value);
    }

    function clearSuperTokenMinimumDeposit(
        ISuperfluid host,
        ISuperToken superToken
    )
        external
    {
        _clearConfig(host, superToken, SuperfluidGovernanceConfigs.SUPERTOKEN_MINIMUM_DEPOSIT_KEY);
        emit SuperTokenMinimumDepositChanged(host, superToken, false, 0);
    }

    // trustedForwarder
    event TrustedForwarderChanged(
        ISuperfluid indexed host,
        ISuperfluidToken indexed superToken,
        bool isKeySet,
        address forwarder,
        bool enabled);

    function isTrustedForwarder(
        ISuperfluid host,
        ISuperfluidToken superToken,
        address forwarder
    )
        external view
        returns (bool)
    {
        return getConfigAsUint256(
            host, superToken,
            SuperfluidGovernanceConfigs.getTrustedForwarderConfigKey(forwarder)) == 1;
    }

    function enableTrustedForwarder(
        ISuperfluid host,
        ISuperfluidToken superToken,
        address forwarder
    )
        public
    {
        _setConfig(
            host, superToken,
            SuperfluidGovernanceConfigs.getTrustedForwarderConfigKey(forwarder),
            1);
        emit TrustedForwarderChanged(host, superToken, true, forwarder, true);
    }

    function disableTrustedForwarder(
        ISuperfluid host,
        ISuperfluidToken superToken,
        address forwarder
    )
        external
    {
        _clearConfig(
            host, superToken,
            SuperfluidGovernanceConfigs.getTrustedForwarderConfigKey(forwarder));
        emit TrustedForwarderChanged(host, superToken, true, forwarder, false);
    }

    // Superfluid registrationKey
    event AppRegistrationKeyChanged(
        ISuperfluid indexed host,
        address indexed deployer,
        string appRegistrationKey,
        uint256 expirationTs
    );

    function verifyAppRegistrationKey(
        ISuperfluid host,
        address deployer,
        string memory registrationKey
    )
        external view
        returns(bool validNow, uint256 expirationTs)
    {
        bytes32 configKey = SuperfluidGovernanceConfigs.getAppRegistrationConfigKey(
            deployer,
            registrationKey
        );
        uint256 expirationTS = getConfigAsUint256(host, ISuperfluidToken(address(0)), configKey);
        return (
            // solhint-disable-next-line not-rely-on-time
            expirationTS >= block.timestamp,
            expirationTS
        );
    }

    function setAppRegistrationKey(
        ISuperfluid host,
        address deployer,
        string memory registrationKey,
        uint256 expirationTs
    )
        external
    {
        bytes32 configKey = SuperfluidGovernanceConfigs.getAppRegistrationConfigKey(
            deployer,
            registrationKey
        );
        _setConfig(host, ISuperfluidToken(address(0)), configKey, expirationTs);
        emit AppRegistrationKeyChanged(host, deployer, registrationKey, expirationTs);
    }

    function clearAppRegistrationKey(
        ISuperfluid host,
        address deployer,
        string memory registrationKey
    )
        external
    {
        bytes32 configKey = SuperfluidGovernanceConfigs.getAppRegistrationConfigKey(
            deployer,
            registrationKey
        );
        _clearConfig(host, ISuperfluidToken(address(0)), configKey);
        emit AppRegistrationKeyChanged(host, deployer, registrationKey, 0);
    }

    // Superfluid App factory
    event AppFactoryAuthorizationChanged(
        ISuperfluid indexed host,
        address indexed factory,
        bool authorized
    );

    /**
     * @dev tells if the given factory is authorized to register apps
     */
    function isAuthorizedAppFactory(
        ISuperfluid host,
        address factory
    )
        external view
        returns (bool)
    {
        return getConfigAsUint256(
            host, ISuperfluidToken(address(0)),
            SuperfluidGovernanceConfigs.getAppFactoryConfigKey(factory)) == 1;
    }

    /**
     * @dev allows the given factory to register new apps without requiring onetime keys
     * @param factory must be an initialized contract
     */
    function authorizeAppFactory(
        ISuperfluid host,
        address factory
    )
        external
    {
        // check if contract
        {
            uint256 cs;
            // solhint-disable-next-line no-inline-assembly
            assembly { cs := extcodesize(factory) }
            if (cs == 0) revert SF_GOV_MUST_BE_CONTRACT();
        }
        _setConfig(
            host, ISuperfluidToken(address(0)),
            SuperfluidGovernanceConfigs.getAppFactoryConfigKey(factory),
            1);
        emit AppFactoryAuthorizationChanged(host, factory, true);
    }

    /**
     * @dev withdraws authorization from a factory to register new apps.
     * Doesn't affect apps previously registered by the factory.
     */
    function unauthorizeAppFactory(
        ISuperfluid host,
        address factory
    )
        external
    {
        _clearConfig(
            host, ISuperfluidToken(address(0)),
            SuperfluidGovernanceConfigs.getAppFactoryConfigKey(factory));
        emit AppFactoryAuthorizationChanged(host, factory, false);
    }

    // NOTE: we currently don't check anything with host in
    // SuperfluidGovernanceII and only assert that the host passed
    // is the correct host in TestGovernance
    modifier onlyAuthorized(ISuperfluid host) {
        _requireAuthorised(host);
        _;
    }

    function _requireAuthorised(ISuperfluid host) internal view virtual;
}
