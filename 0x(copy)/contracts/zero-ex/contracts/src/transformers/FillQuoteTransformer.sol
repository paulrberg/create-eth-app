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

import "0x/contracts/utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "0x/contracts/erc20/src/IERC20Token.sol";
import "0x/contracts/erc20/src/v06/LibERC20TokenV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibSafeMathV06.sol";
import "0x/contracts/utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "../features/interfaces/INativeOrdersFeature.sol";
import "../features/libs/LibNativeOrder.sol";
import "./bridges/IBridgeAdapter.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";
import "../IZeroEx.sol";

/// @dev A transformer that fills an ERC20 market sell/buy quote.
///      This transformer shortcuts bridge orders and fills them directly
contract FillQuoteTransformer is Transformer {
    using LibERC20TokenV06 for IERC20Token;
    using LibERC20Transformer for IERC20Token;
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;
    using LibRichErrorsV06 for bytes;

    /// @dev Whether we are performing a market sell or buy.
    enum Side {
        Sell,
        Buy
    }

    enum OrderType {
        Bridge,
        Limit,
        Rfq,
        Otc
    }

    struct LimitOrderInfo {
        LibNativeOrder.LimitOrder order;
        LibSignature.Signature signature;
        // Maximum taker token amount of this limit order to fill.
        uint256 maxTakerTokenFillAmount;
    }

    struct RfqOrderInfo {
        LibNativeOrder.RfqOrder order;
        LibSignature.Signature signature;
        // Maximum taker token amount of this limit order to fill.
        uint256 maxTakerTokenFillAmount;
    }

    struct OtcOrderInfo {
        LibNativeOrder.OtcOrder order;
        LibSignature.Signature signature;
        // Maximum taker token amount of this limit order to fill.
        uint256 maxTakerTokenFillAmount;
    }

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // Whether we are performing a market sell or buy.
        Side side;
        // The token being sold.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20Token sellToken;
        // The token being bought.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20Token buyToken;
        // External liquidity bridge orders. Sorted by fill sequence.
        IBridgeAdapter.BridgeOrder[] bridgeOrders;
        // Native limit orders. Sorted by fill sequence.
        LimitOrderInfo[] limitOrders;
        // Native RFQ orders. Sorted by fill sequence.
        RfqOrderInfo[] rfqOrders;
        // The sequence to fill the orders in. Each item will fill the next
        // order of that type in either `bridgeOrders`, `limitOrders`,
        // or `rfqOrders.`
        OrderType[] fillSequence;
        // Amount of `sellToken` to sell or `buyToken` to buy.
        // For sells, setting the high-bit indicates that
        // `sellAmount & LOW_BITS` should be treated as a `1e18` fraction of
        // the current balance of `sellToken`, where
        // `1e18+ == 100%` and `0.5e18 == 50%`, etc.
        uint256 fillAmount;
        // Who to transfer unused protocol fees to.
        // May be a valid address or one of:
        // `address(0)`: Stay in flash wallet.
        // `address(1)`: Send to the taker.
        // `address(2)`: Send to the sender (caller of `transformERC20()`).
        address payable refundReceiver;
        // Otc orders. Sorted by fill sequence.
        OtcOrderInfo[] otcOrders;
    }

    struct FillOrderResults {
        // The amount of taker tokens sold, according to balance checks.
        uint256 takerTokenSoldAmount;
        // The amount of maker tokens sold, according to balance checks.
        uint256 makerTokenBoughtAmount;
        // The amount of protocol fee paid.
        uint256 protocolFeePaid;
    }

    /// @dev Intermediate state variables to get around stack limits.
    struct FillState {
        uint256 ethRemaining;
        uint256 boughtAmount;
        uint256 soldAmount;
        uint256 protocolFee;
        uint256 takerTokenBalanceRemaining;
        uint256[4] currentIndices;
        OrderType currentOrderType;
    }

    /// @dev Emitted when a trade is skipped due to a lack of funds
    ///      to pay the 0x Protocol fee.
    /// @param orderHash The hash of the order that was skipped.
    event ProtocolFeeUnfunded(bytes32 orderHash);

    /// @dev The highest bit of a uint256 value.
    uint256 private constant HIGH_BIT = 2 ** 255;
    /// @dev Mask of the lower 255 bits of a uint256 value.
    uint256 private constant LOWER_255_BITS = HIGH_BIT - 1;
    /// @dev If `refundReceiver` is set to this address, unpsent
    ///      protocol fees will be sent to the transform recipient.
    address private constant REFUND_RECEIVER_RECIPIENT = address(1);
    /// @dev If `refundReceiver` is set to this address, unpsent
    ///      protocol fees will be sent to the sender.
    address private constant REFUND_RECEIVER_SENDER = address(2);

    /// @dev The BridgeAdapter address
    IBridgeAdapter public immutable bridgeAdapter;

    /// @dev The exchange proxy contract.
    IZeroEx public immutable zeroEx;

    /// @dev Create this contract.
    /// @param bridgeAdapter_ The bridge adapter contract.
    /// @param zeroEx_ The Exchange Proxy contract.
    constructor(IBridgeAdapter bridgeAdapter_, IZeroEx zeroEx_) public Transformer() {
        bridgeAdapter = bridgeAdapter_;
        zeroEx = zeroEx_;
    }

    /// @dev Sell this contract's entire balance of of `sellToken` in exchange
    ///      for `buyToken` by filling `orders`. Protocol fees should be attached
    ///      to this call. `buyToken` and excess ETH will be transferred back to the caller.
    /// @param context Context information.
    /// @return magicBytes The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    /* solhint-disable function-max-lines */
    function transform(TransformContext calldata context) external override returns (bytes4 magicBytes) {
        TransformData memory data = abi.decode(context.data, (TransformData));
        FillState memory state;

        // Validate data fields.
        if (data.sellToken.isTokenETH() || data.buyToken.isTokenETH()) {
            LibTransformERC20RichErrors
                .InvalidTransformDataError(
                    LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_TOKENS,
                    context.data
                )
                .rrevert();
        }

        if (
            data.bridgeOrders.length + data.limitOrders.length + data.rfqOrders.length + data.otcOrders.length !=
            data.fillSequence.length
        ) {
            LibTransformERC20RichErrors
                .InvalidTransformDataError(
                    LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_ARRAY_LENGTH,
                    context.data
                )
                .rrevert();
        }

        state.takerTokenBalanceRemaining = data.sellToken.getTokenBalanceOf(address(this));
        if (data.side == Side.Sell) {
            data.fillAmount = _normalizeFillAmount(data.fillAmount, state.takerTokenBalanceRemaining);
        }

        // Approve the exchange proxy to spend our sell tokens if native orders
        // are present.
        if (data.limitOrders.length + data.rfqOrders.length + data.otcOrders.length != 0) {
            data.sellToken.approveIfBelow(address(zeroEx), data.fillAmount);
            // Compute the protocol fee if a limit order is present.
            if (data.limitOrders.length != 0) {
                state.protocolFee = uint256(zeroEx.getProtocolFeeMultiplier()).safeMul(tx.gasprice);
            }
        }

        state.ethRemaining = address(this).balance;

        // Fill the orders.
        for (uint256 i = 0; i < data.fillSequence.length; ++i) {
            // Check if we've hit our targets.
            if (data.side == Side.Sell) {
                // Market sell check.
                if (state.soldAmount >= data.fillAmount) {
                    break;
                }
            } else {
                // Market buy check.
                if (state.boughtAmount >= data.fillAmount) {
                    break;
                }
            }

            state.currentOrderType = OrderType(data.fillSequence[i]);
            uint256 orderIndex = state.currentIndices[uint256(state.currentOrderType)];
            // Fill the order.
            FillOrderResults memory results;
            if (state.currentOrderType == OrderType.Bridge) {
                results = _fillBridgeOrder(data.bridgeOrders[orderIndex], data, state);
            } else if (state.currentOrderType == OrderType.Limit) {
                results = _fillLimitOrder(data.limitOrders[orderIndex], data, state);
            } else if (state.currentOrderType == OrderType.Rfq) {
                results = _fillRfqOrder(data.rfqOrders[orderIndex], data, state);
            } else if (state.currentOrderType == OrderType.Otc) {
                results = _fillOtcOrder(data.otcOrders[orderIndex], data, state);
            } else {
                revert("INVALID_ORDER_TYPE");
            }

            // Accumulate totals.
            state.soldAmount = state.soldAmount.safeAdd(results.takerTokenSoldAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(results.makerTokenBoughtAmount);
            state.ethRemaining = state.ethRemaining.safeSub(results.protocolFeePaid);
            state.takerTokenBalanceRemaining = state.takerTokenBalanceRemaining.safeSub(results.takerTokenSoldAmount);
            state.currentIndices[uint256(state.currentOrderType)]++;
        }

        // Ensure we hit our targets.
        if (data.side == Side.Sell) {
            // Market sell check.
            if (state.soldAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillSellQuoteError(address(data.sellToken), state.soldAmount, data.fillAmount)
                    .rrevert();
            }
        } else {
            // Market buy check.
            if (state.boughtAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillBuyQuoteError(address(data.buyToken), state.boughtAmount, data.fillAmount)
                    .rrevert();
            }
        }

        // Refund unspent protocol fees.
        if (state.ethRemaining > 0 && data.refundReceiver != address(0)) {
            bool transferSuccess;
            if (data.refundReceiver == REFUND_RECEIVER_RECIPIENT) {
                (transferSuccess, ) = context.recipient.call{value: state.ethRemaining}("");
            } else if (data.refundReceiver == REFUND_RECEIVER_SENDER) {
                (transferSuccess, ) = context.sender.call{value: state.ethRemaining}("");
            } else {
                (transferSuccess, ) = data.refundReceiver.call{value: state.ethRemaining}("");
            }
            require(transferSuccess, "FillQuoteTransformer/ETHER_TRANSFER_FALIED");
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }

    /* solhint-enable function-max-lines */

    // Fill a single bridge order.
    function _fillBridgeOrder(
        IBridgeAdapter.BridgeOrder memory order,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = _computeTakerTokenFillAmount(
            data,
            state,
            order.takerTokenAmount,
            order.makerTokenAmount,
            0
        );

        (bool success, bytes memory resultData) = address(bridgeAdapter).delegatecall(
            abi.encodeWithSelector(
                IBridgeAdapter.trade.selector,
                order,
                data.sellToken,
                data.buyToken,
                takerTokenFillAmount
            )
        );
        if (success) {
            results.makerTokenBoughtAmount = abi.decode(resultData, (uint256));
            results.takerTokenSoldAmount = takerTokenFillAmount;
        }
    }

    // Fill a single limit order.
    function _fillLimitOrder(
        LimitOrderInfo memory orderInfo,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = LibSafeMathV06.min256(
            _computeTakerTokenFillAmount(
                data,
                state,
                orderInfo.order.takerAmount,
                orderInfo.order.makerAmount,
                orderInfo.order.takerTokenFeeAmount
            ),
            orderInfo.maxTakerTokenFillAmount
        );

        // Emit an event if we do not have sufficient ETH to cover the protocol fee.
        if (state.ethRemaining < state.protocolFee) {
            bytes32 orderHash = zeroEx.getLimitOrderHash(orderInfo.order);
            emit ProtocolFeeUnfunded(orderHash);
            return results; // Empty results.
        }

        try
            zeroEx.fillLimitOrder{value: state.protocolFee}(
                orderInfo.order,
                orderInfo.signature,
                takerTokenFillAmount.safeDowncastToUint128()
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            if (orderInfo.order.takerTokenFeeAmount > 0) {
                takerTokenFilledAmount = takerTokenFilledAmount.safeAdd128(
                    LibMathV06
                        .getPartialAmountFloor(
                            takerTokenFilledAmount,
                            orderInfo.order.takerAmount,
                            orderInfo.order.takerTokenFeeAmount
                        )
                        .safeDowncastToUint128()
                );
            }
            results.takerTokenSoldAmount = takerTokenFilledAmount;
            results.makerTokenBoughtAmount = makerTokenFilledAmount;
            results.protocolFeePaid = state.protocolFee;
        } catch {}
    }

    // Fill a single RFQ order.
    function _fillRfqOrder(
        RfqOrderInfo memory orderInfo,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = LibSafeMathV06.min256(
            _computeTakerTokenFillAmount(data, state, orderInfo.order.takerAmount, orderInfo.order.makerAmount, 0),
            orderInfo.maxTakerTokenFillAmount
        );

        try
            zeroEx.fillRfqOrder(orderInfo.order, orderInfo.signature, takerTokenFillAmount.safeDowncastToUint128())
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            results.takerTokenSoldAmount = takerTokenFilledAmount;
            results.makerTokenBoughtAmount = makerTokenFilledAmount;
        } catch {}
    }

    // Fill a single OTC order.
    function _fillOtcOrder(
        OtcOrderInfo memory orderInfo,
        TransformData memory data,
        FillState memory state
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = LibSafeMathV06.min256(
            _computeTakerTokenFillAmount(data, state, orderInfo.order.takerAmount, orderInfo.order.makerAmount, 0),
            orderInfo.maxTakerTokenFillAmount
        );
        try
            zeroEx.fillOtcOrder(orderInfo.order, orderInfo.signature, takerTokenFillAmount.safeDowncastToUint128())
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            results.takerTokenSoldAmount = takerTokenFilledAmount;
            results.makerTokenBoughtAmount = makerTokenFilledAmount;
        } catch {
            revert("FillQuoteTransformer/OTC_ORDER_FILL_FAILED");
        }
    }

    // Compute the next taker token fill amount of a generic order.
    function _computeTakerTokenFillAmount(
        TransformData memory data,
        FillState memory state,
        uint256 orderTakerAmount,
        uint256 orderMakerAmount,
        uint256 orderTakerTokenFeeAmount
    ) private pure returns (uint256 takerTokenFillAmount) {
        if (data.side == Side.Sell) {
            takerTokenFillAmount = data.fillAmount.safeSub(state.soldAmount);
            if (orderTakerTokenFeeAmount != 0) {
                takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                    takerTokenFillAmount,
                    orderTakerAmount.safeAdd(orderTakerTokenFeeAmount),
                    orderTakerAmount
                );
            }
        } else {
            // Buy
            takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                data.fillAmount.safeSub(state.boughtAmount),
                orderMakerAmount,
                orderTakerAmount
            );
        }
        return
            LibSafeMathV06.min256(
                LibSafeMathV06.min256(takerTokenFillAmount, orderTakerAmount),
                state.takerTokenBalanceRemaining
            );
    }

    // Convert possible proportional values to absolute quantities.
    function _normalizeFillAmount(uint256 rawAmount, uint256 balance) private pure returns (uint256 normalized) {
        if ((rawAmount & HIGH_BIT) == HIGH_BIT) {
            // If the high bit of `rawAmount` is set then the lower 255 bits
            // specify a fraction of `balance`.
            return
                LibSafeMathV06.min256(
                    (balance * LibSafeMathV06.min256(rawAmount & LOWER_255_BITS, 1e18)) / 1e18,
                    balance
                );
        }
        return rawAmount;
    }
}
