# Solidity API

## IERC721Receiver

_Interface for any contract that wants to support safeTransfers
from ERC721 asset contracts._

### Contract
IERC721Receiver : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Interface for any contract that wants to support safeTransfers
from ERC721 asset contracts.

 --- 
### Functions:
### onERC721Received

```solidity
function onERC721Received(address operator, address from, uint256 tokenId, bytes data) external returns (bytes4)
```

_Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
by `operator` from `from`, this function is called.

It must return its Solidity selector to confirm the token transfer.
If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.

The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`._

## IERC165

_Interface of the ERC165 standard, as defined in the
https://eips.ethereum.org/EIPS/eip-165[EIP].

Implementers can declare support of contract interfaces, which can then be
queried by others ({ERC165Checker}).

For an implementation, see {ERC165}._

### Contract
IERC165 : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Interface of the ERC165 standard, as defined in the
https://eips.ethereum.org/EIPS/eip-165[EIP].

Implementers can declare support of contract interfaces, which can then be
queried by others ({ERC165Checker}).

For an implementation, see {ERC165}.

 --- 
### Functions:
### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

## IERC1155Receiver

__Available since v3.1.__

### Contract
IERC1155Receiver : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

_Available since v3.1._

 --- 
### Functions:
### onERC1155Received

```solidity
function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes data) external returns (bytes4)
```

_Handles the receipt of a single ERC1155 token type. This function is
called at the end of a `safeTransferFrom` after the balance has been updated.

NOTE: To accept the transfer, this must return
`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
(i.e. 0xf23a6e61, or its own function selector)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address which initiated the transfer (i.e. msg.sender) |
| from | address | The address which previously owned the token |
| id | uint256 | The ID of the token being transferred |
| value | uint256 | The amount of tokens being transferred |
| data | bytes | Additional data with no specified format |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address operator, address from, uint256[] ids, uint256[] values, bytes data) external returns (bytes4)
```

_Handles the receipt of a multiple ERC1155 token types. This function
is called at the end of a `safeBatchTransferFrom` after the balances have
been updated.

NOTE: To accept the transfer(s), this must return
`bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
(i.e. 0xbc197c81, or its own function selector)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address which initiated the batch transfer (i.e. msg.sender) |
| from | address | The address which previously owned the token |
| ids | uint256[] | An array containing ids of each token being transferred (order and length must match values array) |
| values | uint256[] | An array containing amounts of each token being transferred (order and length must match ids array) |
| data | bytes | Additional data with no specified format |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 | `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed |

inherits IERC165:
### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

## Math

_Standard math utilities missing in the Solidity language._

### Contract
Math : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Standard math utilities missing in the Solidity language.

 --- 
### Functions:
### max

```solidity
function max(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the largest of two numbers._

### min

```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the smallest of two numbers._

### average

```solidity
function average(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the average of two numbers. The result is rounded towards
zero._

### ceilDiv

```solidity
function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the ceiling of the division of two numbers.

This differs from standard division with `/` in that it rounds up instead
of rounding down._

### mulDiv

```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result)
```

Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0

_Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
with further edits by Uniswap Labs also under MIT license._

### mulDiv

```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator, enum Math.Rounding rounding) internal pure returns (uint256)
```

Calculates x * y / denominator with full precision, following the selected rounding direction.

### sqrt

```solidity
function sqrt(uint256 a) internal pure returns (uint256)
```

_Returns the square root of a number. If the number is not a perfect square, the value is rounded down.

Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11)._

### sqrt

```solidity
function sqrt(uint256 a, enum Math.Rounding rounding) internal pure returns (uint256)
```

Calculates sqrt(a), following the selected rounding direction.

### log2

```solidity
function log2(uint256 value) internal pure returns (uint256)
```

_Return the log in base 2, rounded down, of a positive value.
Returns 0 if given 0._

### log2

```solidity
function log2(uint256 value, enum Math.Rounding rounding) internal pure returns (uint256)
```

_Return the log in base 2, following the selected rounding direction, of a positive value.
Returns 0 if given 0._

### log10

```solidity
function log10(uint256 value) internal pure returns (uint256)
```

_Return the log in base 10, rounded down, of a positive value.
Returns 0 if given 0._

### log10

```solidity
function log10(uint256 value, enum Math.Rounding rounding) internal pure returns (uint256)
```

_Return the log in base 10, following the selected rounding direction, of a positive value.
Returns 0 if given 0._

### log256

```solidity
function log256(uint256 value) internal pure returns (uint256)
```

_Return the log in base 256, rounded down, of a positive value.
Returns 0 if given 0.

Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string._

### log256

```solidity
function log256(uint256 value, enum Math.Rounding rounding) internal pure returns (uint256)
```

_Return the log in base 10, following the selected rounding direction, of a positive value.
Returns 0 if given 0._

## Strings

_String operations._

### Contract
Strings : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

String operations.

 --- 
### Functions:
### toString

```solidity
function toString(uint256 value) internal pure returns (string)
```

_Converts a `uint256` to its ASCII `string` decimal representation._

### toHexString

```solidity
function toHexString(uint256 value) internal pure returns (string)
```

_Converts a `uint256` to its ASCII `string` hexadecimal representation._

### toHexString

```solidity
function toHexString(uint256 value, uint256 length) internal pure returns (string)
```

_Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length._

### toHexString

```solidity
function toHexString(address addr) internal pure returns (string)
```

_Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation._

## ECDSA

_Elliptic Curve Digital Signature Algorithm (ECDSA) operations.

These functions can be used to verify that a message was signed by the holder
of the private keys of a given address._

### Contract
ECDSA : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Elliptic Curve Digital Signature Algorithm (ECDSA) operations.

These functions can be used to verify that a message was signed by the holder
of the private keys of a given address.

 --- 
### Functions:
### tryRecover

```solidity
function tryRecover(bytes32 hash, bytes signature) internal pure returns (address, enum ECDSA.RecoverError)
```

_Returns the address that signed a hashed message (`hash`) with
`signature` or error string. This address can then be used for verification purposes.

The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
this function rejects them by requiring the `s` value to be in the lower
half order, and the `v` value to be either 27 or 28.

IMPORTANT: `hash` _must_ be the result of a hash operation for the
verification to be secure: it is possible to craft signatures that
recover to arbitrary addresses for non-hashed data. A safe way to ensure
this is by receiving a hash of the original message (which may otherwise
be too long), and then calling {toEthSignedMessageHash} on it.

Documentation for signature generation:
- with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
- with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]

_Available since v4.3.__

### recover

```solidity
function recover(bytes32 hash, bytes signature) internal pure returns (address)
```

_Returns the address that signed a hashed message (`hash`) with
`signature`. This address can then be used for verification purposes.

The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
this function rejects them by requiring the `s` value to be in the lower
half order, and the `v` value to be either 27 or 28.

IMPORTANT: `hash` _must_ be the result of a hash operation for the
verification to be secure: it is possible to craft signatures that
recover to arbitrary addresses for non-hashed data. A safe way to ensure
this is by receiving a hash of the original message (which may otherwise
be too long), and then calling {toEthSignedMessageHash} on it._

### tryRecover

```solidity
function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, enum ECDSA.RecoverError)
```

_Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.

See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]

_Available since v4.3.__

### recover

```solidity
function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address)
```

_Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.

_Available since v4.2.__

### tryRecover

```solidity
function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, enum ECDSA.RecoverError)
```

_Overload of {ECDSA-tryRecover} that receives the `v`,
`r` and `s` signature fields separately.

_Available since v4.3.__

### recover

```solidity
function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address)
```

_Overload of {ECDSA-recover} that receives the `v`,
`r` and `s` signature fields separately._

### toEthSignedMessageHash

```solidity
function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32)
```

_Returns an Ethereum Signed Message, created from a `hash`. This
produces hash corresponding to the one signed with the
https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
JSON-RPC method as part of EIP-191.

See {recover}._

### toEthSignedMessageHash

```solidity
function toEthSignedMessageHash(bytes s) internal pure returns (bytes32)
```

_Returns an Ethereum Signed Message, created from `s`. This
produces hash corresponding to the one signed with the
https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
JSON-RPC method as part of EIP-191.

See {recover}._

### toTypedDataHash

```solidity
function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32)
```

_Returns an Ethereum Signed Typed Data, created from a
`domainSeparator` and a `structHash`. This produces hash corresponding
to the one signed with the
https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
JSON-RPC method as part of EIP-712.

See {recover}._

## EIP712

_https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.

The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
they need in their contracts using a combination of `abi.encode` and `keccak256`.

This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
({_hashTypedDataV4}).

The implementation of the domain separator was designed to be as efficient as possible while still properly updating
the chain id to protect against replay attacks on an eventual fork of the chain.

NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].

_Available since v3.4.__

### Contract
EIP712 : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.

The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
they need in their contracts using a combination of `abi.encode` and `keccak256`.

This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
({_hashTypedDataV4}).

The implementation of the domain separator was designed to be as efficient as possible while still properly updating
the chain id to protect against replay attacks on an eventual fork of the chain.

NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].

_Available since v3.4._

 --- 
### Functions:
### constructor

```solidity
constructor(string name, string version) internal
```

_Initializes the domain separator and parameter caches.

The meaning of `name` and `version` is specified in
https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:

- `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
- `version`: the current major version of the signing domain.

NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
contract upgrade]._

### _domainSeparatorV4

```solidity
function _domainSeparatorV4() internal view returns (bytes32)
```

_Returns the domain separator for the current chain._

### _hashTypedDataV4

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32)
```

_Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
function returns the hash of the fully encoded EIP712 message for this domain.

This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:

```solidity
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
    keccak256("Mail(address to,string contents)"),
    mailTo,
    keccak256(bytes(mailContents))
)));
address signer = ECDSA.recover(digest, signature);
```_

## ERC165

_Implementation of the {IERC165} interface.

Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
for the additional interface id that will be supported. For example:

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
}
```

Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation._

### Contract
ERC165 : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Implementation of the {IERC165} interface.

Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
for the additional interface id that will be supported. For example:

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
}
```

Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.

 --- 
### Functions:
### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

inherits IERC165:

## SafeCast

_Wrappers over Solidity's uintXX/intXX casting operators with added overflow
checks.

Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
easily result in undesired exploitation or bugs, since developers usually
assume that overflows raise errors. `SafeCast` restores this intuition by
reverting the transaction when such an operation overflows.

Using this library instead of the unchecked operations eliminates an entire
class of bugs, so it's recommended to use it always.

Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
all math on `uint256` and `int256` and then downcasting._

### Contract
SafeCast : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Wrappers over Solidity's uintXX/intXX casting operators with added overflow
checks.

Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
easily result in undesired exploitation or bugs, since developers usually
assume that overflows raise errors. `SafeCast` restores this intuition by
reverting the transaction when such an operation overflows.

Using this library instead of the unchecked operations eliminates an entire
class of bugs, so it's recommended to use it always.

Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
all math on `uint256` and `int256` and then downcasting.

 --- 
### Functions:
### toUint248

```solidity
function toUint248(uint256 value) internal pure returns (uint248)
```

_Returns the downcasted uint248 from uint256, reverting on
overflow (when the input is greater than largest uint248).

Counterpart to Solidity's `uint248` operator.

Requirements:

- input must fit into 248 bits

_Available since v4.7.__

### toUint240

```solidity
function toUint240(uint256 value) internal pure returns (uint240)
```

_Returns the downcasted uint240 from uint256, reverting on
overflow (when the input is greater than largest uint240).

Counterpart to Solidity's `uint240` operator.

Requirements:

- input must fit into 240 bits

_Available since v4.7.__

### toUint232

```solidity
function toUint232(uint256 value) internal pure returns (uint232)
```

_Returns the downcasted uint232 from uint256, reverting on
overflow (when the input is greater than largest uint232).

Counterpart to Solidity's `uint232` operator.

Requirements:

- input must fit into 232 bits

_Available since v4.7.__

### toUint224

```solidity
function toUint224(uint256 value) internal pure returns (uint224)
```

_Returns the downcasted uint224 from uint256, reverting on
overflow (when the input is greater than largest uint224).

Counterpart to Solidity's `uint224` operator.

Requirements:

- input must fit into 224 bits

_Available since v4.2.__

### toUint216

```solidity
function toUint216(uint256 value) internal pure returns (uint216)
```

_Returns the downcasted uint216 from uint256, reverting on
overflow (when the input is greater than largest uint216).

Counterpart to Solidity's `uint216` operator.

Requirements:

- input must fit into 216 bits

_Available since v4.7.__

### toUint208

```solidity
function toUint208(uint256 value) internal pure returns (uint208)
```

_Returns the downcasted uint208 from uint256, reverting on
overflow (when the input is greater than largest uint208).

Counterpart to Solidity's `uint208` operator.

Requirements:

- input must fit into 208 bits

_Available since v4.7.__

### toUint200

```solidity
function toUint200(uint256 value) internal pure returns (uint200)
```

_Returns the downcasted uint200 from uint256, reverting on
overflow (when the input is greater than largest uint200).

Counterpart to Solidity's `uint200` operator.

Requirements:

- input must fit into 200 bits

_Available since v4.7.__

### toUint192

```solidity
function toUint192(uint256 value) internal pure returns (uint192)
```

_Returns the downcasted uint192 from uint256, reverting on
overflow (when the input is greater than largest uint192).

Counterpart to Solidity's `uint192` operator.

Requirements:

- input must fit into 192 bits

_Available since v4.7.__

### toUint184

```solidity
function toUint184(uint256 value) internal pure returns (uint184)
```

_Returns the downcasted uint184 from uint256, reverting on
overflow (when the input is greater than largest uint184).

Counterpart to Solidity's `uint184` operator.

Requirements:

- input must fit into 184 bits

_Available since v4.7.__

### toUint176

```solidity
function toUint176(uint256 value) internal pure returns (uint176)
```

_Returns the downcasted uint176 from uint256, reverting on
overflow (when the input is greater than largest uint176).

Counterpart to Solidity's `uint176` operator.

Requirements:

- input must fit into 176 bits

_Available since v4.7.__

### toUint168

```solidity
function toUint168(uint256 value) internal pure returns (uint168)
```

_Returns the downcasted uint168 from uint256, reverting on
overflow (when the input is greater than largest uint168).

Counterpart to Solidity's `uint168` operator.

Requirements:

- input must fit into 168 bits

_Available since v4.7.__

### toUint160

```solidity
function toUint160(uint256 value) internal pure returns (uint160)
```

_Returns the downcasted uint160 from uint256, reverting on
overflow (when the input is greater than largest uint160).

Counterpart to Solidity's `uint160` operator.

Requirements:

- input must fit into 160 bits

_Available since v4.7.__

### toUint152

```solidity
function toUint152(uint256 value) internal pure returns (uint152)
```

_Returns the downcasted uint152 from uint256, reverting on
overflow (when the input is greater than largest uint152).

Counterpart to Solidity's `uint152` operator.

Requirements:

- input must fit into 152 bits

_Available since v4.7.__

### toUint144

```solidity
function toUint144(uint256 value) internal pure returns (uint144)
```

_Returns the downcasted uint144 from uint256, reverting on
overflow (when the input is greater than largest uint144).

Counterpart to Solidity's `uint144` operator.

Requirements:

- input must fit into 144 bits

_Available since v4.7.__

### toUint136

```solidity
function toUint136(uint256 value) internal pure returns (uint136)
```

_Returns the downcasted uint136 from uint256, reverting on
overflow (when the input is greater than largest uint136).

Counterpart to Solidity's `uint136` operator.

Requirements:

- input must fit into 136 bits

_Available since v4.7.__

### toUint128

```solidity
function toUint128(uint256 value) internal pure returns (uint128)
```

_Returns the downcasted uint128 from uint256, reverting on
overflow (when the input is greater than largest uint128).

Counterpart to Solidity's `uint128` operator.

Requirements:

- input must fit into 128 bits

_Available since v2.5.__

### toUint120

```solidity
function toUint120(uint256 value) internal pure returns (uint120)
```

_Returns the downcasted uint120 from uint256, reverting on
overflow (when the input is greater than largest uint120).

Counterpart to Solidity's `uint120` operator.

Requirements:

- input must fit into 120 bits

_Available since v4.7.__

### toUint112

```solidity
function toUint112(uint256 value) internal pure returns (uint112)
```

_Returns the downcasted uint112 from uint256, reverting on
overflow (when the input is greater than largest uint112).

Counterpart to Solidity's `uint112` operator.

Requirements:

- input must fit into 112 bits

_Available since v4.7.__

### toUint104

```solidity
function toUint104(uint256 value) internal pure returns (uint104)
```

_Returns the downcasted uint104 from uint256, reverting on
overflow (when the input is greater than largest uint104).

Counterpart to Solidity's `uint104` operator.

Requirements:

- input must fit into 104 bits

_Available since v4.7.__

### toUint96

```solidity
function toUint96(uint256 value) internal pure returns (uint96)
```

_Returns the downcasted uint96 from uint256, reverting on
overflow (when the input is greater than largest uint96).

Counterpart to Solidity's `uint96` operator.

Requirements:

- input must fit into 96 bits

_Available since v4.2.__

### toUint88

```solidity
function toUint88(uint256 value) internal pure returns (uint88)
```

_Returns the downcasted uint88 from uint256, reverting on
overflow (when the input is greater than largest uint88).

Counterpart to Solidity's `uint88` operator.

Requirements:

- input must fit into 88 bits

_Available since v4.7.__

### toUint80

```solidity
function toUint80(uint256 value) internal pure returns (uint80)
```

_Returns the downcasted uint80 from uint256, reverting on
overflow (when the input is greater than largest uint80).

Counterpart to Solidity's `uint80` operator.

Requirements:

- input must fit into 80 bits

_Available since v4.7.__

### toUint72

```solidity
function toUint72(uint256 value) internal pure returns (uint72)
```

_Returns the downcasted uint72 from uint256, reverting on
overflow (when the input is greater than largest uint72).

Counterpart to Solidity's `uint72` operator.

Requirements:

- input must fit into 72 bits

_Available since v4.7.__

### toUint64

```solidity
function toUint64(uint256 value) internal pure returns (uint64)
```

_Returns the downcasted uint64 from uint256, reverting on
overflow (when the input is greater than largest uint64).

Counterpart to Solidity's `uint64` operator.

Requirements:

- input must fit into 64 bits

_Available since v2.5.__

### toUint56

```solidity
function toUint56(uint256 value) internal pure returns (uint56)
```

_Returns the downcasted uint56 from uint256, reverting on
overflow (when the input is greater than largest uint56).

Counterpart to Solidity's `uint56` operator.

Requirements:

- input must fit into 56 bits

_Available since v4.7.__

### toUint48

```solidity
function toUint48(uint256 value) internal pure returns (uint48)
```

_Returns the downcasted uint48 from uint256, reverting on
overflow (when the input is greater than largest uint48).

Counterpart to Solidity's `uint48` operator.

Requirements:

- input must fit into 48 bits

_Available since v4.7.__

### toUint40

```solidity
function toUint40(uint256 value) internal pure returns (uint40)
```

_Returns the downcasted uint40 from uint256, reverting on
overflow (when the input is greater than largest uint40).

Counterpart to Solidity's `uint40` operator.

Requirements:

- input must fit into 40 bits

_Available since v4.7.__

### toUint32

```solidity
function toUint32(uint256 value) internal pure returns (uint32)
```

_Returns the downcasted uint32 from uint256, reverting on
overflow (when the input is greater than largest uint32).

Counterpart to Solidity's `uint32` operator.

Requirements:

- input must fit into 32 bits

_Available since v2.5.__

### toUint24

```solidity
function toUint24(uint256 value) internal pure returns (uint24)
```

_Returns the downcasted uint24 from uint256, reverting on
overflow (when the input is greater than largest uint24).

Counterpart to Solidity's `uint24` operator.

Requirements:

- input must fit into 24 bits

_Available since v4.7.__

### toUint16

```solidity
function toUint16(uint256 value) internal pure returns (uint16)
```

_Returns the downcasted uint16 from uint256, reverting on
overflow (when the input is greater than largest uint16).

Counterpart to Solidity's `uint16` operator.

Requirements:

- input must fit into 16 bits

_Available since v2.5.__

### toUint8

```solidity
function toUint8(uint256 value) internal pure returns (uint8)
```

_Returns the downcasted uint8 from uint256, reverting on
overflow (when the input is greater than largest uint8).

Counterpart to Solidity's `uint8` operator.

Requirements:

- input must fit into 8 bits

_Available since v2.5.__

### toUint256

```solidity
function toUint256(int256 value) internal pure returns (uint256)
```

_Converts a signed int256 into an unsigned uint256.

Requirements:

- input must be greater than or equal to 0.

_Available since v3.0.__

### toInt248

```solidity
function toInt248(int256 value) internal pure returns (int248 downcasted)
```

_Returns the downcasted int248 from int256, reverting on
overflow (when the input is less than smallest int248 or
greater than largest int248).

Counterpart to Solidity's `int248` operator.

Requirements:

- input must fit into 248 bits

_Available since v4.7.__

### toInt240

```solidity
function toInt240(int256 value) internal pure returns (int240 downcasted)
```

_Returns the downcasted int240 from int256, reverting on
overflow (when the input is less than smallest int240 or
greater than largest int240).

Counterpart to Solidity's `int240` operator.

Requirements:

- input must fit into 240 bits

_Available since v4.7.__

### toInt232

```solidity
function toInt232(int256 value) internal pure returns (int232 downcasted)
```

_Returns the downcasted int232 from int256, reverting on
overflow (when the input is less than smallest int232 or
greater than largest int232).

Counterpart to Solidity's `int232` operator.

Requirements:

- input must fit into 232 bits

_Available since v4.7.__

### toInt224

```solidity
function toInt224(int256 value) internal pure returns (int224 downcasted)
```

_Returns the downcasted int224 from int256, reverting on
overflow (when the input is less than smallest int224 or
greater than largest int224).

Counterpart to Solidity's `int224` operator.

Requirements:

- input must fit into 224 bits

_Available since v4.7.__

### toInt216

```solidity
function toInt216(int256 value) internal pure returns (int216 downcasted)
```

_Returns the downcasted int216 from int256, reverting on
overflow (when the input is less than smallest int216 or
greater than largest int216).

Counterpart to Solidity's `int216` operator.

Requirements:

- input must fit into 216 bits

_Available since v4.7.__

### toInt208

```solidity
function toInt208(int256 value) internal pure returns (int208 downcasted)
```

_Returns the downcasted int208 from int256, reverting on
overflow (when the input is less than smallest int208 or
greater than largest int208).

Counterpart to Solidity's `int208` operator.

Requirements:

- input must fit into 208 bits

_Available since v4.7.__

### toInt200

```solidity
function toInt200(int256 value) internal pure returns (int200 downcasted)
```

_Returns the downcasted int200 from int256, reverting on
overflow (when the input is less than smallest int200 or
greater than largest int200).

Counterpart to Solidity's `int200` operator.

Requirements:

- input must fit into 200 bits

_Available since v4.7.__

### toInt192

```solidity
function toInt192(int256 value) internal pure returns (int192 downcasted)
```

_Returns the downcasted int192 from int256, reverting on
overflow (when the input is less than smallest int192 or
greater than largest int192).

Counterpart to Solidity's `int192` operator.

Requirements:

- input must fit into 192 bits

_Available since v4.7.__

### toInt184

```solidity
function toInt184(int256 value) internal pure returns (int184 downcasted)
```

_Returns the downcasted int184 from int256, reverting on
overflow (when the input is less than smallest int184 or
greater than largest int184).

Counterpart to Solidity's `int184` operator.

Requirements:

- input must fit into 184 bits

_Available since v4.7.__

### toInt176

```solidity
function toInt176(int256 value) internal pure returns (int176 downcasted)
```

_Returns the downcasted int176 from int256, reverting on
overflow (when the input is less than smallest int176 or
greater than largest int176).

Counterpart to Solidity's `int176` operator.

Requirements:

- input must fit into 176 bits

_Available since v4.7.__

### toInt168

```solidity
function toInt168(int256 value) internal pure returns (int168 downcasted)
```

_Returns the downcasted int168 from int256, reverting on
overflow (when the input is less than smallest int168 or
greater than largest int168).

Counterpart to Solidity's `int168` operator.

Requirements:

- input must fit into 168 bits

_Available since v4.7.__

### toInt160

```solidity
function toInt160(int256 value) internal pure returns (int160 downcasted)
```

_Returns the downcasted int160 from int256, reverting on
overflow (when the input is less than smallest int160 or
greater than largest int160).

Counterpart to Solidity's `int160` operator.

Requirements:

- input must fit into 160 bits

_Available since v4.7.__

### toInt152

```solidity
function toInt152(int256 value) internal pure returns (int152 downcasted)
```

_Returns the downcasted int152 from int256, reverting on
overflow (when the input is less than smallest int152 or
greater than largest int152).

Counterpart to Solidity's `int152` operator.

Requirements:

- input must fit into 152 bits

_Available since v4.7.__

### toInt144

```solidity
function toInt144(int256 value) internal pure returns (int144 downcasted)
```

_Returns the downcasted int144 from int256, reverting on
overflow (when the input is less than smallest int144 or
greater than largest int144).

Counterpart to Solidity's `int144` operator.

Requirements:

- input must fit into 144 bits

_Available since v4.7.__

### toInt136

```solidity
function toInt136(int256 value) internal pure returns (int136 downcasted)
```

_Returns the downcasted int136 from int256, reverting on
overflow (when the input is less than smallest int136 or
greater than largest int136).

Counterpart to Solidity's `int136` operator.

Requirements:

- input must fit into 136 bits

_Available since v4.7.__

### toInt128

```solidity
function toInt128(int256 value) internal pure returns (int128 downcasted)
```

_Returns the downcasted int128 from int256, reverting on
overflow (when the input is less than smallest int128 or
greater than largest int128).

Counterpart to Solidity's `int128` operator.

Requirements:

- input must fit into 128 bits

_Available since v3.1.__

### toInt120

```solidity
function toInt120(int256 value) internal pure returns (int120 downcasted)
```

_Returns the downcasted int120 from int256, reverting on
overflow (when the input is less than smallest int120 or
greater than largest int120).

Counterpart to Solidity's `int120` operator.

Requirements:

- input must fit into 120 bits

_Available since v4.7.__

### toInt112

```solidity
function toInt112(int256 value) internal pure returns (int112 downcasted)
```

_Returns the downcasted int112 from int256, reverting on
overflow (when the input is less than smallest int112 or
greater than largest int112).

Counterpart to Solidity's `int112` operator.

Requirements:

- input must fit into 112 bits

_Available since v4.7.__

### toInt104

```solidity
function toInt104(int256 value) internal pure returns (int104 downcasted)
```

_Returns the downcasted int104 from int256, reverting on
overflow (when the input is less than smallest int104 or
greater than largest int104).

Counterpart to Solidity's `int104` operator.

Requirements:

- input must fit into 104 bits

_Available since v4.7.__

### toInt96

```solidity
function toInt96(int256 value) internal pure returns (int96 downcasted)
```

_Returns the downcasted int96 from int256, reverting on
overflow (when the input is less than smallest int96 or
greater than largest int96).

Counterpart to Solidity's `int96` operator.

Requirements:

- input must fit into 96 bits

_Available since v4.7.__

### toInt88

```solidity
function toInt88(int256 value) internal pure returns (int88 downcasted)
```

_Returns the downcasted int88 from int256, reverting on
overflow (when the input is less than smallest int88 or
greater than largest int88).

Counterpart to Solidity's `int88` operator.

Requirements:

- input must fit into 88 bits

_Available since v4.7.__

### toInt80

```solidity
function toInt80(int256 value) internal pure returns (int80 downcasted)
```

_Returns the downcasted int80 from int256, reverting on
overflow (when the input is less than smallest int80 or
greater than largest int80).

Counterpart to Solidity's `int80` operator.

Requirements:

- input must fit into 80 bits

_Available since v4.7.__

### toInt72

```solidity
function toInt72(int256 value) internal pure returns (int72 downcasted)
```

_Returns the downcasted int72 from int256, reverting on
overflow (when the input is less than smallest int72 or
greater than largest int72).

Counterpart to Solidity's `int72` operator.

Requirements:

- input must fit into 72 bits

_Available since v4.7.__

### toInt64

```solidity
function toInt64(int256 value) internal pure returns (int64 downcasted)
```

_Returns the downcasted int64 from int256, reverting on
overflow (when the input is less than smallest int64 or
greater than largest int64).

Counterpart to Solidity's `int64` operator.

Requirements:

- input must fit into 64 bits

_Available since v3.1.__

### toInt56

```solidity
function toInt56(int256 value) internal pure returns (int56 downcasted)
```

_Returns the downcasted int56 from int256, reverting on
overflow (when the input is less than smallest int56 or
greater than largest int56).

Counterpart to Solidity's `int56` operator.

Requirements:

- input must fit into 56 bits

_Available since v4.7.__

### toInt48

```solidity
function toInt48(int256 value) internal pure returns (int48 downcasted)
```

_Returns the downcasted int48 from int256, reverting on
overflow (when the input is less than smallest int48 or
greater than largest int48).

Counterpart to Solidity's `int48` operator.

Requirements:

- input must fit into 48 bits

_Available since v4.7.__

### toInt40

```solidity
function toInt40(int256 value) internal pure returns (int40 downcasted)
```

_Returns the downcasted int40 from int256, reverting on
overflow (when the input is less than smallest int40 or
greater than largest int40).

Counterpart to Solidity's `int40` operator.

Requirements:

- input must fit into 40 bits

_Available since v4.7.__

### toInt32

```solidity
function toInt32(int256 value) internal pure returns (int32 downcasted)
```

_Returns the downcasted int32 from int256, reverting on
overflow (when the input is less than smallest int32 or
greater than largest int32).

Counterpart to Solidity's `int32` operator.

Requirements:

- input must fit into 32 bits

_Available since v3.1.__

### toInt24

```solidity
function toInt24(int256 value) internal pure returns (int24 downcasted)
```

_Returns the downcasted int24 from int256, reverting on
overflow (when the input is less than smallest int24 or
greater than largest int24).

Counterpart to Solidity's `int24` operator.

Requirements:

- input must fit into 24 bits

_Available since v4.7.__

### toInt16

```solidity
function toInt16(int256 value) internal pure returns (int16 downcasted)
```

_Returns the downcasted int16 from int256, reverting on
overflow (when the input is less than smallest int16 or
greater than largest int16).

Counterpart to Solidity's `int16` operator.

Requirements:

- input must fit into 16 bits

_Available since v3.1.__

### toInt8

```solidity
function toInt8(int256 value) internal pure returns (int8 downcasted)
```

_Returns the downcasted int8 from int256, reverting on
overflow (when the input is less than smallest int8 or
greater than largest int8).

Counterpart to Solidity's `int8` operator.

Requirements:

- input must fit into 8 bits

_Available since v3.1.__

### toInt256

```solidity
function toInt256(uint256 value) internal pure returns (int256)
```

_Converts an unsigned uint256 into a signed int256.

Requirements:

- input must be less than or equal to maxInt256.

_Available since v3.0.__

## DoubleEndedQueue

_A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
the existing queue contents are left in storage.

The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
used in storage, and not in memory.
```
DoubleEndedQueue.Bytes32Deque queue;
```

_Available since v4.6.__

### Contract
DoubleEndedQueue : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
the existing queue contents are left in storage.

The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
used in storage, and not in memory.
```
DoubleEndedQueue.Bytes32Deque queue;
```

_Available since v4.6._

 --- 
### Functions:
### pushBack

```solidity
function pushBack(struct DoubleEndedQueue.Bytes32Deque deque, bytes32 value) internal
```

_Inserts an item at the end of the queue._

### popBack

```solidity
function popBack(struct DoubleEndedQueue.Bytes32Deque deque) internal returns (bytes32 value)
```

_Removes the item at the end of the queue and returns it.

Reverts with `Empty` if the queue is empty._

### pushFront

```solidity
function pushFront(struct DoubleEndedQueue.Bytes32Deque deque, bytes32 value) internal
```

_Inserts an item at the beginning of the queue._

### popFront

```solidity
function popFront(struct DoubleEndedQueue.Bytes32Deque deque) internal returns (bytes32 value)
```

_Removes the item at the beginning of the queue and returns it.

Reverts with `Empty` if the queue is empty._

### front

```solidity
function front(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (bytes32 value)
```

_Returns the item at the beginning of the queue.

Reverts with `Empty` if the queue is empty._

### back

```solidity
function back(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (bytes32 value)
```

_Returns the item at the end of the queue.

Reverts with `Empty` if the queue is empty._

### at

```solidity
function at(struct DoubleEndedQueue.Bytes32Deque deque, uint256 index) internal view returns (bytes32 value)
```

_Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
`length(deque) - 1`.

Reverts with `OutOfBounds` if the index is out of bounds._

### clear

```solidity
function clear(struct DoubleEndedQueue.Bytes32Deque deque) internal
```

_Resets the queue back to being empty.

NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
out on potential gas refunds._

### length

```solidity
function length(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (uint256)
```

_Returns the number of items in the queue._

### empty

```solidity
function empty(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (bool)
```

_Returns true if the queue is empty._

## Address

_Collection of functions related to the address type_

### Contract
Address : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Collection of functions related to the address type

 --- 
### Functions:
### isContract

```solidity
function isContract(address account) internal view returns (bool)
```

_Returns true if `account` is a contract.

[IMPORTANT]
====
It is unsafe to assume that an address for which this function returns
false is an externally-owned account (EOA) and not a contract.

Among others, `isContract` will return false for the following
types of addresses:

 - an externally-owned account
 - a contract in construction
 - an address where a contract will be created
 - an address where a contract lived, but was destroyed
====

[IMPORTANT]
====
You shouldn't rely on `isContract` to protect against flash loan attacks!

Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
constructor.
====_

### sendValue

```solidity
function sendValue(address payable recipient, uint256 amount) internal
```

_Replacement for Solidity's `transfer`: sends `amount` wei to
`recipient`, forwarding all available gas and reverting on errors.

https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
of certain opcodes, possibly making contracts go over the 2300 gas limit
imposed by `transfer`, making them unable to receive funds via
`transfer`. {sendValue} removes this limitation.

https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].

IMPORTANT: because control is transferred to `recipient`, care must be
taken to not create reentrancy vulnerabilities. Consider using
{ReentrancyGuard} or the
https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern]._

### functionCall

```solidity
function functionCall(address target, bytes data) internal returns (bytes)
```

_Performs a Solidity function call using a low level `call`. A
plain `call` is an unsafe replacement for a function call: use this
function instead.

If `target` reverts with a revert reason, it is bubbled up by this
function (like regular Solidity function calls).

Returns the raw returned data. To convert to the expected return value,
use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

Requirements:

- `target` must be a contract.
- calling `target` with `data` must not revert.

_Available since v3.1.__

### functionCall

```solidity
function functionCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
`errorMessage` as a fallback revert reason when `target` reverts.

_Available since v3.1.__

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but also transferring `value` wei to `target`.

Requirements:

- the calling contract must have an ETH balance of at least `value`.
- the called Solidity function must be `payable`.

_Available since v3.1.__

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value, string errorMessage) internal returns (bytes)
```

_Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
with `errorMessage` as a fallback revert reason when `target` reverts.

_Available since v3.1.__

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data) internal view returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a static call.

_Available since v3.3.__

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data, string errorMessage) internal view returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a static call.

_Available since v3.3.__

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a delegate call.

_Available since v3.4.__

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a delegate call.

_Available since v3.4.__

### verifyCallResultFromTarget

```solidity
function verifyCallResultFromTarget(address target, bool success, bytes returndata, string errorMessage) internal view returns (bytes)
```

_Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.

_Available since v4.8.__

### verifyCallResult

```solidity
function verifyCallResult(bool success, bytes returndata, string errorMessage) internal pure returns (bytes)
```

_Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
revert reason or using the provided one.

_Available since v4.3.__

## Context

_Provides information about the current execution context, including the
sender of the transaction and its data. While these are generally available
via msg.sender and msg.data, they should not be accessed in such a direct
manner, since when dealing with meta-transactions the account sending and
paying for execution may not be the actual sender (as far as an application
is concerned).

This contract is only required for intermediate, library-like contracts._

### Contract
Context : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Provides information about the current execution context, including the
sender of the transaction and its data. While these are generally available
via msg.sender and msg.data, they should not be accessed in such a direct
manner, since when dealing with meta-transactions the account sending and
paying for execution may not be the actual sender (as far as an application
is concerned).

This contract is only required for intermediate, library-like contracts.

 --- 
### Functions:
### _msgSender

```solidity
function _msgSender() internal view virtual returns (address)
```

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

## Timers

_Tooling for timepoints, timers and delays_

### Contract
Timers : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Tooling for timepoints, timers and delays

 --- 
### Functions:
### getDeadline

```solidity
function getDeadline(struct Timers.Timestamp timer) internal pure returns (uint64)
```

### setDeadline

```solidity
function setDeadline(struct Timers.Timestamp timer, uint64 timestamp) internal
```

### reset

```solidity
function reset(struct Timers.Timestamp timer) internal
```

### isUnset

```solidity
function isUnset(struct Timers.Timestamp timer) internal pure returns (bool)
```

### isStarted

```solidity
function isStarted(struct Timers.Timestamp timer) internal pure returns (bool)
```

### isPending

```solidity
function isPending(struct Timers.Timestamp timer) internal view returns (bool)
```

### isExpired

```solidity
function isExpired(struct Timers.Timestamp timer) internal view returns (bool)
```

### getDeadline

```solidity
function getDeadline(struct Timers.BlockNumber timer) internal pure returns (uint64)
```

### setDeadline

```solidity
function setDeadline(struct Timers.BlockNumber timer, uint64 timestamp) internal
```

### reset

```solidity
function reset(struct Timers.BlockNumber timer) internal
```

### isUnset

```solidity
function isUnset(struct Timers.BlockNumber timer) internal pure returns (bool)
```

### isStarted

```solidity
function isStarted(struct Timers.BlockNumber timer) internal pure returns (bool)
```

### isPending

```solidity
function isPending(struct Timers.BlockNumber timer) internal view returns (bool)
```

### isExpired

```solidity
function isExpired(struct Timers.BlockNumber timer) internal view returns (bool)
```

## IGovernor

_Interface of the {Governor} core.

_Available since v4.3.__

### Contract
IGovernor : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Interface of the {Governor} core.

_Available since v4.3._

 --- 
### Functions:
### name

```solidity
function name() public view virtual returns (string)
```

module:core

_Name of the governor instance (used in building the ERC712 domain separator)._

### version

```solidity
function version() public view virtual returns (string)
```

module:core

_Version of the governor instance (used in building the ERC712 domain separator). Default: "1"_

### COUNTING_MODE

```solidity
function COUNTING_MODE() public pure virtual returns (string)
```

module:voting

_A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.

There are 2 standard keys: `support` and `quorum`.

- `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
- `quorum=bravo` means that only For votes are counted towards quorum.
- `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.

If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
name that describes the behavior. For example:

- `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
- `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.

NOTE: The string can be decoded by the standard
https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
JavaScript class._

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public pure virtual returns (uint256)
```

module:core

_Hashing function used to (re)build the proposal id from the proposal details.._

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

module:core

_Current state of a proposal, following Compound's convention_

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256)
```

module:core

_Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
beginning of the following block._

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) public view virtual returns (uint256)
```

module:core

_Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
during this block._

### votingDelay

```solidity
function votingDelay() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
leave time for users to buy voting power, or delegate it, before the voting of a proposal starts._

### votingPeriod

```solidity
function votingPeriod() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of blocks, between the vote start and vote ends.

NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
duration compared to the voting delay._

### quorum

```solidity
function quorum(uint256 blockNumber) public view virtual returns (uint256)
```

module:user-config

_Minimum number of cast voted required for a proposal to be successful.

Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes})._

