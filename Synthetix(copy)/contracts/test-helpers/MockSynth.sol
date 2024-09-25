/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Synthetix?utm=code
  */
  
  pragma solidity ^0.5.16;

import "../ExternStateToken.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IFeePool.sol";

// Mock synth that also adheres to system status

contract MockSynth is ExternStateToken {
    IAddressResolver private addressResolver;
    bytes32 public currencyKey;

    // Where fees are pooled in sUSD
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        address _owner,
        bytes32 _currencyKey
    ) public ExternStateToken(_proxy, _tokenState, _name, _symbol, _totalSupply, 18, _owner) {
        currencyKey = _currencyKey;
    }

    function setAddressResolver(IAddressResolver _resolver) external {
        addressResolver = _resolver;
    }

    // Used for PurgeableSynth to test removal
    function setTotalSupply(uint256 _totalSupply) external {
        totalSupply = _totalSupply;
    }

    /**
     * @notice _transferToFeeAddress function
     * non-sUSD synths are exchanged into sUSD via synthInitiatedExchange
     * notify feePool to record amount as fee paid to feePool */
    function _transferToFeeAddress(address to, uint value) internal returns (bool) {
        uint amountInUSD;

        // sUSD can be transferred to FEE_ADDRESS directly
        if (currencyKey == "sUSD") {
            amountInUSD = value;
            _transferByProxy(messageSender, to, value);
        } else {
            // for now, do nothing
        }

        // Notify feePool to record sUSD to distribute as fees
        IFeePool(addressResolver.getAddress("FeePool")).recordFeePaid(amountInUSD);

        return true;
    }

    function transfer(address to, uint value) external optionalProxy returns (bool) {
        ISystemStatus(addressResolver.getAddress("SystemStatus")).requireSynthActive(currencyKey);

        // transfers to FEE_ADDRESS will be exchanged into sUSD and recorded as fee
        if (to == FEE_ADDRESS) {
            return _transferToFeeAddress(to, value);
        }

        // transfers to 0x address will be burned
        if (to == address(0)) {
            this.burn(messageSender, value);
            return true;
        }

        return _transferByProxy(messageSender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external optionalProxy returns (bool) {
        ISystemStatus(addressResolver.getAddress("SystemStatus")).requireSynthActive(currencyKey);

        return _transferFromByProxy(messageSender, from, to, value);
    }

    event Issued(address indexed account, uint value);

    event Burned(address indexed account, uint value);

    // Allow these functions which are typically restricted to internal contracts, be open to us for mocking
    function issue(address account, uint amount) external {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emit Issued(account, amount);
    }

    function burn(address account, uint amount) external {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emit Burned(account, amount);
    }
}
