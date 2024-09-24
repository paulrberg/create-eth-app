/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/OpenSea-Seaport?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SignatureVerificationErrors} from "OpenSea-Seaport/seaport-types/src/interfaces/SignatureVerificationErrors.sol";

import {LowLevelHelpers} from "./LowLevelHelpers.sol";

import {
    ECDSA_MaxLength,
    ECDSA_signature_s_offset,
    ECDSA_signature_v_offset,
    ECDSA_twentySeventhAndTwentyEighthBytesSet,
    Ecrecover_args_size,
    Ecrecover_precompile,
    EIP1271_isValidSignature_calldata_baseLength,
    EIP1271_isValidSignature_digest_negativeOffset,
    EIP1271_isValidSignature_selector_negativeOffset,
    EIP1271_isValidSignature_selector,
    EIP1271_isValidSignature_signature_head_offset,
    EIP2098_allButHighestBitMask,
    MaxUint8,
    OneWord,
    Signature_lower_v
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationConstants.sol";

import {
    BadContractSignature_error_length,
    BadContractSignature_error_selector,
    BadSignatureV_error_length,
    BadSignatureV_error_selector,
    BadSignatureV_error_v_ptr,
    Error_selector_offset,
    InvalidSignature_error_length,
    InvalidSignature_error_selector,
    InvalidSigner_error_length,
    InvalidSigner_error_selector
} from "OpenSea-Seaport/seaport-types/src/lib/ConsiderationErrorConstants.sol";

/**
 * @title SignatureVerification
 * @author 0age
 * @notice SignatureVerification contains logic for verifying signatures.
 */
contract SignatureVerification is SignatureVerificationErrors, LowLevelHelpers {
    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer.
     *
     * @param signer                  The signer for the order.
     * @param digest                  The digest to verify signature against.
     * @param originalDigest          The original digest to verify signature
     *                                against.
     * @param originalSignatureLength The original signature length.
     * @param signature               A signature from the signer indicating
     *                                that the order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        uint256 originalSignatureLength,
        bytes memory signature
    ) internal view {
        // Declare value for ecrecover equality or 1271 call success status.
        bool success;

        // Utilize assembly to perform optimized signature verification check.
        assembly {
            // Ensure that first word of scratch space is empty.
            mstore(0, 0)

            // Get the length of the signature.
            let signatureLength := mload(signature)

            // Get the pointer to the value preceding the signature length.
            // This will be used for temporary memory overrides - either the
            // signature head for isValidSignature or the digest for ecrecover.
            let wordBeforeSignaturePtr := sub(signature, OneWord)

            // Cache the current value behind the signature to restore it later.
            let cachedWordBeforeSignature := mload(wordBeforeSignaturePtr)

            // Declare lenDiff + recoveredSigner scope to manage stack pressure.
            {
                // Take the difference between the max ECDSA signature length
                // and the actual signature length. Overflow desired for any
                // values > 65. If the diff is not 0 or 1, it is not a valid
                // ECDSA signature - move on to EIP1271 check.
                let lenDiff := sub(ECDSA_MaxLength, signatureLength)

                // Declare variable for recovered signer.
                let recoveredSigner

                // If diff is 0 or 1, it may be an ECDSA signature.
                // Try to recover signer.
                if iszero(gt(lenDiff, 1)) {
                    // Read the signature `s` value.
                    let originalSignatureS := mload(add(signature, ECDSA_signature_s_offset))

                    // Read the first byte of the word after `s`. If the
                    // signature is 65 bytes, this will be the real `v` value.
                    // If not, it will need to be modified - doing it this way
                    // saves an extra condition.
                    let v := byte(0, mload(add(signature, ECDSA_signature_v_offset)))

                    // If lenDiff is 1, parse 64-byte signature as ECDSA.
                    if lenDiff {
                        // Extract yParity from highest bit of vs and add 27 to
                        // get v.
                        v := add(shr(MaxUint8, originalSignatureS), Signature_lower_v)

                        // Extract canonical s from vs, all but the highest bit.
                        // Temporarily overwrite the original `s` value in the
                        // signature.
                        mstore(
                            add(signature, ECDSA_signature_s_offset),
                            and(originalSignatureS, EIP2098_allButHighestBitMask)
                        )
                    }
                    // Temporarily overwrite the signature length with `v` to
                    // conform to the expected input for ecrecover.
                    mstore(signature, v)

                    // Temporarily overwrite the word before the length with
                    // `digest` to conform to the expected input for ecrecover.
                    mstore(wordBeforeSignaturePtr, digest)

                    // Attempt to recover the signer for the given signature. Do
                    // not check the call status as ecrecover will return a null
                    // address if the signature is invalid.
                    pop(
                        staticcall(
                            gas(),
                            Ecrecover_precompile, // Call ecrecover precompile.
                            wordBeforeSignaturePtr, // Use data memory location.
                            Ecrecover_args_size, // Size of digest, v, r, and s.
                            0, // Write result to scratch space.
                            OneWord // Provide size of returned result.
                        )
                    )

                    // Restore cached word before signature.
                    mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)

                    // Restore cached signature length.
                    mstore(signature, signatureLength)

                    // Restore cached signature `s` value.
                    mstore(add(signature, ECDSA_signature_s_offset), originalSignatureS)

                    // Read the recovered signer from the buffer given as return
                    // space for ecrecover.
                    recoveredSigner := mload(0)
                }

                // Set success to true if the signature provided was a valid
                // ECDSA signature and the signer is not the null address. Use
                // gt instead of direct as success is used outside of assembly.
                success := and(eq(signer, recoveredSigner), gt(signer, 0))
            }

            // If the signature was not verified with ecrecover, try EIP1271.
            if iszero(success) {
                // Reset the original signature length.
                mstore(signature, originalSignatureLength)

                // Temporarily overwrite the word before the signature length
                // and use it as the head of the signature input to
                // `isValidSignature`, which has a value of 64.
                mstore(wordBeforeSignaturePtr, EIP1271_isValidSignature_signature_head_offset)

                // Get pointer to use for the selector of `isValidSignature`.
                let selectorPtr := sub(signature, EIP1271_isValidSignature_selector_negativeOffset)

                // Cache the value currently stored at the selector pointer.
                let cachedWordOverwrittenBySelector := mload(selectorPtr)

                // Cache the value currently stored at the digest pointer.
                let cachedWordOverwrittenByDigest :=
                    mload(sub(signature, EIP1271_isValidSignature_digest_negativeOffset))

                // Write the selector first, since it overlaps the digest.
                mstore(selectorPtr, EIP1271_isValidSignature_selector)

                // Next, write the original digest.
                mstore(sub(signature, EIP1271_isValidSignature_digest_negativeOffset), originalDigest)

                // Call signer with `isValidSignature` to validate signature.
                success :=
                    staticcall(
                        gas(),
                        signer,
                        selectorPtr,
                        add(originalSignatureLength, EIP1271_isValidSignature_calldata_baseLength),
                        0,
                        OneWord
                    )

                // Determine if the signature is valid on successful calls.
                if success {
                    // If first word of scratch space does not contain EIP-1271
                    // signature selector, revert.
                    if iszero(eq(mload(0), EIP1271_isValidSignature_selector)) {
                        // Revert with bad 1271 signature if signer has code.
                        if extcodesize(signer) {
                            // Bad contract signature.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, BadContractSignature_error_selector)

                            // revert(abi.encodeWithSignature(
                            //     "BadContractSignature()"
                            // ))
                            revert(Error_selector_offset, BadContractSignature_error_length)
                        }

                        // Check if signature length was invalid.
                        if gt(sub(ECDSA_MaxLength, signatureLength), 1) {
                            // Revert with generic invalid signature error.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, InvalidSignature_error_selector)

                            // revert(abi.encodeWithSignature(
                            //     "InvalidSignature()"
                            // ))
                            revert(Error_selector_offset, InvalidSignature_error_length)
                        }

                        // Check if v was invalid.
                        if and(
                            eq(signatureLength, ECDSA_MaxLength),
                            iszero(
                                byte(
                                    byte(0, mload(add(signature, ECDSA_signature_v_offset))),
                                    ECDSA_twentySeventhAndTwentyEighthBytesSet
                                )
                            )
                        ) {
                            // Revert with invalid v value.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, BadSignatureV_error_selector)
                            mstore(BadSignatureV_error_v_ptr, byte(0, mload(add(signature, ECDSA_signature_v_offset))))

                            // revert(abi.encodeWithSignature(
                            //     "BadSignatureV(uint8)", v
                            // ))
                            revert(Error_selector_offset, BadSignatureV_error_length)
                        }

                        // Revert with generic invalid signer error message.
                        // Store left-padded selector with push4, mem[28:32]
                        mstore(0, InvalidSigner_error_selector)

                        // revert(abi.encodeWithSignature("InvalidSigner()"))
                        revert(Error_selector_offset, InvalidSigner_error_length)
                    }
                }

                // Restore the cached values overwritten by selector, digest and
                // signature head.
                mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)
                mstore(selectorPtr, cachedWordOverwrittenBySelector)
                mstore(sub(signature, EIP1271_isValidSignature_digest_negativeOffset), cachedWordOverwrittenByDigest)
            }
        }

        // If the call failed...
        if (!success) {
            // Revert and pass reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with error indicating bad contract signature.
            assembly {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, BadContractSignature_error_selector)
                // revert(abi.encodeWithSignature("BadContractSignature()"))
                revert(Error_selector_offset, BadContractSignature_error_length)
            }
        }
    }
}
