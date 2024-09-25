/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Proxy} from "Uniswap-V4/@openzeppelin/contracts/proxy/Proxy.sol";

/// @notice Mock contract that tracks the number of calls to various functions by selector
/// @dev allows for proxying to an implementation contract
///  if real logic or return values are needed
contract MockContract is Proxy {
    mapping(bytes32 => uint256) public calls;
    mapping(bytes32 => mapping(bytes => uint256)) public callParams;

    /// @notice If set, delegatecall to implementation after tracking call
    address internal impl;

    function timesCalledSelector(bytes32 selector) public view returns (uint256) {
        return calls[selector];
    }

    function timesCalled(string calldata fnSig) public view returns (uint256) {
        bytes32 selector = bytes32(uint256(keccak256(bytes(fnSig))) & (type(uint256).max << 224));
        return calls[selector];
    }

    function calledWithSelector(bytes32 selector, bytes calldata params) public view returns (bool) {
        return callParams[selector][params[1:]] > 0; // Drop 0x byte string prefix
    }

    function calledWith(string calldata fnSig, bytes calldata params) public view returns (bool) {
        bytes32 selector = bytes32(uint256(keccak256(bytes(fnSig))) & (type(uint256).max << 224));
        return callParams[selector][params[1:]] > 0; // Drop 0x byte string prefix
    }

    /// @notice exposes implementation contract address
    function _implementation() internal view override returns (address) {
        return impl;
    }

    function setImplementation(address _impl) external {
        impl = _impl;
    }

    /// @notice Captures calls by selector
    function _beforeFallback() internal override {
        bytes32 selector = bytes32(msg.data[:5]);
        bytes memory params = msg.data[5:];
        calls[selector]++;
        callParams[selector][params]++;
    }
}
