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
  
  /*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "../src/LibBytes.sol";

contract TestLibBytes {
    using LibBytes for bytes;

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return The byte that was popped off.
    function publicPopLastByte(bytes memory b) public pure returns (bytes memory, bytes1 result) {
        result = b.popLastByte();
        return (b, result);
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return True if arrays are the same. False otherwise.
    function publicEquals(bytes memory lhs, bytes memory rhs) public pure returns (bool equal) {
        equal = lhs.equals(rhs);
        return equal;
    }

    function publicEqualsPop1(bytes memory lhs, bytes memory rhs) public pure returns (bool equal) {
        lhs.popLastByte();
        rhs.popLastByte();
        equal = lhs.equals(rhs);
        return equal;
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return address from byte array.
    function publicReadAddress(bytes memory b, uint256 index) public pure returns (address result) {
        result = b.readAddress(index);
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function publicWriteAddress(bytes memory b, uint256 index, address input) public pure returns (bytes memory) {
        b.writeAddress(index, input);
        return b;
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return bytes32 value from byte array.
    function publicReadBytes32(bytes memory b, uint256 index) public pure returns (bytes32 result) {
        result = b.readBytes32(index);
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function publicWriteBytes32(bytes memory b, uint256 index, bytes32 input) public pure returns (bytes memory) {
        b.writeBytes32(index, input);
        return b;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return uint256 value from byte array.
    function publicReadUint256(bytes memory b, uint256 index) public pure returns (uint256 result) {
        result = b.readUint256(index);
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function publicWriteUint256(bytes memory b, uint256 index, uint256 input) public pure returns (bytes memory) {
        b.writeUint256(index, input);
        return b;
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return bytes4 value from byte array.
    function publicReadBytes4(bytes memory b, uint256 index) public pure returns (bytes4 result) {
        result = b.readBytes4(index);
        return result;
    }

    /// @dev Copies a block of memory from one location to another.
    /// @param mem Memory contents we want to apply memCopy to
    /// @param dest Destination offset into <mem>.
    /// @param source Source offset into <mem>.
    /// @param length Length of bytes to copy from <source> to <dest>
    /// @return mem Memory contents after calling memCopy.
    function testMemcpy(
        bytes memory mem,
        uint256 dest,
        uint256 source,
        uint256 length // not external, we need input in memory
    ) public pure returns (bytes memory) {
        // Sanity check. Overflows are not checked.
        require(source + length <= mem.length);
        require(dest + length <= mem.length);

        // Get pointer to memory contents
        uint256 offset = mem.contentAddress();

        // Execute memCopy adjusted for memory array location
        LibBytes.memCopy(offset + dest, offset + source, length);

        // Return modified memory contents
        return mem;
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function publicSlice(
        bytes memory b,
        uint256 from,
        uint256 to
    ) public pure returns (bytes memory result, bytes memory original) {
        result = LibBytes.slice(b, from, to);
        return (result, b);
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function publicSliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    ) public pure returns (bytes memory result, bytes memory original) {
        result = LibBytes.sliceDestructive(b, from, to);
        return (result, b);
    }

    /// @dev Returns a byte array with an updated length.
    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    /// @param extraBytes Bytes that are appended to end of b in memory.
    function publicWriteLength(
        bytes memory b,
        uint256 length,
        bytes memory extraBytes
    ) public pure returns (bytes memory) {
        uint256 bEnd = b.contentAddress() + b.length;
        LibBytes.memCopy(bEnd, extraBytes.contentAddress(), extraBytes.length);
        b.writeLength(length);
        return b;
    }

    function assertBytesUnchangedAfterLengthReset(bytes memory b, uint256 tempLength) public pure {
        uint256 length = b.length;
        bytes memory bCopy = b.slice(0, length);
        b.writeLength(tempLength);
        b.writeLength(length);
        assert(b.equals(bCopy));
    }
}
