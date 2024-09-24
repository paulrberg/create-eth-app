# Lyra - Smart Contracts
[![CI](https://github.com/lyra-finance/lyra/actions/workflows/run-test.yml/badge.svg)](https://github.com/lyra-finance/lyra/actions/workflows/run-test.yml)
[![codecov](https://codecov.io/gh/lyra-finance/lyra/branch/master/graph/badge.svg?token=PQZNKHH63H)](https://codecov.io/gh/lyra-finance/lyra)

:warning: This SDK is in open alpha and is constantly under development.
:warning: GWAVOracle.sol and LyraAdapter.sol not yet audited.

1. [Avalon documentation](#docs)
2. [Installation](#install)
3. [Importing Lyra into your contract](#imports)
4. [Lyra integration testing](#hardhat)
5. [Call Lyra on kovan/mainnet](#deploys)
6. [Deploy Lyra to localhost](#localhost)
7. [Advanced](#advanced)
8. [Useful calls/common errors](#useful)

## Documentation <a name="docs"></a>

Avalon docs under development: [Avalon Docs](https://docs.lyra.finance/)

## Installation <a name="install"></a>
```bash
$ yarn add @lyrafinance/protocol
$ yarn add hardhat-dependency-compiler
```

Include the dependency compiler plug-in in your `hardhat.config.ts`:
```typescript
import 'hardhat-dependency-compiler'
import { lyraContractPaths } from '@lyrafinance/protocol/dist/test/utils/package/index-paths'

export default {
  // other hardhat config params...
  dependencyCompiler: {
    paths: lyraContractPaths,
  }
}
```

## Importing Lyra into your contract <a name="imports"></a>

```solidity
import {LyraAdapter} from '@lyrafinance/protocol/contracts/periphery/LyraAdapter.sol';

contract DeltaStrategy is LyraAdapter {
  // your structured product contract
}
```

Refer to the [lyra-vaults](https://github.com/lyra-finance/lyra-vaults/blob/master/contracts/strategies/StrategyBase.sol) on using the `LyraAdapter` to connect your contract to Lyra.

## Lyra integration testing <a name="hardhat"></a>

Deploy a full Lyra market in hardhat without need for custom mock contracts.
```typescript
import { TestSystem } from '@lyrafinance/protocol'

describe('Integration Test', () => {
  before(async () => {
    let testSystem = await TestSystem.deploy(signer);
    await TestSystem.seed(signer, testSystem);
  });

  it('your integration test', async () => {
    ...
  });
});
```

Open position and confirm correct payout example test:
```typescript
it('will pay out long calls', async () => {
  boardIds = await testSystem.optionMarket.getLiveBoards();
  strikeIds = await testSystem.optionMarket.getBoardStrikes(boardIds[0]);

  // Buy long call
  await testSystem.optionMarket.openPosition( {
    strikeId: strikeIds[0],
    positionId: 0,
    amount: toBN('1'),
    setCollateralTo: 0,
    iterations: 1,
    minTotalCost: 0,
    maxTotalCost: MAX_UINT,
    optionType: TestSystem.OptionType.LONG_CALL
  });

  // Wait till board expires
  await fastForward(MONTH_SEC);

  // Mock sETH price
  await TestSystem.mockPrice(testSystem, toBN("1500"), 'sETH');

  // Settle option and confirm payout
  await testSystem.optionMarket.settleExpiredBoard(boardIds[0]);
  const preBalance = await testSystem.snx.quoteAsset.balanceOf(signer.address);
  await testSystem.shortCollateral.settleOptions([strikeIds[0]]);
  const postBalance = await testSystem.snx.quoteAsset.balanceOf(signer.address);
  expect(postBalance.sub(preBalance)).to.eq(toBN('500'));
});
```

Refer to the [integration testing example](https://github.com/lyra-finance/lyra-vaults/tree/master/test/integration-tests) on hardhat testing against a mock Lyra market.

## Call Lyra on kovan-ovm/mainnet-ovm  <a name="deploys"></a>
```typescript
import { getMarketDeploys, getGlobalDeploys } from '@lyrafinance/protocol';

// get lyra address/abi/bytecode/more
let lyraMarket = await getMarketDeploys('kovan-ovm', 'sETH');
let lyraGlobal = await getGlobalDeploys('kovan-ovm');

const testFaucet = new Contract(lyraGlobal.TestFaucet.address, lyraGlobal.TestFaucet.abi, deployer);
const sUSD = new Contract(lyraGlobal.QuoteAsset.address, lyraGlobal.QuoteAsset.abi, deployer);
const optionMarket = new Contract(lyraMarket.OptionMarket.address, lyraMarket.OptionMarket.abi, deployer);

// call lyra (`execute` is any implementation of a contract call)
await execute(testFaucet, 'drip', [] as any, provider);
await execute(sUSD, 'approve', [optionMarket.address, MAX_UINT], provider);
await execute(optionMarket, 'openPosition', [tradeParams], provider);
```

Refer to the [lyra-vaults kovan/mainnet scripts](https://github.com/lyra-finance/lyra-vaults/tree/master/scripts) for calling kovan/main-net Lyra markets.

## Deploy Lyra to localhost  <a name="localhost"></a>
```typescript
// deployLyraExample.ts
import { TestSystem } from '@lyrafinance/protocol';

async function main() {
  // 1. create local deployer and network
  const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
  const privateKey = 'local eth address with ETH';

  // 2. optional settings to prevent errors
  provider.getGasPrice = async () => { return ethers.BigNumber.from('0'); };
  provider.estimateGas = async () => { return ethers.BigNumber.from(15000000); }
  const deployer = new ethers.Wallet(privateKey, provider);

  // 3. deploy and seed Lyra market
  let linkTracer = false;
  let exportAddresses = true;
  let localTestSystem = await TestSystem.deploy(deployer, linkTracer, exportAddresses);
  await TestSystem.seed(deployer, localTestSystem, overrides={});

  // 4. call local contracts
  await localTestSystem.optionMarket.openPosition({
    strikeId: 1;
    positionId: 0;
    optionType: TestSystem.OptionType.LONG_CALL;
    amount: toBN("1");
    setCollateralTo: toBN("0");
    iterations: 3;
    minTotalCost: toBN("0");
    maxTotalCost?: toBN("250");
  };)
```

```bash
$ yarn hardhat node 
$ yarn hardhat run deployLyraExample.ts // in a separate window
```
> Can also use `getGlobal/MarketDeploys` on local network by setting `exportAddresses=true`

Refer to the [lyra-vaults localhost deploy scripts](https://github.com/lyra-finance/lyra-vaults/tree/master/scripts) for creating a local Lyra market.

## Advanced <a name="advanced"></a>

For overriding specific parameters when using `TestSystem.deploy()` or `TestSystem.seed()`

```typescript
const overrides: DeployOverrides = { 
  optionMarketParams: {
    ...lyraCore.defaultParams.optionMarketPerams, feePortionReserved: toBN('0.05')
  }
}
```

For easy debugging, set `linkTracer = true` to use `hardhat-tracer` to display all emitted events for every hardhat contract call (does not work in local/kovan/main-net yet)
```typescript
let linkTracer=true;
let localTestSystem = await deployTestSystem(deployer, linkTracer);
```

Run your test scripts with the `yarn test --logs` to enable the plug-in.
As `hardhat-tracer` does not log on reverted calls, rely on CustomErrors thrown by the core Lyra contracts.

## Useful calls / common errors [WIP]  <a name="useful"></a>

For local/hardhat:
- `testSystem.optionGreekCache.updateBoardCachedGreeks(boardId)` to prevent deposit/withdraw early returns when boards stale
- `testSystem.optionMarket.settleBoard(boardId)` before settling individual positions
- `testSystem.mockPrice()` to set mock prices 
- `lyraEvm.fastForward(jumpTime)`to jump to expiry/fast-forward
- use `DeployOverride` and `SeedOverride` during `testSystem.deploy/seed` for setting custom market params such as `standardSize`, `minDelta` and etc. 

Refer to the [lyra-vaults example project](https://github.com/lyra-finance/lyra-vaults/tree/master/test/integration-tests) for example usage of above functions.

### Slither (dev)

To run slither, install it via [instructions found in the slither repo](https://github.com/crytic/slither#how-to-install), and then run the following command: `slither  --exclude-informational --exclude-optimization .`

To prevent false-positives in runs of `slither`, `slither.db.json` has been added to the repo -- this is a file generated by `slither` in triage mode to mark what shouldn't be tested. This will periodically need to be reset, depending on how much the code has changed between the last run and may error on a future run of the contracts. [Note that it is only present to reduce duplicate work in slither results, and does not strictly need to be present in the result]
