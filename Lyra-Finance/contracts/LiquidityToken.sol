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

// Libraries
import "./synthetix/DecimalMath.sol";

// Inherited
import "Lyra-Finance/openzeppelin-contracts-4.4.1/token/ERC20/ERC20.sol";
import "./synthetix/Owned.sol";
import "./libraries/SimpleInitializable.sol";

// Interfaces
import "./interfaces/ILiquidityTracker.sol";

/**
 * @title LiquidityToken
 * @author Lyra
 * @dev An ERC20 token which represents a share of the LiquidityPool.
 * It is minted when users deposit, and burned when users withdraw.
 */
contract LiquidityToken is ERC20, Owned, SimpleInitializable {
  using DecimalMath for uint;

  /// @dev The liquidityPool for which these tokens represent a share of
  address public liquidityPool;
  /// @dev Contract to call when liquidity gets updated. Basically a hook for future contracts to use.
  ILiquidityTracker public liquidityTracker;

  ///////////
  // Setup //
  ///////////

  /**
   * @param name_ Token collection name
   * @param symbol_ Token collection symbol
   */
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Owned() {}

  /**
   * @dev Initialize the contract.
   * @param _liquidityPool LiquidityPool address
   */
  function init(address _liquidityPool) external onlyOwner initializer {
    liquidityPool = _liquidityPool;
  }

  ///////////
  // Admin //
  ///////////

  function setLiquidityTracker(ILiquidityTracker _liquidityTracker) external onlyOwner {
    liquidityTracker = _liquidityTracker;
    emit LiquidityTrackerSet(liquidityTracker);
  }

  ////////////////////////
  // Only LiquidityPool //
  ////////////////////////

  /**
   * @dev Mints new tokens and transfers them to `owner`.
   */
  function mint(address account, uint tokenAmount) external onlyLiquidityPool {
    _mint(account, tokenAmount);
  }

  /**
   * @dev Burn new tokens and transfers them to `owner`.
   */
  function burn(address account, uint tokenAmount) external onlyLiquidityPool {
    _burn(account, tokenAmount);
  }

  //////////
  // Misc //
  //////////
  /**
   * @dev Override to track the liquidty of the token. Mint, address(0), burn - to, address(0)
   */
  function _afterTokenTransfer(address from, address to, uint amount) internal override {
    if (address(liquidityTracker) != address(0)) {
      if (from != address(0)) {
        liquidityTracker.removeTokens(from, amount);
      }
      if (to != address(0)) {
        liquidityTracker.addTokens(to, amount);
      }
    }
  }

  ///////////////
  // Modifiers //
  ///////////////

  modifier onlyLiquidityPool() {
    if (msg.sender != liquidityPool) {
      revert OnlyLiquidityPool(address(this), msg.sender, liquidityPool);
    }
    _;
  }

  ////////////
  // Events //
  ////////////
  event LiquidityTrackerSet(ILiquidityTracker liquidityTracker);

  ////////////
  // Errors //
  ////////////
  // Access
  error OnlyLiquidityPool(address thrower, address caller, address liquidityPool);
}