### getVotes

```solidity
function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256)
```

module:reputation

_Voting power of an `account` at a specific `blockNumber`.

Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
multiple), {ERC20Votes} tokens._

### getVotesWithParams

```solidity
function getVotesWithParams(address account, uint256 blockNumber, bytes params) public view virtual returns (uint256)
```

module:reputation

_Voting power of an `account` at a specific `blockNumber` given additional encoded parameters._

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)
```

module:voting

_Returns whether `account` has cast a vote on `proposalId`._

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) public virtual returns (uint256 proposalId)
```

_Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
{IGovernor-votingPeriod} blocks after the voting starts.

Emits a {ProposalCreated} event._

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual returns (uint256 proposalId)
```

_Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
deadline to be reached.

Emits a {ProposalExecuted} event.

Note: some module can modify the requirements for execution, for example by adding an additional timelock._

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance)
```

_Cast a vote

Emits a {VoteCast} event._

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) public virtual returns (uint256 balance)
```

_Cast a vote with a reason

Emits a {VoteCast} event._

### castVoteWithReasonAndParams

```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string reason, bytes params) public virtual returns (uint256 balance)
```

_Cast a vote with a reason and additional encoded parameters

Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params._

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256 balance)
```

_Cast a vote using the user's cryptographic signature.

Emits a {VoteCast} event._

