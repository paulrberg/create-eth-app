/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2024 PancakeSwap
pragma solidity ^0.8.24;

/// @title BinPosition
/// @notice Positions represent an owner address' share for a bin
library BinPosition {
    /// @notice Cannot update a position with no liquidity
    error CannotUpdateEmptyPosition();

    // info stored for each user's position
    struct Info {
        // the amount of share owned by this position
        uint256 share;
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The address of the position owner
    /// @param binId The binId
    /// @return position The position info struct of the given owners' position
    function get(mapping(bytes32 => Info) storage self, address owner, uint24 binId)
        internal
        view
        returns (BinPosition.Info storage position)
    {
        bytes32 key;
        // make use of memory scratch space
        // ref: https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol#L95
        // memory will be 12 bytes of zeros, the 20 bytes of address, 3 bytes for uint24
        assembly {
            mstore(0x03, binId)
            mstore(0x00, owner)
            key := keccak256(0x0c, 0x17)
        }
        position = self[key];
    }

    function addShare(Info storage self, uint256 share) internal {
        self.share += share;
    }

    function subShare(Info storage self, uint256 share) internal {
        self.share -= share;
    }
}
