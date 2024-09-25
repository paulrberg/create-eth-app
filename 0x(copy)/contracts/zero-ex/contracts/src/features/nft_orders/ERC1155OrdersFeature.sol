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

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "0x/contracts/erc20/src/IEtherToken.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinERC1155Spender.sol";
import "../../migrations/LibMigrate.sol";
import "../../storage/LibERC1155OrdersStorage.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IERC1155OrdersFeature.sol";
import "../libs/LibNFTOrder.sol";
import "../libs/LibSignature.sol";
import "./NFTOrders.sol";

/// @dev Feature for interacting with ERC1155 orders.
contract ERC1155OrdersFeature is IFeature, IERC1155OrdersFeature, FixinERC1155Spender, NFTOrders {
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;
    using LibNFTOrder for LibNFTOrder.ERC1155Order;
    using LibNFTOrder for LibNFTOrder.NFTOrder;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "ERC1155Orders";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev The magic return value indicating the success of a `onERC1155Received`.
    bytes4 private constant ERC1155_RECEIVED_MAGIC_BYTES = this.onERC1155Received.selector;

    constructor(address zeroExAddress, IEtherToken weth) public NFTOrders(zeroExAddress, weth) {}

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellERC1155.selector);
        _registerFeatureFunction(this.buyERC1155.selector);
        _registerFeatureFunction(this.cancelERC1155Order.selector);
        _registerFeatureFunction(this.batchBuyERC1155s.selector);
        _registerFeatureFunction(this.onERC1155Received.selector);
        _registerFeatureFunction(this.preSignERC1155Order.selector);
        _registerFeatureFunction(this.validateERC1155OrderSignature.selector);
        _registerFeatureFunction(this.validateERC1155OrderProperties.selector);
        _registerFeatureFunction(this.getERC1155OrderInfo.selector);
        _registerFeatureFunction(this.getERC1155OrderHash.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells an ERC1155 asset to fill the given order.
    /// @param buyOrder The ERC1155 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc1155TokenId The ID of the ERC1155 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param erc1155SellAmount The amount of the ERC1155 asset
    ///        to sell.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC1155 asset to the buyer.
    function sellERC1155(
        LibNFTOrder.ERC1155Order memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes memory callbackData
    ) public override {
        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                erc1155SellAmount,
                erc1155TokenId,
                unwrapNativeToken,
                msg.sender, // taker
                msg.sender, // owner
                callbackData
            )
        );
    }

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buyERC1155(
        LibNFTOrder.ERC1155Order memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 erc1155BuyAmount,
        bytes memory callbackData
    ) public payable override {
        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        _buyERC1155(sellOrder, signature, BuyParams(erc1155BuyAmount, msg.value, callbackData));
        uint256 ethBalanceAfter = address(this).balance;
        // Cannot use pre-existing ETH balance
        if (ethBalanceAfter < ethBalanceBefore) {
            LibNFTOrdersRichErrors
                .OverspentEthError(ethBalanceBefore - ethBalanceAfter + msg.value, msg.value)
                .rrevert();
        }
        // Refund
        _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
    }

    /// @dev Cancel a single ERC1155 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC1155Order(uint256 orderNonce) public override {
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (orderNonce & 255);
        // Update order cancellation bit vector to indicate that the order
        // has been cancelled/filled by setting the designated bit to 1.
        LibERC1155OrdersStorage.getStorage().orderCancellationByMaker[msg.sender][uint248(orderNonce >> 8)] |= flag;

        emit ERC1155OrderCancelled(msg.sender, orderNonce);
    }

    /// @dev Cancel multiple ERC1155 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC1155Orders(uint256[] calldata orderNonces) external override {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            cancelERC1155Order(orderNonces[i]);
        }
    }

    /// @dev Buys multiple ERC1155 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC1155 sell orders.
    /// @param signatures The order signatures.
    /// @param erc1155FillAmounts The amounts of the ERC1155 assets
    ///        to buy for each order.
    /// @param callbackData The data (if any) to pass to the taker
    ///        callback for each order. Refer to the `callbackData`
    ///        parameter to for `buyERC1155`.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC1155s(
        LibNFTOrder.ERC1155Order[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    ) public payable override returns (bool[] memory successes) {
        require(
            sellOrders.length == signatures.length &&
                sellOrders.length == erc1155FillAmounts.length &&
                sellOrders.length == callbackData.length,
            "ERC1155OrdersFeature::batchBuyERC1155s/ARRAY_LENGTH_MISMATCH"
        );
        successes = new bool[](sellOrders.length);

        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        if (revertIfIncomplete) {
            for (uint256 i = 0; i < sellOrders.length; i++) {
                // Will revert if _buyERC1155 reverts.
                _buyERC1155(
                    sellOrders[i],
                    signatures[i],
                    BuyParams(
                        erc1155FillAmounts[i],
                        address(this).balance.safeSub(ethBalanceBefore), // Remaining ETH available
                        callbackData[i]
                    )
                );
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < sellOrders.length; i++) {
                // Delegatecall `_buyERC1155` to catch swallow reverts while
                // preserving execution context.
                // Note that `_buyERC1155` is a public function but should _not_
                // be registered in the Exchange Proxy.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this._buyERC1155.selector,
                        sellOrders[i],
                        signatures[i],
                        BuyParams(
                            erc1155FillAmounts[i],
                            address(this).balance.safeSub(ethBalanceBefore), // Remaining ETH available
                            callbackData[i]
                        )
                    )
                );
            }
        }

        // Cannot use pre-existing ETH balance
        uint256 ethBalanceAfter = address(this).balance;
        if (ethBalanceAfter < ethBalanceBefore) {
            LibNFTOrdersRichErrors
                .OverspentEthError(msg.value + (ethBalanceBefore - ethBalanceAfter), msg.value)
                .rrevert();
        }

        // Refund
        _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
    }

    /// @dev Callback for the ERC1155 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC1155 asset if
    ///      a valid ERC1155 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC1155 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param tokenId The ID of the asset being transferred.
    /// @param value The amount being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC1155 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0xf23a6e61),
    ///         indicating that the callback succeeded.
    function onERC1155Received(
        address operator,
        address /* from */,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4 success) {
        // Decode the order, signature, and `unwrapNativeToken` from
        // `data`. If `data` does not encode such parameters, this
        // will throw.
        (
            LibNFTOrder.ERC1155Order memory buyOrder,
            LibSignature.Signature memory signature,
            bool unwrapNativeToken
        ) = abi.decode(data, (LibNFTOrder.ERC1155Order, LibSignature.Signature, bool));

        // `onERC1155Received` is called by the ERC1155 token contract.
        // Check that it matches the ERC1155 token in the order.
        if (msg.sender != address(buyOrder.erc1155Token)) {
            LibNFTOrdersRichErrors.ERC1155TokenMismatchError(msg.sender, address(buyOrder.erc1155Token)).rrevert();
        }

        _sellERC1155(
            buyOrder,
            signature,
            SellParams(
                value.safeDowncastToUint128(),
                tokenId,
                unwrapNativeToken,
                operator, // taker
                address(this), // owner (we hold the NFT currently)
                new bytes(0) // No taker callback
            )
        );

        return ERC1155_RECEIVED_MAGIC_BYTES;
    }

    /// @dev Approves an ERC1155 order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC1155 order.
    function preSignERC1155Order(LibNFTOrder.ERC1155Order memory order) public override {
        require(order.maker == msg.sender, "ERC1155OrdersFeature::preSignERC1155Order/MAKER_MISMATCH");
        bytes32 orderHash = getERC1155OrderHash(order);

        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        // Set `preSigned` to true on the order state variable
        // to indicate that the order has been pre-signed.
        stor.orderState[orderHash].preSigned = true;

        emit ERC1155OrderPreSigned(
            order.direction,
            order.maker,
            order.taker,
            order.expiry,
            order.nonce,
            order.erc20Token,
            order.erc20TokenAmount,
            order.fees,
            order.erc1155Token,
            order.erc1155TokenId,
            order.erc1155TokenProperties,
            order.erc1155TokenAmount
        );
    }

    // Core settlement logic for selling an ERC1155 asset.
    // Used by `sellERC1155` and `onERC1155Received`.
    function _sellERC1155(
        LibNFTOrder.ERC1155Order memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) private {
        uint256 erc20FillAmount = _sellNFT(buyOrder.asNFTOrder(), signature, params);

        emit ERC1155OrderFilled(
            buyOrder.direction,
            buyOrder.maker,
            params.taker,
            buyOrder.nonce,
            buyOrder.erc20Token,
            erc20FillAmount,
            buyOrder.erc1155Token,
            params.tokenId,
            params.sellAmount,
            address(0)
        );
    }

    // Core settlement logic for buying an ERC1155 asset.
    // Used by `buyERC1155` and `batchBuyERC1155s`.
    function _buyERC1155(
        LibNFTOrder.ERC1155Order memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) public payable {
        uint256 erc20FillAmount = _buyNFT(sellOrder.asNFTOrder(), signature, params);

        emit ERC1155OrderFilled(
            sellOrder.direction,
            sellOrder.maker,
            msg.sender,
            sellOrder.nonce,
            sellOrder.erc20Token,
            erc20FillAmount,
            sellOrder.erc1155Token,
            sellOrder.erc1155TokenId,
            params.buyAmount,
            address(0)
        );
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC1155 order. Reverts if not.
    /// @param order The ERC1155 order.
    /// @param signature The signature to validate.
    function validateERC1155OrderSignature(
        LibNFTOrder.ERC1155Order memory order,
        LibSignature.Signature memory signature
    ) public view override {
        bytes32 orderHash = getERC1155OrderHash(order);
        _validateOrderSignature(orderHash, signature, order.maker);
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(
        bytes32 orderHash,
        LibSignature.Signature memory signature,
        address maker
    ) internal view override {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            // Check if order hash has been pre-signed by the maker.
            bool isPreSigned = LibERC1155OrdersStorage.getStorage().orderState[orderHash].preSigned;
            if (!isPreSigned) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, address(0)).rrevert();
            }
        } else {
            address signer = LibSignature.getSignerOfHash(orderHash, signature);
            if (signer != maker) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, signer).rrevert();
            }
        }
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer. Always
    ///        1 for ERC721 assets.
    function _transferNFTAssetFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal override {
        _transferERC1155AssetFrom(IERC1155Token(token), from, to, tokenId, amount);
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(
        LibNFTOrder.NFTOrder memory /* order */,
        bytes32 orderHash,
        uint128 fillAmount
    ) internal override {
        LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();
        uint128 filledAmount = stor.orderState[orderHash].filledAmount;
        // Filled amount should never overflow 128 bits
        assert(filledAmount + fillAmount > filledAmount);
        stor.orderState[orderHash].filledAmount = filledAmount + fillAmount;
    }

    /// @dev If the given order is buying an ERC1155 asset, checks
    ///      whether or not the given token ID satisfies the required
    ///      properties specified in the order. If the order does not
    ///      specify any properties, this function instead checks
    ///      whether the given token ID matches the ID in the order.
    ///      Reverts if any checks fail, or if the order is selling
    ///      an ERC1155 asset.
    /// @param order The ERC1155 order.
    /// @param erc1155TokenId The ID of the ERC1155 asset.
    function validateERC1155OrderProperties(
        LibNFTOrder.ERC1155Order memory order,
        uint256 erc1155TokenId
    ) public view override {
        _validateOrderProperties(order.asNFTOrder(), erc1155TokenId);
    }

    /// @dev Get the order info for an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return orderInfo Info about the order.
    function getERC1155OrderInfo(
        LibNFTOrder.ERC1155Order memory order
    ) public view override returns (LibNFTOrder.OrderInfo memory orderInfo) {
        orderInfo.orderAmount = order.erc1155TokenAmount;
        orderInfo.orderHash = getERC1155OrderHash(order);

        // Only buy orders with `erc1155TokenId` == 0 can be property
        // orders.
        if (
            order.erc1155TokenProperties.length > 0 &&
            (order.direction != LibNFTOrder.TradeDirection.BUY_NFT || order.erc1155TokenId != 0)
        ) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (
            order.direction == LibNFTOrder.TradeDirection.BUY_NFT && address(order.erc20Token) == NATIVE_TOKEN_ADDRESS
        ) {
            orderInfo.status = LibNFTOrder.OrderStatus.INVALID;
            return orderInfo;
        }

        // Check for expiry.
        if (order.expiry <= block.timestamp) {
            orderInfo.status = LibNFTOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        {
            LibERC1155OrdersStorage.Storage storage stor = LibERC1155OrdersStorage.getStorage();

            LibERC1155OrdersStorage.OrderState storage orderState = stor.orderState[orderInfo.orderHash];
            orderInfo.remainingAmount = order.erc1155TokenAmount.safeSub128(orderState.filledAmount);

            // `orderCancellationByMaker` is indexed by maker and nonce.
            uint256 orderCancellationBitVector = stor.orderCancellationByMaker[order.maker][uint248(order.nonce >> 8)];
            // The bitvector is indexed by the lower 8 bits of the nonce.
            uint256 flag = 1 << (order.nonce & 255);

            if (orderInfo.remainingAmount == 0 || orderCancellationBitVector & flag != 0) {
                orderInfo.status = LibNFTOrder.OrderStatus.UNFILLABLE;
                return orderInfo;
            }
        }

        // Otherwise, the order is fillable.
        orderInfo.status = LibNFTOrder.OrderStatus.FILLABLE;
    }

    /// @dev Get the order info for an NFT order.
    /// @param order The NFT order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(
        LibNFTOrder.NFTOrder memory order
    ) internal view override returns (LibNFTOrder.OrderInfo memory orderInfo) {
        return getERC1155OrderInfo(order.asERC1155Order());
    }

    /// @dev Get the EIP-712 hash of an ERC1155 order.
    /// @param order The ERC1155 order.
    /// @return orderHash The order hash.
    function getERC1155OrderHash(
        LibNFTOrder.ERC1155Order memory order
    ) public view override returns (bytes32 orderHash) {
        return _getEIP712Hash(LibNFTOrder.getERC1155OrderStructHash(order));
    }
}
