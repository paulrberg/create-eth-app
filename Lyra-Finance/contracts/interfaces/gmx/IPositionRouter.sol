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

interface IPositionRouter {
  struct IncreasePositionRequest {
    address account;
    address[] path;
    address indexToken;
    uint amountIn;
    uint minOut;
    uint sizeDelta;
    bool isLong;
    uint acceptablePrice;
    uint executionFee;
    uint blockNumber;
    uint blockTime;
    bool hasCollateralInETH;
    address callbackTarget;
  }

  struct DecreasePositionRequest {
    address account;
    address[] path;
    address indexToken;
    uint collateralDelta;
    uint sizeDelta;
    bool isLong;
    address receiver;
    uint acceptablePrice;
    uint minOut;
    uint executionFee;
    uint blockNumber;
    uint blockTime;
    bool withdrawETH;
    address callbackTarget;
  }

  function increasePositionRequests(
    bytes32 key
  )
    external
    view
    returns (
      address account,
      address[] memory,
      address,
      uint amountIn,
      uint,
      uint,
      bool,
      uint,
      uint,
      uint,
      uint,
      bool,
      address
    );

  function decreasePositionRequests(
    bytes32 key
  )
    external
    view
    returns (
      address account,
      address[] memory,
      address,
      uint,
      uint,
      bool,
      address,
      uint,
      uint,
      uint,
      uint,
      uint,
      bool,
      address
    );

  function vault() external view returns (address);

  function callbackGasLimit() external view returns (uint);

  function minExecutionFee() external view returns (uint);

  function increasePositionRequestKeysStart() external returns (uint);

  function decreasePositionRequestKeysStart() external returns (uint);

  function executeIncreasePositions(uint _count, address payable _executionFeeReceiver) external;

  function executeDecreasePositions(uint _count, address payable _executionFeeReceiver) external;

  function createIncreasePosition(
    address[] memory _path,
    address _indexToken,
    uint _amountIn,
    uint _minOut,
    uint _sizeDelta,
    bool _isLong,
    uint _acceptablePrice,
    uint _executionFee,
    bytes32 _referralCode,
    address _callbackTarget
  ) external payable returns (bytes32);

  function createDecreasePosition(
    address[] memory _path,
    address _indexToken,
    uint _collateralDelta,
    uint _sizeDelta,
    bool _isLong,
    address _receiver,
    uint _acceptablePrice,
    uint _minOut,
    uint _executionFee,
    bool _withdrawETH,
    address _callbackTarget
  ) external payable returns (bytes32);

  function cancelIncreasePosition(bytes32 _key, address _executionFeeReceiver) external returns (bool);

  function cancelDecreasePosition(bytes32 _key, address _executionFeeReceiver) external returns (bool);

  function maxGlobalLongSizes(address _token) external view returns (uint256);

  function maxGlobalShortSizes(address _token) external view returns (uint256);
}
