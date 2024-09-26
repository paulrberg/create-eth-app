# Solidity API

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
DoubleEndedQueue : 0x/@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol

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

