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

import { ISuperfluid, ISuperfluidToken } from "../interfaces/superfluid/ISuperfluid.sol";
import { IInstantDistributionAgreementV1 } from "../interfaces/agreements/IInstantDistributionAgreementV1.sol";
import { ForwarderBase } from "./ForwarderBase.sol";

/**
 * @title IDAv1Forwarder
 * @author Superfluid
 * The IDAv1Forwarder contract provides an easy to use interface to
 * InstantDistributionAgreementV1 specific functionality of Super Tokens.
 * Instances of this contract can operate on the protocol only if configured as "trusted forwarder"
 * by protocol governance.
 */
contract IDAv1Forwarder is ForwarderBase {
    IInstantDistributionAgreementV1 internal immutable _ida;

    // is tied to a specific instance of host and agreement contracts at deploy time
    constructor(ISuperfluid host) ForwarderBase(host) {
        _ida = IInstantDistributionAgreementV1(
            address(
                _host.getAgreementClass(keccak256("org.superfluid-finance.agreements.InstantDistributionAgreement.v1"))
            )
        );
    }

    /**
     * @dev Creates a new index for the specified token.
     * @param token The address of the super token.
     * @param indexId The ID of the index.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function createIndex(ISuperfluidToken token, uint32 indexId, bytes memory userData) external returns (bool) {
        bytes memory callData = abi.encodeCall(
            _ida.createIndex,
            (
                token,
                indexId,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Updates the value of an existing index for the specified token.
     * @param token The address of the super token.
     * @param indexId The ID of the index.
     * @param indexValue The new value of the index.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function updateIndex(ISuperfluidToken token, uint32 indexId, uint128 indexValue, bytes memory userData)
        external
        returns (bool)
    {
        bytes memory callData = abi.encodeCall(
            _ida.updateIndex,
            (
                token,
                indexId,
                indexValue,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Distributes a specified amount of tokens according to the specified index.
     * @param token The address of the super token.
     * @param indexId The ID of the index.
     * @param amount The amount of tokens to distribute.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function distribute(ISuperfluidToken token, uint32 indexId, uint128 amount, bytes memory userData)
        external
        returns (bool)
    {
        bytes memory callData = abi.encodeCall(
            _ida.distribute,
            (
                token,
                indexId,
                amount,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Calculates the distribution of tokens for a given publisher, index, and amount.
     * @param token The address of the super token.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @param amount The amount of tokens to distribute.
     * @return actualAmount The actual amount of tokens which will be distributed.
     * @return newIndexValue The new value of the index.
     */
    function calculateDistribution(ISuperfluidToken token, address publisher, uint32 indexId, uint128 amount)
        external
        view
        returns (uint256 actualAmount, uint128 newIndexValue)
    {
        return _ida.calculateDistribution(token, publisher, indexId, amount);
    }

    /**
     * @dev Retrieves information about the specified index for a given publisher.
     * @param token The address of the super token.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @return exist A boolean indicating whether the index exists.
     * @return indexValue The value of the index.
     * @return totalUnitsApproved The total number of approved units.
     * @return totalUnitsPending The total number of pending units.
     */
    function getIndex(ISuperfluidToken token, address publisher, uint32 indexId)
        external
        view
        returns (bool exist, uint128 indexValue, uint128 totalUnitsApproved, uint128 totalUnitsPending)
    {
        return _ida.getIndex(token, publisher, indexId);
    }

    /**
     * @dev Approves a subscription for the specified token, publisher, and index.
     * @param token The address of the super token.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function approveSubscription(ISuperfluidToken token, address publisher, uint32 indexId, bytes memory userData)
        external
        returns (bool)
    {
        bytes memory callData = abi.encodeCall(
            _ida.approveSubscription,
            (
                token,
                publisher,
                indexId,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Revokes a subscription for the specified token, publisher, and index.
     * @param token The address of the super token.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function revokeSubscription(ISuperfluidToken token, address publisher, uint32 indexId, bytes memory userData)
        external
        returns (bool)
    {
        bytes memory callData = abi.encodeCall(
            _ida.revokeSubscription,
            (
                token,
                publisher,
                indexId,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Deletes a subscription for the specified token, publisher, index, and subscriber.
     * @param token The address of the super token.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @param subscriber The address of the subscriber.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function deleteSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) external returns (bool) {
        bytes memory callData = abi.encodeCall(
            _ida.deleteSubscription,
            (
                token,
                publisher,
                indexId,
                subscriber,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Updates the subscription units for the specified token, index, subscriber, and units.
     * @param token The address of the super token.
     * @param indexId The ID of the index.
     * @param subscriber The address of the subscriber.
     * @param units The new units value.
     * @param userData Additional user-defined data.
     * @return bool A boolean indicating whether the operation was successful.
     */
    function updateSubscriptionUnits(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes memory userData
    ) external returns (bool) {
        bytes memory callData = abi.encodeCall(
            _ida.updateSubscription,
            (
                token,
                indexId,
                subscriber,
                units,
                new bytes(0) // ctx placeholder
            )
        );
        return _forwardBatchCall(address(_ida), callData, userData);
    }

    /**
     * @dev Retrieves information about the specified subscription for a given token, publisher, index, and subscriber.
     * @param token The address of the super token.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @param subscriber The address of the subscriber.
     * @return exist The address of the publisher.
     * @return approved Whether the subscription is approved.
     * @return units The units value of the subscription.
     * @return pendingDistribution The amount of tokens pending distribution for the subscription.
     */
    function getSubscription(ISuperfluidToken token, address publisher, uint32 indexId, address subscriber)
        external
        view
        returns (bool exist, bool approved, uint128 units, uint256 pendingDistribution)
    {
        return _ida.getSubscription(token, publisher, indexId, subscriber);
    }

    /**
     * @dev Computes the ID of a publisher based on the publisher's address and index ID.
     * @param publisher The address of the publisher.
     * @param indexId The ID of the index.
     * @return publisherId The computed publisher ID.
     */
    function getPublisherId(address publisher, uint32 indexId) external pure returns (bytes32 publisherId) {
        return keccak256(abi.encodePacked("publisher", publisher, indexId));
    }

    /**
     * @dev Computes the ID of a subscription based on the subscriber's address and publisher ID.
     * @param subscriber The address of the subscriber.
     * @param publisherId The ID of the publisher.
     * @return subscriptionId The computed subscription ID.
     */
    function getSubscriptionId(address subscriber, bytes32 publisherId)
        external
        pure
        returns (bytes32 subscriptionId)
    {
        return keccak256(abi.encodePacked("subscription", subscriber, publisherId));
    }

    /**
     * @dev Retrieves information about the specified subscription based on its ID.
     * @param token The address of the super token.
     * @param subscriptionId The ID of the subscription.
     * @return publisher The address of the publisher.
     * @return indexId The ID of the index.
     * @return approved Whether the subscription is approved.
     * @return units The units value of the subscription.
     * @return pendingDistribution The amount of tokens pending distribution for the subscription.
     */
    function getSubscriptionByID(ISuperfluidToken token, bytes32 subscriptionId)
        external
        view
        returns (address publisher, uint32 indexId, bool approved, uint128 units, uint256 pendingDistribution)
    {
        return _ida.getSubscriptionByID(token, subscriptionId);
    }

    /**
     * @dev Lists all subscriptions of a subscriber for the specified token.
     * @param token The address of the super token.
     * @param subscriber The address of the subscriber.
     * @return publishers The addresses of the publishers.
     * @return indexIds The IDs of the indexes for the subscription.
     * @return unitsList The unit amount for subscriptions to each index.
     */
    function listSubscriptions(ISuperfluidToken token, address subscriber)
        external
        view
        returns (address[] memory publishers, uint32[] memory indexIds, uint128[] memory unitsList)
    {
        return _ida.listSubscriptions(token, subscriber);
    }
}
