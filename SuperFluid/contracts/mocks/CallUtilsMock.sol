/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/protocols/SuperFluid?utm=code
  */
  
  // SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { CallUtils } from "../libs/CallUtils.sol";

contract CallUtilsMock {
    error Custom();
    error CustomVal(uint256);

    enum Gm { Ngmi }

    uint[] public a;
    // case 1: catch all
    function revertEmpty() public pure {
        // solhint-disable-next-line reason-string
        revert();
    }
    // case 2: (Panic(uint256)) 0x01
    function revertAssert() public pure {
        assert(false);
    }
    // case 2: (Panic(uint256)) 0x11
    function revertOverflow() public pure returns(uint) {
        uint b = type(uint256).max + 1;
        return b;
    }
    // case 2: (Panic(uint256)) 0x12
    function revertDivByZero() public pure {
        int z = 0;
        int b = 0;
        b = z / b;
    }
    // case 2: (Panic(uint256)) 0x21
    function revertEnum() public pure {
        uint max = type(uint).max;
        Gm(max);
    }
    // case 2: (Panic(uint256)) 0x31
    function revertPop() public {
        a.pop();
    }
    // case 2: (Panic(uint256)) 0x32
    function revertArrayAccess() public view {
        a[type(uint).max];
    }
    // case 2: (Panic(uint256)) 0x41
    function revertBigArray() public pure returns(uint8[] memory) {
        uint8[] memory d = new uint8[](type(uint256).max);
        return d;
    }
    // case 2: (Panic(uint256)) 0x51
    function revertZeroInitializedFunctionPointer() external pure returns (int) {
        // Variable containing a function pointer
        function (int, int) internal pure returns (int) funcPtr;

        // This call will fail because funcPtr is still a zero-initialized function pointer
        return funcPtr(4, 5);
    }

    // case 3: Error(string)
    function revertString() public pure {
        revert("gm");
    }
    // case 4: custom errors
    function revertCustom() public pure {
        revert Custom();
    }
    function revertCustomVal() public pure {
        revert CustomVal(26);
    }

    function revertTest(string memory funcSig) public {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSignature(funcSig));
        if (!success) {
            CallUtils.revertFromReturnedData(data);
        }
    }
}
