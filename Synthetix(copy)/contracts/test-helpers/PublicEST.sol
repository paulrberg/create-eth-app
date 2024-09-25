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

import "../interfaces/IRewardEscrowV2.sol";
import "../ExternStateToken.sol";

contract PublicEST is ExternStateToken {
    uint8 public constant DECIMALS = 18;

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        address _owner
    ) public ExternStateToken(_proxy, _tokenState, _name, _symbol, _totalSupply, DECIMALS, _owner) {}

    function transfer(address to, uint value) external optionalProxy returns (bool) {
        return _transferByProxy(messageSender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external optionalProxy returns (bool) {
        return _transferFromByProxy(messageSender, from, to, value);
    }

    // Index all parameters to make them easier to find in raw logs (as this will be emitted via a proxy and not decoded)
    event Received(address indexed sender, uint256 indexed inputA, bytes32 indexed inputB);

    function somethingToBeProxied(uint256 inputA, bytes32 inputB) external {
        emit Received(messageSender, inputA, inputB);
    }

    // SIP-252: allow to call revokeFrom on rewardsEscrow
    // this is needed here because SNX is both the required caller for this method, and needs to be an actual ERC20,
    // so using an EOA instead of it doesn't work
    function revokeFrom(
        address rewardEscrowV2,
        address account,
        address recipient,
        uint targetAmount,
        uint startIndex
    ) external {
        IRewardEscrowV2(rewardEscrowV2).revokeFrom(account, recipient, targetAmount, startIndex);
    }
}
