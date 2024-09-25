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
import "../vendor/IUniswapV3Pool.sol";
import "../migrations/LibMigrate.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinTokenSpender.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IUniswapV3Feature.sol";

/// @dev VIP uniswap fill functions.
contract UniswapV3Feature is IFeature, IUniswapV3Feature, FixinCommon, FixinTokenSpender {
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "UniswapV3Feature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);
    /// @dev WETH contract.
    IEtherToken private immutable WETH;
    /// @dev UniswapV3 Factory contract address prepended with '0xff' and left-aligned.
    bytes32 private immutable UNI_FF_FACTORY_ADDRESS;
    /// @dev UniswapV3 pool init code hash.
    bytes32 private immutable UNI_POOL_INIT_CODE_HASH;
    /// @dev Minimum size of an encoded swap path:
    ///      sizeof(address(inputToken) | uint24(fee) | address(outputToken))
    uint256 private constant SINGLE_HOP_PATH_SIZE = 20 + 3 + 20;
    /// @dev How many bytes to skip ahead in an encoded path to start at the next hop:
    ///      sizeof(address(inputToken) | uint24(fee))
    uint256 private constant PATH_SKIP_HOP_SIZE = 20 + 3;
    /// @dev The size of the swap callback data.
    uint256 private constant SWAP_CALLBACK_DATA_SIZE = 128;
    /// @dev Minimum tick price sqrt ratio.
    uint160 internal constant MIN_PRICE_SQRT_RATIO = 4295128739;
    /// @dev Minimum tick price sqrt ratio.
    uint160 internal constant MAX_PRICE_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    /// @dev Mask of lower 20 bytes.
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    /// @dev Mask of lower 3 bytes.
    uint256 private constant UINT24_MASK = 0xffffff;

    /// @dev Construct this contract.
    /// @param weth The WETH contract.
    /// @param uniFactory The UniswapV3 factory contract.
    /// @param poolInitCodeHash The UniswapV3 pool init code hash.
    constructor(IEtherToken weth, address uniFactory, bytes32 poolInitCodeHash) public {
        WETH = weth;
        UNI_FF_FACTORY_ADDRESS = bytes32((uint256(0xff) << 248) | (uint256(uniFactory) << 88));
        UNI_POOL_INIT_CODE_HASH = poolInitCodeHash;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.sellEthForTokenToUniswapV3.selector);
        _registerFeatureFunction(this.sellTokenForEthToUniswapV3.selector);
        _registerFeatureFunction(this.sellTokenForTokenToUniswapV3.selector);
        _registerFeatureFunction(this._sellTokenForTokenToUniswapV3.selector);
        _registerFeatureFunction(this._sellHeldTokenForTokenToUniswapV3.selector);
        _registerFeatureFunction(this.uniswapV3SwapCallback.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sell attached ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the first token is WETH.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellEthForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 minBuyAmount,
        address recipient
    ) public payable override returns (uint256 buyAmount) {
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        return
            _swap(
                encodedPath,
                msg.value,
                minBuyAmount,
                address(this), // we are payer because we hold the WETH
                _normalizeRecipient(recipient)
            );
    }

    /// @dev Sell a token for ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the last token is WETH.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of ETH to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of ETH bought.
    function sellTokenForEthToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payable recipient
    ) public override returns (uint256 buyAmount) {
        buyAmount = _swap(
            encodedPath,
            sellAmount,
            minBuyAmount,
            msg.sender,
            address(this) // we are recipient because we need to unwrap WETH
        );
        WETH.withdraw(buyAmount);
        // Transfer ETH to recipient.
        (bool success, bytes memory revertData) = _normalizeRecipient(recipient).call{value: buyAmount}("");
        if (!success) {
            revertData.rrevert();
        }
    }

    /// @dev Sell a token for another token directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) public override returns (uint256 buyAmount) {
        buyAmount = _swap(encodedPath, sellAmount, minBuyAmount, msg.sender, _normalizeRecipient(recipient));
    }

    /// @dev Sell a token for another token directly against uniswap v3. Internal variant.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for payer.
    /// @param payer The address to pull the sold tokens from.
    /// @return buyAmount Amount of the last token in the path bought.
    function _sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient,
        address payer
    ) public override onlySelf returns (uint256 buyAmount) {
        buyAmount = _swap(encodedPath, sellAmount, minBuyAmount, payer, _normalizeRecipient(recipient, payer));
    }

    /// @dev Sell a token for another token directly against uniswap v3.
    ///      Private variant, uses tokens held by `address(this)`.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function _sellHeldTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) public override onlySelf returns (uint256 buyAmount) {
        buyAmount = _swap(encodedPath, sellAmount, minBuyAmount, address(this), _normalizeRecipient(recipient));
    }

    /// @dev The UniswapV3 pool swap callback which pays the funds requested
    ///      by the caller/pool to the pool. Can only be called by a valid
    ///      UniswapV3 pool.
    /// @param amount0Delta Token0 amount owed.
    /// @param amount1Delta Token1 amount owed.
    /// @param data Arbitrary data forwarded from swap() caller. An ABI-encoded
    ///        struct of: inputToken, outputToken, fee, payer
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        IERC20Token token0;
        IERC20Token token1;
        address payer;
        {
            uint24 fee;
            // Decode the data.
            require(data.length == SWAP_CALLBACK_DATA_SIZE, "UniswapFeature/INVALID_SWAP_CALLBACK_DATA");
            assembly {
                let p := add(36, calldataload(68))
                token0 := calldataload(p)
                token1 := calldataload(add(p, 32))
                fee := calldataload(add(p, 64))
                payer := calldataload(add(p, 96))
            }
            (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
            // Only a valid pool contract can call this function.
            require(
                msg.sender == address(_toPool(token0, fee, token1)),
                "UniswapV3Feature/INVALID_SWAP_CALLBACK_CALLER"
            );
        }
        // Pay the amount owed to the pool.
        if (amount0Delta > 0) {
            _pay(token0, payer, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            _pay(token1, payer, msg.sender, uint256(amount1Delta));
        } else {
            revert("UniswapV3Feature/INVALID_SWAP_AMOUNTS");
        }
    }

    // Executes successive swaps along an encoded uniswap path.
    function _swap(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payer,
        address recipient
    ) private returns (uint256 buyAmount) {
        if (sellAmount != 0) {
            require(sellAmount <= uint256(type(int256).max), "UniswapV3Feature/SELL_AMOUNT_OVERFLOW");

            // Perform a swap for each hop in the path.
            bytes memory swapCallbackData = new bytes(SWAP_CALLBACK_DATA_SIZE);
            while (true) {
                bool isPathMultiHop = _isPathMultiHop(encodedPath);
                bool zeroForOne;
                IUniswapV3Pool pool;
                {
                    (IERC20Token inputToken, uint24 fee, IERC20Token outputToken) = _decodeFirstPoolInfoFromPath(
                        encodedPath
                    );
                    pool = _toPool(inputToken, fee, outputToken);
                    zeroForOne = inputToken < outputToken;
                    _updateSwapCallbackData(swapCallbackData, inputToken, outputToken, fee, payer);
                }
                (int256 amount0, int256 amount1) = pool.swap(
                    // Intermediate tokens go to this contract.
                    isPathMultiHop ? address(this) : recipient,
                    zeroForOne,
                    int256(sellAmount),
                    zeroForOne ? MIN_PRICE_SQRT_RATIO + 1 : MAX_PRICE_SQRT_RATIO - 1,
                    swapCallbackData
                );
                {
                    int256 _buyAmount = -(zeroForOne ? amount1 : amount0);
                    require(_buyAmount >= 0, "UniswapV3Feature/INVALID_BUY_AMOUNT");
                    buyAmount = uint256(_buyAmount);
                }
                if (!isPathMultiHop) {
                    // Done.
                    break;
                }
                // Continue with next hop.
                payer = address(this); // Subsequent hops are paid for by us.
                sellAmount = buyAmount;
                // Skip to next hop along path.
                encodedPath = _shiftHopFromPathInPlace(encodedPath);
            }
        }
        require(minBuyAmount <= buyAmount, "UniswapV3Feature/UNDERBOUGHT");
    }

    // Pay tokens from `payer` to `to`, using `transferFrom()` if
    // `payer` != this contract.
    function _pay(IERC20Token token, address payer, address to, uint256 amount) private {
        if (payer != address(this)) {
            _transferERC20TokensFrom(token, payer, to, amount);
        } else {
            _transferERC20Tokens(token, to, amount);
        }
    }

    // Update `swapCallbackData` in place with new values.
    function _updateSwapCallbackData(
        bytes memory swapCallbackData,
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint24 fee,
        address payer
    ) private pure {
        assembly {
            let p := add(swapCallbackData, 32)
            mstore(p, inputToken)
            mstore(add(p, 32), outputToken)
            mstore(add(p, 64), and(UINT24_MASK, fee))
            mstore(add(p, 96), and(ADDRESS_MASK, payer))
        }
    }

    // Compute the pool address given two tokens and a fee.
    function _toPool(
        IERC20Token inputToken,
        uint24 fee,
        IERC20Token outputToken
    ) private view returns (IUniswapV3Pool pool) {
        // address(keccak256(abi.encodePacked(
        //     hex"ff",
        //     UNI_FACTORY_ADDRESS,
        //     keccak256(abi.encode(inputToken, outputToken, fee)),
        //     UNI_POOL_INIT_CODE_HASH
        // )))
        bytes32 ffFactoryAddress = UNI_FF_FACTORY_ADDRESS;
        bytes32 poolInitCodeHash = UNI_POOL_INIT_CODE_HASH;
        (IERC20Token token0, IERC20Token token1) = inputToken < outputToken
            ? (inputToken, outputToken)
            : (outputToken, inputToken);
        assembly {
            let s := mload(0x40)
            let p := s
            mstore(p, ffFactoryAddress)
            p := add(p, 21)
            // Compute the inner hash in-place
            mstore(p, token0)
            mstore(add(p, 32), token1)
            mstore(add(p, 64), and(UINT24_MASK, fee))
            mstore(p, keccak256(p, 96))
            p := add(p, 32)
            mstore(p, poolInitCodeHash)
            pool := and(ADDRESS_MASK, keccak256(s, 85))
        }
    }

    // Return whether or not an encoded uniswap path contains more than one hop.
    function _isPathMultiHop(bytes memory encodedPath) private pure returns (bool isMultiHop) {
        return encodedPath.length > SINGLE_HOP_PATH_SIZE;
    }

    // Return the first input token, output token, and fee of an encoded uniswap path.
    function _decodeFirstPoolInfoFromPath(
        bytes memory encodedPath
    ) private pure returns (IERC20Token inputToken, uint24 fee, IERC20Token outputToken) {
        require(encodedPath.length >= SINGLE_HOP_PATH_SIZE, "UniswapV3Feature/BAD_PATH_ENCODING");
        assembly {
            let p := add(encodedPath, 32)
            inputToken := shr(96, mload(p))
            p := add(p, 20)
            fee := shr(232, mload(p))
            p := add(p, 3)
            outputToken := shr(96, mload(p))
        }
    }

    // Skip past the first hop of an encoded uniswap path in-place.
    function _shiftHopFromPathInPlace(bytes memory encodedPath) private pure returns (bytes memory shiftedEncodedPath) {
        require(encodedPath.length >= PATH_SKIP_HOP_SIZE, "UniswapV3Feature/BAD_PATH_ENCODING");
        uint256 shiftSize = PATH_SKIP_HOP_SIZE;
        uint256 newSize = encodedPath.length - shiftSize;
        assembly {
            shiftedEncodedPath := add(encodedPath, shiftSize)
            mstore(shiftedEncodedPath, newSize)
        }
    }

    // Convert null address values to alternative address.
    function _normalizeRecipient(
        address recipient,
        address alternative
    ) private pure returns (address payable normalizedRecipient) {
        return recipient == address(0) ? payable(alternative) : payable(recipient);
    }

    // Convert null address values to msg.sender.
    function _normalizeRecipient(address recipient) private view returns (address payable normalizedRecipient) {
        return _normalizeRecipient(recipient, msg.sender);
    }
}
