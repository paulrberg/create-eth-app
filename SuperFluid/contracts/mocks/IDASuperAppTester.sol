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
    ISuperToken,
    ISuperApp
} from "../superfluid/Superfluid.sol";
import {
    IInstantDistributionAgreementV1
} from "../interfaces/agreements/IInstantDistributionAgreementV1.sol";


contract IDASuperAppTester is ISuperApp {

    ISuperfluid private _host;
    IInstantDistributionAgreementV1 private _ida;
    ISuperToken private _token;
    uint32 private _indexId;

    constructor(
        ISuperfluid host,
        uint256 configWord,
        IInstantDistributionAgreementV1 ida,
        ISuperToken token,
        uint32 indexId)
    {
        _host = host;
        _host.registerAppWithKey(configWord, "");
        _ida = ida;
        _token = token;
        _indexId = indexId;

        _host.callAgreement(
            _ida,
            abi.encodeCall(
                _ida.createIndex,
                (
                    _token,
                    _indexId,
                    new bytes(0) // placeholder ctx
                )
            ),
            new bytes(0) // user data
        );
    }

    function updateSubscription(
        address subscriber,
        uint128 units
    )
        external
    {
        _host.callAgreement(
            _ida,
            abi.encodeCall(
                _ida.updateSubscription,
                (
                    _token,
                    _indexId,
                    subscriber,
                    units,
                    new bytes(0) // placeholder ctx
                )
            ),
            new bytes(0) // user data
        );
    }

    function distribute(
        uint128 amount
    )
        external
    {
        _host.callAgreement(
            _ida,
            abi.encodeCall(
                _ida.distribute,
                (
                    _token,
                    _indexId,
                    amount,
                    new bytes(0) // placeholder ctx
                )
            ),
            new bytes(0) // user data
        );
    }

    function _expectCallback(
        bytes calldata ctx,
        bytes32 callbackType,
        bytes calldata agreementData
    )
        private view
    {
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        bytes32 expectedCallbackType;
        bytes4 expectedSelector;
        bytes memory expectedAgreementData;
        (
            expectedCallbackType,
            expectedSelector,
            expectedAgreementData
        ) = abi.decode(context.userData, (bytes32, bytes4, bytes));
        require(expectedCallbackType == callbackType, "wrong callbackType");
        require(expectedSelector == context.agreementSelector, "wrong agreementSelector");
        require(keccak256(expectedAgreementData) == keccak256(agreementData), "wrong aAgreementData");
    }

    event SubscriptionDataBefore(
        address publisher,
        uint32 indexId,
        bool approved,
        uint128 units,
        uint256 pendingDistribution);
    event SubscriptionDataAfter(
        address publisher,
        uint32 indexId,
        bool approved,
        uint128 units,
        uint256 pendingDistribution);
    function _packSubscriptionData(bytes32 agreementId) private view returns (bytes memory){
        address publisher;
        uint32 indexId;
        bool approved;
        uint128 units;
        uint256 pendingDistribution;
        (
            publisher,
            indexId,
            approved,
            units,
            pendingDistribution
        ) = _ida.getSubscriptionByID(_token, agreementId);
        return abi.encode(publisher, indexId, approved, units, pendingDistribution);
    }

    bool private _forceGetSubscriptionByID = false;
    function setForceGetSubscriptionByID() external {
        _forceGetSubscriptionByID = true;
    }

    function _emitSubscriptionDataEvents(bytes memory cbdata, bytes32 agreementId, bool deleted)
        private
    {
        address publisher;
        uint32 indexId;
        bool approved;
        uint128 units;
        uint256 pendingDistribution;

        if (cbdata.length > 0) {
            (
                publisher,
                indexId,
                approved,
                units,
                pendingDistribution
            ) = abi.decode(cbdata, (address, uint32, bool, uint128, uint256));
            emit SubscriptionDataBefore(publisher, indexId, approved, units, pendingDistribution);
        }

        if (!deleted) {
            (
                publisher,
                indexId,
                approved,
                units,
                pendingDistribution
            ) = _ida.getSubscriptionByID(_token, agreementId);
            emit SubscriptionDataAfter(publisher, indexId, approved, units, pendingDistribution);
        }
    }

    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external view
        requireValidCtx(ctx)
        onlyExpected(superToken, agreementClass)
        virtual override
        returns (bytes memory cbdata)
    {
        _expectCallback(ctx, keccak256("created"), agreementData);
        if (_forceGetSubscriptionByID) {
            _ida.getSubscriptionByID(_token, agreementId);
        }
        return new bytes(0);
    }

    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        onlyExpected(superToken, agreementClass)
        virtual override
        returns (bytes memory newCtx)
    {
        _expectCallback(ctx, keccak256("created"), agreementData);
        _emitSubscriptionDataEvents(cbdata, agreementId, false);
        return ctx;
    }

    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external view
        requireValidCtx(ctx)
        onlyExpected(superToken, agreementClass)
        virtual override
        returns (bytes memory /*cbdata*/)
    {
        _expectCallback(ctx, keccak256("updated"), agreementData);
        return _packSubscriptionData(agreementId);
    }

    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        onlyExpected(superToken, agreementClass)
        virtual override
        returns (bytes memory newCtx)
    {
        _expectCallback(ctx, keccak256("updated"), agreementData);
        _emitSubscriptionDataEvents(cbdata, agreementId, false);
        return ctx;
    }

    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external view
        requireValidCtx(ctx)
        onlyExpected(superToken, agreementClass)
        virtual override
        returns (bytes memory /*cbdata*/)
    {
        _expectCallback(ctx, keccak256("deleted"), agreementData);
        return _packSubscriptionData(agreementId);
    }

    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        onlyExpected(superToken, agreementClass)
        virtual override
        returns (bytes memory newCtx)
    {
        _expectCallback(ctx, keccak256("deleted"), agreementData);
        _emitSubscriptionDataEvents(cbdata, agreementId, true);
        return ctx;
    }

    modifier requireValidCtx(bytes calldata ctx) {
        require(ISuperfluid(msg.sender).isCtxValid(ctx), "IDASuperAppTester: ctx not valid before");
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(superToken == _token, "not accepted token");
        require(agreementClass == address(_ida), "not ida");
        _;
    }
}