### castVoteWithReasonAndParamsBySig

```solidity
function castVoteWithReasonAndParamsBySig(uint256 proposalId, uint8 support, string reason, bytes params, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256 balance)
```

_Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.

Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params._

inherits IERC165:
### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

 --- 
### Events:
### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)
```

_Emitted when a proposal is created._

### ProposalCanceled

```solidity
event ProposalCanceled(uint256 proposalId)
```

_Emitted when a proposal is canceled._

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Emitted when a proposal is executed._

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason)
```

_Emitted when a vote is cast without params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used._

### VoteCastWithParams

```solidity
event VoteCastWithParams(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params)
```

_Emitted when a vote is cast with params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
`params` are additional encoded parameters. Their intepepretation also depends on the voting module used._

inherits IERC165:

## Governor

_Core of the governance system, designed to be extended though various modules.

This contract is abstract and requires several function to be implemented in various modules:

- A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
- A voting module must implement {_getVotes}
- Additionanly, the {votingPeriod} must also be implemented

_Available since v4.3.__

### Contract
Governor : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Core of the governance system, designed to be extended though various modules.

This contract is abstract and requires several function to be implemented in various modules:

- A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
- A voting module must implement {_getVotes}
- Additionanly, the {votingPeriod} must also be implemented

_Available since v4.3._

 --- 
