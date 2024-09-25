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
  
  // SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library CallWithGas {
    /**
     * @notice `staticcall` another contract forwarding a precomputed amount of
     *         gas.
     * @dev contains protections against EIP-150-induced insufficient gas
     *      griefing
     * @dev reverts iff the target is not a contract or we encounter an
     *      out-of-gas
     * @return success true iff the call succeded and returned no more than
     *                 `maxReturnBytes` of return data
     * @return returnData the return data or revert reason of the call
     * @param target the contract (reverts if non-contract) on which to make the
     *               `staticcall`
     * @param data the calldata to pass
     * @param callGas the gas to pass for the call. If the call requires more than
     *                the specified amount of gas and the caller didn't provide at
     *                least `callGas`, triggers an out-of-gas in the caller.
     * @param maxReturnBytes Only this many bytes of return data are read back
     *                       from the call. This prevents griefing the caller. If
     *                       more bytes are returned or the revert reason is
     *                       longer, success will be false and returnData will be
     *                       `abi.encodeWithSignature("Error(string)", "CallWithGas: returnData too long")`
     */
    function functionStaticCallWithGas(
        address target,
        bytes memory data,
        uint256 callGas,
        uint256 maxReturnBytes
    ) internal view returns (bool success, bytes memory returnData) {
        assembly ("memory-safe") {
            returnData := mload(0x40)
            success := staticcall(callGas, target, add(data, 0x20), mload(data), add(returnData, 0x20), maxReturnBytes)

            // As of the time this contract was written, `verbatim` doesn't work in
            // inline assembly.  Assignment of a value to a variable costs gas
            // (although how much is unpredictable because it depends on the Yul/IR
            // optimizer), as does the `GAS` opcode itself. Also solc tends to reorder
            // the call to `gas()` with preparing the arguments for `div`. Therefore,
            // the `gas()` below returns less than the actual amount of gas available
            // for computation at the end of the call. That makes this check slightly
            // too conservative. However, we do not correct for this because the
            // correction would become outdated (possibly too permissive) if the
            // opcodes are repriced.

            // https://eips.ethereum.org/EIPS/eip-150
            // https://ronan.eth.link/blog/ethereum-gas-dangers/
            if iszero(or(success, or(returndatasize(), lt(div(callGas, 63), gas())))) {
                // The call failed due to not enough gas left. We deliberately consume
                // all remaining gas with `invalid` (instead of `revert`) to make this
                // failure distinguishable to our caller.
                invalid()
            }

            switch gt(returndatasize(), maxReturnBytes)
            case 0 {
                switch returndatasize()
                case 0 {
                    returnData := 0x60
                    success := and(success, iszero(iszero(extcodesize(target))))
                }
                default {
                    mstore(returnData, returndatasize())
                    mstore(0x40, add(returnData, add(0x20, returndatasize())))
                }
            }
            default {
                // returnData = abi.encodeWithSignature("Error(string)", "CallWithGas: returnData too long")
                success := 0
                mstore(returnData, 0) // clear potentially dirty bits
                mstore(add(returnData, 0x04), 0x6408c379a0) // length and selector
                mstore(add(returnData, 0x24), 0x20)
                mstore(add(returnData, 0x44), 0x20)
                mstore(add(returnData, 0x64), "CallWithGas: returnData too long")
                mstore(0x40, add(returnData, 0x84))
            }
        }
    }

    /// See `functionCallWithGasAndValue`
    function functionCallWithGas(
        address target,
        bytes memory data,
        uint256 callGas,
        uint256 maxReturnBytes
    ) internal returns (bool success, bytes memory returnData) {
        return functionCallWithGasAndValue(payable(target), data, callGas, 0, maxReturnBytes);
    }

    /**
     * @notice `call` another contract forwarding a precomputed amount of gas.
     * @notice Unlike `functionStaticCallWithGas`, a failure is not signaled if
     *         there is too much return data. Instead, it is simply truncated.
     * @dev contains protections against EIP-150-induced insufficient gas griefing
     * @dev reverts iff caller doesn't have enough native asset balance, the
     *      target is not a contract, or due to out-of-gas
     * @return success true iff the call succeded
     * @return returnData the return data or revert reason of the call
     * @param target the contract (reverts if non-contract) on which to make the
     *               `call`
     * @param data the calldata to pass
     * @param callGas the gas to pass for the call. If the call requires more than
     *                the specified amount of gas and the caller didn't provide at
     *                least `callGas`, triggers an out-of-gas in the caller.
     * @param value the amount of the native asset in wei to pass to the callee
     *              with the call
     * @param maxReturnBytes Only this many bytes of return data/revert reason are
     *                       read back from the call. This prevents griefing the
     *                       caller. If more bytes are returned or the revert
     *                       reason is longer, returnData will be truncated
     */
    function functionCallWithGasAndValue(
        address payable target,
        bytes memory data,
        uint256 callGas,
        uint256 value,
        uint256 maxReturnBytes
    ) internal returns (bool success, bytes memory returnData) {
        if (value > 0 && (address(this).balance < value || target.code.length == 0)) {
            return (success, returnData);
        }

        assembly ("memory-safe") {
            returnData := mload(0x40)
            success := call(callGas, target, value, add(data, 0x20), mload(data), add(returnData, 0x20), maxReturnBytes)

            // As of the time this contract was written, `verbatim` doesn't work in
            // inline assembly.  Assignment of a value to a variable costs gas
            // (although how much is unpredictable because it depends on the Yul/IR
            // optimizer), as does the `GAS` opcode itself. Also solc tends to reorder
            // the call to `gas()` with preparing the arguments for `div`. Therefore,
            // the `gas()` below returns less than the actual amount of gas available
            // for computation at the end of the call. That makes this check slightly
            // too conservative. However, we do not correct for this because the
            // correction would become outdated (possibly too permissive) if the
            // opcodes are repriced.

            // https://eips.ethereum.org/EIPS/eip-150
            // https://ronan.eth.link/blog/ethereum-gas-dangers/
            if iszero(or(success, or(returndatasize(), lt(div(callGas, 63), gas())))) {
                // The call failed due to not enough gas left. We deliberately consume
                // all remaining gas with `invalid` (instead of `revert`) to make this
                // failure distinguishable to our caller.
                invalid()
            }

            switch gt(returndatasize(), maxReturnBytes)
            case 0 {
                switch returndatasize()
                case 0 {
                    returnData := 0x60
                    if iszero(value) {
                        success := and(success, iszero(iszero(extcodesize(target))))
                    }
                }
                default {
                    mstore(returnData, returndatasize())
                    mstore(0x40, add(returnData, add(0x20, returndatasize())))
                }
            }
            default {
                mstore(returnData, maxReturnBytes)
                mstore(0x40, add(returnData, add(0x20, maxReturnBytes)))
            }
        }
    }
}
