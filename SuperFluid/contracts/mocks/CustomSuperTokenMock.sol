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

import { CustomSuperTokenBase, ISuperToken } from "../interfaces/superfluid/CustomSuperTokenBase.sol";
import { UUPSProxy } from "../upgradability/UUPSProxy.sol";

abstract contract CustomSuperTokenBaseMock is CustomSuperTokenBase, UUPSProxy {
    function getFirstCustomTokenStorageSlot() external pure virtual returns (uint slot);

    function callSelfBurn(
        address to,
        uint256 amount,
        bytes memory userData
    ) external virtual;

    function callSelfTransferFrom(
        address holder,
        address spender,
        address recipient,
        uint256 amount
    ) external virtual;

    function callSelfApproveFor(
        address account,
        address spender,
        uint256 amount
    ) external virtual;
}

// solhint-disable-next-line no-empty-blocks
abstract contract CustomSuperTokenMock is CustomSuperTokenBaseMock, ISuperToken {}

contract CustomSuperTokenProxyMock is CustomSuperTokenBaseMock {

    uint256 private _firstStorageSlot;

    function getFirstCustomTokenStorageSlot() external pure override returns (uint slot) {
        assembly { slot:= _firstStorageSlot.slot }
    }

    // this function overrides the default ISuperToken.selfMint behavior
    function selfMint(
        address to,
        uint256 amount,
        bytes memory userData
    ) external {
        // this makes msg.sender to self
        this.delegatecallSelfMint(to, amount, userData);
    }

    // this function uses delegatecall to avoid calling shadow mint defined in this contract
    function delegatecallSelfMint(
        address to,
        uint256 amount,
        bytes memory userData
    ) external {
        address logic = _implementation();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(
            abi.encodeCall(
                ISuperToken(address(this)).selfMint,
                (
                    to,
                    amount,
                    userData
                )
            )
        );
        assert(success);
    }

    // this function self calls burn
    function callSelfBurn(
        address to,
        uint256 amount,
        bytes memory userData
    ) external override {
        // this makes msg.sender to self
        ISuperToken(address(this)).selfBurn(to, amount, userData);
    }

    // this function self calls transferFrom
    function callSelfTransferFrom(
        address holder,
        address spender,
        address recipient,
        uint256 amount
    ) external override {
        ISuperToken(address(this)).selfTransferFrom(holder, spender, recipient, amount);
    }

    // this function self calls approveFor
    function callSelfApproveFor(
        address account,
        address spender,
        uint256 amount
    ) external override {
        ISuperToken(address(this)).selfApproveFor(account, spender, amount);
    }
}
