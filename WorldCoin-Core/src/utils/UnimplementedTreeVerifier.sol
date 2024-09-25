/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/WorldCoin-Core?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ITreeVerifier} from "../interfaces/ITreeVerifier.sol";

/// @title Unimplemented Tree Verifier
/// @author Worldcoin
/// @notice A tree verifier instance that will always revert.
/// @dev This verifier is used as the default implementation for the update and remove endpoints in
///      the WorldID identity manager. We do not currently have ZK circuit designs for these
///      endpoints, but having the contract portion already implemented makes it easier for the
///      future where those will work.
contract UnimplementedTreeVerifier is ITreeVerifier {
    /// @notice Thrown when an operation is not supported.
    error UnsupportedOperation();

    /// @notice Verifies the provided proof data for the provided public inputs.
    /// @dev Exists to satisfy the interface. Will always revert.
    ///
    /// @param a The first G1Point of the proof (ar).
    /// @param b The G2Point for the proof (bs).
    /// @param c The second G1Point of the proof (kr).
    /// @param input The public inputs to the function, reduced such that it is a member of the
    ///              field `Fr` where `r` is `SNARK_SCALAR_FIELD`.
    ///
    /// @custom:reverts UnsupportedOperation When called.
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external pure returns (bool) {
        delete a;
        delete b;
        delete c;
        delete input;
        revert UnsupportedOperation();
    }
}
