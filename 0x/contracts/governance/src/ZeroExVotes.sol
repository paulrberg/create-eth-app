/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/0x?utm=code
  */
  
  // SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2023 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.8.19;

import "0x/@openzeppelin/contracts/utils/math/SafeCast.sol";
import "0x/@openzeppelin/contracts/utils/math/Math.sol";
import "0x/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "0x/@openzeppelin/contracts/governance/utils/IVotes.sol";
import "0x/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "0x/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "0x/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IZeroExVotes.sol";

contract ZeroExVotes is IZeroExVotes, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public immutable token;
    uint256 public immutable quadraticThreshold;

    mapping(address => Checkpoint[]) internal _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    constructor(address _token, uint256 _quadraticThreshold) {
        require(_token != address(0), "ZeroExVotes: token cannot be 0");
        token = _token;
        quadraticThreshold = _quadraticThreshold;
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyToken() {
        _checkSenderIsToken();
        _;
    }

    function initialize() public virtual onlyProxy initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function checkpoints(address account, uint32 pos) public view returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function numCheckpoints(address account) public view returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function getVotes(address account) public view returns (uint256) {
        unchecked {
            uint256 pos = _checkpoints[account].length;
            return pos == 0 ? 0 : _unsafeAccess(_checkpoints[account], pos - 1).votes;
        }
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function getQuadraticVotes(address account) public view returns (uint256) {
        unchecked {
            uint256 pos = _checkpoints[account].length;
            return pos == 0 ? 0 : _unsafeAccess(_checkpoints[account], pos - 1).quadraticVotes;
        }
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ZeroExVotes: block not yet mined");

        Checkpoint memory checkpoint = _checkpointsLookup(_checkpoints[account], blockNumber);
        return checkpoint.votes;
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function getPastQuadraticVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ZeroExVotes: block not yet mined");

        Checkpoint memory checkpoint = _checkpointsLookup(_checkpoints[account], blockNumber);
        return checkpoint.quadraticVotes;
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ZeroExVotes: block not yet mined");

        // Note that due to the disabled updates of `_totalSupplyCheckpoints` in `writeCheckpointTotalSupply` function
        // this always returns 0.
        Checkpoint memory checkpoint = _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
        return checkpoint.votes;
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function getPastQuadraticTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ZeroExVotes: block not yet mined");

        // Note that due to the disabled updates of `_totalSupplyCheckpoints` in `writeCheckpointTotalSupply` function
        // this always returns 0.
        Checkpoint memory checkpoint = _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
        return checkpoint.quadraticVotes;
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function moveVotingPower(
        address src,
        address dst,
        uint256 srcBalance,
        uint256 dstBalance,
        uint96 srcBalanceLastUpdated,
        uint96 dstBalanceLastUpdated,
        uint256 amount
    ) public virtual onlyToken returns (bool) {
        if (src != dst) {
            if (src != address(0)) {
                (
                    uint256 oldWeight,
                    uint256 newWeight,
                    uint256 oldQuadraticWeight,
                    uint256 newQuadraticWeight
                ) = _writeCheckpoint(_checkpoints[src], _subtract, srcBalance, srcBalanceLastUpdated, amount);

                emit DelegateVotesChanged(src, oldWeight, newWeight);
                emit DelegateQuadraticVotesChanged(src, oldQuadraticWeight, newQuadraticWeight);
            }

            if (dst != address(0)) {
                (
                    uint256 oldWeight,
                    uint256 newWeight,
                    uint256 oldQuadraticWeight,
                    uint256 newQuadraticWeight
                ) = _writeCheckpoint(_checkpoints[dst], _add, dstBalance, dstBalanceLastUpdated, amount);

                emit DelegateVotesChanged(dst, oldWeight, newWeight);
                emit DelegateQuadraticVotesChanged(dst, oldQuadraticWeight, newQuadraticWeight);
            }
        }
        return true;
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function writeCheckpointTotalSupplyMint(
        uint256 accountBalance,
        uint256 amount
    ) public virtual onlyToken returns (bool) {
        (, uint256 newWeight, , uint256 newQuadraticWeight) = _writeCheckpoint(
            _totalSupplyCheckpoints,
            _add,
            accountBalance,
            0,
            amount
        );

        emit TotalSupplyChanged(newWeight, newQuadraticWeight);
        return true;
    }

    /**
     * @inheritdoc IZeroExVotes
     */
    function writeCheckpointTotalSupplyBurn(
        uint256 accountBalance,
        uint256 amount
    ) public virtual onlyToken returns (bool) {
        (, uint256 newWeight, , uint256 newQuadraticWeight) = _writeCheckpoint(
            _totalSupplyCheckpoints,
            _subtract,
            accountBalance,
            0,
            amount
        );

        emit TotalSupplyChanged(newWeight, newQuadraticWeight);
        return true;
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     * Implementation as in openzeppelin/token/ERC20/extensions/ERC20Votes.sol except here we return the entire
     * checkpoint rather than part of it
     */
    function _checkpointsLookup(
        Checkpoint[] storage ckpts,
        uint256 blockNumber
    ) internal view returns (Checkpoint memory checkpoint) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the
        // invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 length = ckpts.length;

        uint256 low = 0;
        uint256 high = length;

        if (length > 5) {
            uint256 mid = length - Math.sqrt(length);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // Leaving here for posterity this is the original OZ implementation which we've replaced
        // return high == 0 ? 0 : _unsafeAccess(ckpts, high - 1).votes;
        if (high != 0) checkpoint = _unsafeAccess(ckpts, high - 1);
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 userBalance,
        uint96 balanceLastUpdated,
        uint256 delta
    )
        internal
        virtual
        returns (uint256 oldWeight, uint256 newWeight, uint256 oldQuadraticWeight, uint256 newQuadraticWeight)
    {
        uint256 pos = ckpts.length;

        Checkpoint memory oldCkpt = pos == 0 ? Checkpoint(0, 0, 0) : _unsafeAccess(ckpts, pos - 1);

        oldWeight = oldCkpt.votes;
        newWeight = op(oldWeight, delta);

        oldQuadraticWeight = oldCkpt.quadraticVotes;

        // Remove the entire sqrt userBalance from quadratic voting power.
        // Note that `userBalance` is value _after_ transfer.
        if (pos > 0) {
            uint256 oldQuadraticVotingPower = userBalance <= quadraticThreshold
                ? userBalance
                : quadraticThreshold + Math.sqrt((userBalance - quadraticThreshold) * 1e18);
            oldCkpt.quadraticVotes -= SafeCast.toUint96(oldQuadraticVotingPower);
        }

        // if wallet > threshold, calculate quadratic power over the treshold only, below threshold is linear
        uint256 newBalance = op(userBalance, delta);
        uint256 newQuadraticBalance = newBalance <= quadraticThreshold
            ? newBalance
            : quadraticThreshold + Math.sqrt((newBalance - quadraticThreshold) * 1e18);
        newQuadraticWeight = oldCkpt.quadraticVotes + newQuadraticBalance;

        if (pos > 0 && oldCkpt.fromBlock == block.number) {
            Checkpoint storage chpt = _unsafeAccess(ckpts, pos - 1);
            chpt.votes = SafeCast.toUint96(newWeight);
            chpt.quadraticVotes = SafeCast.toUint96(newQuadraticWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCast.toUint32(block.number),
                    votes: SafeCast.toUint96(newWeight),
                    quadraticVotes: SafeCast.toUint96(newQuadraticWeight)
                })
            );
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     * Implementation from openzeppelin/token/ERC20/extensions/ERC20Votes.sol
     * https://github.com/ethereum/solidity/issues/9117
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos) internal pure returns (Checkpoint storage result) {
        assembly ("memory-safe") {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    function _checkSenderIsToken() private {
        require(msg.sender == token, "ZeroExVotes: only token allowed");
    }
}
