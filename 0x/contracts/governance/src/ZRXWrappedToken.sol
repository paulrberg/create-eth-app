/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/0x?utm=code
  */
  
  // SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2023 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.8.19;

import "0x/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "0x/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "0x/@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import "0x/@openzeppelin/contracts/governance/utils/IVotes.sol";
import "0x/@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./IZeroExVotes.sol";
import "./CallWithGas.sol";

contract ZRXWrappedToken is ERC20, ERC20Permit, ERC20Wrapper {
    using CallWithGas for address;

    struct DelegateInfo {
        address delegate;
        uint96 balanceLastUpdated;
    }

    constructor(
        IERC20 wrappedToken,
        IZeroExVotes _zeroExVotes
    ) ERC20("Wrapped ZRX", "wZRX") ERC20Permit("Wrapped ZRX") ERC20Wrapper(wrappedToken) {
        zeroExVotes = _zeroExVotes;
    }

    IZeroExVotes public immutable zeroExVotes;
    mapping(address => DelegateInfo) private _delegates;

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // The functions below are the required overrides from the base contracts

    function decimals() public pure override(ERC20, ERC20Wrapper) returns (uint8) {
        return 18;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);

        DelegateInfo memory fromDelegate = delegateInfo(from);
        DelegateInfo memory toDelegate = delegateInfo(to);

        uint256 fromBalance = fromDelegate.delegate == address(0) ? 0 : balanceOf(from) + amount;
        uint256 toBalance = toDelegate.delegate == address(0) ? 0 : balanceOf(to) - amount;

        if (fromDelegate.delegate != address(0)) _delegates[from].balanceLastUpdated = SafeCast.toUint96(block.number);

        if (toDelegate.delegate != address(0)) _delegates[to].balanceLastUpdated = SafeCast.toUint96(block.number);

        zeroExVotes.moveVotingPower(
            fromDelegate.delegate,
            toDelegate.delegate,
            fromBalance,
            toBalance,
            fromDelegate.balanceLastUpdated,
            toDelegate.balanceLastUpdated,
            amount
        );
    }

    function _mint(address account, uint256 amount) internal override(ERC20) {
        super._mint(account, amount);

        zeroExVotes.writeCheckpointTotalSupplyMint(balanceOf(account) - amount, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);

        address(zeroExVotes).functionCallWithGas(
            abi.encodeCall(zeroExVotes.writeCheckpointTotalSupplyBurn, (balanceOf(account) + amount, amount)),
            500_000,
            32
        );
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view returns (address) {
        return _delegates[account].delegate;
    }

    /**
     * @dev Get the last block number when `account`'s balance changed.
     */
    function delegatorBalanceLastUpdated(address account) public view returns (uint96) {
        return _delegates[account].balanceLastUpdated;
    }

    function delegateInfo(address account) public view returns (DelegateInfo memory) {
        return _delegates[account];
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {IZeroExVotes-DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        DelegateInfo memory delegateInfo = delegateInfo(delegator);
        uint256 delegatorBalance = balanceOf(delegator);

        _delegates[delegator] = DelegateInfo(delegatee, SafeCast.toUint96(block.timestamp));

        emit DelegateChanged(delegator, delegateInfo.delegate, delegatee);

        zeroExVotes.moveVotingPower(
            delegateInfo.delegate,
            delegatee,
            delegatorBalance,
            0,
            delegateInfo.balanceLastUpdated,
            0,
            delegatorBalance
        );
    }
}