### Modifiers:
### onlyGovernance

```solidity
modifier onlyGovernance()
```

_Restricts a function so it can only be executed through governance proposals. For example, governance
parameter setters in {GovernorSettings} are protected using this modifier.

The governance executing address may be different from the Governor's own address, for example it could be a
timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
for example, additional timelock proposers are not able to change governance parameters without going through the
governance protocol (since v4.6)._

 --- 
### Functions:
### constructor

```solidity
constructor(string name_) internal
```

_Sets the value for {name} and {version}_

### receive

```solidity
receive() external payable virtual
```

_Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### name

```solidity
function name() public view virtual returns (string)
```

_See {IGovernor-name}._

### version

```solidity
function version() public view virtual returns (string)
```

_See {IGovernor-version}._

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public pure virtual returns (uint256)
```

_See {IGovernor-hashProposal}.

The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
advance, before the proposal is submitted.

Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
same proposal (with same operation and same description) will have the same id if submitted on multiple governors
across multiple networks. This also means that in order to execute the same operation twice (on the same
governor) the proposer will have to change the description in order to avoid proposal id conflicts._

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

_See {IGovernor-state}._

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalSnapshot}._

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalDeadline}._

### proposalThreshold

```solidity
function proposalThreshold() public view virtual returns (uint256)
```

_Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_._

### _quorumReached

```solidity
function _quorumReached(uint256 proposalId) internal view virtual returns (bool)
```

_Amount of votes already cast passes the threshold limit._

### _voteSucceeded

```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool)
```

_Is the proposal successful or not._

### _getVotes

```solidity
function _getVotes(address account, uint256 blockNumber, bytes params) internal view virtual returns (uint256)
```

_Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`._

