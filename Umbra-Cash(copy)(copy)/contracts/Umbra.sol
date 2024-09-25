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

import "Umbra-Cash/@openzeppelin/contracts/access/Ownable.sol";
import "Umbra-Cash/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IUmbraHookReceiver.sol";

contract Umbra is Ownable {
  // =========================================== Events ============================================

  /// @notice Emitted when a payment is sent
  event Announcement(
    address indexed receiver, // stealth address
    uint256 amount, // funds
    address indexed token, // token address or ETH placeholder
    bytes32 pkx, // ephemeral public key x coordinate
    bytes32 ciphertext // encrypted entropy and payload extension
  );

  /// @notice Emitted when a token is withdrawn
  event TokenWithdrawal(
    address indexed receiver, // stealth address
    address indexed acceptor, // destination of funds
    uint256 amount, // funds
    address indexed token // token address
  );

  // ======================================= State variables =======================================

  /// @dev Placeholder address used to identify transfer of native ETH
  address internal constant ETH_TOKEN_PLACHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice An ETH amount that must be sent alongside each payment; used as an anti-spam measure
  uint256 public toll;

  /// @notice A privileged address, set by the admin, that can sweep all collected ETH tolls
  address public tollCollector;

  /// @notice The address where ETH funds are sent when collected by the tollCollector
  address payable public tollReceiver;

  /// @notice Token payments pending withdrawal; stealth address => token address => amount
  mapping(address => mapping(address => uint256)) public tokenPayments;

  // ======================================= Setup & Admin ========================================

  /**
   * @param _toll Amount of ETH required per send
   * @param _tollCollector Address that can sweep collected funds
   * @param _tollReceiver Address that receives collected funds
   */
  constructor(
    uint256 _toll,
    address _tollCollector,
    address payable _tollReceiver
  ) {
    toll = _toll;
    tollCollector = _tollCollector;
    tollReceiver = _tollReceiver;
  }

  /**
   * @notice Admin only function to update the toll
   * @param _newToll New ETH toll in wei
   */
  function setToll(uint256 _newToll) external onlyOwner {
    toll = _newToll;
  }

  /**
   * @notice Admin only function to update the toll collector
   * @param _newTollCollector New address which has fund sweeping privileges
   */
  function setTollCollector(address _newTollCollector) external onlyOwner {
    tollCollector = _newTollCollector;
  }

  /**
   * @notice Admin only function to update the toll receiver
   * @param _newTollReceiver New address which receives collected funds
   */
  function setTollReceiver(address payable _newTollReceiver) external onlyOwner {
    tollReceiver = _newTollReceiver;
  }

  /**
   * @notice Function only the toll collector can call to sweep funds to the toll receiver
   */
  function collectTolls() external {
    require(msg.sender == tollCollector, "Umbra: Not toll collector");
    tollReceiver.transfer(address(this).balance);
  }

  // ======================================= Send =================================================

  /**
   * @notice Send and announce ETH payment to a stealth address
   * @param _receiver Stealth address receiving the payment
   * @param _tollCommitment Exact toll the sender is paying; should equal contract toll;
   * the committment is used to prevent frontrunning attacks by the owner;
   * see https://github.com/ScopeLift/umbra-protocol/issues/54 for more information
   * @param _pkx X-coordinate of the ephemeral public key used to encrypt the payload
   * @param _ciphertext Encrypted entropy (used to generated the stealth address) and payload extension
   */
  function sendEth(
    address payable _receiver,
    uint256 _tollCommitment,
    bytes32 _pkx, // ephemeral public key x coordinate
    bytes32 _ciphertext
  ) external payable {
    require(_tollCommitment == toll, "Umbra: Invalid or outdated toll commitment");

    // also protects from underflow
    require(msg.value > toll, "Umbra: Must pay more than the toll");

    uint256 amount = msg.value - toll;
    emit Announcement(_receiver, amount, ETH_TOKEN_PLACHOLDER, _pkx, _ciphertext);

    _receiver.transfer(amount);
  }

  /**
   * @notice Send and announce an ERC20 payment to a stealth address
   * @param _receiver Stealth address receiving the payment
   * @param _tokenAddr Address of the ERC20 token being sent
   * @param _amount Amount of the token to send, in its own base units
   * @param _pkx X-coordinate of the ephemeral public key used to encrypt the payload
   * @param _ciphertext Encrypted entropy (used to generated the stealth address) and payload extension
   */
  function sendToken(
    address _receiver,
    address _tokenAddr,
    uint256 _amount,
    bytes32 _pkx, // ephemeral public key x coordinate
    bytes32 _ciphertext
  ) external payable {
    require(msg.value == toll, "Umbra: Must pay the exact toll");
    require(tokenPayments[_receiver][_tokenAddr] == 0, "Umbra: Cannot send more tokens to stealth address");

    tokenPayments[_receiver][_tokenAddr] = _amount;
    emit Announcement(_receiver, _amount, _tokenAddr, _pkx, _ciphertext);

    SafeERC20.safeTransferFrom(IERC20(_tokenAddr), msg.sender, address(this), _amount);
  }

  // ======================================= Withdraw =============================================

  /**
   * @notice Withdraw an ERC20 token payment sent to a stealth address
   * @dev This method must be directly called by the stealth address
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   */
  function withdrawToken(address _acceptor, address _tokenAddr) external {
    _withdrawTokenInternal(msg.sender, _acceptor, _tokenAddr, address(0), 0, IUmbraHookReceiver(0), "");
  }

  /**
   * @notice Withdraw an ERC20 token payment sent to a stealth address
   * @dev This method must be directly called by the stealth address
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _hook Contract that will be called after the token withdrawal has completed
   * @param _data Arbitrary data that will be passed to the post-withdraw hook contract
   */
  function withdrawTokenAndCall(
    address _acceptor,
    address _tokenAddr,
    IUmbraHookReceiver _hook,
    bytes memory _data
  ) external {
    _withdrawTokenInternal(msg.sender, _acceptor, _tokenAddr, address(0), 0, _hook, _data);
  }

  /**
   * @notice Withdraw an ERC20 token payment on behalf of a stealth address via signed authorization
   * @param _stealthAddr The stealth address whose token balance will be withdrawn
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _sponsor Address which is compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token to pay to the sponsor
   * @param _v ECDSA signature component: Parity of the `y` coordinate of point `R`
   * @param _r ECDSA signature component: x-coordinate of `R`
   * @param _s ECDSA signature component: `s` value of the signature
   */
  function withdrawTokenOnBehalf(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    _validateWithdrawSignature(
      _stealthAddr,
      _acceptor,
      _tokenAddr,
      _sponsor,
      _sponsorFee,
      IUmbraHookReceiver(0),
      "",
      _v,
      _r,
      _s
    );
    _withdrawTokenInternal(_stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, IUmbraHookReceiver(0), "");
  }

  /**
   * @notice Withdraw an ERC20 token payment on behalf of a stealth address via signed authorization
   * @param _stealthAddr The stealth address whose token balance will be withdrawn
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _sponsor Address which is compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token to pay to the sponsor
   * @param _hook Contract that will be called after the token withdrawal has completed
   * @param _data Arbitrary data that will be passed to the post-withdraw hook contract
   * @param _v ECDSA signature component: Parity of the `y` coordinate of point `R`
   * @param _r ECDSA signature component: x-coordinate of `R`
   * @param _s ECDSA signature component: `s` value of the signature
   */
  function withdrawTokenAndCallOnBehalf(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    _validateWithdrawSignature(_stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, _hook, _data, _v, _r, _s);
    _withdrawTokenInternal(_stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, _hook, _data);
  }

  /**
   * @notice Low level withdrawal function that should only be called after safety checks
   * @param _stealthAddr The stealth address whose token balance will be withdrawn
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _sponsor Address which is compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token to pay to the sponsor
   * @param _hook Contract that will be called after the token withdrawal has completed
   * @param _data Arbitrary data that will be passed to the post-withdraw hook contract
   */
  function _withdrawTokenInternal(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data
  ) internal {
    uint256 _amount = tokenPayments[_stealthAddr][_tokenAddr];

    // also protects from underflow
    require(_amount > _sponsorFee, "Umbra: No balance to withdraw or fee exceeds balance");

    uint256 _withdrawalAmount = _amount - _sponsorFee;
    delete tokenPayments[_stealthAddr][_tokenAddr];
    emit TokenWithdrawal(_stealthAddr, _acceptor, _withdrawalAmount, _tokenAddr);

    SafeERC20.safeTransfer(IERC20(_tokenAddr), _acceptor, _withdrawalAmount);

    if (_sponsorFee > 0) {
      SafeERC20.safeTransfer(IERC20(_tokenAddr), _sponsor, _sponsorFee);
    }

    if (address(_hook) != address(0)) {
      _hook.tokensWithdrawn(_withdrawalAmount, _stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, _data);
    }
  }

  /**
   * @notice Internal method which recovers address from signature of the parameters and throws if not _stealthAddr
   * @param _stealthAddr The stealth address whose token balance will be withdrawn
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _sponsor Address which is compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token to pay to the sponsor
   * @param _hook Contract that will be called after the token withdrawal has completed
   * @param _data Arbitrary data that will be passed to the post-withdraw hook contract
   * @param _v ECDSA signature component: Parity of the `y` coordinate of point `R`
   * @param _r ECDSA signature component: x-coordinate of `R`
   * @param _s ECDSA signature component: `s` value of the signature
   */
  function _validateWithdrawSignature(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) internal view {
    uint256 _chainId;
    assembly {
      _chainId := chainid()
    }

    bytes32 _digest =
      keccak256(
        abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          keccak256(
            abi.encode(_chainId, address(this), _acceptor, _tokenAddr, _sponsor, _sponsorFee, address(_hook), _data)
          )
        )
      );

    address _recoveredAddress = ecrecover(_digest, _v, _r, _s);
    require(_recoveredAddress != address(0) && _recoveredAddress == _stealthAddr, "Umbra: Invalid Signature");
  }
}
