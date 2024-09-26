# Solidity API

## IERC20Permit

_Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].

Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
need to send a transaction, and thus is not required to hold Ether at all._

### Contract
IERC20Permit : 0x/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].

Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
need to send a transaction, and thus is not required to hold Ether at all.

 --- 
### Functions:
### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

_Sets `value` as the allowance of `spender` over ``owner``'s tokens,
given ``owner``'s signed approval.

IMPORTANT: The same issues {IERC20-approve} has related to transaction
ordering also apply here.

Emits an {Approval} event.

Requirements:

- `spender` cannot be the zero address.
- `deadline` must be a timestamp in the future.
- `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
over the EIP712-formatted function arguments.
- the signature must use ``owner``'s current nonce (see {nonces}).

For more information on the signature format, see the
https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
section]._

### nonces

```solidity
function nonces(address owner) external view returns (uint256)
```

_Returns the current nonce for `owner`. This value must be
included whenever a signature is generated for {permit}.

Every successful call to {permit} increases ``owner``'s nonce by one. This
prevents a signature from being used multiple times._

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```

_Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}._

