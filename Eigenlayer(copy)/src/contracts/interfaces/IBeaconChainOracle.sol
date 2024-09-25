/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Eigenlayer?utm=code
  */
  
  // SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

/**
 * @title Interface for the BeaconStateOracle contract.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 */
interface IBeaconChainOracle {
    /// @notice Largest blockNumber that has been confirmed by the oracle.
    function latestConfirmedOracleBlockNumber() external view returns(uint64);
    /// @notice Mapping: Beacon Chain blockNumber => the Beacon Chain state root at the specified blockNumber.
    /// @dev This will return `bytes32(0)` if the state root at the specified blockNumber is not yet confirmed.
    function beaconStateRootAtBlockNumber(uint64 blockNumber) external view returns(bytes32);

    /// @notice Mapping: address => whether or not the address is in the set of oracle signers.
    function isOracleSigner(address _oracleSigner) external view returns(bool);

    /// @notice Mapping: Beacon Chain blockNumber => oracle signer address => whether or not the oracle signer has voted on the state root at the blockNumber.
    function hasVoted(uint64 blockNumber, address oracleSigner) external view returns(bool);

    /// @notice Mapping: Beacon Chain blockNumber => state root => total number of oracle signer votes for the state root at the blockNumber. 
    function stateRootVotes(uint64 blockNumber, bytes32 stateRoot) external view returns(uint256);

    /// @notice Total number of members of the set of oracle signers.
    function totalOracleSigners() external view returns(uint256);

    /**
     * @notice Number of oracle signers that must vote for a state root in order for the state root to be confirmed.
     * Adjustable by this contract's owner through use of the `setThreshold` function.
     * @dev We note that there is an edge case -- when the threshold is adjusted downward, if a state root already has enough votes to meet the *new* threshold,
     * the state root must still receive one additional vote from an oracle signer to be confirmed. This behavior is intended, to minimize unexpected root confirmations.
     */
    function threshold() external view returns(uint256);

    /**
     * @notice Owner-only function used to modify the value of the `threshold` variable.
     * @param _threshold Desired new value for the `threshold` variable. Function will revert if this is set to zero.
     */
    function setThreshold(uint256 _threshold) external;

    /**
     * @notice Owner-only function used to add a signer to the set of oracle signers.
     * @param _oracleSigners Array of address to be added to the set.
     * @dev Function will have no effect on the i-th input address if `_oracleSigners[i]`is already in the set of oracle signers.
     */
    function addOracleSigners(address[] memory _oracleSigners) external;

    /**
     * @notice Owner-only function used to remove a signer from the set of oracle signers.
     * @param _oracleSigners Array of address to be removed from the set.
     * @dev Function will have no effect on the i-th input address if `_oracleSigners[i]`is already not in the set of oracle signers.
     */
    function removeOracleSigners(address[] memory _oracleSigners) external;

    /**
     * @notice Called by a member of the set of oracle signers to assert that the Beacon Chain state root is `stateRoot` at `blockNumber`.
     * @dev The state root will be finalized once the total number of votes *for this exact state root at this exact blockNumber* meets the `threshold` value.
     * @param blockNumber The Beacon Chain blockNumber of interest.
     * @param stateRoot The Beacon Chain state root that the caller asserts was the correct root, at the specified `blockNumber`.
     */
    function voteForBeaconChainStateRoot(uint64 blockNumber, bytes32 stateRoot) external;
}