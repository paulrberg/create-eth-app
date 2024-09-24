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

contract TestRRUtils {
    using BytesUtils for *;
    using RRUtils for *;

    uint16 constant DNSTYPE_A = 1;
    uint16 constant DNSTYPE_CNAME = 5;
    uint16 constant DNSTYPE_MX = 15;
    uint16 constant DNSTYPE_TEXT = 16;
    uint16 constant DNSTYPE_RRSIG = 46;
    uint16 constant DNSTYPE_TYPE1234 = 1234;

    function testNameLength() public pure {
        require(hex"00".nameLength(0) == 1, "nameLength('.') == 1");
        require(hex"0361626300".nameLength(4) == 1, "nameLength('.') == 1");
        require(hex"0361626300".nameLength(0) == 5, "nameLength('abc.') == 5");
    }

    function testLabelCount() public pure {
        require(hex"00".labelCount(0) == 0, "labelCount('.') == 0");
        require(hex"016100".labelCount(0) == 1, "labelCount('a.') == 1");
        require(
            hex"016201610000".labelCount(0) == 2,
            "labelCount('b.a.') == 2"
        );
        require(
            hex"066574686c61620378797a00".labelCount(6 + 1) == 1,
            "nameLength('(bthlab).xyz.') == 6"
        );
    }

    function testIterateRRs() public pure {
        // a. IN A 3600 127.0.0.1
        // b.a. IN A 3600 192.168.1.1
        bytes
            memory rrs = hex"0161000001000100000e1000047400000101620161000001000100000e100004c0a80101";
        bytes[2] memory names = [bytes(hex"016100"), bytes(hex"0162016100")];
        bytes[2] memory rdatas = [bytes(hex"74000001"), bytes(hex"c0a80101")];
        uint i = 0;
        for (
            RRUtils.RRIterator memory iter = rrs.iterateRRs(0);
            !iter.done();
            iter.next()
        ) {
            require(uint(iter.dnstype) == 1, "Type matches");
            require(uint(iter.class) == 1, "Class matches");
            require(uint(iter.ttl) == 3600, "TTL matches");
            require(
                keccak256(iter.name()) == keccak256(names[i]),
                "Name matches"
            );
            require(
                keccak256(iter.rdata()) == keccak256(rdatas[i]),
                "Rdata matches"
            );
            i++;
        }
        require(i == 2, "Expected 2 records");
    }

    // Canonical ordering https://tools.ietf.org/html/rfc4034#section-6.1
    function testCompareNames() public pure {
        bytes memory bthLabXyz = hex"066274686c61620378797a00";
        bytes memory ethLabXyz = hex"066574686c61620378797a00";
        bytes memory xyz = hex"0378797a00";
        bytes memory a_b_c = hex"01610162016300";
        bytes memory b_b_c = hex"01620162016300";
        bytes memory c = hex"016300";
        bytes memory d = hex"016400";
        bytes memory a_d_c = hex"01610164016300";
        bytes memory b_a_c = hex"01620161016300";
        bytes memory ab_c_d = hex"0261620163016400";
        bytes memory a_c_d = hex"01610163016400";
        bytes
            memory verylong1_eth = hex"223031323334353637383930313233343536373839303132333435363738393031613031303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637380365746800";
        bytes
            memory verylong2_eth = hex"2130313233343536373839303132333435363738393031323334353637383930316131303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637380365746800";

        require(
            hex"0301616100".compareNames(hex"0302616200") < 0,
            "label lengths are correctly checked"
        );
        require(
            a_b_c.compareNames(c) > 0,
            "one name has a difference of >1 label to with the same root name"
        );
        require(
            a_b_c.compareNames(d) < 0,
            "one name has a difference of >1 label to with different root name"
        );
        require(
            a_b_c.compareNames(a_d_c) < 0,
            "two names start the same but have differences in later labels"
        );
        require(
            a_b_c.compareNames(b_a_c) > 0,
            "the first label sorts later, but the first label sorts earlier"
        );
        require(
            ab_c_d.compareNames(a_c_d) > 0,
            "two names where the first label on one is a prefix of the first label on the other"
        );
        require(
            a_b_c.compareNames(b_b_c) < 0,
            "two names where the first label on one is a prefix of the first label on the other"
        );
        require(xyz.compareNames(ethLabXyz) < 0, "xyz comes before ethLab.xyz");
        require(
            bthLabXyz.compareNames(ethLabXyz) < 0,
            "bthLab.xyz comes before ethLab.xyz"
        );
        require(
            bthLabXyz.compareNames(bthLabXyz) == 0,
            "bthLab.xyz and bthLab.xyz are the same"
        );
        require(
            ethLabXyz.compareNames(bthLabXyz) > 0,
            "ethLab.xyz comes after bethLab.xyz"
        );
        require(bthLabXyz.compareNames(xyz) > 0, "bthLab.xyz comes after xyz");

        require(
            verylong1_eth.compareNames(verylong2_eth) > 0,
            "longa.vlong.eth comes after long.vlong.eth"
        );
    }

    function testSerialNumberGt() public pure {
        require(RRUtils.serialNumberGte(1, 0), "1 >= 0");
        require(!RRUtils.serialNumberGte(0, 1), "!(0 <= 1)");
        require(RRUtils.serialNumberGte(0, 0xFFFFFFFF), "0 >= 0xFFFFFFFF");
        require(!RRUtils.serialNumberGte(0xFFFFFFFF, 0), "!(0 <= 0xFFFFFFFF)");
        require(
            RRUtils.serialNumberGte(0x11111111, 0xAAAAAAAA),
            "0x11111111 >= 0xAAAAAAAA"
        );
        require(RRUtils.serialNumberGte(1, 1), "1 >= 1");
    }

    function testKeyTag() public view {
        require(
            hex"0101030803010001a80020a95566ba42e886bb804cda84e47ef56dbd7aec612615552cec906d2116d0ef207028c51554144dfeafe7c7cb8f005dd18234133ac0710a81182ce1fd14ad2283bc83435f9df2f6313251931a176df0da51e54f42e604860dfb359580250f559cc543c4ffd51cbe3de8cfd06719237f9fc47ee729da06835fa452e825e9a18ebc2ecbcf563474652c33cf56a9033bcdf5d973121797ec8089041b6e03a1b72d0a735b984e03687309332324f27c2dba85e9db15e83a0143382e974b0621c18e625ecec907577d9e7bade95241a81ebbe8a901d4d3276e40b114c0a2e6fc38d19c2e6aab02644b2813f575fc21601e0dee49cd9ee96a43103e524d62873d"
                .computeKeytag() == 19036,
            "Invalid keytag"
        );
        require(
            hex"010003050440000003ba2fa05a75e173bede89eb71831ab14035f2408ad09df4d8dc8f8f72e8f13506feaddf7b04cb14958b82966e3420562302c4002bc4fd088432e160519bb14dae82443850c1423e06085710b5caf070d46b7ba7e481414f6a5fe225fdca984c959091645d0cf1c9a1a313d7e7fb7ba60b967b71a65f8cef2c3768e11b081c8fcf"
                .computeKeytag() == 21693,
            "Invalid keytag (2)"
        );
        require(
            hex"0100030503010001bfa54c38d909fabb0f937d70d775ba0df4c0badb09707d995249406950407a621c794c68b186b15dbf8f9f9ea231e9f96414ccda4eceb50b17a9ac6c4bd4b95da04849e96ee791578b703bc9ae184fb1794bac792a0787f693a40f19f523ee6dbd3599dbaaa9a50437926ecf6438845d1d49448962524f2a1a7a36b3a0a1eca3"
                .computeKeytag() == 33630
        );
        require(
            hex"0101030803010001acffb409bcc939f831f7a1e5ec88f7a59255ec53040be432027390a4ce896d6f9086f3c5e177fbfe118163aaec7af1462c47945944c4e2c026be5e98bbcded25978272e1e3e079c5094d573f0e83c92f02b32d3513b1550b826929c80dd0f92cac966d17769fd5867b647c3f38029abdc48152eb8f207159ecc5d232c7c1537c79f4b7ac28ff11682f21681bf6d6aba555032bf6f9f036beb2aaa5b3778d6eebfba6bf9ea191be4ab0caea759e2f773a1f9029c73ecb8d5735b9321db085f1b8e2d8038fe2941992548cee0d67dd4547e11dd63af9c9fc1c5466fb684cf009d7197c2cf79e792ab501e6a8a1ca519af2cb9b5f6367e94c0d47502451357be1b5"
                .computeKeytag() == 20326,
            "Invalid keytag (3)"
        );
    }
}
