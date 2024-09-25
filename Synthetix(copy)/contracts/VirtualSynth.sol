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

// Inheritance
import "Synthetix/openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/ISynth.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IVirtualSynth.sol";
import "./interfaces/IExchanger.sol";

// https://docs.synthetix.io/contracts/source/contracts/virtualsynth
// Note: this contract should be treated as an abstract contract and should not be directly deployed.
//       On higher versions of solidity, it would be marked with the `abstract` keyword.
//       This contracts implements logic that is only intended to be accessed behind a proxy.
//       For the deployed "mastercopy" version, see VirtualSynthMastercopy.
contract VirtualSynth is ERC20, IVirtualSynth {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    IERC20 public synth;
    IAddressResolver public resolver;

    bool public settled = false;

    uint8 public constant decimals = 18;

    // track initial supply so we can calculate the rate even after all supply is burned
    uint public initialSupply;

    // track final settled amount of the synth so we can calculate the rate after settlement
    uint public settledAmount;

    bytes32 public currencyKey;

    bool public initialized = false;

    function initialize(
        IERC20 _synth,
        IAddressResolver _resolver,
        address _recipient,
        uint _amount,
        bytes32 _currencyKey
    ) external {
        require(!initialized, "vSynth already initialized");
        initialized = true;

        synth = _synth;
        resolver = _resolver;
        currencyKey = _currencyKey;

        // Assumption: the synth will be issued to us within the same transaction,
        // and this supply matches that
        _mint(_recipient, _amount);

        initialSupply = _amount;

        // Note: the ERC20 base contract does not have a constructor, so we do not have to worry
        // about initializing its state separately
    }

    // INTERNALS

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(resolver.requireAndGetAddress("Exchanger", "Exchanger contract not found"));
    }

    function secsLeft() internal view returns (uint) {
        return exchanger().maxSecsLeftInWaitingPeriod(address(this), currencyKey);
    }

    function calcRate() internal view returns (uint) {
        if (initialSupply == 0) {
            return 0;
        }

        uint synthBalance;

        if (!settled) {
            synthBalance = IERC20(address(synth)).balanceOf(address(this));
            (uint reclaim, uint rebate, ) = exchanger().settlementOwing(address(this), currencyKey);

            if (reclaim > 0) {
                synthBalance = synthBalance.sub(reclaim);
            } else if (rebate > 0) {
                synthBalance = synthBalance.add(rebate);
            }
        } else {
            synthBalance = settledAmount;
        }

        return synthBalance.divideDecimalRound(initialSupply);
    }

    function balanceUnderlying(address account) internal view returns (uint) {
        uint vBalanceOfAccount = balanceOf(account);

        return vBalanceOfAccount.multiplyDecimalRound(calcRate());
    }

    function settleSynth() internal {
        if (settled) {
            return;
        }
        settled = true;

        exchanger().settle(address(this), currencyKey);

        settledAmount = IERC20(address(synth)).balanceOf(address(this));

        emit Settled(totalSupply(), settledAmount);
    }

    // VIEWS

    function name() external view returns (string memory) {
        return string(abi.encodePacked("Virtual Synth ", currencyKey));
    }

    function symbol() external view returns (string memory) {
        return string(abi.encodePacked("v", currencyKey));
    }

    // get the rate of the vSynth to the synth.
    function rate() external view returns (uint) {
        return calcRate();
    }

    // show the balance of the underlying synth that the given address has, given
    // their proportion of totalSupply
    function balanceOfUnderlying(address account) external view returns (uint) {
        return balanceUnderlying(account);
    }

    function secsLeftInWaitingPeriod() external view returns (uint) {
        return secsLeft();
    }

    function readyToSettle() external view returns (bool) {
        return secsLeft() == 0;
    }

    // PUBLIC FUNCTIONS

    // Perform settlement of the underlying exchange if required,
    // then burn the accounts vSynths and transfer them their owed balanceOfUnderlying
    function settle(address account) external {
        settleSynth();

        IERC20(address(synth)).transfer(account, balanceUnderlying(account));

        _burn(account, balanceOf(account));
    }

    event Settled(uint totalSupply, uint amountAfterSettled);
}
