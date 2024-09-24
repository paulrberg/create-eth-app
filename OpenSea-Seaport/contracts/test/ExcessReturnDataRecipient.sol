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
  
  // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract ExcessReturnDataRecipient {
    uint256 private revertDataSize;

    function setRevertDataSize(uint256 size) external {
        revertDataSize = size;
    }

    // Code created with the help of Stack Exchange question
    // https://ethereum.stackexchange.com/questions/8086
    // Question by Doug King:
    // https://ethereum.stackexchange.com/users/2041/doug-king
    // Answer by Tjaden Hess:
    // https://ethereum.stackexchange.com/users/131/tjaden-hess
    // Modified to use Yul instead of Solidity and added change of
    // base to convert to natural logarithm
    function ln(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(
                m,
                0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
            )
            mstore(
                add(m, 0x20),
                0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            )
            mstore(
                add(m, 0x40),
                0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
            )
            mstore(
                add(m, 0x60),
                0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            )
            mstore(
                add(m, 0x80),
                0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
            )
            mstore(
                add(m, 0xa0),
                0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            )
            mstore(
                add(m, 0xc0),
                0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
            )
            mstore(
                add(m, 0xe0),
                0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            )
            mstore(0x40, add(m, 0x100))
            let
                magic
            := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let
                shift
            := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(
                        arg,
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )
            y := mul(y, 10000000000000000)
            y := div(y, 14426950408889632)
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        assembly {
            switch gt(y, 3)
            case 1 {
                z := y
                let x := div(add(y, 1), 2)
                for {

                } lt(x, z) {

                } {
                    z := x
                    x := div(add(div(y, x), x), 2)
                }
            }
            case 0 {
                z := 1
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bytes4 magic) {
        magic = this.onERC1155Received.selector;
        if (revertDataSize > 0) {
            uint256 gasToCalculateSqrt = (54 * ln(gasleft())) + 1200;
            uint256 w = (sqrt(
                2048 * (gasleft() - gasToCalculateSqrt) + 9431040
            ) - 3072) / 4;

            assembly {
                let size := mul(w, 32)
                calldatacopy(0, 0, mul(w, 32))
                revert(0, size)
            }
        }
    }

    receive() external payable {
        if (revertDataSize > 0) {
            uint256 gasToCalculateSqrt = (54 * ln(gasleft())) + 1200;
            uint256 w = (sqrt(
                2048 * (gasleft() - gasToCalculateSqrt) + 9431040
            ) - 3072) / 2;

            assembly {
                let size := mul(w, 32)
                calldatacopy(0, 0, mul(w, 32))
                revert(0, size)
            }
        }
    }
}
