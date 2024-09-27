# Solidity API

## LibERC20TokenV06

### Contract
LibERC20TokenV06 : 0x(copy)/contracts/erc20/src/v06/LibERC20TokenV06.sol

 --- 
### Functions:
### compatApprove

```solidity
function compatApprove(contract IERC20Token token, address spender, uint256 allowance) internal
```

_Calls `IERC20Token(token).approve()`.
     Reverts if the return data is invalid or the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |
| spender | address | The address that receives an allowance. |
| allowance | uint256 | The allowance to set. |

### approveIfBelow

```solidity
function approveIfBelow(contract IERC20Token token, address spender, uint256 amount) internal
```

_Calls `IERC20Token(token).approve()` and sets the allowance to the
     maximum if the current approval is not already >= an amount.
     Reverts if the return data is invalid or the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |
| spender | address | The address that receives an allowance. |
| amount | uint256 | The minimum allowance needed. |

### compatTransfer

```solidity
function compatTransfer(contract IERC20Token token, address to, uint256 amount) internal
```

_Calls `IERC20Token(token).transfer()`.
     Reverts if the return data is invalid or the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |
| to | address | The address that receives the tokens |
| amount | uint256 | Number of tokens to transfer. |

### compatTransferFrom

```solidity
function compatTransferFrom(contract IERC20Token token, address from, address to, uint256 amount) internal
```

_Calls `IERC20Token(token).transferFrom()`.
     Reverts if the return data is invalid or the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |
| from | address | The owner of the tokens. |
| to | address | The address that receives the tokens |
| amount | uint256 | Number of tokens to transfer. |

### compatDecimals

```solidity
function compatDecimals(contract IERC20Token token) internal view returns (uint8 tokenDecimals)
```

_Retrieves the number of decimals for a token.
     Returns `18` if the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenDecimals | uint8 | The number of decimals places for the token. |

### compatAllowance

```solidity
function compatAllowance(contract IERC20Token token, address owner, address spender) internal view returns (uint256 allowance_)
```

_Retrieves the allowance for a token, owner, and spender.
     Returns `0` if the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |
| owner | address | The owner of the tokens. |
| spender | address | The address the spender. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| allowance_ | uint256 | The allowance for a token, owner, and spender. |

### compatBalanceOf

```solidity
function compatBalanceOf(contract IERC20Token token, address owner) internal view returns (uint256 balance)
```

_Retrieves the balance for a token owner.
     Returns `0` if the call reverts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IERC20Token | The address of the token contract. |
| owner | address | The owner of the tokens. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| balance | uint256 | The token balance of an owner. |

