/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/0x?utm=code
  */
  
  // SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "0x/contracts/erc20/src/IEtherToken.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibNativeOrdersRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinEIP712.sol";
import "../fixins/FixinTokenSpender.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibNativeOrdersStorage.sol";
import "../storage/LibOtcOrdersStorage.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IOtcOrdersFeature.sol";
import "./libs/LibNativeOrder.sol";
import "./libs/LibSignature.sol";

/// @dev Feature for interacting with OTC orders.
contract OtcOrdersFeature is IFeature, IOtcOrdersFeature, FixinCommon, FixinEIP712, FixinTokenSpender {
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "OtcOrders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev ETH pseudo-token address.
    address private constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherToken private immutable WETH;

    constructor(address zeroExAddress, IEtherToken weth) public FixinEIP712(zeroExAddress) {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.fillOtcOrder.selector);
        _registerFeatureFunction(this.fillOtcOrderForEth.selector);
        _registerFeatureFunction(this.fillOtcOrderWithEth.selector);
        _registerFeatureFunction(this.fillTakerSignedOtcOrderForEth.selector);
        _registerFeatureFunction(this.fillTakerSignedOtcOrder.selector);
        _registerFeatureFunction(this.batchFillTakerSignedOtcOrders.selector);
        _registerFeatureFunction(this._fillOtcOrder.selector);
        _registerFeatureFunction(this.getOtcOrderInfo.selector);
        _registerFeatureFunction(this.getOtcOrderHash.selector);
        _registerFeatureFunction(this.lastOtcTxOriginNonce.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        uint128 takerTokenFillAmount
    ) public override returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, msg.sender);
        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            takerTokenFillAmount,
            msg.sender,
            msg.sender
        );

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            msg.sender,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Unwraps bought WETH into ETH. before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderForEth(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        uint128 takerTokenFillAmount
    ) public override returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        require(order.makerToken == WETH, "OtcOrdersFeature::fillOtcOrderForEth/MAKER_TOKEN_NOT_WETH");
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, msg.sender);
        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            takerTokenFillAmount,
            msg.sender,
            address(this)
        );
        // Unwrap WETH
        WETH.withdraw(makerTokenFilledAmount);
        // Transfer ETH to taker
        _transferEth(msg.sender, makerTokenFilledAmount);

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            msg.sender,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Fill an OTC order whose taker token is WETH for up
    ///      to `msg.value`.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderWithEth(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature
    ) public payable override returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        if (order.takerToken == WETH) {
            // Wrap ETH
            WETH.deposit{value: msg.value}();
        } else {
            require(
                address(order.takerToken) == ETH_TOKEN_ADDRESS,
                "OtcOrdersFeature::fillOtcOrderWithEth/INVALID_TAKER_TOKEN"
            );
        }

        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, msg.sender);

        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            msg.value.safeDowncastToUint128(),
            address(this),
            msg.sender
        );
        if (takerTokenFilledAmount < msg.value) {
            uint256 refundAmount = msg.value - uint256(takerTokenFilledAmount);
            if (order.takerToken == WETH) {
                WETH.withdraw(refundAmount);
            }
            // Refund unused ETH
            _transferEth(msg.sender, refundAmount);
        }

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            msg.sender,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        LibSignature.Signature memory takerSignature
    ) public override {
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        address taker = LibSignature.getSignerOfHash(orderInfo.orderHash, takerSignature);

        _validateOtcOrder(order, orderInfo, makerSignature, taker);
        _settleOtcOrder(order, order.takerAmount, taker, taker);

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            taker,
            address(order.makerToken),
            address(order.takerToken),
            order.makerAmount,
            order.takerAmount
        );
    }

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    ///      Unwraps bought WETH into ETH. before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrderForEth(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        LibSignature.Signature memory takerSignature
    ) public override {
        require(order.makerToken == WETH, "OtcOrdersFeature::fillTakerSignedOtcOrder/MAKER_TOKEN_NOT_WETH");
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        address taker = LibSignature.getSignerOfHash(orderInfo.orderHash, takerSignature);

        _validateOtcOrder(order, orderInfo, makerSignature, taker);
        _settleOtcOrder(order, order.takerAmount, taker, address(this));
        // Unwrap WETH
        WETH.withdraw(order.makerAmount);
        // Transfer ETH to taker
        _transferEth(payable(taker), order.makerAmount);

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            taker,
            address(order.makerToken),
            address(order.takerToken),
            order.makerAmount,
            order.takerAmount
        );
    }

    /// @dev Fills multiple taker-signed OTC orders.
    /// @param orders Array of OTC orders.
    /// @param makerSignatures Array of maker signatures for each order.
    /// @param takerSignatures Array of taker signatures for each order.
    /// @param unwrapWeth Array of booleans representing whether or not
    ///        to unwrap bought WETH into ETH for each order. Should be set
    ///        to false if the maker token is not WETH.
    /// @return successes Array of booleans representing whether or not
    ///         each order in `orders` was filled successfully.
    function batchFillTakerSignedOtcOrders(
        LibNativeOrder.OtcOrder[] memory orders,
        LibSignature.Signature[] memory makerSignatures,
        LibSignature.Signature[] memory takerSignatures,
        bool[] memory unwrapWeth
    ) public override returns (bool[] memory successes) {
        require(
            orders.length == makerSignatures.length &&
                orders.length == takerSignatures.length &&
                orders.length == unwrapWeth.length,
            "OtcOrdersFeature::batchFillTakerSignedOtcOrders/MISMATCHED_ARRAY_LENGTHS"
        );
        successes = new bool[](orders.length);
        for (uint256 i = 0; i != orders.length; i++) {
            bytes4 fnSelector = unwrapWeth[i]
                ? this.fillTakerSignedOtcOrderForEth.selector
                : this.fillTakerSignedOtcOrder.selector;
            // Swallow reverts
            (successes[i], ) = _implementation.delegatecall(
                abi.encodeWithSelector(fnSelector, orders[i], makerSignatures[i], takerSignatures[i])
            );
        }
    }

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Internal variant.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @param taker The address to fill the order in the context of.
    /// @param useSelfBalance Whether to use the Exchange Proxy's balance
    ///        of input tokens.
    /// @param recipient The recipient of the bought maker tokens.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibSignature.Signature memory makerSignature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) public override onlySelf returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        LibNativeOrder.OtcOrderInfo memory orderInfo = getOtcOrderInfo(order);
        _validateOtcOrder(order, orderInfo, makerSignature, taker);
        (takerTokenFilledAmount, makerTokenFilledAmount) = _settleOtcOrder(
            order,
            takerTokenFillAmount,
            useSelfBalance ? address(this) : taker,
            recipient
        );

        emit OtcOrderFilled(
            orderInfo.orderHash,
            order.maker,
            taker,
            address(order.makerToken),
            address(order.takerToken),
            makerTokenFilledAmount,
            takerTokenFilledAmount
        );
    }

    /// @dev Validates an OTC order, reverting if the order cannot be
    ///      filled by the given taker.
    /// @param order The OTC order.
    /// @param orderInfo Info on the order.
    /// @param makerSignature The order signature from the maker.
    /// @param taker The order taker.
    function _validateOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        LibNativeOrder.OtcOrderInfo memory orderInfo,
        LibSignature.Signature memory makerSignature,
        address taker
    ) private view {
        // Must be fillable.
        if (orderInfo.status != LibNativeOrder.OrderStatus.FILLABLE) {
            LibNativeOrdersRichErrors.OrderNotFillableError(orderInfo.orderHash, uint8(orderInfo.status)).rrevert();
        }

        // Must be a valid taker for the order.
        if (order.taker != address(0) && order.taker != taker) {
            LibNativeOrdersRichErrors.OrderNotFillableByTakerError(orderInfo.orderHash, taker, order.taker).rrevert();
        }

        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        // Must be fillable by the tx.origin.
        if (order.txOrigin != tx.origin && !stor.originRegistry[order.txOrigin][tx.origin]) {
            LibNativeOrdersRichErrors
                .OrderNotFillableByOriginError(orderInfo.orderHash, tx.origin, order.txOrigin)
                .rrevert();
        }

        // Maker signature must be valid for the order.
        address makerSigner = LibSignature.getSignerOfHash(orderInfo.orderHash, makerSignature);
        if (makerSigner != order.maker && !stor.orderSignerRegistry[order.maker][makerSigner]) {
            LibNativeOrdersRichErrors
                .OrderNotSignedByMakerError(orderInfo.orderHash, makerSigner, order.maker)
                .rrevert();
        }
    }

    /// @dev Settle the trade between an OTC order's maker and taker.
    /// @param order The OTC order.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @param payer The address holding the taker tokens.
    /// @param recipient The recipient of the maker tokens.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _settleOtcOrder(
        LibNativeOrder.OtcOrder memory order,
        uint128 takerTokenFillAmount,
        address payer,
        address recipient
    ) private returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
        {
            // Unpack nonce fields
            uint64 nonceBucket = uint64(order.expiryAndNonce >> 128);
            uint128 nonce = uint128(order.expiryAndNonce);
            // Update tx origin nonce for the order
            LibOtcOrdersStorage.getStorage().txOriginNonces[order.txOrigin][nonceBucket] = nonce;
        }

        if (takerTokenFillAmount == order.takerAmount) {
            takerTokenFilledAmount = order.takerAmount;
            makerTokenFilledAmount = order.makerAmount;
        } else {
            // Clamp the taker token fill amount to the fillable amount.
            takerTokenFilledAmount = LibSafeMathV06.min128(takerTokenFillAmount, order.takerAmount);
            // Compute the maker token amount.
            // This should never overflow because the values are all clamped to
            // (2^128-1).
            makerTokenFilledAmount = uint128(
                LibMathV06.getPartialAmountFloor(
                    uint256(takerTokenFilledAmount),
                    uint256(order.takerAmount),
                    uint256(order.makerAmount)
                )
            );
        }

        if (payer == address(this)) {
            if (address(order.takerToken) == ETH_TOKEN_ADDRESS) {
                // Transfer ETH to the maker.
                payable(order.maker).transfer(takerTokenFilledAmount);
            } else {
                // Transfer this -> maker.
                _transferERC20Tokens(order.takerToken, order.maker, takerTokenFilledAmount);
            }
        } else {
            // Transfer taker -> maker
            _transferERC20TokensFrom(order.takerToken, payer, order.maker, takerTokenFilledAmount);
        }
        // Transfer maker -> recipient.
        _transferERC20TokensFrom(order.makerToken, order.maker, recipient, makerTokenFilledAmount);
    }

    /// @dev Get the order info for an OTC order.
    /// @param order The OTC order.
    /// @return orderInfo Info about the order.
    function getOtcOrderInfo(
        LibNativeOrder.OtcOrder memory order
    ) public view override returns (LibNativeOrder.OtcOrderInfo memory orderInfo) {
        // compute order hash.
        orderInfo.orderHash = getOtcOrderHash(order);

        LibOtcOrdersStorage.Storage storage stor = LibOtcOrdersStorage.getStorage();

        // Unpack expiry and nonce fields
        uint64 expiry = uint64(order.expiryAndNonce >> 192);
        uint64 nonceBucket = uint64(order.expiryAndNonce >> 128);
        uint128 nonce = uint128(order.expiryAndNonce);

        // check tx origin nonce
        uint128 lastNonce = stor.txOriginNonces[order.txOrigin][nonceBucket];
        if (nonce <= lastNonce) {
            orderInfo.status = LibNativeOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for expiration.
        if (expiry <= uint64(block.timestamp)) {
            orderInfo.status = LibNativeOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        orderInfo.status = LibNativeOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }

    /// @dev Get the canonical hash of an OTC order.
    /// @param order The OTC order.
    /// @return orderHash The order hash.
    function getOtcOrderHash(LibNativeOrder.OtcOrder memory order) public view override returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNativeOrder.getOtcOrderStructHash(order));
    }

    /// @dev Get the last nonce used for a particular
    ///      tx.origin address and nonce bucket.
    /// @param txOrigin The address.
    /// @param nonceBucket The nonce bucket index.
    /// @return lastNonce The last nonce value used.
    function lastOtcTxOriginNonce(
        address txOrigin,
        uint64 nonceBucket
    ) public view override returns (uint128 lastNonce) {
        LibOtcOrdersStorage.Storage storage stor = LibOtcOrdersStorage.getStorage();
        return stor.txOriginNonces[txOrigin][nonceBucket];
    }
}
