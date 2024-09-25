/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/Uniswap-V4?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "Uniswap-V4/forge-std/Test.sol";
import {GasSnapshot} from "Uniswap-V4/forge-gas-snapshot/GasSnapshot.sol";
import {LPFeeLibrary} from "../../src/libraries/LPFeeLibrary.sol";
import {ProtocolFeeLibrary} from "../../src/libraries/ProtocolFeeLibrary.sol";

contract ProtocolFeeLibraryTest is Test, GasSnapshot {
    function test_getZeroForOneFee() public pure {
        uint24 fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE - 1) << 12 | ProtocolFeeLibrary.MAX_PROTOCOL_FEE;
        assertEq(ProtocolFeeLibrary.getZeroForOneFee(fee), uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE));
    }

    function test_fuzz_getZeroForOneFee(uint24 fee) public pure {
        assertEq(ProtocolFeeLibrary.getZeroForOneFee(fee), fee % 4096);
    }

    function test_getOneForZeroFee() public pure {
        uint24 fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE - 1) << 12 | ProtocolFeeLibrary.MAX_PROTOCOL_FEE;
        assertEq(ProtocolFeeLibrary.getOneForZeroFee(fee), uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE - 1));
    }

    function test_fuzz_getOneForZeroFee(uint24 fee) public pure {
        assertEq(ProtocolFeeLibrary.getOneForZeroFee(fee), fee >> 12);
    }

    function test_isValidProtocolFee_fee() public pure {
        uint24 fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE + 1) << 12 | ProtocolFeeLibrary.MAX_PROTOCOL_FEE;
        assertFalse(ProtocolFeeLibrary.isValidProtocolFee(fee));

        fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE) << 12 | (ProtocolFeeLibrary.MAX_PROTOCOL_FEE + 1);
        assertFalse(ProtocolFeeLibrary.isValidProtocolFee(fee));

        fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE + 1) << 12 | (ProtocolFeeLibrary.MAX_PROTOCOL_FEE + 1);
        assertFalse(ProtocolFeeLibrary.isValidProtocolFee(fee));

        fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE) << 12 | ProtocolFeeLibrary.MAX_PROTOCOL_FEE;
        assertTrue(ProtocolFeeLibrary.isValidProtocolFee(fee));

        fee = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE - 1) << 12 | ProtocolFeeLibrary.MAX_PROTOCOL_FEE - 1;
        assertTrue(ProtocolFeeLibrary.isValidProtocolFee(fee));

        fee = uint24(0) << 12 | uint24(0);
        assertTrue(ProtocolFeeLibrary.isValidProtocolFee(fee));
    }

    function test_fuzz_isValidProtocolFee(uint24 fee) public pure {
        if ((fee >> 12 > ProtocolFeeLibrary.MAX_PROTOCOL_FEE) || (fee % 4096 > ProtocolFeeLibrary.MAX_PROTOCOL_FEE)) {
            assertFalse(ProtocolFeeLibrary.isValidProtocolFee(fee));
        } else {
            assertTrue(ProtocolFeeLibrary.isValidProtocolFee(fee));
        }
    }

    function test_calculateSwapFee() public pure {
        assertEq(
            ProtocolFeeLibrary.calculateSwapFee(uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE), LPFeeLibrary.MAX_LP_FEE),
            LPFeeLibrary.MAX_LP_FEE
        );
        assertEq(ProtocolFeeLibrary.calculateSwapFee(uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE), 3000), 3997);
        assertEq(
            ProtocolFeeLibrary.calculateSwapFee(uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE), 0),
            ProtocolFeeLibrary.MAX_PROTOCOL_FEE
        );
        assertEq(ProtocolFeeLibrary.calculateSwapFee(0, 0), 0);
        assertEq(ProtocolFeeLibrary.calculateSwapFee(0, 1000), 1000);
    }

    function test_fuzz_calculateSwapFee(uint24 protocolFee, uint24 lpFee) public pure {
        protocolFee = uint24(bound(protocolFee, 0, ProtocolFeeLibrary.MAX_PROTOCOL_FEE));
        lpFee = uint24(bound(lpFee, 0, LPFeeLibrary.MAX_LP_FEE));
        uint24 swapFee = ProtocolFeeLibrary.calculateSwapFee(protocolFee, lpFee);
        // if lp fee is not the max, the swap fee should never be the max since the protocol fee is taken off first and then the lp fee is taken from the remaining amount
        if (lpFee < LPFeeLibrary.MAX_LP_FEE) {
            assertLt(swapFee, LPFeeLibrary.MAX_LP_FEE);
        }
        assertGe(swapFee, lpFee);

        uint256 expectedSwapFee =
            protocolFee + lpFee * uint256(LPFeeLibrary.MAX_LP_FEE - protocolFee) / LPFeeLibrary.MAX_LP_FEE;
        assertEq(swapFee, uint24(expectedSwapFee));
    }

    function test_calculateSwapFee_gas() public {
        uint24 self = uint24(ProtocolFeeLibrary.MAX_PROTOCOL_FEE);
        uint24 lpFee = LPFeeLibrary.MAX_LP_FEE;
        snapStart("calculateSwapFee");
        ProtocolFeeLibrary.calculateSwapFee(self, lpFee);
        snapEnd();
    }
}
