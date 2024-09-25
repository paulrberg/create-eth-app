<h1 align="center">Welcome to superfluid protocol-monorepo 👋</h1>

<p>
  <a href="#superfluid-financeethereum-contracts" target="_blank">
    <img alt="npm" src="https://img.shields.io/npm/v/@superfluid-finance/ethereum-contracts?label=ethereum-contracts">
  </a>
  <a href="#superfluid-financesubgraph" target="_blank">
    <img alt="GitHub package.json version (subfolder of monorepo)" src="https://img.shields.io/github/package-json/v/superfluid-finance/protocol-monorepo?filename=packages%2Fsubgraph%2Fpackage.json&label=subgraph"> 
  </a>
  <a href="#superfluid-financejs-sdk" target="_blank">
    <img alt="npm" src="https://img.shields.io/npm/v/@superfluid-finance/js-sdk?label=js-sdk">
  </a>
  <a href="#superfluid-financesdk-core" target="_blank">
    <img alt="npm" src="https://img.shields.io/npm/v/@superfluid-finance/sdk-core?label=sdk-core">
  </a>
  <a href="#superfluid-financesdk-redux" target="_blank">
    <img alt="npm" src="https://img.shields.io/npm/v/@superfluid-finance/sdk-redux?label=sdk-redux">
  </a>
  <a href="#superfluid-financehot-fuzz" target="_blank">
    <img alt="GitHub package.json version (subfolder of monorepo)" src="https://img.shields.io/github/package-json/v/superfluid-finance/protocol-monorepo?filename=packages%2Fhot-fuzz%2Fpackage.json&label=hot-fuzz"> 
  </a>
  <br>
  <a href="https://twitter.com/Superfluid_HQ/status/" target="_blank">
    <img alt="Twitter: Superfluid_HQ" src="https://img.shields.io/twitter/follow/Superfluid_HQ.svg?style=social" />
  </a>
  <a href="https://www.codetriage.com/superfluid-finance/protocol-monorepo">
      <img src="https://www.codetriage.com/superfluid-finance/protocol-monorepo/badges/users.svg">
  </a>
</p>

> Contracts and resources for the Superfluid Protocol

### 🏠 [Homepage](https://superfluid.finance)

### ✨ [Superfluid App](https://app.superfluid.finance/)

### 📖 [Docs](https://docs.superfluid.finance)

The Superfluid Protocol is a framework that realizes the real-time finance vision
where user accounts are connected together, and transactions can happen between
user accounts instantaneously as a result.

This repository implements the superfluid protocol as Ethereum contracts. It also
contains a Javascript SDK for developing Web3 applications using the superfluid
protocol.

