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

import {
    AdvancedOrder,
    CriteriaResolver,
    Execution,
    Fulfillment,
    Order,
    OrderComponents
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationStructs.sol";

import {
    SeaportInterface
} from "OpenSea-Seaport/seaport-types/src/interfaces/SeaportInterface.sol";

/**
 * @title  PausableZoneController
 * @author cupOJoseph, BCLeFevre, stuckinaboot
 * @notice PausableZoneController enables deploying, pausing and executing
 *         orders on PausableZones. This deployer is designed to be owned
 *         by a gnosis safe, DAO, or trusted party.
 */
interface PausableZoneControllerInterface {
    /**
     * @notice Deploy a PausableZone to a precomputed address.
     *
     * @param salt The salt to be used to derive the zone address
     *
     * @return derivedAddress The derived address for the zone.
     */
    function createZone(bytes32 salt) external returns (address derivedAddress);

    /**
     * @notice Pause orders on a given zone.
     *
     * @param zone The address of the zone to be paused.
     *
     * @return success A boolean indicating the zone has been paused.
     */
    function pause(address zone) external returns (bool success);

    /**
     * @notice Cancel Seaport offers on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to cancel.
     */
    function cancelOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        OrderComponents[] calldata orders
    ) external;

    /**
     * @notice Execute an arbitrary number of matched orders on a given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Execute an arbitrary number of matched advanced orders on a
     *         given zone.
     *
     * @param pausableZoneAddress The zone that manages the orders to be
     *                            cancelled.
     * @param seaportAddress      The Seaport address.
     * @param orders              The orders to match.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific order as well as
     *                            that order's offer or consideration,
     *                            a token identifier, and a proof that
     *                            the supplied token identifier is
     *                            contained in the order's merkle root.
     * @param fulfillments        An array of elements allocating offer
     *                            components to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        address pausableZoneAddress,
        SeaportInterface seaportAddress,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Initiate Zone ownership transfer by assigning a new potential
     *         owner of this contract. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership.
     *         Only the owner in question may call this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice Assign the given address with the ability to pause the zone.
     *
     * @param pauserToAssign The address to assign the pauser role.
     */
    function assignPauser(address pauserToAssign) external;

    /**
     * @notice Assign the given address with the ability to operate the
     *         given zone.
     *
     * @param pausableZoneAddress The zone address to assign operator role.
     * @param operatorToAssign    The address to assign as operator.
     */
    function assignOperator(
        address pausableZoneAddress,
        address operatorToAssign
    ) external;

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the pauser.
     *
     * @return The address of the pauser.
     */
    function pauser() external view returns (address);
}