### _countVote

```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes params) internal virtual
```

_Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.

Note: Support is generic and can represent various things depending on the voting system used._

### _defaultParams

```solidity
function _defaultParams() internal view virtual returns (bytes)
```

_Default additional encoded parameters used by castVote methods that don't include them

Note: Should be overridden by specific implementations to use an appropriate value, the
meaning of the additional params, in the context of that implementation_

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) public virtual returns (uint256)
```

_See {IGovernor-propose}._

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual returns (uint256)
```

_See {IGovernor-execute}._

### _execute

```solidity
function _execute(uint256, address[] targets, uint256[] values, bytes[] calldatas, bytes32) internal virtual
```

_Internal execution mechanism. Can be overridden to implement different execution mechanism_

### _beforeExecute

```solidity
function _beforeExecute(uint256, address[] targets, uint256[], bytes[] calldatas, bytes32) internal virtual
```

_Hook before execution is triggered._

### _afterExecute

```solidity
function _afterExecute(uint256, address[], uint256[], bytes[], bytes32) internal virtual
```

_Hook after execution is triggered._

### _cancel

```solidity
function _cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal virtual returns (uint256)
```

_Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
canceled to allow distinguishing it from executed proposals.

Emits a {IGovernor-ProposalCanceled} event._

### getVotes

```solidity
function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256)
```

_See {IGovernor-getVotes}._

### getVotesWithParams

```solidity
function getVotesWithParams(address account, uint256 blockNumber, bytes params) public view virtual returns (uint256)
```

_See {IGovernor-getVotesWithParams}._

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256)
```

_See {IGovernor-castVote}._

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReason}._

### castVoteWithReasonAndParams

```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string reason, bytes params) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParams}._

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteBySig}._

### castVoteWithReasonAndParamsBySig

```solidity
function castVoteWithReasonAndParamsBySig(uint256 proposalId, uint8 support, string reason, bytes params, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParamsBySig}._

### _castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason) internal virtual returns (uint256)
```

_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().

Emits a {IGovernor-VoteCast} event._

### _castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason, bytes params) internal virtual returns (uint256)
```

_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.

Emits a {IGovernor-VoteCast} event._

### relay

```solidity
function relay(address target, uint256 value, bytes data) external payable virtual
```

_Relays a transaction or function call to an arbitrary target. In cases where the governance executor
is some contract other than the governor itself, like when using a timelock, this function can be invoked
in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
Note that if the executor is simply the governor itself, use of `relay` is redundant._

### _executor

```solidity
function _executor() internal view virtual returns (address)
```

_Address through which the governor executes action. Will be overloaded by module that execute actions
through another contract such as a timelock._

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC721Receiver-onERC721Received}._

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155Received}._

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155BatchReceived}._

inherits IERC1155Receiver:
inherits IERC721Receiver:
inherits IGovernor:
### COUNTING_MODE

```solidity
function COUNTING_MODE() public pure virtual returns (string)
```

module:voting

_A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.

There are 2 standard keys: `support` and `quorum`.

- `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
- `quorum=bravo` means that only For votes are counted towards quorum.
- `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.

If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
name that describes the behavior. For example:

- `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
- `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.

NOTE: The string can be decoded by the standard
https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
JavaScript class._

### votingDelay

```solidity
function votingDelay() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
leave time for users to buy voting power, or delegate it, before the voting of a proposal starts._

### votingPeriod

```solidity
function votingPeriod() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of blocks, between the vote start and vote ends.

NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
duration compared to the voting delay._

### quorum

```solidity
function quorum(uint256 blockNumber) public view virtual returns (uint256)
```

module:user-config

_Minimum number of cast voted required for a proposal to be successful.

Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes})._

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)
```

module:voting

_Returns whether `account` has cast a vote on `proposalId`._

inherits EIP712:
### _domainSeparatorV4

```solidity
function _domainSeparatorV4() internal view returns (bytes32)
```

_Returns the domain separator for the current chain._

### _hashTypedDataV4

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32)
```

_Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
function returns the hash of the fully encoded EIP712 message for this domain.

This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:

```solidity
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
    keccak256("Mail(address to,string contents)"),
    mailTo,
    keccak256(bytes(mailContents))
)));
address signer = ECDSA.recover(digest, signature);
```_

inherits ERC165:
inherits IERC165:

 --- 
### Events:
inherits IERC1155Receiver:
inherits IERC721Receiver:
inherits IGovernor:
### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)
```

_Emitted when a proposal is created._

### ProposalCanceled

```solidity
event ProposalCanceled(uint256 proposalId)
```

_Emitted when a proposal is canceled._

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Emitted when a proposal is executed._

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason)
```

_Emitted when a vote is cast without params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used._

### VoteCastWithParams

```solidity
event VoteCastWithParams(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params)
```

_Emitted when a vote is cast with params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
`params` are additional encoded parameters. Their intepepretation also depends on the voting module used._

inherits EIP712:
inherits ERC165:
inherits IERC165:

## IVotes

_Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.

_Available since v4.5.__

### Contract
IVotes : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.

_Available since v4.5._

 --- 
### Functions:
### getVotes

```solidity
function getVotes(address account) external view returns (uint256)
```

_Returns the current amount of votes that `account` has._

### getPastVotes

```solidity
function getPastVotes(address account, uint256 blockNumber) external view returns (uint256)
```

_Returns the amount of votes that `account` had at the end of a past block (`blockNumber`)._

### getPastTotalSupply

```solidity
function getPastTotalSupply(uint256 blockNumber) external view returns (uint256)
```

_Returns the total supply of votes available at the end of a past block (`blockNumber`).

NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
Votes that have not been delegated are still part of total supply, even though they would not participate in a
vote._

### delegates

```solidity
function delegates(address account) external view returns (address)
```

_Returns the delegate that `account` has chosen._

### delegate

```solidity
function delegate(address delegatee) external
```

_Delegates votes from the sender to `delegatee`._

### delegateBySig

```solidity
function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external
```

_Delegates votes from signer to `delegatee`._

 --- 
### Events:
### DelegateChanged

```solidity
event DelegateChanged(address delegator, address fromDelegate, address toDelegate)
```

_Emitted when an account changes their delegate._

### DelegateVotesChanged

```solidity
event DelegateVotesChanged(address delegate, uint256 previousBalance, uint256 newBalance)
```

_Emitted when a token transfer or delegate change results in changes to a delegate's number of votes._

## GovernorVotes

_Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.

_Available since v4.3.__

### Contract
GovernorVotes : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.

_Available since v4.3._

 --- 
### Functions:
### constructor

```solidity
constructor(contract IVotes tokenAddress) internal
```

### _getVotes

```solidity
function _getVotes(address account, uint256 blockNumber, bytes) internal view virtual returns (uint256)
```

Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).

inherits Governor:
### receive

```solidity
receive() external payable virtual
```

_Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### name

```solidity
function name() public view virtual returns (string)
```

_See {IGovernor-name}._

### version

```solidity
function version() public view virtual returns (string)
```

_See {IGovernor-version}._

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public pure virtual returns (uint256)
```

