/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee?utm=code
  */
  
  // SPDX-License-Identifier: MIT

/**

 TheViralCrypto presents: #VIRAL
   
 by @SatoshiViral

 Community: @TheViralCrypto
 Website: https://theviralcrypto.co/

 */

pragma solidity ^0.8.10;

import "./interfaces/DividendPayingToken.sol";
import "./interfaces/Ownable.sol";
import "./interfaces/IDex.sol";
import "./interfaces/IERC20.sol";


library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract VIRAL is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public  pair;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled;
    bool public tradingEnabled;
    
    VIRALDividendTracker public dividendTracker;

    address public treasuryWallet = 0x73fA5dDF2aB78D92bB723D92Ab98aF7A0A4Fde8F;
    address public devWallet = 0x16023072c6a88555736B654629fC807d623617A5;

    uint256 public swapTokensAtAmount = 500_000 * 10**18;
    uint256 public maxBuyAmount = 1_000_000 * 10**18;
    uint256 public maxSellAmount = 1_000_000 * 10**18;

            ///////////////
           //   Fees    //
          ///////////////
    
    struct Taxes {
        uint256 rewards;
        uint256 treasury;
        uint256 liquidity;
        uint256 dev;
    }

    Taxes public buyTaxes = Taxes(0,0,0,2);
    Taxes public sellTaxes = Taxes(5,10,3,2);

    uint256 public totalBuyTax = 2;
    uint256 public totalSellTax = 20;

    mapping (address => bool) public _isBot;
      
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

        ///////////////
       //   Events  //
      ///////////////
      
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped,uint256 amount);
    event ProcessedDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);


    constructor() ERC20("VIRAL", "VIRAL") {

        dividendTracker = new VIRALDividendTracker();

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        dividendTracker.updateLP_Token(pair);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(treasuryWallet, true);
        excludeFromFees(devWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 10e9* (10**18));
    }

    receive() external payable {}
    function updateDividendTracker(address newAddress) public onlyOwner {
        VIRALDividendTracker newDividendTracker = VIRALDividendTracker(payable(newAddress));

        newDividendTracker.excludeFromDividends(address(newDividendTracker), true);
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        dividendTracker = newDividendTracker;
    }

    
    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }
    
    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    /// @notice Send remaining ETH to treasuryWallet
    /// @dev It will send all ETH to treasuryWallet
    function forceSend() external {
        uint256 ETHbalance = address(this).balance;
        payable(treasuryWallet).sendValue(ETHbalance);
    }

    function trackerRescueETH20Tokens(address tokenAddress) external onlyOwner{
        dividendTracker.trackerRescueETH20Tokens(owner(), tokenAddress);
    }

    function trackerForceSend() external onlyOwner{
        dividendTracker.trackerForceSend(owner());
    }
    
    function updateRouter(address newRouter) external onlyOwner{
        router = IRouter(newRouter);
    }
    
     /////////////////////////////////
    // Exclude / Include functions //
   /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "VIRAL: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(address account, bool value) external onlyOwner{
        dividendTracker.excludeFromDividends(account, value);
    }

     ///////////////////////
    //  Setter Functions //
   ///////////////////////

    function setTreasuryWallet(address newWallet) external onlyOwner{
        treasuryWallet = newWallet;
    }

    function setDevWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }

    /// @notice Update the threshold to swap tokens for liquidity,
    ///   treasury and dividends.
    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**18;
    }

    function setBuyTaxes(uint256 _rewards, uint256 _treasury, uint256 _liquidity, uint256 _dev) external onlyOwner{
        require(_rewards + _treasury + _liquidity + _dev <= 20, "Fee must be <= 20%");
        buyTaxes = Taxes(_rewards, _treasury, _liquidity, _dev);
        totalBuyTax = _rewards + _treasury + _liquidity + _dev;
    }

    function setSellTaxes(uint256 _rewards, uint256 _treasury, uint256 _liquidity,uint256 _dev) external onlyOwner{
        require(_rewards + _treasury + _liquidity + _dev <= 20, "Fee must be <= 20%");
        sellTaxes = Taxes(_rewards, _treasury, _liquidity, _dev);
        totalSellTax = _rewards + _treasury + _liquidity + _dev;
    }

    function setMaxBuyAndSell(uint256 maxBuy, uint256 maxSell) external onlyOwner{
        maxBuyAmount = maxBuy * 10**18;
        maxSellAmount = maxSell * 10**18;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, treasury and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    
    
    function activateTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }

    function setClaimEnabled(bool state) external onlyOwner{
        claimEnabled = state;
    }

    /// @param bot The bot address
    /// @param value "true" to blacklist, "false" to unblacklist
    function setBot(address bot, bool value) external onlyOwner{
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }
    
    function setBulkBot(address[] memory bots, bool value) external onlyOwner{
        for(uint256 i; i<bots.length; i++){
            _isBot[bots[i]] = value;
        }
    }

    function setLP_Token(address _lpToken) external onlyOwner{
        dividendTracker.updateLP_Token(_lpToken);
    }


    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }
    
    
    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value, "VIRAL: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[newPair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

     //////////////////////
    // Getter Functions //
   //////////////////////

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(address account)
        external view returns (
             address,
            uint256,
            uint256,
            uint256,
            uint256){
        return dividendTracker.getAccount(account);
    }

     ////////////////////////
    // Transfer Functions //
   ////////////////////////
   
    // Airdrop tokens to users. This won't update the dividend balance in order to avoid a gas issue.
    // Users will get dividend balance updated as soon as their balance change.
    function airdropTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner{
        require(accounts.length == amounts.length, "Arrays must have same size");
        for(uint256 i; i< accounts.length; i++){
            super._transfer(msg.sender, accounts[i], amounts[i]);
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping){
            require(tradingEnabled, "Trading not active");
            require(!_isBot[from] && !_isBot[to], "Bye Bye Bot");
            if(automatedMarketMakerPairs[to]) require(amount <= maxSellAmount, "You are exceeding maxSellAmount");
            else if(automatedMarketMakerPairs[from]) require(amount <= maxBuyAmount, "You are exceeding maxBuyAmount");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap && !swapping && swapEnabled && automatedMarketMakerPairs[to] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            if(totalSellTax> 0){
                swapAndLiquify(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from]) takeFee = false;

        if(takeFee) {
            uint256 feeAmt;
            if(automatedMarketMakerPairs[to]) feeAmt = amount * totalSellTax / 100;
            else if(automatedMarketMakerPairs[from]) feeAmt = amount * totalBuyTax / 100;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}

    }

    function swapAndLiquify(uint256 tokens) private {
        // Split the contract balance into halves
        uint256 tokensToAddLiquidityWith = tokens / 2;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 ETHToAddLiquidityWith = address(this).balance - initialBalance;

        if(ETHToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        uint256 totalTax = (totalSellTax - sellTaxes.liquidity);

        // Send LP to treasuryWallet
        uint256 treasuryAmt = lpBalance * sellTaxes.treasury / totalTax;
        if(treasuryAmt > 0){
            IERC20(pair).transfer(treasuryWallet, treasuryAmt);
        }

        // Send LP to dev
        uint256 devAmt = lpBalance * sellTaxes.dev / totalTax;
        if(devAmt > 0){
            IERC20(pair).transfer(devWallet, devAmt);
        }

        //Send LP to dividends
        uint256 dividends = lpBalance * sellTaxes.rewards / totalTax;
        if(dividends > 0){
            bool success = IERC20(pair).transfer(address(dividendTracker), dividends);
            if (success) {
                dividendTracker.distributeLPDividends(dividends);
                emit SendDividends(tokens, dividends);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

}

contract VIRALDividendTracker is Ownable, DividendPayingToken {
    using Address for address payable;

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);

    constructor()  DividendPayingToken("VIRAL_Dividen_Tracker", "VIRAL_Dividend_Tracker") {}

    function trackerRescueETH20Tokens(address recipient, address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function trackerForceSend(address recipient) external onlyOwner{
        uint256 ETHbalance = address(this).balance;
        payable(recipient).sendValue(ETHbalance);
    }

    function updateLP_Token(address _lpToken) external onlyOwner{
        LP_Token = _lpToken;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "VIRAL_Dividend_Tracker: No transfers allowed");
    }
    

    function excludeFromDividends(address account, bool value) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
      if(value == true){
        _setBalance(account, 0);
      }
      else{
        _setBalance(account, balanceOf(account));
      }
      emit ExcludeFromDividends(account, value);

    }

    function getAccount(address account) public view returns (address, uint256, uint256, uint256, uint256 ) {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
        
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function processAccount(address payable account) external onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }
}
