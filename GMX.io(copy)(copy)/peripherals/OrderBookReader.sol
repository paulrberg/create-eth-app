/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/GMX.io?utm=code
  */
  
  // SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";

import "../core/interfaces/IOrderBook.sol";

contract OrderBookReader {
    using SafeMath for uint256;

    struct Vars {
        uint256 i;
        uint256 index;
        address account;
        uint256 uintLength;
        uint256 addressLength;
    }

    function getIncreaseOrders(
        address payable _orderBookAddress, 
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address purchaseToken,
                uint256 purchaseTokenAmount,
                address collateralToken,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold,
                // uint256 executionFee
            ) = orderBook.getIncreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(purchaseTokenAmount);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (purchaseToken);
            addressProps[vars.i * vars.addressLength + 1] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 2] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getDecreaseOrders(
        address payable _orderBookAddress, 
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 2);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address collateralToken,
                uint256 collateralDelta,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold,
                // uint256 executionFee
            ) = orderBook.getDecreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(collateralDelta);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 1] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getSwapOrders(
        address payable _orderBookAddress, 
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBook orderBook = IOrderBook(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address path0,
                address path1,
                address path2,
                uint256 amountIn, 
                uint256 minOut, 
                uint256 triggerRatio, 
                bool triggerAboveThreshold,
                bool shouldUnwrap,
                // uint256 executionFee
            ) = orderBook.getSwapOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(amountIn);
            uintProps[vars.i * vars.uintLength + 1] = uint256(minOut);
            uintProps[vars.i * vars.uintLength + 2] = uint256(triggerRatio);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerAboveThreshold ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 4] = uint256(shouldUnwrap ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (path0);
            addressProps[vars.i * vars.addressLength + 1] = (path1);
            addressProps[vars.i * vars.addressLength + 2] = (path2);

            vars.i++;
        }

        return (uintProps, addressProps);
    }
}
