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

import {
    ISuperfluid,
    ISuperToken,
    ISuperfluidToken,
    ISuperApp,
    SuperAppDefinitions
} from "../interfaces/superfluid/ISuperfluid.sol";
import { AgreementBase } from "../agreements/AgreementBase.sol";
import { AgreementLibrary } from "../agreements/AgreementLibrary.sol";


contract AgreementMock is AgreementBase {

    using SafeCast for uint256;

    uint256 constant private _REAL_TIME_BALANCE_SLOT_ID = 65552025;

    // using immutable, otherweise the proxy contract would see zero instead
    bytes32 immutable private _type;
    uint immutable private _version;

    constructor(address host, bytes32 t, uint v) AgreementBase(host) {
        _type = t;
        _version = v;
    }

    function version() external view returns (uint) { return _version; }

    function agreementType() external override view returns (bytes32) {
        return _type;
    }

    function realtimeBalanceOf(
       ISuperfluidToken token,
       address account,
       uint256 /* time */
    )
       external view override
       returns (
           int256 dynamicBalance,
           uint256 deposit,
           uint256 owedDeposit
       )
    {
        bytes32[] memory slotData = token.getAgreementStateSlot(
            address(this), account, _REAL_TIME_BALANCE_SLOT_ID, 3);
        return (
            uint256(slotData[0]).toInt256(),
            uint256(slotData[1]),
            uint256(slotData[2])
        );
    }

    /**
     * SuperfluidToken Mockings
     */

    function setRealtimeBalanceFor(
        ISuperfluidToken token,
        address account,
        int256 dynamicBalance,
        uint256 deposit,
        uint256 owedDeposit
    ) external {
        bytes32[] memory slotData = new bytes32[](3);
        slotData[0] = bytes32(uint256(dynamicBalance));
        slotData[1] = bytes32(uint256(deposit));
        slotData[2] = bytes32(uint256(owedDeposit));
        token.updateAgreementStateSlot(account, _REAL_TIME_BALANCE_SLOT_ID, slotData);
    }

    function createAgreementFor(
        ISuperfluidToken token,
        bytes32 id,
        bytes32[] calldata data
        ) external {
        token.createAgreement(id, data);
    }

    function updateAgreementDataFor(
        ISuperfluidToken token,
        bytes32 id,
        bytes32[] calldata data
        ) external {
        token.updateAgreementData(id, data);
    }

    function terminateAgreementFor(
        ISuperfluidToken token,
        bytes32 id,
        uint dataLength
        ) external {
        token.terminateAgreement(id, dataLength);
    }

    function updateAgreementStateSlotFor(
        ISuperfluidToken token,
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
        ) external {
        token.updateAgreementStateSlot(account, slotId, slotData);
    }

    function settleBalanceFor(
        ISuperfluidToken token,
        address account,
        int256 delta
        ) external {
        token.settleBalance(account, delta);
    }

    function makeLiquidationPayoutsFor(
        ISuperfluidToken token,
        bytes32 id,
        bool useDefaultRewardAccount,
        address liquidator,
        address targetAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta
    ) external {
        bytes memory liquidationTypeData = useDefaultRewardAccount
            ? abi.encode(1, 0)
            : abi.encode(1, 2);
        token.makeLiquidationPayoutsV2(
            id,
            liquidationTypeData,
            liquidator,
            useDefaultRewardAccount,
            targetAccount,
            rewardAmount,
            targetAccountBalanceDelta
        );
    }

    /**
     * Agreement Framework Mockings
     */

    function tryCallAppBeforeCallback(ISuperfluid host, ISuperApp appMock, bool hackCtx, bytes calldata ctx)
        external returns (bytes memory newCtx)
    {
        return host.callAppBeforeCallback(
            appMock,
            abi.encodeCall(
                appMock.beforeAgreementCreated,
                (
                    ISuperToken(address(0)), /* ISuperToken */
                    address(this), /* agreementClass */
                    bytes32(uint256(0)), /* agreementId */
                    new bytes(0), /* agreementData */
                    new bytes(0) /* placeholder ctx */
                )
            ),
            true, /* isTermination */
            hackCtx ? new bytes(0) : ctx);
    }

    function tryCallAppAfterCallback(ISuperfluid host, ISuperApp appMock, bool hackCtx, bytes calldata ctx)
        external returns (bytes memory newCtx)
    {
        return host.callAppAfterCallback(
            appMock,
            abi.encodeCall(
                appMock.afterAgreementCreated,
                (
                    ISuperToken(address(0)), /* ISuperToken */
                    address(this), /* agreementClass */
                    bytes32(uint256(0)), /* agreementId */
                    new bytes(0), /* agreementData */
                    new bytes(0), /* cbData */
                    new bytes(0) /* placeholder ctx */
                )
            ),
            true, /* isTermination */
            hackCtx ? new bytes(0) : ctx);
    }

    function tryAppCallbackPush(ISuperfluid host, ISuperApp appMock, bool hackCtx, bytes calldata ctx)
        external returns (bytes memory newCtx)
    {
        return host.appCallbackPush(hackCtx ? new bytes(0) : ctx, appMock, 0, 0, ISuperfluidToken(address(0)));
    }

    function tryAppCallbackPop(ISuperfluid host, bytes calldata ctx)
        external returns (bytes memory newCtx)
    {
        return host.appCallbackPop(ctx, 0);
    }

    function tryCtxUseCredit(ISuperfluid host, bool hackCtx, bytes calldata ctx)
        external returns (bytes memory newCtx)
    {
        return host.ctxUseCredit(hackCtx ? new bytes(0) : ctx, 0);
    }

    function tryJailApp(ISuperfluid host, ISuperApp appMock, bool hackCtx, bytes calldata ctx)
        external returns (bytes memory newCtx)
    {
        return host.jailApp(hackCtx ? new bytes(0) : ctx, appMock, 0);
    }

    /**
     * Trivial Agreement Operations
     */

    modifier requireValidCtx(bytes memory ctx) {
        require(ISuperfluid(msg.sender).isCtxValid(ctx), "AgreementMock: ctx not valid given by host?!");
        _;
    }

    /// doRevert agreement operation
    function doRevert(string calldata reason, bytes calldata ctx) external view requireValidCtx(ctx) {
        revert(reason);
    }

    /// pingMe agreement operation, emits Pong event
    event Pong(uint256 ping);

    function pingMe(address expectedMsgSender, uint256 ping, bytes calldata ctx)
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        assert(context.msgSender == expectedMsgSender);
        emit Pong(ping);
        return ctx;
    }

    /**
     * App Callback Mocking Agreement Operations
     */

    /// _callAppBeforeCallback base agreement operation, emits AppBeforeCallbackResult event
    event AppBeforeCallbackResult(
        uint8 appLevel,
        uint8 callType,
        bytes4 agreementSelector,
        bytes cbdata);

    function _callAppBeforeCallback(
        ISuperApp app,
        uint256 noopBit,
        bytes calldata ctx
    )
        private
    {
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        AgreementLibrary.CallbackInputs memory cbStates = AgreementLibrary.createCallbackInputs(
            ISuperfluidToken(address(0)) /* token */,
            address(app) /* account */,
            0 /* agreementId */,
            "" /* agreementData */
        );
        cbStates.noopBit = noopBit;
        bytes memory cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, ctx);
        emit AppBeforeCallbackResult(
            context.appCallbackLevel,
            context.callType,
            context.agreementSelector,
            cbdata);
    }

    /// _callAppAfterAgreementCallback base agreement operation, emits AppAfterCallbackResult event
    event AppAfterCallbackResult(
        uint8 appLevel,
        uint8 callType,
        bytes4 agreementSelector);

    function _callAppAfterAgreementCallback(
        ISuperApp app,
        uint256 noopBit,
        bytes calldata ctx
    )
        private returns (bytes memory newCtx)
    {
        bool isJailed = ISuperfluid(msg.sender).isAppJailed(app);
        ISuperfluid.Context memory context = ISuperfluid(msg.sender).decodeCtx(ctx);
        AgreementLibrary.CallbackInputs memory cbStates = AgreementLibrary.createCallbackInputs(
            ISuperfluidToken(address(0)) /* token */,
            address(app) /* account */,
            0 /* agreementId */,
            "" /* agreementData */
        );
        cbStates.noopBit = noopBit;
        ISuperfluid.Context memory appContext;
        (appContext, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, "", ctx);
        if (isJailed) {
            // appContext.callType is a sufficient check that the callback was not called at all
            require(appContext.callType == 0, "AgreementMock: callback should not reach jailed app");
        } else {
            require(ISuperfluid(msg.sender).isCtxValid(newCtx), "AgreementMock: ctx not valid after callback");
        }
        emit AppAfterCallbackResult(
            context.appCallbackLevel,
            context.callType,
            context.agreementSelector);
    }

    function callAppBeforeAgreementCreatedCallback(
        ISuperApp app,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        _callAppBeforeCallback(app, SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP, ctx);
        return ctx;
    }

    function callAppAfterAgreementCreatedCallback(
        ISuperApp app,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        return _callAppAfterAgreementCallback(app, SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP, ctx);
    }

    function callAppBeforeAgreementUpdatedCallback(
        ISuperApp app,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        _callAppBeforeCallback(app, SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP, ctx);
        return ctx;
    }

    function callAppAfterAgreementUpdatedCallback(
        ISuperApp app,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        return _callAppAfterAgreementCallback(app, SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP, ctx);
    }

    function callAppBeforeAgreementTerminatedCallback(
        ISuperApp app,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        _callAppBeforeCallback(app, SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP, ctx);
        newCtx = ctx;
    }

    function callAppAfterAgreementTerminatedCallback(
        ISuperApp app,
        bytes calldata ctx
    )
        external
        requireValidCtx(ctx)
        returns (bytes memory newCtx)
    {
        return _callAppAfterAgreementCallback(app, SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP, ctx);
    }

}
