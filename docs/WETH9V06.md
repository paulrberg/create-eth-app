# Solidity API

## WETH9V06

### Contract
WETH9V06 : 0x(copy)/contracts/erc20/src/v06/WETH9V06.sol

 --- 
### Functions:
### receive

```solidity
receive() external payable
```

### deposit

```solidity
function deposit() public payable
```

### withdraw

```solidity
function withdraw(uint256 wad) public
```

### totalSupply

```solidity
function totalSupply() public view returns (uint256)
```

### approve

```solidity
function approve(address guy, uint256 wad) public returns (bool)
```

### transfer

```solidity
function transfer(address dst, uint256 wad) public returns (bool)
```

### transferFrom

```solidity
function transferFrom(address src, address dst, uint256 wad) public returns (bool)
```

 --- 
### Events:
### Approval

```solidity
event Approval(address _owner, address _spender, uint256 _value)
```

### Transfer

```solidity
event Transfer(address _from, address _to, uint256 _value)
```

### Deposit

```solidity
event Deposit(address _owner, uint256 _value)
```

### Withdrawal

```solidity
event Withdrawal(address _owner, uint256 _value)
```

