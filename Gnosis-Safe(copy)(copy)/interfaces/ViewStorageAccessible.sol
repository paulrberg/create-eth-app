/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Gnosis-Safe?utm=code
  */
  
  pragma solidity >=0.5.0 <0.9.0;

/// @title ViewStorageAccessible - Interface on top of StorageAccessible base class to allow simulations from view functions.
/// @notice Adjusted version of https://github.com/gnosis/util-contracts/blob/3db1e531cb243a48ea91c60a800d537c1000612a/contracts/StorageAccessible.sol
interface ViewStorageAccessible {
    /**
     * @dev Same as `simulate` on StorageAccessible. Marked as view so that it can be called from external contracts
     * that want to run simulations from within view functions. Will revert if the invoked simulation attempts to change state.
     */
    function simulate(address targetContract, bytes calldata calldataPayload) external view returns (bytes memory);
}
