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

import { SafeCast } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeCast.sol";
import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";
import { UUPSProxy } from "../upgradability/UUPSProxy.sol";
import { SafeGasLibrary } from "../libs/SafeGasLibrary.sol";

import {
    ISuperfluid,
    ISuperfluidGovernance,
    ISuperAgreement,
    ISuperApp,
    SuperAppDefinitions,
    ContextDefinitions,
    BatchOperation,
    SuperfluidGovernanceConfigs,
    ISuperfluidToken,
    ISuperToken,
    ISuperTokenFactory
} from "../interfaces/superfluid/ISuperfluid.sol";

import { CallUtils } from "../libs/CallUtils.sol";
import { BaseRelayRecipient } from "../libs/BaseRelayRecipient.sol";

/**
 * @dev The Superfluid host implementation.
 *
 * NOTE:
 * - Please read ISuperfluid for implementation notes.
 * - For some deeper technical notes, please visit protocol-monorepo wiki area.
 *
 * @author Superfluid
 */
contract Superfluid is
    UUPSProxiable,
    ISuperfluid,
    BaseRelayRecipient
{

    using SafeCast for uint256;

    struct AppManifest {
        uint256 configWord;
    }

    // solhint-disable-next-line var-name-mixedcase
    bool immutable public NON_UPGRADABLE_DEPLOYMENT;

    // solhint-disable-next-line var-name-mixedcase
    bool immutable public APP_WHITE_LISTING_ENABLED;

    /**
     * @dev Maximum number of level of apps can be composed together
     *
     * NOTE:
     * - TODO Composite app feature is currently disabled. Hence app cannot
     *   will not be able to call other app.
     */
    // solhint-disable-next-line var-name-mixedcase
    uint constant public MAX_APP_CALLBACK_LEVEL = 1;

    // solhint-disable-next-line var-name-mixedcase
    uint64 constant public CALLBACK_GAS_LIMIT = 3000000;

    uint32 constant public MAX_NUM_AGREEMENTS = 256;

    /* WARNING: NEVER RE-ORDER VARIABLES! Always double-check that new
       variables are added APPEND-ONLY. Re-ordering variables can
       permanently BREAK the deployed proxy contract. */

    /// @dev Governance contract
    ISuperfluidGovernance internal _gov;

    /// @dev Agreement list indexed by agreement index minus one
    ISuperAgreement[] internal _agreementClasses;
    /// @dev Mapping between agreement type to agreement index (starting from 1)
    mapping (bytes32 => uint) internal _agreementClassIndices;

    /// @dev Super token
    ISuperTokenFactory internal _superTokenFactory;

    /// @dev App manifests
    mapping(ISuperApp => AppManifest) internal _appManifests;
    /// @dev Composite app white-listing: source app => (target app => isAllowed)
    mapping(ISuperApp => mapping(ISuperApp => bool)) internal _compositeApps;
    /// @dev Ctx stamp of the current transaction, it should always be cleared to
    ///      zero before transaction finishes
    bytes32 internal _ctxStamp;
    /// @dev if app whitelisting is enabled, this is to make sure the keys are used only once
    mapping(bytes32 => bool) internal _appKeysUsedDeprecated;

    /// NOTE: Whenever modifying the storage layout here it is important to update the validateStorageLayout
    /// function in its respective mock contract to ensure that it doesn't break anything or lead to unexpected
    /// behaviors/layout when upgrading

    constructor(bool nonUpgradable, bool appWhiteListingEnabled) {
        NON_UPGRADABLE_DEPLOYMENT = nonUpgradable;
        APP_WHITE_LISTING_ENABLED = appWhiteListingEnabled;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // UUPSProxiable
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function initialize(
        ISuperfluidGovernance gov
    )
        external
        initializer // OpenZeppelin Initializable
    {
        _gov = gov;
    }

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.superfluid-finance.contracts.Superfluid.implementation");
    }

    function updateCode(address newAddress) external override onlyGovernance {
        if (NON_UPGRADABLE_DEPLOYMENT) revert HOST_NON_UPGRADEABLE();
        if (Superfluid(newAddress).NON_UPGRADABLE_DEPLOYMENT()) revert HOST_CANNOT_DOWNGRADE_TO_NON_UPGRADEABLE();
        _updateCodeAddress(newAddress);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Time
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getNow() public view  returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Governance
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getGovernance() external view override returns (ISuperfluidGovernance) {
        return _gov;
    }

    function replaceGovernance(ISuperfluidGovernance newGov) external override onlyGovernance {
        emit GovernanceReplaced(_gov, newGov);
        _gov = newGov;
    }

    /**************************************************************************
     * Agreement Whitelisting
     *************************************************************************/

    function registerAgreementClass(ISuperAgreement agreementClassLogic) external onlyGovernance override {
        bytes32 agreementType = agreementClassLogic.agreementType();
        if (_agreementClassIndices[agreementType] != 0) {
            revert HOST_AGREEMENT_ALREADY_REGISTERED();
        }
        if (_agreementClasses.length >= MAX_NUM_AGREEMENTS) revert HOST_MAX_256_AGREEMENTS();
        ISuperAgreement agreementClass;
        if (!NON_UPGRADABLE_DEPLOYMENT) {
            // initialize the proxy
            UUPSProxy proxy = new UUPSProxy();
            proxy.initializeProxy(address(agreementClassLogic));
            agreementClass = ISuperAgreement(address(proxy));
        } else {
            agreementClass = ISuperAgreement(address(agreementClassLogic));
        }
        // register the agreement proxy
        _agreementClasses.push((agreementClass));
        _agreementClassIndices[agreementType] = _agreementClasses.length;
        emit AgreementClassRegistered(agreementType, address(agreementClassLogic));
    }

    function updateAgreementClass(ISuperAgreement agreementClassLogic) external onlyGovernance override {
        if (NON_UPGRADABLE_DEPLOYMENT) revert HOST_NON_UPGRADEABLE();
        bytes32 agreementType = agreementClassLogic.agreementType();
        uint idx = _agreementClassIndices[agreementType];
        if (idx == 0) {
            revert HOST_AGREEMENT_IS_NOT_REGISTERED();
        }
        UUPSProxiable proxiable = UUPSProxiable(address(_agreementClasses[idx - 1]));
        proxiable.updateCode(address(agreementClassLogic));
        emit AgreementClassUpdated(agreementType, address(agreementClassLogic));
    }

    function isAgreementTypeListed(bytes32 agreementType)
        external view override
        returns (bool yes)
    {
        uint idx = _agreementClassIndices[agreementType];
        return idx != 0;
    }

    function isAgreementClassListed(ISuperAgreement agreementClass)
        public view override
        returns (bool yes)
    {
        bytes32 agreementType = agreementClass.agreementType();
        uint idx = _agreementClassIndices[agreementType];
        // it should also be the same agreement class proxy address
        return idx != 0 && _agreementClasses[idx - 1] == agreementClass;
    }

    function getAgreementClass(bytes32 agreementType)
        external view override
        returns(ISuperAgreement agreementClass)
    {
        uint idx = _agreementClassIndices[agreementType];
        if (idx == 0) {
            revert HOST_AGREEMENT_IS_NOT_REGISTERED();
        }
        return ISuperAgreement(_agreementClasses[idx - 1]);
    }

    function mapAgreementClasses(uint256 bitmap)
        external view override
        returns (ISuperAgreement[] memory agreementClasses) {
        uint i;
        uint n;
        // create memory output using the counted size
        agreementClasses = new ISuperAgreement[](_agreementClasses.length);
        // add to the output
        n = 0;
        for (i = 0; i < _agreementClasses.length; ++i) {
            if ((bitmap & (1 << i)) > 0) {
                agreementClasses[n++] = _agreementClasses[i];
            }
        }
        // resize memory arrays
        assembly { mstore(agreementClasses, n) }
    }

    function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view override
        returns (uint256 newBitmap)
    {
        uint idx = _agreementClassIndices[agreementType];
        if (idx == 0) {
            revert HOST_AGREEMENT_IS_NOT_REGISTERED();
        }
        return bitmap | (1 << (idx - 1));
    }

    function removeFromAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view override
        returns (uint256 newBitmap)
    {
        uint idx = _agreementClassIndices[agreementType];
        if (idx == 0) {
            revert HOST_AGREEMENT_IS_NOT_REGISTERED();
        }
        return bitmap & ~(1 << (idx - 1));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Super Token Factory
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getSuperTokenFactory()
        external view override
        returns (ISuperTokenFactory factory)
    {
        return _superTokenFactory;
    }

    function getSuperTokenFactoryLogic()
        external view override
        returns (address logic)
    {
        assert(address(_superTokenFactory) != address(0));
        if (NON_UPGRADABLE_DEPLOYMENT) return address(_superTokenFactory);
        else return UUPSProxiable(address(_superTokenFactory)).getCodeAddress();
    }

    function updateSuperTokenFactory(ISuperTokenFactory newFactory)
        external override
        onlyGovernance
    {
        if (address(_superTokenFactory) == address(0)) {
            if (!NON_UPGRADABLE_DEPLOYMENT) {
                // initialize the proxy
                UUPSProxy proxy = new UUPSProxy();
                proxy.initializeProxy(address(newFactory));
                _superTokenFactory = ISuperTokenFactory(address(proxy));
            } else {
                _superTokenFactory = newFactory;
            }
            _superTokenFactory.initialize();
        } else {
            if (NON_UPGRADABLE_DEPLOYMENT) revert HOST_NON_UPGRADEABLE();
            UUPSProxiable(address(_superTokenFactory)).updateCode(address(newFactory));
        }
        emit SuperTokenFactoryUpdated(_superTokenFactory);
    }

    function updateSuperTokenLogic(ISuperToken token, address newLogicOverride)
        external override
        onlyGovernance
    {
        address newLogic = newLogicOverride != address(0) ?
            newLogicOverride :
            address(_superTokenFactory.getSuperTokenLogic());

        // assuming it's uups proxiable
        UUPSProxiable(address(token)).updateCode(newLogic);
        emit SuperTokenLogicUpdated(token, newLogic);
    }

    function changeSuperTokenAdmin(ISuperToken token, address newAdmin) external onlyGovernance {
        token.changeAdmin(newAdmin);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // App Registry
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperfluid
    function registerApp(uint256 configWord) external override {
        if (APP_WHITE_LISTING_ENABLED) {
            // for historical reasons, we internal use "k1" as default registration key
            // solhint-disable-next-line avoid-tx-origin
            _enforceAppRegistrationPermissioning("k1", tx.origin);
        }
        _registerApp(ISuperApp(msg.sender), configWord);
    }

    /// @inheritdoc ISuperfluid
    function registerApp(ISuperApp app, uint256 configWord) external override {
        // Cannot register an EOA as SuperApp
        if ((address(app)).code.length == 0) revert HOST_MUST_BE_CONTRACT();
        if (APP_WHITE_LISTING_ENABLED) {
            _enforceAppRegistrationPermissioning("k1", msg.sender);
        }
        _registerApp(app, configWord);
    }

    /// @custom:deprecated
    function registerAppWithKey(uint256 configWord, string calldata registrationKey)
        external override
    {
        if (APP_WHITE_LISTING_ENABLED) {
            // solhint-disable-next-line avoid-tx-origin
            _enforceAppRegistrationPermissioning(registrationKey, tx.origin);
        }
        _registerApp(ISuperApp(msg.sender), configWord);
    }

    // internally we keep using the gov config method with key
    function _enforceAppRegistrationPermissioning(string memory registrationKey, address deployer) internal view {
        bytes32 configKey = SuperfluidGovernanceConfigs.getAppRegistrationConfigKey(
            // solhint-disable-next-line avoid-tx-origin
            deployer,
            registrationKey
        );
        // check if the key is valid and not expired
        if (
            _gov.getConfigAsUint256(
                this,
                ISuperfluidToken(address(0)),
                configKey
            // solhint-disable-next-line not-rely-on-time
            ) < block.timestamp)
        {
            revert HOST_NO_APP_REGISTRATION_PERMISSION();
        }
    }

    /// @custom:deprecated
    function registerAppByFactory(ISuperApp app, uint256 configWord) external override {
        // Cannot register an EOA as SuperApp
        if ((address(app)).code.length == 0) revert HOST_MUST_BE_CONTRACT();
        if (APP_WHITE_LISTING_ENABLED) {
            // enforce permissiniong with legacy gov config key for app factory
            bytes32 configKey = SuperfluidGovernanceConfigs.getAppFactoryConfigKey(msg.sender);
            bool isAuthorizedAppFactory = _gov.getConfigAsUint256(this, ISuperfluidToken(address(0)), configKey) == 1;
            if (!isAuthorizedAppFactory) revert HOST_NO_APP_REGISTRATION_PERMISSION();
            // We do not enforce any assumptions about what a "factory" is. It is whatever gov decided to.
        }
        _registerApp(app, configWord);
    }

    function _registerApp(ISuperApp app, uint256 configWord) private {
        // validate configWord
        if (
            !SuperAppDefinitions.isConfigWordClean(configWord) ||
            SuperAppDefinitions.getAppCallbackLevel(configWord) == 0 ||
            (configWord & SuperAppDefinitions.APP_JAIL_BIT) != 0
        ) {
            revert HOST_INVALID_CONFIG_WORD();
        }

        if (_appManifests[ISuperApp(app)].configWord != 0) revert HOST_SUPER_APP_ALREADY_REGISTERED();
        _appManifests[ISuperApp(app)] = AppManifest(configWord);
        emit AppRegistered(app);
    }

    function isApp(ISuperApp app) public view override returns(bool) {
        return _appManifests[app].configWord > 0;
    }

    function getAppCallbackLevel(ISuperApp appAddr) public override view returns(uint8) {
        return SuperAppDefinitions.getAppCallbackLevel(_appManifests[appAddr].configWord);
    }

    function getAppManifest(
        ISuperApp app
    )
        external view override
        returns (
            bool isSuperApp,
            bool isJailed,
            uint256 noopMask
        )
    {
        AppManifest memory manifest = _appManifests[app];
        isSuperApp = (manifest.configWord > 0);
        if (isSuperApp) {
            isJailed = SuperAppDefinitions.isAppJailed(manifest.configWord);
            noopMask = manifest.configWord & SuperAppDefinitions.AGREEMENT_CALLBACK_NOOP_BITMASKS;
        }
    }

    function isAppJailed(
        ISuperApp app
    )
        external view override
        returns(bool)
    {
        return SuperAppDefinitions.isAppJailed(_appManifests[app].configWord);
    }

    function allowCompositeApp(
        ISuperApp targetApp
    )
        external override
    {
        ISuperApp sourceApp = ISuperApp(msg.sender);
        if (!isApp(sourceApp)) revert HOST_SENDER_IS_NOT_SUPER_APP();
        if (!isApp(targetApp)) revert HOST_RECEIVER_IS_NOT_SUPER_APP();
        if (getAppCallbackLevel(sourceApp) <= getAppCallbackLevel(targetApp)) {
            revert HOST_SOURCE_APP_NEEDS_HIGHER_APP_LEVEL();
        }
        _compositeApps[sourceApp][targetApp] = true;
    }

    function isCompositeAppAllowed(
        ISuperApp app,
        ISuperApp targetApp
    )
        external view override
        returns (bool)
    {
        return _compositeApps[app][targetApp];
    }

    /**************************************************************************
     * Agreement Framework
     *************************************************************************/

    function callAppBeforeCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external override
        onlyAgreement
        assertValidCtx(ctx)
        returns(bytes memory cbdata)
    {
        (bool success, bytes memory returnedData) = _callCallback(app, true, isTermination, callData, ctx);
        if (success) {
            if (CallUtils.isValidAbiEncodedBytes(returnedData)) {
                cbdata = abi.decode(returnedData, (bytes));
            } else {
                if (!isTermination) {
                    revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_MALFORMATED);
                } else {
                    _jailApp(app, SuperAppDefinitions.APP_RULE_CTX_IS_MALFORMATED);
                }
            }
        }
    }

    function callAppAfterCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external override
        onlyAgreement
        assertValidCtx(ctx)
        returns(bytes memory newCtx)
    {
        (bool success, bytes memory returnedData) = _callCallback(app, false, isTermination, callData, ctx);
        if (success) {
            // the non static callback should not return empty ctx
            if (CallUtils.isValidAbiEncodedBytes(returnedData)) {
                newCtx = abi.decode(returnedData, (bytes));
                if (!_isCtxValid(newCtx)) {
                    if (!isTermination) {
                        revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_READONLY);
                    } else {
                        newCtx = ctx;
                        _jailApp(app, SuperAppDefinitions.APP_RULE_CTX_IS_READONLY);
                    }
                }
            } else {
                if (!isTermination) {
                    revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_MALFORMATED);
                } else {
                    newCtx = ctx;
                    _jailApp(app, SuperAppDefinitions.APP_RULE_CTX_IS_MALFORMATED);
                }
            }
        } else {
            newCtx = ctx;
        }
    }

    function appCallbackPush(
        bytes calldata ctx,
        ISuperApp app,
        uint256 appCreditGranted,
        int256 appCreditUsed,
        ISuperfluidToken appCreditToken
    )
        external override
        onlyAgreement
        assertValidCtx(ctx)
        returns (bytes memory appCtx)
    {
        Context memory context = decodeCtx(ctx);
        // NOTE: we use 1 as a magic number here as we want to do this check once we are in a callback
        // we use 1 instead of MAX_APP_CALLBACK_LEVEL because 1 captures what we are trying to enforce
        if (isApp(ISuperApp(context.msgSender)) && context.appCallbackLevel >= 1) {
            if (!_compositeApps[ISuperApp(context.msgSender)][app]) {
                revert APP_RULE(SuperAppDefinitions.APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED);
            }
        }
        context.appCallbackLevel++;
        context.callType = ContextDefinitions.CALL_INFO_CALL_TYPE_APP_CALLBACK;
        context.appCreditGranted = appCreditGranted;
        context.appCreditUsed = appCreditUsed;
        context.appAddress = address(app);
        context.appCreditToken = appCreditToken;
        appCtx = _updateContext(context);
    }

    function appCallbackPop(
        bytes calldata ctx,
        int256 appCreditUsedDelta
    )
        external override
        onlyAgreement
        returns (bytes memory newCtx)
    {
        Context memory context = decodeCtx(ctx);
        context.appCreditUsed += appCreditUsedDelta;
        newCtx = _updateContext(context);
    }

    function ctxUseCredit(
        bytes calldata ctx,
        int256 appCreditUsedMore
    )
        external override
        onlyAgreement
        assertValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        Context memory context = decodeCtx(ctx);
        context.appCreditUsed += appCreditUsedMore;

        newCtx = _updateContext(context);
    }

    function jailApp(
        bytes calldata ctx,
        ISuperApp app,
        uint256 reason
    )
        external override
        onlyAgreement
        assertValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        _jailApp(app, reason);
        return ctx;
    }

    /**************************************************************************
    * Contextless Call Proxies
    *************************************************************************/

    function _callAgreement(
        address msgSender,
        ISuperAgreement agreementClass,
        bytes memory callData,
        bytes memory userData
    )
        internal
        cleanCtx
        isAgreement(agreementClass)
        returns(bytes memory returnedData)
    {
        // beware of the endianness
        bytes4 agreementSelector = CallUtils.parseSelector(callData);

        //Build context data
        bytes memory ctx = _updateContext(Context({
            appCallbackLevel: 0,
            callType: ContextDefinitions.CALL_INFO_CALL_TYPE_AGREEMENT,
            timestamp: getNow(),
            msgSender: msgSender,
            agreementSelector: agreementSelector,
            userData: userData,
            appCreditGranted: 0,
            appCreditWantedDeprecated: 0,
            appCreditUsed: 0,
            appAddress: address(0),
            appCreditToken: ISuperfluidToken(address(0))
        }));
        bool success;
        (success, returnedData) = _callExternalWithReplacedCtx(address(agreementClass), callData, 0, ctx);
        if (!success) {
            CallUtils.revertFromReturnedData(returnedData);
        }
        // clear the stamp
        _ctxStamp = 0;
    }

    function callAgreement(
        ISuperAgreement agreementClass,
        bytes memory callData,
        bytes memory userData
    )
        external override
        returns(bytes memory returnedData)
    {
        return _callAgreement(msg.sender, agreementClass, callData, userData);
    }

    function _callAppAction(
        address msgSender,
        ISuperApp app,
        uint256 value,
        bytes memory callData
    )
        internal
        cleanCtx
        isAppActive(app)
        isValidAppAction(callData)
        returns(bytes memory returnedData)
    {
        // Build context data
        bytes memory ctx = _updateContext(Context({
            appCallbackLevel: 0,
            callType: ContextDefinitions.CALL_INFO_CALL_TYPE_APP_ACTION,
            timestamp: getNow(),
            msgSender: msgSender,
            agreementSelector: 0,
            userData: "",
            appCreditGranted: 0,
            appCreditWantedDeprecated: 0,
            appCreditUsed: 0,
            appAddress: address(app),
            appCreditToken: ISuperfluidToken(address(0))
        }));
        bool success;
        (success, returnedData) = _callExternalWithReplacedCtx(address(app), callData, value, ctx);
        if (success) {
            ctx = abi.decode(returnedData, (bytes));
            if (!_isCtxValid(ctx)) revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_READONLY);
        } else {
            CallUtils.revertFromReturnedData(returnedData);
        }
        // clear the stamp
        _ctxStamp = 0;
    }

    function callAppAction(
        ISuperApp app,
        bytes memory callData
    )
        external override // NOTE: modifiers are called in _callAppAction
        returns(bytes memory returnedData)
    {
        return _callAppAction(msg.sender, app, 0, callData);
    }

    /**************************************************************************
     * Contextual Call Proxies
     *************************************************************************/

    function callAgreementWithContext(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData,
        bytes calldata ctx
    )
        external override
        requireValidCtx(ctx)
        isAgreement(agreementClass)
        returns (bytes memory newCtx, bytes memory returnedData)
    {
        Context memory context = decodeCtx(ctx);
        if (context.appAddress != msg.sender) revert HOST_CALL_AGREEMENT_WITH_CTX_FROM_WRONG_ADDRESS();

        address oldSender = context.msgSender;
        context.msgSender = msg.sender;
        //context.agreementSelector =;
        context.userData = userData;
        newCtx = _updateContext(context);

        bool success;
        (success, returnedData) = _callExternalWithReplacedCtx(address(agreementClass), callData, 0, newCtx);
        if (success) {
            (newCtx) = abi.decode(returnedData, (bytes));
            assert(_isCtxValid(newCtx));
            // back to old msg.sender
            context = decodeCtx(newCtx);
            context.msgSender = oldSender;
            newCtx = _updateContext(context);
        } else {
            CallUtils.revertFromReturnedData(returnedData);
        }
    }

    function callAppActionWithContext(
        ISuperApp app,
        bytes calldata callData,
        bytes calldata ctx
    )
        external override
        requireValidCtx(ctx)
        isAppActive(app)
        isValidAppAction(callData)
        returns(bytes memory newCtx)
    {
        Context memory context = decodeCtx(ctx);
        if (context.appAddress != msg.sender) revert HOST_CALL_APP_ACTION_WITH_CTX_FROM_WRONG_ADDRESS();

        address oldSender = context.msgSender;
        context.msgSender = msg.sender;
        newCtx = _updateContext(context);

        (bool success, bytes memory returnedData) = _callExternalWithReplacedCtx(address(app), callData, 0, newCtx);
        if (success) {
            (newCtx) = abi.decode(returnedData, (bytes));
            if (!_isCtxValid(newCtx)) revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_READONLY);
            // back to old msg.sender
            context = decodeCtx(newCtx);
            context.msgSender = oldSender;
            newCtx = _updateContext(context);
        } else {
            CallUtils.revertFromReturnedData(returnedData);
        }
    }

    function decodeCtx(bytes memory ctx)
        public pure override
        returns (Context memory context)
    {
        return _decodeCtx(ctx);
    }

    function isCtxValid(bytes calldata ctx)
        external view override
        returns (bool)
    {
        return _isCtxValid(ctx);
    }

    /**************************************************************************
    * Batch call
    **************************************************************************/

    function _batchCall(
        address msgSender,
        Operation[] calldata operations
    )
       internal
    {
        bool valueForwarded = false;
        for (uint256 i = 0; i < operations.length; ++i) {
            uint32 operationType = operations[i].operationType;
            if (operationType == BatchOperation.OPERATION_TYPE_ERC20_APPROVE) {
                (address spender, uint256 amount) =
                    abi.decode(operations[i].data, (address, uint256));
                ISuperToken(operations[i].target).operationApprove(
                    msgSender,
                    spender,
                    amount);
            } else if (operationType == BatchOperation.OPERATION_TYPE_ERC20_TRANSFER_FROM) {
                (address sender, address receiver, uint256 amount) =
                    abi.decode(operations[i].data, (address, address, uint256));
                ISuperToken(operations[i].target).operationTransferFrom(
                    msgSender,
                    sender,
                    receiver,
                    amount);
            } else if (operationType == BatchOperation.OPERATION_TYPE_ERC777_SEND) {
                (address recipient, uint256 amount, bytes memory userData) =
                    abi.decode(operations[i].data, (address, uint256, bytes));
                ISuperToken(operations[i].target).operationSend(
                    msgSender,
                    recipient,
                    amount,
                    userData);
            } else if (operationType == BatchOperation.OPERATION_TYPE_ERC20_INCREASE_ALLOWANCE) {
                (address spender, uint256 addedValue) =
                    abi.decode(operations[i].data, (address, uint256));
                ISuperToken(operations[i].target).operationIncreaseAllowance(
                    msgSender,
                    spender,
                    addedValue);
            } else if (operationType == BatchOperation.OPERATION_TYPE_ERC20_DECREASE_ALLOWANCE) {
                (address spender, uint256 subtractedValue) =
                    abi.decode(operations[i].data, (address, uint256));
                ISuperToken(operations[i].target).operationDecreaseAllowance(
                    msgSender,
                    spender,
                    subtractedValue);
            } else if (operationType == BatchOperation.OPERATION_TYPE_SUPERTOKEN_UPGRADE) {
                ISuperToken(operations[i].target).operationUpgrade(
                    msgSender,
                    abi.decode(operations[i].data, (uint256))); // amount
            } else if (operationType == BatchOperation.OPERATION_TYPE_SUPERTOKEN_DOWNGRADE) {
                ISuperToken(operations[i].target).operationDowngrade(
                    msgSender,
                    abi.decode(operations[i].data, (uint256))); // amount
            } else if (operationType == BatchOperation.OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT) {
                (bytes memory callData, bytes memory userData) = abi.decode(operations[i].data, (bytes, bytes));
                _callAgreement(
                    msgSender,
                    ISuperAgreement(operations[i].target),
                    callData,
                    userData);
            } else if (operationType == BatchOperation.OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION) {
                _callAppAction(
                    msgSender,
                    ISuperApp(operations[i].target),
                    valueForwarded ? 0 : msg.value,
                    operations[i].data);
                valueForwarded = true;
            } else {
               revert HOST_UNKNOWN_BATCH_CALL_OPERATION_TYPE();
            }
        }
        if (msg.value != 0 && !valueForwarded) {
            // return ETH provided if not forwarded
            payable(msg.sender).transfer(msg.value);
        }
    }

    /// @dev ISuperfluid.batchCall implementation
    function batchCall(
       Operation[] calldata operations
    )
       external override payable
    {
        _batchCall(msg.sender, operations);
    }

    /// @dev ISuperfluid.forwardBatchCall implementation
    function forwardBatchCall(Operation[] calldata operations)
        external override
    {
        _batchCall(_getTransactionSigner(), operations);
    }

    /// @dev BaseRelayRecipient.isTrustedForwarder implementation
    function isTrustedForwarder(address forwarder)
        public view override
        returns(bool)
    {
        return _gov.getConfigAsUint256(
            this,
            ISuperfluidToken(address(0)),
            SuperfluidGovernanceConfigs.getTrustedForwarderConfigKey(forwarder)
        ) != 0;
    }

    /// @dev IRelayRecipient.isTrustedForwarder implementation
    function versionRecipient()
        external override pure
        returns (string memory)
    {
        return "v1";
    }

    /**************************************************************************
    * Internal
    **************************************************************************/

    function _jailApp(ISuperApp app, uint256 reason)
        internal
    {
        if ((_appManifests[app].configWord & SuperAppDefinitions.APP_JAIL_BIT) == 0) {
            _appManifests[app].configWord |= SuperAppDefinitions.APP_JAIL_BIT;
            emit Jail(app, reason);
        }
    }

    function _updateContext(Context memory context)
        private
        returns (bytes memory ctx)
    {
        if (context.appCallbackLevel > MAX_APP_CALLBACK_LEVEL) {
            revert APP_RULE(SuperAppDefinitions.APP_RULE_MAX_APP_LEVEL_REACHED);
        }
        uint256 callInfo = ContextDefinitions.encodeCallInfo(context.appCallbackLevel, context.callType);
        uint256 creditIO =
            context.appCreditGranted.toUint128() |
            (uint256(context.appCreditWantedDeprecated.toUint128()) << 128);
        // NOTE: nested encoding done due to stack too deep error when decoding in _decodeCtx
        ctx = abi.encode(
            abi.encode(
                callInfo,
                context.timestamp,
                context.msgSender,
                context.agreementSelector,
                context.userData
            ),
            abi.encode(
                creditIO,
                context.appCreditUsed,
                context.appAddress,
                context.appCreditToken
            )
        );
        _ctxStamp = keccak256(ctx);
    }

    function _decodeCtx(bytes memory ctx)
        private pure
        returns (Context memory context)
    {
        bytes memory ctx1;
        bytes memory ctx2;
        (ctx1, ctx2) = abi.decode(ctx, (bytes, bytes));
        {
            uint256 callInfo;
            (
                callInfo,
                context.timestamp,
                context.msgSender,
                context.agreementSelector,
                context.userData
            ) = abi.decode(ctx1, (
                uint256,
                uint256,
                address,
                bytes4,
                bytes));
            (context.appCallbackLevel, context.callType) = ContextDefinitions.decodeCallInfo(callInfo);
        }
        {
            uint256 creditIO;
            (
                creditIO,
                context.appCreditUsed,
                context.appAddress,
                context.appCreditToken
            ) = abi.decode(ctx2, (
                uint256,
                int256,
                address,
                ISuperfluidToken));
            context.appCreditGranted = creditIO & type(uint128).max;
            context.appCreditWantedDeprecated = creditIO >> 128;
        }
    }

    function _isCtxValid(bytes memory ctx) private view returns (bool) {
        return ctx.length != 0 && keccak256(ctx) == _ctxStamp;
    }

    function _callExternalWithReplacedCtx(
        address target,
        bytes memory callData,
        uint256 value,
        bytes memory ctx
    )
        private
        returns(bool success, bytes memory returnedData)
    {
        assert(target != address(0));

        // STEP 1 : replace placeholder ctx with actual ctx
        callData = _replacePlaceholderCtx(callData, ctx);

        // STEP 2: Call external with replaced context
        /* solhint-disable-next-line avoid-low-level-calls */
        (success, returnedData) = target.call{value: value}(callData);
        // if target is not a contract or some arbitrary address,
        // success will be true and returnedData will be 0x (length = 0)
        // this leads to unintended behaviors, so we want to check to ensure
        // that the length of returnedData is greater than 0

        if (success) {
            if (returnedData.length == 0) {
                revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_MALFORMATED);
            }
        }
    }

    function _callCallback(
        ISuperApp app,
        bool isStaticall,
        bool isTermination,
        bytes memory callData,
        bytes memory ctx
    )
        private
        returns(bool success, bytes memory returnedData)
    {
        assert(address(app) != address(0));

        callData = _replacePlaceholderCtx(callData, ctx);

        uint256 gasLimit = CALLBACK_GAS_LIMIT;
        uint256 gasLeftBefore = gasleft();
        if (isStaticall) {
            /* solhint-disable-next-line avoid-low-level-calls*/
            (success, returnedData) = address(app).staticcall{ gas: gasLimit }(callData);
        } else {
            /* solhint-disable-next-line avoid-low-level-calls*/
            (success, returnedData) = address(app).call{ gas: gasLimit }(callData);
        }

        if (!success) {
            // - "/ 63" is a magic to avoid out of gas attack.
            //   See: https://medium.com/@wighawag/ethereum-the-concept-of-gas-and-its-dangers-28d0eb809bb2.
            // - Without it, an app callback may use this to block the APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK jail
            //   rule.
            // - Also note that, the CALLBACK_GAS_LIMIT given to the app includes the overhead an app developer may not
            //   have direct control of, such as abi decoding code block. It is recommend for the app developer to stay
            //   at least 30000 less gas usage from that value to not trigger
            //   APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK.
            if (!SafeGasLibrary._isOutOfGas(gasLeftBefore)) {
                if (!isTermination) {
                    CallUtils.revertFromReturnedData(returnedData);
                } else {
                    _jailApp(app, SuperAppDefinitions.APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK);
                }
            } else {
                // For legit out of gas issue, the call may still fail if more gas is provided
                // and this is okay, because there can be incentive to jail the app by providing
                // more gas.
                revert HOST_NEED_MORE_GAS();
            }
        }
    }

    /**
     * @dev Replace the placeholder ctx with the actual ctx
     */
    function _replacePlaceholderCtx(bytes memory data, bytes memory ctx)
        internal pure
        returns (bytes memory dataWithCtx)
    {
        // 1.a ctx needs to be padded to align with 32 bytes boundary
        uint256 dataLen = data.length;

        // Double check if the ctx is a placeholder ctx
        //
        // NOTE: This can't check all cases - user can still put nonzero length of zero data
        // developer experience check. So this is more like a sanity check for clumsy app developers.
        //
        // So, agreements MUST NOT TRUST the ctx passed to it, and always use the isCtxValid first.
        {
            uint256 placeHolderCtxLength;
            // NOTE: len(data) is data.length + 32 https://docs.soliditylang.org/en/latest/abi-spec.html
            // solhint-disable-next-line no-inline-assembly
            assembly { placeHolderCtxLength := mload(add(data, dataLen)) }
            if (placeHolderCtxLength != 0) revert HOST_NON_ZERO_LENGTH_PLACEHOLDER_CTX();
        }

        // 1.b remove the placeholder ctx
        // solhint-disable-next-line no-inline-assembly
        assembly { mstore(data, sub(dataLen, 0x20)) }

        // 1.c pack data with the replacement ctx
        return abi.encodePacked(
            data,
            // bytes with padded length
            uint256(ctx.length),
            ctx, new bytes(CallUtils.padLength32(ctx.length) - ctx.length) // ctx padding
        );
        // NOTE: the alternative placeholderCtx is passing extra calldata to the agreements
        // agreements would use assembly code to read the ctx
        // Because selector is part of calldata, we do the padding internally, instead of
        // outside
    }

    modifier requireValidCtx(bytes memory ctx) {
        if (!_isCtxValid(ctx)) revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_READONLY);
        _;
    }

    modifier assertValidCtx(bytes memory ctx) {
        assert(_isCtxValid(ctx));
        _;
    }

    modifier cleanCtx() {
        if (_ctxStamp != 0) revert APP_RULE(SuperAppDefinitions.APP_RULE_CTX_IS_NOT_CLEAN);
        _;
    }

    modifier isAgreement(ISuperAgreement agreementClass) {
        if (!isAgreementClassListed(agreementClass)) {
            revert HOST_ONLY_LISTED_AGREEMENT();
        }
        _;
    }

    modifier onlyGovernance() {
        if (msg.sender != address(_gov)) revert HOST_ONLY_GOVERNANCE();
        _;
    }

    modifier onlyAgreement() {
        if (!isAgreementClassListed(ISuperAgreement(msg.sender))) {
            revert HOST_ONLY_LISTED_AGREEMENT();
        }
        _;
    }

    modifier isAppActive(ISuperApp app) {
        uint256 configWord = _appManifests[app].configWord;
        if (configWord == 0) revert HOST_NOT_A_SUPER_APP();
        if (SuperAppDefinitions.isAppJailed(configWord)) revert HOST_SUPER_APP_IS_JAILED();
        _;
    }

    modifier isValidAppAction(bytes memory callData) {
        bytes4 actionSelector = CallUtils.parseSelector(callData);
        if (actionSelector == ISuperApp.beforeAgreementCreated.selector ||
            actionSelector == ISuperApp.afterAgreementCreated.selector ||
            actionSelector == ISuperApp.beforeAgreementUpdated.selector ||
            actionSelector == ISuperApp.afterAgreementUpdated.selector ||
            actionSelector == ISuperApp.beforeAgreementTerminated.selector ||
            actionSelector == ISuperApp.afterAgreementTerminated.selector) {
            revert HOST_AGREEMENT_CALLBACK_IS_NOT_ACTION();
        }
        _;
    }
}
