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
pragma solidity ^0.8.13;

import "../../SeaportStructs.sol";
import "../../lib/types/MatchComponentType.sol";

library MatchArrays {
    function FulfillmentComponents(FulfillmentComponent memory a)
        internal
        pure
        returns (FulfillmentComponent[] memory)
    {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](1);
        arr[0] = a;
        return arr;
    }

    function FulfillmentComponents(FulfillmentComponent memory a, FulfillmentComponent memory b)
        internal
        pure
        returns (FulfillmentComponent[] memory)
    {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e,
        FulfillmentComponent memory f
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentComponents(
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e,
        FulfillmentComponent memory f,
        FulfillmentComponent memory g
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(uint256 maxLength, FulfillmentComponent memory a)
        internal
        pure
        returns (FulfillmentComponent[] memory)
    {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 1)
        }
        arr[0] = a;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent memory a,
        FulfillmentComponent memory b
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 2)
        }
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 3)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 4)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 5)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e,
        FulfillmentComponent memory f
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 6)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentComponentsWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent memory a,
        FulfillmentComponent memory b,
        FulfillmentComponent memory c,
        FulfillmentComponent memory d,
        FulfillmentComponent memory e,
        FulfillmentComponent memory f,
        FulfillmentComponent memory g
    ) internal pure returns (FulfillmentComponent[] memory) {
        FulfillmentComponent[] memory arr = new FulfillmentComponent[](
            maxLength
        );
        assembly {
            mstore(arr, 7)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function extend(FulfillmentComponent[] memory arr1, FulfillmentComponent[] memory arr2)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        uint256 length1 = arr1.length;
        uint256 length2 = arr2.length;
        newArr = new FulfillmentComponent[](length1 + length2);
        for (uint256 i = 0; i < length1;) {
            newArr[i] = arr1[i];
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < arr2.length;) {
            uint256 j;
            unchecked {
                j = i + length1;
            }
            newArr[j] = arr2[i];
            unchecked {
                ++i;
            }
        }
    }

    function allocateFulfillmentComponents(uint256 length) internal pure returns (FulfillmentComponent[] memory arr) {
        arr = new FulfillmentComponent[](length);
        assembly {
            mstore(arr, 0)
        }
    }

    function truncate(FulfillmentComponent[] memory arr, uint256 newLength)
        internal
        pure
        returns (FulfillmentComponent[] memory _arr)
    {
        // truncate the array
        assembly {
            let oldLength := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), gt(newLength, oldLength))
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function truncateUnsafe(FulfillmentComponent[] memory arr, uint256 newLength)
        internal
        pure
        returns (FulfillmentComponent[] memory _arr)
    {
        // truncate the array
        assembly {
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function append(FulfillmentComponent[] memory arr, FulfillmentComponent memory value)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        uint256 length = arr.length;
        newArr = new FulfillmentComponent[](length + 1);
        newArr[length] = value;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function appendUnsafe(FulfillmentComponent[] memory arr, FulfillmentComponent memory value)
        internal
        pure
        returns (FulfillmentComponent[] memory modifiedArr)
    {
        uint256 length = arr.length;
        modifiedArr = arr;
        assembly {
            mstore(modifiedArr, add(length, 1))
            mstore(add(modifiedArr, shl(5, add(length, 1))), value)
        }
    }

    function copy(FulfillmentComponent[] memory arr) internal pure returns (FulfillmentComponent[] memory newArr) {
        uint256 length = arr.length;
        newArr = new FulfillmentComponent[](length);
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function copyAndResize(FulfillmentComponent[] memory arr, uint256 newLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](newLength);
        uint256 length = arr.length;
        // allow shrinking a copy without copying extra members
        length = (length > newLength) ? newLength : length;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        // TODO: consider writing 0-pointer to the rest of the array if longer for dynamic elements
    }

    function copyAndAllocate(FulfillmentComponent[] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        uint256 originalLength = arr.length;
        for (uint256 i = 0; i < originalLength;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, originalLength)
        }
    }

    function pop(FulfillmentComponent[] memory arr) internal pure returns (FulfillmentComponent memory value) {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popUnsafe(FulfillmentComponent[] memory arr) internal pure returns (FulfillmentComponent memory value) {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popLeft(FulfillmentComponent[] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr, FulfillmentComponent memory value)
    {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function popLeftUnsafe(FulfillmentComponent[] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr, FulfillmentComponent memory value)
    {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function fromFixed(FulfillmentComponent[1] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](1);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[1] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 1)
        }
    }

    function fromFixed(FulfillmentComponent[2] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](2);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[2] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 2)
        }
    }

    function fromFixed(FulfillmentComponent[3] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](3);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[3] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 3)
        }
    }

    function fromFixed(FulfillmentComponent[4] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](4);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[4] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 4)
        }
    }

    function fromFixed(FulfillmentComponent[5] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](5);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[5] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 5)
        }
    }

    function fromFixed(FulfillmentComponent[6] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](6);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[6] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 6)
        }
    }

    function fromFixed(FulfillmentComponent[7] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](7);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[7] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[] memory newArr)
    {
        newArr = new FulfillmentComponent[](maxLength);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 7)
        }
    }

    function FulfillmentComponentArrays(FulfillmentComponent[] memory a)
        internal
        pure
        returns (FulfillmentComponent[][] memory)
    {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](1);
        arr[0] = a;
        return arr;
    }

    function FulfillmentComponentArrays(FulfillmentComponent[] memory a, FulfillmentComponent[] memory b)
        internal
        pure
        returns (FulfillmentComponent[][] memory)
    {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e,
        FulfillmentComponent[] memory f
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentComponentArrays(
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e,
        FulfillmentComponent[] memory f,
        FulfillmentComponent[] memory g
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(uint256 maxLength, FulfillmentComponent[] memory a)
        internal
        pure
        returns (FulfillmentComponent[][] memory)
    {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 1)
        }
        arr[0] = a;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 2)
        }
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 3)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 4)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 5)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e,
        FulfillmentComponent[] memory f
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 6)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentComponentArraysWithMaxLength(
        uint256 maxLength,
        FulfillmentComponent[] memory a,
        FulfillmentComponent[] memory b,
        FulfillmentComponent[] memory c,
        FulfillmentComponent[] memory d,
        FulfillmentComponent[] memory e,
        FulfillmentComponent[] memory f,
        FulfillmentComponent[] memory g
    ) internal pure returns (FulfillmentComponent[][] memory) {
        FulfillmentComponent[][] memory arr = new FulfillmentComponent[][](
            maxLength
        );
        assembly {
            mstore(arr, 7)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function extend(FulfillmentComponent[][] memory arr1, FulfillmentComponent[][] memory arr2)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        uint256 length1 = arr1.length;
        uint256 length2 = arr2.length;
        newArr = new FulfillmentComponent[][](length1 + length2);
        for (uint256 i = 0; i < length1;) {
            newArr[i] = arr1[i];
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < arr2.length;) {
            uint256 j;
            unchecked {
                j = i + length1;
            }
            newArr[j] = arr2[i];
            unchecked {
                ++i;
            }
        }
    }

    function allocateFulfillmentComponentArrays(uint256 length)
        internal
        pure
        returns (FulfillmentComponent[][] memory arr)
    {
        arr = new FulfillmentComponent[][](length);
        assembly {
            mstore(arr, 0)
        }
    }

    function truncate(FulfillmentComponent[][] memory arr, uint256 newLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory _arr)
    {
        // truncate the array
        assembly {
            let oldLength := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), gt(newLength, oldLength))
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function truncateUnsafe(FulfillmentComponent[][] memory arr, uint256 newLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory _arr)
    {
        // truncate the array
        assembly {
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function append(FulfillmentComponent[][] memory arr, FulfillmentComponent[] memory value)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        uint256 length = arr.length;
        newArr = new FulfillmentComponent[][](length + 1);
        newArr[length] = value;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function appendUnsafe(FulfillmentComponent[][] memory arr, FulfillmentComponent[] memory value)
        internal
        pure
        returns (FulfillmentComponent[][] memory modifiedArr)
    {
        uint256 length = arr.length;
        modifiedArr = arr;
        assembly {
            mstore(modifiedArr, add(length, 1))
            mstore(add(modifiedArr, shl(5, add(length, 1))), value)
        }
    }

    function copy(FulfillmentComponent[][] memory arr) internal pure returns (FulfillmentComponent[][] memory newArr) {
        uint256 length = arr.length;
        newArr = new FulfillmentComponent[][](length);
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function copyAndResize(FulfillmentComponent[][] memory arr, uint256 newLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](newLength);
        uint256 length = arr.length;
        // allow shrinking a copy without copying extra members
        length = (length > newLength) ? newLength : length;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        // TODO: consider writing 0-pointer to the rest of the array if longer for dynamic elements
    }

    function copyAndAllocate(FulfillmentComponent[][] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        uint256 originalLength = arr.length;
        for (uint256 i = 0; i < originalLength;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, originalLength)
        }
    }

    function pop(FulfillmentComponent[][] memory arr) internal pure returns (FulfillmentComponent[] memory value) {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popUnsafe(FulfillmentComponent[][] memory arr)
        internal
        pure
        returns (FulfillmentComponent[] memory value)
    {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popLeft(FulfillmentComponent[][] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr, FulfillmentComponent[] memory value)
    {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function popLeftUnsafe(FulfillmentComponent[][] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr, FulfillmentComponent[] memory value)
    {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function fromFixed(FulfillmentComponent[][1] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](1);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][1] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 1)
        }
    }

    function fromFixed(FulfillmentComponent[][2] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](2);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][2] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 2)
        }
    }

    function fromFixed(FulfillmentComponent[][3] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](3);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][3] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 3)
        }
    }

    function fromFixed(FulfillmentComponent[][4] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](4);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][4] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 4)
        }
    }

    function fromFixed(FulfillmentComponent[][5] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](5);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][5] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 5)
        }
    }

    function fromFixed(FulfillmentComponent[][6] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](6);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][6] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 6)
        }
    }

    function fromFixed(FulfillmentComponent[][7] memory arr)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](7);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(FulfillmentComponent[][7] memory arr, uint256 maxLength)
        internal
        pure
        returns (FulfillmentComponent[][] memory newArr)
    {
        newArr = new FulfillmentComponent[][](maxLength);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 7)
        }
    }

    function Fulfillments(Fulfillment memory a) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](1);
        arr[0] = a;
        return arr;
    }

    function Fulfillments(Fulfillment memory a, Fulfillment memory b) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function Fulfillments(Fulfillment memory a, Fulfillment memory b, Fulfillment memory c)
        internal
        pure
        returns (Fulfillment[] memory)
    {
        Fulfillment[] memory arr = new Fulfillment[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function Fulfillments(Fulfillment memory a, Fulfillment memory b, Fulfillment memory c, Fulfillment memory d)
        internal
        pure
        returns (Fulfillment[] memory)
    {
        Fulfillment[] memory arr = new Fulfillment[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e,
        Fulfillment memory f
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function Fulfillments(
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e,
        Fulfillment memory f,
        Fulfillment memory g
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function FulfillmentsWithMaxLength(uint256 maxLength, Fulfillment memory a)
        internal
        pure
        returns (Fulfillment[] memory)
    {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 1)
        }
        arr[0] = a;
        return arr;
    }

    function FulfillmentsWithMaxLength(uint256 maxLength, Fulfillment memory a, Fulfillment memory b)
        internal
        pure
        returns (Fulfillment[] memory)
    {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 2)
        }
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function FulfillmentsWithMaxLength(
        uint256 maxLength,
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 3)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function FulfillmentsWithMaxLength(
        uint256 maxLength,
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 4)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function FulfillmentsWithMaxLength(
        uint256 maxLength,
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 5)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function FulfillmentsWithMaxLength(
        uint256 maxLength,
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e,
        Fulfillment memory f
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 6)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function FulfillmentsWithMaxLength(
        uint256 maxLength,
        Fulfillment memory a,
        Fulfillment memory b,
        Fulfillment memory c,
        Fulfillment memory d,
        Fulfillment memory e,
        Fulfillment memory f,
        Fulfillment memory g
    ) internal pure returns (Fulfillment[] memory) {
        Fulfillment[] memory arr = new Fulfillment[](maxLength);
        assembly {
            mstore(arr, 7)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function extend(Fulfillment[] memory arr1, Fulfillment[] memory arr2)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        uint256 length1 = arr1.length;
        uint256 length2 = arr2.length;
        newArr = new Fulfillment[](length1 + length2);
        for (uint256 i = 0; i < length1;) {
            newArr[i] = arr1[i];
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < arr2.length;) {
            uint256 j;
            unchecked {
                j = i + length1;
            }
            newArr[j] = arr2[i];
            unchecked {
                ++i;
            }
        }
    }

    function allocateFulfillments(uint256 length) internal pure returns (Fulfillment[] memory arr) {
        arr = new Fulfillment[](length);
        assembly {
            mstore(arr, 0)
        }
    }

    function truncate(Fulfillment[] memory arr, uint256 newLength) internal pure returns (Fulfillment[] memory _arr) {
        // truncate the array
        assembly {
            let oldLength := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), gt(newLength, oldLength))
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function truncateUnsafe(Fulfillment[] memory arr, uint256 newLength)
        internal
        pure
        returns (Fulfillment[] memory _arr)
    {
        // truncate the array
        assembly {
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function append(Fulfillment[] memory arr, Fulfillment memory value)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        uint256 length = arr.length;
        newArr = new Fulfillment[](length + 1);
        newArr[length] = value;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function appendUnsafe(Fulfillment[] memory arr, Fulfillment memory value)
        internal
        pure
        returns (Fulfillment[] memory modifiedArr)
    {
        uint256 length = arr.length;
        modifiedArr = arr;
        assembly {
            mstore(modifiedArr, add(length, 1))
            mstore(add(modifiedArr, shl(5, add(length, 1))), value)
        }
    }

    function copy(Fulfillment[] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        uint256 length = arr.length;
        newArr = new Fulfillment[](length);
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function copyAndResize(Fulfillment[] memory arr, uint256 newLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](newLength);
        uint256 length = arr.length;
        // allow shrinking a copy without copying extra members
        length = (length > newLength) ? newLength : length;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        // TODO: consider writing 0-pointer to the rest of the array if longer for dynamic elements
    }

    function copyAndAllocate(Fulfillment[] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        uint256 originalLength = arr.length;
        for (uint256 i = 0; i < originalLength;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, originalLength)
        }
    }

    function pop(Fulfillment[] memory arr) internal pure returns (Fulfillment memory value) {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popUnsafe(Fulfillment[] memory arr) internal pure returns (Fulfillment memory value) {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popLeft(Fulfillment[] memory arr)
        internal
        pure
        returns (Fulfillment[] memory newArr, Fulfillment memory value)
    {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function popLeftUnsafe(Fulfillment[] memory arr)
        internal
        pure
        returns (Fulfillment[] memory newArr, Fulfillment memory value)
    {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function fromFixed(Fulfillment[1] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](1);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[1] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 1)
        }
    }

    function fromFixed(Fulfillment[2] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](2);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[2] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 2)
        }
    }

    function fromFixed(Fulfillment[3] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](3);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[3] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 3)
        }
    }

    function fromFixed(Fulfillment[4] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](4);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[4] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 4)
        }
    }

    function fromFixed(Fulfillment[5] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](5);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[5] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 5)
        }
    }

    function fromFixed(Fulfillment[6] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](6);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[6] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 6)
        }
    }

    function fromFixed(Fulfillment[7] memory arr) internal pure returns (Fulfillment[] memory newArr) {
        newArr = new Fulfillment[](7);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(Fulfillment[7] memory arr, uint256 maxLength)
        internal
        pure
        returns (Fulfillment[] memory newArr)
    {
        newArr = new Fulfillment[](maxLength);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 7)
        }
    }

    function MatchComponents(MatchComponent memory a) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](1);
        arr[0] = a;
        return arr;
    }

    function MatchComponents(MatchComponent memory a, MatchComponent memory b)
        internal
        pure
        returns (MatchComponent[] memory)
    {
        MatchComponent[] memory arr = new MatchComponent[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function MatchComponents(MatchComponent memory a, MatchComponent memory b, MatchComponent memory c)
        internal
        pure
        returns (MatchComponent[] memory)
    {
        MatchComponent[] memory arr = new MatchComponent[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function MatchComponents(
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function MatchComponents(
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d,
        MatchComponent memory e
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function MatchComponents(
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d,
        MatchComponent memory e,
        MatchComponent memory f
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function MatchComponents(
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d,
        MatchComponent memory e,
        MatchComponent memory f,
        MatchComponent memory g
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function MatchComponentsWithMaxLength(uint256 maxLength, MatchComponent memory a)
        internal
        pure
        returns (MatchComponent[] memory)
    {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 1)
        }
        arr[0] = a;
        return arr;
    }

    function MatchComponentsWithMaxLength(uint256 maxLength, MatchComponent memory a, MatchComponent memory b)
        internal
        pure
        returns (MatchComponent[] memory)
    {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 2)
        }
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function MatchComponentsWithMaxLength(
        uint256 maxLength,
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 3)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function MatchComponentsWithMaxLength(
        uint256 maxLength,
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 4)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function MatchComponentsWithMaxLength(
        uint256 maxLength,
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d,
        MatchComponent memory e
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 5)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function MatchComponentsWithMaxLength(
        uint256 maxLength,
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d,
        MatchComponent memory e,
        MatchComponent memory f
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 6)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function MatchComponentsWithMaxLength(
        uint256 maxLength,
        MatchComponent memory a,
        MatchComponent memory b,
        MatchComponent memory c,
        MatchComponent memory d,
        MatchComponent memory e,
        MatchComponent memory f,
        MatchComponent memory g
    ) internal pure returns (MatchComponent[] memory) {
        MatchComponent[] memory arr = new MatchComponent[](maxLength);
        assembly {
            mstore(arr, 7)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function extend(MatchComponent[] memory arr1, MatchComponent[] memory arr2)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        uint256 length1 = arr1.length;
        uint256 length2 = arr2.length;
        newArr = new MatchComponent[](length1 + length2);
        for (uint256 i = 0; i < length1;) {
            newArr[i] = arr1[i];
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < arr2.length;) {
            uint256 j;
            unchecked {
                j = i + length1;
            }
            newArr[j] = arr2[i];
            unchecked {
                ++i;
            }
        }
    }

    function allocateMatchComponents(uint256 length) internal pure returns (MatchComponent[] memory arr) {
        arr = new MatchComponent[](length);
        assembly {
            mstore(arr, 0)
        }
    }

    function truncate(MatchComponent[] memory arr, uint256 newLength)
        internal
        pure
        returns (MatchComponent[] memory _arr)
    {
        // truncate the array
        assembly {
            let oldLength := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), gt(newLength, oldLength))
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function truncateUnsafe(MatchComponent[] memory arr, uint256 newLength)
        internal
        pure
        returns (MatchComponent[] memory _arr)
    {
        // truncate the array
        assembly {
            mstore(arr, newLength)
            _arr := arr
        }
    }

    function append(MatchComponent[] memory arr, MatchComponent memory value)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        uint256 length = arr.length;
        newArr = new MatchComponent[](length + 1);
        newArr[length] = value;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function appendUnsafe(MatchComponent[] memory arr, MatchComponent memory value)
        internal
        pure
        returns (MatchComponent[] memory modifiedArr)
    {
        uint256 length = arr.length;
        modifiedArr = arr;
        assembly {
            mstore(modifiedArr, add(length, 1))
            mstore(add(modifiedArr, shl(5, add(length, 1))), value)
        }
    }

    function copy(MatchComponent[] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        uint256 length = arr.length;
        newArr = new MatchComponent[](length);
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function copyAndResize(MatchComponent[] memory arr, uint256 newLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](newLength);
        uint256 length = arr.length;
        // allow shrinking a copy without copying extra members
        length = (length > newLength) ? newLength : length;
        for (uint256 i = 0; i < length;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        // TODO: consider writing 0-pointer to the rest of the array if longer for dynamic elements
    }

    function copyAndAllocate(MatchComponent[] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        uint256 originalLength = arr.length;
        for (uint256 i = 0; i < originalLength;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, originalLength)
        }
    }

    function pop(MatchComponent[] memory arr) internal pure returns (MatchComponent memory value) {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popUnsafe(MatchComponent[] memory arr) internal pure returns (MatchComponent memory value) {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, shl(5, length)))
            mstore(arr, sub(length, 1))
        }
    }

    function popLeft(MatchComponent[] memory arr)
        internal
        pure
        returns (MatchComponent[] memory newArr, MatchComponent memory value)
    {
        assembly {
            let length := mload(arr)
            returndatacopy(returndatasize(), returndatasize(), iszero(length))
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function popLeftUnsafe(MatchComponent[] memory arr)
        internal
        pure
        returns (MatchComponent[] memory newArr, MatchComponent memory value)
    {
        // This function is unsafe because it does not check if the array is empty.
        assembly {
            let length := mload(arr)
            value := mload(add(arr, 0x20))
            newArr := add(arr, 0x20)
            mstore(newArr, sub(length, 1))
        }
    }

    function fromFixed(MatchComponent[1] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](1);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[1] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 1;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 1)
        }
    }

    function fromFixed(MatchComponent[2] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](2);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[2] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 2;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 2)
        }
    }

    function fromFixed(MatchComponent[3] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](3);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[3] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 3;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 3)
        }
    }

    function fromFixed(MatchComponent[4] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](4);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[4] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 4;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 4)
        }
    }

    function fromFixed(MatchComponent[5] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](5);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[5] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 5;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 5)
        }
    }

    function fromFixed(MatchComponent[6] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](6);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[6] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 6;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 6)
        }
    }

    function fromFixed(MatchComponent[7] memory arr) internal pure returns (MatchComponent[] memory newArr) {
        newArr = new MatchComponent[](7);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function fromFixedWithMaxLength(MatchComponent[7] memory arr, uint256 maxLength)
        internal
        pure
        returns (MatchComponent[] memory newArr)
    {
        newArr = new MatchComponent[](maxLength);
        for (uint256 i = 0; i < 7;) {
            newArr[i] = arr[i];
            unchecked {
                ++i;
            }
        }
        assembly {
            mstore(newArr, 7)
        }
    }

    function uints(uint256 a) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](1);
        arr[0] = a;
        return arr;
    }

    function uints(uint256 a, uint256 b) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function uints(uint256 a, uint256 b, uint256 c) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function uints(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function uints(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function uints(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function uints(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 g)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function uintsWithMaxLength(uint256 maxLength, uint256 a) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 1)
        }
        arr[0] = a;
        return arr;
    }

    function uintsWithMaxLength(uint256 maxLength, uint256 a, uint256 b) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 2)
        }
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function uintsWithMaxLength(uint256 maxLength, uint256 a, uint256 b, uint256 c)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 3)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function uintsWithMaxLength(uint256 maxLength, uint256 a, uint256 b, uint256 c, uint256 d)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 4)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function uintsWithMaxLength(uint256 maxLength, uint256 a, uint256 b, uint256 c, uint256 d, uint256 e)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 5)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function uintsWithMaxLength(uint256 maxLength, uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 6)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function uintsWithMaxLength(
        uint256 maxLength,
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e,
        uint256 f,
        uint256 g
    ) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint[](maxLength);
        assembly {
            mstore(arr, 7)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function allocateUints(uint256 length) internal pure returns (uint256[] memory arr) {
        arr = new uint[](length);
        assembly {
            mstore(arr, 0)
        }
    }

    function ints(int256 a) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](1);
        arr[0] = a;
        return arr;
    }

    function ints(int256 a, int256 b) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](2);
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function ints(int256 a, int256 b, int256 c) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](3);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function ints(int256 a, int256 b, int256 c, int256 d) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function ints(int256 a, int256 b, int256 c, int256 d, int256 e) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](5);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function ints(int256 a, int256 b, int256 c, int256 d, int256 e, int256 f) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](6);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function ints(int256 a, int256 b, int256 c, int256 d, int256 e, int256 f, int256 g)
        internal
        pure
        returns (int256[] memory)
    {
        int256[] memory arr = new int[](7);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 1)
        }
        arr[0] = a;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a, int256 b) internal pure returns (int256[] memory) {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 2)
        }
        arr[0] = a;
        arr[1] = b;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a, int256 b, int256 c)
        internal
        pure
        returns (int256[] memory)
    {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 3)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a, int256 b, int256 c, int256 d)
        internal
        pure
        returns (int256[] memory)
    {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 4)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a, int256 b, int256 c, int256 d, int256 e)
        internal
        pure
        returns (int256[] memory)
    {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 5)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a, int256 b, int256 c, int256 d, int256 e, int256 f)
        internal
        pure
        returns (int256[] memory)
    {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 6)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        return arr;
    }

    function intsWithMaxLength(uint256 maxLength, int256 a, int256 b, int256 c, int256 d, int256 e, int256 f, int256 g)
        internal
        pure
        returns (int256[] memory)
    {
        int256[] memory arr = new int[](maxLength);
        assembly {
            mstore(arr, 7)
        }
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        arr[4] = e;
        arr[5] = f;
        arr[6] = g;
        return arr;
    }

    function allocateInts(uint256 length) internal pure returns (int256[] memory arr) {
        arr = new int[](length);
        assembly {
            mstore(arr, 0)
        }
    }

    function amountKey(MatchComponent memory component) internal pure returns (uint256) {
        return component.amount;
    }

    function indexKey(MatchComponent memory component) internal pure returns (uint256) {
        return (component.orderIndex << 8) | component.itemIndex;
    }

    function sortByAmount(MatchComponent[] memory components) internal pure {
        sort(components, amountKey);
    }

    function sortByIndex(MatchComponent[] memory components) internal pure {
        sort(components, indexKey);
    }

    // Sorts the array in-place with intro-quicksort.
    function sort(MatchComponent[] memory a, function(MatchComponent memory) internal pure returns (uint256) accessor)
        internal
        pure
    {
        if (a.length < 2) {
            return;
        }

        uint256[] memory stack = new uint256[](2 * a.length);
        uint256 stackIndex = 0;

        uint256 l = 0;
        uint256 h = a.length - 1;

        stack[stackIndex++] = l;
        stack[stackIndex++] = h;

        while (stackIndex > 0) {
            h = stack[--stackIndex];
            l = stack[--stackIndex];

            if (h - l <= 12) {
                // Insertion sort for small subarrays
                for (uint256 i = l + 1; i <= h; i++) {
                    MatchComponent memory k = a[i];
                    uint256 j = i;
                    while (j > l && accessor(a[j - 1]) > accessor(k)) {
                        a[j] = a[j - 1];
                        j--;
                    }
                    a[j] = k;
                }
            } else {
                // Intro-Quicksort
                uint256 p = (l + h) / 2;

                // Median of 3
                if (accessor(a[l]) > accessor(a[p])) {
                    (a[l], a[p]) = (a[p], a[l]);
                }
                if (accessor(a[l]) > accessor(a[h])) {
                    (a[l], a[h]) = (a[h], a[l]);
                }
                if (accessor(a[p]) > accessor(a[h])) {
                    (a[p], a[h]) = (a[h], a[p]);
                }

                uint256 pivot = accessor(a[p]);
                uint256 i = l;
                uint256 j = h;

                while (i <= j) {
                    while (accessor(a[i]) < pivot) {
                        i++;
                    }
                    while (accessor(a[j]) > pivot) {
                        j--;
                    }
                    if (i <= j) {
                        (a[i], a[j]) = (a[j], a[i]);
                        i++;
                        j--;
                    }
                }

                if (j > l) {
                    stack[stackIndex++] = l;
                    stack[stackIndex++] = j;
                }
                if (i < h) {
                    stack[stackIndex++] = i;
                    stack[stackIndex++] = h;
                }
            }
        }
    }
}
