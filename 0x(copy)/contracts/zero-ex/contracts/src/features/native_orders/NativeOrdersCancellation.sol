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

import "0x/contracts/erc20/src/IERC20Token.sol";
import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";
import "../../storage/LibNativeOrdersStorage.sol";
import "../interfaces/INativeOrdersEvents.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./NativeOrdersInfo.sol";

/// @dev Feature for cancelling limit and RFQ orders.
abstract contract NativeOrdersCancellation is INativeOrdersEvents, NativeOrdersInfo {
    using LibRichErrorsV06 for bytes;

    /// @dev Highest bit of a uint256, used to flag cancelled orders.
    uint256 private constant HIGH_BIT = 1 << 255;

    constructor(address zeroExAddress) internal NativeOrdersInfo(zeroExAddress) {}

    /// @dev Cancel a single limit order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The limit order.
    function cancelLimitOrder(LibNativeOrder.LimitOrder memory order) public {
        bytes32 orderHash = getLimitOrderHash(order);
        if (msg.sender != order.maker && !isValidOrderSigner(order.maker, msg.sender)) {
            LibNativeOrdersRichErrors.OnlyOrderMakerAllowed(orderHash, msg.sender, order.maker).rrevert();
        }
        _cancelOrderHash(orderHash, order.maker);
    }

    /// @dev Cancel a single RFQ order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The RFQ order.
    function cancelRfqOrder(LibNativeOrder.RfqOrder memory order) public {
        bytes32 orderHash = getRfqOrderHash(order);
        if (msg.sender != order.maker && !isValidOrderSigner(order.maker, msg.sender)) {
            LibNativeOrdersRichErrors.OnlyOrderMakerAllowed(orderHash, msg.sender, order.maker).rrevert();
        }
        _cancelOrderHash(orderHash, order.maker);
    }

    /// @dev Cancel multiple limit orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The limit orders.
    function batchCancelLimitOrders(LibNativeOrder.LimitOrder[] memory orders) public {
        for (uint256 i = 0; i < orders.length; ++i) {
            cancelLimitOrder(orders[i]);
        }
    }

    /// @dev Cancel multiple RFQ orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The RFQ orders.
    function batchCancelRfqOrders(LibNativeOrder.RfqOrder[] memory orders) public {
        for (uint256 i = 0; i < orders.length; ++i) {
            cancelRfqOrder(orders[i]);
        }
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrders(IERC20Token makerToken, IERC20Token takerToken, uint256 minValidSalt) public {
        _cancelPairLimitOrders(msg.sender, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrdersWithSigner(
        address maker,
        IERC20Token makerToken,
        IERC20Token takerToken,
        uint256 minValidSalt
    ) public {
        // verify that the signer is authorized for the maker
        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        _cancelPairLimitOrders(maker, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrders(
        IERC20Token[] memory makerTokens,
        IERC20Token[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairLimitOrders(msg.sender, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrdersWithSigner(
        address maker,
        IERC20Token[] memory makerTokens,
        IERC20Token[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairLimitOrders(maker, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrders(IERC20Token makerToken, IERC20Token takerToken, uint256 minValidSalt) public {
        _cancelPairRfqOrders(msg.sender, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrdersWithSigner(
        address maker,
        IERC20Token makerToken,
        IERC20Token takerToken,
        uint256 minValidSalt
    ) public {
        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        _cancelPairRfqOrders(maker, makerToken, takerToken, minValidSalt);
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrders(
        IERC20Token[] memory makerTokens,
        IERC20Token[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairRfqOrders(msg.sender, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker the maker for whom the msg.sender is the signer.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrdersWithSigner(
        address maker,
        IERC20Token[] memory makerTokens,
        IERC20Token[] memory takerTokens,
        uint256[] memory minValidSalts
    ) public {
        require(
            makerTokens.length == takerTokens.length && makerTokens.length == minValidSalts.length,
            "NativeOrdersFeature/MISMATCHED_PAIR_ORDERS_ARRAY_LENGTHS"
        );

        if (!isValidOrderSigner(maker, msg.sender)) {
            LibNativeOrdersRichErrors.InvalidSignerError(maker, msg.sender).rrevert();
        }

        for (uint256 i = 0; i < makerTokens.length; ++i) {
            _cancelPairRfqOrders(maker, makerTokens[i], takerTokens[i], minValidSalts[i]);
        }
    }

    /// @dev Cancel a limit or RFQ order directly by its order hash.
    /// @param orderHash The order's order hash.
    /// @param maker The order's maker.
    function _cancelOrderHash(bytes32 orderHash, address maker) private {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();
        // Set the high bit on the raw taker token fill amount to indicate
        // a cancel. It's OK to cancel twice.
        stor.orderHashToTakerTokenFilledAmount[orderHash] |= HIGH_BIT;

        emit OrderCancelled(orderHash, maker);
    }

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided.
    /// @param maker The target maker address
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function _cancelPairRfqOrders(
        address maker,
        IERC20Token makerToken,
        IERC20Token takerToken,
        uint256 minValidSalt
    ) private {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        uint256 oldMinValidSalt = stor.rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][
            address(makerToken)
        ][address(takerToken)];

        // New min salt must >= the old one.
        if (oldMinValidSalt > minValidSalt) {
            LibNativeOrdersRichErrors.CancelSaltTooLowError(minValidSalt, oldMinValidSalt).rrevert();
        }

        stor.rfqOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][address(makerToken)][
            address(takerToken)
        ] = minValidSalt;

        emit PairCancelledRfqOrders(maker, address(makerToken), address(takerToken), minValidSalt);
    }

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided.
    /// @param maker The target maker address
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function _cancelPairLimitOrders(
        address maker,
        IERC20Token makerToken,
        IERC20Token takerToken,
        uint256 minValidSalt
    ) private {
        LibNativeOrdersStorage.Storage storage stor = LibNativeOrdersStorage.getStorage();

        uint256 oldMinValidSalt = stor.limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][
            address(makerToken)
        ][address(takerToken)];

        // New min salt must >= the old one.
        if (oldMinValidSalt > minValidSalt) {
            LibNativeOrdersRichErrors.CancelSaltTooLowError(minValidSalt, oldMinValidSalt).rrevert();
        }

        stor.limitOrdersMakerToMakerTokenToTakerTokenToMinValidOrderSalt[maker][address(makerToken)][
            address(takerToken)
        ] = minValidSalt;

        emit PairCancelledLimitOrders(maker, address(makerToken), address(takerToken), minValidSalt);
    }
}
