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

interface ERC20ApprovalInterface {
    function approve(address, uint256) external returns (bool);
}

interface NFTApprovalInterface {
    function setApprovalForAll(address, bool) external;
}

contract EIP1271Wallet {
    bytes4 private constant _EIP_1271_MAGIC_VALUE = 0x1626ba7e;

    address public immutable owner;

    bool public showRevertMessage;

    mapping(bytes32 => bool) public digestApproved;

    bool public isValid;

    constructor(address _owner) {
        owner = _owner;
        showRevertMessage = true;
        isValid = true;
    }

    function setValid(bool valid) external {
        isValid = valid;
    }

    function revertWithMessage(bool showMessage) external {
        showRevertMessage = showMessage;
    }

    function registerDigest(bytes32 digest, bool approved) external {
        digestApproved[digest] = approved;
    }

    function approveERC20(
        ERC20ApprovalInterface token,
        address operator,
        uint256 amount
    ) external {
        if (msg.sender != owner) {
            revert("Only owner");
        }

        token.approve(operator, amount);
    }

    function approveNFT(NFTApprovalInterface token, address operator) external {
        if (msg.sender != owner) {
            revert("Only owner");
        }

        token.setApprovalForAll(operator, true);
    }

    function isValidSignature(
        bytes32 digest,
        bytes memory signature
    ) external view returns (bytes4) {
        if (digestApproved[digest]) {
            return _EIP_1271_MAGIC_VALUE;
        }

        // NOTE: this is obviously not secure, do not use outside of testing.
        if (signature.length == 64) {
            // All signatures of length 64 are OK as long as valid is true
            return isValid ? _EIP_1271_MAGIC_VALUE : bytes4(0xffffffff);
        }

        if (signature.length != 65) {
            revert();
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert();
        }

        if (v != 27 && v != 28) {
            revert();
        }

        address signer = ecrecover(digest, v, r, s);

        if (signer == address(0)) {
            revert();
        }

        if (signer != owner) {
            if (showRevertMessage) {
                revert("BAD SIGNER");
            }

            revert();
        }

        return isValid ? _EIP_1271_MAGIC_VALUE : bytes4(0xffffffff);
    }
}
