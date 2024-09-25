# Ubeswap

Ubeswap is a protocol for decentralized exchange and automated liquidity provision on Celo.

https://ubeswap.org

## Deployed Contracts

- UniswapV2Factory - https://explorer.celo.org/address/0x62d5b84be28a183abb507e125b384122d2c25fae
- UniswapV2Router02 - https://explorer.celo.org/address/0xe3d8bd6aed4f159bc8000a9cd47cffdb95f96121

## Docs

[Development](docs/DEVELOPMENT.md)

[Deployment](docs/DEPLOYMENT.md)

## Verification

Verified sources are available on [Sourcify](https://sourcify.dev/).

To verify the sources yourself on Sourcify:

1. Run `./verify.sh` from the root directory.
2. For each of `UniswapV2Factory` and `UniswapV2Router02`:
   a. Upload the verified metadata from `deployments/metadata/<Contract Name>/metadata.json`
   b. Upload the sources from `verified-sources/`

### Mainnet

- [Factory](https://repo.sourcify.dev/contracts/full_match/42220/0x62d5b84bE28a183aBB507E125B384122D2C25fAE/)
- [Router](https://repo.sourcify.dev/contracts/full_match/42220/0xE3D8bd6Aed4F159bc8000a9cD47CffDb95F96121/)

### Alfajores

- [Factory](https://repo.sourcify.dev/contracts/full_match/44787/0x62d5b84bE28a183aBB507E125B384122D2C25fAE/)
- [Router](https://repo.sourcify.dev/contracts/full_match/44787/0xE3D8bd6Aed4F159bc8000a9cD47CffDb95F96121/)

## License

MIT
