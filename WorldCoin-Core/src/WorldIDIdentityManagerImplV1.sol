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

import {WorldIDImpl} from "./abstract/WorldIDImpl.sol";

import {IWorldID} from "./interfaces/IWorldID.sol";
import {ITreeVerifier} from "./interfaces/ITreeVerifier.sol";
import {ISemaphoreVerifier} from "WorldCoin-Core/lib/semaphore/packages/contracts/contracts/interfaces/ISemaphoreVerifier.sol";
import {IBridge} from "./interfaces/IBridge.sol";

import {SemaphoreTreeDepthValidator} from "./utils/SemaphoreTreeDepthValidator.sol";
import {VerifierLookupTable} from "./data/VerifierLookupTable.sol";

/// @title WorldID Identity Manager Implementation Version 1
/// @author Worldcoin
/// @notice An implementation of a batch-based identity manager for the WorldID protocol.
/// @dev The manager is based on the principle of verifying externally-created Zero Knowledge Proofs
///      to perform the insertions.
/// @dev This is the implementation delegated to by a proxy.
contract WorldIDIdentityManagerImplV1 is WorldIDImpl, IWorldID {
    ///////////////////////////////////////////////////////////////////////////////
    ///                   A NOTE ON IMPLEMENTATION CONTRACTS                    ///
    ///////////////////////////////////////////////////////////////////////////////

    // This contract is designed explicitly to operate from behind a proxy contract. As a result,
    // there are a few important implementation considerations:
    //
    // - All updates made after deploying a given version of the implementation should inherit from
    //   the latest version of the implementation. This prevents storage clashes.
    // - All functions that are less access-restricted than `private` should be marked `virtual` in
    //   order to enable the fixing of bugs in the existing interface.
    // - Any function that reads from or modifies state (i.e. is not marked `pure`) must be
    //   annotated with the `onlyProxy` and `onlyInitialized` modifiers. This ensures that it can
    //   only be called when it has access to the data in the proxy, otherwise results are likely to
    //   be nonsensical.
    // - This contract deals with important data for the WorldID system. Ensure that all newly-added
    //   functionality is carefully access controlled using `onlyOwner`, or a more granular access
    //   mechanism.
    // - Do not assign any contract-level variables at the definition site unless they are
    //   `constant`.
    //
    // Additionally, the following notes apply:
    //
    // - Initialisation and ownership management are not protected behind `onlyProxy` intentionally.
    //   This ensures that the contract can safely be disposed of after it is no longer used.
    // - Carefully consider what data recovery options are presented as new functionality is added.
    //   Care must be taken to ensure that a migration plan can exist for cases where upgrades
    //   cannot recover from an issue or vulnerability.

    ///////////////////////////////////////////////////////////////////////////////
    ///                    !!!!! DATA: DO NOT REORDER !!!!!                     ///
    ///////////////////////////////////////////////////////////////////////////////

    // To ensure compatibility between upgrades, it is exceedingly important that no reordering of
    // these variables takes place. If reordering happens, a storage clash will occur (effectively a
    // memory safety error).

    /// @notice The address of the contract authorized to perform identity management operations.
    /// @dev The identity operator defaults to being the same as the owner.
    address internal _identityOperator;

    /// @notice The latest root of the identity merkle tree.
    uint256 internal _latestRoot;

    /// @notice A mapping from the value of the merkle tree root to the timestamp at which the root
    ///         was superseded by a newer one.
    mapping(uint256 => uint128) internal rootHistory;

    /// @notice The amount of time an outdated root is considered as valid.
    /// @dev This prevents proofs getting invalidated in the mempool by another tx modifying the
    ///      group.
    uint256 internal rootHistoryExpiry;

    /// @notice The `r` for the finite field `Fr` under which arithmetic is done on the proof input.
    /// @dev Used internally to ensure that the proof input is scaled to within the field `Fr`.
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant SNARK_SCALAR_FIELD_MIN_ONE =
        21888242871839275222246405745257275088548364400416034343698204186575808495616;

    /// @notice The table of verifiers for verifying batch identity insertions.
    VerifierLookupTable internal batchInsertionVerifiers;

    /// @notice The table of verifiers for verifying identity updates.
    VerifierLookupTable internal identityUpdateVerifiers;

    /// @notice The verifier instance needed for operating within the semaphore protocol.
    ISemaphoreVerifier internal semaphoreVerifier;

    /// @notice The interface of the bridge contract from L1 to supported target chains.
    IBridge internal _stateBridge;

    /// @notice Boolean flag to enable/disable the state bridge.
    bool internal _isStateBridgeEnabled;

    /// @notice The depth of the Semaphore merkle tree.
    uint8 internal treeDepth;

    ///////////////////////////////////////////////////////////////////////////////
    ///                               PUBLIC TYPES                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Provides information about a merkle tree root.
    ///
    /// @param root The value of the merkle tree root.
    /// @param supersededTimestamp The timestamp at which the root was inserted into the history.
    ///        This may be 0 if the requested root is the current root (which has not yet been
    ///        inserted into the history).
    /// @param isValid Whether or not the root is valid (has not expired).
    struct RootInfo {
        uint256 root;
        uint128 supersededTimestamp;
        bool isValid;
    }

    /// @notice Represents the kind of element that has not been provided in reduced form.
    enum UnreducedElementType {
        PreRoot,
        IdentityCommitment,
        PostRoot
    }

    /// @notice Represents the kind of change that is made to the root of the tree.
    enum TreeChange {
        Insertion,
        Deletion,
        Update
    }

    /// @notice Represents the kinds of dependencies that can be updated.
    enum Dependency {
        StateBridge,
        InsertionVerifierLookupTable,
        DeletionVerifierLookupTable,
        UpdateVerifierLookupTable,
        SemaphoreVerifier
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                             CONSTANT FUNCTIONS                          ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice A constant representing a root that doesn't exist.
    /// @dev Can be checked against when querying for root data.
    function NO_SUCH_ROOT() public pure returns (RootInfo memory rootInfo) {
        return RootInfo(0x0, 0x0, false);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when encountering an element that should be reduced as a member of `Fr` but
    ///         is not.
    /// @dev `r` in this case is given by `SNARK_SCALAR_FIELD`.
    ///
    /// @param elementType The kind of element that was encountered unreduced.
    /// @param element The value of that element.
    error UnreducedElement(UnreducedElementType elementType, uint256 element);

    /// @notice Thrown when trying to execute a privileged action without being the contract
    ///         manager.
    ///
    /// @param user The user that attempted the action that they were not authorised for.
    error Unauthorized(address user);

    /// @notice Thrown when one or more of the identity commitments to be inserted is invalid.
    ///
    /// @param index The index in the array of identity commitments where the invalid commitment was
    ///        found.
    error InvalidCommitment(uint256 index);

    /// @notice Thrown when the provided proof cannot be verified for the accompanying inputs.
    error ProofValidationFailure();

    /// @notice Thrown when the provided root is not the very latest root.
    ///
    /// @param providedRoot The root that was provided as the `preRoot` for a transaction.
    /// @param latestRoot The actual latest root at the time of the transaction.
    error NotLatestRoot(uint256 providedRoot, uint256 latestRoot);

    /// @notice Thrown when attempting to enable the bridge when it is already enabled.
    error StateBridgeAlreadyEnabled();

    /// @notice Thrown when attempting to disable the bridge when it is already disabled.
    error StateBridgeAlreadyDisabled();

    /// @notice Thrown when attempting to set the state bridge address to the zero address.
    error InvalidStateBridgeAddress();

    /// @notice Thrown when Semaphore tree depth is not supported.
    ///
    /// @param depth Passed tree depth.
    error UnsupportedTreeDepth(uint8 depth);

    /// @notice Thrown when the inputs to `removeIdentities` or `updateIdentities` do not match in
    ///         length.
    error MismatchedInputLengths();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when the current root of the tree is updated.
    ///
    /// @param preRoot The value of the tree's root before the update.
    /// @param kind Either "insertion" or "update", the kind of alteration that was made to the
    ///        tree.
    /// @param postRoot The value of the tree's root after the update.
    event TreeChanged(uint256 indexed preRoot, TreeChange indexed kind, uint256 indexed postRoot);

    /// @notice Emitted when a dependency's address is updated via an admin action.
    ///
    /// @param kind The kind of dependency that was updated.
    /// @param oldAddress The old address of that dependency.
    /// @param newAddress The new address of that dependency.
    event DependencyUpdated(
        Dependency indexed kind, address indexed oldAddress, address indexed newAddress
    );

    /// @notice Emitted when the state bridge is enabled or disabled.
    ///
    /// @param isEnabled Set to `true` if the event comes from the state bridge being enabled,
    ///        `false` otherwise.
    event StateBridgeStateChange(bool indexed isEnabled);

    /// @notice Emitted when the root history expiry time is changed.
    ///
    /// @param oldExpiryTime The expiry time prior to the change.
    /// @param newExpiryTime The expiry time after the change.
    event RootHistoryExpirySet(uint256 indexed oldExpiryTime, uint256 indexed newExpiryTime);

    /// @notice Emitted when the identity operator is changed.
    ///
    /// @param oldOperator The address of the old identity operator.
    /// @param newOperator The address of the new identity operator.
    event IdentityOperatorChanged(address indexed oldOperator, address indexed newOperator);

    /// @notice Emitter when the WorldIDIdentityManagerImpl is initialized.

    /// @param _treeDepth The depth of the MerkeTree
    /// @param initialRoot The initial value for the `latestRoot` in the contract. When deploying
    ///        this should be set to the root of the empty tree.
    event WorldIDIdentityManagerImplInitialized(uint8 _treeDepth, uint256 initialRoot);

    ///////////////////////////////////////////////////////////////////////////////
    ///                             INITIALIZATION                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Constructs the contract.
    constructor() {
        // When called in the constructor, this is called in the context of the implementation and
        // not the proxy. Calling this thereby ensures that the contract cannot be spuriously
        // initialized on its own.
        _disableInitializers();
    }

    /// @notice Initializes the contract.
    /// @dev Must be called exactly once.
    /// @dev This is marked `reinitializer()` to allow for updated initialisation steps when working
    ///      with upgrades based upon this contract. Be aware that there are only 256 (zero-indexed)
    ///      initialisations allowed, so decide carefully when to use them. Many cases can safely be
    ///      replaced by use of setters.
    /// @dev This function is explicitly not virtual as it does not make sense to override even when
    ///      upgrading. Create a separate initializer function instead.
    ///
    /// @param _treeDepth The depth of the MerkeTree
    /// @param initialRoot The initial value for the `latestRoot` in the contract. When deploying
    ///        this should be set to the root of the empty tree.
    /// @param _batchInsertionVerifiers The verifier lookup table for batch insertions.
    /// @param _batchUpdateVerifiers The verifier lookup table for batch updates.
    /// @param _semaphoreVerifier The verifier to use for semaphore protocol proofs.
    ///
    /// @custom:reverts string If called more than once at the same initialisation number.
    /// @custom:reverts UnsupportedTreeDepth If passed tree depth is not among defined values.
    function initialize(
        uint8 _treeDepth,
        uint256 initialRoot,
        VerifierLookupTable _batchInsertionVerifiers,
        VerifierLookupTable _batchUpdateVerifiers,
        ISemaphoreVerifier _semaphoreVerifier
    ) public reinitializer(1) {
        // First, ensure that all of the parent contracts are initialised.
        __delegateInit();

        if (!SemaphoreTreeDepthValidator.validate(_treeDepth)) {
            revert UnsupportedTreeDepth(_treeDepth);
        }

        // Now perform the init logic for this contract.
        treeDepth = _treeDepth;
        rootHistoryExpiry = 1 hours;
        _latestRoot = initialRoot;
        batchInsertionVerifiers = _batchInsertionVerifiers;
        identityUpdateVerifiers = _batchUpdateVerifiers;
        semaphoreVerifier = _semaphoreVerifier;
        _identityOperator = owner();

        // Say that the contract is initialized.
        __setInitialized();

        emit WorldIDIdentityManagerImplInitialized(_treeDepth, initialRoot);
    }

    /// @notice Responsible for initialising all of the supertypes of this contract.
    /// @dev Must be called exactly once.
    /// @dev When adding new superclasses, ensure that any initialization that they need to perform
    ///      is accounted for here.
    ///
    /// @custom:reverts string If called more than once.
    function __delegateInit() internal virtual onlyInitializing {
        __WorldIDImpl_init();
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                           IDENTITY MANAGEMENT                           ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Registers identities into the WorldID system.
    /// @dev Can only be called by the identity operator.
    /// @dev Registration is performed off-chain and verified on-chain via the `insertionProof`.
    ///      This saves gas and time over inserting identities one at a time.
    ///
    /// @param insertionProof The proof that given the conditions (`preRoot`, `startIndex` and
    ///        `identityCommitments`), insertion into the tree results in `postRoot`. Elements 0 and
    ///        1 are the `x` and `y` coordinates for `ar` respectively. Elements 2 and 3 are the `x`
    ///        coordinate for `bs`, and elements 4 and 5 are the `y` coordinate for `bs`. Elements 6
    ///        and 7 are the `x` and `y` coordinates for `krs`.
    /// @param preRoot The value for the root of the tree before the `identityCommitments` have been
    ////       inserted. Must be an element of the field `Kr`.
    /// @param startIndex The position in the tree at which the insertions were made.
    /// @param identityCommitments The identities that were inserted into the tree starting at
    ///        `startIndex` and `preRoot` to give `postRoot`. All of the commitments must be
    ///        elements of the field `Kr`.
    /// @param postRoot The root obtained after inserting all of `identityCommitments` into the tree
    ///        described by `preRoot`. Must be an element of the field `Kr`.
    ///
    /// @custom:reverts Unauthorized If the message sender is not authorised to add identities.
    /// @custom:reverts InvalidCommitment If one or more of the provided commitments is invalid.
    /// @custom:reverts NotLatestRoot If the provided `preRoot` is not the latest root.
    /// @custom:reverts ProofValidationFailure If `insertionProof` cannot be verified using the
    ///                 provided inputs.
    /// @custom:reverts UnreducedElement If any of the `preRoot`, `postRoot` and
    ///                 `identityCommitments` is not an element of the field `Kr`. It describes the
    ///                 type and value of the unreduced element.
    /// @custom:reverts VerifierLookupTable.NoSuchVerifier If the batch sizes doesn't match a known
    ///                 verifier.
    /// @custom:reverts VerifierLookupTable.BatchTooLarge If the batch size exceeds the maximum
    ///                 batch size.
    function registerIdentities(
        uint256[8] calldata insertionProof,
        uint256 preRoot,
        uint32 startIndex,
        uint256[] calldata identityCommitments,
        uint256 postRoot
    ) public virtual onlyProxy onlyInitialized onlyIdentityOperator {
        // We can only operate on the latest root in reduced form.
        if (preRoot >= SNARK_SCALAR_FIELD) {
            revert UnreducedElement(UnreducedElementType.PreRoot, preRoot);
        }
        if (preRoot != _latestRoot) {
            revert NotLatestRoot(preRoot, _latestRoot);
        }

        // As the `startIndex` is restricted to a uint32, where
        // `type(uint32).max <<< SNARK_SCALAR_FIELD`, we are safe not to check this. As verified in
        // the tests, a revert happens if you pass a value larger than `type(uint32).max` when
        // calling outside the type-checker's protection.

        // We need the post root to be in reduced form.
        if (postRoot >= SNARK_SCALAR_FIELD) {
            revert UnreducedElement(UnreducedElementType.PostRoot, postRoot);
        }

        // We can only operate on identities that are valid and in reduced form.
        validateIdentityCommitmentsForRegistration(identityCommitments);

        // Having validated the preconditions we can now check the proof itself.
        bytes32 inputHash = calculateIdentityRegistrationInputHash(
            startIndex, preRoot, postRoot, identityCommitments
        );

        // No matter what, the inputs can result in a hash that is not an element of the scalar
        // field in which we're operating. We reduce it into the field before handing it to the
        // verifier.
        uint256 reducedElement = uint256(inputHash) % SNARK_SCALAR_FIELD;

        // We need to look up the correct verifier before we can verify.
        ITreeVerifier insertionVerifier =
            batchInsertionVerifiers.getVerifierFor(identityCommitments.length);

        // With that, we can properly try and verify.
        try insertionVerifier.verifyProof(
            [insertionProof[0], insertionProof[1]],
            [[insertionProof[2], insertionProof[3]], [insertionProof[4], insertionProof[5]]],
            [insertionProof[6], insertionProof[7]],
            [reducedElement]
        ) returns (bool verifierResult) {
            // If the proof did not verify, we revert with a failure.
            if (!verifierResult) {
                revert ProofValidationFailure();
            }

            // If it did verify, we need to update the contract's state. We set the currently valid
            // root to the root after the insertions.
            _latestRoot = postRoot;

            // We also need to add the previous root to the history, and set the timestamp at
            // which it was expired.
            rootHistory[preRoot] = uint128(block.timestamp);

            emit TreeChanged(preRoot, TreeChange.Insertion, postRoot);
        } catch Error(string memory errString) {
            /// This is not the revert we're looking for.
            revert(errString);
        } catch {
            // If we reach here we know it's the internal error, as the tree verifier only uses
            // `require`s otherwise, which will be re-thrown above.
            revert ProofValidationFailure();
        }
    }

    /// @notice Updates identities in the WorldID system.
    /// @dev Can only be called by the identity operator.
    /// @dev The update is performed off-chain and verified on-chain via the `updateProof`. This
    ///      saves gas and time over removing identities one at a time.
    /// @dev This function can perform arbitrary identity alterations and does not require any
    ///      preconditions on the inputs other than that the identities are in reduced form.
    ///
    /// @param updateProof The proof that, given the conditions (`preRoot`, `startIndex` and
    ///        `removedIdentities`), updates in the tree results in `postRoot`. Elements 0 and 1 are
    ///        the `x` and `y` coordinates for `ar` respectively. Elements 2 and 3 are the `x`
    ///        coordinate for `bs`, and elements 4 and 5 are the `y` coordinate for `bs`. Elements 6
    ///        and 7 are the `x` and `y` coordinates for `krs`.
    /// @param preRoot The value for the root of the tree before the `updatedIdentities` have been
    ////       altered. Must be an element of the field `Kr`.
    /// @param leafIndices The array of leaf indices at which the update operations take place in
    ///        the tree. Elements in this array are extended to 256 bits when encoding.
    /// @param oldIdentities The array of old values for the identities. Length must match that of
    ///        `leafIndices`.
    /// @param newIdentities The array of new values for the identities. Length must match that of
    ///        `leafIndices`.
    /// @param postRoot The root obtained after removing all of `removedIdentities` from the tree
    ///        described by `preRoot`. Must be an element of the field `Kr`.
    ///
    /// The arrays `leafIndices`, `oldIdentities` and `newIdentities` are arranged such that the
    /// triple at an element `i` in those arrays corresponds to one update operation.
    ///
    /// @custom:reverts Unauthorized If the message sender is not authorised to update identities.
    /// @custom:reverts NotLatestRoot If the provided `preRoot` is not the latest root.
    /// @custom:reverts MismatchedInputLengths If the provided arrays for `leafIndices`,
    ///                 `oldIdentities` and `newIdentities` do not match in length.
    /// @custom:reverts ProofValidationFailure If `removalProof` cannot be verified using the
    ///                 provided inputs.
    /// @custom:reverts UnreducedElement If any of the `preRoot`, `postRoot` and `identities` is not
    ///                 an element of the field `Kr`. It describes the type and value of the
    ///                 unreduced element.
    /// @custom:reverts NoSuchVerifier If the batch sizes doesn't match a known verifier.
    function updateIdentities(
        uint256[8] calldata updateProof,
        uint256 preRoot,
        uint32[] calldata leafIndices,
        uint256[] calldata oldIdentities,
        uint256[] calldata newIdentities,
        uint256 postRoot
    ) public virtual onlyProxy onlyInitialized onlyIdentityOperator {
        // We can only operate on the latest root in reduced form.
        if (preRoot >= SNARK_SCALAR_FIELD) {
            revert UnreducedElement(UnreducedElementType.PreRoot, preRoot);
        }
        if (preRoot != _latestRoot) {
            revert NotLatestRoot(preRoot, _latestRoot);
        }

        // We also need the post root to be in reduced form.
        if (postRoot >= SNARK_SCALAR_FIELD) {
            revert UnreducedElement(UnreducedElementType.PostRoot, postRoot);
        }

        // We also need the arrays to be of the same length.
        if (
            leafIndices.length != oldIdentities.length || leafIndices.length != newIdentities.length
        ) {
            revert MismatchedInputLengths();
        }

        // We only operate on identities that are in reduced form.
        validateIdentitiesForUpdate(oldIdentities, newIdentities);

        // With valid preconditions we can calculate the input to the proof.
        bytes32 inputHash = calculateIdentityUpdateInputHash(
            preRoot, postRoot, leafIndices, oldIdentities, newIdentities
        );

        // No matter what, the input hashing process can result in a hash that is not an element of
        // the field Fr. We reduce it into the field to give it safely to the verifier.
        uint256 reducedInputHash = uint256(inputHash) % SNARK_SCALAR_FIELD;

        // We have to look up the correct verifier before we can verify.
        ITreeVerifier updateVerifier = identityUpdateVerifiers.getVerifierFor(leafIndices.length);

        // Now we delegate to another function in order to avoid the limit on stack variables.
        performIdentityUpdate(updateVerifier, updateProof, reducedInputHash, preRoot, postRoot);
    }

    /// @notice Performs the verification of the identity update proof.
    /// @dev This function only exists because `updateIdentities` ended up with more than 16 local
    ///      variables, and hence ran into the limit on the EVM. It will be called as a direct call
    ///      and is hence relatively cheap.
    /// @dev Can only be called by the owner.
    /// @dev The update is performed off-chain and verified on-chain via the `updateProof`. This
    ///      saves gas and time over removing identities one at a time.
    /// @dev This function can perform arbitrary identity alterations and does not require any
    ///      preconditions on the inputs other than that the identities are in reduced form.
    ///
    /// @param updateVerifier The merkle tree verifier to use for updates of the correct batch size.
    /// @param updateProof The proof that, given the conditions (`preRoot`, `startIndex` and
    ///        `removedIdentities`), updates in the tree results in `postRoot`. Elements 0 and 1 are
    ///        the `x` and `y` coordinates for `ar` respectively. Elements 2 and 3 are the `x`
    ///        coordinate for `bs`, and elements 4 and 5 are the `y` coordinate for `bs`. Elements 6
    ///        and 7 are the `x` and `y` coordinates for `krs`.
    /// @param inputHash The input hash for the update operation.
    /// @param preRoot The value for the root of the tree before the `updatedIdentities` have been
    ////       altered. Must be an element of the field `Kr`.
    /// @param postRoot The root obtained after removing all of `removedIdentities` from the tree
    ///        described by `preRoot`. Must be an element of the field `Kr`.
    ///
    /// @custom:reverts ProofValidationFailure If `removalProof` cannot be verified using the
    ///                 provided inputs.
    function performIdentityUpdate(
        ITreeVerifier updateVerifier,
        uint256[8] calldata updateProof,
        uint256 inputHash,
        uint256 preRoot,
        uint256 postRoot
    ) internal virtual onlyProxy onlyInitialized onlyIdentityOperator {
        // Pull out the proof terms and verifier input.
        uint256[2] memory ar = [updateProof[0], updateProof[1]];
        uint256[2][2] memory bs =
            [[updateProof[2], updateProof[3]], [updateProof[4], updateProof[5]]];
        uint256[2] memory krs = [updateProof[6], updateProof[7]];
        uint256[1] memory proofInput = [inputHash];

        // Now it's possible to verify the proof.
        try updateVerifier.verifyProof(ar, bs, krs, proofInput) returns (bool verifierResult) {
            // If the proof did not verify, we revert with a failure.
            if (!verifierResult) {
                revert ProofValidationFailure();
            }

            // If it did verify, we need to update the contract's state. We set the currently valid
            // root to the root after the insertions.
            _latestRoot = postRoot;

            // We also need to add the previous root to the history, and set the timestamp at which
            // it was expired.
            rootHistory[preRoot] = uint128(block.timestamp);

            emit TreeChanged(preRoot, TreeChange.Update, postRoot);
        } catch Error(string memory errString) {
            /// This is not the revert we're looking for.
            revert(errString);
        } catch {
            // If we reach here we know it's the internal error, as the tree verifier only uses
            // `require`s otherwise, which will be re-thrown above.
            revert ProofValidationFailure();
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                             UTILITY FUNCTIONS                           ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Calculates the input hash for the identity registration verifier.
    /// @dev Implements the computation described below.
    ///
    /// @param startIndex The index in the tree from which inserting started.
    /// @param preRoot The root value of the tree before these insertions were made.
    /// @param postRoot The root value of the tree after these insertions were made.
    /// @param identityCommitments The identities that were added to the tree to produce `postRoot`.
    ///
    /// @return hash The input hash calculated as described below.
    ///
    /// We keccak hash all input to save verification gas. Inputs are arranged as follows:
    ///
    /// StartIndex || PreRoot || PostRoot || IdComms[0] || IdComms[1] || ... || IdComms[batchSize-1]
    ///     32	   ||   256   ||   256    ||    256     ||    256     || ... ||     256 bits
    function calculateIdentityRegistrationInputHash(
        uint32 startIndex,
        uint256 preRoot,
        uint256 postRoot,
        uint256[] calldata identityCommitments
    ) public view virtual onlyProxy onlyInitialized returns (bytes32 hash) {
        bytes memory bytesToHash =
            abi.encodePacked(startIndex, preRoot, postRoot, identityCommitments);

        hash = keccak256(bytesToHash);
    }

    /// @notice Calculates the input hash for the identity update verifier.
    /// @dev Implements the computation described below.
    ///
    /// @param preRoot The root value of the tree before the updates were made.
    /// @param postRoot The root value of the tree after the updates were made.
    /// @param leafIndices The array of leaf indices at which the update operations take place in
    ///        the tree. Elements in this array are extended to 256 bits when encoding.
    /// @param oldIdentities The array of old values for the identities. Length must match that of
    ///        `leafIndices`.
    /// @param newIdentities The array of new values for the identities. Length must match that of
    ///        `leafIndices`.
    ///
    /// @return hash The input hash calculated as described below.
    ///
    /// The arrays `leafIndices`, `oldIdentities` and `newIdentities` are arranged such that the
    /// triple at an element `i` in those arrays corresponds to one update operation.
    ///
    /// We keccak hash all input to save verification gas. The inputs are arranged as follows:
    ///
    /// preRoot || postRoot || ix[0] || ... || ix[n] || oi[0] || ... || oi[n] || ni[0] || ... || ni[n] ||
    ///   256   ||    256   ||  256  || ... ||  256  ||  256  || ... ||  256  ||  256  || ... ||  256  ||
    ///
    /// where:
    /// - `ix[i] == leafIndices[i]`
    /// - `oi[i] == oldIdentities[i]`
    /// - `ni[i] == newIdentities[i]`
    /// - `id[i] == identities[i]`
    /// - `n == batchSize - 1`
    function calculateIdentityUpdateInputHash(
        uint256 preRoot,
        uint256 postRoot,
        uint32[] calldata leafIndices,
        uint256[] calldata oldIdentities,
        uint256[] calldata newIdentities
    ) public view virtual onlyProxy onlyInitialized returns (bytes32 hash) {
        bytes memory bytesToHash =
            abi.encodePacked(preRoot, postRoot, leafIndices, oldIdentities, newIdentities);

        hash = keccak256(bytesToHash);
    }

    /// @notice Allows a caller to query the latest root.
    ///
    /// @return root The value of the latest tree root.
    function latestRoot() public view virtual onlyProxy onlyInitialized returns (uint256) {
        return _latestRoot;
    }

    /// @notice Allows a caller to query the root history for information about a given root.
    /// @dev Should be used sparingly as the query can be quite expensive.
    ///
    /// @param root The root for which you are querying information.
    /// @return rootInfo The information about `root`, or `NO_SUCH_ROOT` if `root` does not exist.
    ///         Note that if the queried root is the current, the timestamp will be invalid as the
    ///         root has not been superseded.
    function queryRoot(uint256 root)
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (RootInfo memory)
    {
        if (root == _latestRoot) {
            return RootInfo(_latestRoot, 0, true);
        } else {
            uint128 rootTimestamp = rootHistory[root];

            if (rootTimestamp == 0) {
                return NO_SUCH_ROOT();
            }

            bool isValid = !(block.timestamp - rootTimestamp > rootHistoryExpiry);
            return RootInfo(root, rootTimestamp, isValid);
        }
    }

    /// @notice Validates an array of identity commitments, reverting if it finds one that is
    ///         invalid or has not been reduced.
    /// @dev Identities are not valid if an identity is a non-zero element that occurs after a zero
    ///      element in the array.
    ///
    /// @param identityCommitments The array of identity commitments to be validated.
    ///
    /// @custom:reverts Reverts with `InvalidCommitment` if one or more of the provided commitments
    ///                 is invalid.
    /// @custom:reverts Reverts with `UnreducedElement` if one or more of the provided commitments
    ///                 is not in reduced form.
    function validateIdentityCommitmentsForRegistration(uint256[] calldata identityCommitments)
        internal
        view
        virtual
    {
        uint256 offset;
        uint256 max;
        assembly ("memory-safe") {
            // offset of the first element in the array
            offset := identityCommitments.offset
            // offset one byte after the end of argument section
            max := add(offset, shl(5, identityCommitments.length))

            // increment offset until either of the following happens:
            // - offset is equal to max, meaning we've reached the end of the array
            // - the element at offset is zero
            // - the element at offset is greater than or equal to SNARK_SCALAR_FIELD
            // The latter two conditions are combined into a single check of the form
            // `element - 1 < SNARK_SCALAR_FIELD - 1`. This abuses unsigned comparisons:
            // if `element` is zero, it will underflow and be greater than SNARK_SCALAR_FIELD - 1.
            // If `element` is non-zero, we can cancel the -1 terms and the comparison becomes what
            // we want: `element < SNARK_SCALAR_FIELD`.
            for {} and(
                lt(offset, max), lt(sub(calldataload(offset), 1), SNARK_SCALAR_FIELD_MIN_ONE)
            ) { offset := add(offset, 32) } {}
        }

        // check if the loop terminated before end of array and handle the remaining elements
        if (offset < max) {
            uint256 index = identityCommitments.length - ((max - offset) >> 5);
            uint256 element = identityCommitments[index];

            // Check if the loop terminated because it found a zero
            // this means we need to finish looping and make sure all remaining elements are zero.
            if (element == 0) {
                assembly ("memory-safe") {
                    // we just confirmed this element is zero
                    offset := add(offset, 32)

                    // increment offset until either of the following happens:
                    // - offset is equal to max, meaning we've reached the end of the array
                    // - the element at offset is non-zero
                    for {} and(lt(offset, max), iszero(calldataload(offset))) {
                        offset := add(offset, 32)
                    } {}
                }

                // check if the loop terminated because it found a non-zero element
                // if yes, revert.
                if (offset < max) {
                    index = identityCommitments.length - ((max - offset) >> 5);
                    revert InvalidCommitment(index);
                }
            }
            // otherwise check if the loop terminated because it found an unreduced element
            // if so, revert
            else if (element >= SNARK_SCALAR_FIELD) {
                revert UnreducedElement(UnreducedElementType.IdentityCommitment, element);
            }
        }
    }

    /// @notice Validates that an array of identity commitments is within bounds of the SNARK_SCALAR_FIELD
    /// @param identityCommitments The array of identity commitments to be validated.
    function validateArrayIsInReducedForm(uint256[] calldata identityCommitments)
        internal
        view
        virtual
    {
        uint256 offset;
        uint256 max;
        assembly ("memory-safe") {
            // offset of the first element in the array
            offset := identityCommitments.offset
            // offset one byte after the end of argument section
            max := add(offset, shl(5, identityCommitments.length))

            // increment offset until either of the following happens:
            // - offset is equal to max, meaning we've reached the end of the array
            // - the element at offset is greater than or equal to SNARK_SCALAR_FIELD
            for {} and(lt(offset, max), lt(calldataload(offset), SNARK_SCALAR_FIELD)) {
                offset := add(offset, 32)
            } {}
        }
        // check if the loop terminated before end of array and revert if so
        if (offset < max) {
            uint256 index = identityCommitments.length - ((max - offset) >> 5);
            uint256 element = identityCommitments[index];
            revert UnreducedElement(UnreducedElementType.IdentityCommitment, element);
        }
    }

    /// @notice Validates the array of identities for each of the old and new commitments being in
    ///         reduced form.
    /// @dev Must be called with arrays of the same length.
    ///
    /// @param oldIdentities The array of old values for the identities.
    /// @param newIdentities The array of new values for the identities.
    ///
    /// @custom:reverts UnreducedElement If one or more of the provided commitments is not in
    ////                reduced form.
    function validateIdentitiesForUpdate(
        uint256[] calldata oldIdentities,
        uint256[] calldata newIdentities
    ) internal view virtual {
        validateArrayIsInReducedForm(oldIdentities);
        validateArrayIsInReducedForm(newIdentities);
    }

    /// @notice Reverts if the provided root value is not valid.
    /// @dev A root is valid if it is either the latest root, or not the latest root but has not
    ///      expired.
    ///
    /// @param root The root of the merkle tree to check for validity.
    ///
    /// @custom:reverts ExpiredRoot If the provided `root` has expired.
    /// @custom:reverts NonExistentRoot If the provided `root` does not exist in the history.
    function requireValidRoot(uint256 root) public view virtual onlyProxy onlyInitialized {
        // The latest root is always valid.
        if (root == _latestRoot) {
            return;
        }

        // Otherwise, we need to check things via the timestamp.
        uint128 rootTimestamp = rootHistory[root];

        // A root does not exist if it has no associated timestamp.
        if (rootTimestamp == 0) {
            revert NonExistentRoot();
        }

        // A root is no longer valid if it has expired.
        if (block.timestamp - rootTimestamp > rootHistoryExpiry) {
            revert ExpiredRoot();
        }
    }

    /// @notice Gets the address for the lookup table of merkle tree verifiers used for identity
    ///         registrations.
    ///
    /// @return addr The address of the contract being used as the verifier lookup table.
    function getRegisterIdentitiesVerifierLookupTableAddress()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (address)
    {
        return address(batchInsertionVerifiers);
    }

    /// @notice Sets the address for the lookup table of merkle tree verifiers used for identity
    ///         registrations.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newTable The new verifier lookup table to be used for verifying identity
    ///        registrations.
    function setRegisterIdentitiesVerifierLookupTable(VerifierLookupTable newTable)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        VerifierLookupTable oldTable = batchInsertionVerifiers;
        batchInsertionVerifiers = newTable;
        emit DependencyUpdated(
            Dependency.InsertionVerifierLookupTable, address(oldTable), address(newTable)
        );
    }

    /// @notice Gets the address for the lookup table of merkle tree verifiers used for identity
    ///         updates.
    /// @dev The update verifier is also used for member removals.
    ///
    /// @return addr The address of the contract being used as the verifier lookup table.
    function getIdentityUpdateVerifierLookupTableAddress()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (address)
    {
        return address(identityUpdateVerifiers);
    }

    /// @notice Sets the address for the lookup table of merkle tree verifiers to be used for
    ///         verification of identity updates.
    /// @dev Only the owner of the contract can call this function.
    /// @dev The update verifier is also used for member removals.
    ///
    /// @param newTable The new lookup table instance to be used for verifying identity updates.
    function setIdentityUpdateVerifierLookupTable(VerifierLookupTable newTable)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        VerifierLookupTable oldTable = identityUpdateVerifiers;
        identityUpdateVerifiers = newTable;
        emit DependencyUpdated(
            Dependency.UpdateVerifierLookupTable, address(oldTable), address(newTable)
        );
    }

    /// @notice Gets the address of the verifier used for verification of semaphore proofs.
    ///
    /// @return addr The address of the contract being used as the verifier.
    function getSemaphoreVerifierAddress()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (address)
    {
        return address(semaphoreVerifier);
    }

    /// @notice Sets the address for the semaphore verifier to be used for verification of
    ///         semaphore proofs.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newVerifier The new verifier instance to be used for verifying semaphore proofs.
    function setSemaphoreVerifier(ISemaphoreVerifier newVerifier)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        ISemaphoreVerifier oldVerifier = semaphoreVerifier;
        semaphoreVerifier = newVerifier;
        emit DependencyUpdated(
            Dependency.SemaphoreVerifier, address(oldVerifier), address(newVerifier)
        );
    }

    /// @notice Gets the current amount of time used to expire roots in the history.
    ///
    /// @return expiryTime The amount of time it takes for a root to expire.
    function getRootHistoryExpiry()
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (uint256)
    {
        return rootHistoryExpiry;
    }

    /// @notice Sets the time to wait before expiring a root from the root history.
    /// @dev Only the owner of the contract can call this function.
    ///
    /// @param newExpiryTime The new time to use to expire roots.
    function setRootHistoryExpiry(uint256 newExpiryTime)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        if (newExpiryTime == 0) {
            revert("Expiry time cannot be zero.");
        }
        uint256 oldExpiry = rootHistoryExpiry;
        rootHistoryExpiry = newExpiryTime;

        emit RootHistoryExpirySet(oldExpiry, newExpiryTime);
    }

    /// @notice Gets the Semaphore tree depth the contract was initialized with.
    ///
    /// @return initializedTreeDepth Tree depth.
    function getTreeDepth() public view virtual onlyProxy onlyInitialized returns (uint8) {
        return treeDepth;
    }

    /// @notice Gets the address that is authorised to perform identity operations on this identity
    ///         manager instance.
    ///
    /// @return _ The address authorized to perform identity operations.
    function identityOperator() public view virtual onlyProxy onlyInitialized returns (address) {
        return _identityOperator;
    }

    /// @notice Sets the address that is authorised to perform identity operations on this identity
    ///         manager instance.
    ///
    /// @param newIdentityOperator The address of the new identity operator.
    ///
    /// @return _ The address of the old identity operator.
    function setIdentityOperator(address newIdentityOperator)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
        returns (address)
    {
        address oldOperator = _identityOperator;
        _identityOperator = newIdentityOperator;
        emit IdentityOperatorChanged(oldOperator, newIdentityOperator);
        return oldOperator;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                    SEMAPHORE PROOF VALIDATION LOGIC                     ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice A verifier for the semaphore protocol.
    /// @dev Note that a double-signaling check is not included here, and should be carried by the
    ///      caller.
    ///
    /// @param root The of the Merkle tree
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    ///
    /// @custom:reverts string If the zero-knowledge proof cannot be verified for the public inputs.
    function verifyProof(
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) public view virtual onlyProxy onlyInitialized {
        // Check the preconditions on the inputs.
        requireValidRoot(root);

        // With that done we can now verify the proof.
        semaphoreVerifier.verifyProof(
            root, nullifierHash, signalHash, externalNullifierHash, proof, treeDepth
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                    SEMAPHORE PROOF VALIDATION LOGIC                     ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Ensures that the guarded operation can only be performed by the authorized identity
    ///         operator contract.
    ///
    /// @custom:reverts Unauthorized If the caller is not the identity operator.
    modifier onlyIdentityOperator() {
        if (msg.sender != _identityOperator) {
            revert Unauthorized(msg.sender);
        }

        _;
    }
}
