/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ConduitControllerInterface} from "OpenSea-Seaport/seaport-types/src/interfaces/ConduitControllerInterface.sol";

import {ConduitInterface} from "OpenSea-Seaport/seaport-types/src/interfaces/ConduitInterface.sol";

import {Conduit} from "./Conduit.sol";

/**
 * @title ConduitController
 * @author 0age
 * @notice ConduitController enables deploying and managing new conduits, or
 *         contracts that allow registered callers (or open "channels") to
 *         transfer approved ERC20/721/1155 tokens on their behalf.
 */
contract ConduitController is ConduitControllerInterface {
    // Register keys, owners, new potential owners, and channels by conduit.
    mapping(address => ConduitProperties) internal _conduits;

    // Set conduit creation code and runtime code hashes as immutable arguments.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
    bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;

    /**
     * @dev Initialize contract by deploying a conduit and setting the creation
     *      code and runtime code hashes as immutable arguments.
     */
    constructor() {
        // Derive the conduit creation code hash and set it as an immutable.
        _CONDUIT_CREATION_CODE_HASH = keccak256(type(Conduit).creationCode);

        // Deploy a conduit with the zero hash as the salt.
        Conduit zeroConduit = new Conduit{ salt: bytes32(0) }();

        // Retrieve the conduit runtime code hash and set it as an immutable.
        _CONDUIT_RUNTIME_CODE_HASH = address(zeroConduit).codehash;
    }

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner) external override returns (address conduit) {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InvalidInitialOwner();
        }

        // If the first 20 bytes of the conduit key do not match the caller...
        if (address(uint160(bytes20(conduitKey))) != msg.sender) {
            // Revert with an error indicating that the creator is invalid.
            revert InvalidCreator();
        }

        // Derive address from deployer, conduit key and creation code hash.
        conduit = address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(bytes1(0xff), address(this), conduitKey, _CONDUIT_CREATION_CODE_HASH))
                )
            )
        );

        // If derived conduit exists, as evidenced by comparing runtime code...
        if (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH) {
            // Revert with an error indicating that the conduit already exists.
            revert ConduitAlreadyExists(conduit);
        }

        // Deploy the conduit via CREATE2 using the conduit key as the salt.
        new Conduit{ salt: conduitKey }();

        // Initialize storage variable referencing conduit properties.
        ConduitProperties storage conduitProperties = _conduits[conduit];

        // Set the supplied initial owner as the owner of the conduit.
        conduitProperties.owner = initialOwner;

        // Set conduit key used to deploy the conduit to enable reverse lookup.
        conduitProperties.key = conduitKey;

        // Emit an event indicating that the conduit has been deployed.
        emit NewConduit(conduit, conduitKey);

        // Emit an event indicating that conduit ownership has been assigned.
        emit OwnershipTransferred(conduit, address(0), initialOwner);
    }

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(address conduit, address channel, bool isOpen) external override {
        // Ensure the caller is the current owner of the conduit in question.
        _assertCallerIsConduitOwner(conduit);

        // Call the conduit, updating the channel.
        ConduitInterface(conduit).updateChannel(channel, isOpen);

        // Retrieve storage region where channels for the conduit are tracked.
        ConduitProperties storage conduitProperties = _conduits[conduit];

        // Retrieve the index, if one currently exists, for the updated channel.
        uint256 channelIndexPlusOne = (conduitProperties.channelIndexesPlusOne[channel]);

        // Determine whether the updated channel is already tracked as open.
        bool channelPreviouslyOpen = channelIndexPlusOne != 0;

        // If the channel has been set to open and was previously closed...
        if (isOpen && !channelPreviouslyOpen) {
            // Add the channel to the channels array for the conduit.
            conduitProperties.channels.push(channel);

            // Add new open channel length to associated mapping as index + 1.
            conduitProperties.channelIndexesPlusOne[channel] = (conduitProperties.channels.length);
        } else if (!isOpen && channelPreviouslyOpen) {
            // Set a previously open channel as closed via "swap & pop" method.
            // Decrement located index to get the index of the closed channel.
            uint256 removedChannelIndex;

            // Skip underflow check as channelPreviouslyOpen being true ensures
            // that channelIndexPlusOne is nonzero.
            unchecked {
                removedChannelIndex = channelIndexPlusOne - 1;
            }

            // Use length of channels array to determine index of last channel.
            uint256 finalChannelIndex = conduitProperties.channels.length - 1;

            // If closed channel is not last channel in the channels array...
            if (finalChannelIndex != removedChannelIndex) {
                // Retrieve the final channel and place the value on the stack.
                address finalChannel = (conduitProperties.channels[finalChannelIndex]);

                // Overwrite the removed channel using the final channel value.
                conduitProperties.channels[removedChannelIndex] = finalChannel;

                // Update final index in associated mapping to removed index.
                conduitProperties.channelIndexesPlusOne[finalChannel] = (channelIndexPlusOne);
            }

            // Remove the last channel from the channels array for the conduit.
            conduitProperties.channels.pop();

            // Remove the closed channel from associated mapping of indexes.
            delete conduitProperties.channelIndexesPlusOne[channel];
        }
    }

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner) external override {
        // Ensure the caller is the current owner of the conduit in question.
        _assertCallerIsConduitOwner(conduit);

        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsZeroAddress(conduit);
        }

        // Ensure the new potential owner is not already set.
        if (newPotentialOwner == _conduits[conduit].potentialOwner) {
            revert NewPotentialOwnerAlreadySet(conduit, newPotentialOwner);
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner of the conduit.
        _conduits[conduit].potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external override {
        // Ensure the caller is the current owner of the conduit in question.
        _assertCallerIsConduitOwner(conduit);

        // Ensure that ownership transfer is currently possible.
        if (_conduits[conduit].potentialOwner == address(0)) {
            revert NoPotentialOwnerCurrentlySet(conduit);
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
        _conduits[conduit].potentialOwner = address(0);
    }

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external override {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // If caller does not match current potential owner of the conduit...
        if (msg.sender != _conduits[conduit].potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner(conduit);
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the conduit.
        _conduits[conduit].potentialOwner = address(0);

        // Emit an event indicating conduit ownership has been transferred.
        emit OwnershipTransferred(conduit, _conduits[conduit].owner, msg.sender);

        // Set the caller as the owner of the conduit.
        _conduits[conduit].owner = msg.sender;
    }

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view override returns (address owner) {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the current owner of the conduit in question.
        owner = _conduits[conduit].owner;
    }

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view override returns (bytes32 conduitKey) {
        // Attempt to retrieve a conduit key for the conduit in question.
        conduitKey = _conduits[conduit].key;

        // Revert if no conduit key was located.
        if (conduitKey == bytes32(0)) {
            revert NoConduit();
        }
    }

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey) external view override returns (address conduit, bool exists) {
        // Derive address from deployer, conduit key and creation code hash.
        conduit = address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(bytes1(0xff), address(this), conduitKey, _CONDUIT_CREATION_CODE_HASH))
                )
            )
        );

        // Determine whether conduit exists by retrieving its runtime code.
        exists = (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH);
    }

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit) external view override returns (address potentialOwner) {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the current potential owner of the conduit in question.
        potentialOwner = _conduits[conduit].potentialOwner;
    }

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel) external view override returns (bool isOpen) {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the current channel status for the conduit in question.
        isOpen = _conduits[conduit].channelIndexesPlusOne[channel] != 0;
    }

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit) external view override returns (uint256 totalChannels) {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
        totalChannels = _conduits[conduit].channels.length;
    }

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex) external view override returns (address channel) {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve the total open channel count for the conduit in question.
        uint256 totalChannels = _conduits[conduit].channels.length;

        // Ensure that the supplied index is within range.
        if (channelIndex >= totalChannels) {
            revert ChannelOutOfRange(conduit);
        }

        // Retrieve the channel at the given index.
        channel = _conduits[conduit].channels[channelIndex];
    }

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit) external view override returns (address[] memory channels) {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // Retrieve all of the open channels on the conduit in question.
        channels = _conduits[conduit].channels;
    }

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        override
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash)
    {
        // Retrieve the conduit creation code hash from runtime.
        creationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Retrieve the conduit runtime code hash from runtime.
        runtimeCodeHash = _CONDUIT_RUNTIME_CODE_HASH;
    }

    /**
     * @dev Private view function to revert if the caller is not the owner of a
     *      given conduit.
     *
     * @param conduit The conduit for which to assert ownership.
     */
    function _assertCallerIsConduitOwner(address conduit) private view {
        // Ensure that the conduit in question exists.
        _assertConduitExists(conduit);

        // If the caller does not match the current owner of the conduit...
        if (msg.sender != _conduits[conduit].owner) {
            // Revert, indicating that the caller is not the owner.
            revert CallerIsNotOwner(conduit);
        }
    }

    /**
     * @dev Private view function to revert if a given conduit does not exist.
     *
     * @param conduit The conduit for which to assert existence.
     */
    function _assertConduitExists(address conduit) private view {
        // Attempt to retrieve a conduit key for the conduit in question.
        if (_conduits[conduit].key == bytes32(0)) {
            // Revert if no conduit key was located.
            revert NoConduit();
        }
    }
}
