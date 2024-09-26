# Solidity API

## GovernorVotes

_Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.

_Available since v4.3.__

### Contract
GovernorVotes : 0x/@openzeppelin/contracts/governance/extensions/GovernorVotes.sol

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

