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

import { Context } from "SuperFluid/@openzeppelin/contracts/utils/Context.sol";
import { IERC20 } from "SuperFluid/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC777 } from "SuperFluid/@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC777Sender } from "SuperFluid/@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import { IERC777Recipient } from "SuperFluid/@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import { IERC1820Registry } from "SuperFluid/@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {
    ERC1820Implementer, IERC1820Implementer
} from "SuperFluid/@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

import { ISuperToken } from "../superfluid/SuperToken.sol";


contract ERC777SenderRecipientMock is Context, IERC777Sender, IERC777Recipient, ERC1820Implementer {
    event TokensToSendCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event TokensReceivedCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    bool private _shouldRevertSend;
    bool private _shouldRevertReceive;

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 constant private _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 constant private _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertSend) {
            revert("_shouldRevertSend");
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit TokensToSendCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertReceive) {
            revert("_shouldRevertReceive");
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit TokensReceivedCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function senderFor(address account) public {
        _registerInterfaceForAddress(_TOKENS_SENDER_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerSender(self);
        }
    }

    function registerSender(address sender) public {
        _erc1820.setInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, sender);
    }

    function recipientFor(address account) public {
        _registerInterfaceForAddress(_TOKENS_RECIPIENT_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerRecipient(self);
        }
    }

    function registerRecipient(address recipient) public {
        _erc1820.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, recipient);
    }

    function setShouldRevertSend(bool shouldRevert) public {
        _shouldRevertSend = shouldRevert;
    }

    function setShouldRevertReceive(bool shouldRevert) public {
        _shouldRevertReceive = shouldRevert;
    }

    function send(IERC777 token, address to, uint256 amount, bytes memory data) public {
        // This is 777's send function, not the Solidity send function
        token.send(to, amount, data); // solhint-disable-line check-send-result
    }

    function burn(IERC777 token, uint256 amount, bytes memory data) public {
        token.burn(amount, data);
    }

    function upgradeAll(ISuperToken token) public {
        IERC20 underlying = IERC20(token.getUnderlyingToken());
        uint256 amount = underlying.balanceOf(address(this));
        underlying.approve(address(token), amount);
        token.upgrade(amount);
    }

    function upgradeAllToSelf(ISuperToken token) public {
        IERC20 underlying = IERC20(token.getUnderlyingToken());
        uint256 amount = underlying.balanceOf(address(this));
        underlying.approve(address(token), amount);
        token.upgradeTo(address(this), amount, "");
    }
}

contract ERC777RecipientReverting is IERC777Recipient, IERC1820Implementer {
    bytes32 constant private _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // allow to use the hook for this contract itself
    constructor() {
        IERC1820Registry erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    function tokensReceived(
        address /*operator*/,
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external pure override {
        revert("they shall not pass");
    }

    // allow anybody to use the hook
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/)
        external pure override
        returns(bytes32)
    {
        return
            interfaceHash == _TOKENS_RECIPIENT_INTERFACE_HASH ?
            keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC")) :
            bytes32(0x00);
    }
}

/*
* ERC777Recipient which drains all gas it gets, trying to make the caller run out of gas
*/
contract ERC777RecipientDrainingGas is IERC777Recipient, IERC1820Implementer {
    bytes32 constant private _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    uint256 internal _uselessVar = 1;

    event DrainedGas(uint256 allowance, uint256 burned);

    function tokensReceived(
        address /*operator*/,
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*userData*/,
        bytes calldata /*operatorData*/
    ) external override {
        uint256 initialGas = gasleft();
        while (gasleft() > 30000) { // need to leave enough for the send() itself to not fail
            _uselessVar++; // SSTORE drains much faster than an empty loop
        }
        emit DrainedGas(initialGas, gasleft());
    }

    // allow anybody to use the hook
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/)
        external pure override
        returns(bytes32)
    {
        return
            interfaceHash == _TOKENS_RECIPIENT_INTERFACE_HASH ?
            keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC")) :
            bytes32(0x00);
    }
}


