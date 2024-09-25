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

// solhint-disable max-states-count
// Notes: SuperToken is rich with states, disable this default rule here.

import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";
import {
    ISuperfluid,
    ISuperToken,
    IERC20,
    IConstantOutflowNFT,
    IConstantInflowNFT
} from "../interfaces/superfluid/ISuperfluid.sol";
import { SuperfluidToken } from "./SuperfluidToken.sol";
import { ERC777Helper } from "../libs/ERC777Helper.sol";
import { SafeERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeCast } from "SuperFluid/@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC777Recipient } from "SuperFluid/@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import { IERC777Sender } from "SuperFluid/@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import { Address } from "SuperFluid/@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Superfluid's super token implementation
 *
 * @author Superfluid
 */
contract SuperToken is
    UUPSProxiable,
    SuperfluidToken,
    ISuperToken
{

    using SafeMath for uint256;
    using SafeCast for uint256;
    using Address for address;
    using ERC777Helper for ERC777Helper.Operators;
    using SafeERC20 for IERC20;

    // See: https://eips.ethereum.org/EIPS/eip-1967#admin-address
    bytes32 constant private _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    uint8 constant private _STANDARD_DECIMALS = 18;

    // solhint-disable-next-line var-name-mixedcase
    IConstantOutflowNFT immutable public CONSTANT_OUTFLOW_NFT;

    // solhint-disable-next-line var-name-mixedcase
    IConstantInflowNFT immutable public CONSTANT_INFLOW_NFT;

    /* WARNING: NEVER RE-ORDER VARIABLES! Including the base contracts.
       Always double-check that new
       variables are added APPEND-ONLY. Re-ordering variables can
       permanently BREAK the deployed proxy contract. */

    /// @dev The underlying ERC20 token
    IERC20 internal _underlyingToken;

    /// @dev Decimals of the underlying token
    uint8 internal _underlyingDecimals;

    /// @dev IERC20Metadata Name property
    string internal _name;

    /// @dev IERC20Metadata Symbol property
    string internal _symbol;

    /// @dev ERC20 Allowances Storage
    mapping(address => mapping (address => uint256)) internal _allowances;

    /// @dev ERC777 operators support data
    ERC777Helper.Operators internal _operators;

    // NOTE: for future compatibility, these are reserved solidity slots
    // The sub-class of SuperToken solidity slot will start after _reserve22

    // NOTE: Whenever modifying the storage layout here it is important to update the validateStorageLayout
    // function in its respective mock contract to ensure that it doesn't break anything or lead to unexpected
    // behaviors/layout when upgrading

    uint256 internal _reserve22;
    uint256 private _reserve23;
    uint256 private _reserve24;
    uint256 private _reserve25;
    uint256 private _reserve26;
    uint256 private _reserve27;
    uint256 private _reserve28;
    uint256 private _reserve29;
    uint256 private _reserve30;
    uint256 internal _reserve31;

    // NOTE: You cannot add more storage here. Refer to CustomSuperTokenBase.sol
    // to see the hard-coded storage padding used by SETH and PureSuperToken

    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    )
        SuperfluidToken(host)
        // solhint-disable-next-line no-empty-blocks
    {
        // @note This constructor is only run for the initial
        // deployment of the logic contract.

        // set the immutable canonical NFT proxy addresses
        CONSTANT_OUTFLOW_NFT = constantOutflowNFT;
        CONSTANT_INFLOW_NFT = constantInflowNFT;

        emit ConstantOutflowNFTCreated(constantOutflowNFT);
        emit ConstantInflowNFTCreated(constantInflowNFT);
    }

    /// @dev Initialize the Super Token proxy
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    )
        external
        virtual
        override
        initializer // OpenZeppelin Initializable
    {
        // @note This function is only run once during the initial
        // deployment of the proxy contract.

        // initialize the Super Token
        _initialize(underlyingToken, underlyingDecimals, n, s, address(0));
    }

    /// @dev Initialize the Super Token proxy with an admin
    function initializeWithAdmin(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s,
        address admin
    )
        external
        virtual
        override
        initializer // OpenZeppelin Initializable
    {
        // @note This function is only run once during the initial
        // deployment of the proxy contract.

        // initialize the Super Token
        _initialize(underlyingToken, underlyingDecimals, n, s, admin);
    }

    function proxiableUUID() public pure virtual override returns (bytes32) {
        return keccak256("org.superfluid-finance.contracts.SuperToken.implementation");
    }

    /**
     * @notice Updates the logic contract the proxy is pointing at
     * @dev Only the admin can call this function (host if admin == address(0))
     * @param newAddress Address of the new logic contract
     */
    function updateCode(address newAddress) external virtual override onlyAdmin {
        UUPSProxiable._updateCodeAddress(newAddress);

        // @note This is another check to ensure that when updating to a new SuperToken logic contract
        // that we have passed the correct NFT proxy contracts in the construction of the new SuperToken
        // logic contract
        if (
            CONSTANT_OUTFLOW_NFT !=
            SuperToken(newAddress).CONSTANT_OUTFLOW_NFT() ||
            CONSTANT_INFLOW_NFT !=
            SuperToken(newAddress).CONSTANT_INFLOW_NFT()
        ) {
            revert SUPER_TOKEN_NFT_PROXY_ADDRESS_CHANGED();
        }
    }

    function changeAdmin(address newAdmin) external override onlyAdmin {
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);

        emit AdminChanged(oldAdmin, newAdmin);
    }

    function getAdmin() external view override returns (address) {
        return _getAdmin();
    }

    function _getAdmin() internal view returns (address admin) {
        assembly {
            // solium-disable-line
            admin := sload(_ADMIN_SLOT)
        }
    }

    function _setAdmin(address newAdmin) internal {
        assembly {
            // solium-disable-line
            sstore(_ADMIN_SLOT, newAdmin)
        }
    }


    /**************************************************************************
     * ERC20 Token Info
     *************************************************************************/

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure virtual override returns (uint8) {
        return _STANDARD_DECIMALS;
    }

    /**************************************************************************
     * (private) Token Logics
     *************************************************************************/

    function _initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s,
        address admin
    ) internal {
        _underlyingToken = underlyingToken;
        _underlyingDecimals = underlyingDecimals;

        _name = n;
        _symbol = s;

        _setAdmin(admin);

        // register interfaces
        ERC777Helper.register(address(this));

        // help tools like explorers detect the token contract
        emit Transfer(address(0), address(0), 0);

        // previous admin will always be the zero address in an uninitialized contract
        emit AdminChanged(address(0), admin);
    }

    /**
     * @notice in the original openzeppelin implementation, transfer() and transferFrom()
     * did invoke the send and receive hooks, as required by ERC777.
     * This hooks were removed from super tokens for ERC20 transfers in order to protect
     * interfacing contracts which don't expect invocations of ERC20 transfers to potentially reenter.
     * Interactions relying on ERC777 hooks need to use the ERC777 interface.
     * For more context, see https://github.com/superfluid-finance/protocol-monorepo/wiki/About-ERC-777
     */
    function _transferFrom(address spender, address holder, address recipient, uint amount)
        internal returns (bool)
    {
        if (holder == address(0)) {
            revert SUPER_TOKEN_TRANSFER_FROM_ZERO_ADDRESS();
        }
        if (recipient == address(0)) {
            revert SUPER_TOKEN_TRANSFER_TO_ZERO_ADDRESS();
        }
        address operator = msg.sender;

        _move(operator, holder, recipient, amount, "", "");

        if (spender != holder) {
            _approve(
                holder,
                spender,
                _allowances[holder][spender].sub(amount, "SuperToken: transfer amount exceeds allowance"));
        }

        return true;
    }

    /**
     * @dev Send tokens
     * @param operator address operator address
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        internal
    {
        if (from == address(0)) {
            revert SUPER_TOKEN_TRANSFER_FROM_ZERO_ADDRESS();
        }
        if (to == address(0)) {
            revert SUPER_TOKEN_TRANSFER_TO_ZERO_ADDRESS();
        }

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        private
    {
        SuperfluidToken._move(from, to, amount.toInt256());

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If invokeHook is true and a send hook is registered for `account`,
     * the corresponding function will be called with `operator`, `userData` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20.Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `invokeHook` and `requireReceptionAck` are set and `account` is a contract,
     *   it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address operator,
        address account,
        uint256 amount,
        bool invokeHook,
        bool requireReceptionAck,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        if (account == address(0)) {
            revert SUPER_TOKEN_MINT_TO_ZERO_ADDRESS();
        }

        SuperfluidToken._mint(account, amount);

        if (invokeHook) {
            _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);
        }

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param userData bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _burn(
        address operator,
        address from,
        uint256 amount,
        bool invokeHook,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        if (from == address(0)) {
            revert SUPER_TOKEN_BURN_FROM_ZERO_ADDRESS();
        }

        if (invokeHook) {
            _callTokensToSend(operator, from, address(0), amount, userData, operatorData);
        }

        SuperfluidToken._burn(from, amount);

        emit Burned(operator, from, amount, userData, operatorData);
        emit Transfer(from, address(0), amount);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `account`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address account, address spender, uint256 amount)
        internal
    {
        if (account == address(0)) {
            revert SUPER_TOKEN_APPROVE_FROM_ZERO_ADDRESS();
        }
        if (spender == address(0)) {
            revert SUPER_TOKEN_APPROVE_TO_ZERO_ADDRESS();
        }

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        private
    {
        address implementer = ERC777Helper._ERC1820_REGISTRY.getInterfaceImplementer(
            from, ERC777Helper._TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        private
    {
        address implementer = ERC777Helper._ERC1820_REGISTRY.getInterfaceImplementer(
            to, ERC777Helper._TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            if (to.isContract()) revert SUPER_TOKEN_NOT_ERC777_TOKENS_RECIPIENT();
        }
    }

    /**************************************************************************
     * ERC20 Implementations
     *************************************************************************/

    function totalSupply()
        public view virtual override returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address account
    )
        public
        view
        virtual
        override
        returns(uint256 balance)
    {
        // solhint-disable-next-line not-rely-on-time
        (int256 availableBalance, , ,) = super.realtimeBalanceOfNow(account);
        return availableBalance < 0 ? 0 : uint256(availableBalance);
    }

    function transfer(address recipient, uint256 amount)
        public virtual override returns (bool)
    {
        return _transferFrom(msg.sender, msg.sender, recipient, amount);
    }

    function allowance(address account, address spender)
        public view virtual override returns (uint256)
    {
        return _allowances[account][spender];
    }

    function approve(address spender, uint256 amount)
        public virtual override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address holder, address recipient, uint256 amount)
        public virtual override returns (bool)
    {
        return _transferFrom(msg.sender, holder, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public virtual override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public virtual override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue,
            "SuperToken: decreased allowance below zero"));
        return true;
    }

    /**************************************************************************
     * ERC-777 functions
     *************************************************************************/

    function granularity() external pure virtual override returns (uint256) { return 1; }

    function send(address recipient, uint256 amount, bytes calldata userData) external virtual override {
        _send(msg.sender, msg.sender, recipient, amount, userData, "", true);
    }

    function burn(uint256 amount, bytes calldata userData) external virtual override {
        _downgrade(msg.sender, msg.sender, msg.sender, amount, userData, "");
    }

    function isOperatorFor(address operator, address tokenHolder) external virtual override view returns (bool) {
        return _operators.isOperatorFor(operator, tokenHolder);
    }

    function authorizeOperator(address operator) external virtual override {
        address holder = msg.sender;
        _operators.authorizeOperator(holder, operator);
        emit AuthorizedOperator(operator, holder);
    }

    function revokeOperator(address operator) external virtual override {
        address holder = msg.sender;
        _operators.revokeOperator(holder, operator);
        emit RevokedOperator(operator, holder);
    }

    function defaultOperators() external virtual override view returns (address[] memory) {
        return ERC777Helper.defaultOperators(_operators);
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external virtual override {
        address operator = msg.sender;
        if (!_operators.isOperatorFor(operator, sender)) revert SUPER_TOKEN_CALLER_IS_NOT_OPERATOR_FOR_HOLDER();
        _send(operator, sender, recipient, amount, userData, operatorData, true);
    }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external virtual override {
        address operator = msg.sender;
        if (!_operators.isOperatorFor(operator, account)) revert SUPER_TOKEN_CALLER_IS_NOT_OPERATOR_FOR_HOLDER();
        _downgrade(operator, account, account, amount, userData, operatorData);
    }

    function _setupDefaultOperators(address[] memory operators) internal {
        _operators.setupDefaultOperators(operators);
    }

    /**************************************************************************
     * SuperToken custom token functions
     *************************************************************************/

    function selfMint(
        address account,
        uint256 amount,
        bytes memory userData
    )
        external virtual override
        onlySelf
    {
        _mint(msg.sender, account, amount, userData.length != 0 /* invokeHook */,
            userData.length != 0 /* requireReceptionAck */, userData, new bytes(0));
    }

    function selfBurn(
       address account,
       uint256 amount,
       bytes memory userData
    )
       external virtual override
       onlySelf
    {
       _burn(msg.sender, account, amount, userData.length != 0 /* invokeHook */, userData, new bytes(0));
    }

    function selfApproveFor(
        address account,
        address spender,
        uint256 amount
    )
        external virtual override
        onlySelf
    {
        _approve(account, spender, amount);
    }

    function selfTransferFrom(
        address holder,
        address spender,
        address recipient,
        uint256 amount
    )
        external virtual override
        onlySelf
    {
        _transferFrom(spender, holder, recipient, amount);
    }

    /**************************************************************************
     * SuperToken extra functions
     *************************************************************************/

    function transferAll(address recipient)
        external virtual override
    {
        _transferFrom(msg.sender, msg.sender, recipient, balanceOf(msg.sender));
    }

    /**************************************************************************
     * ERC20 wrapping
     *************************************************************************/

    /// @inheritdoc ISuperToken
    function getUnderlyingToken() external view virtual override returns(address) {
        return address(_underlyingToken);
    }

    /// @inheritdoc ISuperToken
    function getUnderlyingDecimals() external view virtual override returns (uint8) {
        return _underlyingDecimals;
    }

    /// @inheritdoc ISuperToken
    function toUnderlyingAmount(uint256 amount)
        external
        view
        virtual
        override
        returns (uint256 underlyingAmount, uint256 adjustedAmount)
    {
        return _toUnderlyingAmount(amount);
    }

    /// @inheritdoc ISuperToken
    function upgrade(uint256 amount) external virtual override {
        _upgrade(msg.sender, msg.sender, msg.sender, amount, "", "");
    }

    /// @inheritdoc ISuperToken
    function upgradeTo(address to, uint256 amount, bytes calldata userData) external virtual override {
        _upgrade(msg.sender, msg.sender, to, amount, userData, "");
    }

    /// @inheritdoc ISuperToken
    function downgrade(uint256 amount) external virtual override {
        _downgrade(msg.sender, msg.sender, msg.sender, amount, "", "");
    }

    /// @inheritdoc ISuperToken
    function downgradeTo(address to, uint256 amount) external virtual override {
        _downgrade(msg.sender, msg.sender, to, amount, "", "");
    }

    function _upgrade(
        address operator,
        address account,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        if (address(_underlyingToken) == address(0)) revert SUPER_TOKEN_NO_UNDERLYING_TOKEN();

        (uint256 underlyingAmount, uint256 adjustedAmount) = _toUnderlyingAmount(amount);

        uint256 amountBefore = _underlyingToken.balanceOf(address(this));
        _underlyingToken.safeTransferFrom(account, address(this), underlyingAmount);
        uint256 amountAfter = _underlyingToken.balanceOf(address(this));
        uint256 actualUpgradedAmount = amountAfter - amountBefore;
        if (underlyingAmount != actualUpgradedAmount) revert SUPER_TOKEN_INFLATIONARY_DEFLATIONARY_NOT_SUPPORTED();

        _mint(operator, to, adjustedAmount,
            // if `userData.length` is greater than 0, we set invokeHook and requireReceptionAck true
            userData.length != 0, userData.length != 0, userData, operatorData);

        emit TokenUpgraded(to, adjustedAmount);
    }

    function _downgrade(
        address operator, // the account executing the transaction
        address account,  // the account whose super tokens we are burning
        address to,       // the account receiving the underlying tokens
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        if (address(_underlyingToken) == address(0)) revert SUPER_TOKEN_NO_UNDERLYING_TOKEN();

        (uint256 underlyingAmount, uint256 adjustedAmount) = _toUnderlyingAmount(amount);

         // _burn will check the (actual) amount availability again
         _burn(operator, account, adjustedAmount, userData.length != 0, userData, operatorData);

        uint256 amountBefore = _underlyingToken.balanceOf(address(this));
        _underlyingToken.safeTransfer(to, underlyingAmount);
        uint256 amountAfter = _underlyingToken.balanceOf(address(this));
        uint256 actualDowngradedAmount = amountBefore - amountAfter;
        if (underlyingAmount != actualDowngradedAmount) revert SUPER_TOKEN_INFLATIONARY_DEFLATIONARY_NOT_SUPPORTED();

        emit TokenDowngraded(account, adjustedAmount);
    }

    /**
     * @dev Handle decimal differences between underlying token and super token
     */
    function _toUnderlyingAmount(uint256 amount)
        private view
        returns (uint256 underlyingAmount, uint256 adjustedAmount)
    {
        uint256 factor;
        if (_underlyingDecimals < _STANDARD_DECIMALS) {
            // if underlying has less decimals
            // one can upgrade less "granualar" amount of tokens
            factor = 10 ** (_STANDARD_DECIMALS - _underlyingDecimals);
            underlyingAmount = amount / factor;
            // remove precision errors
            adjustedAmount = underlyingAmount * factor;
        } else if (_underlyingDecimals > _STANDARD_DECIMALS) {
            // if underlying has more decimals
            // one can upgrade more "granualar" amount of tokens
            factor = 10 ** (_underlyingDecimals - _STANDARD_DECIMALS);
            underlyingAmount = amount * factor;
            adjustedAmount = amount;
        } else {
            underlyingAmount = adjustedAmount = amount;
        }
    }

    /**************************************************************************
     * Superfluid Batch Operations
     *************************************************************************/

    function operationApprove(
        address account,
        address spender,
        uint256 amount
    )
        external virtual override
        onlyHost
    {
        _approve(account, spender, amount);
    }

    function operationIncreaseAllowance(
        address account,
        address spender,
        uint256 addedValue
    )
        external virtual override
        onlyHost
    {
        _approve(account, spender, _allowances[account][spender] + addedValue);
    }

    function operationDecreaseAllowance(
        address account,
        address spender,
        uint256 subtractedValue
    )
        external virtual override
        onlyHost
    {
        _approve(account, spender, _allowances[account][spender].sub(subtractedValue,
            "SuperToken: decreased allowance below zero"));
    }

    function operationTransferFrom(
        address account,
        address spender,
        address recipient,
        uint256 amount
    )
        external virtual override
        onlyHost
    {
        _transferFrom(account, spender, recipient, amount);
    }

    function operationSend(
        address spender,
        address recipient,
        uint256 amount,
        bytes memory userData
    )
        external virtual override
        onlyHost
    {
        _send(msg.sender, spender, recipient, amount, userData, "", true);
    }

    function operationUpgrade(address account, uint256 amount)
        external virtual override
        onlyHost
    {
        _upgrade(msg.sender, account, account, amount, "", "");
    }

    function operationDowngrade(address account, uint256 amount)
        external virtual override
        onlyHost
    {
        _downgrade(msg.sender, account, account, amount, "", "");
    }

    /**************************************************************************
    * Modifiers
    *************************************************************************/

    modifier onlySelf() {
        if (msg.sender != address(this)) revert SUPER_TOKEN_ONLY_SELF();
        _;
    }

    /**
     * @dev The host contract is implicitly the admin if admin is address(0) else it is the explicitly set admin
     * override address
     */
    modifier onlyAdmin() {
        address adminSlotAdmin = _getAdmin();
        address admin = adminSlotAdmin == address(0) ? address(_host) : adminSlotAdmin;
        if (msg.sender != admin) revert SUPER_TOKEN_ONLY_ADMIN();
        _;
    }

}
