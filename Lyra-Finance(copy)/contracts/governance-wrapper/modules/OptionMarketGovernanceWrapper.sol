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

import "../BaseGovernanceWrapper.sol";

import "../../OptionMarket.sol";

contract OptionMarketGovernanceWrapper is BaseGovernanceWrapper {
  struct OptionMarketBounds {
    bool boardFreezingBlocked;
    bool boardForceSettlingBlocked;
    uint minBaseIv;
    uint maxBaseIv;
    uint minSkew;
    uint maxSkew;
    bool recoverFundsBlocked;
    bool canZeroBaseLimit;
  }

  OptionMarket public optionMarket;
  address public boardManager;
  OptionMarketBounds internal optionMarketBounds;

  ////////////////
  // Only Owner //
  ////////////////

  function setOptionMarket(OptionMarket _optionMarket) external onlyOwner {
    if (address(optionMarket) != address(0)) {
      revert OMGW_OptionMarketAlreadySet(optionMarket);
    }
    _optionMarket.acceptOwnership();
    optionMarket = _optionMarket;
    emit OMGW_OptionMarketSet(_optionMarket);
  }

  function setBoardManager(address _boardManager) external onlyOwner {
    boardManager = _boardManager;
    emit OMGW_BoardManagerChanged(_boardManager);
  }

  function setOptionMarketBounds(OptionMarketBounds memory _optionMarketBounds) external onlyOwner {
    optionMarketBounds = _optionMarketBounds;
    emit OMGW_OptionMarketBoundsSet(_optionMarketBounds);
  }

  function setOptionMarketParams(OptionMarket.OptionMarketParameters memory _optionMarketParams) external onlyOwner {
    optionMarket.setOptionMarketParams(_optionMarketParams);
    emit OMGW_OptionMarketParamsSet(_optionMarketParams);
  }

  ////////////////////////////
  // Board Manager or Owner //
  ////////////////////////////

  function createOptionBoard(
    uint expiry,
    uint baseIV,
    uint[] memory strikePrices,
    uint[] memory skews,
    bool frozen
  ) external onlyBoardManagerOrOwner returns (uint boardId) {
    boardId = optionMarket.createOptionBoard(expiry, baseIV, strikePrices, skews, frozen);
    emit OMGW_BoardCreated(msg.sender, expiry, boardId);
  }

  function addStrikeToBoard(uint boardId, uint strikePrice, uint skew) external onlyBoardManagerOrOwner {
    optionMarket.addStrikeToBoard(boardId, strikePrice, skew);
    emit OMGW_StrikeAddedToBoard(msg.sender, boardId, strikePrice, skew);
  }

  ///////////////////////////
  // Risk Council or Owner //
  ///////////////////////////
  function setOptionMarketBaseLimit(uint baseLimit) external onlyRiskCouncilOrOwner {
    if(msg.sender == riskCouncil) {
      if(baseLimit != 0 || !optionMarketBounds.canZeroBaseLimit) {
        revert OMGW_BaseLimitInvalid(baseLimit, msg.sender);
      }
    }
    optionMarket.setBaseLimit(baseLimit);
    emit OMGW_OptionMarketBaseLimit(baseLimit);
  }

  function setBoardFrozen(uint boardId, bool frozen) external onlyRiskCouncilOrOwner {
    if (optionMarketBounds.boardFreezingBlocked && msg.sender == riskCouncil) {
      revert OMGW_BoardFreezingIsBlocked(msg.sender);
    }
    optionMarket.setBoardFrozen(boardId, frozen);
    emit OMGW_BoardFrozen(msg.sender, boardId, frozen);
  }

  function setBoardBaseIv(uint boardId, uint baseIv) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      if (baseIv < optionMarketBounds.minBaseIv || baseIv > optionMarketBounds.maxBaseIv) {
        revert OMGW_BaseIVOutOfBounds(baseIv, boardId, msg.sender);
      }
    }
    optionMarket.setBoardBaseIv(boardId, baseIv);
    emit OMGW_BoardBaseIvSet(msg.sender, boardId, baseIv);
  }

  function setStrikeSkew(uint strikeId, uint skew) external onlyRiskCouncilOrOwner {
    if (msg.sender == riskCouncil) {
      if (skew < optionMarketBounds.minSkew || skew > optionMarketBounds.maxSkew) {
        revert OMGW_SkewOutOfBounds(skew, strikeId, msg.sender);
      }
    }
    optionMarket.setStrikeSkew(strikeId, skew);
    emit OMGW_StrikeSkewSet(msg.sender, strikeId, skew);
  }

  function forceSettleBoard(uint boardId) external onlyRiskCouncilOrOwner {
    if (optionMarketBounds.boardForceSettlingBlocked) {
      revert OMGW_BoardForceSettlingIsBlocked(boardId, msg.sender);
    }
    optionMarket.forceSettleBoard(boardId);
    emit OMGW_BoardForceSettled(msg.sender, boardId);
  }

  function recoverOMFunds(IERC20Decimals token, address recipient) external onlyRiskCouncilOrOwner {
    if (optionMarketBounds.recoverFundsBlocked) {
      revert OMGW_RecoverFundsBlocked(msg.sender);
    }
    optionMarket.recoverFunds(token, recipient);
    emit OMGW_OptionMarketFundsRecovered(msg.sender, token, recipient);
  }

  ///////////
  // Views //
  ///////////
  function getOptionMarketBounds() external view returns (OptionMarketBounds memory bounds) {
    return optionMarketBounds;
  }

  ////////////
  // Access //
  ////////////

  function _onlyBoardManagerOrOwner() internal view {
    if (msg.sender != owner && msg.sender != boardManager) {
      revert OMGW_OnlyOwnerOrBoardManager(msg.sender, owner, boardManager);
    }
  }

  modifier onlyBoardManagerOrOwner() {
    _onlyBoardManagerOrOwner();
    _;
  }

  ////////////
  // Events //
  ////////////
  event OMGW_OptionMarketSet(OptionMarket optionMarket);

  event OMGW_BoardManagerChanged(address boardManager);

  event OMGW_OptionMarketBoundsSet(OptionMarketBounds bounds);

  event OMGW_OptionMarketParamsSet(OptionMarket.OptionMarketParameters optionMarketParams);

  event OMGW_BoardBaseIvSet(address indexed caller, uint indexed boardId, uint baseIv);

  event OMGW_StrikeSkewSet(address indexed caller, uint indexed strikeId, uint skew);

  event OMGW_BoardForceSettled(address indexed caller, uint indexed boardId);

  event OMGW_StrikeAddedToBoard(address indexed caller, uint indexed boardId, uint strikePrice, uint skew);

  event OMGW_BoardCreated(address indexed caller, uint expiry, uint boardId);

  event OMGW_BoardFrozen(address indexed caller, uint indexed boardId, bool frozen);

  event OMGW_OptionMarketFundsRecovered(address indexed caller, IERC20Decimals token, address recipient);

  event OMGW_OptionMarketBaseLimit(uint baseLimit);

  ////////////
  // Errors //
  ////////////
  error OMGW_OptionMarketAlreadySet(OptionMarket optionMarket);

  error OMGW_OnlyOwnerOrBoardManager(address caller, address owner, address boardManager);

  error OMGW_BoardFreezingIsBlocked(address caller);

  error OMGW_BaseIVOutOfBounds(uint baseIv, uint boardId, address caller);

  error OMGW_SkewOutOfBounds(uint skew, uint strikeId, address caller);

  error OMGW_BoardForceSettlingIsBlocked(uint boardId, address caller);

  error OMGW_RecoverFundsBlocked(address caller);

  error OMGW_BaseLimitInvalid(uint baseLimit, address caller);
}
