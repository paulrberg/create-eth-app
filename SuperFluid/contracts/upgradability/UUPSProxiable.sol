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

import { UUPSUtils } from "./UUPSUtils.sol";
import { Initializable } from "SuperFluid/@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxiable contract.
 */
abstract contract UUPSProxiable is Initializable {

    /**
     * @dev Get current implementation code address.
     */
    function getCodeAddress() public view returns (address codeAddress)
    {
        return UUPSUtils.implementation();
    }

    function updateCode(address newAddress) external virtual;

    // allows to mark logic contracts as initialized in order to reduce the attack surface
    // solhint-disable-next-line no-empty-blocks
    function castrate() external initializer { }

    /**
     * @dev Proxiable UUID marker function, this would help to avoid wrong logic
     *      contract to be used for upgrading.
     *
     * NOTE: The semantics of the UUID deviates from the actual UUPS standard,
     *       where it is equivalent of _IMPLEMENTATION_SLOT.
     */
    function proxiableUUID() public view virtual returns (bytes32);

    /**
     * @dev Update code address function.
     *      It is internal, so the derived contract could setup its own permission logic.
     */
    function _updateCodeAddress(address newAddress) internal
    {
        // require UUPSProxy.initializeProxy first
        require(UUPSUtils.implementation() != address(0), "UUPSProxiable: not upgradable");
        require(
            proxiableUUID() == UUPSProxiable(newAddress).proxiableUUID(),
            "UUPSProxiable: not compatible logic"
        );
        require(
            address(this) != newAddress,
            "UUPSProxiable: proxy loop"
        );
        UUPSUtils.setImplementation(newAddress);
        emit CodeUpdated(proxiableUUID(), newAddress);
    }

    event CodeUpdated(bytes32 uuid, address codeAddress);

}
