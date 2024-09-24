<a name="introduction"/></a>

# EigenLayer
<p align="center"><b><font size="+1">
🚧 The Slasher contract is under active development and its interface expected to change. We recommend writing slashing logic without integrating with the Slasher at this point in time. 🚧
</font></b><p>
EigenLayer (formerly 'EigenLayr') is a set of smart contracts deployed on Ethereum that enable restaking of assets to secure new services.
At present, this repository contains *both* the contracts for EigenLayer *and* a set of general "middleware" contracts, designed to be reusable across different applications built on top of EigenLayer.

Note that the interactions between middleware and EigenLayer are not yet "set in stone", and may change somewhat prior to the platform being fully live on mainnet; in particular, payment architecture is likely to evolve. As such, the "middleware" contracts should not be treated as definitive, but merely as a helpful reference, at least until the architecture is more settled.

Click the links in the Table of Contents below to access more specific documentation. We recommend starting with the [EigenLayer Technical Specification](docs/EigenLayer-tech-spec.md) to get a better overview before diving into any of the other docs.  For contracts addresses deployed on Goerli, click [here](https://github.com/Layr-Labs/eigenlayer-contracts/blob/master/script/output/M1_deployment_goerli_2023_3_23.json).
## Table of Contents  
* [Introduction](#introduction)
* [Installation and Running Tests / Analyzers](#installation)
* [EigenLayer Technical Specification](docs/EigenLayer-tech-spec.md)

Design Docs
* [Withdrawals Design Doc](docs/Guaranteed-stake-updates.md)
* [EigenPods Design Doc](docs/EigenPods.md)

Flow Docs
* [EigenLayer Withdrawal Flow](docs/EigenLayer-withdrawal-flow.md)
* [EigenLayer Deposit Flow](docs/EigenLayer-deposit-flow.md)
* [EigenLayer Delegation Flow](docs/EigenLayer-delegation-flow.md)
* [Middleware Registration Flow for Operators](docs/Middleware-registration-operator-flow.md)

<a name="installation"/></a>
## Installation and Running Tests / Analyzers

### Installation

```
foundryup

forge install
```

This repository uses Foundry as a smart contract development toolchain.

See the [Foundry Docs](https://book.getfoundry.sh/) for more info on installation and usage.

### Natspec Documentation

You will notice that we also have hardhat installed in this repo. This is only used to generate natspec [docgen](https://github.com/OpenZeppelin/solidity-docgen). This is our workaround until foundry [finishes implementing](https://github.com/foundry-rs/foundry/issues/1675) the `forge doc` command.

To generate the docs, run `npx hardhat docgen` (you may need to run `npm install` first). The output is located in `docs/docgen`

### Run Tests

Prior to running tests, you should set up your environment. At present this repository contains fork tests against ETH mainnet; your environment will use an `RPC_MAINNET` key to run these tests. See the `.env.example` file for an example -- two simple options are to  copy the LlamaNodes RPC url to your `env` or use your own infura API key in the provided format. If you don't set the `RPC_MAINNET` key then the test cases will default to LlamaNodes RPC url when fork testing.

The main command to run tests is:

`forge test -vv`

### Run Tests on a Fork
Environment config is contained in config.yml.  Before running the following commands, [install yq](https://mikefarah.gitbook.io/yq/v/v3.x/).  Then set up the environment with this script:

`source source-env.sh [CHAIN]`

for example, on goerli: `source source-env.sh goerli`.  Currently options for `[CHAIN]` are `goerli`, `local`.  Then to run the actual tests:

`forge test --fork-url [RPC_URL]`

### Run Static Analysis

`solhint 'src/contracts/**/*.sol'`

`slither .`

### Generate Inheritance and Control-Flow Graphs

first [install surya](https://github.com/ConsenSys/surya/)

then run

`surya inheritance ./src/contracts/**/*.sol | dot -Tpng > InheritanceGraph.png`

and/or

`surya graph ./src/contracts/middleware/*.sol | dot -Tpng > MiddlewareControlFlowGraph.png`

and/or

`surya mdreport surya_report.md ./src/contracts/**/*.sol`

## Deployments

### M1 (Current Mainnet Deployment)

| Name | Solidity | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- | -------- | 
| StrategyManager | [`StrategyManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/StrategyManager.sol) | [`0x8586...075A`](https://etherscan.io/address/0x858646372CC42E1A627fcE94aa7A7033e7CF075A) | [`0x5d25...42Fb`](https://etherscan.io/address/0x5d25EEf8CfEdaA47d31fE2346726dE1c21e342Fb) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| Strategy: cbETH | [`StrategyBaseTVLLimits`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/strategies/StrategyBaseTVLLimits.sol) | [`0x5494...56bc`](https://etherscan.io/address/0x54945180dB7943c0ed0FEE7EdaB2Bd24620256bc) | [`0xdfdA...46d3`](https://etherscan.io/address/0xdfdA04f980bE6A64E3607c95Ca26012Ab9aA46d3) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| Strategy: stETH | [`StrategyBaseTVLLimits`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/strategies/StrategyBaseTVLLimits.sol) | [`0x93c4...564D`](https://etherscan.io/address/0x93c4b944D05dfe6df7645A86cd2206016c51564D) | [`0xdfdA...46d3`](https://etherscan.io/address/0xdfdA04f980bE6A64E3607c95Ca26012Ab9aA46d3) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| Strategy: rETH | [`StrategyBaseTVLLimits`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/strategies/StrategyBaseTVLLimits.sol) | [`0x1BeE...dCD2`](https://etherscan.io/address/0x1BeE69b7dFFfA4E2d53C2a2Df135C388AD25dCD2) | [`0xdfdA...46d3`](https://etherscan.io/address/0xdfdA04f980bE6A64E3607c95Ca26012Ab9aA46d3) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| EigenPodManager | [`EigenPodManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/pods/EigenPodManager.sol) | [`0x91E6...A338`](https://etherscan.io/address/0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338) | [`0xEB86...e111`](https://etherscan.io/address/0xEB86a5c40FdE917E6feC440aBbCDc80E3862e111) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| EigenPod (beacon) | [`EigenPod`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/pods/EigenPod.sol) | [`0x5a2a...9073`](https://etherscan.io/address/0x5a2a4F2F3C18f09179B6703e63D9eDD165909073) | [`0x5c86...9dA7`](https://etherscan.io/address/0x5c86e9609fbBc1B754D0FD5a4963Fdf0F5b99dA7) | - Beacon: [OpenZeppelin BeaconProxy@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/beacon/BeaconProxy.sol) <br />- Deployed pods use [UpgradableBeacon@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/beacon/UpgradeableBeacon.sol) |
| DelayedWithdrawalRouter | [`DelayedWithdrawalRouter`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/pods/DelayedWithdrawalRouter.sol) | [`0x7Fe7...23D8`](https://etherscan.io/address/0x7Fe7E9CC0F274d2435AD5d56D5fa73E47F6A23D8) | [`0x44Bc...E2AF`](https://etherscan.io/address/0x44Bcb0E01CD0C5060D4Bb1A07b42580EF983E2AF) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| DelegationManager | [`DelegationManager`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/DelegationManager.sol) | [`0x3905...f37A`](https://etherscan.io/address/0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A) | [`0xf97E...75e4`](https://etherscan.io/address/0xf97E97649Da958d290e84E6D571c32F4b7F475e4) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| Slasher | [`Slasher`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/core/Slasher.sol) | [`0xD921...c3Cd`](https://etherscan.io/address/0xD92145c07f8Ed1D392c1B88017934E301CC1c3Cd) | [`0xef31...d6d8`](https://etherscan.io/address/0xef31c292801f24f16479DD83197F1E6AeBb8d6d8) | Proxy: [OpenZeppelin TUP@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) |
| PauserRegistry | [`PauserRegistry`](https://github.com/Layr-Labs/eigenlayer-contracts/blob/0139d6213927c0a7812578899ddd3dda58051928/src/contracts/permissions/PauserRegistry.sol) | - | [`0x0c43...7060`](https://etherscan.io/address/0x0c431C66F4dE941d089625E5B423D00707977060) | |
| Pauser Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0x5050…2390`](https://etherscan.io/address/0x5050389572f2d220ad927CcbeA0D406831012390) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Community Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0xFEA4...c598`](https://etherscan.io/address/0xFEA47018D632A77bA579846c840d5706705Dc598) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Executor Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0x369e...9111`](https://etherscan.io/address/0x369e6F597e22EaB55fFb173C6d9cD234BD699111) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Operations Multisig | [`GnosisSafe@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol) | [`0xBE16...3e90`](https://etherscan.io/address/0xBE1685C81aA44FF9FB319dD389addd9374383e90) | [`0xd9db...9552`](https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552) | Proxy: [`GnosisSafeProxy@1.3.0`](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxy.sol) |
| Timelock | [Compound: `Timelock.sol`](https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/Timelock.sol) | - | [`0xA6Db...0EAF`](https://etherscan.io/address/0xA6Db1A8C5a981d1536266D2a393c5F8dDb210EAF) | |
| Proxy Admin | [OpenZeppelin ProxyAdmin@4.7.1](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/proxy/transparent/ProxyAdmin.sol) | - | [`0x8b95...2444`](https://etherscan.io/address/0x8b9566AdA63B64d1E1dcF1418b43fd1433b72444) | |
