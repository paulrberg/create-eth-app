/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  //SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IBaseRegistrar.sol";
import {Ownable} from "Ethereum-Name-Service/@openzeppelin/contracts/access/Ownable.sol";
import {Create2} from "Ethereum-Name-Service/@openzeppelin/contracts/utils/Create2.sol";
import {Address} from "Ethereum-Name-Service/@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev A proxy contract that wraps new registrar controllers to ensure they don't shorten the duration of registrations by causing an overflow.
 */
contract ETHRegistrarControllerProxy {
    address public immutable controller;
    IBaseRegistrar public immutable registrar;

    constructor(address _controller, IBaseRegistrar _registrar) {
        controller = _controller;
        registrar = _registrar;
    }

    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {
        require(msg.sender == controller);
        require(duration < 365000000 days);
        return registrar.register(id, owner, duration);
    }

    function registerOnly(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {
        require(msg.sender == controller);
        require(duration < 365000000 days);
        return registrar.registerOnly(id, owner, duration);
    }

    function renew(uint256 id, uint256 duration) external returns (uint256) {
        require(msg.sender == controller);
        require(duration < 365000000 days);
        return registrar.renew(id, duration);
    }
}

/**
 * @dev Contract to act as the owner of the ETHRegistrar, permitting its owner to make certain changes with additional checks.
 *      This was implemented in response to a vulnerability disclosure that would permit the DAO to appoint a malicious controller
 *      that shortens the registration period of affected ENS names. This contract exists to prevent that from happening.
 */
contract ETHRegistrarAdmin is Ownable {
    using Address for address;

    IBaseRegistrar public immutable registrar;

    constructor(address _registrar) {
        registrar = IBaseRegistrar(_registrar);
    }

    /**
     * @dev Deploys a controller proxy for the given controller, if one does not already exist.
     *      Anyone can call this function, but the proxy will only function if added by an authorized
     *      caller using `addController`.
     * @param controller The controller contract to create a proxy for.
     * @return The address of the controller proxy.
     */
    function deployControllerProxy(
        address controller
    ) public returns (address) {
        address proxyAddress = getProxyAddress(controller);
        if (!proxyAddress.isContract()) {
            new ETHRegistrarControllerProxy{salt: bytes32(0)}(
                controller,
                registrar
            );
        }
        return proxyAddress;
    }

    /**
     * @dev Authorizes a controller proxy to register and renew names on the registrar.
     * @param controller The controller contract to authorize.
     */
    function addController(address controller) external onlyOwner {
        deployControllerProxy(controller);
        registrar.addController(getProxyAddress(controller));
    }

    /**
     * @dev Deauthorizes a controller proxy.
     * @param controller The controller contract to deauthorize.
     */
    function removeController(address controller) external onlyOwner {
        registrar.removeController(getProxyAddress(controller));
    }

    /**
     * @dev Gets the address of the proxy contract for a given controller.
     * @param controller The controller contract to get the proxy address for.
     * @return The address of the proxy contract.
     */
    function getProxyAddress(address controller) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(0),
                keccak256(
                    abi.encodePacked(
                        type(ETHRegistrarControllerProxy).creationCode,
                        uint256(uint160(controller)),
                        uint256(uint160(address(registrar)))
                    )
                )
            );
    }

    /**
     * @dev Sets the resolver for the TLD this registrar manages.
     * @param resolver The address of the resolver to set.
     */
    function setResolver(address resolver) external onlyOwner {
        registrar.setResolver(resolver);
    }
}
