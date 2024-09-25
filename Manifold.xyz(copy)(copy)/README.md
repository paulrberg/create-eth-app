# manifoldxyz-creator-core-solidity

## The Manifold Creator Core Contracts

**A library for extendible creator contracts.**

 * Implementation for ERC721
 * Implementation for ERC1155

The Manifold Creator Core contracts provide creators with the ability to deploy an ERC721/ERC1155 NFT smart contract with basic minting functionality, on-chain royalties and permissioning.  Additionally, they provide a framework for extending the functionality of the smart contract by installing extension applications.

These contracts are used in the [Manifold Studio](https://studio.manifoldxyz.dev/).

This enables creators to use the same underlying Manifold Creator Core contract to continue creating new and innovative NFT's and experiences.

See our [developer documentation](https://docs.manifold.xyz/v/manifold-for-developers/manifold-creator-architecture/overview) and [blog post](https://manifoldxyz.substack.com/p/manifold-creator) for more information.

Go [here](https://docs.manifold.xyz/v/manifold-for-developers/manifold-creator-architecture/contracts/extensions/extensions-examples) for example applications that have been added to Manifold Creator Core contracts.

## Overview

### Installation

```console
$ npm install @manifoldxyz/creator-core-solidity
```

### Usage

Once installed, you can use the contracts in the library by importing them:

```solidity
pragma solidity ^0.8.0;

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract MyContract is ERC721Creator  {
    constructor() ERC721Creator ("MyContract", "MC") {
    }
}
```

The available contracts are:

 * ERC721Creator
 * ERC721CreatorUpgradeable - A transparent proxy upgradeable version of ERC721Creator
 * ERC721CreatorEnumerable - Note that using enumerable significantly increase mint costs by around 2x
 * ERC1155Creator

[Manifold Studio](https://studio.manifoldxyz.dev/) currently makes use of ERC721Creator and ERC1155Creator

### Extension Applications

The most powerful aspect of Manifold Creator Core contracts is the ability to extend the functionality of your smart contract by adding new Extension Applications (Apps). Apps have the ability to override the following functionality for any token created by that App:

**ERC721**
 * mint
 * tokenURI
 * transferFrom/safeTransferFrom pre-transfer check
 * burn pre-burn check
 * define royalties for extension minted tokens

**ERC1155**
 * mint
 * uri
 * safeTransferFrom pre-transfer check
 * burn pre-burn check
 * define royalties for extension minted tokens

In order to create an app, you'll need to implement one or more interfaces within contracts/extensions, deploy the new app and register it to the main Creator Core contract using the registerExtension function (which is only accessible to the contract owner or admins).

Example applications can be found [here](https://github.com/manifoldxyz/creator-core-extensions-solidity).

## Running the package unit tests

```
forge test
```
