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
    ISuperfluid, ISuperToken, SuperAppBase, ISuperApp, SuperAppDefinitions, IConstantFlowAgreementV1, ISuperAgreement
} from "../apps/SuperAppBase.sol";
import { CFAv1Library } from "../apps/CFAv1Library.sol";

contract StreamRedirector is SuperAppBase {
    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1;
    ISuperfluid public host;
    bytes32 public constant CFA_ID =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    address public receiver; // flow is redirected to hardcoded receiver address
    ISuperToken public token; // accepted super token

    constructor(
        ISuperfluid _host,
        ISuperToken _token,
        address _receiver,
        uint256 _appLevel
    ) {
        assert(address(_token) != address(0));
        assert(address(_receiver) != address(0));
        assert(address(_host) != address(0));

        host = _host;

        cfaV1 = CFAv1Library.InitData(
            host,
            IConstantFlowAgreementV1(address(host.getAgreementClass(CFA_ID)))
        );

        uint256 configWord = _appLevel |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        token = _token;
        receiver = _receiver;

        host.registerAppWithKey(configWord, "");
    }

    /**
     * Custom Errors
     */
    error OnlyHost();
    error OnlyCFA();
    error UnsupportedToken();

    /**
     * Creates a stream from an _originAccount who has granted this SuperApp ACL permissions
     * to this SuperApp.
     * @param _originAccount ACL permissions granter
     * @param _flowRate desired flow rate
     */
    function startStreamToSelf(address _originAccount, int96 _flowRate) public {
        cfaV1.createFlowByOperator(
            _originAccount,
            address(this),
            token,
            _flowRate
        );
    }

    /**
     * Terminates a stream from an _originAccount who has granted this SuperApp ACL permissions
     * @param _originAccount ACL permissions granter
     */
    function stopStreamToSelf(address _originAccount) public {
        cfaV1.deleteFlowByOperator(_originAccount, address(this), token);
    }

    /**
     * Creates a stream from this Super App to another SuperApp.
     * @param _superApp the targeted super app
     * @param _flowRate desired flow rate
     */
    function startStreamToSuperApp(address _superApp, int96 _flowRate) public {
        cfaV1.createFlow(_superApp, token, _flowRate);
    }

    /**
     * Delete a stream from sender to receiver.
     * @param _sender the sender super app
     * @param _receiver the receiver super app
     */
    function stopStreamToSuperApp(address _sender, address _receiver) public {
        cfaV1.deleteFlow(_sender, _receiver, token);
    }

    /**
     * A callback which occurs after CF agreement creation which redirects a stream.
     */
    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // agreementId,
        bytes calldata, // agreementData,
        bytes calldata, // cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyHost
        onlySupportedSuperToken(_superToken)
        onlyCFA(_agreementClass)
        returns (bytes memory newCtx)
    {
        newCtx = _ctx;
        int96 netFlowRate = cfaV1.cfa.getNetFlow(_superToken, address(this));
        newCtx = cfaV1.createFlowWithCtx(
            newCtx,
            receiver,
            _superToken,
            netFlowRate
        );
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // calldata _agreementData,
        bytes calldata, // calldata _cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        if (!_isCFAv1(_agreementClass) || address(_superToken) != address(token)) {
            return _ctx;
        }

        newCtx = _ctx;
        (, int96 currentFlowRate, , ) = cfaV1.cfa.getFlow(
            _superToken,
            address(this),
            receiver
        );

        if (currentFlowRate > 0) {
            newCtx = cfaV1.deleteFlowWithCtx(
                newCtx,
                address(this),
                receiver,
                _superToken
            );
        }
    }

    /**
     * Alleviates the composite app rule by allowing this app to call
     * the target app.
     * @param _targetApp address of the target super app, should be initialized with final_level
     */
    function allowCompositeApp(address _targetApp) public {
        host.allowCompositeApp(ISuperApp(_targetApp));
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType() == CFA_ID;
    }

    /**
     * Modifiers
     */
    modifier onlyHost() {
        if (msg.sender != address(host)) revert OnlyHost();
        _;
    }
    modifier onlySupportedSuperToken(ISuperToken _superToken) {
        if (address(_superToken) != address(token)) revert UnsupportedToken();
        _;
    }

    modifier onlyCFA(address agreementClass) {
        if (!_isCFAv1(agreementClass)) revert OnlyCFA();
        _;
    }
}
