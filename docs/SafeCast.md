# Solidity API

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
SafeCast : 0x/@openzeppelin/contracts/utils/math/SafeCast.sol

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

