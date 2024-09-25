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
pragma solidity =0.8.12;

import "../interfaces/IStrategyManager.sol";
import "../permissions/Pausable.sol";
import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "Eigenlayer/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "Eigenlayer/lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title Base implementation of `IStrategy` interface, designed to be inherited from by more complex strategies.
 * @author Layr Labs, Inc.
 * @notice Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service
 * @notice Simple, basic, "do-nothing" Strategy that holds a single underlying token and returns it on withdrawals.
 * Implements minimal versions of the IStrategy functions, this contract is designed to be inherited by
 * more complex strategies, which can then override its functions as necessary.
 * @dev Note that some functions have their mutability restricted; developers inheriting from this contract cannot broaden
 * the mutability without modifying this contract itself.
 * @dev This contract is expressly *not* intended for use with 'fee-on-transfer'-type tokens.
 * Setting the `underlyingToken` to be a fee-on-transfer token may result in improper accounting.
 * @notice This contract functions similarly to an ERC4626 vault, only without issuing a token.
 * To mitigate against the common "inflation attack" vector, we have chosen to use the 'virtual shares' mitigation route,
 * similar to [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol).
 * We acknowledge that this mitigation has the known downside of the virtual shares causing some losses to users, which are pronounced
 * particularly in the case of the share exchange rate changing signficantly, either positively or negatively.
 * For a fairly thorough discussion of this issue and our chosen mitigation strategy, we recommend reading through
 * [this thread](https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706) on the OpenZeppelin repo.
 * We specifically use a share offset of `SHARES_OFFSET` and a balance offset of `BALANCE_OFFSET`.
 */