For technical document, references and tutorials, etc, refer to the
[docs site](http://docs.superfluid.finance/).

## Packages

#### [`@superfluid-finance/ethereum-contracts`](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/ethereum-contracts)

<p>
  <a href="https://www.npmjs.com/package/@superfluid-finance/ethereum-contracts" target="_blank">
    <img alt="Version" src="https://img.shields.io/npm/v/@superfluid-finance/ethereum-contracts.svg">
  </a>
  <a href="https://codecov.io/gh/superfluid-finance/protocol-monorepo/tree/dev/packages/ethereum-contracts">
    <img src="https://codecov.io/gh/superfluid-finance/protocol-monorepo/branch/dev/graph/badge.svg?token=LJW5NDGEJ9&flag=ethereum-contracts"/>
  </a>
  <a href="#" target="_blank">
    <img alt="License: AGPLv3" src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" />
  </a>
</p>

EVM contracts implementation for the Superfluid Protocol.

If you're interest in peeking under the hood, then check out the contracts package.

#### [`@superfluid-finance/metadata`](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/metadata)

<p>
  <a href="https://www.npmjs.com/package/@superfluid-finance/metadata" target="_blank">
    <img alt="Version" src="https://img.shields.io/npm/v/@superfluid-finance/metadata.svg">
  </a>
  <a href="#" target="_blank">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg" />
  </a>
</p>

Contract addresses, subgraph URLs, and other metadata for the Superfluid Protocol.

#### [`@superfluid-finance/sdk-core`](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/sdk-core)

<p>
  <a href="https://www.npmjs.com/package/@superfluid-finance/sdk-core" target="_blank">
    <img alt="Version" src="https://img.shields.io/npm/v/@superfluid-finance/sdk-core.svg">
  </a>
  <a href="https://codecov.io/gh/superfluid-finance/protocol-monorepo/tree/dev/packages/sdk-core">
    <img src="https://codecov.io/gh/superfluid-finance/protocol-monorepo/branch/dev/graph/badge.svg?token=LJW5NDGEJ9&flag=sdk-core"/>
  </a>
  <a href="#" target="_blank">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg" />
  </a>
</p>

SDK-Core is an application framework for interacting with the Superfluid Protocol without Solidity knowledge.

#### [`@superfluid-finance/sdk-redux`](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/sdk-redux)

<p>
  <a href="https://www.npmjs.com/package/@superfluid-finance/sdk-redux" target="_blank">
    <img alt="Version" src="https://img.shields.io/npm/v/@superfluid-finance/sdk-redux.svg">
  </a>
  <a href="#" target="_blank">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg" />
  </a>
</p>

SDK-Redux is an application framework for building front-end applications that interact with the Superfluid Protocol.

#### [`@superfluid-finance/hot-fuzz`](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/hot-fuzz)

<p>
  <a href="#" target="_blank">
    <img alt="License: AGPLv3" src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" />
  </a>
</p>

Hot-fuzz is a wrapper of [Echidna](https://github.com/crytic/echidna/) with additional helper for fuzzing
your Superfluid smart contracts applications, including [Super Apps](https://docs.superfluid.finance/superfluid/protocol-developers/super-apps).

#### [`@superfluid-finance/subgraph`](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/subgraph)

<p>
  <a href="#" target="_blank">
    <img alt="License: AGPLv3" src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" />
  </a>
</p>

Official subgraph for the Superfluid Protocol.

#### [`@superfluid-finance/js-sdk`](https://github.com/superfluid-finance/protocol-monorepo/tree/release-js-sdk-stable/packages/js-sdk)

<p>
  <a href="https://www.npmjs.com/package/@superfluid-finance/js-sdk" target="_blank">
    <img alt="Version" src="https://img.shields.io/npm/v/@superfluid-finance/js-sdk.svg">
  </a>
  <a href="#" target="_blank">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg" />
  </a>
</p>

:warning: This package is fully deprecated, use sdk-core instead :warning:

You can get the last release of js-sdk at the branch [here](https://github.com/superfluid-finance/protocol-monorepo/tree/release-js-sdk-stable/packages/js-sdk).

Javascript SDK for building with Superfluid Protocol.

## Bug Bounty

Click [here](https://github.com/superfluid-finance/protocol-monorepo/tree/dev/packages/ethereum-contracts/bug-bounty.md) for more information regarding our Bug Bounty.

## Examples

See our [examples repo](https://github.com/superfluid-finance/super-examples) for some Superfluid app examples.

## Contributing

Contributions, issues, and feature suggestions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## Contributors ✨

Thanks goes to these wonderful people ([🐸](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://www.joshua-trujillo.com/"><img src="https://avatars.githubusercontent.com/u/41972979?v=4?s=100" width="100px;" alt="Joshua Trujillo"/><br /><sub><b>Joshua Trujillo</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=JoshuaTrujillo15" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://manavdarji.notelet.so/"><img src="https://avatars.githubusercontent.com/u/36959497?v=4?s=100" width="100px;" alt="Manav Darji"/><br /><sub><b>Manav Darji</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=manav2401" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Drewsapple"><img src="https://avatars.githubusercontent.com/u/4532572?v=4?s=100" width="100px;" alt="Drew Fisher"/><br /><sub><b>Drew Fisher</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=Drewsapple" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/d10r"><img src="https://avatars.githubusercontent.com/u/5479136?v=4?s=100" width="100px;" alt="Didi"/><br /><sub><b>Didi</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=d10r" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://medium.com/@samparsky"><img src="https://avatars.githubusercontent.com/u/8148384?v=4?s=100" width="100px;" alt="Omidiora Samuel"/><br /><sub><b>Omidiora Samuel</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=samparsky" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/iamsahu"><img src="https://avatars.githubusercontent.com/u/46891804?v=4?s=100" width="100px;" alt="Prafful"/><br /><sub><b>Prafful</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=iamsahu" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mjaago"><img src="https://avatars.githubusercontent.com/u/25458626?v=4?s=100" width="100px;" alt="mjaago"/><br /><sub><b>mjaago</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=mjaago" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/markcarey"><img src="https://avatars.githubusercontent.com/u/98136?v=4?s=100" width="100px;" alt="markcarey"/><br /><sub><b>markcarey</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=markcarey" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/bertux"><img src="https://avatars.githubusercontent.com/u/5703?v=4?s=100" width="100px;" alt="Bertrand Juglas"/><br /><sub><b>Bertrand Juglas</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/pulls?q=is%3Apr+reviewed-by%3Abertux" title="Reviewed Pull Requests">👀</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://personal-site-shreyaspapi.vercel.app"><img src="https://avatars.githubusercontent.com/u/22324802?v=4?s=100" width="100px;" alt="Shreyas Papinwar"/><br /><sub><b>Shreyas Papinwar</b></sub></a><br /><a href="https://github.com/superfluid-finance/protocol-monorepo/commits?author=shreyaspapi" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
