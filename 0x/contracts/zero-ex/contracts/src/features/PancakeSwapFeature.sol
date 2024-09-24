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
import "./interfaces/IPancakeSwapFeature.sol";

/// @dev VIP pancake fill functions.
contract PancakeSwapFeature is IFeature, IPancakeSwapFeature, FixinCommon {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "PancakeSwapFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 2);
    /// @dev WBNB contract.
    IEtherToken private immutable WBNB;

    // 0xFF + address of the PancakeSwap factory contract.
    uint256 private constant FF_PANCAKESWAP_FACTORY =
        0xffbcfccbde45ce874adcb698cc183debcf179528120000000000000000000000;
    // 0xFF + address of the PancakeSwapV2 factory contract.
    uint256 private constant FF_PANCAKESWAPV2_FACTORY =
        0xffca143ce32fe78f1f7019d7d551a6402fc5350c730000000000000000000000;
    // 0xFF + address of the BakerySwap factory contract.
    uint256 private constant FF_BAKERYSWAP_FACTORY = 0xff01bf7c66c6bd861915cdaae475042d3c4bae16a70000000000000000000000;
    // 0xFF + address of the SushiSwap factory contract.
    uint256 private constant FF_SUSHISWAP_FACTORY = 0xffc35DADB65012eC5796536bD9864eD8773aBc74C40000000000000000000000;
    // 0xFF + address of the ApeSwap factory contract.
    uint256 private constant FF_APESWAP_FACTORY = 0xff0841bd0b734e4f5853f0dd8d7ea041c241fb0da60000000000000000000000;
    // 0xFF + address of the CafeSwap factory contract.
    uint256 private constant FF_CAFESWAP_FACTORY = 0xff3e708fdbe3ada63fc94f8f61811196f1302137ad0000000000000000000000;
    // 0xFF + address of the CheeseSwap factory contract.
    uint256 private constant FF_CHEESESWAP_FACTORY = 0xffdd538e4fd1b69b7863e1f741213276a6cf1efb3b0000000000000000000000;
    // 0xFF + address of the JulSwap factory contract.
    uint256 private constant FF_JULSWAP_FACTORY = 0xff553990f2cba90272390f62c5bdb1681ffc8996750000000000000000000000;

    // Init code hash of the PancakeSwap pair contract.
    uint256 private constant PANCAKESWAP_PAIR_INIT_CODE_HASH =
        0xd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66;
    // Init code hash of the PancakeSwapV2 pair contract.
    uint256 private constant PANCAKESWAPV2_PAIR_INIT_CODE_HASH =
        0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5;
    // Init code hash of the BakerySwap pair contract.
    uint256 private constant BAKERYSWAP_PAIR_INIT_CODE_HASH =
        0xe2e87433120e32c4738a7d8f3271f3d872cbe16241d67537139158d90bac61d3;
    // Init code hash of the SushiSwap pair contract.
    uint256 private constant SUSHISWAP_PAIR_INIT_CODE_HASH =
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    // Init code hash of the ApeSwap pair contract.
    uint256 private constant APESWAP_PAIR_INIT_CODE_HASH =
        0xf4ccce374816856d11f00e4069e7cada164065686fbef53c6167a63ec2fd8c5b;
    // Init code hash of the CafeSwap pair contract.
    uint256 private constant CAFESWAP_PAIR_INIT_CODE_HASH =
        0x90bcdb5d0bf0e8db3852b0b7d7e05cc8f7c6eb6d511213c5ba02d1d1dbeda8d3;
    // Init code hash of the CheeseSwap pair contract.
    uint256 private constant CHEESESWAP_PAIR_INIT_CODE_HASH =
        0xf52c5189a89e7ca2ef4f19f2798e3900fba7a316de7cef6c5a9446621ba86286;
    // Init code hash of the JulSwap pair contract.
    uint256 private constant JULSWAP_PAIR_INIT_CODE_HASH =
        0xb1e98e21a5335633815a8cfb3b580071c2e4561c50afd57a8746def9ed890b18;

    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    // BNB pseudo-token address.
    uint256 private constant ETH_TOKEN_ADDRESS_32 = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    // Maximum token quantity that can be swapped against the PancakeSwapPair contract.
    uint256 private constant MAX_SWAP_AMOUNT = 2 ** 112;

    // bytes4(keccak256("executeCall(address,bytes)"))
    uint256 private constant ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32 =
        0xbca8c7b500000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("getReserves()"))
    uint256 private constant PANCAKESWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
        0x0902f1ac00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address,bytes)"))
    uint256 private constant PANCAKESWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x022c0d9f00000000000000000000000000000000000000000000000000000000;
    // bytes4(keccak256("swap(uint256,uint256,address)"))
    uint256 private constant BAKERYSWAP_PAIR_SWAP_CALL_SELECTOR_32 =
        0x6d9a640a00000000000000000000000000000000000000000000000000000000;
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
    /// @param wbnb The WBNB contract.
    constructor(IEtherToken wbnb) public {
        WBNB = wbnb;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellToPancakeSwap.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Efficiently sell directly to pancake/BakerySwap/SushiSwap.
    /// @param tokens Sell path.
    /// @param sellAmount of `tokens[0]` Amount to sell.
    /// @param minBuyAmount Minimum amount of `tokens[-1]` to buy.
    /// @param fork The protocol fork to use.
    /// @return buyAmount Amount of `tokens[-1]` bought.
    function sellToPancakeSwap(
        IERC20Token[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        ProtocolFork fork
    ) external payable override returns (uint256 buyAmount) {
        require(tokens.length > 1, "PancakeSwapFeature/InvalidTokensLength");
        {
            // Load immutables onto the stack.
            IEtherToken wbnb = WBNB;

            // Store some vars in memory to get around stack limits.
            assembly {
                // calldataload(mload(0xA00)) == first element of `tokens` array
                mstore(0xA00, add(calldataload(0x04), 0x24))
                // mload(0xA20) == fork
                mstore(0xA20, fork)
                // mload(0xA40) == WBNB
                mstore(0xA40, wbnb)
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
                        // Not selling BNB. Selling an ERC20 instead.
                        // Make sure BNB was not attached to the call.
                        if gt(callvalue(), 0) {
                            revert(0, 0)
                        }
                        // For the first pair we need to transfer sellTokens into the
                        // pair contract.
                        moveTakerTokensTo(sellToken, pair, sellAmount)
                    }
                    default {
                        // If selling BNB, we need to wrap it to WBNB and transfer to the
                        // pair contract.
                        if iszero(eq(callvalue(), sellAmount)) {
                            revert(0, 0)
                        }
                        sellToken := mload(0xA40) // Re-assign to WBNB
                        // Call `WBNB.deposit{value: sellAmount}()`
                        mstore(0xB00, WETH_DEPOSIT_CALL_SELECTOR_32)
                        if iszero(call(gas(), sellToken, sellAmount, 0xB00, 0x4, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                        // Call `WBNB.transfer(pair, sellAmount)`
                        mstore(0xB00, ERC20_TRANSFER_CALL_SELECTOR_32)
                        mstore(0xB04, pair)
                        mstore(0xB24, sellAmount)
                        if iszero(call(gas(), sellToken, 0, 0xB00, 0x44, 0x00, 0x0)) {
                            bubbleRevert()
                        }
                    }
                    // No need to check results, if deposit/transfers failed the PancakeSwapPair will
                    // reject our trade (or it may succeed if somehow the reserve was out of sync)
                    // this is fine for the taker.
                }

                // Call pair.getReserves(), store the results at `0xC00`
                mstore(0xB00, PANCAKESWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                    bubbleRevert()
                }
                // Revert if the pair contract does not return at least two words.
                if lt(returndatasize(), 0x40) {
                    mstore(0, pair)
                    revert(0, 32)
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
                    // Forward directly to taker UNLESS they want BNB back.
                    switch eq(buyToken, ETH_TOKEN_ADDRESS_32)
                    case 0 {
                        receiver := caller()
                    }
                    default {
                        receiver := address()
                    }
                }

                // Call pair.swap()
                switch mload(0xA20) // fork
                case 2 {
                    mstore(0xB00, BAKERYSWAP_PAIR_SWAP_CALL_SELECTOR_32)
                }
                default {
                    mstore(0xB00, PANCAKESWAP_PAIR_SWAP_CALL_SELECTOR_32)
                }
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

            // If buying BNB, unwrap the WBNB first
            if eq(buyToken, ETH_TOKEN_ADDRESS_32) {
                // Call `WBNB.withdraw(buyAmount)`
                mstore(0xB00, WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(0xB04, buyAmount)
                if iszero(call(gas(), mload(0xA40), 0, 0xB00, 0x24, 0x00, 0x0)) {
                    bubbleRevert()
                }
                // Transfer BNB to the caller.
                if iszero(call(gas(), caller(), buyAmount, 0xB00, 0x0, 0x00, 0x0)) {
                    bubbleRevert()
                }
            }

            // Functions ///////////////////////////////////////////////////////

            // Load a token address from the `tokens` calldata argument.
            function loadTokenAddress(idx) -> addr {
                addr := and(ADDRESS_MASK, calldataload(add(mload(0xA00), mul(idx, 0x20))))
            }

            // Convert BNB pseudo-token addresses to WBNB.
            function normalizeToken(token) -> normalized {
                normalized := token
                // Translate BNB pseudo-tokens to WBNB.
                if eq(token, ETH_TOKEN_ADDRESS_32) {
                    normalized := mload(0xA40)
                }
            }

            // Compute the address of the PancakeSwapPair contract given two
            // tokens.
            function computePairAddress(tokenA, tokenB) -> pair {
                // Convert BNB pseudo-token addresses to WBNB.
                tokenA := normalizeToken(tokenA)
                tokenB := normalizeToken(tokenB)
                // There is one contract for every combination of tokens,
                // which is deployed using CREATE2.
                // The derivation of this address is given by:
                //   address(keccak256(abi.encodePacked(
                //       bytes(0xFF),
                //       address(PANCAKESWAP_FACTORY_ADDRESS),
                //       keccak256(abi.encodePacked(
                //           tokenA < tokenB ? tokenA : tokenB,
                //           tokenA < tokenB ? tokenB : tokenA,
                //       )),
                //       bytes32(PANCAKESWAP_PAIR_INIT_CODE_HASH),
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
                switch mload(0xA20) // fork
                case 0 {
                    mstore(0xB00, FF_PANCAKESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, PANCAKESWAP_PAIR_INIT_CODE_HASH)
                }
                case 1 {
                    mstore(0xB00, FF_PANCAKESWAPV2_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, PANCAKESWAPV2_PAIR_INIT_CODE_HASH)
                }
                case 2 {
                    mstore(0xB00, FF_BAKERYSWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, BAKERYSWAP_PAIR_INIT_CODE_HASH)
                }
                case 3 {
                    mstore(0xB00, FF_SUSHISWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, SUSHISWAP_PAIR_INIT_CODE_HASH)
                }
                case 4 {
                    mstore(0xB00, FF_APESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, APESWAP_PAIR_INIT_CODE_HASH)
                }
                case 5 {
                    mstore(0xB00, FF_CAFESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, CAFESWAP_PAIR_INIT_CODE_HASH)
                }
                case 6 {
                    mstore(0xB00, FF_CHEESESWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, CHEESESWAP_PAIR_INIT_CODE_HASH)
                }
                default {
                    mstore(0xB00, FF_JULSWAP_FACTORY)
                    mstore(0xB15, salt)
                    mstore(0xB35, JULSWAP_PAIR_INIT_CODE_HASH)
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
        require(buyAmount >= minBuyAmount, "PancakeSwapFeature/UnderBought");
    }
}
