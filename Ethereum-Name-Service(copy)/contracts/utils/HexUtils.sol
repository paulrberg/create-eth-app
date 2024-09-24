/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Ethereum-Name-Service?utm=code
  */
  
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library HexUtils {
    /**
     * @dev Attempts to parse bytes32 from a hex string
     * @param str The string to parse
     * @param idx The offset to start parsing at
     * @param lastIdx The (exclusive) last index in `str` to consider. Use `str.length` to scan the whole string.
     */
    function hexStringToBytes32(
        bytes memory str,
        uint256 idx,
        uint256 lastIdx
    ) internal pure returns (bytes32 r, bool valid) {
        valid = true;
        assembly {
            // check that the index to read to is not past the end of the string
            if gt(lastIdx, mload(str)) {
                revert(0, 0)
            }

            function getHex(c) -> ascii {
                // chars 48-57: 0-9
                if and(gt(c, 47), lt(c, 58)) {
                    ascii := sub(c, 48)
                    leave
                }
                // chars 65-70: A-F
                if and(gt(c, 64), lt(c, 71)) {
                    ascii := add(sub(c, 65), 10)
                    leave
                }
                // chars 97-102: a-f
                if and(gt(c, 96), lt(c, 103)) {
                    ascii := add(sub(c, 97), 10)
                    leave
                }
                // invalid char
                ascii := 0xff
            }

            let ptr := add(str, 32)
            for {
                let i := idx
            } lt(i, lastIdx) {
                i := add(i, 2)
            } {
                let byte1 := getHex(byte(0, mload(add(ptr, i))))
                let byte2 := getHex(byte(0, mload(add(ptr, add(i, 1)))))
                // if either byte is invalid, set invalid and break loop
                if or(eq(byte1, 0xff), eq(byte2, 0xff)) {
                    valid := false
                    break
                }
                let combined := or(shl(4, byte1), byte2)
                r := or(shl(8, r), combined)
            }
        }
    }

    /**
     * @dev Attempts to parse an address from a hex string
     * @param str The string to parse
     * @param idx The offset to start parsing at
     * @param lastIdx The (exclusive) last index in `str` to consider. Use `str.length` to scan the whole string.
     */
    function hexToAddress(
        bytes memory str,
        uint256 idx,
        uint256 lastIdx
    ) internal pure returns (address, bool) {
        if (lastIdx - idx < 40) return (address(0x0), false);
        (bytes32 r, bool valid) = hexStringToBytes32(str, idx, lastIdx);
        return (address(uint160(uint256(r))), valid);
    }
}
