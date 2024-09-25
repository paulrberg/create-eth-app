# Uniswap v4 Core

[![Lint](https://github.com/Uniswap/v4-core/actions/workflows/lint.yml/badge.svg)](https://github.com/Uniswap/v4-core/actions/workflows/lint.yml)
[![Tests](https://github.com/Uniswap/v4-core/actions/workflows/tests-merge.yml/badge.svg)](https://github.com/Uniswap/v4-core/actions/workflows/tests-merge.yml)

Uniswap v4 is a new automated market maker protocol that provides extensible and customizable pools. `v4-core` hosts the core pool logic for creating pools and executing pool actions like swapping and providing liquidity.

The contracts in this repo are in early stages - we are releasing the draft code now so that v4 can be built in public, with open feedback and meaningful community contribution. We expect this will be a months-long process, and we appreciate any kind of contribution, no matter how small.

## Contributing

If you’re interested in contributing please see our [contribution guidelines](./CONTRIBUTING.md)!

## Whitepaper

A more detailed description of Uniswap v4 Core can be found in the draft of the [Uniswap v4 Core Whitepaper](./docs/whitepaper-v4.pdf).

## Architecture

`v4-core` uses a singleton-style architecture, where all pool state is managed in the `PoolManager.sol` contract. Pool actions can be taken after an initial call to `unlock`. Integrators implement the `unlockCallback` and proceed with any of the following actions on the pools:

- `swap`
- `modifyLiquidity`
- `donate`
- `take`
- `settle`
- `mint`
- `burn`

Note that pool initialization can happen outside the context of unlocking the PoolManager.

Only the net balances owed to the user (positive) or to the pool (negative) are tracked throughout the duration of an unlock. This is the `delta` field held in the unlock state. Any number of actions can be run on the pools, as long as the deltas accumulated during the unlock reach 0 by the unlock’s release. This unlock and call style architecture gives callers maximum flexibility in integrating with the core code.

Additionally, a pool may be initialized with a hook contract, that can implement any of the following callbacks in the lifecycle of pool actions:

- {before,after}Initialize
- {before,after}AddLiquidity
- {before,after}RemoveLiquidity
- {before,after}Swap
- {before,after}Donate

The callback logic, may be updated by the hooks dependent on their implementation. However _which_ callbacks are executed on a pool cannot change after pool initialization.

## Repository Structure

All contracts are held within the `v4-core/src` folder.

Note that helper contracts used by tests are held in the `v4-core/src/test` subfolder within the `src` folder. Any new test helper contracts should be added here, but all foundry tests are in the `v4-core/test` folder.

```markdown
src/
----interfaces/
    | IPoolManager.sol
    | ...
----libraries/
    | Position.sol
    | Pool.sol
    | ...
----test
----PoolManager.sol
...
test/
----libraries/
    | Position.t.sol
    | Pool.t.sol
```

## Local deployment and Usage

To utilize the contracts and deploy to a local testnet, you can install the code in your repo with forge:

```markdown
forge install https://github.com/Uniswap/v4-core
```

To integrate with the contracts, the interfaces are available to use:

```solidity

import {IPoolManager} from 'v4-core/contracts/interfaces/IPoolManager.sol';
import {IUnlockCallback} from 'v4-core/contracts/interfaces/callback/IUnlockCallback.sol';

contract MyContract is IUnlockCallback {
    IPoolManager poolManager;

    function doSomethingWithPools() {
        // this function will call `unlockCallback` below
        poolManager.unlock(...);
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        // perform pool actions
        poolManager.swap(...)
    }
}

```

## License

The primary license for Uniswap V4 Core is the Business Source License 1.1 (`BUSL-1.1`), see [LICENSE](https://github.com/Uniswap/v4-core/blob/main/LICENSE). Minus the following exceptions:

- Some [libraries](./src/libraries) have a GPL license
- Both [FullMath.sol](./src/libraries/FullMath.sol) and [Hooks.sol](./src/libraries/Hooks.sol) have an MIT License
- [Interfaces](./src/interfaces) and [types](./src/types/) have an MIT license

Each of these files states their license type.
