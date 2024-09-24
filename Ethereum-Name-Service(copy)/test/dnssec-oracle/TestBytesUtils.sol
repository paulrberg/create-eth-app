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
  
  pragma solidity ^0.8.4;

import "../../contracts/dnssec-oracle/RRUtils.sol";
import "../../contracts/dnssec-oracle/BytesUtils.sol";

contract TestBytesUtils {
    using BytesUtils for *;

    function testKeccak() public pure {
        require(
            "".keccak(0, 0) ==
                bytes32(
                    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
                ),
            "Incorrect hash of empty string"
        );
        require(
            "foo".keccak(0, 3) ==
                bytes32(
                    0x41b1a0649752af1b28b3dc29a1556eee781e4a4c3a1f7f53f90fa834de098c4d
                ),
            "Incorrect hash of 'foo'"
        );
        require(
            "foo".keccak(0, 0) ==
                bytes32(
                    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
                ),
            "Incorrect hash of empty string"
        );
    }

    function testEquals() public pure {
        require("hello".equals("hello") == true, "String equality");
        require("hello".equals("goodbye") == false, "String inequality");
        require(
            "hello".equals(1, "ello") == true,
            "Substring to string equality"
        );
        require(
            "hello".equals(1, "jello", 1, 4) == true,
            "Substring to substring equality"
        );
        require(
            "zhello".equals(1, "abchello", 3) == true,
            "Compare different value with multiple length"
        );
        require(
            "0x0102030000".equals(0, "0x010203") == false,
            "Compare with offset and trailing bytes"
        );
    }

    function testComparePartial() public pure {
        require(
            "xax".compare(1, 1, "xxbxx", 2, 1) < 0 == true,
            "Compare same length"
        );
        require(
            "xax".compare(1, 1, "xxabxx", 2, 2) < 0 == true,
            "Compare different length"
        );
        require(
            "xax".compare(1, 1, "xxaxx", 2, 1) == 0 == true,
            "Compare same with different offset"
        );
        require(
            "01234567890123450123456789012345ab".compare(
                0,
                33,
                "01234567890123450123456789012345aa",
                0,
                33
            ) ==
                0 ==
                true,
            "Compare different long strings same length smaller partial length which must be equal"
        );
        require(
            "01234567890123450123456789012345ab".compare(
                0,
                33,
                "01234567890123450123456789012345aa",
                0,
                34
            ) <
                0 ==
                true,
            "Compare long strings same length different partial length"
        );
        require(
            "0123456789012345012345678901234a".compare(
                0,
                32,
                "0123456789012345012345678901234b",
                0,
                32
            ) <
                0 ==
                true,
            "Compare strings exactly 32 characters long"
        );
    }

    function testCompare() public pure {
        require("a".compare("a") == 0 == true, "Compare equal");
        require(
            "a".compare("b") < 0 == true,
            "Compare different value with same length"
        );
        require(
            "b".compare("a") > 0 == true,
            "Compare different value with same length"
        );
        require(
            "aa".compare("ab") < 0 == true,
            "Compare different value with multiple length"
        );
        require(
            "a".compare("aa") < 0 == true,
            "Compare different value with different length"
        );
        require(
            "aa".compare("a") > 0 == true,
            "Compare different value with different length"
        );
        bytes memory longChar = "1234567890123456789012345678901234";
        require(
            longChar.compare(longChar) == 0 == true,
            "Compares more than 32 bytes char"
        );
        bytes memory otherLongChar = "2234567890123456789012345678901234";
        require(
            longChar.compare(otherLongChar) < 0 == true,
            "Compare long char with difference at start"
        );
    }

    function testSubstring() public pure {
        require(
            keccak256(bytes("hello".substring(0, 0))) == keccak256(bytes("")),
            "Copy 0 bytes"
        );
        require(
            keccak256(bytes("hello".substring(0, 4))) ==
                keccak256(bytes("hell")),
            "Copy substring"
        );
        require(
            keccak256(bytes("hello".substring(1, 4))) ==
                keccak256(bytes("ello")),
            "Copy substring"
        );
        require(
            keccak256(bytes("hello".substring(0, 5))) ==
                keccak256(bytes("hello")),
            "Copy whole string"
        );
    }

    function testReadUint8() public pure {
        require(uint("a".readUint8(0)) == 0x61, "a == 0x61");
        require(uint("ba".readUint8(1)) == 0x61, "a == 0x61");
    }

    function testReadUint16() public pure {
        require(uint("abc".readUint16(1)) == 0x6263, "Read uint 16");
    }

    function testReadUint32() public pure {
        require(uint("abcde".readUint32(1)) == 0x62636465, "Read uint 32");
    }

    function testReadBytes20() public pure {
        require(
            bytes32("abcdefghijklmnopqrstuv".readBytes20(1)) ==
                bytes32(
                    0x62636465666768696a6b6c6d6e6f707172737475000000000000000000000000
                ),
            "readBytes20"
        );
    }

    function testReadBytes32() public pure {
        require(
            "0123456789abcdef0123456789abcdef".readBytes32(0) ==
                bytes32(
                    0x3031323334353637383961626364656630313233343536373839616263646566
                ),
            "readBytes32"
        );
    }

    function testBase32HexDecodeWord() public pure {
        require(
            "C4".base32HexDecodeWord(0, 2) == bytes32(bytes1("a")),
            "Decode 'a'"
        );
        require(
            "C5GG".base32HexDecodeWord(0, 4) == bytes32(bytes2("aa")),
            "Decode 'aa'"
        );
        require(
            "C5GM2".base32HexDecodeWord(0, 5) == bytes32(bytes3("aaa")),
            "Decode 'aaa'"
        );
        require(
            "C5GM2O8".base32HexDecodeWord(0, 7) == bytes32(bytes4("aaaa")),
            "Decode 'aaaa'"
        );
        require(
            "C5GM2OB1".base32HexDecodeWord(0, 8) == bytes32(bytes5("aaaaa")),
            "Decode 'aaaaa'"
        );
        require(
            "c5gm2Ob1".base32HexDecodeWord(0, 8) == bytes32(bytes5("aaaaa")),
            "Decode 'aaaaa' lowercase"
        );
        require(
            "C5H66P35CPJMGQBADDM6QRJFE1ON4SRKELR7EU3PF8".base32HexDecodeWord(
                0,
                42
            ) == bytes32(bytes26("abcdefghijklmnopqrstuvwxyz")),
            "Decode alphabet"
        );
        require(
            "c5h66p35cpjmgqbaddm6qrjfe1on4srkelr7eu3pf8".base32HexDecodeWord(
                0,
                42
            ) == bytes32(bytes26("abcdefghijklmnopqrstuvwxyz")),
            "Decode alphabet lowercase"
        );
        require(
            "C5GM2OB1C5GM2OB1C5GM2OB1C5GM2OB1C5GM2OB1C5GM2OB1C5GG"
                .base32HexDecodeWord(0, 52) ==
                bytes32("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            "Decode 32*'a'"
        );
        require(
            " bst4hlje7r0o8c8p4o8q582lm0ejmiqt\x07matoken\x03xyz\x00"
                .base32HexDecodeWord(1, 32) ==
                bytes32(hex"5f3a48d66e3ec18431192611a2a055b01d3b4b5d"),
            "Decode real bytes32hex"
        );
    }
}
