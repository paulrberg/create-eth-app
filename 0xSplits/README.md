# splits-contracts

[![codecov](https://codecov.io/gh/0xSplits/splits-contracts/branch/main/graph/badge.svg?token=ERFQOFF0L7)](https://codecov.io/gh/0xSplits/splits-contracts)

## Run locally
```
yarn hardhat node
```

## Metamask network config
- Network name: `Localhost`
- New RPC URL: `http://{{LOCALHOST URL - ie 127.0.0.1}}:8545`
- Chain ID: `1337`

## Dev Setup
Make sure to have node installed, need >= 12. Can find the installation
[here](https://nodejs.org/en/download/). A node version manager can also
be useful, you can read more about it [here](https://github.com/nvm-sh/nvm).

Install yarn: `npm install --global yarn`  
Confirm the installation: `yarn --version`

Run `yarn install` to add packages

Follow the hardhat network setup instructions in the Metamask network config section up above.
If you do not have metamask installed, you can find it [here](https://metamask.io/).

Add funds to your wallet, you can find the instructions below in the Commands section.

Setup your .env.local file. Copy over the .env.local.sample file and fill in the values. Message someone else to get the values.

## Common Errors
If you are getting an error on the `yarn hardhat node` command, you may need to clear out the artifacts/cache. Run `yarn hardhat clean`, then try again.

# Commands
```
// Send funds to local wallet
yarn hardhat seedAccount --network localhost {{YOUR_WALLET_ADDRESS}}

// Create split with random recipients
yarn hardhat createSplit --network localhost --size {{SIZE}}
```
