## Setup

Install dependencies:
    
    nvm use # Should install node 10.16.0
    npm install -g ganache-cli
    npm install

### Ganache

Run Ganache:

    ganache-cli --port 9545 --deterministic

Any time you shutdown ganache, you will need to do `zos push` and `zos create` to deploy the project into the blank blockchain.

    npx zos session --network local --from 0x1df62f291b2e969fb0849d99d9ce41e2f137006e --expires 3600
    zos push
    zos create XPoap --init initialize --args '"Poap","POAP","https://poap.xyz",[]'

### Truffle Commands

To run a console:

    npx truffle console --network local

To run tests:

    npx truffle test

## Useful Commands

### Working with ZeppelinOS

#### Session

Start by creating a session:

```bash
npx zos session --network local --from 0x1df62f291b2e969fb0849d99d9ce41e2f137006e --expires 3600
```

This creates a "connection" that will be used for every zos command. We define which network to connect, which account to use by default
for all transaction and when it expires (3600 seconds after last used).

If no current session exists, or it its expired we need to create one.

#### Create or Upgrade Contracts

When we create a new contract run:

    npx zos add MyContract

To upgrade a current contract (change the code of it)

    npx zos update MyContract

After any change we need to **push** the changes:

    npx zos push

`add` and `update` only change the contract instance, but they don't actually release/create an instance of that contract.
To create an instance we do:

    npz zos create MyContract --init initialize --args 42,hitchhiker


### Contract addresses ###
#### Production ####
* Mainnet: [0x22c1f6050e56d2876009903609a2cc3fef83b415](https://etherscan.io/address/0x22c1f6050e56d2876009903609a2cc3fef83b415)
* xDAI: [0x22c1f6050e56d2876009903609a2cc3fef83b415](https://blockscout.com/poa/xdai/address/0x22c1f6050e56d2876009903609a2cc3fef83b415/transactions)

#### Development ####
* Rinkeby: []()
* Sokol: [0x22c1f6050e56d2876009903609a2cc3fef83b415](https://blockscout.com/poa/sokol/address/0x22c1f6050e56d2876009903609a2cc3fef83b415/transactions)
* Binance Smart Chain: [0xe310633E107e87F8Dfe50b00C360be60e926A1d6](https://testnet.bscscan.com/address/0xe310633e107e87f8dfe50b00c360be60e926a1d6)
