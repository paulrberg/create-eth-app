# Ape Staking Public

This repository contains all the smart contracts related to $APE Staking. It also contains the script needed to 
deploy these contracts to either local environment or Goerli testnet and set all the needed values to start interacting 
with the staking contract. 

## Dependencies
Install `Node.js v16.2.0`.

Run `npm install` to install dependencies.

## Environment Variables
Create a `.env` file at the root of the project, and add the following variables (also visible in `.env.example`):
```
ALCHEMY_KEY=
PRIVATE_KEY_TESTNET=
ETHERSCAN_API_KEY=
```

## Deployment
The script behind the scenes

- Deploys a mock $APE ERC-20 coin contract
- Deploys mock BAYC, MAYC, BAKC ERC-721 contracts
- Deploys the staking Contract
- Deploys the $APE Staked Voting contract
- Sets up the `TimeRange` structs for all the 4 pools for the first year with the real values 
  (amount of distributed $APE for the first 4 quarters, max amount, duration of quarters etc..) These can be changed as needed for testing.
  Also, the distribution start time is set as the next top of the hour (i.e. running the script at 5:25 PM, then distribution starts at 6 PM)

### Local
In a separate terminal, run `npx hardhat node` to spin up a local Ethereum environment.

Run `npm run contracts:deploy:local` to compile and deploy all the contracts.

### Testnet
Provide values for the following environment variables in the .env file
- `ALCHEMY_KEY`
- `PRIVATE_KEY_TESTNET`
- `ETHERSCAN_API_KEY`

Run `npm run contracts:deploy:goerli` to compile and deploy all the contracts.



