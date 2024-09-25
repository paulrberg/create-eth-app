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

import {IWorldIDGroups} from "./interfaces/IWorldIDGroups.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";

/// @title WorldID Router Implementation Version 1
/// @author Worldcoin
/// @notice A router component that can dispatch group numbers to the correct identity manager
///         implementation.
/// @dev This is the implementation delegated to by a proxy.
contract WorldIDRouterImplV1 is WorldIDImpl, IWorldIDGroups {
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

    /// The null address.
    IWorldID internal constant NULL_ROUTER = IWorldID(address(0x0));

    /// The routing table used to dispatch from groups to addresses.
    IWorldID[] internal routingTable;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice An error raised when routing is requested for a group that does not exist.
    ///
    /// @param groupId The group identifier that was requested but does not exist.
    error NoSuchGroup(uint256 groupId);

    /// @notice The requested group has been disabled.
    error GroupIsDisabled();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a group is added to the router.
    ///
    /// @param groupId The identifier for the group.
    /// @param identityManager The address of the identity manager associated with the group.
    event GroupAdded(uint256 indexed groupId, address indexed identityManager);

    /// @notice Emitted when a group is updated in the router.
    ///
    /// @param groupId The identitfier for the group.
    /// @param oldIdentityManager The address of the previous identity manager associated with the
    ///        group.
    /// @param newIdentityManager The address of the new identity manager associated with the group.
    event GroupUpdated(
        uint256 indexed groupId,
        address indexed oldIdentityManager,
        address indexed newIdentityManager
    );

    /// @notice Emitted when a group is disabled in the router.
    ///
    /// @param groupId The identifier of the group that has been disabled.
    event GroupDisabled(uint256 indexed groupId);

    /// @notice Emitted when a group is enabled in the router.
    ///
    /// @param initialGroupIdentityManager The address of the identity manager to be used for the first group
    event GroupIdentityManagerRouterImplInitialized(IWorldID initialGroupIdentityManager);

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
    /// @param initialGroupIdentityManager The address of the identity manager to be used for the
    ///        initial group (group ID 0) when instantiating the router.
    ///
    /// @custom:reverts string If called more than once at the same initalisation number.
    function initialize(IWorldID initialGroupIdentityManager) public reinitializer(1) {
        // Initialize the sub-contracts.
        __delegateInit();

        // Now we can perform our own internal initialisation.
        routingTable.push(initialGroupIdentityManager);

        // Mark the contract as initialized.
        __setInitialized();

        emit GroupIdentityManagerRouterImplInitialized(initialGroupIdentityManager);
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
    ///                                 ROUTING                                 ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Gets the route for the provided group number.
    ///
    /// @param groupNumber The number of the group to get the route for.
    ///
    /// @return target The target address for the group number.
    ///
    /// @custom:reverts NoSuchGroup If the requested `groupNumber` does not exist.
    /// @custom:reverts GroupDisabled If the group has been disabled.
    function routeFor(uint256 groupNumber)
        public
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (IWorldID)
    {
        // We want to revert if the group does not exist.
        if (groupNumber >= groupCount()) {
            revert NoSuchGroup(groupNumber);
        }

        // If there is no valid route for a given group we also revert.
        if (routingTable[groupNumber] == NULL_ROUTER) {
            revert GroupIsDisabled();
        }

        // With preconditions checked we can return the route.
        return routingTable[groupNumber];
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                             GROUP MANAGEMENT                            ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Adds a group to the router.
    /// @dev It is perfectly valid to add a group with a target address of 0 in order to disable it.
    /// @dev While it reverts if the group identifier is not sequential, this is due to the fact
    ///      that group identifiers are allocated externally. As a result, they cannot just be
    ///      allocated by the router.
    ///
    /// @param groupIdentityManager The address of the identity manager instance to be used for the
    ///        group. If this is set to the null address the group is disabled.
    ///
    /// @custom:reverts DuplicateGroup If the `groupId` already exists in the routing table.
    /// @custom:reverts NonSequentialGroup If the `groupId` is not the sequentially next group based
    ///                 on the known groups.
    function addGroup(IWorldID groupIdentityManager)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
    {
        uint256 groupId = groupCount();
        // Insert the entry into the routing table.
        insertNewTableEntry(groupIdentityManager);

        emit GroupAdded(groupId, address(groupIdentityManager));
    }

    /// @notice Updates the target address for a group in the router.
    /// @dev It is perfectly valid to update a group with a target address of 0 in order to disable
    ///      it.
    ///
    /// @param groupId The identitifier for the group to have its target address updated.
    /// @param newTargetAddress The new target address for the group in routing. If this is set to
    ///        the null address the group will be disabled.
    ///
    /// @return oldTarget The old target address for the group.
    ///
    /// @custom:reverts NoSuchGroup If the target group does not exist to be updated.
    function updateGroup(uint256 groupId, IWorldID newTargetAddress)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
        returns (IWorldID oldTarget)
    {
        oldTarget = performGroupUpdate(groupId, newTargetAddress);
        emit GroupUpdated(groupId, address(oldTarget), address(newTargetAddress));
    }

    /// @notice Disables the target group in the router.
    ///
    /// @param groupId The identifier for the group to be disabled.
    ///
    /// @return oldTarget The old target address for the group.
    ///
    /// @custom:reverts NoSuchGroup If the target group does not exist to be disabled.
    function disableGroup(uint256 groupId)
        public
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
        returns (IWorldID oldTarget)
    {
        oldTarget = performGroupUpdate(groupId, NULL_ROUTER);
        emit GroupDisabled(groupId);
    }

    /// @notice Updates the target address for a group in the router.
    /// @dev It is perfectly valid to update a group with a target address of 0 in order to disable
    ///      it.
    ///
    /// @param groupId The identitifier for the group to have its target address updated.
    /// @param newTarget The new target address for the group in routing. If this is set to the null
    ///        address the group will be disabled.
    ///
    /// @return oldTarget The old target address for the group.
    ///
    /// @custom:reverts NoSuchGroup If the target group does not exist to be updated.
    function performGroupUpdate(uint256 groupId, IWorldID newTarget)
        internal
        virtual
        onlyProxy
        onlyInitialized
        onlyOwner
        returns (IWorldID oldTarget)
    {
        // It is not possible to update a non-existent group.
        if (groupId >= groupCount()) {
            revert NoSuchGroup(groupId);
        }

        oldTarget = routingTable[groupId];
        routingTable[groupId] = newTarget;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                              DATA QUERYING                              ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Gets the number of groups in the routing table.
    ///
    /// @return count The number of groups in the table.
    function groupCount() public view virtual onlyProxy onlyInitialized returns (uint256 count) {
        return routingTable.length;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                            INTERNAL FUNCTIONS                           ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Inserts the `targetAddress` into the routing table for the provided `groupId`.
    /// @dev Callers must ensure that the group identifier requested is the next in the table before
    ///      calling.
    ///
    /// @param targetAddress The address to be routed to for the provided `groupId`.
    function insertNewTableEntry(IWorldID targetAddress)
        internal
        virtual
        onlyProxy
        onlyInitialized
    {
        routingTable.push(targetAddress);
    }

    /// @notice Gets the group identifier for the group with the highest group identifier known to
    ///         the router.
    ///
    /// @return groupId The highest group identifier known.
    function nextGroupId()
        internal
        view
        virtual
        onlyProxy
        onlyInitialized
        returns (uint256 groupId)
    {
        return groupCount();
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                            WORLDID COMPLIANCE                           ///
    ///////////////////////////////////////////////////////////////////////////////

    /// @notice Verifies a WorldID zero knowledge proof.
    /// @dev Note that a double-signaling check is not included here, and should be carried by the
    ///      caller.
    ///
    /// @param root The of the Merkle tree
    /// @param groupId The group identifier for the group to verify a proof for.
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    ///
    /// @custom:reverts Any If the `proof` is invalid. The exact type of the revert depends on the
    ///                 `IWorldID` implementation being called into.
    /// @custom:reverts NoSuchGroup If the provided `groupId` references a group that does not exist.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external virtual onlyProxy onlyInitialized {
        IWorldID identityManager = routeFor(groupId);
        identityManager.verifyProof(root, signalHash, nullifierHash, externalNullifierHash, proof);
    }
}
