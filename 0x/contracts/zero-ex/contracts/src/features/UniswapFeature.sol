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
import "0x/contracts/erc20/src/IEtherToken.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IUniswapFeature.sol";

/// @dev VIP uniswap fill functions.
contract UniswapFeature is IFeature, IUniswapFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "UniswapFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 2);
    /// @dev WETH contract.
    IEtherToken private immutable WETH;

    // 0xFF + address of the UniswapV2Factory contract.
    uint256 private constant FF_UNISWAP_FACTORY = 0xFF5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f0000000000000000000000;
    // 0xFF + address of the (Sushiswap) UniswapV2Factory contract.
    uint256 private constant FF_SUSHISWAP_FACTORY = 0xFFC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac0000000000000000000000;
    // Init code hash of the UniswapV2Pair contract.
    uint256 private constant UNISWAP_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    // Init code hash of the (Sushiswap) UniswapV2Pair contract.
    uint256 private constant SUSHISWAP_PAIR_INIT_CODE_HASH =
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    // ETH pseudo-token address.
    uint256 private constant ETH_TOKEN_ADDRESS_32 = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    // Maximum token quantity that can be swapped against the UniswapV2Pair contract.
    uint256 private constant MAX_SWAP_AMOUNT = 2 ** 112;

    // bytes4(keccak256("executeCall(address,bytes)"))
    uint256 private constant ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32 =
        0xbca8c7b500000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("getReserves()"))
    uint256 private constant UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
        0x0902f1ac00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address,bytes)"))
    uint256 private constant UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x022c0d9f00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transferFrom(address,address,uint256)"))
    uint256 private constant TRANSFER_FROM_CALL_SELECTOR_32 =
        0x23b872dd00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("allowance(address,address)"))
    uint256 private constant ALLOWANCE_CALL_SELECTOR_32 =
        0xdd62ed3e00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("withdraw(uint256)"))
    uint256 private constant WETH_WITHDRAW_CALL_SELECTOR_32 =
        0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("deposit()"))
    uint256 private constant WETH_DEPOSIT_CALL_SELECTOR_32 =
        0xd0e30db000000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("transfer(address,uint256)"))
    uint256 private constant ERC20_TRANSFER_CALL_SELECTOR_32 =
        0xa9059cbb00000000000000000000000000000000000000000000000000000000;

    /// @dev Construct this contract.
    /// @param weth The WETH contract.
    constructor(IEtherToken weth) public {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToUniswap.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Efficiently sell directly to uniswap/sushiswap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param isSushi Use sushiswap if true.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToUniswap(
        IERC20Token[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    ) external payable override returns (uint256 buyAmount) {
        require(tokens.length > 1, "UniswapFeature/InvalidTokensLength");
        {
            // Load immutables onto the stack.
            IEtherToken weth = WETH;

            // Store some vars in memory to get around stack limits.
            assembly {
                // calldataload(mload(0xA00)) == first element of `tokens` array
                mstore(0xA00, add(calldataload(0x04), 0x24))
                // mload(0xA20) == isSushi
                mstore(0xA20, isSushi)
                // mload(0xA40) == WETH
                mstore(0xA40, weth)
            }
        }

        assembly {
            // numPairs == tokens.length - 1
            let numPairs := sub(calldataload(add(calldataload(0x04), 0x4)), 1)
            // We use the previous buy amount as the sell amount for the next
            // pair in a path. So for the first swap we want to set it to `sellAmount`.
            buyAmount := sellAmount
            let buyToken
            let nextPair := 0

            for {
                let i := 0
            } lt(i, numPairs) {
                i := add(i, 1)
            } {
                // sellToken = tokens[i]
                let sellToken := loadTokenAddress(i)
                // buyToken = tokens[i+1]
                buyToken := loadTokenAddress(add(i, 1))
                // The canonical ordering of this token pair.
                let pairOrder := lt(normalizeToken(sellToken), normalizeToken(buyToken))

                // Compute the pair address if it hasn't already been computed
                // from the last iteration.
                let pair := nextPair
                if iszero(pair) {
                    pair := computePairAddress(sellToken, buyToken)
                    nextPair := 0
                }

                if iszero(i) {
                    // This is the first token in the path.
                    switch eq(sellToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        // Not selling ETH. Selling an ERC20 instead.
                        // Make sure ETH was not attached to the call.
                        if gt(callvalue(), 0) {
                            revert(0, 0)
                        }
                        // For the first pair we need to transfer sellTokens into the
                        // pair contract.
                        moveTakerTokensTo(sellToken, pair, sellAmount)
                    }
                    default {
                        // If selling ETH, we need to wrap it to WETH and transfer to the
                        // pair contract.
                        if iszero(eq(callvalue(), sellAmount)) {
                            revert(0, 0)
                        }
                        sellToken := mload(0xA40) // Re-assign to WETH
                        // Call `WETH.deposit{value: sellAmount}()`
                        mstore(0xB00, WETH_DEPOSIT_CALL_SELECTOR_32)
                        if iszero(call(gas(), sellToken, sellAmount, 0xB00, 0x4, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                        // Call `WETH.transfer(pair, sellAmount)`
                        mstore(0xB00, ERC20_TRANSFER_CALL_SELECTOR_32)
                        mstore(0xB04, pair)
                        mstore(0xB24, sellAmount)
                        if iszero(call(gas(), sellToken, 0, 0xB00, 0x44, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                    }
                    // No need to check results, if deposit/transfers failed the UniswapV2Pair will
                    // reject our trade (or it may succeed if somehow the reserve was out of sync)
                    // this is fine for the taker.
                }

                // Call pair.getReserves(), store the results at `0xC00`
                mstore(0xB00, UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                    bubbleRevert()
                }
                // Revert if the pair contract does not return at least two words.
                if lt(returndatasize(), 0x40) {
                    revert(0, 0)
                }

                // Sell amount for this hop is the previous buy amount.
                let pairSellAmount := buyAmount
                // Compute the buy amount based on the pair reserves.
                {
                    let sellReserve
                    let buyReserve
                    switch iszero(pairOrder)
                    case 0 {
                        // Transpose if pair order is different.
                        sellReserve := mload(0xC00)
                        buyReserve := mload(0xC20)
                    }
                    default {
                        sellReserve := mload(0xC20)
                        buyReserve := mload(0xC00)
                    }
                    // Ensure that the sellAmount is < 2¹¹².
                    if gt(pairSellAmount, MAX_SWAP_AMOUNT) {
                        revert(0, 0)
                    }
                    // Pairs are in the range (0, 2¹¹²) so this shouldn't overflow.
                    // buyAmount = (pairSellAmount * 997 * buyReserve) /
                    //     (pairSellAmount * 997 + sellReserve * 1000);
                    let sellAmountWithFee := mul(pairSellAmount, 997)
                    buyAmount := div(mul(sellAmountWithFee, buyReserve), add(sellAmountWithFee, mul(sellReserve, 1000)))
                }

                let receiver
                // Is this the last pair contract?
                switch eq(add(i, 1), numPairs)
                case 0 {
                    // Not the last pair contract, so forward bought tokens to
                    // the next pair contract.
                    nextPair := computePairAddress(buyToken, loadTokenAddress(add(i, 2)))
                    receiver := nextPair
                }
                default {
                    // The last pair contract.
                    // Forward directly to taker UNLESS they want ETH back.
                    switch eq(buyToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        receiver := caller()
                    }
                    default {
                        receiver := address()
                    }
                }

                // Call pair.swap()
                mstore(0xB00, UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
                switch pairOrder
                case 0 {
                    mstore(0xB04, buyAmount)
                    mstore(0xB24, 0)
                }
                default {
                    mstore(0xB04, 0)
                    mstore(0xB24, buyAmount)
                }
                mstore(0xB44, receiver)
                mstore(0xB64, 0x80)
                mstore(0xB84, 0)
                if iszero(call(gas(), pair, 0, 0xB00, 0xA4, 0, 0)) {
                    bubbleRevert()
                }
            } // End for-loop.

            // If buying ETH, unwrap the WETH first
            if eq(buyToken, ETH_TOKEN_ADDRESS_32) {
                // Call `WETH.withdraw(buyAmount)`
                mstore(0xB00, WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(0xB04, buyAmount)
                if iszero(call(gas(), mload(0xA40), 0, 0xB00, 0x24, 0x00, 0x0)) {
                    bubbleRevert()
                }
                // Transfer ETH to the caller.
                if iszero(call(gas(), caller(), buyAmount, 0xB00, 0x0, 0x00, 0x0)) {
                    bubbleRevert()
                }
            }

            // Functions ///////////////////////////////////////////////////////

            // Load a token address from the `tokens` calldata argument.
            function loadTokenAddress(idx) -> addr {
                addr := and(ADDRESS_MASK, calldataload(add(mload(0xA00), mul(idx, 0x20))))
            }

            // Convert ETH pseudo-token addresses to WETH.
            function normalizeToken(token) -> normalized {
                normalized := token
                // Translate ETH pseudo-tokens to WETH.
                if eq(token, ETH_TOKEN_ADDRESS_32) {
                    normalized := mload(0xA40)
                }
            }

            // Compute the address of the UniswapV2Pair contract given two
            // tokens.
            function computePairAddress(tokenA, tokenB) -> pair {
                // Convert ETH pseudo-token addresses to WETH.
                tokenA := normalizeToken(tokenA)
                tokenB := normalizeToken(tokenB)
                // There is one contract for every combination of tokens,
                // which is deployed using CREATE2.
                // The derivation of this address is given by:
                //   address(keccak256(abi.encodePacked(
                //       bytes(0xFF),
                //       address(UNISWAP_FACTORY_ADDRESS),
                //       keccak256(abi.encodePacked(
                //           tokenA < tokenB ? tokenA : tokenB,
                //           tokenA < tokenB ? tokenB : tokenA,
                //       )),
                //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
                //   )));

                // Compute the salt (the hash of the sorted tokens).
                // Tokens are written in reverse memory order to packed encode
                // them as two 20-byte values in a 40-byte chunk of memory
                // starting at 0xB0C.
                switch lt(tokenA, tokenB)
                case 0 {
                    mstore(0xB14, tokenA)
                    mstore(0xB00, tokenB)
                }
                default {
                    mstore(0xB14, tokenB)
                    mstore(0xB00, tokenA)
                }
                let salt := keccak256(0xB0C, 0x28)
                // Compute the pair address by hashing all the components together.
                switch mload(0xA20) // isSushi
                case 0 {
                    mstore(0xB00, FF_UNISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, UNISWAP_PAIR_INIT_CODE_HASH)
                }
                default {
                    mstore(0xB00, FF_SUSHISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, SUSHISWAP_PAIR_INIT_CODE_HASH)
                }
                pair := and(ADDRESS_MASK, keccak256(0xB00, 0x55))
            }

            // Revert with the return data from the most recent call.
            function bubbleRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Move `amount` tokens from the taker/caller to `to`.
            function moveTakerTokensTo(token, to, amount) {
                // Perform a `transferFrom()`
                mstore(0xB00, TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(0xB04, caller())
                mstore(0xB24, to)
                mstore(0xB44, amount)

                let success := call(
                    gas(),
                    token,
                    0,
                    0xB00,
                    0x64,
                    0xC00,
                    // Copy only the first 32 bytes of return data. We
                    // only care about reading a boolean in the success
                    // case. We will use returndatacopy() in the failure case.
                    0x20
                )

                let rdsize := returndatasize()

                // Check for ERC20 success. ERC20 tokens should
                // return a boolean, but some return nothing or
                // extra data. We accept 0-length return data as
                // success, or at least 32 bytes that starts with
                // a 32-byte boolean true.
                success := and(
                    success, // call itself succeeded
                    or(
                        iszero(rdsize), // no return data, or
                        and(
                            iszero(lt(rdsize, 32)), // at least 32 bytes
                            eq(mload(0xC00), 1) // starts with uint256(1)
                        )
                    )
                )

                if iszero(success) {
                    // Revert with the data returned from the transferFrom call.
                    returndatacopy(0, 0, rdsize)
                    revert(0, rdsize)
                }
            }
        }

        // Revert if we bought too little.
        // TODO: replace with rich revert?
        require(buyAmount >= minBuyAmount, "UniswapFeature/UnderBought");
    }
}
