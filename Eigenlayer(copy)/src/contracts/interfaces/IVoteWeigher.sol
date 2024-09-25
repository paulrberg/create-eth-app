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
 * @title Interface for a `VoteWeigher`-type contract.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice Note that `NUMBER_OF_QUORUMS` is expected to remain constant, as suggested by its uppercase formatting.
 */
interface IVoteWeigher {
    /**
     * @notice This function computes the total weight of the @param operator in the quorum @param quorumNumber.
     * @dev returns zero in the case that `quorumNumber` is greater than or equal to `NUMBER_OF_QUORUMS`
     */
    function weightOfOperator(address operator, uint256 quorumNumber) external returns (uint96);

    /// @notice Number of quorums that are being used by the middleware.
    function NUMBER_OF_QUORUMS() external view returns (uint256);

    /**
     * @notice This defines the earnings split between different quorums. Mapping is quorumNumber => BIPS which the quorum earns, out of the total earnings.
     * @dev The sum of all entries, i.e. sum(quorumBips[0] through quorumBips[NUMBER_OF_QUORUMS - 1]) should *always* be 10,000!
     */
    function quorumBips(uint256 quorumNumber) external view returns (uint256);
}