_See {IGovernor-hashProposal}.

The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
advance, before the proposal is submitted.

Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
same proposal (with same operation and same description) will have the same id if submitted on multiple governors
across multiple networks. This also means that in order to execute the same operation twice (on the same
governor) the proposer will have to change the description in order to avoid proposal id conflicts._

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

_See {IGovernor-state}._

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalSnapshot}._

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalDeadline}._

### proposalThreshold

```solidity
function proposalThreshold() public view virtual returns (uint256)
```

_Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_._

### _quorumReached

```solidity
function _quorumReached(uint256 proposalId) internal view virtual returns (bool)
```

_Amount of votes already cast passes the threshold limit._

### _voteSucceeded

```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool)
```

_Is the proposal successful or not._

### _countVote

```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes params) internal virtual
```

_Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.

Note: Support is generic and can represent various things depending on the voting system used._

### _defaultParams

```solidity
function _defaultParams() internal view virtual returns (bytes)
```

_Default additional encoded parameters used by castVote methods that don't include them

Note: Should be overridden by specific implementations to use an appropriate value, the
meaning of the additional params, in the context of that implementation_

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) public virtual returns (uint256)
```

_See {IGovernor-propose}._

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual returns (uint256)
```

_See {IGovernor-execute}._

### _execute

```solidity
function _execute(uint256, address[] targets, uint256[] values, bytes[] calldatas, bytes32) internal virtual
```

_Internal execution mechanism. Can be overridden to implement different execution mechanism_

### _beforeExecute

```solidity
function _beforeExecute(uint256, address[] targets, uint256[], bytes[] calldatas, bytes32) internal virtual
```

_Hook before execution is triggered._

### _afterExecute

```solidity
function _afterExecute(uint256, address[], uint256[], bytes[], bytes32) internal virtual
```

_Hook after execution is triggered._

### _cancel

```solidity
function _cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal virtual returns (uint256)
```

_Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
canceled to allow distinguishing it from executed proposals.

Emits a {IGovernor-ProposalCanceled} event._

### getVotes

```solidity
function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256)
```

_See {IGovernor-getVotes}._

### getVotesWithParams

```solidity
function getVotesWithParams(address account, uint256 blockNumber, bytes params) public view virtual returns (uint256)
```

_See {IGovernor-getVotesWithParams}._

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256)
```

_See {IGovernor-castVote}._

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReason}._

### castVoteWithReasonAndParams

```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string reason, bytes params) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParams}._

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteBySig}._

### castVoteWithReasonAndParamsBySig

```solidity
function castVoteWithReasonAndParamsBySig(uint256 proposalId, uint8 support, string reason, bytes params, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParamsBySig}._

### _castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason) internal virtual returns (uint256)
```

_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().

Emits a {IGovernor-VoteCast} event._

### _castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason, bytes params) internal virtual returns (uint256)
```

_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.

Emits a {IGovernor-VoteCast} event._

### relay

```solidity
function relay(address target, uint256 value, bytes data) external payable virtual
```

_Relays a transaction or function call to an arbitrary target. In cases where the governance executor
is some contract other than the governor itself, like when using a timelock, this function can be invoked
in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
Note that if the executor is simply the governor itself, use of `relay` is redundant._

### _executor

```solidity
function _executor() internal view virtual returns (address)
```

_Address through which the governor executes action. Will be overloaded by module that execute actions
through another contract such as a timelock._

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC721Receiver-onERC721Received}._

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155Received}._

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155BatchReceived}._

inherits IERC1155Receiver:
inherits IERC721Receiver:
inherits IGovernor:
### COUNTING_MODE

```solidity
function COUNTING_MODE() public pure virtual returns (string)
```

module:voting

_A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.

There are 2 standard keys: `support` and `quorum`.

- `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
- `quorum=bravo` means that only For votes are counted towards quorum.
- `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.

If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
name that describes the behavior. For example:

- `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
- `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.

NOTE: The string can be decoded by the standard
https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
JavaScript class._

### votingDelay

```solidity
function votingDelay() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
leave time for users to buy voting power, or delegate it, before the voting of a proposal starts._

### votingPeriod

```solidity
function votingPeriod() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of blocks, between the vote start and vote ends.

NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
duration compared to the voting delay._

### quorum

```solidity
function quorum(uint256 blockNumber) public view virtual returns (uint256)
```

module:user-config

_Minimum number of cast voted required for a proposal to be successful.

Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes})._

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)
```

module:voting

_Returns whether `account` has cast a vote on `proposalId`._

inherits EIP712:
### _domainSeparatorV4

```solidity
function _domainSeparatorV4() internal view returns (bytes32)
```

_Returns the domain separator for the current chain._

### _hashTypedDataV4

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32)
```

_Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
function returns the hash of the fully encoded EIP712 message for this domain.

This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:

```solidity
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
    keccak256("Mail(address to,string contents)"),
    mailTo,
    keccak256(bytes(mailContents))
)));
address signer = ECDSA.recover(digest, signature);
```_

inherits ERC165:
inherits IERC165:

 --- 
### Events:
inherits Governor:
inherits IERC1155Receiver:
inherits IERC721Receiver:
inherits IGovernor:
### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)
```

_Emitted when a proposal is created._

### ProposalCanceled

```solidity
event ProposalCanceled(uint256 proposalId)
```

_Emitted when a proposal is canceled._

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Emitted when a proposal is executed._

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason)
```

_Emitted when a vote is cast without params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used._

### VoteCastWithParams

```solidity
event VoteCastWithParams(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params)
```

_Emitted when a vote is cast with params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
`params` are additional encoded parameters. Their intepepretation also depends on the voting module used._

inherits EIP712:
inherits ERC165:
inherits IERC165:

## Checkpoints

_This library defines the `History` struct, for checkpointing values as they change at different points in
time, and later looking up past values by block number. See {Votes} as an example.

To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
checkpoint for the current transaction block using the {push} function.

_Available since v4.5.__

### Contract
Checkpoints : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

This library defines the `History` struct, for checkpointing values as they change at different points in
time, and later looking up past values by block number. See {Votes} as an example.

To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
checkpoint for the current transaction block using the {push} function.

_Available since v4.5._

 --- 
### Functions:
### getAtBlock

```solidity
function getAtBlock(struct Checkpoints.History self, uint256 blockNumber) internal view returns (uint256)
```

_Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
block, the requested block number must be in the past, excluding the current block._

### getAtProbablyRecentBlock

```solidity
function getAtProbablyRecentBlock(struct Checkpoints.History self, uint256 blockNumber) internal view returns (uint256)
```

_Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
checkpoints._

### push

```solidity
function push(struct Checkpoints.History self, uint256 value) internal returns (uint256, uint256)
```

_Pushes a value onto a History so that it is stored as the checkpoint for the current block.

Returns previous value and new value._

### push

```solidity
function push(struct Checkpoints.History self, function (uint256,uint256) view returns (uint256) op, uint256 delta) internal returns (uint256, uint256)
```

_Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
be set to `op(latest, delta)`.

Returns previous value and new value._

### latest

```solidity
function latest(struct Checkpoints.History self) internal view returns (uint224)
```

_Returns the value in the most recent checkpoint, or zero if there are no checkpoints._

### latestCheckpoint

```solidity
function latestCheckpoint(struct Checkpoints.History self) internal view returns (bool exists, uint32 _blockNumber, uint224 _value)
```

_Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
in the most recent checkpoint._

### length

```solidity
function length(struct Checkpoints.History self) internal view returns (uint256)
```

_Returns the number of checkpoint._

### push

```solidity
function push(struct Checkpoints.Trace224 self, uint32 key, uint224 value) internal returns (uint224, uint224)
```

_Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.

Returns previous value and new value._

### lowerLookup

```solidity
function lowerLookup(struct Checkpoints.Trace224 self, uint32 key) internal view returns (uint224)
```

_Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none._

### upperLookup

```solidity
function upperLookup(struct Checkpoints.Trace224 self, uint32 key) internal view returns (uint224)
```

_Returns the value in the most recent checkpoint with key lower or equal than the search key._

### latest

```solidity
function latest(struct Checkpoints.Trace224 self) internal view returns (uint224)
```

_Returns the value in the most recent checkpoint, or zero if there are no checkpoints._

### latestCheckpoint

```solidity
function latestCheckpoint(struct Checkpoints.Trace224 self) internal view returns (bool exists, uint32 _key, uint224 _value)
```

_Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
in the most recent checkpoint._

### length

```solidity
function length(struct Checkpoints.Trace224 self) internal view returns (uint256)
```

_Returns the number of checkpoint._

### push

```solidity
function push(struct Checkpoints.Trace160 self, uint96 key, uint160 value) internal returns (uint160, uint160)
```

_Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.

Returns previous value and new value._

### lowerLookup

```solidity
function lowerLookup(struct Checkpoints.Trace160 self, uint96 key) internal view returns (uint160)
```

_Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none._

### upperLookup

```solidity
function upperLookup(struct Checkpoints.Trace160 self, uint96 key) internal view returns (uint160)
```

_Returns the value in the most recent checkpoint with key lower or equal than the search key._

### latest

```solidity
function latest(struct Checkpoints.Trace160 self) internal view returns (uint160)
```

_Returns the value in the most recent checkpoint, or zero if there are no checkpoints._

### latestCheckpoint

```solidity
function latestCheckpoint(struct Checkpoints.Trace160 self) internal view returns (bool exists, uint96 _key, uint160 _value)
```

_Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
in the most recent checkpoint._

### length

```solidity
function length(struct Checkpoints.Trace160 self) internal view returns (uint256)
```

_Returns the number of checkpoint._

## GovernorVotesQuorumFraction

_Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
fraction of the total supply.

_Available since v4.3.__

### Contract
GovernorVotesQuorumFraction : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction_flattened.sol

Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
fraction of the total supply.

_Available since v4.3._

 --- 
### Functions:
### constructor

```solidity
constructor(uint256 quorumNumeratorValue) internal
```

_Initialize quorum as a fraction of the token's total supply.

The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
customized by overriding {quorumDenominator}._

### quorumNumerator

```solidity
function quorumNumerator() public view virtual returns (uint256)
```

_Returns the current quorum numerator. See {quorumDenominator}._

### quorumNumerator

```solidity
function quorumNumerator(uint256 blockNumber) public view virtual returns (uint256)
```

_Returns the quorum numerator at a specific block number. See {quorumDenominator}._

### quorumDenominator

```solidity
function quorumDenominator() public view virtual returns (uint256)
```

_Returns the quorum denominator. Defaults to 100, but may be overridden._

### quorum

```solidity
function quorum(uint256 blockNumber) public view virtual returns (uint256)
```

_Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`._

