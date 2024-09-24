/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Umbra-Cash?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/// @dev Interface that post-withdraw hooks must implement to interop with Umbra
interface IUmbraHookReceiver {
  /**
   * @notice Method called after a user completes an Umbra token withdrawal
   * @param _amount The amount of the token withdrawn _after_ subtracting the sponsor fee
   * @param _stealthAddr The stealth address whose token balance was withdrawn
   * @param _acceptor Address where withdrawn funds were sent; can be this contract
   * @param _tokenAddr Address of the ERC20 token that was withdrawn
   * @param _sponsor Address which was compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token that was paid to the sponsor
   * @param _data Arbitrary data passed to this hook by the withdrawer
   */
  function tokensWithdrawn(
    uint256 _amount,
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    bytes memory _data
  ) external;
}