contract StrategyBase is Initializable, Pausable, IStrategy {
    using SafeERC20 for IERC20;

    uint8 internal constant PAUSED_DEPOSITS = 0;
    uint8 internal constant PAUSED_WITHDRAWALS = 1;

    /**
     * @notice virtual shares used as part of the mitigation of the common 'share inflation' attack vector.
     * Constant value chosen to reasonably reduce attempted share inflation by the first depositor, while still
     * incurring reasonably small losses to depositors
     */
    uint256 internal constant SHARES_OFFSET = 1e3;
    /** 
     * @notice virtual balance used as part of the mitigation of the common 'share inflation' attack vector
     * Constant value chosen to reasonably reduce attempted share inflation by the first depositor, while still
     * incurring reasonably small losses to depositors
     */
    uint256 internal constant BALANCE_OFFSET = 1e3;

    /// @notice EigenLayer's StrategyManager contract
    IStrategyManager public immutable strategyManager;

    /// @notice The underlying token for shares in this Strategy
    IERC20 public underlyingToken;

    /// @notice The total number of extant shares in this Strategy
    uint256 public totalShares;

    /// @notice Simply checks that the `msg.sender` is the `strategyManager`, which is an address stored immutably at construction.
    modifier onlyStrategyManager() {
        require(msg.sender == address(strategyManager), "StrategyBase.onlyStrategyManager");
        _;
    }

    /// @notice Since this contract is designed to be initializable, the constructor simply sets `strategyManager`, the only immutable variable.
    constructor(IStrategyManager _strategyManager) {
        strategyManager = _strategyManager;
        _disableInitializers();
    }

    function initialize(IERC20 _underlyingToken, IPauserRegistry _pauserRegistry) public virtual initializer {
        _initializeStrategyBase(_underlyingToken, _pauserRegistry);
    }

    /// @notice Sets the `underlyingToken` and `pauserRegistry` for the strategy.
    function _initializeStrategyBase(IERC20 _underlyingToken, IPauserRegistry _pauserRegistry) internal onlyInitializing {
        underlyingToken = _underlyingToken;
        _initializePauser(_pauserRegistry, UNPAUSE_ALL);
    }

    /**
     * @notice Used to deposit tokens into this Strategy
     * @param token is the ERC20 token being deposited
     * @param amount is the amount of token being deposited
     * @dev This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
     * `depositIntoStrategy` function, and individual share balances are recorded in the strategyManager as well.
     * @dev Note that the assumption is made that `amount` of `token` has already been transferred directly to this contract
     * (as performed in the StrategyManager's deposit functions). In particular, setting the `underlyingToken` of this contract
     * to be a fee-on-transfer token will break the assumption that the amount this contract *received* of the token is equal to
     * the amount that was input when the transfer was performed (i.e. the amount transferred 'out' of the depositor's balance).
     * @return newShares is the number of new shares issued at the current exchange ratio.
     */
    function deposit(IERC20 token, uint256 amount)
        external
        virtual
        override
        onlyWhenNotPaused(PAUSED_DEPOSITS)
        onlyStrategyManager
        returns (uint256 newShares)
    {
        // call hook to allow for any pre-deposit logic
        _beforeDeposit(token, amount);

        require(token == underlyingToken, "StrategyBase.deposit: Can only deposit underlyingToken");

        // copy `totalShares` value to memory, prior to any change
        uint256 priorTotalShares = totalShares;

        /**
         * @notice calculation of newShares *mirrors* `underlyingToShares(amount)`, but is different since the balance of `underlyingToken`
         * has already been increased due to the `strategyManager` transferring tokens to this strategy prior to calling this function
         */
        // account for virtual shares and balance
        uint256 virtualShareAmount = priorTotalShares + SHARES_OFFSET;
        uint256 virtualTokenBalance = _tokenBalance() + BALANCE_OFFSET;
        // calculate the prior virtual balance to account for the tokens that were already transferred to this contract
        uint256 virtualPriorTokenBalance = virtualTokenBalance - amount;
        newShares = (amount * virtualShareAmount) / virtualPriorTokenBalance;

        // extra check for correctness / against edge case where share rate can be massively inflated as a 'griefing' sort of attack
        require(newShares != 0, "StrategyBase.deposit: newShares cannot be zero");

        // update total share amount to account for deposit
        totalShares = (priorTotalShares + newShares);
        return newShares;
    }

    /**
     * @notice Used to withdraw tokens from this Strategy, to the `depositor`'s address
     * @param depositor is the address to receive the withdrawn funds
     * @param token is the ERC20 token being transferred out
     * @param amountShares is the amount of shares being withdrawn
     * @dev This function is only callable by the strategyManager contract. It is invoked inside of the strategyManager's
     * other functions, and individual share balances are recorded in the strategyManager as well.
     */
    function withdraw(address depositor, IERC20 token, uint256 amountShares)
        external
        virtual
        override
        onlyWhenNotPaused(PAUSED_WITHDRAWALS)
        onlyStrategyManager
    {
        // call hook to allow for any pre-withdrawal logic
        _beforeWithdrawal(depositor, token, amountShares);
        
        require(token == underlyingToken, "StrategyBase.withdraw: Can only withdraw the strategy token");

        // copy `totalShares` value to memory, prior to any change
        uint256 priorTotalShares = totalShares;

        require(
            amountShares <= priorTotalShares,
            "StrategyBase.withdraw: amountShares must be less than or equal to totalShares"
        );

        /**
         * @notice calculation of amountToSend *mirrors* `sharesToUnderlying(amountShares)`, but is different since the `totalShares` has already
         * been decremented. Specifically, notice how we use `priorTotalShares` here instead of `totalShares`.
         */
        // account for virtual shares and balance
        uint256 virtualPriorTotalShares = priorTotalShares + SHARES_OFFSET;
        uint256 virtualTokenBalance = _tokenBalance() + BALANCE_OFFSET;
        // calculate ratio based on virtual shares and balance, being careful to multiply before dividing
        uint256 amountToSend = (virtualTokenBalance * amountShares) / virtualPriorTotalShares;

        // Decrease the `totalShares` value to reflect the withdrawal
        totalShares = priorTotalShares - amountShares;

        underlyingToken.safeTransfer(depositor, amountToSend);
    }


    /**
     * @notice Called in the external `deposit` function, before any logic is executed. Expected to be overridden if strategies want such logic.
     * @param token The token being deposited
     * @param amount The amount of `token` being deposited
     */
    function _beforeDeposit(IERC20 token, uint256 amount)  internal virtual {}

    /**
     * @notice Called in the external `withdraw` function, before any logic is executed.  Expected to be overridden if strategies want such logic.
     * @param depositor The address that will receive the withdrawn tokens
     * @param token The token being withdrawn
     * @param amountShares The amount of shares being withdrawn
     */
    function _beforeWithdrawal(address depositor, IERC20 token, uint256 amountShares) internal virtual {}

    /**
     * @notice Currently returns a brief string explaining the strategy's goal & purpose, but for more complex
     * strategies, may be a link to metadata that explains in more detail.
     */
    function explanation() external pure virtual override returns (string memory) {
        return "Base Strategy implementation to inherit from for more complex implementations";
    }

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlying`, this function guarantees no state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @return The amount of underlying tokens corresponding to the input `amountShares`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function sharesToUnderlyingView(uint256 amountShares) public view virtual override returns (uint256) {
        // account for virtual shares and balance
        uint256 virtualTotalShares = totalShares + SHARES_OFFSET;
        uint256 virtualTokenBalance = _tokenBalance() + BALANCE_OFFSET;
        // calculate ratio based on virtual shares and balance, being careful to multiply before dividing
        return (virtualTokenBalance * amountShares) / virtualTotalShares;
    }

    /**
     * @notice Used to convert a number of shares to the equivalent amount of underlying tokens for this strategy.
     * @notice In contrast to `sharesToUnderlyingView`, this function **may** make state modifications
     * @param amountShares is the amount of shares to calculate its conversion into the underlying token
     * @return The amount of underlying tokens corresponding to the input `amountShares`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function sharesToUnderlying(uint256 amountShares) public view virtual override returns (uint256) {
        return sharesToUnderlyingView(amountShares);
    }

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToShares`, this function guarantees no state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @return The amount of shares corresponding to the input `amountUnderlying`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function underlyingToSharesView(uint256 amountUnderlying) public view virtual returns (uint256) {
        // account for virtual shares and balance
        uint256 virtualTotalShares = totalShares + SHARES_OFFSET;
        uint256 virtualTokenBalance = _tokenBalance() + BALANCE_OFFSET;
        // calculate ratio based on virtual shares and balance, being careful to multiply before dividing
        return (amountUnderlying * virtualTotalShares) / virtualTokenBalance;
    }

    /**
     * @notice Used to convert an amount of underlying tokens to the equivalent amount of shares in this strategy.
     * @notice In contrast to `underlyingToSharesView`, this function **may** make state modifications
     * @param amountUnderlying is the amount of `underlyingToken` to calculate its conversion into strategy shares
     * @return The amount of shares corresponding to the input `amountUnderlying`
     * @dev Implementation for these functions in particular may vary significantly for different strategies
     */
    function underlyingToShares(uint256 amountUnderlying) external view virtual returns (uint256) {
        return underlyingToSharesView(amountUnderlying);
    }

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlying`, this function guarantees no state modifications
     */
    function userUnderlyingView(address user) external view virtual returns (uint256) {
        return sharesToUnderlyingView(shares(user));
    }

    /**
     * @notice convenience function for fetching the current underlying value of all of the `user`'s shares in
     * this strategy. In contrast to `userUnderlyingView`, this function **may** make state modifications
     */
    function userUnderlying(address user) external virtual returns (uint256) {
        return sharesToUnderlying(shares(user));
    }

    /**
     * @notice convenience function for fetching the current total shares of `user` in this strategy, by
     * querying the `strategyManager` contract
     */
    function shares(address user) public view virtual returns (uint256) {
        return strategyManager.stakerStrategyShares(user, IStrategy(address(this)));
    }

    /// @notice Internal function used to fetch this contract's current balance of `underlyingToken`.
    // slither-disable-next-line dead-code
    function _tokenBalance() internal view virtual returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
