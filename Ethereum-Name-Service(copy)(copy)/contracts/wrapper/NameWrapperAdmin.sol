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

import "./INameWrapper.sol";
import "./Controllable.sol";
import {INameWrapperUpgrade} from "./INameWrapperUpgrade.sol";
import {BytesUtils} from "./BytesUtils.sol";
import {ENS} from "../registry/ENS.sol";
import {Ownable} from "Ethereum-Name-Service/@openzeppelin/contracts/access/Ownable.sol";
import {Create2} from "Ethereum-Name-Service/@openzeppelin/contracts/utils/Create2.sol";
import {Address} from "Ethereum-Name-Service/@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev A proxy contract that wraps new name wrapper controllers to ensure they don't shorten the duration of registrations.
 */
contract NameWrapperControllerProxy {
    address public immutable controller;
    INameWrapper public immutable wrapper;

    constructor(address _controller, INameWrapper _wrapper) {
        controller = _controller;
        wrapper = _wrapper;
    }

    /**
     * @dev Registers a new .eth second-level domain and wraps it.
     *      Only callable by authorised controllers.
     * @param label The label to register (Eg, 'foo' for 'foo.eth').
     * @param wrappedOwner The owner of the wrapped name.
     * @param duration The duration, in seconds, to register the name for.
     * @param resolver The resolver address to set on the ENS registry (optional).
     * @param ownerControlledFuses Initial owner-controlled fuses to set
     * @return registrarExpiry The expiry date of the new name on the .eth registrar, in seconds since the Unix epoch.
     */
    function registerAndWrapETH2LD(
        string calldata label,
        address wrappedOwner,
        uint256 duration,
        address resolver,
        uint16 ownerControlledFuses
    ) external returns (uint256 registrarExpiry) {
        require(msg.sender == controller);
        require(duration < 365000000 days);
        return
            wrapper.registerAndWrapETH2LD(
                label,
                wrappedOwner,
                duration,
                resolver,
                ownerControlledFuses
            );
    }

    /**
     * @notice Renews a .eth second-level domain.
     * @dev Only callable by authorised controllers.
     * @param tokenId The hash of the label to register (eg, `keccak256('foo')`, for 'foo.eth').
     * @param duration The number of seconds to renew the name for.
     * @return expires The expiry date of the name on the .eth registrar, in seconds since the Unix epoch.
     */
    function renew(
        uint256 tokenId,
        uint256 duration
    ) external returns (uint256 expires) {
        require(msg.sender == controller);
        require(duration < 365000000 days);
        return wrapper.renew(tokenId, duration);
    }
}

/**
 * @dev Contract to act as the owner of the NameWrapper, permitting its owner to make certain changes with additional checks.
 *      This was implemented in response to a vulnerability disclosure that would permit the DAO to appoint a malicious controller
 *      that shortens the registration period of affected ENS names. This contract exists to prevent that from happening.
 */
contract NameWrapperAdmin is Ownable, INameWrapperUpgrade {
    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    using BytesUtils for bytes;
    using Address for address;

    INameWrapper public immutable wrapper;
    IBaseRegistrar public immutable registrar;
    ENS public immutable ens;
    INameWrapperUpgrade public upgradeContract;

    constructor(address _wrapper) {
        wrapper = INameWrapper(_wrapper);
        registrar = wrapper.registrar();
        ens = wrapper.ens();
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
            new NameWrapperControllerProxy{salt: bytes32(0)}(
                controller,
                wrapper
            );
        }
        return proxyAddress;
    }

    /**
     * @dev Authorizes a controller proxy to register and renew names on the wrapper.
     * @param controller The controller contract to authorize.
     */
    function addController(address controller) external onlyOwner {
        deployControllerProxy(controller);
        Controllable(address(wrapper)).setController(
            getProxyAddress(controller),
            true
        );
    }

    /**
     * @dev Deauthorizes a controller proxy.
     * @param controller The controller contract to deauthorize.
     */
    function removeController(address controller) external onlyOwner {
        Controllable(address(wrapper)).setController(
            getProxyAddress(controller),
            false
        );
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
                        type(NameWrapperControllerProxy).creationCode,
                        uint256(uint160(controller)),
                        uint256(uint160(address(wrapper)))
                    )
                )
            );
    }

    /**
     * @notice Set the metadata service. Only the owner can do this
     * @param _metadataService The new metadata service
     */
    function setMetadataService(
        IMetadataService _metadataService
    ) public onlyOwner {
        wrapper.setMetadataService(_metadataService);
    }

    /**
     * @notice Set the address of the upgradeContract of the contract. only admin can do this
     * @dev The default value of upgradeContract is the 0 address. Use the 0 address at any time
     * to make the contract not upgradable.
     * @param _upgradeAddress address of an upgraded contract
     */
    function setUpgradeContract(
        INameWrapperUpgrade _upgradeAddress
    ) external onlyOwner {
        if (address(upgradeContract) == address(0)) {
            wrapper.setUpgradeContract(this);
        }
        upgradeContract = _upgradeAddress;
        if (address(upgradeContract) == address(0)) {
            wrapper.setUpgradeContract(INameWrapperUpgrade(address(0)));
        }
    }

    function wrapFromUpgrade(
        bytes calldata name,
        address wrappedOwner,
        uint32 fuses,
        uint64 expiry,
        address approved,
        bytes calldata extraData
    ) external {
        require(msg.sender == address(wrapper));
        (bytes32 labelhash, uint256 offset) = name.readLabel(0);
        bytes32 parentNode = name.namehash(offset);
        bytes32 node = keccak256(abi.encodePacked(parentNode, labelhash));
        if (parentNode == ETH_NODE) {
            registrar.transferFrom(
                address(wrapper),
                address(upgradeContract),
                uint256(labelhash)
            );
        }
        ens.setOwner(node, address(upgradeContract));
        upgradeContract.wrapFromUpgrade(
            name,
            wrappedOwner,
            fuses,
            expiry,
            approved,
            extraData
        );
    }
}