### updateQuorumNumerator

```solidity
function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual
```

_Changes the quorum numerator.

Emits a {QuorumNumeratorUpdated} event.

Requirements:

- Must be called through a governance proposal.
- New numerator must be smaller or equal to the denominator._

### _updateQuorumNumerator

```solidity
function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual
```

_Changes the quorum numerator.

Emits a {QuorumNumeratorUpdated} event.

Requirements:

- New numerator must be smaller or equal to the denominator._

inherits GovernorVotes:
### _getVotes

```solidity
function _getVotes(address account, uint256 blockNumber, bytes) internal view virtual returns (uint256)
```

Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).

inherits Governor:
### receive

```solidity
receive() external payable virtual
```

_Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### name

```solidity
function name() public view virtual returns (string)
```

_See {IGovernor-name}._

### version

```solidity
function version() public view virtual returns (string)
```

_See {IGovernor-version}._

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public pure virtual returns (uint256)
```

_See {IGovernor-hashProposal}.

The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
advance, before the proposal is submitted.

Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
same proposal (with same operation and same description) will have the same id if submitted on multiple governors
across multiple networks. This also means that in order to execute the same operation twice (on the same
governor) the proposer will have to change the description in order to avoid proposal id conflicts._

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

_See {IGovernor-state}._

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalSnapshot}._

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalDeadline}._

### proposalThreshold

```solidity
function proposalThreshold() public view virtual returns (uint256)
```

_Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_._

### _quorumReached

```solidity
function _quorumReached(uint256 proposalId) internal view virtual returns (bool)
```

_Amount of votes already cast passes the threshold limit._

### _voteSucceeded

```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool)
```

_Is the proposal successful or not._

### _countVote

```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes params) internal virtual
```

_Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.

Note: Support is generic and can represent various things depending on the voting system used._

### _defaultParams

```solidity
function _defaultParams() internal view virtual returns (bytes)
```

_Default additional encoded parameters used by castVote methods that don't include them

Note: Should be overridden by specific implementations to use an appropriate value, the
meaning of the additional params, in the context of that implementation_

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) public virtual returns (uint256)
```

_See {IGovernor-propose}._

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual returns (uint256)
```

_See {IGovernor-execute}._

### _execute

```solidity
function _execute(uint256, address[] targets, uint256[] values, bytes[] calldatas, bytes32) internal virtual
```

_Internal execution mechanism. Can be overridden to implement different execution mechanism_

### _beforeExecute

```solidity
function _beforeExecute(uint256, address[] targets, uint256[], bytes[] calldatas, bytes32) internal virtual
```

_Hook before execution is triggered._

### _afterExecute

```solidity
function _afterExecute(uint256, address[], uint256[], bytes[], bytes32) internal virtual
```

_Hook after execution is triggered._

### _cancel

```solidity
function _cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal virtual returns (uint256)
```

_Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
canceled to allow distinguishing it from executed proposals.

Emits a {IGovernor-ProposalCanceled} event._

### getVotes

```solidity
function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256)
```

_See {IGovernor-getVotes}._

### getVotesWithParams

```solidity
function getVotesWithParams(address account, uint256 blockNumber, bytes params) public view virtual returns (uint256)
```

_See {IGovernor-getVotesWithParams}._

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256)
```

_See {IGovernor-castVote}._

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReason}._

### castVoteWithReasonAndParams

```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string reason, bytes params) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParams}._

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteBySig}._

### castVoteWithReasonAndParamsBySig

```solidity
function castVoteWithReasonAndParamsBySig(uint256 proposalId, uint8 support, string reason, bytes params, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParamsBySig}._

### _castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason) internal virtual returns (uint256)
```

_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().

Emits a {IGovernor-VoteCast} event._

### _castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason, bytes params) internal virtual returns (uint256)
```

_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.

Emits a {IGovernor-VoteCast} event._

### relay

```solidity
function relay(address target, uint256 value, bytes data) external payable virtual
```

_Relays a transaction or function call to an arbitrary target. In cases where the governance executor
is some contract other than the governor itself, like when using a timelock, this function can be invoked
in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
Note that if the executor is simply the governor itself, use of `relay` is redundant._

### _executor

```solidity
function _executor() internal view virtual returns (address)
```

_Address through which the governor executes action. Will be overloaded by module that execute actions
through another contract such as a timelock._

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC721Receiver-onERC721Received}._

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155Received}._

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155BatchReceived}._

inherits IERC1155Receiver:
inherits IERC721Receiver:
inherits IGovernor:
### COUNTING_MODE

```solidity
function COUNTING_MODE() public pure virtual returns (string)
```

module:voting

_A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.

There are 2 standard keys: `support` and `quorum`.

- `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
- `quorum=bravo` means that only For votes are counted towards quorum.
- `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.

If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
name that describes the behavior. For example:

- `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
- `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.

NOTE: The string can be decoded by the standard
https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
JavaScript class._

### votingDelay

```solidity
function votingDelay() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
leave time for users to buy voting power, or delegate it, before the voting of a proposal starts._

### votingPeriod

```solidity
function votingPeriod() public view virtual returns (uint256)
```

module:user-config

_Delay, in number of blocks, between the vote start and vote ends.

NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
duration compared to the voting delay._

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)
```

module:voting

_Returns whether `account` has cast a vote on `proposalId`._

inherits EIP712:
### _domainSeparatorV4

```solidity
function _domainSeparatorV4() internal view returns (bytes32)
```

_Returns the domain separator for the current chain._

### _hashTypedDataV4

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32)
```

_Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
function returns the hash of the fully encoded EIP712 message for this domain.

This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:

```solidity
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
    keccak256("Mail(address to,string contents)"),
    mailTo,
    keccak256(bytes(mailContents))
)));
address signer = ECDSA.recover(digest, signature);
```_

inherits ERC165:
inherits IERC165:

 --- 
### Events:
### QuorumNumeratorUpdated

```solidity
event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator)
```

inherits GovernorVotes:
inherits Governor:
inherits IERC1155Receiver:
inherits IERC721Receiver:
inherits IGovernor:
### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)
```

_Emitted when a proposal is created._

### ProposalCanceled

```solidity
event ProposalCanceled(uint256 proposalId)
```

_Emitted when a proposal is canceled._

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Emitted when a proposal is executed._

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason)
```

_Emitted when a vote is cast without params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used._

### VoteCastWithParams

```solidity
event VoteCastWithParams(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params)
```

_Emitted when a vote is cast with params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
`params` are additional encoded parameters. Their intepepretation also depends on the voting module used._

inherits EIP712:
inherits ERC165:
inherits IERC165:

