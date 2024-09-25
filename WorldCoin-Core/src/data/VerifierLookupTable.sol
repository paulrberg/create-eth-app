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

import {Ownable2Step} from "WorldCoin-Core/lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import {ITreeVerifier} from "../interfaces/ITreeVerifier.sol";

/// @title Batch Lookup Table
/// @author Worldcoin
/// @notice A table that provides the correct tree verifier based on the provided batch size.
/// @dev It should be used to query the correct verifier before using that verifier for verifying a
///      tree modification proof.
contract VerifierLookupTable is Ownable2Step {
    ////////////////////////////////////////////////////////////////////////////////
    ///                                   DATA                                   ///
    ////////////////////////////////////////////////////////////////////////////////

    /// The null address.
    address internal constant nullAddress = address(0x0);

    /// The null verifier.
    ITreeVerifier internal constant nullVerifier = ITreeVerifier(nullAddress);

    /// The lookup table for routing batches.
    ///
    /// As we expect to only have a few batch sizes per contract, a mapping is used due to its
    /// natively sparse storage.
    mapping(uint256 => ITreeVerifier) internal verifier_lut;

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Raised if a batch size is requested that the lookup table doesn't know about.
    error NoSuchVerifier();

    /// @notice Raised if an attempt is made to add a verifier for a batch size that already exists.
    error VerifierExists();

    /// @notice Thrown when an attempt is made to renounce ownership.
    error CannotRenounceOwnership();

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                  ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a verifier is added to the lookup table.
    ///
    /// @param batchSize The size of the batch that the verifier has been added for.
    /// @param verifierAddress The address of the verifier that was associated with `batchSize`.
    event VerifierAdded(uint256 indexed batchSize, address indexed verifierAddress);

    /// @notice Emitted when a verifier is updated in the lookup table.
    ///
    /// @param batchSize The size of the batch that the verifier has been updated for.
    /// @param oldVerifierAddress The address of the old verifier for `batchSize`.
    /// @param newVerifierAddress The address of the new verifier for `batchSize`.
    event VerifierUpdated(
        uint256 indexed batchSize,
        address indexed oldVerifierAddress,
        address indexed newVerifierAddress
    );

    /// @notice Emitted when a verifier is disabled in the lookup table.
    ///
    /// @param batchSize The batch size that had its verifier disabled.
    event VerifierDisabled(uint256 indexed batchSize);

    ////////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTION                               ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Constructs a new batch lookup table.
    /// @dev It is initially constructed without any verifiers.
    constructor() Ownable2Step() {}

    ////////////////////////////////////////////////////////////////////////////////
    ///                                ACCESSORS                                 ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Obtains the verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to get the associated verifier for.
    ///
    /// @return verifier The tree verifier for the provided `batchSize`.
    ///
    /// @custom:reverts NoSuchVerifier If there is no verifier associated with the `batchSize`.
    function getVerifierFor(uint256 batchSize) public view returns (ITreeVerifier verifier) {
        // Check the preconditions for querying the verifier.
        validateVerifier(batchSize);

        // With the preconditions checked, we can return the verifier.
        verifier = verifier_lut[batchSize];
    }

    /// @notice Adds a verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to add the verifier for.
    /// @param verifier The verifier for a batch of size `batchSize`.
    ///
    /// @custom:reverts VerifierExists If `batchSize` already has an associated verifier.
    /// @custom:reverts string If the caller is not the owner.
    function addVerifier(uint256 batchSize, ITreeVerifier verifier) public onlyOwner {
        // Check that there is no entry for that batch size.
        if (verifier_lut[batchSize] != nullVerifier) {
            revert VerifierExists();
        }

        // Add the verifier.
        updateVerifier(batchSize, verifier);
        emit VerifierAdded(batchSize, address(verifier));
    }

    /// @notice Updates the verifier for the provided `batchSize`.
    ///
    /// @param batchSize The batch size to add the verifier for.
    /// @param verifier The verifier for a batch of size `batchSize`.
    ///
    /// @return oldVerifier The old verifier instance associated with this batch size.
    ///
    /// @custom:reverts string If the caller is not the owner.
    function updateVerifier(uint256 batchSize, ITreeVerifier verifier)
        public
        onlyOwner
        returns (ITreeVerifier oldVerifier)
    {
        oldVerifier = verifier_lut[batchSize];
        verifier_lut[batchSize] = verifier;
        emit VerifierUpdated(batchSize, address(oldVerifier), address(verifier));
    }

    /// @notice Disables the verifier for the provided batch size.
    ///
    /// @param batchSize The batch size to disable the verifier for.
    ///
    /// @return oldVerifier The old verifier associated with the batch size.
    ///
    /// @custom:reverts string If the caller is not the owner.
    function disableVerifier(uint256 batchSize)
        public
        onlyOwner
        returns (ITreeVerifier oldVerifier)
    {
        oldVerifier = updateVerifier(batchSize, ITreeVerifier(nullAddress));
        emit VerifierDisabled(batchSize);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                          INTERNAL FUNCTIONALITY                          ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Checks if the entry for the provided `batchSize` is a valid verifier.
    ///
    /// @param batchSize The batch size to check.
    ///
    /// @custom:reverts NoSuchVerifier If `batchSize` does not have an associated verifier.
    /// @custom:reverts BatchTooLarge If `batchSize` exceeds the maximum batch size.
    function validateVerifier(uint256 batchSize) internal view {
        if (verifier_lut[batchSize] == nullVerifier) {
            revert NoSuchVerifier();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                           OWNERSHIP MANAGEMENT                           ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Ensures that ownership of the lookup table cannot be renounced.
    /// @dev This function is intentionally not `virtual` as we do not want it to be possible to
    ///      renounce ownership for the lookup table.
    /// @dev This function is marked as `onlyOwner` to maintain the access restriction from the base
    ///      contract.
    function renounceOwnership() public view override onlyOwner {
        revert CannotRenounceOwnership();
    }
}
