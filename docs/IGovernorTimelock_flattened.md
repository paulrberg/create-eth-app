# Solidity API

## IERC165

_Interface of the ERC165 standard, as defined in the
https://eips.ethereum.org/EIPS/eip-165[EIP].

Implementers can declare support of contract interfaces, which can then be
queried by others ({ERC165Checker}).

For an implementation, see {ERC165}._

### Contract
IERC165 : 0x/@openzeppelin/contracts/governance/extensions/IGovernorTimelock_flattened.sol

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
ERC165 : 0x/@openzeppelin/contracts/governance/extensions/IGovernorTimelock_flattened.sol

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

## IGovernor

_Interface of the {Governor} core.

_Available since v4.3.__

### Contract
IGovernor : 0x/@openzeppelin/contracts/governance/extensions/IGovernorTimelock_flattened.sol

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

## IGovernorTimelock

_Extension of the {IGovernor} for timelock supporting modules.

_Available since v4.3.__

### Contract
IGovernorTimelock : 0x/@openzeppelin/contracts/governance/extensions/IGovernorTimelock_flattened.sol

Extension of the {IGovernor} for timelock supporting modules.

_Available since v4.3._

 --- 
### Functions:
### timelock

```solidity
function timelock() public view virtual returns (address)
```

### proposalEta

```solidity
function proposalEta(uint256 proposalId) public view virtual returns (uint256)
```

### queue

```solidity
function queue(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public virtual returns (uint256 proposalId)
```

inherits IGovernor:
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
### ProposalQueued

```solidity
event ProposalQueued(uint256 proposalId, uint256 eta)
```

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

inherits IERC165:

