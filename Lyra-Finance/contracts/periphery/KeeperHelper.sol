/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Lyra-Finance?utm=code
  */
  
  //SPDX-License-Identifier: ISC
pragma solidity 0.8.16;

// Interfaces
import "../OptionMarket.sol";

/**
 * @title KeeperHelper
 * @author Lyra
 * @dev A wrapper function that reduces the number of calls required for the keeperBot to liquidate positions
 */
contract KeeperHelper {
  OptionMarket public optionMarket;
  ShortCollateral public shortCollateral;
  OptionGreekCache public greekCache;
  bool public initialized;

  constructor() {}

  function init(OptionMarket _optionMarket, ShortCollateral _shortCollateral, OptionGreekCache _greekCache) external {
    require(!initialized, "Keeper Helper: already initialized");

    optionMarket = _optionMarket;
    shortCollateral = _shortCollateral;
    greekCache = _greekCache;
    initialized = true;
  }

  function updateAllBoardCachedGreeks() external {
    uint[] memory liveBoards = optionMarket.getLiveBoards();

    for (uint i = 0; i < liveBoards.length; ++i) {
      greekCache.updateBoardCachedGreeks(liveBoards[i]);
    }
  }

  function updateStaleBoardCachedGreeks() external {
    uint[] memory liveBoards = optionMarket.getLiveBoards();

    for (uint i = 0; i < liveBoards.length; ++i) {
      if (greekCache.isBoardCacheStale(liveBoards[i])) {
        greekCache.updateBoardCachedGreeks(liveBoards[i]);
      }
    }
  }

  /**
   * @dev Liquidates positions using a compressed uint
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function liquidate8(uint batch1) external {
    uint[] memory pids = new uint[](8);
    for (uint i = 0; i < 8; ++i) {
      pids[i] = uint(uint32(batch1 >> (32 * i)));
    }
    _liquidateMany(pids);
  }

  /**
   * @dev Allows liquidations of multiple positions in a single call
   */
  function _liquidateMany(uint[] memory positionIds) internal {
    uint positionIdsLength = positionIds.length;
    for (uint i = 0; i < positionIdsLength; ++i) {
      if (positionIds[i] == 0) continue;
      optionMarket.liquidatePosition(positionIds[i], msg.sender);
    }
  }

  function liquidateMany(uint[] memory positionIds) external {
    for (uint i = 0; i < positionIds.length; ++i) {
      optionMarket.liquidatePosition(positionIds[i], msg.sender);
    }
  }

  /**
   * @dev Settles up to 8 positions
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function settle8(uint batch1) external {
    uint[] memory pids = new uint[](8);
    for (uint i = 0; i < 8; ++i) {
      pids[i] = _shiftUint32(batch1, i);
    }

    for (uint i = pids.length - 1; i > 0; i--) {
      if (pids[i] == 0) {
        if (pids.length != 0) {
          assembly {
            mstore(pids, sub(mload(pids), 1))
          }
        }
      }
    }
    _settleMany(pids);
  }

  /**
   * @dev Settles up to 16 positions
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function settle16(uint batch1, uint batch2) external {
    uint[] memory pids = new uint[](16);
    for (uint i = 0; i < 16; ++i) {
      if (i / 8 == 0) {
        pids[i] = _shiftUint32(batch1, i);
      } else if (i / 8 == 1) {
        pids[(i % 8) + 8] = _shiftUint32(batch2, i);
      }
    }

    for (uint i = pids.length - 1; i > 0; i--) {
      if (pids[i] == 0) {
        if (pids.length != 0) {
          assembly {
            mstore(pids, sub(mload(pids), 1))
          }
        }
      }
    }
    _settleMany(pids);
  }

  /**
   * @dev Settles up to 24 positions
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function settle24(uint batch1, uint batch2, uint batch3) external {
    uint[] memory pids = new uint[](24);

    for (uint i = 0; i < 24; ++i) {
      if (i / 8 == 0) {
        pids[i] = _shiftUint32(batch1, i);
      } else if (i / 8 == 1) {
        pids[(i % 8) + 8] = _shiftUint32(batch2, i);
      } else if (i / 8 == 2) {
        pids[(i % 8) + 16] = _shiftUint32(batch3, i);
      }
    }

    for (uint i = pids.length - 1; i > 0; i--) {
      if (pids[i] == 0) {
        if (pids.length != 0) {
          assembly {
            mstore(pids, sub(mload(pids), 1))
          }
        }
      }
    }
    _settleMany(pids);
  }

  /**
   * @dev Settles up to 32 positions
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function settle32(uint batch1, uint batch2, uint batch3, uint batch4) external {
    uint[] memory pids = new uint[](32);

    for (uint i = 0; i < 32; ++i) {
      if (i / 8 == 0) {
        pids[i] = _shiftUint32(batch1, i);
      } else if (i / 8 == 1) {
        pids[(i % 8) + 8] = _shiftUint32(batch2, i);
      } else if (i / 8 == 2) {
        pids[(i % 8) + 16] = _shiftUint32(batch3, i);
      } else if (i / 8 == 3) {
        pids[(i % 8) + 24] = _shiftUint32(batch4, i);
      }
    }

    for (uint i = pids.length - 1; i > 0; i--) {
      if (pids[i] == 0) {
        if (pids.length != 0) {
          assembly {
            mstore(pids, sub(mload(pids), 1))
          }
        }
      }
    }
    _settleMany(pids);
  }

  /**
   * @dev Settles up to 40 positions
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function settle40(uint batch1, uint batch2, uint batch3, uint batch4, uint batch5) external {
    uint[] memory pids = new uint[](40);

    for (uint i = 0; i < 40; ++i) {
      if (i / 8 == 0) {
        pids[i] = _shiftUint32(batch1, i);
      } else if (i / 8 == 1) {
        pids[(i % 8) + 8] = _shiftUint32(batch2, i);
      } else if (i / 8 == 2) {
        pids[(i % 8) + 16] = _shiftUint32(batch3, i);
      } else if (i / 8 == 3) {
        pids[(i % 8) + 24] = _shiftUint32(batch4, i);
      } else if (i / 8 == 4) {
        pids[(i % 8) + 32] = _shiftUint32(batch5, i);
      }
    }

    for (uint i = pids.length - 1; i > 0; i--) {
      if (pids[i] == 0) {
        if (pids.length != 0) {
          assembly {
            mstore(pids, sub(mload(pids), 1))
          }
        }
      }
    }
    _settleMany(pids);
  }

  /**
   * @dev Settles up to 80 positions
   *
   * @param batch1 Is a compressed uint which contains up to 8 positionIds (uint32)
   */
  function settle80(
    uint batch1,
    uint batch2,
    uint batch3,
    uint batch4,
    uint batch5,
    uint batch6,
    uint batch7,
    uint batch8,
    uint batch9,
    uint batch10
  ) external {
    uint[] memory pids = new uint[](80);

    for (uint i = 0; i < 80; ++i) {
      if (i / 8 == 0) {
        pids[i] = _shiftUint32(batch1, i);
      } else if (i / 8 == 1) {
        pids[(i % 8) + 8] = _shiftUint32(batch2, i);
      } else if (i / 8 == 2) {
        pids[(i % 8) + 16] = _shiftUint32(batch3, i);
      } else if (i / 8 == 3) {
        pids[(i % 8) + 24] = _shiftUint32(batch4, i);
      } else if (i / 8 == 4) {
        pids[(i % 8) + 32] = _shiftUint32(batch5, i);
      } else if (i / 8 == 5) {
        pids[(i % 8) + 40] = _shiftUint32(batch6, i);
      } else if (i / 8 == 6) {
        pids[(i % 8) + 48] = _shiftUint32(batch7, i);
      } else if (i / 8 == 7) {
        pids[(i % 8) + 56] = _shiftUint32(batch8, i);
      } else if (i / 8 == 8) {
        pids[(i % 8) + 64] = _shiftUint32(batch9, i);
      } else if (i / 8 == 9) {
        pids[(i % 8) + 72] = _shiftUint32(batch10, i);
      }
    }

    for (uint i = pids.length - 1; i > 0; i--) {
      if (pids[i] == 0) {
        if (pids.length != 0) {
          assembly {
            mstore(pids, sub(mload(pids), 1))
          }
        }
      }
    }
    _settleMany(pids);
  }

  /**
   * @dev Allows settlement of many positions in a single call.
   */
  function _settleMany(uint[] memory positionIds) internal {
    shortCollateral.settleOptions(positionIds);
  }

  /**
   * @dev Allows settlement of many positions in a single call.
   */
  function settleMany(uint[] memory positionIds) external {
    shortCollateral.settleOptions(positionIds);
  }

  /**
   * @dev Extracts a specific positionId from a uint32 batch
   */
  function _shiftUint32(uint batch, uint loc) internal pure returns (uint) {
    return uint(uint32(batch >> (32 * (loc % 8))));
  }
}
